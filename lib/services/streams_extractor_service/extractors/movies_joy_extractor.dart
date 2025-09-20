import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html_parser;
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

class MoviesJoyExtractor implements BaseStreamExtractor {
  MoviesJoyExtractor() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: false,
        error: true,
        compact: true,
        enabled: kDebugMode,
      ),
    );
  }

  final String _providerKey = "semo_moviesjoy";
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

  List<Map<String, String?>> _parseSearchResults(Document document, Uri baseUri) {
    final List<Map<String, String?>> results = <Map<String, String?>>[];
    final List<Element> items = document.querySelectorAll(".flw-item");

    for (final Element item in items) {
      final Element? titleAnchor = item.querySelector("h2.film-name a");
      if (titleAnchor == null) {
        continue;
      }

      final String title = titleAnchor.text.trim();
      final String? href = titleAnchor.attributes["href"];
      if (href == null || href.isEmpty) {
        continue;
      }

      final String url = baseUri.resolve(href).toString();
      final Element? infoElement = item.querySelector(".fd-infor");
      final List<Element> infoSpans = infoElement?.querySelectorAll(".fdi-item") ?? <Element>[];

      String? year;
      for (final Element span in infoSpans) {
        final String text = span.text.trim();
        if (RegExp(r"^\d{4}").hasMatch(text)) {
          year = text.substring(0, 4);
          break;
        }
      }

      final String type = infoElement?.querySelector(".fdi-type")?.text.trim().toLowerCase() ?? "";

      results.add(
        <String, String?>{
          "title": title,
          "url": url,
          "year": year,
          "type": type,
        },
      );
    }

    return results;
  }

  Future<String?> _findSeasonId(int tvShowId, int season) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        return null;
      }

      final Uri requestUri = Uri.parse(baseUrl).resolve("ajax/season/list/$tvShowId");
      final Response<dynamic> response = await _dio.get(requestUri.toString());
      final Document document = html_parser.parse(response.data);
      final List<Element> seasonLinks = document.querySelectorAll("a[data-id]");

      for (final Element link in seasonLinks) {
        final String text = link.text.normalize();
        final String lookup = "season $season";

        if (text.contains(lookup)) {
          final String? seasonId = link.attributes["data-id"];
          if (seasonId != null && seasonId.isNotEmpty) {
            return seasonId;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _findEpisodeId(String seasonId, int episode) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        return null;
      }

      final Uri requestUri = Uri.parse(baseUrl).resolve("ajax/season/episodes/$seasonId");
      final Response<dynamic> response = await _dio.get(requestUri.toString());
      final Document document = html_parser.parse(response.data);
      final List<Element> episodeLinks = document.querySelectorAll("a[data-id]");

      for (final Element link in episodeLinks) {
        final String text = link.text.normalize();
        final String lookup = "eps $episode";

        if (text.contains(lookup)) {
          final String? episodeId = link.attributes["data-id"];
          if (episodeId != null && episodeId.isNotEmpty) {
            return episodeId;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _findEpisodeStreamServerId(String episodeId) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        return null;
      }

      final Uri requestUri = Uri.parse(baseUrl).resolve("ajax/episode/servers/$episodeId");
      final Response<dynamic> response = await _dio.get(requestUri.toString());
      final Document document = html_parser.parse(response.data);
      final Element? firstServer = document.querySelector("a[data-id]");

      if (firstServer == null) {
        return null;
      }

      final String? serverId = firstServer.attributes["data-id"];
      if (serverId == null || serverId.isEmpty) {
        return null;
      }

      return serverId;
    } catch (_) {}

    return null;
  }

  Future<String?> _findEpisodeUrl(String tvShowUrl, int season, int episode) async {
    final int? tvShowId = int.tryParse(tvShowUrl.normalize().split("-").last);

    if (tvShowId == null) {
      return null;
    }

    final String? seasonId = await _findSeasonId(tvShowId, season);
    if (seasonId == null) {
      return null;
    }

    final String? episodeId = await _findEpisodeId(seasonId, episode);
    if (episodeId == null) {
      return null;
    }

    final String? serverId = await _findEpisodeStreamServerId(episodeId);
    if (serverId == null) {
      return null;
    }

    return "$tvShowUrl.$serverId";
  }

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => true;

  @override
  Future<Map<String, Object?>?> getExternalLink(StreamExtractorOptions options) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      final Uri baseUri = Uri.parse(baseUrl);
      String normalizedQuery = options.title.normalize();
      normalizedQuery = normalizedQuery.replaceAll(RegExp(r"[^a-z0-9\s-]"), "");
      normalizedQuery = normalizedQuery.replaceAll(RegExp(" "), "-");

      if (normalizedQuery.isEmpty) {
        throw Exception("Failed to build search query for ${options.title}");
      }

      final Uri searchUri = baseUri.resolve("search/$normalizedQuery");
      final Response<dynamic> response = await _dio.get(searchUri.toString());
      final Document document = html_parser.parse(response.data);
      final List<Map<String, String?>> results = _parseSearchResults(document, baseUri);

      if (results.isEmpty) {
        return null;
      }

      final bool isTvShow = options.season != null && options.episode != null;
      final String targetTitle = options.title.normalize();
      Map<String, String?>? match;

      for (final Map<String, String?> result in results) {
        final String normalizedTitle = (result["title"] ?? "").normalize();
        final bool titleMatches = normalizedTitle == targetTitle || normalizedTitle.contains(targetTitle) || targetTitle.contains(normalizedTitle);

        if (!titleMatches) {
          continue;
        }

        if (isTvShow || (!isTvShow && options.releaseYear == null)) {
          final String type = (result["type"] ?? "").toLowerCase();

          if (type.contains("tv") || type.contains("show") || type.contains("series") || type.isEmpty) {
            match = result;
            break;
          }

          continue;
        }

        final String type = (result["type"] ?? "").toLowerCase();

        if (options.releaseYear != null && result["year"] != null) {
          if (type.isNotEmpty && !type.contains("movie")) {
            continue;
          }

          if (result["year"] == options.releaseYear) {
            match = result;
            break;
          }
          continue;
        }
      }

      String? externalLink = match?["url"];

      if (externalLink == null) {
        return null;
      }

      if (isTvShow) {
        externalLink = externalLink.replaceFirst("/tv/", "/watch-tv/");
        externalLink = await _findEpisodeUrl(externalLink, options.season!, options.episode!);
      } else {
        externalLink = externalLink.replaceFirst("/movie/", "/watch-movie/");
      }

      return <String, Object?>{
        "url": externalLink,
      };
    } catch (e, s) {
      _logger.e("Error fetching external link for MoviesJoy", error: e, stackTrace: s);
    }

    return null;
  }

  @override
  Future<List<MediaStream>> getStreams(StreamExtractorOptions options, {String? externalLink, Map<String, String>? externalLinkHeaders}) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final Map<String, dynamic>? stream = await _extractStreamFromPageRequestsService.extract(externalLink);
      final String? url = stream?["url"];
      Map<String, String> headers = stream?["headers"] ?? <String, String>{};

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for: $_providerKey");
      }

      return <MediaStream>[
        MediaStream(
          type: url.toLowerCase().contains("m3u8") || url.toLowerCase().contains("m3u") ? StreamType.hls : (url.toLowerCase().contains("mkv") ? StreamType.mkv : StreamType.mp4),
          url: url,
          headers: headers,
        ),
      ];
    } catch (e, s) {
      _logger.e("Error extracting stream in MoviesJoyExtractor", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }
}
