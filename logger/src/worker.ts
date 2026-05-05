// Droonialarm SITREP logger — Cloudflare Worker.
//
// Cron: every 1 minute → fetch api.app.eesti.ee/api/sitrep/v1/full-events
// → record snapshot + diff alerts into D1.
// HTTP: GET / shows recent activity, GET /alerts.json returns JSON.

interface Env {
  DB: D1Database;
}

interface SitrepWrapper {
  type: string;
  data: {
    event: {
      id: number;
      title: string | null;
      eventStatus: string | null;
      startDate: string | null;
    };
    alerts?: SitrepAlert[];
  };
}

interface SitrepAlert {
  id: number;
  state: string | null;
  type: string | null;
  startDate: string | null;
  endDate: string | null;
  cancelledAt: string | null;
  notificationSound: string | null;
  content?: { countryCode?: string; title?: string; text?: string }[];
  ehakLocations?: { ehakCode?: string }[];
}

const SITREP_URL = "https://api.app.eesti.ee/api/sitrep/v1/full-events";
const ARCHIVE_KEEP = 4320; // 3 days × 1440 min

export default {
  async scheduled(_event: ScheduledEvent, env: Env, ctx: ExecutionContext) {
    ctx.waitUntil(pollAndStore(env));
  },

  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    if (url.pathname === "/poll") {
      // Manual poll (for testing).
      await pollAndStore(env);
      return new Response("polled\n");
    }
    if (url.pathname === "/alerts.json") {
      const rows = await env.DB.prepare(
        `SELECT alert_id, event_id, state, start_date, end_date, cancelled_at,
                ehak_codes, text_et, text_en, text_ru, notification_sound, alert_type,
                first_seen, last_seen
         FROM observations
         ORDER BY first_seen DESC
         LIMIT 200`,
      ).all();
      return Response.json(rows.results);
    }
    if (url.pathname === "/snapshots.json") {
      const rows = await env.DB.prepare(
        `SELECT id, fetched_at, status, event_count, alert_count, raw_size, raw_sha256
         FROM snapshots ORDER BY id DESC LIMIT 200`,
      ).all();
      return Response.json(rows.results);
    }
    if (url.pathname === "/raw") {
      const id = url.searchParams.get("snapshot_id");
      if (!id) return new Response("snapshot_id required", { status: 400 });
      const row = await env.DB.prepare(
        `SELECT body FROM raw_archive WHERE snapshot_id = ?`,
      )
        .bind(Number(id))
        .first<{ body: string }>();
      if (!row) return new Response("not found", { status: 404 });
      return new Response(row.body, { headers: { "content-type": "application/json" } });
    }
    return renderDashboard(env);
  },
};

async function pollAndStore(env: Env): Promise<void> {
  const fetchedAt = new Date().toISOString();
  let body = "";
  let status = 0;
  try {
    const res = await fetch(SITREP_URL, {
      headers: {
        "user-agent":
          "Droonialarm-Logger/0.1 (+https://github.com/marttirandma/droonialarm)",
        accept: "application/json",
      },
      // Cloudflare Workers default 30s timeout is plenty.
      cf: { cacheEverything: false } as RequestInitCfProperties,
    });
    status = res.status;
    body = await res.text();
  } catch (e: unknown) {
    console.error("fetch failed", e);
    await env.DB.prepare(
      `INSERT INTO snapshots(fetched_at, status, event_count, alert_count, raw_size, raw_sha256)
       VALUES(?,?,?,?,?,?)`,
    )
      .bind(fetchedAt, 0, 0, 0, 0, "fetch-failed")
      .run();
    return;
  }

  let parsed: SitrepWrapper[] = [];
  try {
    if (status === 200) parsed = JSON.parse(body);
  } catch {
    /* keep raw body, store as-is */
  }

  const sha = await sha256Hex(body);

  // Stable JSON for content_digest: sort alerts content by countryCode.
  const alertsFlat: { evtId: number | null; a: SitrepAlert }[] = [];
  for (const w of parsed) {
    const evtId = w.data?.event?.id ?? null;
    for (const a of w.data?.alerts ?? []) {
      alertsFlat.push({ evtId, a });
    }
  }

  const snapshotInsert = await env.DB.prepare(
    `INSERT INTO snapshots(fetched_at, status, event_count, alert_count, raw_size, raw_sha256)
     VALUES(?,?,?,?,?,?)`,
  )
    .bind(fetchedAt, status, parsed.length, alertsFlat.length, body.length, sha)
    .run();
  const snapshotId = Number(snapshotInsert.meta?.last_row_id ?? 0);

  // Archive raw body for forensic replay (only on real responses).
  if (status === 200 && body.length > 0 && snapshotId > 0) {
    await env.DB.prepare(
      `INSERT INTO raw_archive(snapshot_id, body) VALUES(?,?)`,
    )
      .bind(snapshotId, body)
      .run();
  }

  // Upsert events.
  for (const w of parsed) {
    const e = w.data?.event;
    if (!e?.id) continue;
    await env.DB.prepare(
      `INSERT INTO events(event_id, title, start_date, status, first_seen, last_seen)
       VALUES(?,?,?,?,?,?)
       ON CONFLICT(event_id) DO UPDATE SET title=excluded.title, status=excluded.status,
                                           last_seen=excluded.last_seen`,
    )
      .bind(e.id, e.title ?? "", e.startDate ?? "", e.eventStatus ?? "", fetchedAt, fetchedAt)
      .run();
  }

  // Upsert observations (one per alert × content_digest).
  for (const { evtId, a } of alertsFlat) {
    const digest = await contentDigest(a);
    const ehakCodes =
      (a.ehakLocations ?? [])
        .map((x) => x.ehakCode)
        .filter(Boolean)
        .join(",") || null;
    const textET = pickText(a.content, "ET");
    const textEN = pickText(a.content, "EN");
    const textRU = pickText(a.content, "RU");
    await env.DB.prepare(
      `INSERT INTO observations(alert_id, event_id, state, start_date, end_date,
                                cancelled_at, content_digest, ehak_codes,
                                text_et, text_en, text_ru, notification_sound,
                                alert_type, first_seen, last_seen)
       VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
       ON CONFLICT(alert_id, content_digest) DO UPDATE SET
         state=excluded.state, end_date=excluded.end_date,
         cancelled_at=excluded.cancelled_at, last_seen=excluded.last_seen`,
    )
      .bind(
        a.id,
        evtId,
        a.state ?? "",
        a.startDate ?? "",
        a.endDate ?? "",
        a.cancelledAt ?? null,
        digest,
        ehakCodes,
        textET,
        textEN,
        textRU,
        a.notificationSound ?? null,
        a.type ?? null,
        fetchedAt,
        fetchedAt,
      )
      .run();
  }

  // Prune raw_archive beyond the keep window.
  await env.DB.prepare(
    `DELETE FROM raw_archive
       WHERE snapshot_id IN (
         SELECT id FROM snapshots
         ORDER BY id DESC
         LIMIT -1 OFFSET ?
       )`,
  )
    .bind(ARCHIVE_KEEP)
    .run();
}

function pickText(
  cs: SitrepAlert["content"],
  lang: string,
): string | null {
  if (!cs) return null;
  for (const c of cs) {
    if (c.countryCode === lang && c.text) return c.text;
  }
  return null;
}

async function contentDigest(a: SitrepAlert): Promise<string> {
  const parts: string[] = [
    a.state ?? "",
    a.startDate ?? "",
    a.endDate ?? "",
    a.cancelledAt ?? "",
    ...(a.content ?? [])
      .slice()
      .sort((x, y) => (x.countryCode ?? "").localeCompare(y.countryCode ?? ""))
      .flatMap((c) => [c.countryCode ?? "", c.text ?? ""]),
  ];
  return await sha256Hex(parts.join(""));
}

async function sha256Hex(s: string): Promise<string> {
  const buf = new TextEncoder().encode(s);
  const hash = await crypto.subtle.digest("SHA-256", buf);
  return [...new Uint8Array(hash)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function renderDashboard(env: Env): Promise<Response> {
  const recentObs = await env.DB.prepare(
    `SELECT alert_id, event_id, state, start_date, end_date,
            ehak_codes, text_et, first_seen, last_seen
     FROM observations
     ORDER BY first_seen DESC
     LIMIT 50`,
  ).all<{
    alert_id: number;
    event_id: number | null;
    state: string;
    start_date: string;
    end_date: string;
    ehak_codes: string | null;
    text_et: string | null;
    first_seen: string;
    last_seen: string;
  }>();

  const recentSnaps = await env.DB.prepare(
    `SELECT id, fetched_at, status, event_count, alert_count, raw_size
     FROM snapshots ORDER BY id DESC LIMIT 30`,
  ).all<{
    id: number;
    fetched_at: string;
    status: number;
    event_count: number;
    alert_count: number;
    raw_size: number;
  }>();

  const html = `<!doctype html>
<html lang="et"><head>
<meta charset="utf-8"><title>Droonialarm SITREP logger</title>
<style>
  body { font: 13px/1.4 -apple-system, sans-serif; max-width: 1200px; margin: 24px auto; padding: 0 16px; background:#0c0c0c; color:#eee; }
  h1 { color:#ff5040; margin-bottom: 6px; }
  .sub { color:#888; margin-bottom: 24px; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 32px; }
  th, td { border-bottom: 1px solid #222; padding: 6px 8px; text-align: left; vertical-align: top; }
  th { color:#aaa; font-weight: 600; }
  tr:hover { background:#161616; }
  .state-OPEN { color:#ff5040; font-weight: 600; }
  .state-COMPLETED { color:#888; }
  .state-CANCELLED { color:#666; text-decoration: line-through; }
  code { background:#1a1a1a; padding: 1px 4px; border-radius: 3px; }
  .text { max-width: 600px; }
</style></head><body>
<h1>Droonialarm SITREP logger</h1>
<div class="sub">Pollib <code>api.app.eesti.ee/api/sitrep/v1/full-events</code> iga minut.</div>

<h2>Viimased 50 alert-vaatlust (alert_id × content_digest)</h2>
<table>
  <tr><th>alert_id</th><th>event</th><th>state</th><th>EHAK</th><th>algus</th><th>lõpp</th><th class="text">tekst (ET)</th><th>esmane vaatlus</th><th>viimane</th></tr>
  ${recentObs.results
    .map(
      (r) => `
  <tr>
    <td><code>${r.alert_id}</code></td>
    <td><code>${r.event_id ?? ""}</code></td>
    <td class="state-${r.state}">${r.state ?? ""}</td>
    <td><code>${r.ehak_codes ?? ""}</code></td>
    <td>${r.start_date ?? ""}</td>
    <td>${r.end_date ?? ""}</td>
    <td class="text">${escapeHtml(r.text_et ?? "")}</td>
    <td>${r.first_seen}</td>
    <td>${r.last_seen}</td>
  </tr>`,
    )
    .join("")}
</table>

<h2>Viimased 30 snapshot'i</h2>
<table>
  <tr><th>id</th><th>aeg</th><th>status</th><th>events</th><th>alerts</th><th>bytes</th><th>raw</th></tr>
  ${recentSnaps.results
    .map(
      (s) => `
  <tr>
    <td>${s.id}</td>
    <td>${s.fetched_at}</td>
    <td>${s.status}</td>
    <td>${s.event_count}</td>
    <td>${s.alert_count}</td>
    <td>${s.raw_size}</td>
    <td><a href="/raw?snapshot_id=${s.id}" style="color:#ff5040">↓</a></td>
  </tr>`,
    )
    .join("")}
</table>

<p><a href="/alerts.json" style="color:#ff5040">JSON: alerts</a> · <a href="/snapshots.json" style="color:#ff5040">JSON: snapshots</a> · <a href="/poll" style="color:#ff5040">manuaalne poll</a></p>
</body></html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8" } });
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
