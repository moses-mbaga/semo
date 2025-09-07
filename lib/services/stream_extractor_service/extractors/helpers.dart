import "dart:async";

import "package:diacritic/diacritic.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";

String normalizeForComparison(String text) => removeDiacritics(text)
    .replaceAll(RegExp("[–—−]"), "-") // Replace various dash types
    .replaceAll(RegExp(r"\s+"), " ") // Normalize whitespace
    .toLowerCase()
    .trim();

Future<Map<String, dynamic>?> extractStreamFromPage(String pageUrl, {bool Function(String url)? filter}) async {
  final Set<String> seen = <String>{};
  final Completer<Map<String, dynamic>?> completer = Completer<Map<String, dynamic>?>();
  HeadlessInAppWebView? headless;

  Map<String, dynamic>? hlsCandidate;
  Map<String, dynamic>? mp4Candidate;
  Map<String, dynamic>? mkvCandidate;
  bool readyToCapture = false;

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
    if (!readyToCapture) {
      return;
    }
    if (filter != null && !filter(url)) {
      return;
    }
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

// Find requests that contain m3u8, mp4 or mvk
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

  // Find and click a Skip button, wait until it is unlocked (no "Skip in X")
  final String jsSkipAndReady = """
(() => {
  const notifyReady = () => { try { window.flutter_inappwebview.callHandler('skipReady'); } catch(e) {} };

  function isUnlockedText(text) {
    if (!text) return false;
    const t = text.toLowerCase().trim();
    if (!t.includes('skip')) return false;
    return !(/skip\s*in\s*\d/.test(t));
  }

  function tryClick(el) {
    try {
      el.click();
      try { el.dispatchEvent(new MouseEvent('click', {bubbles:true, cancelable:true, view: window})); } catch(e) {}
      notifyReady();
      return true;
    } catch(e) {}
    return false;
  }

  function scan() {
    const nodes = Array.from(document.querySelectorAll('button, a, div, span'));
    for (const el of nodes) {
      const txt = (el.innerText || el.textContent || '').trim();
      if (!txt || !/skip/i.test(txt)) continue;
      if (isUnlockedText(txt)) {
        if (tryClick(el)) return true;
      } else {
        try {
          const obs = new MutationObserver(() => {
            const t2 = (el.innerText || el.textContent || '').trim();
            if (isUnlockedText(t2)) { tryClick(el); obs.disconnect(); }
          });
          obs.observe(el, {characterData: true, childList: true, subtree: true});
        } catch(e) {}
      }
    }
    return false;
  }

  let clicked = false;
  if (scan()) clicked = true;
  const interval = setInterval(() => {
    if (clicked) { clearInterval(interval); return; }
    if (scan()) { clicked = true; clearInterval(interval); }
  }, 500);

  // Safety timeout: if no Skip is found/unlocked, allow capture anyway
  setTimeout(() => { if (!clicked) notifyReady(); }, 8000);
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
      controller.addJavaScriptHandler(
        handlerName: "skipReady",
        callback: (List<dynamic> args) async {
          readyToCapture = true;
          return null;
        },
      );
    },
    onLoadStop: (InAppWebViewController controller, WebUri? url) async {
      await controller.evaluateJavascript(source: jsSniffer);
      await controller.evaluateJavascript(source: jsSkipAndReady);
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

  // Timeout: allow time for skip + stream to appear, then pick best
  await Future<void>.delayed(const Duration(seconds: 20), () => finish());

  return completer.future;
}
