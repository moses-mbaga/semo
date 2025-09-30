import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/models/stream_subtitles.dart";
import "package:semo/services/subtitles_service.dart";
import "package:semo/services/streams_extractor_service/streams_extractor_service.dart";

mixin StreamHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final StreamsExtractorService _streamsExtractorService = StreamsExtractorService();
  final SubtitlesService _subtitlesService = SubtitlesService();

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
      final StreamExtractorOptions options = StreamExtractorOptions(
        tmdbId: event.movie.id,
        title: event.movie.title,
        releaseYear: (event.movie.releaseDate.isNotEmpty ? event.movie.releaseDate.split("-")[0] : null),
        imdbId: imdbId,
      );

      final Future<List<MediaStream>> streamsFuture = _streamsExtractorService.getStreams(options);
      Future<List<StreamSubtitles>> subtitlesFuture = Future<List<StreamSubtitles>>.value(<StreamSubtitles>[]);
      if (imdbId != null && imdbId.isNotEmpty) {
        subtitlesFuture = _subtitlesService.getSubtitles(imdbId: imdbId).catchError((Object? _) => <StreamSubtitles>[]);
      }

      final List<MediaStream> baseStreams = await streamsFuture;
      final List<StreamSubtitles> subtitles = await subtitlesFuture;

      if (baseStreams.isEmpty) {
        throw Exception("No streams returned");
      }

      final List<MediaStream> enrichedStreams = _attachSubtitles(baseStreams, subtitles);

      final Map<String, List<MediaStream>> updatedStreams = Map<String, List<MediaStream>>.from(state.movieStreams ?? <String, List<MediaStream>>{});
      updatedStreams[movieId] = enrichedStreams;

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
      final StreamExtractorOptions options = StreamExtractorOptions(
        tmdbId: event.tvShow.id,
        season: event.episode.season,
        episode: event.episode.number,
        title: event.tvShow.name,
        imdbId: imdbId,
      );

      final Future<List<MediaStream>> streamsFuture = _streamsExtractorService.getStreams(options);
      Future<List<StreamSubtitles>> subtitlesFuture = Future<List<StreamSubtitles>>.value(<StreamSubtitles>[]);
      if (imdbId != null && imdbId.isNotEmpty) {
        subtitlesFuture = _subtitlesService
            .getSubtitles(
              imdbId: imdbId,
              seasonNumber: event.episode.season,
              episodeNumber: event.episode.number,
            )
            .catchError((Object? _) => <StreamSubtitles>[]);
      }

      final List<MediaStream> baseStreams = await streamsFuture;
      final List<StreamSubtitles> subtitles = await subtitlesFuture;

      if (baseStreams.isEmpty) {
        throw Exception("No streams returned");
      }

      final List<MediaStream> enrichedStreams = _attachSubtitles(baseStreams, subtitles);
      final Map<String, List<MediaStream>> updatedStreams = Map<String, List<MediaStream>>.from(state.episodeStreams ?? <String, List<MediaStream>>{});
      updatedStreams[episodeId] = enrichedStreams;

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
    final Map<String, List<MediaStream>> updatedStreams = Map<String, List<MediaStream>>.from(state.movieStreams ?? <String, List<MediaStream>>{});
    updatedStreams.remove(movieId);

    emit(state.copyWith(
      movieStreams: updatedStreams,
    ));
  }

  void onRemoveEpisodeStream(RemoveEpisodeStream event, Emitter<AppState> emit) {
    final String episodeId = event.episodeId.toString();
    final Map<String, List<MediaStream>> updatedStreams = Map<String, List<MediaStream>>.from(state.episodeStreams ?? <String, List<MediaStream>>{});
    updatedStreams.remove(episodeId);

    emit(state.copyWith(
      episodeStreams: updatedStreams,
    ));
  }

  List<MediaStream> _attachSubtitles(List<MediaStream> streams, List<StreamSubtitles> subtitles) {
    if (streams.isEmpty) {
      return streams;
    }

    return streams.map(
      (MediaStream stream) {
        final List<StreamSubtitles> existing = stream.subtitles ?? <StreamSubtitles>[];

        return MediaStream(
          type: stream.type,
          url: stream.url,
          headers: stream.headers,
          quality: stream.quality,
          subtitles: subtitles.isEmpty ? existing : subtitles,
          audios: stream.audios,
          hasDefaultAudio: stream.hasDefaultAudio,
        );
      },
    ).toList();
  }
}
