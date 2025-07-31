import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/models/movie.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/tmdb_service.dart";

mixin PersonHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadPersonMedia(LoadPersonMedia event, Emitter<AppState> emit) async {
    final String personId = event.personId.toString();
    final bool isPersonMediaLoading = state.isLoadingPersonMedia?[personId] == true;

    if (isPersonMediaLoading) {
      return;
    }

    final bool isPersonMoviesLoaded = state.personMovies?.containsKey(personId) ?? false;
    final bool isPersonTvShowsLoaded = state.personTvShows?.containsKey(personId) ?? false;
    final Map<String, bool> updatedLoadingStatus = Map<String, bool>.from(state.isLoadingPersonMedia ?? <String, bool>{});

    if (isPersonMoviesLoaded && isPersonTvShowsLoaded) {
      updatedLoadingStatus[personId] = false;
      emit(state.copyWith(
        isLoadingPersonMedia: updatedLoadingStatus,
        error: null,
      ));
      return;
    }

    updatedLoadingStatus[personId] = true;

    emit(state.copyWith(
      isLoadingPersonMedia: updatedLoadingStatus,
      error: null,
    ));

    try {
      Map<String, List<Movie>> personMovies = state.personMovies ?? <String, List<Movie>>{};
      Map<String, List<TvShow>> personTvShows = state.personTvShows ?? <String, List<TvShow>>{};

      final List<Movie> movies = await _tmdbService.getPersonMovies(event.personId);
      final List<TvShow> tvShows = await _tmdbService.getPersonTvShows(event.personId);

      personMovies[personId] = movies;
      personTvShows[personId] = tvShows;

      updatedLoadingStatus[personId] = false;

      emit(state.copyWith(
        personMovies: personMovies,
        personTvShows: personTvShows,
        isLoadingPersonMedia: updatedLoadingStatus,
      ));
    } catch (e, s) {
      _logger.e("Error loading person media", error: e, stackTrace: s);

      updatedLoadingStatus[personId] = false;
      emit(state.copyWith(
        isLoadingPersonMedia: updatedLoadingStatus,
        error: "Failed to load media",
      ));
    }
  }
}