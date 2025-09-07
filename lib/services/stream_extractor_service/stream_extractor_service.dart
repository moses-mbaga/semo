import "dart:math" as math;

import "package:logger/logger.dart";
import "package:semo/models/episode.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/kiss_kh_extractor.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/services/stream_extractor_service/extractors/movie_box_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/movies_api_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/multi_movies_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/cine_pro_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/show_box_extractor.dart";

class StreamExtractorService {
  static final Logger _logger = Logger();
  static final List<StreamingServer> _streamingServers = <StreamingServer>[
    const StreamingServer(name: "Random", extractor: null),
    StreamingServer(name: "CinePro", extractor: CineProExtractor()),
    StreamingServer(name: "KissKh", extractor: KissKhExtractor()),
    StreamingServer(name: "MovieBox", extractor: MovieBoxExtractor()),
    StreamingServer(name: "MoviesApi", extractor: MoviesApiExtractor()),
    StreamingServer(name: "MultiMovies", extractor: MultiMoviesExtractor()),
    StreamingServer(name: "ShowBox", extractor: ShowBoxExtractor()),
  ];

  static List<StreamingServer> get streamingServers => _streamingServers;

  static Future<MediaStream?> getStream({Movie? movie, TvShow? tvShow, Episode? episode}) async {
    try {
      math.Random random = math.Random();
      String serverName = AppPreferencesService().getStreamingServer();
      MediaStream? stream;
      BaseStreamExtractor? extractor;

      final MediaType requestedMediaType = movie != null ? MediaType.movies : (tvShow != null && episode != null ? MediaType.tvShows : MediaType.none);

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

      StreamExtractorOptions? streamExtractorOptions;

      if (movie != null) {
        streamExtractorOptions = StreamExtractorOptions(tmdbId: movie.id, title: movie.title, movieReleaseYear: movie.releaseDate.split("-")[0]);
      } else if (tvShow != null && episode != null) {
        streamExtractorOptions = StreamExtractorOptions(
          tmdbId: tvShow.id,
          season: episode.season,
          episode: episode.number,
          title: tvShow.name,
        );
      }

      if (streamExtractorOptions == null) {
        throw Exception("StreamExtractorOptions is null");
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

        String? externalLink;

        if (extractor?.needsExternalLink == true) {
          externalLink = await extractor?.getExternalLink(streamExtractorOptions);
          if (externalLink == null || externalLink.isEmpty) {
            throw Exception("Failed to retrieve external link for ${streamExtractorOptions.title} in $serverName");
          }
        }

        stream = await extractor?.getStream(externalLink, streamExtractorOptions);

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
