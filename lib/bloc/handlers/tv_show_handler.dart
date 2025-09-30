import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/models/season.dart";
import "package:semo/models/episode.dart";
import "package:semo/models/person.dart";
import "package:semo/models/search_results.dart";
import "package:semo/services/tmdb_service.dart";

mixin TvShowHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadTvShowDetails(LoadTvShowDetails event, Emitter<AppState> emit) async {
    final String tvShowId = event.tvShowId.toString();
    final bool isTvShowLoading = state.isTvShowLoading?[tvShowId] == true;

    if (isTvShowLoading) {
      return;
    }

    TvShow? existingTvShow;
    if (state.tvShows != null) {
      try {
        existingTvShow = state.tvShows!.firstWhere((TvShow tvShow) => tvShow.id.toString() == tvShowId);
      } catch (_) {}
    }

    final bool isSeasonsLoaded = state.tvShowSeasons?.containsKey(tvShowId) ?? false;
    final bool isFirstSeasonEpisodesLoaded = _isFirstSeasonEpisodesLoaded(tvShowId);
    final bool isCastLoaded = state.tvShowCast?.containsKey(tvShowId) ?? false;
    final bool isRecommendationsLoaded = state.tvShowRecommendationsPagingControllers?.containsKey(tvShowId) ?? false;
    final bool isSimilarLoaded = state.similarTvShowsPagingControllers?.containsKey(tvShowId) ?? false;
    final bool isTrailerLoaded = existingTvShow?.trailerUrl?.isNotEmpty ?? false;

    final Map<String, bool> updatedLoadingStatus = Map<String, bool>.from(state.isTvShowLoading ?? <String, bool>{});

    if (isTrailerLoaded && isSeasonsLoaded && isFirstSeasonEpisodesLoaded && isCastLoaded && isRecommendationsLoaded && isSimilarLoaded) {
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
        _loadTvShowBasicDetails(event.tvShowId, emit),
        _loadTvShowSeasons(event.tvShowId, emit),
        _loadTvShowImdbId(event.tvShowId, emit),
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

  Future<void> _loadTvShowBasicDetails(int tvShowId, Emitter<AppState> emit) async {
    try {
      final TvShow? tvShow = await _tmdbService.getTvShow(tvShowId);
      if (tvShow != null) {
        final String? trailerUrl = await _tmdbService.getTrailerUrl(MediaType.tvShows, tvShowId);
        final TvShow updatedTvShow = tvShow.copyWith(trailerUrl: trailerUrl);

        final List<TvShow> tvShows = List<TvShow>.from(state.tvShows ?? <TvShow>[]);
        final int existingIndex = tvShows.indexWhere((TvShow m) => m.id == tvShowId);

        if (existingIndex != -1) {
          tvShows[existingIndex] = updatedTvShow;
        } else {
          tvShows.add(updatedTvShow);
        }

        emit(state.copyWith(
          tvShows: tvShows,
        ));
      }
    } catch (e, s) {
      _logger.e("Error loading TV show basic details for ID $tvShowId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadTvShowImdbId(int tvShowId, Emitter<AppState> emit) async {
    try {
      final String? imdbId = await _tmdbService.getImdbId(MediaType.tvShows, tvShowId);

      if (imdbId != null && imdbId.isNotEmpty) {
        final Map<String, String> tvShowImdbIds = Map<String, String>.from(state.tvShowImdbIds ?? <String, String>{});
        tvShowImdbIds[tvShowId.toString()] = imdbId;

        emit(state.copyWith(
          tvShowImdbIds: tvShowImdbIds,
        ));
      }
    } catch (e, s) {
      _logger.w("Error loading TV show IMDB id for ID $tvShowId", error: e, stackTrace: s);
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

  Future<void> _loadTvShowSeasons(int tvShowId, Emitter<AppState> emit) async {
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
    }
  }

  Future<void> _loadEpisodesForSeason(int tvShowId, int seasonNumber, Emitter<AppState> emit) async {
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
          final SearchResults? results = await _tmdbService.getRecommendations(MediaType.tvShows, tvShowId, pageKey);
          final List<TvShow> tvShows = results?.tvShows ?? <TvShow>[];
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
          final SearchResults? results = await _tmdbService.getSimilar(MediaType.tvShows, tvShowId, pageKey);
          final List<TvShow> tvShows = results?.tvShows ?? <TvShow>[];
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
    final List<TvShow> tvShows = List<TvShow>.from(state.tvShows ?? <TvShow>[]);
    tvShows.removeWhere((TvShow tvShow) => tvShow.id == event.tvShowId);

    Map<String, List<Person>> tvShowCast = Map<String, List<Person>>.from(state.tvShowCast ?? <String, List<Person>>{});
    tvShowCast.remove(event.tvShowId.toString());

    Map<String, List<Season>> tvShowSeasons = Map<String, List<Season>>.from(state.tvShowSeasons ?? <String, List<Season>>{});
    tvShowSeasons.remove(event.tvShowId.toString());

    Map<String, Map<int, List<Episode>>> tvShowEpisodes = Map<String, Map<int, List<Episode>>>.from(state.tvShowEpisodes ?? <String, Map<int, List<Episode>>>{});
    tvShowEpisodes.remove(event.tvShowId.toString());

    Map<String, PagingController<int, TvShow>> recommendationsControllers = Map<String, PagingController<int, TvShow>>.from(state.tvShowRecommendationsPagingControllers ?? <String, PagingController<int, TvShow>>{});
    recommendationsControllers.remove(event.tvShowId.toString());

    Map<String, PagingController<int, TvShow>> similarTvShowsControllers = Map<String, PagingController<int, TvShow>>.from(state.similarTvShowsPagingControllers ?? <String, PagingController<int, TvShow>>{});
    similarTvShowsControllers.remove(event.tvShowId.toString());

    final Map<String, bool> loadingStatus = Map<String, bool>.from(state.isTvShowLoading ?? <String, bool>{});
    loadingStatus[event.tvShowId.toString()] = false;

    emit(state.copyWith(
      tvShows: tvShows,
      tvShowCast: tvShowCast,
      tvShowSeasons: tvShowSeasons,
      tvShowEpisodes: tvShowEpisodes,
      tvShowRecommendationsPagingControllers: recommendationsControllers,
      similarTvShowsPagingControllers: similarTvShowsControllers,
      isTvShowLoading: loadingStatus,
    ));

    add(LoadTvShowDetails(event.tvShowId));
  }
}
