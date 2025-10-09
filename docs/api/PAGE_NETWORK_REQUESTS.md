**Page Network Requests Service**

- **Location:** `lib/services/page_network_requests_service.dart`
- **Purpose:** Spin up a headless `InAppWebView` instance, inject sniffing JavaScript, and report matching network requests (URL + headers) back to Dart.
- **Pattern:** Static utility with a session wrapper. Caller manages session lifecycle.

**Core Types**

- `PageNetworkRequestsService`
  - Exposes `startCapture` to launch a headless webview and capture network traffic.
- `PageNetworkRequestsSession`
  - Holds the running `HeadlessInAppWebView` instance and provides `dispose()` for cleanup.
- `PageRequestCallback`
  - Typedef: `void Function(String url, Map<String, String> headers)` invoked for each captured request matching the filter.

**API**

- `static Future<PageNetworkRequestsSession> startCapture({ required String pageUrl, required PageRequestCallback onRequest, List<String> includePatterns = const <String>[], Map<String, Future<dynamic> Function(List<dynamic>)>? extraHandlers, List<String>? extraOnLoadStopScripts, InAppWebViewSettings? settings, })`
  - Launches a headless webview pointed at `pageUrl`.
  - Injects a JavaScript sniffer that patches `fetch` and `XMLHttpRequest`, calling back to Dart when a URL contains any of the supplied `includePatterns`.
  - Also hooks into `onLoadResource` and `shouldInterceptRequest` for additional coverage.
  - `extraHandlers`: optional map of additional JavaScript handlers to register.
  - `extraOnLoadStopScripts`: extra scripts executed after the page finishes loading.
  - `settings`: override default `InAppWebViewSettings` if needed (defaults enable JS, request interception, and a desktop UA).
  - Returns a `PageNetworkRequestsSession`; call `dispose()` when finished to tear down the webview.

**Usage Pattern**

```dart
final session = await PageNetworkRequestsService.startCapture(
  pageUrl: targetUrl,
  includePatterns: const [".m3u8", ".mp4"],
  onRequest: (url, headers) {
    // Inspect or store the request
  },
);

// ... once done
await session.dispose();
```

**Notes**

- The injected JavaScript lowercases URLs when matching `includePatterns`; provide patterns in lowercase for clarity.
- Headers captured from `fetch` are best-effort; some providers restrict access via CORS or obfuscation.
- Always call `dispose()` to avoid leaking headless webviews.
- Commonly used by extractors that need to inspect dynamic page loads before resolving final stream URLs.
