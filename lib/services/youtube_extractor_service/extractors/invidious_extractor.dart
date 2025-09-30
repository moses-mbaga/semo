import "dart:math";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/services/youtube_extractor_service/extractors/base_youtube_extractor.dart";
import "package:semo/services/youtube_extractor_service/extractors/utils/youtube_helpers.dart";

class InvidiousExtractor extends BaseYoutubeExtractor {
  InvidiousExtractor() {
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

  static const List<_ManifestEndpoint> _manifestEndpoints = <_ManifestEndpoint>[
    _ManifestEndpoint(
      urlTemplate: "https://inv-eu1.nadeko.net/companion/api/manifest/dash/id/{youtube_id}?local=true&unique_res=1",
      headers: <String, String>{
        "Origin": "https://inv.nadeko.net",
      },
    ),
    _ManifestEndpoint(
      urlTemplate: "https://inv-eu2.nadeko.net/companion/api/manifest/dash/id/{youtube_id}?local=true&unique_res=1",
      headers: <String, String>{
        "Origin": "https://inv.nadeko.net",
      },
    ),
    _ManifestEndpoint(
      urlTemplate: "https://inv-eu3.nadeko.net/companion/api/manifest/dash/id/{youtube_id}?local=true&unique_res=1",
      headers: <String, String>{
        "Origin": "https://inv.nadeko.net",
      },
    ),
  ];

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.plain,
    ),
  );
  final Logger _logger = Logger();
  final Random _random = Random();

  @override
  Future<List<MediaStream>> extractStreams(String youtubeUrl) async {
    final String trimmedUrl = youtubeUrl.trim();
    if (trimmedUrl.isEmpty) {
      return <MediaStream>[];
    }

    final Uri? normalizedYoutubeUri = normalizeYouTubeUri(trimmedUrl);
    if (normalizedYoutubeUri == null) {
      _logger.w("Failed to normalize YouTube URL for Invidious extraction: $youtubeUrl");
      return <MediaStream>[];
    }

    final String? videoId = extractYouTubeVideoId(normalizedYoutubeUri);
    if (videoId == null || videoId.isEmpty) {
      _logger.w("Could not extract video ID from YouTube URL: ${normalizedYoutubeUri.toString()}");
      return <MediaStream>[];
    }

    final _ManifestEndpoint manifestEndpoint = _selectManifestEndpoint();
    final Uri manifestUri = manifestEndpoint.buildUri(videoId);
    final Map<String, String> manifestHeaders = manifestEndpoint.headers;

    try {
      final Response<String> response = await _dio.get<String>(
        manifestUri.toString(),
        options: Options(headers: Map<String, String>.from(manifestHeaders)),
      );
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        _logger.w("Invidious manifest request failed with status ${response.statusCode} for video $videoId");
        return <MediaStream>[];
      }

      final String? body = response.data;
      if (body == null || body.isEmpty) {
        _logger.w("Received empty DASH manifest from ${manifestUri.host} for video $videoId");
        return <MediaStream>[];
      }

      return <MediaStream>[
        MediaStream(
          type: StreamType.dash,
          url: manifestUri.toString(),
          headers: Map<String, String>.from(manifestHeaders),
        ),
      ];
    } catch (e, s) {
      _logger.e("Failed to get Invidious manifest", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }

  _ManifestEndpoint _selectManifestEndpoint() {
    if (_manifestEndpoints.length == 1) {
      return _manifestEndpoints.first;
    }

    final int index = _random.nextInt(_manifestEndpoints.length);
    return _manifestEndpoints[index];
  }
}

class _ManifestEndpoint {
  const _ManifestEndpoint({
    required this.urlTemplate,
    required this.headers,
  });

  final String urlTemplate;
  final Map<String, String> headers;

  Uri buildUri(String videoId) {
    final String replaced = urlTemplate.replaceAll("{youtube_id}", videoId);
    return Uri.parse(replaced);
  }
}
