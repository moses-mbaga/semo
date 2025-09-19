import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";

abstract class BaseStreamExtractor {
  List<MediaType> get acceptedMediaTypes;
  bool get needsExternalLink;
  Future<Map<String, Object?>?> getExternalLink(StreamExtractorOptions options);

  // New multi-stream API. For now, implementations should return at most one.
  Future<List<MediaStream>> getStreams(
    StreamExtractorOptions options, {
    String? externalLink,
    Map<String, String>? externalLinkHeaders,
  });
}
