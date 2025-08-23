**Recent Searches Service**

- **Location:** `lib/services/recent_searches_service.dart`
- **Backend:** Cloud Firestore per‑user document.
- **Pattern:** Singleton (`RecentSearchesService()` returns one shared instance).
- **Auth required:** All reads/writes require a signed‑in Firebase user.

**Data Model**

- **Collection:** `recent_searches`
- **Document ID:** current user UID (`FirebaseAuth.instance.currentUser!.uid`)
- **Schema:**
  - `movies`: `List<String>` — recent search queries for Movies
  - `tv_shows`: `List<String>` — recent search queries for TV Shows
- When the document does not exist, the service initializes it with empty arrays for both fields.
- Updates use `SetOptions(merge: true)` to update only the targeted field.

**API**

- `Future<List<String>> getRecentSearches(MediaType mediaType)`
  - Reads the user document and returns the list for the given `mediaType`.
  - The method returns the list in reversed order relative to what is stored to prioritize most‑recent queries in UI.

- `Future<void> add(MediaType mediaType, String query)`
  - Inserts `query` at the beginning of the list, removes any duplicate, and trims the list to a maximum of 20 items.
  - Writes back using merge.

- `Future<void> remove(MediaType mediaType, String query)`
  - Removes `query` if present and writes the updated list using merge.

- `Future<void> clear()`
  - Deletes the user’s recent searches document. A subsequent `getRecentSearches` will recreate empty lists.

**Prerequisites**

- **Firebase:** Project configured and initialized; Firestore enabled.
- **Auth:** A user is signed in (see `docs/api/AUTH.md`). If not authenticated, methods log an error and return safe fallbacks.
- **Rules:** Firestore security rules should restrict access to `recent_searches/{uid}` to the owning user.

**Common Usage**

- **Load recent searches for suggestions:**
  - `final movies = await RecentSearchesService().getRecentSearches(MediaType.movies);`
  - `final tv = await RecentSearchesService().getRecentSearches(MediaType.tvShows);`
  - Used by: `lib/bloc/handlers/recent_searches_handler.dart` (`onLoadRecentSearches`).

- **Record a query after search submit:**
  - `await RecentSearchesService().add(MediaType.movies, query);`
  - Triggered in handler: `onAddRecentSearch`.

- **Remove a single entry:**
  - `await RecentSearchesService().remove(MediaType.tvShows, query);`

- **Clear all (e.g., account cleanup):**
  - `await RecentSearchesService().clear();`

**Behavior & Limits**

- Lists are capped at 20 entries; newest insertions take precedence and duplicates are de‑duplicated.
- Methods catch and log errors via `logger` and otherwise no‑op or return empty lists.

**Ordering Note**

- `getRecentSearches` returns the list reversed from storage to present most‑recent first. If you read the raw stored array elsewhere, account for this convention.

