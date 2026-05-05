# Droonialarm SITREP logger

Cloudflare Worker, mis pollib `api.app.eesti.ee/api/sitrep/v1/full-events` iga minut ja salvestab kõik alert-vaatlused D1 andmebaasi.

**Eesmärk:** koguda empiiriline andmestik, et näha:
- Kas regionaalsed alert'id (üksiku maakonna) ilmuvad full-events list'i?
- Kui kauaks?
- Kui kiiresti pärast SMS'i?

## Mida ta kogub

Iga minut:
- **`snapshots`** — üks rida: päringu aeg, HTTP status, event'ide arv, alert'ide arv, raw vastuse SHA-256
- **`raw_archive`** — täielik JSON vastus (säilitame viimased ~3 päeva, vana visatakse minema)
- **`events`** — iga unikaalne event_id koos viimase tiitli/staatusega
- **`observations`** — üks rida iga unikaalse `(alert_id, content_digest)` kombinatsiooni kohta:
  - state, startDate, endDate, cancelledAt
  - EHAK koodid
  - tekst ET / EN / RU
  - notificationSound
  - first_seen ja last_seen — *millal me seda esimest korda nägime ja viimati nägime API-s*

## Setup

```bash
cd /Users/marttirandma/droonialarm/logger

# 1) Login (ühekordselt)
npx wrangler login

# 2) Loo D1 andmebaas
npm run db:create
# kopeeri tagastatav database_id wrangler.toml-i (asenda REPLACE_WITH_DB_ID_AFTER_CREATE)

# 3) Migreeri skeem
npm run db:migrate

# 4) Deploy
npm run deploy
```

Wrangler tagastab Worker'i URL'i kujul `https://droonialarm-sitrep-logger.<sinu-account>.workers.dev`. Ava see brauseris — näed dashboard'i.

## URL'id

- `/` — HTML dashboard, viimased 50 alert-vaatlust + 30 snapshot'i
- `/alerts.json` — viimased 200 alert-vaatlust JSON-na
- `/snapshots.json` — viimased 200 snapshot'i JSON-na
- `/raw?snapshot_id=N` — täisvastus (kui veel `raw_archive`'is)
- `/poll` — käsitsi poll (test'imiseks)

## SQL-päringud kontrollimiseks

```bash
# Mitu unikaalset alert'i kokku näinud?
npx wrangler d1 execute droonialarm-sitrep --remote \
  --command="select count(distinct alert_id) from observations"

# Kõik regionaalsed alert'id (üksik EHAK kood)
npx wrangler d1 execute droonialarm-sitrep --remote \
  --command="select alert_id, ehak_codes, first_seen, text_et from observations
            where ehak_codes != '' and ehak_codes not like '%,%'
            order by first_seen desc"

# Kui kaua iga alert API-s püsis (last_seen - first_seen)
npx wrangler d1 execute droonialarm-sitrep --remote \
  --command="select alert_id, first_seen, last_seen,
            (julianday(last_seen) - julianday(first_seen))*86400 as duration_sec
            from observations order by first_seen desc limit 50"
```

## Kulu

- Worker'i päringud: 1440/päevas = ~43 200/kuu, vaba tier on 100 000/päevas
- D1 reads/writes: ~10/min × ~14 400/päevas = vaba tier 100 000 read + 100 000 write
- D1 storage: ~263KB raw × 4320 snap = ~1.1GB; vaba tier 5GB

**Mahtub vabasse tier'i**.
