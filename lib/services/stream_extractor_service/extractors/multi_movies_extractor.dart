import "dart:async";
import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html_parser;
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";
import "package:semo/utils/string_extensions.dart";

class MultiMoviesExtractor implements BaseStreamExtractor {
  MultiMoviesExtractor() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: false,
        error: true,
        compact: true,
        enabled: kDebugMode,
      ),
    );
  }

  final String _providerKey = "multi";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: <String, String>{
        "sec-ch-ua": '"Not_A Brand";v="8", "Chromium";v="120", "Microsoft Edge";v="120"',
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": '"Windows"',
        "Referer": "https://multimovies.online/",
        "Sec-Fetch-User": "?1",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0",
      },
    ),
  );
  final Logger _logger = Logger();

  List<Map<String, String>> _parsePostsFromDocument(Document document) {
    final List<Map<String, String>> catalog = <Map<String, String>>[];
    final List<Element> items = document.querySelectorAll(".items.full,.result-item");

    for (final Element item in items) {
      final List<Element> children = item.children;

      for (final Element element in children) {
        final Element? posterElement = element.querySelector(".poster,.image");
        final Element? detailsElement = element.querySelector(".details,.meta");

        if (posterElement == null) {
          continue;
        }

        final Element? imgElement = posterElement.querySelector("img");
        final Element? linkElement = posterElement.querySelector("a");
        final Element? yearElement = detailsElement?.querySelector(".year");

        if (imgElement == null || linkElement == null) {
          continue;
        }

        final String? title = imgElement.attributes["alt"];
        final String? link = linkElement.attributes["href"];
        final String year = yearElement?.text.trim() ?? "";

        if (title != null && link != null) {
          catalog.add(<String, String>{
            "title": title,
            "year": year,
            "link": link,
          });
        }
      }
    }

    return catalog;
  }

  Future<String?> _findEpisodeUrl(String tvShowUrl, int seasonNumber, int episodeNumber) async {
    final Response<dynamic> response = await _dio.get(tvShowUrl);
    final Document document = html_parser.parse(response.data);
    List<Map<String, String>> episodes = _parseEpisodesFromDocument(document);

    if (episodes.isEmpty) {
      throw Exception("No episodes found for $tvShowUrl");
    }

    String? targetEpisodeUrl;

    for (final Map<String, String> episode in episodes) {
      if (episode["season"] == "$seasonNumber" && episode["episode"] == "$episodeNumber") {
        targetEpisodeUrl = episode["link"];
        break;
      }
    }

    return targetEpisodeUrl;
  }

  List<Map<String, String>> _parseEpisodesFromDocument(Document document) {
    final List<Map<String, String>> catalog = <Map<String, String>>[];
    final List<Element> items = document.querySelectorAll("#episodes,#seasons");

    for (final Element item in items) {
      final List<Element> children = item.children;

      for (final Element element in children) {
        final List<Element> seasonElements = element.children;

        for (final Element seasonElement in seasonElements) {
          final List<Element> episodeElements = seasonElement.querySelectorAll(".se-a,ul,li");

          for (final Element episodeElement in episodeElements) {
            final Element? episodeNumberElement = episodeElement.querySelector(".numerando");
            final Element? linkElement = episodeElement.querySelector("a");

            if (episodeNumberElement == null || linkElement == null) {
              continue;
            }

            final List<String> seasonEpisodeNumber = episodeNumberElement.text.normalize().split("-");
            final String seasonNumber = seasonEpisodeNumber[0].trim();
            final String episodeNumber = seasonEpisodeNumber[1].trim();
            final String? link = linkElement.attributes["href"];

            if (link != null) {
              catalog.add(<String, String>{
                "season": seasonNumber,
                "episode": episodeNumber,
                "link": link,
              });
            }
          }
        }
      }
    }

    return catalog;
  }

  Future<MediaStream?> _extractStream(String url) async {
    try {
      final Response<dynamic> response = await _dio.get(url);
      final Document document = html_parser.parse(response.data);

      final Element? playerOption = document.querySelector("#player-option-1");
      if (playerOption == null) {
        return null;
      }

      final String? postId = playerOption.attributes["data-post"];
      final String? nume = playerOption.attributes["data-nume"];
      final String? typeValue = playerOption.attributes["data-type"];

      final Uri uri = Uri.parse(url);
      final String baseUrl = "${uri.scheme}://${uri.host}";

      // Make AJAX request to get player data
      final FormData formData = FormData.fromMap(<String, String>{
        "action": "doo_player_ajax",
        "post": postId ?? "",
        "nume": nume ?? "",
        "type": typeValue ?? "",
      });

      final Response<dynamic> playerResponse = await _dio.post(
        "$baseUrl/wp-admin/admin-ajax.php",
        data: formData,
      );

      final Map<String, dynamic> playerData = playerResponse.data as Map<String, dynamic>;
      _logger.d("Player data: $playerData");

      String? iframeUrl = _extractIframeUrl(playerData["embed_url"]);
      _logger.d("Initial iframe URL: $iframeUrl");

      if (iframeUrl == null) {
        return null;
      }

      // Handle external iframe processing
      if (!iframeUrl.contains("multimovies")) {
        iframeUrl = await _processExternalIframe(iframeUrl);
      }

      if (iframeUrl == null) {
        return null;
      }

      // Get the iframe content and extract stream
      final Response<dynamic> iframeResponse = await _dio.get(
        iframeUrl,
        options: Options(
          headers: <String, String>{
            "Referer": url,
          },
        ),
      );

      final String? streamUrl = _extractStreamUrl(iframeResponse.data);

      if (streamUrl != null) {
        final String cleanedStreamUrl = streamUrl.replaceAll(
          RegExp("&i=\\d+,'\\.4&"),
          "&i=0.4&",
        );
        return MediaStream(
          url: cleanedStreamUrl,
        );
      }
    } catch (e, s) {
      _logger.e("Error extracting stream", error: e, stackTrace: s);
    }

    return null;
  }

  String? _extractIframeUrl(String? embedUrl) {
    if (embedUrl == null) {
      return null;
    }

    final RegExp iframeRegex = RegExp('<iframe[^>]+src="([^"]+)"[^>]*>', caseSensitive: false);
    final RegExpMatch? match = iframeRegex.firstMatch(embedUrl);

    return match?.group(1) ?? embedUrl;
  }

  Future<String?> _processExternalIframe(String iframeUrl) async {
    try {
      final Uri uri = Uri.parse(iframeUrl);
      String playerBaseUrl = "${uri.scheme}://${uri.host}";

      // Try to get the actual base URL through redirects
      try {
        final Response<dynamic> headResponse = await _dio.head(
          playerBaseUrl,
          options: Options(
            followRedirects: true,
            maxRedirects: 5,
          ),
        );

        if (headResponse.realUri.toString() != playerBaseUrl) {
          final Uri realUri = headResponse.realUri;
          playerBaseUrl = "${realUri.scheme}://${realUri.host}";
        }
      } catch (e) {
        // If head request fails, try with maxRedirects: 0
        try {
          final Response<dynamic> response = await _dio.head(
            playerBaseUrl,
            options: Options(
              followRedirects: false,
              validateStatus: (int? status) => status != null && status >= 200 && status < 400,
            ),
          );

          final String? location = response.headers["location"]?.first;
          if (location != null) {
            playerBaseUrl = location;
          }
        } catch (e, s) {
          _logger.e("Error getting player base URL", error: e, stackTrace: s);
        }
      }

      final String playerId = uri.pathSegments.last;
      final FormData formData = FormData.fromMap(<String, String>{
        "sid": playerId,
      });

      _logger.d("External form data: $playerBaseUrl/embedhelper.php");

      final Response<dynamic> playerResponse = await _dio.post(
        "$playerBaseUrl/embedhelper.php",
        data: formData,
      );

      final Map<String, dynamic> playerData = playerResponse.data as Map<String, dynamic>;
      final String? siteUrl = playerData["siteUrls"]?["smwh"];

      String? siteId;
      if (playerData["mresult"] is String) {
        try {
          final String decoded = utf8.decode(base64.decode(playerData["mresult"]));
          final Map<String, dynamic> decodedData = jsonDecode(decoded);
          siteId = decodedData["smwh"];
        } catch (e, s) {
          _logger.e("Error decoding mresult", error: e, stackTrace: s);
        }
      } else if (playerData["mresult"] is Map) {
        siteId = playerData["mresult"]["smwh"];
      }

      if (siteUrl != null && siteId != null) {
        final String newIframeUrl = siteUrl + siteId;
        _logger.d("New iframe URL: $newIframeUrl");
        return newIframeUrl;
      }

      return iframeUrl;
    } catch (e, s) {
      _logger.e("Error processing external iframe", error: e, stackTrace: s);
      return iframeUrl;
    }
  }

  String? _extractStreamUrl(String iframeData) {
    // Extract the eval function and decode it
    final RegExp functionRegex = RegExp(r"eval\(function\((.*?)\)\{.*?return p\}.*?\('(.*?)'\.split");
    final RegExpMatch? match = functionRegex.firstMatch(iframeData);

    if (match == null) {
      return null;
    }

    final String? encodedString = match.group(2);
    if (encodedString == null) {
      return null;
    }

    final List<String> parts = encodedString.split("',36,");
    if (parts.length < 2) {
      return null;
    }

    String p = parts[0].trim();
    final List<String> k = parts[1].substring(2).split("|");
    final int c = k.length;

    for (int i = c - 1; i >= 0; i--) {
      if (k[i].isNotEmpty) {
        final RegExp regex = RegExp("\\b${i.toRadixString(36)}\\b");
        p = p.replaceAll(regex, k[i]);
      }
    }

    // Extract stream URL from decoded string
    final RegExp streamRegex = RegExp(r'https?://[^"]+?\.m3u8[^"]*');
    final RegExpMatch? streamMatch = streamRegex.firstMatch(p);

    return streamMatch?.group(0);
  }

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => true;

  @override
  Future<Map<String, Object?>?> getExternalLink(StreamExtractorOptions options) async {
    final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception("Failed to get base URL for $_providerKey");
    }

    String searchQuery = Uri.encodeComponent(options.title);
    String searchUrl = "$baseUrl/?s=$searchQuery";

    final Response<dynamic> response = await _dio.get(searchUrl);
    final Document document = html_parser.parse(response.data);
    List<Map<String, String>> posts = _parsePostsFromDocument(document);

    if (posts.isEmpty) {
      throw Exception("No search results found for ${options.title}");
    }

    String? targetPostUrl;

    for (final Map<String, String> post in posts) {
      final String lowerPostTitle = "${post["title"]}".normalize();
      final String lowerSearchTitle = options.title.normalize();

      if (options.releaseYear != null) {
        if (lowerPostTitle.contains(lowerSearchTitle) && "${post["year"]}" == options.releaseYear!) {
          targetPostUrl = post["link"];
          break;
        }
      }

      if (lowerPostTitle == lowerSearchTitle || lowerPostTitle.contains(lowerSearchTitle)) {
        targetPostUrl = post["link"];
        break;
      }
    }

    if (targetPostUrl == null || targetPostUrl.isEmpty) {
      return null;
    }

    return <String, Object?>{
      "url": targetPostUrl,
    };
  }

  @override
  Future<MediaStream?> getStream(StreamExtractorOptions options, {String? externalLink, Map<String, String>? externalLinkHeaders}) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      if (options.season != null && options.episode != null) {
        final String? episodeUrl = await _findEpisodeUrl(externalLink, options.season!, options.episode!);
        if (episodeUrl != null) {
          return await _extractStream(episodeUrl);
        } else {
          throw Exception("Failed to find episode URL for ${options.title} S${options.season}E${options.episode}");
        }
      } else {
        return _extractStream(externalLink);
      }
    } catch (e, s) {
      _logger.e("Error in MultiMoviesExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
