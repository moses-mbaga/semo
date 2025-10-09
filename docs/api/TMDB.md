**TMDB Service**

- **Location:** `lib/services/tmdb_service.dart`
- **Backend:** The Movie Database (TMDB) v3 REST API
- **HTTP:** `dio` client with `PrettyDioLogger` enabled in debug builds
- **Auth:** Bearer token from `SecretsService.tmdbAccessToken` (TMDB v4 access token)
- **Pattern:** Singleton (`TMDBService()` returns one shared instance)
- **Timeouts:** 10s connect and receive timeouts

**API**

Movies

- `Future<SearchResults?> getNowPlayingMovies()`
  - Fetches now playing movies (fixed `page = 1`). Returns `SearchResults` or `null` on error.

- `Future<SearchResults?> getTrendingMovies(int page)`
  - Weekly trending movies. Paginates with `page` (1-based). May return `null` on error.

- `Future<SearchResults?> getPopularMovies(int page)`
  - Popular movies, paginated. May return `null` on error.

- `Future<SearchResults?> getTopRatedMovies(int page)`
  - Top rated movies, paginated. May return `null` on error.

- `Future<SearchResults?> discoverMovies(int page, {Map<String, String>? parameters})`
  - TMDB discover API for movies. Pass TMDB query params (e.g., `{"with_genres": "28"}`). Returns `SearchResults?`.

- `Future<SearchResults?> searchMovies(String query, int page)`
  - Text search for movies with `include_adult=false`. Returns `SearchResults?`.

- `Future<List<Genre>> getMovieGenres()`
  - Lists all movie genres. Returns `[]` on error.

- `Future<Movie?> getMovie(int id)`
  - Movie details by TMDB ID. Returns `Movie` or `null` on error.

TV Shows

- `Future<SearchResults?> getOnTheAirTvShows()`
  - Currently airing TV shows (fixed `page = 1`). Returns `SearchResults?`.

- `Future<SearchResults?> getTrendingTvShows(int page)`
  - Weekly trending TV shows. Paginates with `page`. Returns `SearchResults?`.

- `Future<SearchResults?> getPopularTvShows(int page)`
  - Popular TV shows, paginated. Returns `SearchResults?`.

- `Future<SearchResults?> getTopRatedTvShows(int page)`
  - Top rated TV shows, paginated. Returns `SearchResults?`.

- `Future<SearchResults?> discoverTvShows(int page, {Map<String, String>? parameters})`
  - TMDB discover API for TV. Pass TMDB query params (e.g., `{"with_genres": "18"}`). Returns `SearchResults?`.

- `Future<SearchResults?> searchTvShows(String query, int page)`
  - Text search for TV shows with `include_adult=false`. Returns `SearchResults?`.

- `Future<List<Genre>> getTvShowGenres()`
  - Lists all TV genres. Returns `[]` on error.

- `Future<TvShow?> getTvShow(int id)`
  - TV show details by TMDB ID. Returns `TvShow` or `null` on error.

- `Future<List<Season>> getTvShowSeasons(int id)`
  - Extracts seasons from show details, filters out specials (`season.number <= 0`) and seasons with `airDate == null`. Returns `[]` on error.

- `Future<List<Episode>> getEpisodes(int showId, int seasonNumber)`
  - Episodes for a given show/season, filtered to those with non-null `airDate`. Returns `[]` on error.

Common

- `Future<String?> getImdbId(MediaType mediaType, int id)`
  - Fetches external IDs for a movie or TV show and extracts the IMDb ID (`tt...`). Returns `null` if unavailable.

- `Future<SearchResults?> searchFromUrl(MediaType mediaType, String url, int page, Map<String, String>? parameters)`
  - Convenience wrapper over the internal search to hit arbitrary TMDB list endpoints with pagination and optional params.

- `Future<String?> getGenreBackdrop(MediaType mediaType, Genre genre)`
  - Returns a backdrop path for the provided `genre`. Uses `genre.backdropPath` when available; otherwise performs a one-page discover request for the genre and returns a random item's backdrop. Returns `null` on error or when none found.

- `Future<SearchResults?> getRecommendations(MediaType mediaType, int id, int page)`
  - Recommendations for a movie/TV show by ID, paginated. Returns `SearchResults?`.

- `Future<SearchResults?> getSimilar(MediaType mediaType, int id, int page)`
  - Similar movies/TV shows by ID, paginated. Returns `SearchResults?`.

- `Future<String?> getTrailerUrl(MediaType mediaType, int mediaId)`
  - Fetches videos and selects the highest-resolution, official YouTube trailer. Returns a full YouTube watch URL string or `null` if none.

- `Future<List<Person>> getCast(MediaType mediaType, int mediaId)`
  - Cast credits for a title. Filters results to `department == "Acting"`. Returns `[]` on error.

- `Future<List<Movie>> getPersonMovies(int personId)` / `Future<List<TvShow>> getPersonTvShows(int personId)`
  - Filmography for a person. Returns lists of `Movie`/`TvShow`. Returns `[]` on error.

**Prerequisites**

- **Secrets:** Set `TMDB_ACCESS_TOKEN` in `.env` and generate with `envied`. See `docs/api/SECRETS.md`.
- **Network:** App must have connectivity to TMDB endpoints in `lib/utils/urls.dart`.
- **Models:** Uses `Movie`, `TvShow`, `Season`, `Episode`, `Genre`, `Person`, and `SearchResults` from `lib/models/`.

**Behavior & Error Handling**

- Returns `null` for object/collection wrappers (`SearchResults`, `Movie`, `TvShow`) on failures; list-returning methods yield `[]`.
- Logs errors with `logger` and continues without throwing to callers in most paths.
- Adds `PrettyDioLogger` interceptor only once (in debug builds). Authorization header is attached at client creation.
- All requests use 10s connect/receive timeouts.

**Common Usage**

- Create/obtain singleton:
  - `final tmdb = TMDBService();`

- Search movies (page 1):
  - `final results = await tmdb.searchMovies("inception", 1);`
  - `final movies = results?.movies ?? [];`

- Get details + recommendations:
  - `final movie = await tmdb.getMovie(27205);`
  - `final recs = await tmdb.getRecommendations(MediaType.movies, 27205, 1);`

- TV seasons and episodes:
  - `final seasons = await tmdb.getTvShowSeasons(1399);`
  - `final eps = await tmdb.getEpisodes(1399, 1);`

- Trailer URL (YouTube):
  - `final trailer = await tmdb.getTrailerUrl(MediaType.movies, 27205);`

- Resolve IMDb ID for subtitles/streams:
  - `final imdbId = await tmdb.getImdbId(MediaType.movies, 27205);`

**Notes**

- `SearchResults` encapsulates paging data and either `movies` or `tvShows` based on `MediaType`.
- `getGenreBackdrop` performs a discover request and picks a random backdrop; consider caching on the caller side if used frequently.
- `getCast` uses `aggregate_credits` for TV shows and filters for the Acting department only.

**Quick Reference**

- File: `lib/services/tmdb_service.dart`
- Auth: `SecretsService.tmdbAccessToken` → `Authorization: Bearer …`
- URLs: see `lib/utils/urls.dart`
