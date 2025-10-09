**ZIP to VTT Service**

- **Location:** `lib/services/zip_to_vtt_service.dart`
- **Purpose:** Download subtitle ZIP archives and return WebVTT text for playback.
- **Pattern:** Singleton (`ZipToVttService()` returns one shared instance).

**API**

- `Future<String?> extract(String zipUrl)`
  - Downloads the ZIP archive using `dio` (10s connect/receive timeouts).
  - Validates the archive and searches for the first `.vtt` or `.srt` entry (prefers `.vtt`).
  - Decodes text as UTF-8, falling back to Latin-1 when needed.
  - If the entry is `.srt`, converts it to WebVTT via `SubtitlesService().srtToVtt`.
  - Logs and returns `null` on failure.

**Internal Helpers**

- `_getZipBytes` — Fetches bytes from the provided URL.
- `_findFirstByExtension` — Locates archive entries by extension.
- `_decodeText` / `_readFileBytes` — Handle decoding and decompression.

**Usage**

```dart
final vttText = await ZipToVttService().extract(subtitles.url);
if (vttText != null) {
  // supply to the video player
}
```

**Notes**

- Designed to work with `StreamSubtitles` entries returned by `SubtitlesService`.
- Errors are logged with `logger`; callers receive `null` for both network and parsing failures.
- Ensure the app has network permission; this helper performs direct HTTP requests.
