import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html_parser;
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_audio.dart";
import "package:semo/services/youtube_extractor_service/extractors/base_youtube_extractor.dart";
import "package:semo/services/youtube_extractor_service/extractors/utils/youtube_helpers.dart";
import "package:semo/services/youtube_extractor_service/extractors/utils/stream_probe.dart";

class PokeExtractor extends BaseYoutubeExtractor {
  PokeExtractor() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: false,
        responseBody: false,
        responseHeader: false,
        error: true,
        compact: true,
        enabled: kDebugMode,
      ),
    );
  }

  static const String _baseUrl = "https://poketube.fun";

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.plain,
    ),
  );
  final Logger _logger = Logger();
  final StreamProbe _streamProbe = StreamProbe();

  @override
  Future<List<MediaStream>> extractStreams(String youtubeUrl) async {
    final String trimmedUrl = youtubeUrl.trim();
    if (trimmedUrl.isEmpty) {
      return <MediaStream>[];
    }

    final Uri? normalizedYoutubeUri = normalizeYouTubeUri(trimmedUrl);
    if (normalizedYoutubeUri == null) {
      _logger.w("Failed to normalize YouTube URL for Poke extraction: $youtubeUrl");
      return <MediaStream>[];
    }

    final String? videoId = extractYouTubeVideoId(normalizedYoutubeUri);
    if (videoId == null || videoId.isEmpty) {
      _logger.w("Could not extract video ID from YouTube URL: ${normalizedYoutubeUri.toString()}");
      return <MediaStream>[];
    }

    final Uri downloadUri = Uri.parse("$_baseUrl/download?v=$videoId");

    try {
      final Response<String> response = await _dio.get<String>(downloadUri.toString());

      final int? statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        _logger.w("Poke request failed with status $statusCode for video $videoId");
        return <MediaStream>[];
      }

      final String? body = response.data;
      if (body == null || body.isEmpty) {
        _logger.w("Received empty response from ${downloadUri.host} for video $videoId");
        return <MediaStream>[];
      }

      final Document document = html_parser.parse(body);

      final _ParsedAudio? audio = _extractBestAudio(document, downloadUri);
      if (audio == null) {
        _logger.w("No suitable m4a audio streams found on ${downloadUri.host} for video $videoId");
        return <MediaStream>[];
      }

      final List<_ParsedVideo> videos = _extractMp4Videos(document, downloadUri);
      if (videos.isEmpty) {
        _logger.w("No mp4 video streams found on ${downloadUri.host} for video $videoId");
        return <MediaStream>[];
      }

      final StreamAudio externalAudio = StreamAudio(
        language: "Default",
        url: audio.url,
        isDefault: false,
      );

      final StreamProbeResult audioProbe = await _streamProbe.probe(
        audio.url,
        expectedMimeTypePrefixes: <String>["audio/"],
      );
      if (!audioProbe.isSuccessful) {
        _logger.w(
          "Poke audio probe failed for video $videoId: ${audioProbe.failureReason ?? "unknown reason"}"
          " (status=${audioProbe.statusCode}, contentType=${audioProbe.contentType})",
        );
        return <MediaStream>[];
      }

      if (audioProbe.usedFallbackMime) {
        _logger.i(
          "Poke audio probe accepted fallback mime for video $videoId (contentType=${audioProbe.contentType})",
        );
      }

      final _ParsedVideo primaryVideo = videos.first;
      final StreamProbeResult videoProbe = await _streamProbe.probe(
        primaryVideo.url,
        expectedMimeTypePrefixes: <String>["video/"],
      );
      if (!videoProbe.isSuccessful) {
        _logger.w(
          "Poke video probe failed for video $videoId: ${videoProbe.failureReason ?? "unknown reason"}"
          " (status=${videoProbe.statusCode}, contentType=${videoProbe.contentType})",
        );
        return <MediaStream>[];
      }

      if (videoProbe.usedFallbackMime) {
        _logger.i(
          "Poke video probe accepted fallback mime for video $videoId (contentType=${videoProbe.contentType})",
        );
      }

      return videos
          .map(
            (_ParsedVideo video) => MediaStream(
              type: StreamType.mp4,
              url: video.url,
              quality: video.label,
              audios: <StreamAudio>[externalAudio],
              hasDefaultAudio: false,
            ),
          )
          .toList();
    } catch (error, stackTrace) {
      _logger.e("Failed to fetch Poke streams", error: error, stackTrace: stackTrace);
    }

    return <MediaStream>[];
  }

  _ParsedAudio? _extractBestAudio(Document document, Uri baseUri) {
    final Element? audioSection = document.querySelector('section[aria-labelledby="audio"]');
    if (audioSection == null) {
      return null;
    }

    _ParsedAudio? bestAudio;
    int bestScore = -1;

    final List<Element> audioArticles = audioSection.querySelectorAll("article");
    for (final Element article in audioArticles) {
      final Element? meta = article.querySelector(".meta");
      if (meta == null) {
        continue;
      }

      final String label = meta.querySelector(".label")?.text.trim() ?? "";
      if (!label.toLowerCase().contains("m4a")) {
        continue;
      }

      final Element? link = article.querySelector("a");
      final String? href = link?.attributes["href"];
      final String? resolvedUrl = _resolveUrl(href, baseUri);
      if (resolvedUrl == null) {
        continue;
      }

      final Uri? hrefUri = _tryParseUri(href);
      if (hrefUri == null) {
        continue;
      }

      final int score = _audioScore(label);
      if (score > bestScore) {
        bestScore = score;
        bestAudio = _ParsedAudio(label: label.isEmpty ? "m4a" : label, url: resolvedUrl);
      }
    }

    return bestAudio;
  }

  List<_ParsedVideo> _extractMp4Videos(Document document, Uri baseUri) {
    final Element? videoSection = document.querySelector('section[aria-labelledby="videoonly"]');
    if (videoSection == null) {
      return <_ParsedVideo>[];
    }

    final List<_ParsedVideo> videos = <_ParsedVideo>[];
    final List<Element> videoArticles = videoSection.querySelectorAll("article");

    for (final Element article in videoArticles) {
      final Element? meta = article.querySelector(".meta");
      if (meta == null) {
        continue;
      }

      final String label = meta.querySelector(".label")?.text.trim() ?? "";

      final Element? link = article.querySelector("a");
      final String? href = link?.attributes["href"];
      final String? resolvedUrl = _resolveUrl(href, baseUri);
      if (resolvedUrl == null) {
        continue;
      }

      final Uri? hrefUri = _tryParseUri(href);
      if (hrefUri == null) {
        continue;
      }

      final int height = _extractHeight(label) ?? 0;

      videos.add(
        _ParsedVideo(
          label: label.isEmpty ? "MP4" : label,
          url: resolvedUrl,
          height: height,
        ),
      );
    }

    videos.sort((_ParsedVideo a, _ParsedVideo b) => b.height.compareTo(a.height));

    return videos;
  }

  int _audioScore(String label) {
    final String normalized = label.toLowerCase();
    if (normalized.contains("high")) {
      return 3;
    }

    if (normalized.contains("medium")) {
      return 2;
    }

    if (normalized.contains("low")) {
      return 1;
    }

    return 0;
  }

  int? _extractHeight(String label) {
    final RegExpMatch? match = RegExp(r"(\d{3,4})p", caseSensitive: false).firstMatch(label);
    if (match != null) {
      return int.tryParse(match.group(1) ?? "");
    }

    return null;
  }

  String? _resolveUrl(String? rawHref, Uri baseUri) {
    if (rawHref == null || rawHref.trim().isEmpty) {
      return null;
    }

    final String trimmed = rawHref.trim();

    try {
      final Uri hrefUri = Uri.parse(trimmed);
      final Uri resolved = hrefUri.hasScheme ? hrefUri : baseUri.resolveUri(hrefUri);
      return resolved.toString();
    } catch (_) {
      return null;
    }
  }

  Uri? _tryParseUri(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      return Uri.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}

class _ParsedAudio {
  _ParsedAudio({
    required this.label,
    required this.url,
  });

  final String label;
  final String url;
}

class _ParsedVideo {
  _ParsedVideo({
    required this.label,
    required this.url,
    required this.height,
  });

  final String label;
  final String url;
  final int height;
}
