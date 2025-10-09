**Subtitles Service**

- **Location:** `lib/services/subtitles_service.dart`
- **Backend:** OpenSubtitles search API returning zipped `.srt` downloads.
- **Pattern:** Singleton (`SubtitlesService()` returns one shared instance).
- **Logging:** `PrettyDioLogger` added for JSON requests in debug builds; removed for binary ZIP downloads.

**API**

- `Future<List<StreamSubtitles>> getSubtitles({ required String imdbId, int? seasonNumber, int? episodeNumber })`
  - Accepts the IMDb ID (with or without the `tt` prefix). Optional season/episode narrow the search to TV episodes.
  - Normalises and validates the IMDb ID, then queries the appropriate OpenSubtitles endpoint via `Urls`.
  - Filters results to `.srt` format and to an allowlist of languages (`EN`, `FI`, `ES`, `FR`, `DE`, `PT`, `IT`, `RU`, `AR`, `TR`, `HI`, `ZH`, `JA`, `KO`).
  - Sorts by the provider `Score` descending and returns each match as `StreamSubtitles` with `type = SubtitlesType.zip` and the original ZIP download URL.
  - Returns an empty list when nothing matches or an error occurs.

- `String srtToVtt(String srt)`
  - Converts `.srt` content into WebVTT by adjusting timestamps and stripping numeric counters.
  - Used by `ZipToVttService` to expose WebVTT text to the player.

**Workflow**

1. Determine the IMDb ID for the current media (use `TMDBService.getImdbId` when necessary).
2. Call `SubtitlesService().getSubtitles(...)` to obtain available subtitle downloads.
3. When a user selects one, pass the `StreamSubtitles.url` to `ZipToVttService().extract` to download and convert the ZIP into WebVTT text for playback.

**Prerequisites**

- Network connectivity to OpenSubtitles endpoints defined in `lib/utils/urls.dart`.
- A valid IMDb identifier for the media item.

**Common Usage**

- **Load movie subtitles in BLoC handler:**
  - `final subs = await SubtitlesService().getSubtitles(imdbId: imdbId);`
  - Example: `lib/bloc/handlers/subtitles_handler.dart` (`onLoadMovieSubtitles`).

- **Load episode subtitles in BLoC handler:**
  - `final subs = await SubtitlesService().getSubtitles(imdbId: imdbId, seasonNumber: s, episodeNumber: e);`
  - Example: `lib/bloc/handlers/subtitles_handler.dart` (`onLoadEpisodeSubtitles`).

- **Convert selected subtitle for playback:**
  - `final vtt = await ZipToVttService().extract(selectedSubtitles.url);`
  - Example consumption: `lib/components/semo_player.dart`.

**Behavior & Error Handling**

- Returns an empty list on errors; logs warnings/errors via `logger`.
- Automatically trims `tt` prefixes and ignores invalid/empty IDs.
- Filters non-`.srt` formats to avoid unsupported subtitle types.

**Notes**

- Locale filtering keeps the UI manageable; adjust the allowlist if broader language support is required.
- Web builds should avoid referencing this service due to reliance on `dart:io` in downstream ZIP handling.
- Caching is handled by callers; the service performs no local storage.

**Quick Reference**

- Methods: `getSubtitles(...)`, `srtToVtt(...)`
- Models: `StreamSubtitles` (`lib/models/stream_subtitles.dart`), `SubtitlesType` enum.
- Helpers: `ZipToVttService` for download + conversion.
