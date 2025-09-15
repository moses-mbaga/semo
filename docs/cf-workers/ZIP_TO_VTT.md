# Cloudflare Worker: zip-to-vtt

Fetches a remote ZIP containing subtitles, selects the best `.vtt`/`.srt`, converts SRT to WebVTT when needed, enables CORS, and edge‑caches the result.

Source: `cf-workers/workers/zip-to-vtt/index.ts`

## What it does

- Downloads the ZIP from `?url=<zip>`.
- Filters `.vtt` and `.srt` files.
- Chooses the best subtitle:
  - Prefers `.vtt`; fallsback to `.srt`,
  - Otherwise the first candidate.
- Converts SRT to WebVTT.

## Quick start

From `cf-workers/`:

```
npm install
npm run dev:zip-to-vtt
```

Wrangler prints a local URL like `http://127.0.0.1:8787`.

## API

Method: `GET` (and `OPTIONS` for CORS).

Query params:

- `url` (required): Encoded URL to the ZIP file.

Examples:

```
# Simple fetch; best candidate chosen automatically
curl "http://127.0.0.1:8787/?url=https%3A%2F%2Fexample.com%2Fsubs.zip" -i
```

### Authentication

- Requires `Authorization: Bearer <CF_WORKERS_API_KEY>` on non-`OPTIONS` requests.

### Secrets

- Provide a repository secret `CF_WORKERS_API_KEY` containing your API key.
- The GitHub Actions workflow uploads it to the worker via `wrangler secret put` before deploy.

### Behavior

- Response headers:
  - `Content-Type: text/vtt; charset=utf-8`
  - `Cache-Control: public, max-age=3600`
  - CORS: `Access-Control-Allow-Origin: *`, methods `GET, OPTIONS`, headers `Content-Type`
- On errors, returns JSON `{ "error": "message" }` with appropriate status and the same CORS headers.

### Edge caching

- Uses `caches.default` to cache successful responses for 1 hour by full request URL.

## Deploy

Local deploy (requires Cloudflare login):

```
npx wrangler login
npm run deploy:zip-to-vtt
```

GitHub Actions: see `.github/workflows/deploy-cf-workers.yml`. It installs deps and runs `npm run deploy:zip-to-vtt` when `cf-workers/**` changes on `main`. Required repository secrets:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `CF_WORKERS_API_KEY`

## Routes and domains

- Configure in `cf-workers/workers/zip-to-vtt/wrangler.toml` (add `routes`/`route`) or attach in the Cloudflare dashboard after deploy.

## Limits and caveats

- Large ZIPs: The entire archive is read into memory. Very large ZIPs can exceed memory/time limits on Workers. Keep subtitle zips small.
- Content layout: Only top-level files that end with `.srt` or `.vtt` are considered; nested directories are supported by zip.js but still filtered by filename.

## Observability

```
npx wrangler tail -c cf-workers/workers/zip-to-vtt/wrangler.toml
```

## Troubleshooting

- 400: Missing `url`.
- 502: Failed to fetch ZIP (provider returned non-OK).
- 422: ZIP had no entries, or none with `.srt`/`.vtt`.
- 500: Unexpected runtime errors.

## Security

- CORS is permissive for convenience. Restrict origins/methods if exposing publicly.
- Only fetches the URL you provide; verify and sanitize sources in your application before passing them to the worker.
