import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/helpers.dart";
import "package:semo/services/stream_extractor_service/extractors/streaming_server_base_url_extractor.dart";

class CineProExtractor implements BaseStreamExtractor {
  CineProExtractor() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        enabled: kDebugMode,
      ),
    );
  }

  final String _providerKey = "semo_cinepro";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  final Logger _logger = Logger();

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => false;

  @override
  Future<String?> getExternalLink(StreamExtractorOptions options) async => null;

  @override
  Future<MediaStream?> getStream(String? externalLink, StreamExtractorOptions options) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null) {
        _logger.e("No base URL found for provider: $_providerKey");
        return null;
      }

      final String mediaType = options.season != null && options.episode != null ? "tv" : "movie";
      String url = "$baseUrl/$mediaType/${options.tmdbId}";

      if (options.season != null && options.episode != null) {
        url += "?s=${options.season}&e=${options.episode}";
      }

      final Response<dynamic> response = await _dio.get(url);
      final List<Map<String, dynamic>> streams = response.data["files"]?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

      for (Map<String, dynamic> stream in streams) {
        final String? streamUrl = stream["file"];
        final String language = normalizeForComparison(stream["lang"] ?? "");
        final String type = normalizeForComparison(stream["type"] ?? "");
        final Map<String, String> headers = <String, String>{};

        if (stream["headers"] != null) {
          headers.addAll(Map<String, String>.from(stream["headers"]));
        }

        if (streamUrl != null &&
            streamUrl.isNotEmpty &&
            !streamUrl.contains("shadowlandschronicles.com") && // Remove broken stream sources
            !streamUrl.contains("cdn.niggaflix.xyz") && // Remove broken stream sources
            (type == "mp4" || type == "hls") &&
            (language == "en" || language == "english")) {
          _logger.i("Found valid stream: $headers");
          return MediaStream(
            url: streamUrl,
            headers: headers,
          );
        }
      }
    } catch (e, s) {
      _logger.e("Error in CineProExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
