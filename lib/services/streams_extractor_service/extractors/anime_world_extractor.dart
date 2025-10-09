import "dart:async";

import "package:logger/logger.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/streams_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/extract_stream_from_page_requests_service.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";
import "package:semo/utils/string_extensions.dart";

class AnimeWorldExtractor implements BaseStreamExtractor {
  AnimeWorldExtractor();

  final String _providerKey = "semo_animeworld";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final ExtractStreamFromPageRequestsService _extractStreamFromPageRequestsService =
      const ExtractStreamFromPageRequestsService();
  final Logger _logger = Logger();

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => false;

  @override
  Future<Map<String, Object?>?> getExternalLink(StreamExtractorOptions options) async => null;

  @override
  Future<List<MediaStream>> getStreams(StreamExtractorOptions options, {String? externalLink, Map<String, String>? externalLinkHeaders}) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      String slug = options.title.normalize().toLowerCase();
      slug = slug.replaceAll(RegExp(r"[^a-z0-9\s-]"), "");
      slug = slug.replaceAll(RegExp(r"\s+"), "-");
      slug = slug.replaceAll(RegExp(r"-+"), "-");
      slug = slug.replaceAll(RegExp(r"^-+"), "");
      slug = slug.replaceAll(RegExp(r"-+$"), "");

      if (slug.isEmpty) {
        throw Exception("Failed to normalize title for AnimeWorld extraction");
      }

      final bool isTv = options.season != null && options.episode != null;
      final Uri pageUri = Uri.parse(baseUrl).resolve(
        isTv
            ? "/episode/$slug-${options.season}x${options.episode}/"
            : "/movies/$slug/",
      );

      final Map<String, dynamic>? stream = await _extractStreamFromPageRequestsService.extract(pageUri.toString());
      final String? url = stream?["url"] as String?;
      Map<String, String> headers = <String, String>{};
      final Map<dynamic, dynamic>? rawHeaders = stream?["headers"] as Map<dynamic, dynamic>?;
      if (rawHeaders != null) {
        headers = rawHeaders.map(
          (dynamic key, dynamic value) => MapEntry<String, String>(key.toString(), value.toString()),
        );
      }

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL captured for AnimeWorld");
      }

      final String lowerUrl = url.toLowerCase();
      StreamType streamType = StreamType.mp4;
      if (lowerUrl.contains("m3u8") || lowerUrl.contains("m3u")) {
        streamType = StreamType.hls;
      } else if (lowerUrl.contains("mkv")) {
        streamType = StreamType.mkv;
      }

      return <MediaStream>[
        MediaStream(
          type: streamType,
          url: url,
          headers: headers.isEmpty ? null : headers,
        ),
      ];
    } catch (e, s) {
      _logger.e("Error extracting stream in AnimeWorldExtractor", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }
}
