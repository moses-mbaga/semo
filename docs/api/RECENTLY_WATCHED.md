**Recently Watched Service**

- **Location:** `lib/services/recently_watched_service.dart`
- **Backend:** Cloud Firestore per‑user document.
- **Pattern:** Singleton (`RecentlyWatchedService()` returns one shared instance).
- **Auth required:** All reads/writes require a signed‑in Firebase user.

**Data Model**

- **Collection:** `recently_watched`
- **Document ID:** current user UID (`FirebaseAuth.instance.currentUser!.uid`)
- **Schema:**
  - `movies`: `Map<String, { progress: int, timestamp: int }>`
    - Key: TMDB movie ID as string
    - `progress`: playback position in seconds
    - `timestamp`: last update time (`DateTime.millisecondsSinceEpoch`)
  - `tv_shows`: `Map<String, { visibleInMenu: bool, <seasonId>: Map<String, { progress: int, timestamp: int }> }>`
    - Top‑level key: TMDB TV show ID as string
    - `visibleInMenu`: whether the show should appear in the UI “Recently Watched” list
    - Season key: TMDB season ID as string
    - Episode map key: TMDB episode ID as string, value contains `progress` and `timestamp` (seconds + ms epoch)
- When the document does not exist, the service initializes it with empty maps for both fields.

**API**

- `Future<Map<String, dynamic>> getRecentlyWatched()`
  - Fetches the full document; creates with defaults if missing.

- `int getMovieProgress(int movieId, Map<String, dynamic>? recentlyWatched)`
  - Reads a movie’s progress (seconds) from a provided cache map; returns `0` if missing.

- `Future<Map<String, Map<String, dynamic>>?> getEpisodes(int tvShowId, int seasonId, {Map<String, dynamic>? recentlyWatched})`
  - Returns episode map for a season or `null` if none; removes `visibleInMenu` from the show payload internally.

- `Map<String, Map<String, dynamic>> getEpisodesFromCache(int tvShowId, int seasonId, Map<String, dynamic>? recentlyWatched)`
  - Cached variant (no Firestore read) that returns an empty map when unavailable.

- `int getEpisodeProgress(int tvShowId, int seasonId, int episodeId, Map<String, dynamic>? recentlyWatched)`
  - Reads a single episode’s progress (seconds) from the cache; returns `0` if missing.

- `Future<Map<String, dynamic>> updateMovieProgress(int movieId, int progress, {Map<String, dynamic>? recentlyWatched})`
  - Upserts the movie entry with `progress` and current `timestamp`. Returns updated document map.

- `Future<Map<String, dynamic>> updateEpisodeProgress(int tvShowId, int seasonId, int episodeId, int progress, {Map<String, dynamic>? recentlyWatched})`
  - Upserts episode data; ensures enclosing show/season maps exist; sets `visibleInMenu: true`. Returns updated document map.

- `Future<Map<String, dynamic>> removeEpisodeProgress(int tvShowId, int seasonId, int episodeId, {Map<String, dynamic>? recentlyWatched})`
  - Removes an episode entry and returns updated document map.

- `Future<List<int>> getMovieIds({Map<String, dynamic>? recentlyWatched})`
  - Returns movie IDs sorted by most‑recent `timestamp` descending.

- `Future<Map<String, dynamic>> removeMovie(int movieId, {Map<String, dynamic>? recentlyWatched})`
  - Removes a movie entry and returns updated document map.

- `Future<List<int>> getTvShowIds({Map<String, dynamic>? recentlyWatched})`
  - Returns TV show IDs with `visibleInMenu == true`, sorted by the latest episode `timestamp` descending.

- `Future<Map<String, dynamic>> hideTvShow(int tvShowId, {Map<String, dynamic>? recentlyWatched})`
  - Sets `visibleInMenu` to `false` for a show and returns updated document map.

- `Future<Map<String, dynamic>> removeTvShow(int tvShowId, {Map<String, dynamic>? recentlyWatched})`
  - Removes the entire show subtree and returns updated document map.

- `Future<void> clear()`
  - Deletes the user’s document.

**Prerequisites**

- **Firebase:** Project configured and initialized; Firestore enabled.
- **Auth:** A user is signed in (see `docs/api/AUTH.md`). If not authenticated, methods log and return safe fallbacks.
- **Rules:** Lock down `recently_watched/{uid}` to the owning user.

**Common Usage**

- **Resume playback position (Player):**
  - Movie: `RecentlyWatchedService().getMovieProgress(movieId, state.recentlyWatched)`
  - Episode: `RecentlyWatchedService().getEpisodeProgress(tvId, seasonId, epId, state.recentlyWatched)`
  - Example: `lib/screens/player_screen.dart`

- **Update progress during playback:**
  - Movie: `await RecentlyWatchedService().updateMovieProgress(movieId, progressSecs, recentlyWatched: cache)`
  - Episode: `await RecentlyWatchedService().updateEpisodeProgress(tvId, seasonId, epId, progressSecs, recentlyWatched: cache)`
  - Example: `lib/bloc/handlers/recently_watched_handler.dart` (`onUpdateMovieProgress`, `onUpdateEpisodeProgress`)

- **Build UI lists:**
  - Movies: `await RecentlyWatchedService().getMovieIds(recentlyWatched: doc)` then resolve to models.
  - TV Shows: `await RecentlyWatchedService().getTvShowIds(recentlyWatched: doc)` then resolve to models.

- **Hide or remove:**
  - Hide show from menu: `await RecentlyWatchedService().hideTvShow(tvId)`
  - Remove movie/show/episode: corresponding `remove*` methods.

**Behavior & Notes**

- Progress values are stored in seconds; timestamps are epoch milliseconds for sorting.
- For TV shows, the presence of any episode sets the show as visible; `hideTvShow` toggles visibility without deleting progress.
- Methods catch and log errors via `logger` and otherwise return empty collections, updated maps, or no‑ops.
- Passing a `recentlyWatched` cache avoids extra Firestore reads in tight update loops.

