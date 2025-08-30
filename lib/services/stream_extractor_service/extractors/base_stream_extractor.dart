import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_extractor_options.dart";

abstract class BaseStreamExtractor {
  Future<String?> getExternalLink(StreamExtractorOptions options);
  Future<MediaStream?> getStream(String externalLink, StreamExtractorOptions options);
}
