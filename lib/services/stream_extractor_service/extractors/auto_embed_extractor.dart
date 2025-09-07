import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/common_headers.dart";
import "package:semo/services/stream_extractor_service/extractors/helpers.dart";
import "package:semo/services/stream_extractor_service/extractors/streaming_server_base_url_extractor.dart";

class AutoEmbedExtractor implements BaseStreamExtractor {
  AutoEmbedExtractor() {
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

  final String _providerKey = "autoEmbed";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: commonHeaders,
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
      String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      final bool isTv = options.season != null && options.episode != null;
      final String path = "/embed${isTv ? "/tv/${options.tmdbId}/${options.season}/${options.episode}" : "/movie/${options.tmdbId}"}?server=2";

      baseUrl = "https://test.${baseUrl.replaceFirst("https://", "")}";
      final Uri pageUri = Uri.parse(baseUrl).resolve(path);

      final Map<String, dynamic>? stream = await extractStreamFromPageRequests(
        pageUri.toString(),
        filter: (String url) => url.startsWith("https://proxy.vidsrc.co/?u="),
      );
      final String? url = stream?["url"];
      Map<String, String> headers = stream?["headers"] ?? <String, String>{};

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for external link: $externalLink");
      }

      if (!headers.containsKey("Referer")) {
        headers["Referer"] = baseUrl;
      }

      return MediaStream(
        url: url,
        headers: headers,
      );
    } catch (e, s) {
      _logger.e("Error extracting stream in AutoEmbedExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
