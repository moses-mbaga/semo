**Secrets Service**

- **Location:** `lib/services/secrets_service.dart`
- **Source:** Reads from `.env` using `envied` (code‑gen into `secrets_service.g.dart`).
- **Pattern:** Static accessors; no instance required.
- **Build step:** `dart run build_runner build --delete-conflicting-outputs` (re)generates `lib/services/secrets_service.g.dart` after `.env` changes.
- **Obfuscation:** Fields are generated with `obfuscate: true` to avoid plain‑text in source. This mitigates casual scraping but is not a security boundary.

**Environment Variables**

- `TMDB_ACCESS_TOKEN` (String): TMDB v4 API Bearer token.
- `SUBDL_API_KEY` (String): SubDL API key for subtitle downloads.
- `CINEPRO_BASE_URL` (String): Base URL for the CinePro streaming server.

 Declare these in `.env` (use `.env.example` as a template) and run the build step to embed/obfuscate values.

**API**

- `static String tmdbAccessToken`
  - Bearer token used by TMDB requests.
  - Consumed by: `lib/services/tmdb_service.dart` (Authorization header).

- `static String subdlApiKey`
  - API key used for SubDL subtitle queries.
  - Consumed by: `lib/services/subtitle_service.dart` (`api_key` query param).
- `static String cineProBaseUrl`
  - Base URL used for CinePro streaming server requests.
**Common Usage**

- TMDB requests auth header:
  - `HttpHeaders.authorizationHeader: "Bearer ${SecretsService.tmdbAccessToken}"`

- SubDL search parameters:
  - `{"api_key": SecretsService.subdlApiKey, ...}`

**Setup & Workflow**

- Add secrets to `.env` (never commit real values):
  - `TMDB_ACCESS_TOKEN=...`
  - `SUBDL_API_KEY=...`
  - `CINEPRO_BASE_URL=...`
- Generate code: `dart run build_runner build --delete-conflicting-outputs`.
- Verify build: `dart analyze` and run the app.

**Notes**

- Keep `.env` out of version control; only commit `.env.example`.
- If keys are missing or `.env` is not found, `envied` code generation will fail; ensure variables exist before running the build.
- Obfuscation reduces exposure in the repo but does not protect secrets in runtime binaries—treat them as sensitive.

**Quick Reference**

- File: `lib/services/secrets_service.dart`
- Generated: `lib/services/secrets_service.g.dart`
- Env: `.env` with `TMDB_ACCESS_TOKEN`, `SUBDL_API_KEY`, `CINEPRO_BASE_URL`
- Build: `dart run build_runner build --delete-conflicting-outputs`
