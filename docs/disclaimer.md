# Disclaimer

## ⚠️ MITTEAMETLIK

**Droonialarm EI ASENDA ametlikku Eesti hädaolukorra teavitussüsteemi.**

Ametlik kanal on **EE-ALARM** ja informatsiooni-telefon **1247** (Päästeamet).

## Mida see app teeb

Droonialarm:
1. Pollib avalikku [api.app.eesti.ee/api/sitrep/v1/full-events](https://api.app.eesti.ee/api/sitrep/v1/full-events) endpoint'i iga 10-60 sekundi tagant
2. Kui näeb uut alert'i, saadab oma push-teavituse
3. See teavitus kasutab Android'is `USAGE_ALARM` notification channel'i ja iOS'is APNs Critical Alerts entitlement'i (Apple-issued) — mõlemad läbivad vaikse režiimi ja Do Not Disturb seaded

## Mida see app **EI tee**

- **Ei loo alert'e** — me oleme ainult re-broadcaster'id
- **Ei garanteeri 100% kohaletoimetatavust** — sõltume kolmandate osapoolte (Cloudflare, FCM, APNs) tehnoloogiast
- **Ei kanna regionaalseid lühikesi alert'e** Phase 1.0-s — need lähevad ainult EE-ALARM SMS'iga
- **Ei ole life-safety device** — ärge sõltuge sellest enda või lähedaste turvalisuse otsustamisel

## Vastutuse piiramine

MIT litsents on selge: tarkvara on saadaval "AS IS", **ilma garantiideta**.

Eriti:
- Me ei vastuta, kui meie alert ei toimeta (network outage, Apple/Google teenuse rike, server-down, jne)
- Me ei vastuta, kui meie alert on **valeärev** (false positive — kasutaja sai päringu, aga ohtu polnud)
- Me ei vastuta, kui meie alert on **liiga hiline** (latentsus 30+ sekundit pärast SMS'i)
- Me ei vastuta, kui meie alert sisaldab **valesõnastust** (kuna me lihtsalt re-broadcastime SITREP API tagastatavat teksti, peame õigsuse eest vastutavaks Päästeametit)

## Ametlikud allikad

Reaalse hädaohu korral kontrollige alati:

1. **EE-ALARM SMS'id** — saadetakse mobiilioperaatorite kaudu Eesti raku piirkonnas
2. **kriis.ee** — riigiportaal kriiside info'ga
3. **1247** — informatsiooni­telefon (Häirekeskus)
4. **112** — hädaabi-telefon
5. **Eesti äpp** — RIA / RIA ametlik mobil-rakendus
6. **Ole valmis!** — Naiskodukaitse kriisivalmiduse äpp
7. **err.ee** — ERR uudisvoog
8. **Päästeameti, Politsei ja Kaitseväe ametlikud sotsiaalmeedia-kanalid**

## Kuidas teatada veast

Kui näete:
- Meie äpp annab false positive (alert tekib, aga ametlikest allikatest ohtu pole)
- Meie äpp ei alertinud, kui ametlik EE-ALARM oli aktiivne
- Mingi muu probleem

Palun kirjutage:
- E-post: randma.martti@gmail.com
- GitHub issue: https://github.com/marttirandma/droonialarm/issues/new

## Kasutaja vastutus

Selle äpi paigaldamisega te kinnitate, et:
1. Saate aru, et see app on **mitteametlik kolmanda osapoole tööriist**
2. Te jätkate ametliku EE-ALARM kanalile reageerimist
3. Te ei sõltu **ainult** sellest äpist hädaolukorra info saamisel
4. Te mõistate, et alert võib olla hilja, valeärev või puududa
5. Te aktsepteerite MIT litsentsi all "AS IS" tarkvara saadavaolekut

## Kontakt

Vastutav: Martti Randma
E-post: randma.martti@gmail.com
GitHub: [marttirandma/droonialarm](https://github.com/marttirandma/droonialarm)
