import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/person.dart";
import "package:semo/models/search_results.dart";
import "package:semo/services/tmdb_service.dart";

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
    Movie? existingMovie;
    if (state.movies != null) {
      try {
        existingMovie = state.movies!.firstWhere((Movie movie) => movie.id.toString() == movieId);
      } catch (_) {}
    }
    final bool isTrailerLoaded = existingMovie?.trailerUrl?.isNotEmpty ?? false;
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
        _loadMovieImdbId(event.movieId, emit),
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

  Future<void> _loadMovieImdbId(int movieId, Emitter<AppState> emit) async {
    try {
      final String? imdbId = await _tmdbService.getImdbId(MediaType.movies, movieId);

      if (imdbId != null && imdbId.isNotEmpty) {
        final Map<String, String> movieImdbIds = Map<String, String>.from(state.movieImdbIds ?? <String, String>{});
        movieImdbIds[movieId.toString()] = imdbId;

        emit(state.copyWith(
          movieImdbIds: movieImdbIds,
        ));
      }
    } catch (e, s) {
      _logger.w("Error loading movie IMDB id for ID $movieId", error: e, stackTrace: s);
    }
  }

  Future<void> _loadMovieBasicDetails(int movieId, Emitter<AppState> emit) async {
    try {
      final Movie? movie = await _tmdbService.getMovie(movieId);
      if (movie != null) {
        final String? trailerUrl = await _tmdbService.getTrailerUrl(MediaType.movies, movieId);
        final Movie updatedMovie = movie.copyWith(trailerUrl: trailerUrl);

        final List<Movie> movies = List<Movie>.from(state.movies ?? <Movie>[]);
        final int existingIndex = movies.indexWhere((Movie m) => m.id == movieId);

        if (existingIndex != -1) {
          movies[existingIndex] = updatedMovie;
        } else {
          movies.add(updatedMovie);
        }

        emit(state.copyWith(
          movies: movies,
        ));
      }
    } catch (e, s) {
      _logger.e("Error loading basic movie details for ID $movieId", error: e, stackTrace: s);
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
          final SearchResults? results = await _tmdbService.getRecommendations(MediaType.movies, movieId, pageKey);
          final List<Movie> movies = results?.movies ?? <Movie>[];
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
          final SearchResults? results = await _tmdbService.getSimilar(MediaType.movies, movieId, pageKey);
          final List<Movie> movies = results?.movies ?? <Movie>[];
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
    final List<Movie> movies = List<Movie>.from(state.movies ?? <Movie>[]);
    movies.removeWhere((Movie movie) => movie.id == event.movieId);

    Map<String, List<Person>> movieCast = Map<String, List<Person>>.from(state.movieCast ?? <String, List<Person>>{});
    movieCast.remove(event.movieId.toString());

    Map<String, PagingController<int, Movie>> recommendationsControllers = Map<String, PagingController<int, Movie>>.from(state.movieRecommendationsPagingControllers ?? <String, PagingController<int, Movie>>{});
    recommendationsControllers.remove(event.movieId.toString());

    Map<String, PagingController<int, Movie>> similarMoviesControllers = Map<String, PagingController<int, Movie>>.from(state.similarMoviesPagingControllers ?? <String, PagingController<int, Movie>>{});
    similarMoviesControllers.remove(event.movieId.toString());

    final Map<String, bool> loadingStatus = Map<String, bool>.from(state.isMovieLoading ?? <String, bool>{});
    loadingStatus[event.movieId.toString()] = false;

    emit(state.copyWith(
      movies: movies,
      movieCast: movieCast,
      movieRecommendationsPagingControllers: recommendationsControllers,
      similarMoviesPagingControllers: similarMoviesControllers,
      isMovieLoading: loadingStatus,
    ));

    add(LoadMovieDetails(event.movieId));
  }
}
