import "package:semo/enums/stream_type.dart";

class MediaStream {
  MediaStream({
    required this.type,
    this.url = "",
    this.headers = const <String, String>{},
  });

  final StreamType type;
  final String url;
  final Map<String, String> headers;
}
