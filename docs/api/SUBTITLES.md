**Subtitle Service**

- **Location:** `lib/services/subtitle_service.dart`
- **Backend:** OpenSubtitles search + ZIP download; extracts `.srt` files.
- **Storage:** App temporary directory via `path_provider`.
- **Pattern:** Singleton (`SubtitleService()` returns one shared instance).
- **Logging:** `PrettyDioLogger` added for JSON requests; removed for binary ZIP downloads.

**API**

- `Future<List<File>> getSubtitles(int tmdbId, {int? seasonNumber, int? episodeNumber, String? locale = "EN"})`
  - Queries OpenSubtitles for subtitles by ID (and optional season/episode) and downloads/expands ZIPs.
  - Returns a list of `.srt` files saved in a cache directory. On error, returns `[]`.

- `Future<void> deleteAllSubtitles()`
  - Deletes the entire temporary subtitles directory tree used by the service.

**Caching & File Layout**

- Movies: `${tmp}/{locale}/` (e.g., `…/EN/`).
- Episodes: `${tmp}/{tmdbId}/{locale}/{seasonNumber}/{episodeNumber}/`.
- Before network calls, the service scans the destination directory; if `.srt` files exist, it returns them immediately.

**Request Details**

- Search request: `GET Urls.getOpenSubtitlesMovieSearch` or `Urls.getOpenSubtitlesEpisodeSearch` depending on parameters.
- Download: Uses each result `ZipDownloadLink` directly and keeps only `.srt` entries.

**Prerequisites**

- Network connectivity to OpenSubtitles endpoints defined in `Urls`.

**Common Usage**

- Load movie subtitles in BLoC handler:
  - `final files = await SubtitleService().getSubtitles(movieId, locale: "EN");`
  - Example: `lib/bloc/handlers/subtitles_handler.dart` (`onLoadMovieSubtitles`).

- Load episode subtitles in BLoC handler:
  - `final files = await SubtitleService().getSubtitles(tvId, seasonNumber: s, episodeNumber: e, locale: "EN");`
  - Example: `lib/bloc/handlers/subtitles_handler.dart` (`onLoadEpisodeSubtitles`).

- Clear cached subtitles (Settings):
  - `await SubtitleService().deleteAllSubtitles();`
  - Example: `lib/screens/settings_screen.dart`.

**Behavior & Error Handling**

- Returns an empty list on errors; logs warnings/errors via `logger`.
- Skips non-`.srt` archive entries.
- Temporarily removes the HTTP logger before binary downloads to avoid logging ZIP payloads.

**Notes**

- Locale is a simple string passed to OpenSubtitles (e.g., `EN`, `ES`). Ensure it matches provider expectations.
- Consider calling from a background isolate if expanding many ZIPs, though current usage is lightweight.
- Web builds should avoid referencing this service due to `dart:io` usage.

**Quick Reference**

- Methods: `getSubtitles(...)`, `deleteAllSubtitles()`
- Uses: `Urls.getOpenSubtitlesMovieSearch`, `Urls.getOpenSubtitlesEpisodeSearch`
- Cache: temp dir per locale or per tmdbId/season/episode
