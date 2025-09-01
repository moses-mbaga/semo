import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/secrets_service.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/helpers.dart";
import "package:semo/services/stream_extractor_service/extractors/streaming_server_base_url_extractor.dart";

class MovieBoxExtractor implements BaseStreamExtractor {
  MovieBoxExtractor() {
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

  final String _providerKey = "movieBox";
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
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies];

  @override
  bool get needsExternalLink => true;

  @override
  Future<String?> getExternalLink(StreamExtractorOptions options) async {
    final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception("Failed to get base URL for $_providerKey");
    }

    // You need a proxy
    // You can host your own proxy
    // Demo setup: https://github.com/himanshu8443/Cf-Workers/blob/main/src/dob-worker/index.js

    String proxyUrl = SecretsService.cloudflareWorkerProxy;
    String searchUrl = "$baseUrl/wefeed-mobile-bff/subject-api/search/v2";

    final Response<dynamic> response = await _dio.post(
      proxyUrl,
      data: <String, dynamic>{
        "url": searchUrl,
        "method": "POST",
        "body": <String, dynamic>{
          "page": 1,
          "perPage": 20,
          "keyword": options.title,
          "tabId": "Movie",
        }
      },
    );
    final List<Map<String, dynamic>>? searchResults = (response.data as Map<dynamic, dynamic>)["data"]["results"][0]["subjects"].cast<Map<String, dynamic>>();

    if (searchResults == null || searchResults.isEmpty) {
      throw Exception("No search results found for ${options.title}");
    }

    Map<String, dynamic> result = searchResults.firstWhere(
      (Map<String, dynamic> result) {
        bool matchedTitle = normalizeForComparison("${result["title"]}") == normalizeForComparison(options.title);

        if (!matchedTitle) {
          matchedTitle = normalizeForComparison("${result["title"]}").contains(normalizeForComparison(options.title));

          if (!matchedTitle) {
            matchedTitle = normalizeForComparison(options.title).contains(normalizeForComparison("${result["title"]}"));
          }
        }

        if (options.movieReleaseYear != null) {
          bool matchedReleaseYear = normalizeForComparison("${result["releaseDate"]}").split("-")[0] == options.movieReleaseYear;
          return matchedTitle && matchedReleaseYear;
        }

        return matchedTitle;
      },
      orElse: () => <String, dynamic>{},
    );

    return result["subjectId"];
  }

  @override
  Future<MediaStream?> getStream(String? externalLink, StreamExtractorOptions options) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      final String proxyUrl = SecretsService.cloudflareWorkerProxy;
      final String streamUrl = "$baseUrl/wefeed-mobile-bff/subject-api/get?subjectId=$externalLink";
      final Response<dynamic> response = await _dio.post(
        proxyUrl,
        data: <String, dynamic>{
          "url": streamUrl,
          "method": "GET",
        },
      );

      final List<Map<String, dynamic>>? streams = (response.data as Map<dynamic, dynamic>)["data"]["resourceDetectors"][0]["resolutionList"].cast<Map<String, dynamic>>();
      if (streams == null || streams.isEmpty) {
        throw Exception("No streams found for $_providerKey id=$externalLink");
      }

      List<int> resolutions = <int>[1080, 720, 480, 360];
      String? videoUrl;

      for (final int resolution in resolutions) {
        final Map<String, dynamic> stream = streams.firstWhere(
          (Map<String, dynamic> stream) => stream["resolution"] == resolution,
          orElse: () => <String, dynamic>{},
        );

        if (stream.isNotEmpty) {
          videoUrl = stream["resourceLink"];
          break;
        }
      }

      if (videoUrl == null) {
        throw Exception("No video stream found for $_providerKey");
      }

      return MediaStream(url: videoUrl);
    } catch (e, s) {
      _logger.e("Error in MovieBoxExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
