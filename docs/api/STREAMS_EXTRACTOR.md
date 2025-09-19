**Streams Extractor**

- Location: `lib/services/streams_extractor_service/streams_extractor_service.dart`
- Purpose: Resolve one or more playable `MediaStream`s for a movie or TV episode (auto + quality variants) by delegating to one of the supported extractors.

**Concepts**

- `StreamsExtractorService`: Static façade that chooses an extractor and returns an ordered `List<MediaStream>` (auto first, then descending qualities).
- `StreamingServer`: UI‑friendly descriptor of a source with a `name` and an associated extractor instance (or `null` for randomized selection).
- `BaseStreamExtractor`: Interface every extractor implements with `Future<List<MediaStream>> getStreams(StreamExtractorOptions options, { String? externalLink, Map<String, String>? externalLinkHeaders })`.
- `StreamExtractorOptions`: Options passed to extractors (TMDB ID, title, and optionally season/episode or `releaseYear`). Includes optional `imdbId` when available.
- `MediaStream`: The result with a `url` and optional HTTP `headers`.

**Public API**

- `static List<StreamingServer> get streamingServers`
  - The list of available servers. First entry is always `Random` (no extractor bound) to enable random selection.

- `static Future<List<MediaStream>> getStreams(StreamExtractorOptions options)`
  - Inputs: An options object; include `season` and `episode` for TV episodes.
  - Behavior:
    - Uses provided `options` directly (no internal construction).
    - Reads preferred server from `AppPreferencesService().getStreamingServer()`.
    - If preference is `Random`, picks servers at random until a valid stream is found (removing failures from the candidate set for that attempt).
    - If a specific server is selected, delegates only to that extractor.
    - Returns a non-empty list on success. The first item is always the "Auto" HLS variant, followed by quality-labelled streams sorted from highest to lowest resolution. If all HLS candidates fail, downloadable MP4/MKV streams are returned instead (also sorted by inferred quality). Empty list means extraction failed.
  - Errors: Logged with `logger`; method resolves to an empty list on unrecoverable errors.

**Models**

- `StreamExtractorOptions`
  - Movie: `{ tmdbId, title, releaseYear?, imdbId? }`
  - Episode: `{ tmdbId, season, episode, title, imdbId? }`
  - Assertion: `season` and `episode` must be both provided or both omitted.

- `MediaStream`
  - `url`: Final, non‑empty when successful.
  - `headers`: Optional HTTP headers for the player/client.

- `StreamingServer`
  - `name`: Display name.
  - `extractor`: `BaseStreamExtractor?` used when selected. The `Random` server has `extractor = null`.

**Preference & Selection**

- Read current preference: `AppPreferencesService().getStreamingServer()` returns the server name or `"Random"` by default.
- Update preference: `await AppPreferencesService().setStreamingServer(server)` where `server` is a `StreamingServer` from `StreamsExtractorService.streamingServers`.
- Present options: Use `StreamsExtractorService.streamingServers` to populate a selection UI by `name`.

**Usage Examples**

- Movie stream
  - `final opts = StreamExtractorOptions(tmdbId: movie.id, title: movie.title, releaseYear: movie.releaseDate.split('-').first, imdbId: imdbId);`
  - `final streams = await StreamsExtractorService.getStreams(opts);`
  - `if (streams.isNotEmpty) { /* pass ordered list to the player */ }`

- Episode stream
  - `final opts = StreamExtractorOptions(tmdbId: show.id, season: ep.season, episode: ep.number, title: show.name, imdbId: imdbId);`
  - `final streams = await StreamsExtractorService.getStreams(opts);`
  - `if (streams.isNotEmpty) { /* pass ordered list to the player */ }`

- Listing servers for a settings screen
  - `final servers = StreamsExtractorService.streamingServers;`
  - `await AppPreferencesService().setStreamingServer(servers[index]);`

**Extensibility**

- Add a new extractor by implementing `BaseStreamExtractor` and registering it in the `_streamingServers` list inside `streams_extractor_service.dart`:
  - `StreamingServer(name: "YourProvider", extractor: YourProviderExtractor()),`
- No UI changes needed if your settings UI lists `streamingServers` dynamically.

**Notes**

- Individual extractors encapsulate provider‑specific logic and are not documented here.
- When preference is `Random`, the service temporarily removes servers that fail during a single resolution attempt to avoid retry loops.
- Always validate `stream.url` before playback; extractors return `null` if a stream cannot be found.
