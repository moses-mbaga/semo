**Video Quality Service**

- **Location:** `lib/services/video_quality_service.dart`
- **Purpose:** Probe direct file streams (MP4/MKV) with `media_kit` to infer a resolution label when providers don’t expose one.
- **Pattern:** Lightweight, stateless class instantiated where needed.

**API**

- `Future<String?> determineQuality(MediaStream stream)`
  - Opens the supplied `MediaStream` in a temporary `Player` with playback disabled.
  - Polls the player up to 20 times (every 100ms) for `state.width` / `state.height`.
  - If dimensions are detected, maps them to the closest standard resolution via `getClosestResolutionFromDimensions` (e.g., `2160p`, `1080p`).
  - Stops and disposes the player before returning the inferred quality string. Returns `null` if the resolution can’t be determined.

**Usage**

```dart
final qualityService = const VideoQualityService();
final label = await qualityService.determineQuality(stream);
```

The `StreamsExtractorService` automatically uses this helper when processing file-based `MediaStream`s, so most callers do not interact with it directly.

**Notes**

- Only needed for non-adaptive streams (MP4/MKV) where quality metadata is missing.
- The helper incurs a brief delay while probing; avoid calling it on the UI thread for large batches.
- Requires `media_kit` platform integrations to be initialised (handled elsewhere in the app startup).
