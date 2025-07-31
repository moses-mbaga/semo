import "package:index/models/media_stream.dart";
import "package:index/models/stream_extractor_options.dart";

abstract class BaseStreamExtractor {
  Future<MediaStream?> getStream(StreamExtractorOptions options);
}