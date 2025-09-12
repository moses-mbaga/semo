import "dart:core";

class HlsVariantStream {
  const HlsVariantStream({
    required this.uri,
    this.width,
    this.height,
    this.bandwidth,
    this.codecs,
  });

  final Uri uri;
  final int? width;
  final int? height;
  final int? bandwidth;
  final String? codecs;
}
