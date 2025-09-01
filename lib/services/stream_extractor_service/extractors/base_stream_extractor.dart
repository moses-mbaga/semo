import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";

abstract class BaseStreamExtractor {
  List<MediaType> get acceptedMediaTypes;
  bool get needsExternalLink;
  Future<String?> getExternalLink(StreamExtractorOptions options);
  Future<MediaStream?> getStream(String? externalLink, StreamExtractorOptions options);
}
