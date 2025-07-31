import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/enums/media_type.dart";
import "package:index/models/movie.dart";
import "package:index/models/person.dart";
import "package:index/models/search_results.dart";
import "package:index/services/tmdb_service.dart";

mixin MovieHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadMovieDetails(LoadMovieDetails event, Emitter<AppState> emit) async {
    final String movieId = event.movieId.toString();
    final bool isMovieLoading = state.isMovieLoading?[movieId] == true;

    if (isMovieLoading) {
      return;
    }

    final bool isMovieLoaded = state.movies?.indexWhere((Movie movie) => movie.id.toString() == movieId) != -1;
    final bool isTrailerLoaded = state.movieTrailers?.containsKey(movieId) ?? false;
    final bool isCastLoaded = state.movieCast?.containsKey(movieId) ?? false;
    final bool isRecommendationsLoaded = state.movieRecommendationsPagingControllers?.containsKey(movieId) ?? false;
    final bool isSimilarLoaded = state.similarMoviesPagingControllers?.containsKey(movieId) ?? false;

    final Map<String, bool> updatedLoadingStatus = Map<String, bool>.from(state.isMovieLoading ?? <String, bool>{});

    if (isMovieLoaded && isTrailerLoaded && isCastLoaded && isRecommendationsLoaded && isSimilarLoaded) {
      updatedLoadingStatus[movieId] = false;
      emit(state.copyWith(
        isMovieLoading: updatedLoadingStatus,
        error: null,
      ));
      return;
    }

    updatedLoadingStatus[movieId] = true;

    emit(state.copyWith(
      isMovieLoading: updatedLoadingStatus,
      error: null,
    ));

    try {
      await Future.wait(<Future<dynamic>>[
        _loadMovieBasicDetails(event.movieId, emit),
        _loadMovieTrailer(event.movieId, emit),
        _loadMovieCast(event.movieId, emit),
        _loadMovieRecommendations(event.movieId, emit),
        _loadSimilarMovies(event.movieId, emit),
      ]);

      updatedLoadingStatus[movieId] = false;
      emit(state.copyWith(
        isMovieLoading: updatedLoadingStatus,
      ));
    } catch (e, s) {
      _logger.e("Error loading movie details for ID ${event.movieId}", error: e, stackTrace: s);

      updatedLoadingStatus[movieId] = false;
      emit(state.copyWith(
        isMovieLoading: updatedLoadingStatus,
        error: "Failed to load movie details",
      ));
    }
  }

  Future<dynamic> _loadMovieBasicDetails(int movieId, Emitter<AppState> emit) async {
    try {
      final Movie? movie = await _tmdbService.getMovie(movieId);

      if (movie != null) {
        final List<Movie> movies = List<Movie>.from(state.movies ?? <Movie>[]);
        final int existingIndex = movies.indexWhere((Movie m) =>
        m.id == movieId);

        if (existingIndex != -1) {
          movies[existingIndex] = movie;
        } else {
          movies.add(movie);
        }

        emit(state.copyWith(
          movies: movies,
        ));
      }
    } catch (e, s) {
      _logger.e("Error loading basic movie details for ID $movieId", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _loadMovieTrailer(int movieId, Emitter<AppState> emit) async {
    try {
      final String? trailerUrl = await _tmdbService.getTrailerUrl(MediaType.movies, movieId);

      if (trailerUrl != null) {
        Map<String, String> movieTrailers = Map<String, String>.from(state.movieTrailers ?? <String, String>{});
        movieTrailers[movieId.toString()] = trailerUrl;

        emit(state.copyWith(
          movieTrailers: movieTrailers,
        ));
      }
    } catch (e, s) {
      _logger.e("Error loading movie trailer for ID $movieId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadMovieCast(int movieId, Emitter<AppState> emit) async {
    try {
      final List<Person> cast = await _tmdbService.getCast(MediaType.movies, movieId);

      Map<String, List<Person>> movieCast = Map<String, List<Person>>.from(state.movieCast ?? <String, List<Person>>{});
      movieCast[movieId.toString()] = cast;

      emit(state.copyWith(
        movieCast: movieCast,
      ));
    } catch (e, s) {
      _logger.e("Error loading movie cast for ID $movieId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadMovieRecommendations(int movieId, Emitter<AppState> emit) async {
    try {
      final Map<String, PagingController<int, Movie>> recommendationsControllers =
      Map<String, PagingController<int, Movie>>.from(state.movieRecommendationsPagingControllers ?? <String, PagingController<int, Movie>>{});

      final PagingController<int, Movie> recommendationsController = PagingController<int, Movie>(
        getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null: state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getRecommendations(MediaType.movies, movieId, pageKey);
          final List<Movie> movies = results.movies ?? <Movie>[];
          add(AddIncompleteMovies(movies));
          return movies;
        },
      );

      recommendationsControllers[movieId.toString()] = recommendationsController;

      emit(state.copyWith(
        movieRecommendationsPagingControllers: recommendationsControllers,
      ));
    } catch (e, s) {
      _logger.e("Error loading movie recommendations for ID $movieId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadSimilarMovies(int movieId, Emitter<AppState> emit) async {
    try {
      final Map<String, PagingController<int, Movie>> similarMoviesControllers =
      Map<String, PagingController<int, Movie>>.from(state.similarMoviesPagingControllers ?? <String, PagingController<int, Movie>>{});

      final PagingController<int, Movie> similarMoviesController = PagingController<int, Movie>(
        getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
        fetchPage: (int pageKey) async {
          final SearchResults results = await _tmdbService.getSimilar(MediaType.movies, movieId, pageKey);
          final List<Movie> movies = results.movies ?? <Movie>[];
          add(AddIncompleteMovies(movies));
          return movies;
        },
      );

      similarMoviesControllers[movieId.toString()] = similarMoviesController;

      emit(state.copyWith(
        similarMoviesPagingControllers: similarMoviesControllers,
      ));
    } catch (e, s) {
      _logger.e("Error loading similar movies for ID $movieId", error: e, stackTrace: s);
    }
  }

  void onRefreshMovieDetails(RefreshMovieDetails event, Emitter<AppState> emit) {
    state.movieRecommendationsPagingControllers?.forEach((String movieId, PagingController<int, Movie> controller) {
      if (event.movieId == int.parse(movieId)) {
        controller.refresh();
      }
    });

    state.similarMoviesPagingControllers?.forEach((String movieId, PagingController<int, Movie> controller) {
      if (event.movieId == int.parse(movieId)) {
        controller.refresh();
      }
    });

    add(LoadMovieDetails(event.movieId));
  }
}