**Stream Extractor**

- Location: `lib/services/stream_extractor_service/extractor.dart`
- Purpose: Resolve a playable stream URL (`MediaStream`) for a movie or TV episode by delegating to one of the supported extractors.

**Concepts**

- `StreamExtractorService`: Static façade that chooses an extractor and returns a `MediaStream?`.
- `StreamingServer`: UI‑friendly descriptor of a source with a `name` and an associated extractor instance (or `null` for randomized selection).
- `BaseStreamExtractor`: Interface every extractor implements with `Future<MediaStream?> getStream(StreamExtractorOptions options)`.
- `StreamExtractorOptions`: Options passed to extractors (TMDB ID, title, and optionally season/episode or movie release year).
- `MediaStream`: The result with a `url` and optional HTTP `headers`.

**Public API**

- `static List<StreamingServer> get streamingServers`
  - The list of available servers. First entry is always `Random` (no extractor bound) to enable random selection.

- `static Future<MediaStream?> getStream({Movie? movie, TvShow? tvShow, Episode? episode})`
  - Inputs: Provide either `movie`, or both `tvShow` and `episode`.
  - Behavior:
    - Builds `StreamExtractorOptions` from the provided inputs.
    - Reads preferred server from `AppPreferencesService().getStreamingServer()`.
    - If preference is `Random`, picks servers at random until a valid stream is found (removing failures from the candidate set for that attempt).
    - If a specific server is selected, delegates only to that extractor.
    - Returns `MediaStream?` where `url` may be empty on failure; `null` if no extractor yields a stream.
  - Errors: Logged with `logger`; method resolves to `null` on unrecoverable errors.

**Models**

- `StreamExtractorOptions`
  - Movie: `{ tmdbId, title, movieReleaseYear }`
  - Episode: `{ tmdbId: episode.id, season, episode, title: tvShow.name }`
  - Assertion: `season` and `episode` must be both provided or both omitted.

- `MediaStream`
  - `url`: Final, non‑empty when successful.
  - `headers`: Optional HTTP headers for the player/client.

- `StreamingServer`
  - `name`: Display name.
  - `extractor`: `BaseStreamExtractor?` used when selected. The `Random` server has `extractor = null`.

**Preference & Selection**

- Read current preference: `AppPreferencesService().getStreamingServer()` returns the server name or `"Random"` by default.
- Update preference: `await AppPreferencesService().setStreamingServer(server)` where `server` is a `StreamingServer` from `StreamExtractorService.streamingServers`.
- Present options: Use `StreamExtractorService.streamingServers` to populate a selection UI by `name`.

**Usage Examples**

- Movie stream
  - `final stream = await StreamExtractorService.getStream(movie: movie);`
  - `if (stream != null && stream.url.isNotEmpty) { /* play via player */ }`

- Episode stream
  - `final stream = await StreamExtractorService.getStream(tvShow: show, episode: ep);`
  - `if (stream != null && stream.url.isNotEmpty) { /* play via player */ }`

- Listing servers for a settings screen
  - `final servers = StreamExtractorService.streamingServers;`
  - `await AppPreferencesService().setStreamingServer(servers[index]);`

**Extensibility**

- Add a new extractor by implementing `BaseStreamExtractor` and registering it in the `_streamingServers` list inside `extractor.dart`:
  - `StreamingServer(name: "YourProvider", extractor: YourProviderExtractor()),`
- No UI changes needed if your settings UI lists `streamingServers` dynamically.

**Notes**

- Individual extractors encapsulate provider‑specific logic and are not documented here.
- When preference is `Random`, the service temporarily removes servers that fail during a single resolution attempt to avoid retry loops.
- Always validate `stream.url` before playback; extractors return `null` if a stream cannot be found.

