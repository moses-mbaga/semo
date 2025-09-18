import "dart:async";
import "dart:io";
import "dart:math" as math;

import "package:logger/logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/hls_audio_rendition.dart";
import "package:semo/models/hls_manifest.dart";
import "package:semo/models/hls_variant_stream.dart";
import "package:semo/models/stream_audio.dart";
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
import "package:semo/services/hls_parser_service.dart";
import "package:semo/services/stream_extractor_service/extractors/utils/closest_resolution.dart";

class StreamExtractorService {
  static final Logger _logger = Logger();
  static const HlsParserService _hlsParserService = HlsParserService();
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

  static Future<List<MediaStream>> getStreams(StreamExtractorOptions options) async {
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

  static Future<List<MediaStream>> _postProcessStreams(List<MediaStream> streams) async {
    final List<MediaStream> hlsStreams = streams.where((MediaStream stream) => stream.type == StreamType.hls).toList();
    final List<MediaStream> fileStreams = streams.where((MediaStream stream) => stream.type == StreamType.mp4 || stream.type == StreamType.mkv).toList();

    if (hlsStreams.isNotEmpty) {
      final List<MediaStream>? processedHls = await _selectWorkingHlsStream(hlsStreams);
      if (processedHls != null && processedHls.isNotEmpty) {
        return processedHls;
      }
    }

    if (fileStreams.isNotEmpty) {
      final List<MediaStream> processedFiles = await _processFileStreams(fileStreams);
      if (processedFiles.isNotEmpty) {
        return processedFiles;
      }
    }

    return streams;
  }

  static Future<List<MediaStream>?> _selectWorkingHlsStream(List<MediaStream> hlsStreams) async {
    List<MediaStream>? autoFallback;

    for (final MediaStream stream in hlsStreams) {
      final List<MediaStream>? processed = await _buildHlsQualityStreams(stream);
      if (processed == null || processed.isEmpty) {
        continue;
      }

      if (processed.length > 1) {
        return processed;
      }

      autoFallback ??= processed;
    }

    return autoFallback;
  }

  static Future<List<MediaStream>?> _buildHlsQualityStreams(MediaStream stream) async {
    try {
      final HlsManifest manifest = await _hlsParserService.fetchAndParseMasterPlaylist(
        stream.url,
        headers: stream.headers,
      );

      List<StreamAudio>? audios;

      if (manifest.audios.isNotEmpty) {
        final List<StreamAudio> collectedAudios = <StreamAudio>[];

        for (final HlsAudioRendition audio in manifest.audios) {
          if (audio.language == null || audio.uri == null) {
            continue;
          }

          collectedAudios.add(
            StreamAudio(
              language: audio.language!,
              url: audio.uri!.toString(),
              isDefault: audio.isDefault,
            ),
          );
        }

        if (collectedAudios.isNotEmpty) {
          audios = collectedAudios;
        }
      }

      final List<MediaStream> result = <MediaStream>[
        MediaStream(
          type: StreamType.hls,
          url: stream.url,
          headers: stream.headers,
          quality: "Auto",
          subtitles: stream.subtitles,
          audios: audios,
        ),
      ];

      if (!manifest.isEmpty) {
        for (final HlsVariantStream variant in manifest.variants) {
          String quality = "Auto";

          try {
            if (variant.width != null && variant.height != null) {
              quality = getClosestResolutionFromDimensions(variant.width!, variant.height!);
            } else if (variant.bandwidth != null) {
              quality = getClosestResolutionFromBandwidth(variant.bandwidth!);
            }
          } catch (_) {}

          result.add(
            MediaStream(
              type: StreamType.hls,
              url: variant.uri.toString(),
              headers: stream.headers,
              quality: quality,
              subtitles: stream.subtitles,
              audios: audios,
            ),
          );
        }
      }

      // Arrange streams, from highest to lowest quality (Auto is always first)
      if (result.length <= 1) {
        return result;
      }

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

      final MediaStream autoStream = result.first;
      final List<MediaStream> variantStreams = result.skip(1).toList()
        ..sort(
          (MediaStream a, MediaStream b) => qualityWeight(b.quality).compareTo(qualityWeight(a.quality)),
        );

      return <MediaStream>[autoStream, ...variantStreams];
    } catch (e, s) {
      _logger.w("Failed to extract stream qualities", error: e, stackTrace: s);
    }

    return null;
  }

  static Future<List<MediaStream>> _processFileStreams(List<MediaStream> fileStreams) async {
    List<MediaStream> streams = <MediaStream>[];

    for (int i = 0; i < fileStreams.length; i++) {
      MediaStream stream = fileStreams[i];
      streams.add(
        MediaStream(
          type: stream.type,
          url: stream.url,
          headers: stream.headers,
          quality: "Stream ${i + 1}",
          subtitles: stream.subtitles,
          audios: stream.audios,
        ),
      );
    }

    return streams;
  }
}
