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

## Phase 1.1 — Android Notification Listener (regionaalse katvuse saavutamiseks)

```
                 ┌──────────────────────────────┐
                 │  Pixel 7 / Pixel 8 — relay   │
                 │  - 24/7 elektri all          │
                 │  - Päris Eesti äpp paigaldatud│
                 │  - Kõik maakonnad subscribitud│
                 │  - Meie kompanjon-äpp        │
                 │    NotificationListenerService│
                 └──────────────┬───────────────┘
                                │
                                │ HTTPS POST iga uue
                                │ Eesti äpi push'i kohta
                                │
┌─────────────────────────────────────────────────────┐
│  Backend (sama mis Phase 1.0)                       │
│  - eraldi endpoint: /v1/relay-ingest                │
│  - dedupib relay + SITREP API allikate vahel        │
│  - dispatchib edasi nagu enne                       │
└─────────────────────────────────────────────────────┘
```

### Relay-telefon

- **Riistvara:** Pixel 7 (~150€ kasutatuna) või Pixel 8 (~250€) — Google'i ametlik Android, kvaliteetne 24/7-tugi
- **Asukoht:** kuskil Eestis (st kohaliku raku piirkonnas, et FCM topic'utel oleks lokaalne kontekst)
- **Hooldus:** kord kuus läbi vaadata; reboot kui vaja
- **Backup:** üks varu-Pixel sama setup'iga, et single-point-of-failure ei oleks

### Privacy

- Relay-telefonil pole Smart-ID/Mobile-ID logimist — anonüümne maakonnaseire
- Eesti äpp ootab võibolla isikukoodi, aga FCM topic-subscribe töötab ka anonüümse kasutaja peal (testitud avalikust source'ist)

---

## Phase 2 — Ametlik partnerlus (eelistatud lõpplahendus)

Kui Päästeamet / SMIT / RIA vastab AvTS taotlusele positiivselt:

```
┌─────────────────────────────────────────────────────┐
│  Variant A: Eraldatud read-only API endpoint        │
│  https://api.app.eesti.ee/api/sitrep/v1/all-events  │
│  - Kõik alert'id, sh regionaalsed lühikesed         │
│  - Rate limit Päästeameti määratud (nt 1 päring/sek)│
│  - Autenditud API key'ga                            │
└──────────────────────┬──────────────────────────────┘
                       │
                       │  Sama backend kui enne, aga
                       │  100% katvus
                       ▼
              [ülejäänud sama]
```

**VÕI**

```
┌─────────────────────────────────────────────────────┐
│  Variant B: Otsene FCM topic juurdepääs             │
│  RIA Firebase project'is meie äpp kui co-listener   │
└──────────────────────┬──────────────────────────────┘
                       │
                       │  FCM push otse meie äppi
                       │  ilma backend'ita vahepeal
                       ▼
              [Android & iOS app'id]
```

Variant B on tehniliselt kõige elegantsem — eemaldame backend'i polling-koormuse täielikult ja saame sama latentsuse mis Eesti äpp ise.

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
