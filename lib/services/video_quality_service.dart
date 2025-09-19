import "dart:async";

import "package:flutter/widgets.dart";
import "package:video_player/video_player.dart";

import "package:semo/enums/stream_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/services/stream_extractor_service/extractors/utils/closest_resolution.dart";

class VideoQualityService {
  const VideoQualityService();

  Future<String?> determineQuality(MediaStream stream) async {
    VideoPlayerController? controller;

    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(stream.url),
        httpHeaders: stream.headers ?? <String, String>{},
        formatHint: stream.type == StreamType.hls ? VideoFormat.hls : VideoFormat.other,
        closedCaptionFile: null,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      await controller.play();

      const Duration delayBetweenChecks = Duration(milliseconds: 100);
      const int maxAttempts = 20;

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final Size size = controller.value.size;

        if (size.width > 0 && size.height > 0) {
          await controller.pause();
          return getClosestResolutionFromDimensions(size.width.round(), size.height.round());
        }

        await Future<void>.delayed(delayBetweenChecks);
      }
    } catch (_) {
      return null;
    } finally {
      if (controller != null) {
        try {
          await controller.pause();
        } catch (_) {}

        try {
          await controller.dispose();
        } catch (_) {}
      }
    }

    return null;
  }
}
