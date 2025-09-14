// src/subtitles/worker.ts
import { ZipReader, BlobReader, TextWriter } from "@zip.js/zip.js";

const CACHE_TTL_SECONDS = 60 * 60; // 1 hour

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext) {
    try {
      const url = new URL(req.url);
      const zipUrl = url.searchParams.get("url");
      if (!zipUrl) {
        return jsonError("Missing ?url=<zip file>", 400);
      }

      // Edge cache
      const cache = caches.default;
      const cacheKey = new Request(req.url, { method: "GET" });
      const cached = await cache.match(cacheKey);
      if (cached) return withCors(cached);

      // Fetch ZIP
      const zipResp = await fetch(zipUrl, {
        headers: { "User-Agent": "SubProxy/1.0" },
      });
      if (!zipResp.ok) {
        return jsonError(`Failed to fetch ZIP: ${zipResp.status} ${zipResp.statusText}`, 502);
      }

      const zipBlob = await zipResp.blob();
      const reader = new ZipReader(new BlobReader(zipBlob));
      const entries = await reader.getEntries();

      if (!entries || entries.length === 0) {
        await reader.close();
        return jsonError("ZIP has no entries", 422);
      }

      // Pick the first .vtt if present, otherwise the first .srt
      const vtt = entries.find((e) => !e.directory && e.filename.toLowerCase().endsWith(".vtt"));
      const srt = entries.find((e) => !e.directory && e.filename.toLowerCase().endsWith(".srt"));

      const chosen = vtt ?? srt;
      if (!chosen) {
        await reader.close();
        return jsonError("No .srt or .vtt found in ZIP", 422);
      }

      const text = await chosen.getData!(new TextWriter());
      await reader.close();

      const bodyText = chosen.filename.toLowerCase().endsWith(".vtt")
        ? text
        : srtToVtt(text);

      const resp = new Response(bodyText, {
        status: 200,
        headers: {
          "Content-Type": "text/vtt; charset=utf-8",
          "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
        },
      });

      ctx.waitUntil(cache.put(cacheKey, resp.clone()));
      return withCors(resp);
    } catch (err: any) {
      return jsonError(err?.message || "Unexpected error", 500);
    }
  },
};

function withCors(resp: Response) {
  const h = new Headers(resp.headers);
  h.set("Access-Control-Allow-Origin", "*");
  h.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  h.set("Access-Control-Allow-Headers", "Content-Type");
  return new Response(resp.body, { status: resp.status, headers: h });
}

function jsonError(message: string, status = 500) {
  return withCors(
    new Response(JSON.stringify({ error: message }), {
      status,
      headers: { "Content-Type": "application/json; charset=utf-8" },
    })
  );
}

function srtToVtt(srt: string): string {
  const src = srt.replace(/\r\n/g, "\n");
  const lines = src.split("\n");
  const ts = /^(\d{2}:\d{2}:\d{2}),(\d{3})\s-->\s(\d{2}:\d{2}:\d{2}),(\d{3})(.*)$/;

  let out = "WEBVTT\n\n";
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];

    // Drop numeric cue indices if preceding a timestamp
    if (/^\d+$/.test(line.trim())) {
      if (i + 1 < lines.length && ts.test(lines[i + 1])) continue;
    }

    // Convert comma to dot in timestamps; keep any tail settings
    const m = line.match(ts);
    if (m) {
      line = `${m[1]}.${m[2]} --> ${m[3]}.${m[4]}${m[5] || ""}`;
    }

    out += line + "\n";
  }
  return out;
}

export interface Env { }
