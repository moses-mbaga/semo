import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/services/stream_extractor_service/stream_extractor_service.dart";

mixin StreamHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();

  Future<void> onExtractMovieStream(ExtractMovieStream event, Emitter<AppState> emit) async {
    final String movieId = event.movie.id.toString();
    final bool isExtractingMovieStream = state.isExtractingMovieStream?[movieId] == true;

    if (isExtractingMovieStream) {
      return;
    }

    final bool isStreamExtracted = state.movieStreams?.containsKey(movieId) ?? false;
    final Map<String, bool> updatedExtractingStatus = Map<String, bool>.from(state.isExtractingMovieStream ?? <String, bool>{});

    if (isStreamExtracted) {
      updatedExtractingStatus[movieId] = false;
      emit(state.copyWith(
        isExtractingMovieStream: updatedExtractingStatus,
        error: null,
      ));
      return;
    }

    updatedExtractingStatus[movieId] = true;

    emit(state.copyWith(
      isExtractingMovieStream: updatedExtractingStatus,
      error: null,
    ));

    try {
      final String? imdbId = state.movieImdbIds?[movieId];
      final MediaStream? stream = await StreamExtractorService.getStream(movie: event.movie, imdbId: imdbId);

      if (stream == null || stream.url.isEmpty) {
        throw Exception("Stream is null");
      }

      final Map<String, MediaStream> updatedStreams = Map<String, MediaStream>.from(state.movieStreams ?? <String, MediaStream>{});
      updatedStreams[movieId] = stream;

      updatedExtractingStatus[movieId] = false;
      emit(state.copyWith(
        isExtractingMovieStream: updatedExtractingStatus,
        movieStreams: updatedStreams,
      ));
    } catch (e, s) {
      _logger.e("Error extracting stream for ID ${event.movie.id}", error: e, stackTrace: s);

      updatedExtractingStatus[movieId] = false;
      emit(state.copyWith(
        isExtractingMovieStream: updatedExtractingStatus,
        error: "Failed to extract stream",
      ));
    }
  }

  Future<void> onExtractEpisodeStream(ExtractEpisodeStream event, Emitter<AppState> emit) async {
    final String episodeId = event.episode.id.toString();
    final bool isExtractingEpisodeStream = state.isExtractingEpisodeStream?[episodeId] == true;

    if (isExtractingEpisodeStream) {
      return;
    }

    final bool isStreamExtracted = state.episodeStreams?.containsKey(episodeId) ?? false;
    final Map<String, bool> updatedExtractingStatus = Map<String, bool>.from(state.isExtractingEpisodeStream ?? <String, bool>{});

    if (isStreamExtracted) {
      updatedExtractingStatus[episodeId] = false;
      emit(state.copyWith(
        isExtractingEpisodeStream: updatedExtractingStatus,
        error: null,
      ));
      return;
    }

    updatedExtractingStatus[episodeId] = true;

    emit(state.copyWith(
      isExtractingEpisodeStream: updatedExtractingStatus,
      error: null,
    ));

    try {
      final String? imdbId = state.tvShowImdbIds?[event.tvShow.id.toString()];
      final MediaStream? stream = await StreamExtractorService.getStream(
        tvShow: event.tvShow,
        episode: event.episode,
        imdbId: imdbId,
      );

      if (stream == null || stream.url.isEmpty) {
        throw Exception("Stream is null");
      }

      final Map<String, MediaStream> updatedStreams = Map<String, MediaStream>.from(state.episodeStreams ?? <String, MediaStream>{});
      updatedStreams[episodeId] = stream;

      updatedExtractingStatus[episodeId] = false;
      emit(state.copyWith(
        isExtractingEpisodeStream: updatedExtractingStatus,
        episodeStreams: updatedStreams,
      ));
    } catch (e, s) {
      _logger.e("Error extracting stream for ID ${event.episode.id}", error: e, stackTrace: s);

      updatedExtractingStatus[episodeId] = false;
      emit(state.copyWith(
        isExtractingEpisodeStream: updatedExtractingStatus,
        error: "Failed to extract stream",
      ));
    }
  }

  void onRemoveMovieStream(RemoveMovieStream event, Emitter<AppState> emit) {
    final String movieId = event.movieId.toString();
    final Map<String, MediaStream> updatedStreams = Map<String, MediaStream>.from(state.movieStreams ?? <String, MediaStream>{});
    updatedStreams.remove(movieId);

    emit(state.copyWith(
      movieStreams: updatedStreams,
    ));
  }

  void onRemoveEpisodeStream(RemoveEpisodeStream event, Emitter<AppState> emit) {
    final String episodeId = event.episodeId.toString();
    final Map<String, MediaStream> updatedStreams = Map<String, MediaStream>.from(state.episodeStreams ?? <String, MediaStream>{});
    updatedStreams.remove(episodeId);

    emit(state.copyWith(
      episodeStreams: updatedStreams,
    ));
  }
}
