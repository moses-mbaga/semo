# Cloudflare Worker: android-client

Signs and forwards API requests using an Android-like client profile and `x-tr-signature`. Supports GET, POST, and OPTIONS with permissive CORS for browser use.

## What it does

- Generates Android-style `User-Agent` and a randomized `X-Client-Info` JSON payload per request.
- Computes `x-tr-signature` via HMAC-MD5 using the app’s key and the canonicalized request components.
- Forwards the request to the target `url` with the provided `authorization` bearer token.
- Returns the upstream response body (as text) with `application/json` content type and CORS headers.

Source: `cf-workers/workers/android-client/index.js`

## Quick start

From `cf-workers/`:

```
npm install
npm run dev:android-client
```

Wrangler prints a local URL like `http://127.0.0.1:8787`.

## API

Endpoint: root path of the worker (e.g., `/`).

### POST (recommended)

Body (JSON):

```
{
  "url": "https://api.example.com/endpoint",   // required
  "method": "POST",                            // optional, defaults to POST
  "body": { "foo": "bar" },                   // optional object payload
  "authorization": "Bearer <YOUR_TOKEN>"       // optional; provide when required
}
```

Example:

```
curl -X POST "http://127.0.0.1:8787" \
  -H "Content-Type: application/json" \
  -d '{
        "url": "https://api.example.com/endpoint",
        "method": "POST",
        "body": {"foo": "bar"},
        "authorization": "Bearer <YOUR_TOKEN>"
      }'
```

### GET

Query params:

- `url` (required): Encoded target URL.
- `method` (optional): Defaults to `GET`.
- `body` (optional): JSON-encoded string; only for methods that accept bodies.
- `authorization` (optional): Bearer token string.

Example:

```
curl "http://127.0.0.1:8787/?url=https%3A%2F%2Fapi.example.com%2Fendpoint&method=GET&authorization=Bearer%20<YOUR_TOKEN>"
```

### Authentication

- Requires an `Authorization: Bearer <Firebase ID token>` header on non-`OPTIONS` requests.
- ID tokens are verified using the Firebase Admin SDK only.
- The Firebase project is read from `FIREBASE_PROJECT_ID` (set in each worker’s `wrangler.toml`).

### Secrets

- Provide the Firebase service account JSON to the worker as a secret named `FIREBASE_SERVICE_ACCOUNT_JSON`.
- In CI, set a repository secret `FIREBASE_SERVICE_ACCOUNT_JSON` with the entire JSON content (minified or pretty is fine).
- The GitHub Actions workflow uploads it to the worker via `wrangler secret put` before deploy.

### Behavior

- Headers added to upstream request:
  - `Authorization: <your value>` (if provided)
  - `Content-Type: application/json; charset=utf-8` (when a body is present)
  - `User-Agent`, `X-Client-Info`, `X-Client-Status: 1`, `X-Play-Mode: 2`, `x-tr-signature`
  - `Accept-Encoding`, `Connection: keep-alive`
- CORS: `Access-Control-Allow-Origin: *`; methods `GET, POST, OPTIONS`; headers `Content-Type, Authorization`.
- Response: Upstream body returned as text with `Content-Type: application/json`.

## Limits and caveats

- Signature body hash truncation: bodies larger than ~100 KB are truncated before hashing to compute the signature. Use small request bodies to avoid signature mismatch with upstream.
- Only `authorization` can be supplied from clients; arbitrary custom headers are not proxied.
- Upstream content types are normalized to `application/json` by this worker.

## Deploy

Local deploy (requires Cloudflare login):

```
npx wrangler login
npm run deploy:android-client
```

GitHub Actions: see `.github/workflows/deploy-cf-workers.yml`. It installs deps and runs `npm run deploy:android-client` when `cf-workers/**` changes on `main`. Required repository secrets:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `FIREBASE_SERVICE_ACCOUNT_JSON` (service account JSON value)

## Routes and domains

- Configure in `cf-workers/workers/android-client/wrangler.toml` (add `routes`/`route`) or attach in the Cloudflare dashboard after deploy.

## Observability

```
npx wrangler tail -c cf-workers/workers/android-client/wrangler.toml
```

## Troubleshooting

- 400: Missing `url` parameter/body.
- 401/403 from upstream: Invalid or missing `authorization` value.
- 5xx: Upstream error is propagated; generic 500 if the worker fails.
- Signature failures: Reduce payload size (<100 KB) and ensure the target URL and body match exactly what upstream expects.

## Security

- Do not hardcode tokens. Provide `authorization` per request or move token acquisition server-side.
- CORS is permissive for convenience. Restrict origins and headers if exposing publicly.
