import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/bloc/handlers/helpers.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/services/recently_watched_service.dart";

mixin RecentlyWatchedHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  late final HandlerHelpers _helpers = HandlerHelpers(state);

  Future<void> onLoadRecentlyWatched(LoadRecentlyWatched event, Emitter<AppState> emit) async {
    if ((state.recentlyWatchedMovies != null && state.recentlyWatchedTvShows != null) || state.isLoadingRecentlyWatched) {
      return;
    }

    emit(state.copyWith(
      isLoadingRecentlyWatched: true,
      error: null,
    ));

    try {
      final Map<String, dynamic> recentlyWatched = await _recentlyWatchedService.getRecentlyWatched();

      final List<int> movieIds = await _recentlyWatchedService.getMovieIds(recentlyWatched: recentlyWatched);
      final List<int> tvShowIds = await _recentlyWatchedService.getTvShowIds(recentlyWatched: recentlyWatched);

      final List<Movie> recentlyWatchedMovies = await _helpers.fetchMoviesByIds(movieIds);
      final List<TvShow> recentlyWatchedTvShows = await _helpers.fetchTvShowsByIds(tvShowIds);

      emit(state.copyWith(
        recentlyWatched: recentlyWatched,
        recentlyWatchedMovies: recentlyWatchedMovies,
        recentlyWatchedTvShows: recentlyWatchedTvShows,
        isLoadingRecentlyWatched: false,
      ));
    } catch (e, s) {
      _logger.e("Error loading recently watched", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingRecentlyWatched: false,
        error: "Failed to load recently watched",
      ));
    }
  }

  Future<int?> onGetMovieProgress(GetMovieProgress event, Emitter<AppState> emit) async {
    try {
      int? progress = await _recentlyWatchedService.getMovieProgress(event.movieId, recentlyWatched: state.recentlyWatched);
      emit(state.copyWith(
        currentlyPlayingProgress: progress,
      ));
    } catch (e, s) {
      _logger.e("Error loading movie progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to load movie progress",
      ));
    }

    return null;
  }

  Future<void> onGetEpisodeProgress(GetEpisodeProgress event, Emitter<AppState> emit) async {
    try {
      int? progress = await _recentlyWatchedService.getEpisodeProgress(
        event.tvShowId,
        event.seasonId,
        event.episodeId,
        recentlyWatched: state.recentlyWatched,
      );
      emit(state.copyWith(
        currentlyPlayingProgress: progress,
      ));
    } catch (e, s) {
      _logger.e("Error loading episode progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to load episode progress",
      ));
    }
  }

  Future<void> onUpdateMovieProgress(UpdateMovieProgress event, Emitter<AppState> emit) async {
    try {
      final Map<String, dynamic> updatedRecentlyWatched = await _recentlyWatchedService.updateMovieProgress(event.movieId, event.progress, recentlyWatched: state.recentlyWatched);
      final List<Movie> updatedRecentlyWatchedMovies = state.recentlyWatchedMovies ?? <Movie>[];

      if (state.recentlyWatchedMovies != null && !state.recentlyWatchedMovies!.any((Movie movie) => movie.id == event.movieId)) {
        final Movie movie = await _helpers.fetchMovieById(event.movieId);
        updatedRecentlyWatchedMovies.add(movie);
      }

      emit(state.copyWith(
        recentlyWatched: updatedRecentlyWatched,
        recentlyWatchedMovies: updatedRecentlyWatchedMovies,
      ));
    } catch (e, s) {
      _logger.e("Error updating movie progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to update movie progress",
      ));
    }
  }

  Future<void> onUpdateEpisodeProgress(UpdateEpisodeProgress event, Emitter<AppState> emit) async {
    try {
      final Map<String, dynamic> updatedRecentlyWatched = await _recentlyWatchedService.updateEpisodeProgress(
        event.tvShowId,
        event.seasonId,
        event.episodeId,
        event.progress,
        recentlyWatched: state.recentlyWatched,
      );
      final List<TvShow> updatedRecentlyWatchedTvShows = state.recentlyWatchedTvShows ?? <TvShow>[];

      if (state.recentlyWatchedTvShows != null && !state.recentlyWatchedTvShows!.any((TvShow tvShow) => tvShow.id == event.tvShowId)) {
        final TvShow tvShow = await _helpers.fetchTvShowById(event.tvShowId);
        updatedRecentlyWatchedTvShows.add(tvShow);
      }

      emit(state.copyWith(
        recentlyWatched: updatedRecentlyWatched,
        recentlyWatchedTvShows: updatedRecentlyWatchedTvShows,
      ));
    } catch (e, s) {
      _logger.e("Error updating episode progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to update episode progress",
      ));
    }
  }

  Future<void> onDeleteMovieProgress(DeleteMovieProgress event, Emitter<AppState> emit) async {
    try {
      final Map<String, dynamic> updatedRecentlyWatched = await _recentlyWatchedService.removeMovie(event.movieId, recentlyWatched: state.recentlyWatched);
      final List<Movie> updatedRecentlyWatchedMovies = state.recentlyWatchedMovies?.where((Movie movie) => movie.id != event.movieId).toList() ?? <Movie>[];

      emit(state.copyWith(
        recentlyWatched: updatedRecentlyWatched,
        recentlyWatchedMovies: updatedRecentlyWatchedMovies,
      ));
    } catch (e, s) {
      _logger.e("Error deleting movie progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to delete movie progress",
      ));
    }
  }

  Future<void> onDeleteEpisodeProgress(DeleteEpisodeProgress event, Emitter<AppState> emit) async {
    try {
      final Map<String, dynamic> updatedRecentlyWatched = await _recentlyWatchedService.removeEpisodeProgress(
        event.tvShowId,
        event.seasonId,
        event.episodeId,
        recentlyWatched: state.recentlyWatched,
      );
      final List<TvShow> updatedRecentlyWatchedTvShows = state.recentlyWatchedTvShows?.where((TvShow tvShow) => tvShow.id != event.tvShowId).toList() ?? <TvShow>[];

      emit(state.copyWith(
        recentlyWatched: updatedRecentlyWatched,
        recentlyWatchedTvShows: updatedRecentlyWatchedTvShows,
      ));
    } catch (e, s) {
      _logger.e("Error deleting episode progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to delete episode progress",
      ));
    }
  }

  Future<void> onDeleteTvShowProgress(DeleteTvShowProgress event, Emitter<AppState> emit) async {
    try {
      final Map<String, dynamic> updatedRecentlyWatched = await _recentlyWatchedService.removeTvShow(
        event.tvShowId,
        recentlyWatched: state.recentlyWatched,
      );
      final List<TvShow> updatedRecentlyWatchedTvShows = state.recentlyWatchedTvShows?.where((TvShow tvShow) => tvShow.id != event.tvShowId).toList() ?? <TvShow>[];

      emit(state.copyWith(
        recentlyWatched: updatedRecentlyWatched,
        recentlyWatchedTvShows: updatedRecentlyWatchedTvShows,
      ));
    } catch (e, s) {
      _logger.e("Error deleting TV show progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to delete TV show progress",
      ));
    }
  }

  Future<void> onHideTvShowProgress(HideTvShowProgress event, Emitter<AppState> emit) async {
    try {
      final Map<String, dynamic> updatedRecentlyWatched = await _recentlyWatchedService.hideTvShow(
        event.tvShowId,
        recentlyWatched: state.recentlyWatched,
      );
      final List<TvShow> updatedRecentlyWatchedTvShows = state.recentlyWatchedTvShows?.where((TvShow tvShow) => tvShow.id != event.tvShowId).toList() ?? <TvShow>[];

      emit(state.copyWith(
        recentlyWatched: updatedRecentlyWatched,
        recentlyWatchedTvShows: updatedRecentlyWatchedTvShows,
      ));
    } catch (e, s) {
      _logger.e("Error hiding TV show progress", error: e, stackTrace: s);
      emit(state.copyWith(
        error: "Failed to hide TV show progress",
      ));
    }
  }
}