import "package:semo/enums/stream_type.dart";

class MediaStream {
  MediaStream({
    required this.type,
    required this.url,
    this.headers,
    this.subtitles,
    this.audios,
  });

  final StreamType type;
  final String url;
  final Map<String, String>? headers;
  final List<Map<String, String>>? subtitles;
  final List<Map<String, String>>? audios;
}
