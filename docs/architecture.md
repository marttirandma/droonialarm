# Süsteemiarhitektuur

## Phase 1.0 — SITREP API polling

```
┌─────────────────────────────────────────────────────┐
│  api.app.eesti.ee/api/sitrep/v1/full-events         │
│  (RIA / SMIT, autentimist mitte nõudev, avalik)     │
└──────────────────────┬──────────────────────────────┘
                       │
                       │ GET iga 10-60s
                       │
┌──────────────────────┴──────────────────────────────┐
│  Backend (Go binaarfail Hetzner CCX13 Helsinki)     │
│  - pollib SITREP, detekteerib uue alert.id          │
│  - dedupib content_digest'iga                       │
│  - dispatchib FCM (Android) + APNs (iOS)            │
│  - SQLite persistent state                          │
└──────────────────────┬──────────────────────────────┘
                       │
                       │ FCM topic / APNs token
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────┴────────┐            ┌───────┴────────┐
│  Android app   │            │  iOS app       │
│  (Flutter)     │            │  (Flutter)     │
│                │            │                │
│  USAGE_ALARM   │            │  APNs          │
│  channel,      │            │  Critical      │
│  bypassDnd=    │            │  Alerts        │
│  true,         │            │  entitlement   │
│  custom siren  │            │  (Apple-       │
│  loop          │            │  issued)       │
│                │            │                │
│                │            │  iOS launch    │
│                │            │  ootab Apple'i │
│                │            │  vastust       │
└────────────────┘            └────────────────┘
```

### Komponentide vastutused

| Komponent | Mida teeb | Repo path |
|---|---|---|
| **Cloudflare Worker logger** | Empiiriline andme­kogumine SITREP API käitumise kohta | `logger/` |
| **Backend (Go)** | Polling + FCM/APNs dispatch + state | `backend/` |
| **Flutter app (iOS+Android)** | Push võtmine + DND-bypass mängimine + maakonna-valik | `app/` |
| **Docs** | Avalik dokumentatsioon, ametlik pöördumine | `docs/` |

### Andme­voog

1. SITREP backend (SMIT) loob alert'i ja kannab selle proxy kaudu välja
2. Meie Go backend pollib endpoint'i 10-60s tagant
3. Backend võrdleb (alert_id, content_digest)'i SQLite state'iga; uus → dispatch
4. FCM topic push (Android) — kasutaja äpp võtab vastu, näitab USAGE_ALARM channel'iga
5. APNs Critical Alert push (iOS) — kasutaja äpp võtab vastu, süsteem mängib alarm-heli läbi vaikse režiimi (entitlement antud Apple'i poolt)
6. Telefon möirgab läbi vaikse režiimi ja kõikide DND / Focus seadete

### Phase 1.0 piirangud

- **Katvus ~80%** — regionaalsed lühikesed alert'id (üksik maakond, alla 2h) jäävad katmata, sest API neid ei kanna
- Kõikides UI-tekstides kuvatakse "**MITTEAMETLIK** — ametlik kanal on EE-ALARM (1247)"

---

## Phase 1.1 — Apple Critical Alerts entitlement (iOS launch'i eeldus)

iOS pool sõltub `com.apple.developer.usernotifications.critical-alerts` entitlement'i hankimisest Apple'ilt. Apple annab seda riigi-tasandi public-safety / health / emergency äppidele pärast 2-4 nädalat läbivaatust. Kuni vastuseni iOS-i App Store'i ei lansseerita.

Kui entitlement on käes, kasutame APNs payload'is `aps.sound = { critical: 1, name: "siren.caf", volume: 1.0 }` ja `interruption-level: critical`, mis läbib telefoni vaikse režiimi ja kõik Focus / DND seaded.

---

## Phase 2 — Ametlik koostöö Päästeameti / RIA / SMIT-iga

Eesmärk on **ühine** lahendus — täpne tehniline kuju on Päästeameti ja SMIT-i otsus. Pakume välja kolm võimalust, mis kõik sõltuvad **nende** valikust:

1. **Avaliku SITREP feed'i kasutuse kinnitamine** — me jätkame `/api/sitrep/v1/full-events` polling'uga, ametlikus dialoogis on selgitatud katvuse-piirangud ja kvoot.
2. **Ametlik koostöölepe** — kus oleme dokumenteeritud kui legitimse re-broadcast'i operaator, järgime Päästeameti kommunikatsioonipoliitikat ning saame vastutasuks kindluse, et meie tehnilist tegevust ei käsitleta süsteemi koormava või "varjuks" kanalina.
3. **Tehniliselt rikkalikum kanal** — kui Päästeamet leiab, et see on mõistlik (näiteks selleks, et regionaalsed alert'id jõuaks ka iOS-kasutajateni välismaal), saame koostöös arendada eraldi feed'i või topic-pre-aksepteerimist. **See on täielikult Päästeameti / SMIT-i otsus**, mitte meie nõudmine.

Igal juhul jääb meie äpp **ametliku EE-ALARM-kanali täienduseks**, mitte selle asendajaks. Disclaimer ja viide 1247-le on igal ekraanil.
```

---

## Andme­säilitus

| Andmetüüp | Kus | Kestus |
|---|---|---|
| Anonüümsed FCM/APNs token'id | Backend SQLite | Kuni kasutaja äpp deinstalleeritakse + 90 päeva |
| Anonüümne maakonna-eelistus | Backend SQLite | Sama |
| SITREP polling-snapshot'id | Cloudflare D1 (tasuta tier) | 3 päeva (raw archive); aggregaadid ilma piiranguta |
| Reverse-engineering artifaktid | GitHub repo (avalik) | Lõpmata |
| Telemetry / analytics | **PUUDUB** — pole kogu | — |

## Hosting kulu

| Komponent | Tasapind | Kulu / kuu |
|---|---|---|
| Cloudflare Worker + D1 | Tasuta tier | 0€ |
| Hetzner CCX13 Helsinki (backend) | $4.99 | ~5€ |
| Apple Developer | $99/aasta | ~9€ |
| Google Play Developer | $25 ühekordne | — |
| Firebase Cloud Messaging | Tasuta tier | 0€ |
| Domain (droonialarm.ee) | ~12€/aasta | ~1€ |
| **KOKKU** | | **~15€/kuu** |

Autori taskust, ilma crowdfunding'uta. Kui kasutajaskond ületab Cloudflare tasuta tier'i (100k päringut/päevas), läheme üle kommertskvoodile (~5€/kuu lisandub) või MTÜ struktuurile.
