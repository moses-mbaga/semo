**Streams Extractor Service**

- **Location:** `lib/services/streams_extractor_service/streams_extractor_service.dart`
- **Purpose:** Resolve one or more playable `MediaStream`s for a movie or TV episode (auto + quality/file variants) by delegating to one of the supported extractors.

**Concepts**

- `StreamsExtractorService`: Singleton façade that chooses an extractor and returns an ordered `List<MediaStream>` (adaptive streams first, then highest → lowest quality files).
- `StreamingServer`: UI-friendly descriptor of a source with a `name` and an associated extractor instance (or `null` for randomised selection).
- `BaseStreamExtractor`: Interface every extractor implements with `Future<List<MediaStream>> getStreams(StreamExtractorOptions options, { String? externalLink, Map<String, String>? externalLinkHeaders })` plus optional `needsExternalLink/getExternalLink` hooks.
- `StreamExtractorOptions`: Options passed to extractors (TMDB ID, title, optional season/episode, optional `imdbId`).
- `MediaStream`: Resulting playable source with `type`, `url`, optional `headers`, `quality`, `subtitles`, and `audios` metadata.
- `VideoQualityService`: Helper used to probe direct file streams and derive a displayable resolution label when one isn’t provided.

**Available Servers**

The `getStreamingServers()` method returns the list below (filtered for platform support):

1. `Random` (no extractor; enables randomised selection)
2. `AutoEmbed`
3. `HollyMovie` *(skipped on iOS)*
4. `KissKh`
5. `MoviesApi`
6. `MoviesJoy`
7. `MultiMovies`
8. `VidFast`
9. `VidLink`
10. `VidRock`

Each extractor advertises the media types it supports (`MediaType.movies` / `MediaType.tvShows`). Servers that cannot satisfy the requested media type are filtered out before selection.

**Public API**

- `List<StreamingServer> getStreamingServers()`
  - Use to populate server selection UI and to validate saved preferences.

- `Future<List<MediaStream>> getStreams(StreamExtractorOptions options)`
  - Inputs: options describing the movie or episode. Include `season` and `episode` for TV shows and pass `imdbId` when available (some providers require it).
  - Behaviour:
    - Reads the preferred server from `AppPreferencesService().getStreamingServer()`.
    - If a concrete server is selected, tries it up to three times before giving up.
    - If preference is `Random`, shuffles through up to three compatible extractors until a non-empty result is produced.
    - Extractors that require an intermediate page call `getExternalLink` first; the service passes returned URL + headers to `getStreams`.
    - Post-processes the returned list:
      - Prefers adaptive (`HLS`/`DASH`) streams.
      - Falls back to file streams and enriches missing `quality` labels via `VideoQualityService.determineQuality`.
      - Keeps subtitles and audio metadata attached to each `MediaStream`.
    - Returns an empty list when every extractor fails.
  - Errors: Logged with `logger`; method resolves to an empty list on unrecoverable errors.

**Models**

- `StreamExtractorOptions`
  - Movie: `{ tmdbId, title, releaseYear?, imdbId? }`
  - Episode: `{ tmdbId, season, episode, title, imdbId? }`
  - Assertion: `season` and `episode` must be both provided or both omitted.

- `MediaStream`
  - `type`: `StreamType` (`hls`, `dash`, `mp4`, `mkv`, ...).
  - `url`: Final, non-empty when successful.
  - `headers`: Optional HTTP headers for the player/client.
  - `quality`: Human readable (e.g., `Auto`, `1080p`).
  - `subtitles`: Optional list of `StreamSubtitles`.
  - `audios`: Optional alternative audio tracks.
  - `hasDefaultAudio`: Whether default audio is included.

- `StreamingServer`
  - `name`: Display name persisted in preferences.
  - `extractor`: `BaseStreamExtractor?`. The `Random` server has `extractor = null`.

**Preference & Selection**

- Read current preference: `AppPreferencesService().getStreamingServer()` returns the server name or `"Random"` by default.
- Update preference: `await AppPreferencesService().setStreamingServer(server);` where `server` is from `getStreamingServers()`.
- `AppPreferencesService.ensureActiveStreamingServerValidity()` resets stale saved names to `Random` during startup.

**Usage Examples**

- Movie stream
  - `final opts = StreamExtractorOptions(tmdbId: movie.id, title: movie.title, releaseYear: movie.releaseYear, imdbId: imdbId);`
  - `final streams = await StreamsExtractorService().getStreams(opts);`
  - `if (streams.isNotEmpty) { /* pass ordered list to the player */ }`

- Episode stream
  - `final opts = StreamExtractorOptions(tmdbId: show.id, season: ep.seasonNumber, episode: ep.episodeNumber, title: show.name, imdbId: imdbId);`
  - `final streams = await StreamsExtractorService().getStreams(opts);`

- Listing servers for a settings screen
  - `final servers = StreamsExtractorService().getStreamingServers();`
  - `await AppPreferencesService().setStreamingServer(servers[index]);`

**Extensibility**

- Add a new extractor by implementing `BaseStreamExtractor` and registering it in `_streamingServers`:
  - `StreamingServer(name: "YourProvider", extractor: YourProviderExtractor()),`
- Extractors can override `needsExternalLink`/`getExternalLink` to reuse `PageNetworkRequestsService` or other helpers before returning final streams.
- No UI changes are needed if your settings UI lists `getStreamingServers()` dynamically.

**Notes**

- Individual extractor implementations live under `lib/services/streams_extractor_service/extractors/` and encapsulate provider-specific logic.
- Random selection removes extractors that fail during a single attempt to avoid retry loops.
- `VideoQualityService` instantiates a temporary `media_kit` player to infer resolution for file streams; expect a short probe delay when only MP4/MKV links are available.
- Always validate `stream.url` before playback; extractors return `[]` if no stream can be found.
