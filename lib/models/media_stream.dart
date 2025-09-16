import "package:semo/enums/stream_type.dart";
import "package:semo/models/stream_subtitles.dart";

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
  final List<StreamSubtitles>? subtitles;
  final List<Map<String, String>>? audios;
}
