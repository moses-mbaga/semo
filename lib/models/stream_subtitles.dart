import "package:semo/enums/subtitles_type.dart";

class StreamSubtitles {
  const StreamSubtitles({
    required this.name,
    required this.language,
    required this.url,
    required this.type,
  });

  final String name;
  final String language;
  final String url;
  final SubtitlesType type;
}
