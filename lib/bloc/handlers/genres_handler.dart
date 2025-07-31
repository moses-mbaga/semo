import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/enums/media_type.dart";
import "package:index/models/genre.dart";
import "package:index/models/movie.dart";
import "package:index/models/search_results.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/tmdb_service.dart";

mixin GenresHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadGenres(LoadGenres event, Emitter<AppState> emit) async {
    if (event.mediaType == MediaType.movies) {
      if (state.movieGenres != null && state.movieGenres!.isNotEmpty) {
        return;
      }

      emit(state.copyWith(
        isLoadingMovieGenres: true,
        error: null,
      ));

      final Map<String, PagingController<int, Movie>> movieControllers = <String, PagingController<int, Movie>>{};

      try {
        final List<Genre> genres = await _tmdbService.getMovieGenres();

        for (final Genre genre in genres) {
          movieControllers[genre.id.toString()] = PagingController<int, Movie>(
            getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
            fetchPage: (int pageKey) async {
              final SearchResults results = await _tmdbService.discoverMovies(
                pageKey,
                parameters: <String, String>{
                  "with_genres": genre.id.toString(),
                },
              );
              final List<Movie> movies = results.movies ?? <Movie>[];
              add(AddIncompleteMovies(movies));
              return movies;
            },
          );
        }

        emit(state.copyWith(
          movieGenres: genres,
          genreMoviesPagingControllers: movieControllers,
          isLoadingMovieGenres: false,
        ));
      } catch (e, s) {
        _logger.e("Error loading movie genres", error: e, stackTrace: s);
        emit(state.copyWith(
          isLoadingMovieGenres: false,
          error: "Failed to load movie genres",
        ));
      }
    } else if (event.mediaType == MediaType.tvShows) {
      if (state.tvShowGenres != null &&  state.tvShowGenres!.isNotEmpty) {
        return;
      }

      emit(state.copyWith(
        isLoadingTvShowGenres: true,
        error: null,
      ));

      final Map<String, PagingController<int, TvShow>> tvShowControllers = <String, PagingController<int, TvShow>>{};

      try {
        final List<Genre> genres = await _tmdbService.getTvShowGenres();

        for (final Genre genre in genres) {
          tvShowControllers[genre.id.toString()] = PagingController<int, TvShow>(
            getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
            fetchPage: (int pageKey) async {
              final SearchResults results = await _tmdbService.discoverTvShows(
                pageKey,
                parameters: <String, String>{
                  "with_genres": genre.id.toString(),
                },
              );
              final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
              add(AddIncompleteTvShows(tvShows));
              return tvShows;
            },
          );
        }

        emit(state.copyWith(
          tvShowGenres: genres,
          genreTvShowsPagingControllers: tvShowControllers,
          isLoadingTvShowGenres: false,
        ));
      } catch (e, s) {
        _logger.e("Error loading TV show genres", error: e, stackTrace: s);
        emit(state.copyWith(
          isLoadingTvShowGenres: false,
          error: "Failed to load TV show genres",
        ));
      }
    }
  }

  void onRefreshGenres(RefreshGenres event, Emitter<AppState> emit) {
    if (event.mediaType == MediaType.movies) {
      state.genreMoviesPagingControllers?.forEach((String platformId, PagingController<int, Movie> controller) {
        controller.refresh();
      });

      emit(state.copyWith(
        movieGenres: <Genre>[],
        isLoadingMovieGenres: false,
      ));
    } else if (event.mediaType == MediaType.tvShows) {
      state.genreTvShowsPagingControllers?.forEach((String platformId, PagingController<int, TvShow> controller) {
        controller.refresh();
      });

      emit(state.copyWith(
        tvShowGenres: <Genre>[],
        isLoadingTvShowGenres: false,
      ));
    }

    add(LoadGenres(event.mediaType));
  }
}