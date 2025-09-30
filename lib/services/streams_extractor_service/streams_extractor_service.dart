import "dart:async";
import "dart:io";
import "dart:math" as math;

import "package:logger/logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/services/streams_extractor_service/extractors/auto_embed_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/holly_movie_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/kiss_kh_extractor.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/services/streams_extractor_service/extractors/movies_api_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/movies_joy_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/multi_movies_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/vid_fast_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/vid_link_extractor.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/closest_resolution.dart";
import "package:semo/services/streams_extractor_service/extractors/vid_rock_extractor.dart";
import "package:semo/services/video_quality_service.dart";

class StreamsExtractorService {
  factory StreamsExtractorService() => _instance;
  StreamsExtractorService._internal();

  static final StreamsExtractorService _instance = StreamsExtractorService._internal();

  final Logger _logger = Logger();
  final VideoQualityService _videoQualityService = const VideoQualityService();
  final List<StreamingServer> _streamingServers = <StreamingServer>[
    const StreamingServer(name: "Random", extractor: null),
    if (!Platform.isIOS) StreamingServer(name: "AutoEmbed", extractor: AutoEmbedExtractor()),
    if (!Platform.isIOS) StreamingServer(name: "HollyMovie", extractor: HollyMovieExtractor()),
    StreamingServer(name: "KissKh", extractor: KissKhExtractor()),
    StreamingServer(name: "MoviesApi", extractor: MoviesApiExtractor()),
    if (!Platform.isIOS) StreamingServer(name: "MoviesJoy", extractor: MoviesJoyExtractor()),
    StreamingServer(name: "MultiMovies", extractor: MultiMoviesExtractor()),
    StreamingServer(name: "VidFast", extractor: VidFastExtractor()),
    StreamingServer(name: "VidLink", extractor: VidLinkExtractor()),
    StreamingServer(name: "VidRock", extractor: VidRockExtractor()),

    // Broken
    // StreamingServer(name: "CinePro", extractor: CineProExtractor()), // As of 19.09.2025, all streams returned don't work
    // if (!Platform.isIOS) StreamingServer(name: "MappleTV", extractor: MappleTvExtractor()), // As of 19.09.2025, blocked by Cloudflare
    // if (!Platform.isIOS) StreamingServer(name: "ShowBox", extractor: ShowBoxExtractor()), // As of 18.09.2025, blocked by Cloudflare
  ];

  List<StreamingServer> getStreamingServers() => _streamingServers;

  Future<List<MediaStream>> getStreams(StreamExtractorOptions options) async {
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
            return streams;
          }

          _logger.w(
            "No streams found.\nStreamingServer: ${server.name}\nAttempt: ${attempt + 1} of $maxIndividualAttempts",
          );

          await Future<void>.delayed(const Duration(milliseconds: 500));
        }

        return <MediaStream>[];
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
          return streams;
        }

        _logger.w("No streams found.\nStreamingServer: ${server.name}");
        randomAttempts++;

        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    } catch (e, s) {
      _logger.e("Failed to extract stream", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }

  Future<List<MediaStream>> _extractStreamsForServer(
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

    final List<MediaStream> rawStreams = await extractor.getStreams(
      options,
      externalLink: externalLinkUrl,
      externalLinkHeaders: externalLinkHeaders,
    );

    if (rawStreams.isEmpty) {
      return rawStreams;
    }

    return _postProcessStreams(rawStreams);
  }

  Future<List<MediaStream>> _postProcessStreams(List<MediaStream> streams) async {
    final List<MediaStream> adaptiveStreams = streams
        .where((MediaStream stream) => stream.type == StreamType.hls || stream.type == StreamType.dash)
        .toList();
    final List<MediaStream> fileStreams = streams.where((MediaStream stream) => stream.type == StreamType.mp4 || stream.type == StreamType.mkv).toList();

    if (adaptiveStreams.isNotEmpty) {
      return adaptiveStreams;
    }

    if (fileStreams.isNotEmpty) {
      final List<MediaStream> processedFiles = await _processFileStreams(fileStreams);
      if (processedFiles.isNotEmpty) {
        return processedFiles;
      }
    }

    return streams;
  }

  Future<List<MediaStream>> _processFileStreams(List<MediaStream> fileStreams) async {
    List<MediaStream> streams = <MediaStream>[];

    for (int i = 0; i < fileStreams.length; i++) {
      MediaStream stream = fileStreams[i];

      String? quality;
      if (isAlreadyResolution(stream.quality)) {
        quality = stream.quality;
      } else {
        quality = await _videoQualityService.determineQuality(stream);
      }

      streams.add(
        MediaStream(
          type: stream.type,
          url: stream.url,
          headers: stream.headers,
          quality: quality ?? "Stream ${i + 1}",
          subtitles: stream.subtitles,
        ),
      );
    }

    return _arrangeStreamsByQualities(streams);
  }
}

List<MediaStream> _arrangeStreamsByQualities(List<MediaStream> streams) {
  int qualityWeight(String quality) {
    final String normalized = quality.toLowerCase();

    if (normalized == "4k") {
      return 4000;
    }

    if (normalized == "2k") {
      return 2000;
    }

    final RegExpMatch? match = RegExp(r"(\d{3,4})p").firstMatch(normalized);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }

    return 0;
  }

  return streams
    ..sort(
      (MediaStream a, MediaStream b) => qualityWeight(b.quality).compareTo(qualityWeight(a.quality)),
    );
}
