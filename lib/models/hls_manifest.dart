import "dart:core";

import "package:semo/models/hls_audio_rendition.dart";
import "package:semo/models/hls_subtitle_rendition.dart";
import "package:semo/models/hls_variant_stream.dart";

class HlsManifest {
  const HlsManifest({
    required this.variants,
    required this.audios,
    required this.subtitles,
  });

  final List<HlsVariantStream> variants;
  final List<HlsAudioRendition> audios;
  final List<HlsSubtitleRendition> subtitles;

  bool get isEmpty => variants.isEmpty && audios.isEmpty && subtitles.isEmpty;
}
