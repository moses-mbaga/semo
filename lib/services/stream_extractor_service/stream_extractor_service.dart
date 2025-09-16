import "dart:io";
import "dart:math" as math;

import "package:logger/logger.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/services/stream_extractor_service/extractors/auto_embed_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/holly_movie_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/kiss_kh_extractor.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/services/stream_extractor_service/extractors/mapple_tv_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/movies_api_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/multi_movies_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/cine_pro_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/show_box_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/vid_fast_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/vid_link_extractor.dart";

class StreamExtractorService {
  static final Logger _logger = Logger();
  static final List<StreamingServer> _streamingServers = <StreamingServer>[
    const StreamingServer(name: "Random", extractor: null),
    if (!Platform.isIOS) StreamingServer(name: "AutoEmbed", extractor: AutoEmbedExtractor()),
    StreamingServer(name: "CinePro", extractor: CineProExtractor()),
    StreamingServer(name: "HollyMovie", extractor: HollyMovieExtractor()),
    StreamingServer(name: "KissKh", extractor: KissKhExtractor()),
    if (!Platform.isIOS) StreamingServer(name: "MappleTV", extractor: MappleTvExtractor()),
    StreamingServer(name: "MoviesApi", extractor: MoviesApiExtractor()),
    StreamingServer(name: "MultiMovies", extractor: MultiMoviesExtractor()),
    if (!Platform.isIOS) StreamingServer(name: "ShowBox", extractor: ShowBoxExtractor()),
    StreamingServer(name: "VidFast", extractor: VidFastExtractor()),
    StreamingServer(name: "VidLink", extractor: VidLinkExtractor()),
  ];

  static List<StreamingServer> get streamingServers => _streamingServers;

  static Future<MediaStream?> getStream(StreamExtractorOptions options) async {
    try {
      const int maxIndividualAttempts = 3;
      const int maxRandomExtractors = 3;
      final math.Random random = math.Random();
      final String storedServerName = AppPreferencesService().getStreamingServer();
      final bool isTv = options.season != null && options.episode != null;
      final MediaType requestedMediaType = isTv ? MediaType.tvShows : MediaType.movies;

      if (requestedMediaType == MediaType.none) {
        throw Exception("Unable to determine media type for extraction");
      }

      final List<StreamingServer> availableServers = _streamingServers.where((StreamingServer s) => s.extractor != null && s.extractor!.acceptedMediaTypes.contains(requestedMediaType)).toList();

      if (storedServerName != "Random") {
        final StreamingServer server = _streamingServers.firstWhere((StreamingServer server) => server.name == storedServerName);
        final BaseStreamExtractor? extractor = server.extractor;

        if (extractor == null || !extractor.acceptedMediaTypes.contains(requestedMediaType)) {
          throw Exception("Selected server '$storedServerName' does not support ${requestedMediaType.toString()}");
        }

        for (int attempt = 0; attempt < maxIndividualAttempts; attempt++) {
          final List<MediaStream> streams = await _extractStreamsForServer(extractor, options, server.name);

          if (streams.isNotEmpty) {
            _logger.i("Streams found.\nStreamingServer: ${server.name}\nCount: ${streams.length}");
            return streams.first;
          }

          _logger.w(
            "No streams found.\nStreamingServer: ${server.name}\nAttempt: ${attempt + 1} of $maxIndividualAttempts",
          );
        }

        return null;
      }

      final List<StreamingServer> randomServers = List<StreamingServer>.from(availableServers);
      int randomAttempts = 0;

      while (randomAttempts < maxRandomExtractors && randomServers.isNotEmpty) {
        final int randomIndex = random.nextInt(randomServers.length);
        final StreamingServer server = randomServers.removeAt(randomIndex);
        final BaseStreamExtractor extractor = server.extractor!;

        final List<MediaStream> streams = await _extractStreamsForServer(extractor, options, server.name);

        if (streams.isNotEmpty) {
          _logger.i("Streams found.\nStreamingServer: ${server.name}\nCount: ${streams.length}");
          return streams.first;
        }

        _logger.w("No streams found.\nStreamingServer: ${server.name}");
        randomAttempts++;
      }
    } catch (e, s) {
      _logger.e("Failed to extract stream", error: e, stackTrace: s);
    }

    return null;
  }

  static Future<List<MediaStream>> _extractStreamsForServer(
    BaseStreamExtractor extractor,
    StreamExtractorOptions options,
    String serverName,
  ) async {
    String? externalLinkUrl;
    Map<String, String>? externalLinkHeaders;

    if (extractor.needsExternalLink) {
      final Map<String, Object?>? external = await extractor.getExternalLink(options);
      externalLinkUrl = (external?["url"] as String?)?.trim();
      final Map<dynamic, dynamic>? rawHeaders = external?["headers"] as Map<dynamic, dynamic>?;
      if (rawHeaders != null) {
        // ignore: avoid_annotating_with_dynamic
        externalLinkHeaders = rawHeaders.map((dynamic k, dynamic v) => MapEntry<String, String>(k.toString(), v.toString()));
      }

      if (externalLinkUrl == null || externalLinkUrl.isEmpty) {
        throw Exception("Failed to retrieve external link for ${options.title} in $serverName");
      }
    }

    return extractor.getStreams(
      options,
      externalLink: externalLinkUrl,
      externalLinkHeaders: externalLinkHeaders,
    );
  }
}
