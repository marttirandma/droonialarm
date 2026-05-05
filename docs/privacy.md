# Privaatsuspõhimõte

**Versioon 1.0 — kehtiv 4. mai 2026.**

Droonialarm projekt on disainitud selliselt, et **kasutaja PII ei kogune kunagi**. See dokument täpsustab, mida me tegelikult kogume, miks, ja kuidas.

## TL;DR

- **Pole sisselogimist** — ei küsita Smart-ID'd, mobil-ID'd, e-maili, telefoninumbrit
- **Pole reklaami, pole 3rd-party tracker'eid, pole analytics SDK-d**
- **Ainus mida me serveris hoiame:** anonüümne FCM/APNs token + maakonna-valik
- **Iga kasutaja saab äpi igal hetkel kustutada** → kogu data kustub

## Mida me kogume

### 1. Push notification token

| Mis | Miks | Kuidas hoitakse |
|---|---|---|
| FCM device token (Android) või APNs device token (iOS) | Selleks et saata push'i kasutaja seadmele | SQLite andmebaasis backend'is, mitte seotud nime/numbri/e-mailiga |

Token on anonüümne — Google'i ja Apple'i poolt seadmele eraldatav identifikaator. Meil pole võimalust seda token'it konkreetsele isikule seostada.

### 2. Maakonna-eelistus

| Mis | Miks | Kuidas hoitakse |
|---|---|---|
| EHAK koodide list (näiteks ["0086"] = Võru) | Selleks et saata ainult relevantseid alert'e | Salvestub kohalikult `SharedPreferences`'is JA serveris koos token'iga |

Maakonna-eelistus pole privaatne info, aga me hoiame seda anonüümselt token'iga seotuna.

### 3. App version + platvorm

Selleks, et saaksime planeerida updateid ja debug'ida:
- `platform` (android | ios)
- `version` (näiteks 1.0.0)
- `osVersion` (näiteks Android 14, iOS 17.5)

## Mida me **EI** kogu

- ❌ E-maili aadress
- ❌ Telefoninumber
- ❌ IP aadress (server logib esimesed 30 päeva debug'imise tarbeks, siis kustub automatically)
- ❌ Geolocation (asukoha-koordinaadid)
- ❌ Seadme reklaami-ID (Android Advertising ID, iOS IDFA)
- ❌ Käitumise telemetry — millal äppi avate, mida vajutate, jne
- ❌ Kontakte, fotosid, mikrofoni, kaamerat
- ❌ Smart-ID / Mobile-ID identifikaatoreid
- ❌ Mingit muud isiku-identifitseerivat infot

## Andme­säilitus

| Andmed | Kestus |
|---|---|
| FCM/APNs token + maakonna-eelistus | Kuni äpp deinstalleeritakse + 90 päeva (FCM/APNs ise teavitab token'i kehtetuks-jäämisest, või server tuvastab seda push'i error response'ist) |
| Server logfailid | 30 päeva (sisaldab IP'd debug'imise tarbeks, siis kustutatakse) |
| Cloudflare logger raw archive | 3 päeva (siis pruunitakse automaatselt) |
| Cloudflare logger aggregaadid (alert observations) | Lõpmata, AGA need on AVALIKUS andmed (alert tekstid + ajad), ilma kasutaja-infoga |

## Andmete jagamine kolmandate osapooltega

### Mida me **JAGAME**:
- **Cloudflare** (logger hosting, FCM/APNs dispatch infrastructure) — Cloudflare on alusplatform, ta näeb meie database sisu sama palju kui meie ise. [Cloudflare DPA](https://www.cloudflare.com/cloudflare-customer-dpa/).
- **Hetzner** (backend hosting) — sama, alusplatform.
- **Google Firebase** (FCM dispatch Android'ile) — Google näeb FCM token'eid, sõnumi sisu (alert tekstid).
- **Apple** (APNs dispatch iOS'ile) — Apple näeb APNs token'eid, alert tekstid encrypt'itakse end-to-end aga Apple näeb metadata'd.

### Mida me **EI JAGA**:
- Andmemüük — pole
- Reklaami-võrkudele — pole
- Analytics teenusepakkujatele — pole
- Riigi ametiasutustele — pole, kui pole konkreetset õiguskaitse-päringut, mille me kontrollime juriidikuga ja vajalik teavitame avalikkust

## Avalik andmestik

Cloudflare logger'i andmestik on **AVALIK** — kõik saavad näha samu andmeid: [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev).

See andmestik **ei sisalda kasutaja-infot** — see on lihtsalt SITREP API tagastatav alert-loend (sama mis avalik niigi).

## Õiguslik

- Vastutav töötleja: Martti Randma, randma.martti@gmail.com
- Töötlemise alus: GDPR Art. 6(1)(a) — kasutaja nõusolek (äpi paigaldamise ja maakonna-valikuga)
- Andmesubjekti õigused: kustutamine (deinstall'iga), juurdepääs (e-postiga küsides), portatiivsus (e-postiga küsides)

## Muudatused

Selle dokumendi muudatused versioneerime ja avaldame [GitHub repos](https://github.com/marttirandma/droonialarm/blob/main/docs/privacy.md) koos commit-ajaloo läbipaistvalt.

Olulised muudatused (näiteks uut tüüpi andmete kogumine) **antakse** kasutajale äpis sisse-tulles teada, ja **vajavad eraldi nõusolekut**.
