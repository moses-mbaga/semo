import "dart:async";

import "package:semo/services/page_network_requests_service.dart";

// ignore_for_file: unnecessary_string_escapes

class ExtractStreamFromPageRequestsService {
  const ExtractStreamFromPageRequestsService();

  Future<Map<String, dynamic>?> extract(
    String pageUrl, {
    List<String> includePatterns = const <String>[".m3u8", ".mp4", ".mkv"],
    bool Function(String url)? filter,
    bool hasAds = false,
  }) async {
    final Set<String> seen = <String>{};
    final Completer<Map<String, dynamic>?> completer = Completer<Map<String, dynamic>?>();
    PageNetworkRequestsSession? session;

    Map<String, dynamic>? hlsCandidate;
    Map<String, dynamic>? mp4Candidate;
    Map<String, dynamic>? mkvCandidate;

    // Pre-skip candidates captured before ready
    // Used as fallback
    Map<String, dynamic>? preHlsCandidate;
    Map<String, dynamic>? preMp4Candidate;
    Map<String, dynamic>? preMkvCandidate;

    bool readyToCapture = false;

    bool isHls(String url) {
      final String u = url.toLowerCase();
      return u.contains("m3u8");
    }

    bool isMp4(String url) {
      final String u = url.toLowerCase();
      return u.contains("mp4");
    }

    bool isMkv(String url) {
      final String u = url.toLowerCase();
      return u.contains("mkv");
    }

    Future<void> finish([Map<String, dynamic>? value]) async {
      if (!completer.isCompleted) {
        value ??= hlsCandidate ?? mp4Candidate ?? mkvCandidate ?? preHlsCandidate ?? preMp4Candidate ?? preMkvCandidate;
        completer.complete(value);
      }
      try {
        await session?.dispose();
      } catch (_) {}
    }

    void consider(String url, Map<String, String> headers, {bool filterOnly = false}) {
      if (filter != null && !filter(url)) {
        return;
      }

      final bool hls = isHls(url);
      final bool mp4 = isMp4(url);
      final bool mkv = isMkv(url);

      if (!filterOnly && !(hls || mp4 || mkv)) {
        return;
      }

      if (!seen.add(url)) {
        return;
      }

      // If there are no ads, return immediately for any media type
      if (!hasAds) {
        if (hls) {
          hlsCandidate ??= <String, dynamic>{"url": url, "headers": headers};
          unawaited(finish(hlsCandidate));
          return;
        } else if (mp4) {
          mp4Candidate ??= <String, dynamic>{"url": url, "headers": headers};
          unawaited(finish(mp4Candidate));
          return;
        } else if (mkv) {
          mkvCandidate ??= <String, dynamic>{"url": url, "headers": headers};
          unawaited(finish(mkvCandidate));
          return;
        }
      }

      // When there are ads, wait for skip readiness before finishing
      if (!readyToCapture) {
        if (hls) {
          preHlsCandidate ??= <String, dynamic>{"url": url, "headers": headers};
        } else if (mp4) {
          preMp4Candidate ??= <String, dynamic>{"url": url, "headers": headers};
        } else if (mkv) {
          preMkvCandidate ??= <String, dynamic>{"url": url, "headers": headers};
        }
        return;
      }

      // Ready to capture: finish immediately with the first media seen after skip
      if (hls) {
        hlsCandidate ??= <String, dynamic>{"url": url, "headers": headers};
        unawaited(finish(hlsCandidate));
        return;
      } else if (mp4) {
        mp4Candidate ??= <String, dynamic>{"url": url, "headers": headers};
        unawaited(finish(mp4Candidate));
        return;
      } else if (mkv) {
        mkvCandidate ??= <String, dynamic>{"url": url, "headers": headers};
        unawaited(finish(mkvCandidate));
        return;
      }
    }

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
    let sawSkip = false;
    for (const el of nodes) {
      const txt = (el.innerText || el.textContent || '').trim();
      if (!txt || !/skip/i.test(txt)) continue;
      sawSkip = true;
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
    if (!sawSkip) {
      // No skip element currently on page
      // Allow capture immediately
      notifyReady();
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

    session = await PageNetworkRequestsService.startCapture(
      pageUrl: pageUrl,
      onRequest: (String url, Map<String, String> headers) => consider(url, headers, filterOnly: includePatterns.isEmpty),
      includePatterns: includePatterns,
      extraHandlers: <String, Future<dynamic> Function(List<dynamic>)>{
        "skipReady": (List<dynamic> args) async {
          readyToCapture = true;
          return null;
        },
      },
      extraOnLoadStopScripts: <String>[jsSkipAndReady],
    );

    // Timeout: allow time for skip + stream to appear, then pick best
    unawaited(Future<void>.delayed(const Duration(seconds: 20), () => finish()));

    return completer.future;
  }
}
