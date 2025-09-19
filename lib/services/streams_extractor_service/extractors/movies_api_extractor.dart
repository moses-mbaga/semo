import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html_parser;
import "package:semo/models/media_stream.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/streams_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/extract_stream_from_page_requests_service.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";

class MoviesApiExtractor implements BaseStreamExtractor {
  MoviesApiExtractor() {
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

  final String _providerKey = "moviesapi";
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
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      final bool isTv = options.season != null && options.episode != null;
      final String path = isTv ? "/tv/${options.tmdbId}-${options.season}-${options.episode}" : "/movie/${options.tmdbId}";

      final Uri pageUri = Uri.parse(baseUrl).resolve(path);

      final Response<dynamic> res = await _dio.get(pageUri.toString());
      final Document document = html_parser.parse(res.data);

      final List<Element> iframes = document.getElementsByTagName("iframe");
      String? iframeSrc;

      for (final Element iframe in iframes) {
        final String? src = iframe.attributes["src"];
        if (src == null || src.isEmpty) {
          continue;
        }

        final String s = src.trim();
        final String sl = s.toLowerCase();

        if (sl.startsWith("https://vidora.stream")) {
          iframeSrc = s;
          break;
        }
      }

      if (iframeSrc == null || iframeSrc.isEmpty) {
        throw Exception("Vidora iframe not found for $_providerKey: ${pageUri.toString()}");
      }

      final Uri iframeUri = Uri.parse(iframeSrc);
      final String externalUrl = iframeUri.hasScheme ? iframeUri.toString() : pageUri.resolveUri(iframeUri).toString();

      return <String, Object?>{
        "url": externalUrl,
      };
    } catch (e, s) {
      _logger.e("Error getting external link for MoviesApi", error: e, stackTrace: s);
    }

    return null;
  }

  @override
  Future<List<MediaStream>> getStreams(StreamExtractorOptions options, {String? externalLink, Map<String, String>? externalLinkHeaders}) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final Map<String, dynamic>? stream = await _extractStreamFromPageRequestsService.extract(externalLink);
      final String? url = stream?["url"];
      Map<String, String> headers = stream?["headers"] ?? <String, String>{};

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for $_providerKey, with external link: $externalLink");
      }

      if (!headers.containsKey("Origin") || !headers.containsKey("Referer")) {
        headers["Origin"] = "https://vidora.stream";
        headers["Referer"] = "https://vidora.stream";
      }

      return <MediaStream>[
        MediaStream(
          type: url.toLowerCase().contains("m3u8") || url.toLowerCase().contains("m3u") ? StreamType.hls : (url.toLowerCase().contains("mkv") ? StreamType.mkv : StreamType.mp4),
          url: url,
          headers: headers,
        ),
      ];
    } catch (e, s) {
      _logger.e("Error extracting stream in MoviesApiExtractor", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }
}
