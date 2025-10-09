**YouTube Extractor Service**

- **Location:** `lib/services/youtube_extractor_service/youtube_extractor_service.dart`
- **Purpose:** Resolve playable `MediaStream`s for YouTube videos (trailers, extras) without relying on a single backend.
- **Pattern:** Singleton (`YoutubeExtractorService()` returns one shared instance).

**Extractors**

The service cycles through multiple extractor implementations until one succeeds:

1. `PokeExtractor`
2. `PipedExtractor`
3. `InvidiousExtractor`

Each extractor implements `BaseYoutubeExtractor` and returns a list of `MediaStream`s.

**API**

- `Future<List<MediaStream>> getStreams(String youtubeUrl)`
  - Trims and validates the URL; returns `[]` if empty.
  - Iterates through the extractor list, collecting streams from each until a non-empty result is produced.
  - Logs errors per extractor but continues trying the next provider.
  - Returns the first successful list of streams or `[]` if all extractors fail.

**Usage**

```dart
final streams = await YoutubeExtractorService().getStreams(trailerUrl);
if (streams.isNotEmpty) {
  // feed into the media player
}
```

Typically used by the trailer player flow (`TMDBService.getTrailerUrl` → `YoutubeExtractorService.getStreams`).

**Notes**

- Extractors may return adaptive streams (HLS/DASH) or direct file URLs depending on backend capabilities.
- Errors are logged with `logger` for observability; callers receive an empty list on failure.
- Update the `_extractors` list to add/remove providers as availability changes.
