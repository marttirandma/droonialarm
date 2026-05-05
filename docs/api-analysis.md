# SITREP API analüüs — `api.app.eesti.ee/api/sitrep/v1/full-events`

**Status:** Avalik, autentimist mitte nõudev. Latentsus reaalse SMS-väljastamise hetkega ~0 sekundit. Katvus ~80% EE-ALARM aktivatsioonidest empirika põhjal.

**Allikas:** Reverse-engineering Eesti äpi v1.22.0 APK'st (SHA-256 `55390e57b83417ed07e36a304af48102cc5802be18659dfc0b7b406f01778501`) ja avalikust [Flutter source'ist](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public).

---

## 1. Endpoint-i karakteristikud

```
GET https://api.app.eesti.ee/api/sitrep/v1/full-events
```

| Omadus | Väärtus |
|---|---|
| HTTP method'id | Ainult `GET` (kõik teised → 405) |
| Authentication | Pole — accept'ib tühja päringut |
| Content-Type | `application/json` |
| Vastuse tüüp | JSON array, alati 10 elementi |
| Vastuse suurus | ~263KB (sisaldab GeoJSON polügoone) |
| Cloudflare-fronted | Jah (`cf-cache-status: DYNAMIC`) |
| Query parameetrid | **Kõik ignoreeritakse** — testitud `?ehak=`, `?ehakCode=`, `?county=`, `?location=`, `?eventId=`, `?since=`, `?date=`, `?topic=`, `?status=`, `?limit=`, `?page=` — sama 10 elementi vastusena |
| Header'id | Kõik ignoreeritakse — testitud `Accept-Language`, `User-Agent`, `Authorization`, `X-API-Key` — sama vastus |

## 2. Andme­struktuur

```typescript
type SitrepWrapper = {
  type: "EVENT_FULL";
  data: {
    event: {
      id: number;                    // SITREP DB primary key
      title: string;                 // näiteks: "Droonioht"
      eventStatus: "OPEN";           // ainus väärtus mida olen näinud
      startDate: string;             // ISO-8601 UTC, mikrosekundi täpsus
      finishedDate: string | null;
      addressId: number | null;
      address: object | null;
    };
    behavioralGuideline: object | null;  // Alati null mu vaatluses
    documents: object[];
    alerts: SitrepAlert[];
  };
};

type SitrepAlert = {
  id: number;                        // DB primary key
  alertId: number | null;            // External alert ID (kõikidel mu vaatlustel null)
  parentAlertId: number | null;      // CAP-stiilis ahel update'idele
  type: "NOTIFICATION";              // libapp.so'st leidsin ka "MOBILE_HAZARD_ALERT"
  state: "OPEN" | "COMPLETED" | "CANCELLED";
  eventId: number;
  startDate: string;                 // ISO-8601 UTC
  endDate: string;                   // ISO-8601 UTC
  cancelledAt: string | null;
  notificationSound: "PHONE_DEFAULT" | string;
  content: SitrepContent[];
  ehakLocations: { ehakCode: string }[];   // PRAEGU TÜHI enamasti
  geoJsons: SitrepGeoJson[];
};

type SitrepContent = {
  countryCode: "ET" | "EN" | "RU";  // !!! "countryCode" hoiab tegelikult keele-koodi
  languageCode: null;                // Alati null
  title: string;                     // näiteks: "EE-ALARM"
  text: string;                      // Tegelik teate tekst
};

type SitrepGeoJson = {
  id: number;
  uuid: string;
  name: string;                      // näiteks: "alertId-457-alertLayer"
  geoJson: string;                   // STRINGIFITUD GeoJSON FeatureCollection
};
```

**Märkused:**

- **`countryCode` kasutamine keele jaoks** ("ET", "EN", "RU") on omapärane disain'iotsus. Standard CAP / EDXL kasutaks `language` ISO-639 koodiga. See on identifitseeritav fingerprint, mis annab tunnistust et see schema on **bespoke SMIT süsteem**, mitte CAP-baasil.
- **`geoJson` on stringitud JSON sees JSON'is** — peame ise parsima.
- **`ehakLocations` on praegu tavaliselt tühi** — kõik mu vaatlused jaanuar-mai 2026'st on `[]`. Geograafiline kontekst tuleb GeoJSON polügoonidest või tekstist.

## 3. Mida endpoint kannab — empirika

Vt avalikku Cloudflare logger'i andmestikku: [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev)

### Kannab — kinnitatud

| Kuupäev | Sündmus | Kestus | Region |
|---|---|---|---|
| 25. märts 2026 | Auvere droonirünnak | ~12h | Ida- ja Lääne-Virumaa (multi-county) |
| 25. märts 2026 | Virumaa täpsustus | ~24h | Ida- ja Lääne-Virumaa |
| 31. märts 2026 | Üleriigiline õhuoht | ~10h | Eesti, Ida-/Lääne-/Lõuna-Eesti |
| 16. märts 2026 | Tehniline test | ~14h | Üleriigiline test |
| Jaanuar 2025 | Toimepidevuse kontroll | mitu vaatlust | Sisemised testid |

### EI kanna — kinnitatud

| Kuupäev | Sündmus | Kestus | Region |
|---|---|---|---|
| **3. mai 2026** | **Võrumaa droonioht** | **2h** | **Üksik maakond (Võrumaa)** |

3. mai 2026 03:23-05:30 EET aktiveeritud EE-ALARM **ei ilmunud** ei `v1` ega `v2` `full-events` vastusesse. SMS oli olemas, kasutaja sai (vt evidence/ee-alarm-2026-05-03.png).

### Hüpotees katvuse kohta

API kannab tõenäoliselt event'e mis vastavad SITREP backend'is "publish to public app feed" lipule. Üksikute maakondade lühikesed alert'id, mis lähevad MASS_SMS / FCM-only marsruudi, ei läbi seda lippu. **Selle peab kinnitama Päästeamet / SMIT.**

## 4. Mida endpoint EI ANNA — võrdluseks Eesti äpi enda push'iga

Eesti äpi tegelik FCM push payload (vt [push_notifications_service.dart](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public/-/raw/main/lib/services/push_notifications_service.dart#L132-193)) sisaldab struktureeritud välju:

```dart
data['title']                      // EE tekst
data['body']                       // EE tekst
data['location.county']            // näiteks: "Võrumaa"
data['location.settlementUnits']   // JSON array EHAK nimedest
```

Need on **ainult FCM payload'is**, mitte API vastuses. See tähendab: API `ehakLocations` puudus ei tähenda, et alert ei oleks regioonide-spetsiifiline — lihtsalt API ei eksponeeri seda struktureeritud kujul.

**Praktiline järeldus:** kui me regioonipõhiseid alert'e kättesaame, peame **teksti parsima** ("Lõuna-Eestis" → ehak: [Põlva, Valga, Võru], jne), mitte struktureeritud välja kasutama.

## 5. Sõsar-endpoint'id — täielik nimekiri

Reverse-engineerides libapp.so strings dump'ist:

```
/api/sitrep/v1/full-events                    GET, avalik
/api/sitrep/v2/full-events                    GET, avalik (small body — 190KB vs 263KB)
/api/notification/v1/ehak/counties            GET, avalik (FCM topic'ute nimekiri)
/api/notification/v1/push-tokens              POST/DELETE, autenditud (Eesti äpi enda kasutamiseks)
/api/notify/v1/notifications                  GET, avalik (in-app banner'id, mitte SITREP)
```

**Pole** rikkamat endpoint'i, mis tagastaks kõik alert'id ehak-koodidega filtreerida.

## 6. Latentsus — empirika

Mõõdetud kahe juhtumi peal mille SMS dispatch aeg ja API event startDate on mõlemad teada:

| Sündmus | SMS aeg (~) | API alert.startDate | Vahe |
|---|---|---|---|
| 25. märts 2026 Auvere | 09:32 EET | 2026-03-25T06:32:39.485Z (= 09:32:39 EET) | **+39 sekundit** |
| 31. märts 2026 üleriigiline | 00:30 EET | 2026-03-30T21:30:00Z (= 00:30 EET) | **0 sekundit** |

**API on sama backend mis SMS'i saadab.** Latentsus polling-intervalli järgi.

Soovituslik polling-intervall: **10 sekundit** (lubab Cloudflare Worker'is ainult 1 minut, aga Hetzner cron'iga saab tihedamini). 5-15 sekundit annab piisava tundlikkuse ilma server'it tarbetult koormata.

## 7. Stabiilsus

- Cloudflare-fronted (`cf-ray` header'is rütm muutub) → load-balanced
- 200 OK consistent läbi mitme tunni testimise
- Üks 500 error mu testides (1500+ päringust) — võrgu-glitch
- Ei näinud 429 rate limiting'ut intensiivse polling'u juures

**Kasutuse kvoot pole avaldatud.** Eetiline ülempiir: meie polling 1/min vajab ~43 200 päringut kuus, mis on Cloudflare standard'ide järgi tühine. Aga kui me saame ametliku partnerluse, saaks tihedamalt.

## 8. Risk

- **Endpoint võib igal hetkel autentitud-only kanaliks muuta.** Kui SMIT/RIA niimoodi otsustab, oleme tehniliselt katki ja vajaks ametlikku kanalit.
- **Schema võib muutuda.** v1 → v2 → v3 üleminekul peame kohanduma.
- **Rate limit võib kõvastada.** Praegu pole, aga kui meil on suur kasutajaskond ja pollime tihedalt, võib SMIT meid loomulikult piirata.

**Maandus:** ametlik dialoog Päästeameti / RIA / SMIT-iga. Kui meil on koostöölepe, on tehniline jätkusuutlikkus tagatud.

---

## Kontrolli ise

Käivita:

```bash
curl -s -A "Mozilla/5.0" \
  https://api.app.eesti.ee/api/sitrep/v1/full-events \
  | python3 -m json.tool | head -100
```

Reaalajas seire:

- Live dashboard: [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev)
- JSON: [/alerts.json](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev/alerts.json), [/snapshots.json](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev/snapshots.json)
- Logger code: [`logger/`](../logger/)
