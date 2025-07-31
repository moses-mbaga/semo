import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/enums/media_type.dart";
import "package:index/models/tv_show.dart";
import "package:index/models/season.dart";
import "package:index/models/episode.dart";
import "package:index/models/person.dart";
import "package:index/models/search_results.dart";
import "package:index/services/tmdb_service.dart";

mixin TvShowHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadTvShowDetails(LoadTvShowDetails event, Emitter<AppState> emit) async {
    final String tvShowId = event.tvShowId.toString();
    final bool isTvShowLoading = state.isTvShowLoading?[tvShowId] == true;

    if (isTvShowLoading) {
      return;
    }

    final bool isSeasonsLoaded = state.tvShowSeasons?.containsKey(tvShowId) ?? false;
    final bool isFirstSeasonEpisodesLoaded = _isFirstSeasonEpisodesLoaded(tvShowId);
    final bool isCastLoaded = state.tvShowCast?.containsKey(tvShowId) ?? false;
    final bool isRecommendationsLoaded = state.tvShowRecommendationsPagingControllers?.containsKey(tvShowId) ?? false;
    final bool isSimilarLoaded = state.similarTvShowsPagingControllers?.containsKey(tvShowId) ?? false;

    final Map<String, bool> updatedLoadingStatus = Map<String, bool>.from(state.isTvShowLoading ?? <String, bool>{});

    if (isSeasonsLoaded && isFirstSeasonEpisodesLoaded && isCastLoaded && isRecommendationsLoaded && isSimilarLoaded) {
      updatedLoadingStatus[tvShowId] = false;
      emit(state.copyWith(
        isTvShowLoading: updatedLoadingStatus,
        error: null,
      ));
      return;
    }

    updatedLoadingStatus[tvShowId] = true;

    emit(state.copyWith(
      isTvShowLoading: updatedLoadingStatus,
      error: null,
    ));

    try {
      await Future.wait(<Future<dynamic>>[
        _loadTvShowSeasons(event.tvShowId, emit),
        _loadTvShowTrailer(event.tvShowId, emit),
        _loadTvShowCast(event.tvShowId, emit),
        _loadTvShowRecommendations(event.tvShowId, emit),
        _loadSimilarTvShows(event.tvShowId, emit),
      ]);

      updatedLoadingStatus[tvShowId] = false;
      emit(state.copyWith(
        isTvShowLoading: updatedLoadingStatus,
      ));
    } catch (e, s) {
      _logger.e("Error loading TV show details for ID ${event.tvShowId}", error: e, stackTrace: s);

      updatedLoadingStatus[tvShowId] = false;
      emit(state.copyWith(
        isTvShowLoading: updatedLoadingStatus,
        error: "Failed to load TV show details",
      ));
    }
  }

  Future<void> onLoadSeasonEpisodes(LoadSeasonEpisodes event, Emitter<AppState> emit) async {
    final String tvShowId = event.tvShowId.toString();

    final bool isSeasonLoading = state.isSeasonEpisodesLoading?[tvShowId]?[event.seasonNumber] == true;
    if (isSeasonLoading) {
      return;
    }

    final bool isSeasonEpisodesLoaded = state.tvShowEpisodes?[tvShowId]?.containsKey(event.seasonNumber) ?? false;
    if (isSeasonEpisodesLoaded) {
      return;
    }

    final Map<String, Map<int, bool>> updatedSeasonLoadingStatus = Map<String, Map<int, bool>>.from(state.isSeasonEpisodesLoading ?? <String, Map<int, bool>>{});

    if (updatedSeasonLoadingStatus[tvShowId] == null) {
      updatedSeasonLoadingStatus[tvShowId] = <int, bool>{};
    }

    updatedSeasonLoadingStatus[tvShowId]![event.seasonNumber] = true;

    emit(state.copyWith(
      isSeasonEpisodesLoading: updatedSeasonLoadingStatus,
      error: null,
    ));

    try {
      await _loadEpisodesForSeason(event.tvShowId, event.seasonNumber, emit);

      updatedSeasonLoadingStatus[tvShowId]![event.seasonNumber] = false;
      emit(state.copyWith(
        isSeasonEpisodesLoading: updatedSeasonLoadingStatus,
      ));
    } catch (e, s) {
      _logger.e("Error loading episodes for TV show ID $tvShowId, season ${event.seasonNumber}", error: e, stackTrace: s);

      updatedSeasonLoadingStatus[tvShowId]![event.seasonNumber] = false;
      emit(state.copyWith(
        isSeasonEpisodesLoading: updatedSeasonLoadingStatus,
        error: "Failed to load season episodes",
      ));
    }
  }

  bool _isFirstSeasonEpisodesLoaded(String tvShowId) {
    final List<Season>? seasons = state.tvShowSeasons?[tvShowId];
    if (seasons == null || seasons.isEmpty) {
      return false;
    }

    final Season firstSeason = seasons.first;
    return state.tvShowEpisodes?[tvShowId]?.containsKey(firstSeason.number) ?? false;
  }

  Future<dynamic> _loadTvShowSeasons(int tvShowId, Emitter<AppState> emit) async {
    try {
      final List<Season> seasons = await _tmdbService.getTvShowSeasons(tvShowId);

      if (seasons.isNotEmpty) {
        final Map<String, List<Season>> tvShowSeasons = Map<String, List<Season>>.from(state.tvShowSeasons ?? <String, List<Season>>{});
        tvShowSeasons[tvShowId.toString()] = seasons;

        emit(state.copyWith(
          tvShowSeasons: tvShowSeasons,
        ));

        // Load only the first season's episodes initially
        await _loadEpisodesForSeason(tvShowId, seasons.first.number, emit);
      }
    } catch (e, s) {
      _logger.e("Error loading TV show seasons for ID $tvShowId", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<dynamic> _loadEpisodesForSeason(int tvShowId, int seasonNumber, Emitter<AppState> emit) async {
    try {
      final List<Episode> episodes = await _tmdbService.getEpisodes(tvShowId, seasonNumber);

      final Map<String, Map<int, List<Episode>>> tvShowEpisodes = Map<String, Map<int, List<Episode>>>.from(state.tvShowEpisodes ?? <String, Map<int, List<Episode>>>{});

      if (tvShowEpisodes[tvShowId.toString()] == null) {
        tvShowEpisodes[tvShowId.toString()] = <int, List<Episode>>{};
      }

      tvShowEpisodes[tvShowId.toString()]![seasonNumber] = episodes;

      emit(state.copyWith(
        tvShowEpisodes: tvShowEpisodes,
      ));
    } catch (e, s) {
      _logger.e("Error loading episodes for TV show ID $tvShowId, season $seasonNumber", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _loadTvShowTrailer(int tvShowId, Emitter<AppState> emit) async {
    try {
      final String? trailerUrl = await _tmdbService.getTrailerUrl(MediaType.tvShows, tvShowId);

      if (trailerUrl != null) {
        Map<String, String> tvShowTrailers = Map<String, String>.from(state.tvShowTrailers ?? <String, String>{});
        tvShowTrailers[tvShowId.toString()] = trailerUrl;

        emit(state.copyWith(
          tvShowTrailers: tvShowTrailers,
        ));
      }
    } catch (e, s) {
      _logger.e("Error loading TV show trailer for ID $tvShowId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadTvShowCast(int tvShowId, Emitter<AppState> emit) async {
    try {
      final List<Person> cast = await _tmdbService.getCast(MediaType.tvShows, tvShowId);

      Map<String, List<Person>> tvShowCast = Map<String, List<Person>>.from(state.tvShowCast ?? <String, List<Person>>{});
      tvShowCast[tvShowId.toString()] = cast;

      emit(state.copyWith(
        tvShowCast: tvShowCast,
      ));
    } catch (e, s) {
      _logger.e("Error loading TV show cast for ID $tvShowId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadTvShowRecommendations(int tvShowId, Emitter<AppState> emit) async {
    try {
      final Map<String, PagingController<int, TvShow>> recommendationsControllers =
      Map<String, PagingController<int, TvShow>>.from(state.tvShowRecommendationsPagingControllers ?? <String, PagingController<int, TvShow>>{});

      final PagingController<int, TvShow> recommendationsController = PagingController<int, TvShow>(
        getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null: state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getRecommendations(MediaType.tvShows, tvShowId, pageKey);
          final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
          add(AddIncompleteTvShows(tvShows));
          return tvShows;
        },
      );

      recommendationsControllers[tvShowId.toString()] = recommendationsController;

      emit(state.copyWith(
        tvShowRecommendationsPagingControllers: recommendationsControllers,
      ));
    } catch (e, s) {
      _logger.e("Error loading TV show recommendations for ID $tvShowId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadSimilarTvShows(int tvShowId, Emitter<AppState> emit) async {
    try {
      final Map<String, PagingController<int, TvShow>> similarTvShowsControllers =
      Map<String, PagingController<int, TvShow>>.from(state.similarTvShowsPagingControllers ?? <String, PagingController<int, TvShow>>{});

      final PagingController<int, TvShow> similarTvShowsController = PagingController<int, TvShow>(
        getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getSimilar(MediaType.tvShows, tvShowId, pageKey);
          final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
          add(AddIncompleteTvShows(tvShows));
          return tvShows;
        },
      );

      similarTvShowsControllers[tvShowId.toString()] = similarTvShowsController;

      emit(state.copyWith(
        similarTvShowsPagingControllers: similarTvShowsControllers,
      ));
    } catch (e, s) {
      _logger.e("Error loading similar TV shows for ID $tvShowId", error: e, stackTrace: s);
    }
  }

  void onRefreshTvShowDetails(RefreshTvShowDetails event, Emitter<AppState> emit) {
    state.tvShowRecommendationsPagingControllers?.forEach((String tvShowId, PagingController<int, TvShow> controller) {
      if (event.tvShowId == int.parse(tvShowId)) {
        controller.refresh();
      }
    });

    state.similarTvShowsPagingControllers?.forEach((String tvShowId, PagingController<int, TvShow> controller) {
      if (event.tvShowId == int.parse(tvShowId)) {
        controller.refresh();
      }
    });

    add(LoadTvShowDetails(event.tvShowId));
  }
}