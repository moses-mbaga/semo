import "dart:async";

import "package:flutter_inappwebview/flutter_inappwebview.dart";

typedef PageRequestCallback = void Function(String url, Map<String, String> headers);

class PageNetworkRequestsSession {
  const PageNetworkRequestsSession({required this.webView});

  final HeadlessInAppWebView webView;

  Future<void> dispose() async {
    try {
      await webView.dispose();
    } catch (_) {}
  }
}

class PageNetworkRequests {
  static const String _defaultHandlerName = "pageNetworkRequestFound";

  static String _buildSnifferJs(List<String> includePatterns, String handlerName) {
    final List<String> patterns = includePatterns.map((String p) => p.toLowerCase()).toList(growable: false);
    final String jsCheck = patterns.map((String p) => "u.includes('${p.replaceAll("'", "\\'")}')").join(" || ");

    return """
(() => {
  const notify = (url, headers) => {
    try {
      window.flutter_inappwebview.callHandler('$handlerName', {url, headers});
    } catch(e) {}
  };

  const origFetch = window.fetch;
  window.fetch = async function(...args) {
    try {
      const req = args[0];
      const url = (typeof req === 'string') ? req : (req && req.url) ? req.url : '';
      const u = (url || '').toString().toLowerCase();
      if (u && ($jsCheck)) {
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
        if ($jsCheck) {
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
  }

  static bool _matchesIncludePatterns(String url, List<String> includePatterns) {
    final String u = url.toLowerCase();

    for (final String pattern in includePatterns) {
      if (u.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  static Future<PageNetworkRequestsSession> startCapture({
    required String pageUrl,
    required PageRequestCallback onRequest,
    List<String> includePatterns = const <String>[],
    Map<String, Future<dynamic> Function(List<dynamic>)>? extraHandlers,
    List<String>? extraOnLoadStopScripts,
    InAppWebViewSettings? settings,
  }) async {
    final InAppWebViewSettings effectiveSettings = settings ??
        InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldInterceptRequest: true,
          useOnLoadResource: true,
          mediaPlaybackRequiresUserGesture: false,
        );

    final String snifferJs = _buildSnifferJs(includePatterns, _defaultHandlerName);

    final HeadlessInAppWebView headless = HeadlessInAppWebView(
      initialSettings: effectiveSettings,
      initialUrlRequest: URLRequest(url: WebUri(pageUrl)),
      onWebViewCreated: (InAppWebViewController controller) async {
        controller.addJavaScriptHandler(
          handlerName: _defaultHandlerName,
          callback: (List<dynamic> args) async {
            if (args.isNotEmpty && args.first is Map) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(args.first as Map<dynamic, dynamic>);
              final String? url = data["url"] as String?;
              final Map<String, String> headers = Map<String, String>.from(data["headers"] ?? <String, String>{});

              if (url != null && url.isNotEmpty) {
                onRequest(url, headers);
              }
            }

            return null;
          },
        );

        if (extraHandlers != null && extraHandlers.isNotEmpty) {
          extraHandlers.forEach((String name, Future<dynamic> Function(List<dynamic>) callback) {
            controller.addJavaScriptHandler(handlerName: name, callback: callback);
          });
        }
      },
      onLoadStop: (InAppWebViewController controller, WebUri? url) async {
        await controller.evaluateJavascript(source: snifferJs);

        if (extraOnLoadStopScripts != null) {
          for (final String script in extraOnLoadStopScripts) {
            await controller.evaluateJavascript(source: script);
          }
        }
      },
      onLoadResource: (InAppWebViewController controller, LoadedResource resource) async {
        final String url = resource.url.toString();
        if (url.isNotEmpty && _matchesIncludePatterns(url, includePatterns)) {
          onRequest(url, <String, String>{});
        }
      },
      shouldInterceptRequest: (InAppWebViewController controller, WebResourceRequest request) async {
        final String url = request.url.toString();

        if (url.isNotEmpty && _matchesIncludePatterns(url, includePatterns)) {
          final Map<String, String> headers = <String, String>{};

          request.headers?.forEach((String key, String value) {
            headers[key] = value.toString();
          });

          onRequest(url, headers);
        }

        return null;
      },
    );

    await headless.run();
    return PageNetworkRequestsSession(webView: headless);
  }
}
