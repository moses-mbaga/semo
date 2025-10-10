import "dart:async";

import "package:logger/logger.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/streams_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/extract_stream_from_page_requests_service.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";

class XprimeExtractor implements BaseStreamExtractor {
  XprimeExtractor();

  final String _providerKey = "semo_xprime";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final ExtractStreamFromPageRequestsService _extractStreamFromPageRequestsService = const ExtractStreamFromPageRequestsService();
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

      final bool isTv = options.season != null && options.episode != null;
      final String path = isTv ? "/watch/${options.tmdbId}/${options.season}/${options.episode}" : "/watch/${options.tmdbId}";
      final Uri pageUri = Uri.parse(baseUrl).resolve(path);

      final Map<String, dynamic>? stream = await _extractStreamFromPageRequestsService.extract(pageUri.toString(), includePatterns: <String>["oca-worker.kendrickl-3amar.workers.dev"], filter: (String url) => url.startsWith("https://oca-worker.kendrickl-3amar.workers.dev/?v="), acceptAnyOnFilterMatch: true);

      final String? url = stream?["url"];
      final Map<String, String> headers = stream?["headers"] ?? <String, String>{};

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for XprimeExtractor");
      }

      return <MediaStream>[
        MediaStream(
          type: StreamType.hls,
          url: url,
          headers: headers,
        ),
      ];
    } catch (e, s) {
      _logger.e("Error extracting stream in XprimeExtractor", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }
}
