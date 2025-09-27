import "dart:async";

import "package:media_kit/media_kit.dart";

import "package:semo/models/media_stream.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/closest_resolution.dart";

class VideoQualityService {
  const VideoQualityService();

  Future<String?> determineQuality(MediaStream stream) async {
    Player? player;

    try {
      player = Player();
      await player.open(
        Media(
          stream.url,
          httpHeaders: stream.headers ?? <String, String>{},
        ),
        play: false,
      );

      const Duration delayBetweenChecks = Duration(milliseconds: 100);
      const int maxAttempts = 20;

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final int? width = player.state.width;
        final int? height = player.state.height;

        if ((width ?? 0) > 0 && (height ?? 0) > 0) {
          return getClosestResolutionFromDimensions(width!, height!);
        }

        await Future<void>.delayed(delayBetweenChecks);
      }
    } catch (_) {
      return null;
    } finally {
      if (player != null) {
        try {
          await player.stop();
        } catch (_) {}
        await player.dispose();
      }
    }

    return null;
  }
}
