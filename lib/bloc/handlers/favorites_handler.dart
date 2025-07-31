import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/bloc/handlers/helpers.dart";
import "package:index/enums/media_type.dart";
import "package:index/models/movie.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/favorites_service.dart";

mixin FavoritesHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final FavoritesService _favoritesService = FavoritesService();
  late final HandlerHelpers _helpers = HandlerHelpers();

  Future<void> onLoadFavorites(LoadFavorites event, Emitter<AppState> emit) async {
    if ((state.favoriteMovies != null && state.favoriteTvShows != null) || state.isLoadingFavorites) {
      return;
    }

    emit(state.copyWith(
      isLoadingFavorites: true,
      error: null,
    ));

    try {
      final Map<String, List<int>> favorites = _convertToIntListMap(await _favoritesService.getFavorites());

      final List<int> movieIds = favorites[MediaType.movies.toJsonField()] ?? <int>[];
      final List<int> tvShowIds = favorites[MediaType.tvShows.toJsonField()] ?? <int>[];

      final List<Movie> favoriteMovies = await _helpers.fetchMoviesByIds(state, movieIds);
      final List<TvShow> favoriteTvShows = await _helpers.fetchTvShowsByIds(state, tvShowIds);

      emit(state.copyWith(
        favorites: favorites,
        favoriteMovies: favoriteMovies,
        favoriteTvShows: favoriteTvShows,
        isLoadingFavorites: false,
      ));
    } catch (e, s) {
      _logger.e("Error loading favorites", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingFavorites: false,
        error: "Failed to load favorites",
      ));
    }
  }

  // ignore: avoid_annotating_with_dynamic
  Future<dynamic> _addFavorite(dynamic media, MediaType mediaType) async {
    try {
      final int id = _getMediaId(media);
      if (mediaType == MediaType.movies) {
        await _favoritesService.addMovie(id, allFavorites: state.favorites);
      } else if (mediaType == MediaType.tvShows) {
        await _favoritesService.addTvShow(id, allFavorites: state.favorites);
      }
    } catch (e, s) {
      _logger.e("Error adding favorite", error: e, stackTrace: s);
      rethrow;
    }
  }

  void onAddFavorite(AddFavorite event, Emitter<AppState> emit) {
    final int mediaId = _getMediaId(event.media);

    if (event.mediaType == MediaType.movies) {
      final List<Movie> currentFavoriteMovies = List<Movie>.from(state.favoriteMovies ?? <Movie>[]);

      if (currentFavoriteMovies.any((Movie movie) => movie.id == mediaId)) {
        return;
      }

      if (event.media is Movie) {
        currentFavoriteMovies.add(event.media as Movie);

        try {
          unawaited(_addFavorite(event.media, event.mediaType));
        } catch (_) {}

        emit(state.copyWith(favoriteMovies: currentFavoriteMovies));
      }
    } else if (event.mediaType == MediaType.tvShows) {
      final List<TvShow> currentFavoriteTvShows = List<TvShow>.from(state.favoriteTvShows ?? <TvShow>[]);

      if (currentFavoriteTvShows.any((TvShow tvShow) => tvShow.id == mediaId)) {
        return;
      }

      if (event.media is TvShow) {
        currentFavoriteTvShows.add(event.media as TvShow);

        try {
          unawaited(_addFavorite(event.media, event.mediaType));
        } catch (_) {}

        emit(state.copyWith(favoriteTvShows: currentFavoriteTvShows));
      }
    }
  }

  // ignore: avoid_annotating_with_dynamic
  Future<dynamic> _removeFavorite(dynamic media, MediaType mediaType) async {
    try {
      final int id = _getMediaId(media);
      if (mediaType == MediaType.movies) {
        await _favoritesService.removeMovie(id, allFavorites: state.favorites);
      } else if (mediaType == MediaType.tvShows) {
        await _favoritesService.removeTvShow(id, allFavorites: state.favorites);
      }
    } catch (e, s) {
      _logger.e("Error removing favorite", error: e, stackTrace: s);
      rethrow;
    }
  }

  void onRemoveFavorite(RemoveFavorite event, Emitter<AppState> emit) {
    final int mediaId = _getMediaId(event.media);

    if (event.mediaType == MediaType.movies) {
      final List<Movie> currentFavoriteMovies = List<Movie>.from(state.favoriteMovies ?? <Movie>[]);

      currentFavoriteMovies.removeWhere((Movie movie) => movie.id == mediaId);

      try {
        unawaited(_removeFavorite(event.media, event.mediaType));
      } catch (_) {}

      emit(state.copyWith(favoriteMovies: currentFavoriteMovies));
    } else if (event.mediaType == MediaType.tvShows) {
      final List<TvShow> currentFavoriteTvShows = List<TvShow>.from(state.favoriteTvShows ?? <TvShow>[]);

      currentFavoriteTvShows.removeWhere((TvShow tvShow) => tvShow.id == mediaId);

      try {
        unawaited(_removeFavorite(event.media, event.mediaType));
      } catch (_) {}

      emit(state.copyWith(favoriteTvShows: currentFavoriteTvShows));
    }
  }

  void onClearFavorites(ClearFavorites event, Emitter<AppState> emit) {
    try {
      unawaited(_favoritesService.clear());
    } catch (e, s) {
      _logger.e("Error clearing favorites", error: e, stackTrace: s);
    }

    emit(state.copyWith(
      favorites: <String, List<int>>{},
      favoriteMovies: <Movie>[],
      favoriteTvShows: <TvShow>[],
      isLoadingFavorites: false,
    ));
  }

  // ignore: avoid_annotating_with_dynamic
  int _getMediaId(dynamic media) {
    if (media is Movie) {
      return media.id;
    } else if (media is TvShow) {
      return media.id;
    } else {
      throw Exception("Invalid media type: ${media.runtimeType}");
    }
  }

  // ignore: prefer_expression_function_bodies
  Map<String, List<int>> _convertToIntListMap(Map<String, dynamic> favorites) {
    // ignore: avoid_annotating_with_dynamic
    return favorites.map((String key, dynamic value) => MapEntry<String, List<int>>(key, List<int>.from(value)));
  }
}