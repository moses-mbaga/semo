import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/services/youtube_extractor_service/youtube_extractor_service.dart";

mixin TrailerHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final YoutubeExtractorService _youtubeExtractorService = YoutubeExtractorService();

  String _buildTrailerKey(MediaType mediaType, int tmdbId) => "${mediaType.toJsonField()}_$tmdbId";

  Future<void> onExtractTrailerStreams(ExtractTrailerStreams event, Emitter<AppState> emit) async {
    final String key = _buildTrailerKey(event.mediaType, event.tmdbId);

    if (state.isExtractingTrailerStream?[key] == true) {
      return;
    }

    final Map<String, bool> extractingMap = Map<String, bool>.from(state.isExtractingTrailerStream ?? <String, bool>{});
    extractingMap[key] = true;

    emit(
      state.copyWith(
        isExtractingTrailerStream: extractingMap,
        error: null,
      ),
    );

    try {
      final List<MediaStream> streams = await _youtubeExtractorService.getStreams(event.trailerUrl);
      final Map<String, List<MediaStream>> trailerStreams = Map<String, List<MediaStream>>.from(state.trailerStreams ?? <String, List<MediaStream>>{});

      trailerStreams[key] = List<MediaStream>.from(streams);
      extractingMap[key] = false;

      emit(
        state.copyWith(
          trailerStreams: trailerStreams,
          isExtractingTrailerStream: extractingMap,
        ),
      );
    } catch (e, s) {
      extractingMap[key] = false;
      _logger.w("Failed to retrieve trailer streams for TMDB ID ${event.tmdbId}", error: e, stackTrace: s);

      emit(
        state.copyWith(
          isExtractingTrailerStream: extractingMap,
        ),
      );
    }
  }
}
