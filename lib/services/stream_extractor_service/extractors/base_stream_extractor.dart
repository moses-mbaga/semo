import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_extractor_options.dart";

abstract class BaseStreamExtractor {
  Future<MediaStream?> getStream(StreamExtractorOptions options);
}