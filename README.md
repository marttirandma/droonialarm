# Droonialarm

> **MITTEAMETLIK** kolmanda osapoole avatud lähtekoodiga rakendus, mis re-broadcast'ib EE-ALARM teavitusi viisil, mis läbib telefoni vaikse režiimi ja Do Not Disturb seaded.
>
> **Ametlik kanal on EE-ALARM (1247) ja Päästeameti SMS.**
> Ametlikud ametid: [Päästeamet](https://www.rescue.ee/), [RIA](https://ria.ee), [SMIT](https://www.smit.ee).

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Phase](https://img.shields.io/badge/phase-1.0%20development-orange.svg)](#roadmap)
[![Logger](https://img.shields.io/badge/logger-LIVE-green.svg)](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev)

[English summary →](#english-summary) · [Architecture](docs/architecture.md) · [API analysis](docs/api-analysis.md) · [Privacy](docs/privacy.md) · [Letter to officials](docs/letter-to-paasteamet.md)

---

## Probleem

Eesti EE-ALARM süsteem saadab praegu droonihäireid ja teisi hädaolukorra teavitusi **location-based SMS**'ide kaudu. SMS'i tehnoloogiline puudus on:

- **Ei läbi telefoni vaikset režiimi** — telefon ei pii üldse, kui silent peal
- **Ei läbi Do Not Disturb seadeid** — magaja ei ärka
- **Toimib ainult kohaliku raku piirkonnas** — välismaal eestlased jäävad teadmata
- **3-5% õppuse Siil 2025 ajal ei saanud SMS'i üldse** ([Päästeamet, ERR](https://news.err.ee/1609984362/estonia-to-introduce-cell-broadcast-emergency-alert-system-in-2027))

Päästeamet on ise tunnistanud, et süsteem on **"liiga aeglane ja ebausaldusväärne"** ja [hangib praegu cell broadcast'i süsteemi](https://news.err.ee/1609984362/estonia-to-introduce-cell-broadcast-emergency-alert-system-in-2027) (€3.7M, operatiivne 2027).

**Vahepealse aja (2026-2027) jooksul** on Eesti elanikud — eriti unes, vaikse režiimi peal, ja välismaal viibivad eestlased — olukorras, kus nad ei saa hädaolukorra teateid kätte ka siis, kui need on saadetud.

### Konkreetsed juhtumid

- **3. mai 2026 03:23-05:30 EET** — Võrumaal droonioht. Vähemalt kolm sõltumatut tunnistajat võtsid meiega ühendust et nad ei kuulnud SMS'i (telefon vaiksel režiimil). Vt [SMS-screenshot](docs/evidence/ee-alarm-2026-05-03.png).
- **31. märts 2026 ~08:30 EET** — üleriigiline häire. Sama probleem.
- **25. märts 2026** — Auvere droonirünnak. Sama probleem.

## Põhimõte: hädaolukorra teavitus ei tohi olla autentimise taga

Üks võimalik vastus probleemi peale on "kasutage Eesti äppi". Aga Eesti äpp nõuab Mobiil-ID, Smart-ID või ID-kaardi sisselogimist — mistõttu jäävad sellest **välja**:

- Lapsed ja noored alla 15-aastased, kellel pole täisealist e-ID-d
- Eakad inimesed, kes pole e-ID kasutamist omandanud
- Välismaal elavad eestlased, kelle Mobiil-ID on aegunud või kes ootavad uut SIM-i
- Eestis viibivad turistid ja ajutised töötajad
- Igaüks, kel pole hetkel praktilist juurdepääsu e-ID-le

**Sireen ei küsi sinu isikukoodi.** SMS ei küsi sinu Smart-ID'd. Cell broadcast (mis tuleb 2027) ei küsi sinult midagi — see jõuab igale seadmele raku all.

**Hädaolukorra teavitus peab töötama samadel põhimõtetel: maksimaalne katvus, ilma autentimise barjäärita.** Eesmärk on **elusid päästa**, mitte konkreetse riigi-portaali kasutajaskonda kasvatada.

Selle põhimõtte tõttu on meie äpp **avatud kõigile** — ei küsi sisselogimist, ei küsi PII'd, ei küsi e-ID'd. Maakonna-valik on anonüümne, kohalikus seadmes. Ja kui Päästeamet otsustab Eesti äpi edasi-arendamise käigus, et hädaolukorra teavitused võiksid sealt **ka ilma sisselogimiseta** kättesaadavad olla — see oleks igal juhul **õige tee**.

## Lahendus

iOS- ja Android-rakendus, mis:

| Funktsioon | Tehnoloogia |
|---|---|
| **Möirgab läbi vaikse režiimi ja DND (Android)** | `NotificationChannel` `USAGE_ALARM` audio-attributes'iga + `enableBypassDnd(true)` + custom alarm sound + `ACCESS_NOTIFICATION_POLICY` permissioon |
| **Möirgab läbi vaikse režiimi ja DND (iOS)** | APNs Critical Alerts entitlement `com.apple.developer.usernotifications.critical-alerts` — taotleme Apple'ilt enne avalikku launch'i |
| **Töötab välismaal** | Push üle APNs/FCM, ei sõltu Eesti raku-piirkonnast |
| **Töötab ka ilma internetita (eesmärk)** | Android `READ_SMS` luba EE-ALARM saatja peal — vajab Google Play Permissions Declaration ja koostööd Päästeametiga |
| **Maakonna-valik** | Anonüümne, kohalik, ei saadeta serverile, EHAK koodi alusel |
| **Avalik lähtekood** | MIT licence, kogu kood + andmed + dokumentatsioon avalik |

## Tehniline avastus — `api.app.eesti.ee/api/sitrep/v1/full-events`

Eesti äpi avalikust APK'st reverse-engineering ja avalikust [Flutter source'ist](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public) leidsime, et **autentimist mitte nõudev avalik endpoint** eksisteerib:

```
GET https://api.app.eesti.ee/api/sitrep/v1/full-events
```

**Mida see annab:**
- 10 viimast SITREP event'i koos täieliku **ET / EN / RU** sisuga
- GeoJSON polügoonid ohupiirkondadest
- EHAK locations (kuigi praegu enamasti tühjad)
- Alert state (OPEN / COMPLETED / CANCELLED)
- Latentsus tegelik **~0 sekundit** SMS-väljastamise hetkega

**Mida see EI anna:**
- **Regionaalseid lühikesi alert'e** (alla 2 tundi, üksik maakond) — näiteks 3.05 Võrumaa alert sealt PUUDUS täiesti
- API kannab **ainult ~80%** EE-ALARM aktivatsioonidest empirika põhjal

Põhjus: SITREP backend on **SMIT-i (Siseministeeriumi infotehnoloogia- ja arenduskeskus) sisesüsteem**, ja `api.app.eesti.ee` on AINULT proxy mille abil Eesti äpp tarbib piiratud lõiku. **Pole teist avalikku endpoint'i** — kõik proovitud variandid (v2, eventId-järgi, EHAK-filtriga, jne) tagastasid sama 10 event'i.

[Põhjalik tehniline analüüs →](docs/reverse-engineering.md) · [API andmestruktuur →](docs/api-analysis.md)

## Live infrastruktuur

Kogu projekti taga töötab praegu üks komponent:

### Cloudflare SITREP Logger
**URL:** [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev)

Pollib `/api/sitrep/v1/full-events` iga minut ja kogub kõik vaadelused Cloudflare D1 SQLite andmebaasi. Eesmärk:
1. **Empiiriline mõõtmine** — kas regionaalsed lühikesed alert'id ilmuvad API-sse?
2. **Latentsus-andmed** — kui kiiresti pärast SMS'i?
3. **Kättetoimetatavus-statistika** — mis %-l alertidest on EHAK koodid?

[Avalik dashboard](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev) · [JSON: alerts](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev/alerts.json) · [JSON: snapshots](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev/snapshots.json) · [Logger code](logger/)

## Roadmap

### Phase 1.0 — SITREP polling MVP (käib praegu)
- [x] Cloudflare Worker logger deploy'itud, kogub andmeid
- [x] API forensic analüüs lõpetatud, dokumenteeritud
- [x] Ametlik pöördumine Päästeameti / RIA / SMIT-ile koostatud
- [ ] Flutter app'i scaffold (iOS + Android, baas-MVP)
- [ ] Backend (Go) — pollib SITREP, dispatchib FCM (Android) + APNs Critical Alerts (iOS)
- [ ] Android USAGE_ALARM channel + bypassDnd
- [ ] iOS APNs Critical Alerts integratsioon (tingitud Apple'i entitlement-vastusele)
- [ ] Maakonna-valik UI (EHAK põhine, anonüümne)
- [ ] Disclaimer kõikidel ekraanidel ("MITTEAMETLIK")
- [ ] TestFlight + Google Play Internal Testing

**Katvus:** ~80% EE-ALARM aktivatsioonidest (suured nationwide / multi-region event'id, mis avalikus SITREP feed'is on). Regionaalsed lühikesed alert'id jäävad EE-ALARM SMS'i hooleks; täiendava katvuse saaks Päästeametiga ühises lahenduses (vt Phase 2).

### Phase 1.1 — Apple Critical Alerts entitlement (iOS launch'i eeldus)
- [ ] Taotleme `com.apple.developer.usernotifications.critical-alerts` entitlement'it Apple'ilt — vorm [Apple Developer Contact'is](https://developer.apple.com/contact/request/notifications-critical-alerts/)
- [ ] Põhjendus: public-safety drone alert re-broadcast Eesti elanikele, mis töötab koostöös Päästeametiga
- [ ] Apple'i tüüpiline läbivaatus 2-4 nädalat — kuni vastuseni iOS app'i App Store'i ei lansseeri
- [ ] Entitlement käes → APNs `apns-priority: 10` + `sound.critical: 1` payload, läbib iga vaikse režiimi ja DND seade

### Phase 2 — Ametlik koostöö Päästeameti / RIA / SMIT-iga
Eesmärk on **ühine** lahendus, mille tehnilise kuju otsustavad Päästeamet ja RIA. Pakume välja, et:
- saaksime kinnituse, et avalik SITREP feed on lubatud kasutada;
- vajadusel sõlmiksime ametliku koostöölepe (kommunikatsioonipoliitika, alert-täpsus, kasutaja-info kaitse);
- kui see oleks kohaste tehniliste poolt mõistlik, võiksime teha rohkem (näiteks regionaalsete alertide tuum-feedi loomine), aga see on **täielikult Päästeameti / SMIT-i otsus**.

### Phase 3 — Cell broadcast era (2027+)
Kui Eesti võtab kasutusele cell broadcast (EU-Alert), tõenäoliselt äpp pole enam vajalik. Sulgeme projekti, võimaldame andmebaasi ja koodi avalikku arhiivi avatud andmetena.

## Privaatsus ja eetika

[Täielik privaatsuspõhimõte →](docs/privacy.md)

Lühidalt:
- **Pole sisselogimist** — ei küsi Smart-ID'd, mobil-ID'd, ega ühtegi PII'd
- **Anonüümne maakonna-valik** — salvestub kohalikult, ei saadeta serverile
- **FCM/APNs token'id** — salvestuvad serveris ainult anonüümselt, kustutame kuni 90 päeva
- **Pole reklaami, pole tasulisi funktsioone, pole andmemüüki**
- **Iga kasutaja saab äpi igal hetkel kustutada** → kogu data kadub
- **Kogu andmevoog avalikus GitHub'is** — saad ise kontrollida, et me ei tee midagi mida me ei räägi

## Mittekommertslik

- Hosting: Cloudflare Worker tasuta tier + Hetzner CCX13 (~5€/kuu, autori taskust)
- Pole crowdfunding'ut, pole pakettmaksu, pole IPO't
- Kui projekt vajab tulevikus rohkem ressursse, läheme MTÜ struktuurile (Eesti).

## Kuidas aidata

### Eesti elanikuna
- Kasutage **alati ametlikku EE-ALARM kanalit (1247)** ja kriis.ee kui peamine info-allikas
- See app on lihtsalt **lisaks**, mitte asendus
- Aitate meid testides: kui näete ebatäpsust või false-positive'i, [esitage issue](https://github.com/marttirandma/droonialarm/issues/new)

### Arendajana
- Lähtekoodi vaadake `app/` (Flutter), `backend/` (Go), `logger/` (Cloudflare Worker)
- Pull request'id teretulnud
- Vaata [CONTRIBUTING.md](CONTRIBUTING.md)

### Päästeameti, RIA, SMIT esindajana
Kui olete üks ülaltoodud asutustest:
- [Pöördumine teile →](docs/letter-to-paasteamet.md)
- Kontakt: randma.martti@gmail.com
- Oleme valmis igal hetkel täidesaatma teie tehnilisi/kommunikatsioonipoliitilisi nõudmisi
- Eelistaksime **ametlikku koostöö** sõlmimist re-broadcast aktiviteet'i kohta, mis annaks meile lugemis-juurdepääsu täielikule SITREP feed'ile

### Ajakirjanikuna
- Kõik tehnilised andmed avalikud GitHub'is — pole vaja küsida intervjuud, võtke koodibaas alla
- Kui tahate intervjuud projekti taga olevatest tehnoloogilistest valikutest või AvTS protsessist, pöörduge: randma.martti@gmail.com

## Kontakt

- **E-post:** randma.martti@gmail.com
- **GitHub:** [github.com/marttirandma/droonialarm](https://github.com/marttirandma/droonialarm)
- **Live logger dashboard:** [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev)

## Litsents

[MIT License](LICENSE) — kasutage vabalt.

## Tunnustused

- **Päästeamet** ja **SMIT** — SITREP infosüsteemi loomise ja avaliku ohutuse eest
- **RIA** — Eesti äpi avaliku lähtekoodi avaldamise eest [koodivaramu.eesti.ee](https://koodivaramu.eesti.ee), mis tegi selle projekti võimalikuks
- **AS Helmes**, **AS Finestmedia**, **Heisi IT OÜ**, **Srini OÜ** — SITREP süsteemi tegelikud ehitajad
- **Net Group** — Eesti äpi Flutter klient
- **Ukraina rahvas** — kelle pikaajaline kogemus drooniohu vastu valmistudes on Eestile õpikutähena saadav

---

## English summary

**Droonialarm** is an unofficial, open-source iOS+Android app that re-broadcasts Estonia's EE-ALARM emergency notifications in a way that bypasses Do Not Disturb and silent mode on the recipient's phone.

The Estonian state warning system currently sends drone-incursion alerts via location-based SMS. SMS does not bypass silent mode, does not ring through Do Not Disturb, doesn't reach Estonians abroad, and 3-5% of recipients didn't get the SMS at all during the May 2025 Siil exercise (per Päästeamet's own statistics). The official cell-broadcast replacement is procured but not operational until 2027.

This project bridges that gap by polling Estonia's public SITREP API (`api.app.eesti.ee/api/sitrep/v1/full-events`, no auth) every minute and pushing emergency-priority notifications to subscribed devices using:
- **Android:** `USAGE_ALARM` notification channel with `enableBypassDnd(true)`
- **iOS:** APNs Critical Alerts entitlement (`com.apple.developer.usernotifications.critical-alerts`), under application from Apple — iOS launch is conditional on Apple's approval.

Coverage is currently ~80% of EE-ALARM activations (large nationwide and multi-region events). Regional micro-alerts (single county, under 2 hours) would require formal collaboration with Päästeamet/RIA — see Phase 2.

The project is non-commercial, MIT-licensed, has no logins or PII collection, and is operated by [Martti Randma](mailto:randma.martti@gmail.com).

[Full English documentation in `docs/en/` →](docs/en/)
