# Cloudflare Workers

Two Workers are maintained here, each with its own `wrangler.toml` under `workers/`:

- android-client: Signs and forwards requests to a target API using the Android app’s header scheme (generates `x-tr-signature`, Android-like UA, and client info). Supports GET and POST. CORS enabled.
- zip-to-vtt: Fetches a remote ZIP containing a subtitle of either `.srt` or `.vtt` and returns it as a `.vtt` file.

## Prerequisites

- Node.js 20+
- Cloudflare account and Wrangler (Wrangler is included in `devDependencies`)
- For deployments: Cloudflare API token and account ID

## Local Development

Install dependencies from this folder:

```
npm install
```

Run either worker locally (Wrangler will print the local URL/port):

```
npm run dev:android-client
npm run dev:zip-to-vtt
```

Or run both in parallel:

```
npm run dev:all
```

## Deployments

### Direct (local)

Authenticate once with Cloudflare, then deploy:

```
npx wrangler login
npm run deploy:android-client
npm run deploy:zip-to-vtt
```

Or deploy both in parallel:

```
npx wrangler login
npm run deploy:all
```

### GitHub Actions

Required repository secrets:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

The workflow installs deps and runs the two deploy scripts:

- `npm run deploy:android-client`
- `npm run deploy:zip-to-vtt`
- Or `npm run deploy:all` to deploy both in parallel

## Configuration

- Each worker’s `wrangler.toml` sets its `name`, `type`, `main`, and `compatibility_date`.
- To bind a custom domain/route, add the appropriate `routes`/`route` configuration to the worker’s `wrangler.toml` or configure routes in the Cloudflare dashboard after deployment.
