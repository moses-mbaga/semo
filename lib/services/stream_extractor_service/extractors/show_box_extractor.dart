import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html_parser;
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/utils/streaming_server_base_url_extractor.dart";
import "package:semo/utils/string_extensions.dart";

class ShowBoxExtractor implements BaseStreamExtractor {
  ShowBoxExtractor() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        enabled: kDebugMode,
      ),
    );
  }

  final String _providerKey = "showbox";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  final Logger _logger = Logger();

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => true;

  @override
  Future<String?> getExternalLink(StreamExtractorOptions options) async {
    final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception("Failed to get base URL for $_providerKey");
    }

    final String searchQuery = Uri.encodeComponent(options.title);
    final String url = "$baseUrl/search?keyword=$searchQuery&page=1";

    final Response<dynamic> res = await _dio.get(url);
    final Document document = html_parser.parse(res.data);

    final List<Element> items = document.querySelectorAll(".movie-item,.flw-item");
    final List<Map<String, String>> catalog = <Map<String, String>>[];

    for (final Element element in items) {
      final String title = element.querySelector(".film-name")?.text.trim() ?? "";
      final String? link = element.querySelector("a")?.attributes["href"];
      final String? image = element.querySelector("img")?.attributes["src"];

      if (title.isNotEmpty && link != null && image != null) {
        catalog.add(<String, String>{
          "title": title,
          "link": link,
          "image": image,
        });
      }
    }

    if (catalog.isEmpty) {
      throw Exception("No search results found for ${options.title}");
    }

    String? selectedLink;
    for (final Map<String, String> post in catalog) {
      final String postTitle = "${post["title"]}".normalize();
      final String queryTitle = options.title.normalize();

      if (postTitle == queryTitle || postTitle.contains(queryTitle) || queryTitle.contains(postTitle)) {
        selectedLink = post["link"];
        break;
      }
    }

    selectedLink ??= catalog.first["link"];
    return selectedLink;
  }

  String _toAbsoluteUrl(String baseUrl, String href) {
    if (href.startsWith("http://") || href.startsWith("https://")) {
      return href;
    }

    if (href.startsWith("/")) {
      final Uri b = Uri.parse(baseUrl);
      return "${b.scheme}://${b.host}$href";
    }

    return baseUrl.endsWith("/") ? "$baseUrl$href" : "$baseUrl/$href";
  }

  (String endpointPath, String id)? _extractShareLinkInfo(Document document) {
    final List<Element> scripts = document.querySelectorAll("script");
    final RegExp endpointRegex = RegExp(r'''url\s*:\s*['\"]([^'\"]*share[_-]link[^'\"]*)['\"]''', caseSensitive: false);
    final RegExp idRegex = RegExp(r'''data\s*:\s*\{[^}]*['\"]id['\"]\s*:\s*(\d+)''', caseSensitive: false);

    for (final Element script in scripts) {
      final String content = script.text;
      if (content.isEmpty) {
        continue;
      }

      if (content.contains("share_link") && content.contains(r"$.ajax")) {
        final RegExpMatch? eMatch = endpointRegex.firstMatch(content);
        final RegExpMatch? iMatch = idRegex.firstMatch(content);

        if (eMatch != null && iMatch != null) {
          final String endpoint = eMatch.group(1) ?? "";
          final String id = iMatch.group(1) ?? "";

          if (endpoint.isNotEmpty && id.isNotEmpty) {
            return (endpoint, id);
          }
        }
      }
    }

    return null;
  }

  String? _extractShareKeyFromUrl(String febboxUrl) {
    try {
      final Uri uri = Uri.parse(febboxUrl);
      final List<String> segs = uri.pathSegments;
      final int idx = segs.indexWhere((String s) => s.toLowerCase() == "share");

      if (idx != -1 && idx + 1 < segs.length) {
        return segs[idx + 1];
      }

      return uri.queryParameters["share_key"] ?? (segs.isNotEmpty ? segs.last : null);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFileShareList(String shareKey, {String? parentId}) async {
    final Response<dynamic> res = await _dio.get(
      "https://www.febbox.com/file/file_share_list",
      queryParameters: <String, dynamic>{
        "share_key": shareKey,
        if (parentId != null) "parent_id": parentId,
      },
      options: Options(responseType: ResponseType.json),
    );

    final dynamic data = res.data;
    final List<dynamic> list = (data is Map && data["data"] is Map) ? (data["data"]["file_list"] as List<dynamic>? ?? <dynamic>[]) : <dynamic>[];

    return list.cast<Map<String, dynamic>>();
  }

  int _rankFromName(String name) {
    final String t = name.normalize();

    if (RegExp(r"1080p|\b1080\b").hasMatch(t)) {
      return 0;
    }
    if (RegExp(r"720p|\b720\b").hasMatch(t)) {
      return 1;
    }
    if (RegExp(r"480p|\b480\b").hasMatch(t)) {
      return 2;
    }
    if (RegExp(r"360p|\b360\b").hasMatch(t)) {
      return 3;
    }

    return 100;
  }

  String? _pickBestFidFromFiles(List<Map<String, dynamic>> files) {
    String? fid;
    int best = 9999;

    for (final Map<String, dynamic> f in files) {
      final String name = (f["file_name"] ?? "").toString();
      final int r = _rankFromName(name);

      if (r < best) {
        best = r;
        fid = f["fid"]?.toString();
        if (best == 0) {
          break;
        }
      }
    }

    return fid ?? (files.isNotEmpty ? files.first["fid"]?.toString() : null);
  }

  String? _pickSeasonFid(List<Map<String, dynamic>> files, int season) {
    for (final Map<String, dynamic> f in files) {
      final String name = "${f["file_name"]}".normalize();
      final RegExp re = RegExp(r"season\s*(\d+)");
      final Match? m = re.firstMatch(name);

      if (m != null) {
        final int s = int.tryParse(m.group(1) ?? "") ?? -1;
        if (s == season) {
          return f["fid"]?.toString();
        }
      }
    }
    return null;
  }

  String? _pickEpisodeFid(List<Map<String, dynamic>> files, int season, int episode) {
    final RegExp re = RegExp(r"[sS](\d{1,2})[eE](\d{1,2})");

    for (final Map<String, dynamic> f in files) {
      final String name = (f["file_name"] ?? "").toString();
      final Match? m = re.firstMatch(name);

      if (m != null) {
        final int s = int.tryParse(m.group(1) ?? "") ?? -1;
        final int e = int.tryParse(m.group(2) ?? "") ?? -1;
        if (s == season && e == episode) {
          return f["fid"]?.toString();
        }
      }
    }

    return null;
  }

  @override
  Future<MediaStream?> getStream(String? externalLink, StreamExtractorOptions options) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      // 1) Open actual movie page (ensure absolute URL)
      final String moviePageUrl = _toAbsoluteUrl(baseUrl, externalLink);
      final Response<dynamic> movieRes = await _dio.get(moviePageUrl);
      final Document movieDoc = html_parser.parse(movieRes.data);

      // 2) Parse inline script to find ajax endpoint and id
      final (String endpointPath, String id)? ajaxInfo = _extractShareLinkInfo(movieDoc);
      if (ajaxInfo == null) {
        throw Exception("Failed to locate share_link ajax info on movie page");
      }

      // 3) Request endpoint to get febbox link
      final String ajaxUrl = _toAbsoluteUrl(baseUrl, ajaxInfo.$1);
      final bool isTvShow = options.season != null && options.episode != null;
      final Response<dynamic> ajaxRes = await _dio.get(
        ajaxUrl,
        queryParameters: <String, dynamic>{
          "id": ajaxInfo.$2,
          "type": isTvShow ? 2 : 1,
        },
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      final dynamic ajaxData = ajaxRes.data;
      final String? febboxUrl = (ajaxData is Map && ajaxData["data"] is Map) ? (ajaxData["data"]["link"] as String?) : null;
      if (febboxUrl == null || febboxUrl.isEmpty) {
        throw Exception("No febbox link returned by share_link endpoint");
      }

      // 4) Use febbox API to list shared files
      final String? shareKey = _extractShareKeyFromUrl(febboxUrl);
      if (shareKey == null || shareKey.isEmpty) {
        throw Exception("Failed to extract share key from $febboxUrl");
      }

      final List<Map<String, dynamic>> rootFiles = await _fetchFileShareList(shareKey);

      String? targetFid;
      if (options.season != null && options.episode != null) {
        final String? seasonFid = _pickSeasonFid(rootFiles, options.season!);
        if (seasonFid == null) {
          throw Exception("Season ${options.season} not found in febbox share");
        }

        final List<Map<String, dynamic>> episodeFiles = await _fetchFileShareList(shareKey, parentId: seasonFid);
        targetFid = _pickEpisodeFid(episodeFiles, options.season!, options.episode!);

        if (targetFid == null) {
          throw Exception("Episode S${options.season}E${options.episode} not found in febbox share");
        }
      } else {
        targetFid = _pickBestFidFromFiles(rootFiles);
        if (targetFid == null) {
          throw Exception("No files available in febbox share");
        }
      }

      // 5) Use vercel endpoint with fid to get playable link(s)
      final String qualityUrl = "https://febbox.vercel.app/api/video-quality?fid=$targetFid";
      final Response<dynamic> qRes = await _dio.get(qualityUrl);
      final String? html = (qRes.data is Map) ? qRes.data["html"] as String? : null;
      if (html == null || html.isEmpty) {
        throw Exception("No HTML in video-quality response for fid=$targetFid");
      }

      final Document qDoc = html_parser.parse(html);
      final List<Element> qualities = qDoc.querySelectorAll(".file_quality");

      for (final Element el in qualities) {
        final String? link = el.attributes["data-url"];

        if (link != null && link.isNotEmpty) {
          return MediaStream(url: link);
        }
      }
    } catch (e, s) {
      _logger.e("Error in ShowBoxExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
