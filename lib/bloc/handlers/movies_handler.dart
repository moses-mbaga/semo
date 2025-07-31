import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/models/movie.dart";
import "package:index/models/search_results.dart";
import "package:index/services/tmdb_service.dart";

mixin MoviesHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadMovies(LoadMovies event, Emitter<AppState> emit) async {
    bool areAllMoviesLoaded = state.nowPlayingMovies != null && state.nowPlayingMovies!.isNotEmpty;
    bool areAllControllersPopulated = state.trendingMoviesPagingController != null &&
        state.popularMoviesPagingController != null &&
        state.topRatedMoviesPagingController != null;
    if ((areAllMoviesLoaded && areAllControllersPopulated) || state.isLoadingMovies) {
      return;
    }

    emit(state.copyWith(
      isLoadingMovies: true,
      error: null,
    ));

    try {
      final SearchResults results = await _tmdbService.getNowPlayingMovies();
      final List<Movie> nowPlayingMovies = results.movies ?? <Movie>[];
      final List<Movie> limitedNowPlayingMovies = nowPlayingMovies.length > 10 ? nowPlayingMovies.sublist(0, 10) : nowPlayingMovies;

      final PagingController<int, Movie> trendingController = PagingController<int, Movie>(
        getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getTrendingMovies(pageKey);
          final List<Movie> movies = results.movies ?? <Movie>[];
          add(AddIncompleteMovies(movies));
          return movies;
        },
      );

      final PagingController<int, Movie> popularController = PagingController<int, Movie>(
        getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getPopularMovies(pageKey);
          final List<Movie> movies = results.movies ?? <Movie>[];
          add(AddIncompleteMovies(movies));
          return movies;
        },
      );

      final PagingController<int, Movie> topRatedController = PagingController<int, Movie>(
        getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getTopRatedMovies(pageKey);
          final List<Movie> movies = results.movies ?? <Movie>[];
          add(AddIncompleteMovies(movies));
          return movies;
        },
      );

      emit(state.copyWith(
        nowPlayingMovies: limitedNowPlayingMovies,
        trendingMoviesPagingController: trendingController,
        popularMoviesPagingController: popularController,
        topRatedMoviesPagingController: topRatedController,
        isLoadingMovies: false,
      ));
    } catch (e, s) {
      _logger.e("Error loading movies", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingMovies: false,
        error: "Failed to load movies",
      ));
    }
  }

  void onRefreshMovies(RefreshMovies event, Emitter<AppState> emit) {
    state.trendingMoviesPagingController?.refresh();
    state.popularMoviesPagingController?.refresh();
    state.topRatedMoviesPagingController?.refresh();

    emit(state.copyWith(
      nowPlayingMovies: null,
      isLoadingMovies: false,
    ));

    add(LoadMovies());
  }

  void onAddIncompleteMovies(AddIncompleteMovies event, Emitter<AppState> emit) {
    final List<Movie> incompleteMovies = state.incompleteMovies ?? <Movie>[];

    for (final Movie movie in event.movies) {
      try {
        if (!incompleteMovies.any((Movie m) => m.id == movie.id)) {
          incompleteMovies.add(movie);
        }
      } catch (e, s) {
        _logger.e("Error adding incomplete movie ${movie.id}", error: e, stackTrace: s);
      }
    }

    emit(state.copyWith(
      incompleteMovies: incompleteMovies,
    ));
  }
}