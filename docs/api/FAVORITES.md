**Favorites Service**

- **Location:** `lib/services/favorites_service.dart`
- **Backend:** Cloud Firestore per‑user document.
- **Pattern:** Singleton (`FavoritesService()` returns one shared instance).
- **Auth required:** All reads/writes require a signed‑in Firebase user.

**Data Model**

- **Collection:** `favorites`
- **Document ID:** current user UID (`FirebaseAuth.instance.currentUser!.uid`)
- **Schema:**
  - `movies`: `List<int>` — TMDB movie IDs
  - `tv_shows`: `List<int>` — TMDB TV show IDs
- When the document does not exist, the service initializes it with empty arrays for both fields.
- Updates use `SetOptions(merge: true)` to avoid overwriting sibling fields.

**API**

- `Future<Map<String, dynamic>> getFavorites()`
  - Fetches the full favorites document. Creates it with defaults if missing.

- `Future<List<int>> getMovies({Map<String, dynamic>? favorites})`
  - Returns the `movies` list. Optionally pass a previously fetched `favorites` map to avoid an extra read.

- `Future<List<int>> getTvShows({Map<String, dynamic>? favorites})`
  - Returns the `tv_shows` list. Optionally pass a previously fetched `favorites` map to avoid an extra read.

- `Future<void> addMovie(int movieId, {Map<String, dynamic>? allFavorites})`
  - Appends `movieId` if not present; writes merged document.

- `Future<void> addTvShow(int tvShowId, {Map<String, dynamic>? allFavorites})`
  - Appends `tvShowId` if not present; writes merged document.

- `Future<void> removeMovie(int movieId, {Map<String, dynamic>? allFavorites})`
  - Removes `movieId` if present; writes merged document.

- `Future<void> removeTvShow(int tvShowId, {Map<String, dynamic>? allFavorites})`
  - Removes `tvShowId` if present; writes merged document.

- `Future<void> clear()`
  - Deletes the user’s favorites document. A subsequent `getFavorites()` will recreate it with empty lists.

**Prerequisites**

- **Firebase:** Project configured and initialized; Firestore enabled.
- **Auth:** A user is signed in (see `docs/api/AUTH.md`). If not authenticated, methods log an error and return empty results without throwing.
- **Rules:** Firestore security rules should restrict access to `favorites/{uid}` to the owning user.

**Common Usage**

- **Load and display favorites (IDs → models):**
  - The app uses `FavoritesHandler` to fetch IDs, then resolves them to `Movie`/`TvShow` models.
  - See: `lib/bloc/handlers/favorites_handler.dart` (`onLoadFavorites`).

- **Optimistic UI add/remove:**
  - UI updates local state immediately, then calls `addMovie/addTvShow` or `removeMovie/removeTvShow` in the background.
  - See: `onAddFavorite` / `onRemoveFavorite` in the same handler.

- **Check if item is favorite:**
  - `final favs = await FavoritesService().getFavorites();`
  - `final movieIds = await FavoritesService().getMovies(favorites: favs);`
  - `final isFav = movieIds.contains(movieId);`

- **Clear all favorites (e.g., account cleanup):**
  - `await FavoritesService().clear();`

**Behavior & Error Handling**

- Methods catch and log errors via `logger`; they return empty collections or no‑ops on failure.
- Duplicate adds and missing‑item removes are ignored gracefully.
- Passing `allFavorites`/`favorites` avoids extra Firestore reads in tight UI loops.

**Examples**

- **Add favorite movie:**
  - `await FavoritesService().addMovie(movie.id);`

- **Remove favorite TV show:**
  - `await FavoritesService().removeTvShow(tvShow.id);`

- **Load both lists at once:**
  - `final favs = await FavoritesService().getFavorites();`
  - `final movies = await FavoritesService().getMovies(favorites: favs);`
  - `final tv = await FavoritesService().getTvShows(favorites: favs);`

**Notes**

- The service returns a dummy reference if called while unauthenticated; prefer checking auth first to avoid creating stray docs.
- IDs are TMDB integer IDs consistent with the rest of the app’s models.

