-- snapshots: one row per poll. Stores raw JSON for forensic replay.
CREATE TABLE IF NOT EXISTS snapshots (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  fetched_at   TEXT NOT NULL,
  status       INTEGER NOT NULL,
  event_count  INTEGER NOT NULL,
  alert_count  INTEGER NOT NULL,
  raw_size     INTEGER NOT NULL,
  raw_sha256   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_snapshots_fetched_at ON snapshots(fetched_at);

-- observations: every (alert_id, content_digest) pair we ever see.
-- One row per (alert_id, content_digest) — tracks state churn.
CREATE TABLE IF NOT EXISTS observations (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  alert_id        INTEGER NOT NULL,
  event_id        INTEGER,
  state           TEXT,
  start_date      TEXT,
  end_date        TEXT,
  cancelled_at    TEXT,
  content_digest  TEXT NOT NULL,
  ehak_codes      TEXT,
  text_et         TEXT,
  text_en         TEXT,
  text_ru         TEXT,
  notification_sound TEXT,
  alert_type      TEXT,
  first_seen      TEXT NOT NULL,
  last_seen       TEXT NOT NULL,
  UNIQUE(alert_id, content_digest)
);
CREATE INDEX IF NOT EXISTS idx_observations_alert ON observations(alert_id);
CREATE INDEX IF NOT EXISTS idx_observations_first_seen ON observations(first_seen);

-- events: distinct events seen with their latest title/status.
CREATE TABLE IF NOT EXISTS events (
  event_id     INTEGER PRIMARY KEY,
  title        TEXT,
  start_date   TEXT,
  status       TEXT,
  first_seen   TEXT NOT NULL,
  last_seen    TEXT NOT NULL
);

-- raw payload archive — keep last N snapshots for replay/debug.
-- Old rows are pruned by a periodic cleanup query (see worker).
CREATE TABLE IF NOT EXISTS raw_archive (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  snapshot_id  INTEGER NOT NULL REFERENCES snapshots(id),
  body         TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_raw_snapshot ON raw_archive(snapshot_id);
