import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";

class StreamingServer {
  const StreamingServer({
    required this.name,
    required this.extractor,
  });

  final String name;
  final BaseStreamExtractor? extractor;
}
