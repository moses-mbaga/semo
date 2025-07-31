import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/models/search_results.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/tmdb_service.dart";

mixin TvShowsHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadTvShows(LoadTvShows event, Emitter<AppState> emit) async {
    bool areAllTvShowsLoaded = state.onTheAirTvShows != null && state.onTheAirTvShows!.isNotEmpty;
    bool areAllControllersPopulated = state.trendingTvShowsPagingController != null &&
        state.popularTvShowsPagingController != null &&
        state.topRatedTvShowsPagingController != null;
    if ((areAllTvShowsLoaded && areAllControllersPopulated) || state.isLoadingTvShows) {
      return;
    }

    emit(state.copyWith(
      isLoadingTvShows: true,
      error: null,
    ));

    try {
      final SearchResults results = await _tmdbService.getOnTheAirTvShows();
      final List<TvShow> onTheAirTvShows = results.tvShows ?? <TvShow>[];
      final List<TvShow> limitedNowPlayingTvShows = onTheAirTvShows.length > 10 ? onTheAirTvShows.sublist(0, 10) : onTheAirTvShows;

      final PagingController<int, TvShow> trendingController = PagingController<int, TvShow>(
        getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getTrendingTvShows(pageKey);
          final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
          add(AddIncompleteTvShows(tvShows));
          return tvShows;
        },
      );

      final PagingController<int, TvShow> popularController = PagingController<int, TvShow>(
        getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getPopularTvShows(pageKey);
          final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
          add(AddIncompleteTvShows(tvShows));
          return tvShows;
        },
      );

      final PagingController<int, TvShow> topRatedController = PagingController<int, TvShow>(
        getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getTopRatedTvShows(pageKey);
          final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
          add(AddIncompleteTvShows(tvShows));
          return tvShows;
        },
      );

      emit(state.copyWith(
        onTheAirTvShows: limitedNowPlayingTvShows,
        trendingTvShowsPagingController: trendingController,
        popularTvShowsPagingController: popularController,
        topRatedTvShowsPagingController: topRatedController,
        isLoadingTvShows: false,
      ));
    } catch (e, s) {
      _logger.e("Error loading TV shows", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingTvShows: false,
        error: "Failed to load TV shows",
      ));
    }
  }

  void onRefreshTvShows(RefreshTvShows event, Emitter<AppState> emit) {
    state.trendingTvShowsPagingController?.refresh();
    state.popularTvShowsPagingController?.refresh();
    state.topRatedTvShowsPagingController?.refresh();

    emit(state.copyWith(
      onTheAirTvShows: null,
      isLoadingTvShows: false,
    ));

    add(LoadTvShows());
  }

  void onAddIncompleteTvShows(AddIncompleteTvShows event, Emitter<AppState> emit) {
    final List<TvShow> incompleteTvShows = state.incompleteTvShows ?? <TvShow>[];

    for (final TvShow tvShow in event.tvShows) {
      try {
        if (!incompleteTvShows.any((TvShow m) => m.id == tvShow.id)) {
          incompleteTvShows.add(tvShow);
        }
      } catch (e, s) {
        _logger.e("Error adding incomplete TV show ${tvShow.id}", error: e, stackTrace: s);
      }
    }

    emit(state.copyWith(
      incompleteTvShows: incompleteTvShows,
    ));
  }
}