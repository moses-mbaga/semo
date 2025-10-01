import "package:logger/logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/services/youtube_extractor_service/extractors/base_youtube_extractor.dart";
import "package:semo/services/youtube_extractor_service/extractors/invidious_extractor.dart";
import "package:semo/services/youtube_extractor_service/extractors/piped_extractor.dart";
import "package:semo/services/youtube_extractor_service/extractors/poke_extractor.dart";

class YoutubeExtractorService {
  factory YoutubeExtractorService() => _instance;

  YoutubeExtractorService._internal();

  static final YoutubeExtractorService _instance = YoutubeExtractorService._internal();

  final Logger _logger = Logger();
  final List<BaseYoutubeExtractor> _extractors = <BaseYoutubeExtractor>[
    PokeExtractor(),
    PipedExtractor(),
    InvidiousExtractor(),
  ];

  Future<List<MediaStream>> getStreams(String youtubeUrl) async {
    final String trimmedUrl = youtubeUrl.trim();
    if (trimmedUrl.isEmpty) {
      return <MediaStream>[];
    }

    for (final BaseYoutubeExtractor extractor in _extractors) {
      final List<MediaStream> streams = <MediaStream>[];

      try {
        streams.addAll(await extractor.extractStreams(trimmedUrl));
      } catch (e, s) {
        _logger.e("Failed to extract streams", error: e, stackTrace: s);
      }

      if (streams.isNotEmpty) {
        _logger.i("Streams found.\nExtractor: ${extractor.toString()}\nCount: ${streams.length}");
        return streams;
      }
    }

    return <MediaStream>[];
  }
}
