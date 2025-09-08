import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/utils/helpers.dart";
import "package:semo/services/stream_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";

class KissKhExtractor implements BaseStreamExtractor {
  KissKhExtractor() {
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

  final String _providerKey = "kissKh";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  final Logger _logger = Logger();

  Future<String?> _findEpisodeId(String baseUrl, String externalId, StreamExtractorOptions options) async {
    String url = "$baseUrl/api/DramaList/Drama/$externalId?isq=false";

    final Response<dynamic> response = await _dio.get(url);
    final Map<String, dynamic> results = response.data as Map<String, dynamic>;

    if (results.isEmpty) {
      throw Exception("Failed to retrieve info for $externalId");
    }

    List<Map<String, dynamic>>? episodes = (results["episodes"] as List<dynamic>).cast<Map<String, dynamic>>();

    if (episodes.isEmpty) {
      throw Exception("No episodes found for $externalId");
    }

    try {
      Map<String, dynamic> episode = episodes.firstWhere((Map<String, dynamic> episode) => episode["number"] == (options.episode ?? 1));
      int? id = episode["id"];
      return id?.toString();
    } catch (e, s) {
      _logger.e("Error finding episode ID for external ID: $externalId", error: e, stackTrace: s);
    }

    return null;
  }

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => true;

  @override
  Future<String?> getExternalLink(StreamExtractorOptions options) async {
    final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception("Failed to get base URL for $_providerKey");
    }

    String searchQuery = Uri.encodeComponent(options.title);
    String searchUrl = "$baseUrl/api/DramaList/Search?q=$searchQuery&type=0";

    final Response<dynamic> response = await _dio.get(searchUrl);
    final List<Map<String, dynamic>> searchResults = (response.data as List<dynamic>).cast<Map<String, dynamic>>();

    if (searchResults.isEmpty) {
      throw Exception("No search results found for ${options.title}");
    }

    List<String> referenceTitles = <String>[];
    if (options.season != null && options.episode != null) {
      referenceTitles.add("${options.title} - Season ${options.season}");
    } else {
      referenceTitles.add("${options.title} (${options.movieReleaseYear})");
      referenceTitles.add(options.title);
    }

    for (String title in referenceTitles) {
      try {
        Map<String, dynamic> result = searchResults.firstWhere((Map<String, dynamic> result) => normalizeForComparison("${result["title"]}") == normalizeForComparison(title));
        int? id = result["id"];
        return id?.toString();
      } catch (_) {}
    }

    // Fallback
    Map<String, dynamic> result = searchResults.firstWhere((Map<String, dynamic> result) => normalizeForComparison("${result["title"]}").contains(normalizeForComparison(options.title)));
    int? id = result["id"];
    return id?.toString();
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

      final String? episodeId = await _findEpisodeId(baseUrl, externalLink, options);

      if (episodeId == null || episodeId.isEmpty) {
        throw Exception("Failed to extract episode ID for $_providerKey with external ID: $externalLink");
      }

      final String streamUrl = "https://adorable-salamander-ecbb21.netlify.app/api/kisskh/video?id=$episodeId";
      final Response<dynamic> response = await _dio.get(streamUrl);

      final String? videoUrl = response.data?["source"]?["Video"] as String?;
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("No video URL found for $_providerKey id=$episodeId");
      }

      return MediaStream(
        url: videoUrl,
        headers: <String, String>{
          "Referer": baseUrl,
        },
      );
    } catch (e, s) {
      _logger.e("Error in KissKhExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
