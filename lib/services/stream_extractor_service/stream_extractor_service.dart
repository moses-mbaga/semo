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
      math.Random random = math.Random();
      String serverName = AppPreferencesService().getStreamingServer();
      MediaStream? stream;
      BaseStreamExtractor? extractor;

      final bool isTv = options.season != null && options.episode != null;
      final MediaType requestedMediaType = isTv ? MediaType.tvShows : MediaType.movies;

      if (requestedMediaType == MediaType.none) {
        throw Exception("Unable to determine media type for extraction");
      }

      if (serverName != "Random") {
        final StreamingServer server = _streamingServers.firstWhere((StreamingServer server) => server.name == serverName);
        extractor = server.extractor;

        if (extractor == null || !extractor.acceptedMediaTypes.contains(requestedMediaType)) {
          throw Exception("Selected server '$serverName' does not support ${requestedMediaType.toString()}");
        }
      }

      final List<StreamingServer> availableServers = _streamingServers.where((StreamingServer s) => s.extractor != null && s.extractor!.acceptedMediaTypes.contains(requestedMediaType)).toList();

      while ((stream?.url == null || stream!.url.isEmpty) && (serverName != "Random" || availableServers.isNotEmpty)) {
        int randomIndex = -1;

        if (serverName == "Random" && extractor == null) {
          randomIndex = random.nextInt(availableServers.length);
          final StreamingServer server = availableServers[randomIndex];
          extractor = server.extractor;
          serverName = server.name;
        }

        String? externalLinkUrl;
        Map<String, String>? externalLinkHeaders;

        if (extractor?.needsExternalLink == true) {
          final Map<String, Object?>? external = await extractor?.getExternalLink(options);
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

        stream = await extractor?.getStream(
          options,
          externalLink: externalLinkUrl,
          externalLinkHeaders: externalLinkHeaders,
        );

        if (stream == null || stream.url.isEmpty) {
          _logger.w("Stream not found.\nStreamingServer: $serverName");

          stream = null;

          if (serverName == "Random") {
            // Remove this server from the local pool and try another
            if (randomIndex >= 0 && randomIndex < availableServers.length) {
              availableServers.removeAt(randomIndex);
            }
            extractor = null;
            serverName = "Random";
          } else {
            break;
          }
        }
      }

      if (stream != null && stream.url.isNotEmpty) {
        _logger.i("Stream found.\nStreamingServer: $serverName\nUrl: ${stream.url}");
      }

      return stream;
    } catch (e, s) {
      _logger.e("Failed to extract stream", error: e, stackTrace: s);
    }

    return null;
  }
}
