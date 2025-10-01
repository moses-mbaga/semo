import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/streams_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/extract_stream_from_page_requests_service.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";
import "package:semo/utils/string_extensions.dart";

class HollyMovieExtractor implements BaseStreamExtractor {
  HollyMovieExtractor() {
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

  final String _providerKey = "semo_hollymovie";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final ExtractStreamFromPageRequestsService _extractStreamFromPageRequestsService = const ExtractStreamFromPageRequestsService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  final Logger _logger = Logger();

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => true;

  @override
  Future<Map<String, Object?>?> getExternalLink(StreamExtractorOptions options) async {
    String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception("Failed to get base URL for $_providerKey");
    }

    final bool isTv = options.season != null && options.episode != null;
    String formattedTitle = options.title.removeSpecialChars().replaceAll(" ", "-").normalize();
    String path = "/$formattedTitle";

    if (isTv) {
      path = "/episode$path-season-${options.season}-episode-${options.episode}/";
    } else {
      path += "-${options.releaseYear}/";
    }

    final Uri pageUri = Uri.parse(baseUrl).resolve(path);

    final Map<String, dynamic>? stream = await _extractStreamFromPageRequestsService.extract(
      pageUri.toString(),
      includePatterns: <String>["flashstream.cc"],
      filter: (String url) => url.startsWith("https://flashstream.cc/embed"),
      acceptAnyOnFilterMatch: true,
    );
    final String? url = stream?["url"];
    final Map<String, String> headers = stream?["headers"] ?? <String, String>{};

    if (url == null || url.isEmpty) {
      throw Exception("No exteral link found for: $_providerKey");
    }

    return <String, Object?>{
      "url": url,
      "headers": headers,
    };
  }

  @override
  Future<List<MediaStream>> getStreams(StreamExtractorOptions options, {String? externalLink, Map<String, String>? externalLinkHeaders}) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final Uri pageUri = Uri.parse(externalLink);

      final Map<String, dynamic>? stream = await _extractStreamFromPageRequestsService.extract(
        pageUri.toString(),
        includePatterns: <String>["flashstream.cc"],
        filter: (String url) => url.startsWith("https://flashstream.cc/streamsvr"),
        acceptAnyOnFilterMatch: true,
      );
      final String? url = stream?["url"];
      final Map<String, String> headers = stream?["headers"] ?? <String, String>{};

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for: $_providerKey");
      }

      return <MediaStream>[
        MediaStream(
          type: StreamType.hls,
          url: url,
          headers: headers,
        ),
      ];
    } catch (e, s) {
      _logger.e("Error extracting stream in HollyMovieExtractor", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }
}
