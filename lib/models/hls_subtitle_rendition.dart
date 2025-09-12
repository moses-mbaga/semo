import "dart:core";

class HlsSubtitleRendition {
  const HlsSubtitleRendition({
    required this.name,
    this.language,
    required this.isDefault,
    required this.isAutoselect,
    this.uri,
  });

  final String name;
  final String? language;
  final bool isDefault;
  final bool isAutoselect;
  final Uri? uri;
}
