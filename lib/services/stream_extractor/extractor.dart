import "dart:math" as math;

import "package:logger/logger.dart";
import "package:index/models/episode.dart";
import "package:index/models/movie.dart";
import "package:index/models/stream_extractor_options.dart";
import "package:index/models/streaming_server.dart";
import "package:index/models/media_stream.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/stream_extractor/extractors/base_stream_extractor.dart";
import "package:index/services/stream_extractor/extractors/kiss_kh_extractor.dart";
import "package:index/services/preferences.dart";

class StreamExtractor {
  static final Logger _logger = Logger();
  static final List<StreamingServer> _streamingServers = <StreamingServer>[
    const StreamingServer(name: "Random", extractor: null),
    StreamingServer(name: "KissKh", extractor: KissKhExtractor()),
  ];

  static List<StreamingServer> get streamingServers => _streamingServers;

  static Future<MediaStream?> getStream({Movie? movie, TvShow? tvShow, Episode? episode}) async {
    try {
      math.Random random = math.Random();
      String serverName = AppPreferences().getStreamingServer();
      MediaStream? stream;
      BaseStreamExtractor? extractor;

      if (serverName != "Random") {
        StreamingServer server = _streamingServers.firstWhere((StreamingServer server) => server.name == serverName);
        extractor = server.extractor;
      }

      StreamExtractorOptions? streamExtractorOptions;

      if (movie != null) {
        streamExtractorOptions = StreamExtractorOptions(
          tmdbId: movie.id,
          title: movie.title,
          movieReleaseYear: movie.releaseDate.split("-")[0]
        );
      } else if (tvShow != null && episode != null) {
        streamExtractorOptions = StreamExtractorOptions(
          tmdbId: episode.id,
          season: episode.season,
          episode: episode.number,
          title: tvShow.name,
        );
      }

      if (streamExtractorOptions == null) {
        throw Exception("StreamExtractorOptions is null");
      }

      while (stream?.url == null && _streamingServers.isNotEmpty) {
        int randomIndex = random.nextInt(_streamingServers.length);

        if (serverName == "Random" && extractor == null) {
          StreamingServer server = _streamingServers[randomIndex];
          extractor = server.extractor;
        }

        stream = await extractor?.getStream(streamExtractorOptions);

        if (stream == null || stream.url.isEmpty) {
          _logger.w("Stream not found.\nStreamingServer: $serverName");
          if (serverName == "Random") {
            _streamingServers.removeAt(randomIndex);
          }
          stream = null;
        }
      }

      _logger.i("Stream found.\nStreamingServer: $serverName\nUrl: ${stream?.url}");

      return stream;
    } catch (e, s) {
      _logger.e("Failed to extract stream", error: e, stackTrace: s);
      rethrow;
    }
  }
}