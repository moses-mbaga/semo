import "dart:async";
import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/streams_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/common_headers.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/extract_stream_from_page_requests_service.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";
import "package:semo/utils/string_extensions.dart";

class VidRockExtractor implements BaseStreamExtractor {
  VidRockExtractor() {
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

  final String _providerKey = "semo_vidrock";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final ExtractStreamFromPageRequestsService _extractStreamFromPageRequestsService = const ExtractStreamFromPageRequestsService();
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
  bool get needsExternalLink => true;

  @override
  Future<Map<String, Object?>?> getExternalLink(StreamExtractorOptions options) async {
    try {
      String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      final bool isTv = options.season != null && options.episode != null;
      final String path = isTv ? "/tv/${options.tmdbId}/${options.season}/${options.episode}" : "/movie/${options.tmdbId}";

      final Uri pageUri = Uri.parse(baseUrl).resolve(path);

      final Map<String, dynamic>? externalLink = await _extractStreamFromPageRequestsService.extract(
        pageUri.toString(),
        includePatterns: <String>[pageUri.host],
        filter: (String url) => url.contains("${pageUri.host}/api/"),
        acceptAnyOnFilterMatch: true,
      );

      final String? url = externalLink?["url"];

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for: $_providerKey");
      }

      return <String, Object?>{
        "url": url,
      };
    } catch (e, s) {
      _logger.e("Error extracting stream in VidRockExtractor", error: e, stackTrace: s);
    }

    return null;
  }

  @override
  Future<List<MediaStream>> getStreams(StreamExtractorOptions options, {String? externalLink, Map<String, String>? externalLinkHeaders}) async {
    try {
      String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final List<MediaStream> streams = <MediaStream>[];
      String? separatePlaylist;
      final Response<dynamic> response = await _dio.get(externalLink);

      if (response.statusCode == 200) {
        final Map<String, dynamic> sources = Map<String, dynamic>.from(jsonDecode(response.data) as Map<dynamic, dynamic>);

        for (final MapEntry<String, dynamic> sourceEntry in sources.entries) {
          if (sourceEntry.value is! Map) {
            continue;
          }

          final Map<String, dynamic> source = Map<String, dynamic>.from(sourceEntry.value as Map<dynamic, dynamic>);

          final String? url = source["url"] as String?;
          final String? language = (source["language"] as String?)?.normalize();

          if (url != null && language != null && language == "english") {
            if (url.contains("cdn.niggaflix.xyz")) {
              // Ignore because it's broken
              continue;
            }

            if (url.contains("cdn.vidrock.store")) {
              separatePlaylist = url;
              continue;
            }

            if (url.contains("m3u8") || url.contains("m3u")) {
              streams.add(
                MediaStream(
                  type: StreamType.hls,
                  url: url,
                  headers: <String, String>{
                    "Referer": "$baseUrl/",
                  },
                ),
              );
            }
          }
        }
      }

      if (streams.isNotEmpty) {
        // Reorder streams so that those with master playlist come first
        streams.sort((MediaStream a, MediaStream b) {
          final bool aHasMaster = a.url.contains("master.m3u8");
          final bool bHasMaster = b.url.contains("master.m3u8");

          if (aHasMaster && !bHasMaster) {
            return -1;
          }
          if (!aHasMaster && bHasMaster) {
            return 1;
          }

          return 0;
        });
      }

      if (streams.isEmpty && separatePlaylist != null && separatePlaylist.isNotEmpty) {
        final Response<dynamic> response = await _dio.get(separatePlaylist);
        if (response.statusCode == 200) {
          final List<dynamic> sources = List<dynamic>.from(response.data as List<dynamic>);

          for (final dynamic sourceData in sources) {
            if (sourceData is! Map) {
              continue;
            }

            final Map<String, dynamic> source = Map<String, dynamic>.from(sourceData);
            final String? url = source["url"] as String?;
            final dynamic resolutionValue = source["resolution"];
            String resolution = resolutionValue == null ? "Auto" : resolutionValue.toString();

            if (resolution.isNotEmpty && resolution[resolution.length - 1] == "0") {
              resolution += "p";
            }

            if (url != null && url.contains("mp4")) {
              streams.add(
                MediaStream(
                  type: StreamType.mp4,
                  url: url,
                  headers: <String, String>{
                    "Referer": "$baseUrl/",
                  },
                  quality: resolution,
                ),
              );
            }
          }
        }
      }

      if (streams.isEmpty) {
        throw Exception("No streams found for: $_providerKey");
      }

      return streams;
    } catch (e, s) {
      _logger.e("Error extracting stream in VidRockExtractor", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }
}
