import "dart:math";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_audio.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/common_headers.dart";
import "package:semo/services/youtube_extractor_service/extractors/base_youtube_extractor.dart";
import "package:semo/services/youtube_extractor_service/extractors/utils/youtube_helpers.dart";

class PipedExtractor extends BaseYoutubeExtractor {
  PipedExtractor() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: false,
        responseBody: false,
        responseHeader: false,
        error: true,
        compact: true,
        enabled: kDebugMode,
      ),
    );
  }

  static const List<_StreamEndpoint> _streamEndpoints = <_StreamEndpoint>[
    _StreamEndpoint(
      urlTemplate: "https://api.piped.private.coffee/streams/{youtube_id}",
    ),
  ];

  final Random _random = Random();
  final Logger _logger = Logger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      headers: commonHeaders,
    ),
  );

  @override
  Future<List<MediaStream>> extractStreams(String youtubeUrl) async {
    final String trimmedUrl = youtubeUrl.trim();
    if (trimmedUrl.isEmpty) {
      return <MediaStream>[];
    }

    final Uri? normalizedYoutubeUri = normalizeYouTubeUri(trimmedUrl);
    if (normalizedYoutubeUri == null) {
      _logger.w("Failed to normalize YouTube URL for Piped extraction: $youtubeUrl");
      return <MediaStream>[];
    }

    final String? videoId = extractYouTubeVideoId(normalizedYoutubeUri);
    if (videoId == null || videoId.isEmpty) {
      _logger.w("Could not extract video ID from YouTube URL: ${normalizedYoutubeUri.toString()}");
      return <MediaStream>[];
    }

    final _StreamEndpoint endpoint = _selectStreamEndpoint();
    final Uri streamUri = endpoint.buildUri(videoId);

    try {
      final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>(streamUri.toString());

      final int? statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        _logger.w("Piped request failed with status $statusCode for video $videoId");
        return <MediaStream>[];
      }

      final Map<String, dynamic>? payload = response.data;
      if (payload == null || payload.isEmpty) {
        _logger.w("Received empty response from ${streamUri.host} for video $videoId");
        return <MediaStream>[];
      }

      final List<MediaStream> streams = _buildMediaStreams(payload);
      if (streams.isEmpty) {
        _logger.w("No suitable MP4 streams found on ${streamUri.host} for video $videoId");
      }

      return streams;
    } catch (error, stackTrace) {
      _logger.e("Failed to fetch Piped streams", error: error, stackTrace: stackTrace);
    }

    return <MediaStream>[];
  }

  List<MediaStream> _buildMediaStreams(Map<String, dynamic> payload) {
    final List<Map<String, Object?>> videoEntries = _extractEntries(payload["videoStreams"]);
    final List<Map<String, Object?>> audioEntries = _extractEntries(payload["audioStreams"]);

    if (videoEntries.isEmpty || audioEntries.isEmpty) {
      return <MediaStream>[];
    }

    final Map<String, Object?>? bestAudio = _selectBestAudio(audioEntries);
    if (bestAudio == null) {
      return <MediaStream>[];
    }

    final String? audioUrl = _asString(bestAudio["url"]);
    if (audioUrl == null || audioUrl.isEmpty) {
      return <MediaStream>[];
    }

    final StreamAudio externalAudio = StreamAudio(
      language: "Default",
      url: audioUrl,
      isDefault: false,
    );

    final List<MediaStream> streams = <MediaStream>[];
    for (final _ResolutionTarget target in _ResolutionTarget.targets) {
      final Map<String, Object?>? video = _selectBestVideo(videoEntries, target.height);
      if (video == null) {
        continue;
      }

      final String? videoUrl = _asString(video["url"]);
      if (videoUrl == null || videoUrl.isEmpty) {
        continue;
      }

      streams.add(
        MediaStream(
          type: StreamType.mp4,
          url: videoUrl,
          quality: _qualityLabelFor(video, target),
          audios: <StreamAudio>[externalAudio],
          hasDefaultAudio: false,
        ),
      );
    }

    return streams;
  }

  List<Map<String, Object?>> _extractEntries(Object? raw) {
    if (raw is List<Object?>) {
      return raw.whereType<Map<String, Object?>>().map((Map<String, Object?> entry) => Map<String, Object?>.from(entry)).toList();
    }

    return <Map<String, Object?>>[];
  }

  Map<String, Object?>? _selectBestAudio(List<Map<String, Object?>> entries) {
    Map<String, Object?>? best;
    int bestBitrate = -1;

    for (final Map<String, Object?> entry in entries) {
      final String? mimeType = _asString(entry["mimeType"]);
      if (mimeType == null || !mimeType.toLowerCase().contains("audio/mp4")) {
        continue;
      }

      final int bitrate = _asInt(entry["bitrate"]) ?? 0;
      if (bitrate > bestBitrate) {
        bestBitrate = bitrate;
        best = entry;
      }
    }

    return best;
  }

  Map<String, Object?>? _selectBestVideo(List<Map<String, Object?>> entries, int targetHeight) {
    Map<String, Object?>? best;
    int bestBitrate = -1;

    for (final Map<String, Object?> entry in entries) {
      final String? mimeType = _asString(entry["mimeType"]);
      if (mimeType == null || !mimeType.toLowerCase().contains("video/mp4")) {
        continue;
      }

      final bool videoOnly = (entry["videoOnly"] as bool?) ?? false;
      if (!videoOnly) {
        continue;
      }

      final int? height = _asInt(entry["height"]);
      if (height != targetHeight) {
        continue;
      }

      final int bitrate = _asInt(entry["bitrate"]) ?? 0;
      if (bitrate > bestBitrate) {
        bestBitrate = bitrate;
        best = entry;
      }
    }

    return best;
  }

  String _qualityLabelFor(Map<String, Object?> entry, _ResolutionTarget target) {
    final String? label = _asString(entry["quality"]);
    if (label == null || label.trim().isEmpty) {
      return target.label;
    }

    return label.trim();
  }

  _StreamEndpoint _selectStreamEndpoint() {
    if (_streamEndpoints.length == 1) {
      return _streamEndpoints.first;
    }

    final int index = _random.nextInt(_streamEndpoints.length);
    return _streamEndpoints[index];
  }

  String? _asString(Object? value) => value?.toString();

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}

class _ResolutionTarget {
  const _ResolutionTarget({
    required this.label,
    required this.height,
  });

  final String label;
  final int height;

  static const List<_ResolutionTarget> targets = <_ResolutionTarget>[
    _ResolutionTarget(label: "1080p", height: 1080),
    _ResolutionTarget(label: "720p", height: 720),
    _ResolutionTarget(label: "480p", height: 480),
    _ResolutionTarget(label: "360p", height: 360),
  ];
}

class _StreamEndpoint {
  const _StreamEndpoint({
    required this.urlTemplate,
  });

  final String urlTemplate;

  Uri buildUri(String videoId) {
    final String resolved = urlTemplate.replaceAll("{youtube_id}", videoId);
    return Uri.parse(resolved);
  }
}
