import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html_parser;
import "package:semo/models/media_stream.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/stream_extractor_options.dart";
import "package:semo/services/stream_extractor_service/extractors/base_stream_extractor.dart";
import "package:semo/services/stream_extractor_service/extractors/streaming_server_base_url_extractor.dart";

class MoviesApiExtractor implements BaseStreamExtractor {
  MoviesApiExtractor() {
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

  final String _providerKey = "moviesapi";
  final StreamingServerBaseUrlExtractor _streamingServerBaseUrlExtractor = StreamingServerBaseUrlExtractor();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  final Logger _logger = Logger();

  Future<Map<String, dynamic>?> _extractStream(String pageUrl) async {
    final Set<String> seen = <String>{};
    final Completer<Map<String, dynamic>?> completer = Completer<Map<String, dynamic>?>();
    HeadlessInAppWebView? headless;

    Map<String, dynamic>? hlsCandidate;
    Map<String, dynamic>? mp4Candidate;
    Map<String, dynamic>? mkvCandidate;

    bool isHls(String url) {
      final String u = url.toLowerCase();
      return u.contains("m3u8");
    }

    bool isMp4(String url) {
      final String u = url.toLowerCase();
      return u.contains(".mp4");
    }

    bool isMkv(String url) {
      final String u = url.toLowerCase();
      return u.contains(".mkv");
    }

    Future<void> finish([Map<String, dynamic>? value]) async {
      if (!completer.isCompleted) {
        value ??= hlsCandidate ?? mp4Candidate ?? mkvCandidate;
        completer.complete(value);
      }
      try {
        await headless?.dispose();
      } catch (_) {}
    }

    void consider(String url, Map<String, String> headers) {
      if (!seen.add(url)) {
        return;
      }

      if (isHls(url)) {
        hlsCandidate ??= <String, dynamic>{"url": url, "headers": headers};
        unawaited(finish(hlsCandidate));
      } else if (isMp4(url)) {
        mp4Candidate ??= <String, dynamic>{"url": url, "headers": headers};
      } else if (isMkv(url)) {
        mkvCandidate ??= <String, dynamic>{"url": url, "headers": headers};
      }
    }

    final String jsSniffer = """
(() => {
  const notify = (url, headers) => {
    try { 
      window.flutter_inappwebview.callHandler('streamLinkFound', {url, headers}); 
    } catch(e) {}
  };

  const origFetch = window.fetch;
  window.fetch = async function(...args) {
    try {
      const req = args[0];
      const url = (typeof req === 'string') ? req : (req && req.url) ? req.url : '';
      const u = (url || '').toString().toLowerCase();
      if (u && (u.includes('.m3u8') || u.includes('.mp4') || u.includes('.mkv'))) {
        let headers = {};
        if (req && req.headers && typeof req.headers.forEach === 'function') {
          req.headers.forEach((v,k)=>{headers[k]=v});
        }
        notify(url, headers);
      }
    } catch(e) {}
    return origFetch.apply(this, args);
  };

  const OrigXHR = window.XMLHttpRequest;
  function XHR() {
    const xhr = new OrigXHR();
    const open = xhr.open;
    xhr.open = function(method, url, ...rest) {
      try {
        const u = (url || '').toString().toLowerCase();
        if (u.includes('.m3u8') || u.includes('.mp4') || u.includes('.mkv')) {
          let headers = {};
          notify(url, headers);
        }
      } catch(e) {}
      return open.call(this, method, url, ...rest);
    };
    return xhr;
  }
  window.XMLHttpRequest = XHR;
})();
""";

    headless = HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldInterceptRequest: true,
        useOnLoadResource: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      initialUrlRequest: URLRequest(url: WebUri(pageUrl)),
      onWebViewCreated: (InAppWebViewController controller) async {
        controller.addJavaScriptHandler(
          handlerName: "streamLinkFound",
          callback: (List<dynamic> args) async {
            if (args.isNotEmpty && args.first is Map) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(args.first as Map<dynamic, dynamic>);
              final String? url = data["url"] as String?;
              final Map<String, String> headers = Map<String, String>.from(data["headers"] ?? <String, String>{});

              if (url != null && url.isNotEmpty) {
                consider(url, headers);
              }
            }

            return null;
          },
        );
      },
      onLoadStop: (InAppWebViewController controller, WebUri? url) async {
        await controller.evaluateJavascript(source: jsSniffer);
      },
      onLoadResource: (InAppWebViewController controller, LoadedResource resource) async {
        final String url = resource.url.toString();
        if (url.isNotEmpty && (isHls(url) || isMp4(url) || isMkv(url))) {
          consider(url, <String, String>{});
        }
      },
      shouldInterceptRequest: (InAppWebViewController controller, WebResourceRequest request) async {
        final String url = request.url.toString();

        if (url.isNotEmpty && (isHls(url) || isMp4(url) || isMkv(url))) {
          final Map<String, String> headers = <String, String>{};

          request.headers?.forEach((String key, String value) {
            headers[key] = value.toString();
          });

          consider(url, headers);
        }

        return null;
      },
    );

    await headless.run();

    // Timeout: choose best candidate by preference order
    await Future<void>.delayed(const Duration(seconds: 10), () => finish());

    return completer.future;
  }

  @override
  List<MediaType> get acceptedMediaTypes => <MediaType>[MediaType.movies, MediaType.tvShows];

  @override
  bool get needsExternalLink => true;

  @override
  Future<String?> getExternalLink(StreamExtractorOptions options) async {
    try {
      final String? baseUrl = await _streamingServerBaseUrlExtractor.getBaseUrl(_providerKey);
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Failed to get base URL for $_providerKey");
      }

      final bool isTv = options.season != null && options.episode != null;
      final String path = isTv ? "/tv/${options.tmdbId}-${options.season}-${options.episode}" : "/movie/${options.tmdbId}";

      final Uri pageUri = Uri.parse(baseUrl).resolve(path);

      final Response<dynamic> res = await _dio.get(pageUri.toString());
      final Document document = html_parser.parse(res.data);

      final List<Element> iframes = document.getElementsByTagName("iframe");
      String? iframeSrc;

      for (final Element iframe in iframes) {
        final String? src = iframe.attributes["src"];
        if (src == null || src.isEmpty) {
          continue;
        }

        final String s = src.trim();
        final String sl = s.toLowerCase();

        if (sl.startsWith("https://vidora.stream")) {
          iframeSrc = s;
          break;
        }
      }

      if (iframeSrc == null || iframeSrc.isEmpty) {
        throw Exception("Vidora iframe not found for $_providerKey: ${pageUri.toString()}");
      }

      final Uri iframeUri = Uri.parse(iframeSrc);
      final String externalUrl = iframeUri.hasScheme ? iframeUri.toString() : pageUri.resolveUri(iframeUri).toString();

      return externalUrl;
    } catch (e, s) {
      _logger.e("Error getting external link for MoviesApi", error: e, stackTrace: s);
    }

    return null;
  }

  @override
  Future<MediaStream?> getStream(String? externalLink, StreamExtractorOptions options) async {
    try {
      if (externalLink == null || externalLink.isEmpty) {
        throw Exception("External link is required for $_providerKey");
      }

      final Map<String, dynamic>? stream = await _extractStream(externalLink);
      final String? url = stream?["url"];
      Map<String, String> headers = stream?["headers"] ?? <String, String>{};

      if (url == null || url.isEmpty) {
        throw Exception("No stream URL found for external link: $externalLink");
      }

      if (!headers.containsKey("Origin") || !headers.containsKey("Referer")) {
        headers["Origin"] = "https://vidora.stream";
        headers["Referer"] = "https://vidora.stream";
      }

      return MediaStream(
        url: url,
        headers: headers,
      );
    } catch (e, s) {
      _logger.e("Error extracting stream in MoviesApiExtractor", error: e, stackTrace: s);
    }

    return null;
  }
}
