---
layout: default
title: Video — Droonialarm
permalink: /video/
---

# 🎥 Probleemi ja lahenduse selgitus

<blockquote class="tiktok-embed" cite="https://www.tiktok.com/@rahanetis/video/7636266800195456278" data-video-id="7636266800195456278" style="max-width: 605px; min-width: 325px; margin: 24px auto; display: block;">
  <section>
    <a target="_blank" title="@rahanetis" href="https://www.tiktok.com/@rahanetis">@rahanetis</a>
    <p>EE-ALARM SMS ei läbi vaikset režiimi — kuidas seda lahendada</p>
  </section>
</blockquote>
<script async src="https://www.tiktok.com/embed.js"></script>

## Kui video ei mängi

- 📱 Vaata otse TikTok'is: [tiktok.com/@rahanetis/video/7636266800195456278](https://www.tiktok.com/@rahanetis/video/7636266800195456278)
- 🎬 Lae alla MP4: [docs/media/droonialarm-video.mp4](https://github.com/marttirandma/droonialarm/raw/main/docs/media/droonialarm-video.mp4) (~20 MB)

## Mis videos räägitakse

Video selgitab konkreetset probleemi ja praktilist lahendust:

### Probleem
EE-ALARM süsteem saadab Eesti riigi droonihäireid SMS-ide kaudu. **SMS ei läbi telefoni vaikset režiimi ega Do Not Disturb seadet** — kui telefon on öösel hääletu peal, sa LIHTSALT EI KUULE droonihäiret.

Kontrollitud konkreetsed juhtumid:
- **3. mai 2026** Võrumaa droonioht — vähemalt 3 sõltumatut tunnistajat ei kuulnud
- **31. märts 2026** üleriigiline häire
- **25. märts 2026** Auvere droonirünnak

### Mis ei tööta praegu
Reverse-engineerisin Eesti äpi (sh uusima 1.24.0 versiooni) ja Ole Valmis äpi APK-d. **Kumbki ei kasuta** silent-mode-läbimise tehnikaid (Android `USAGE_ALARM` channel, iOS APNs Critical Alerts entitlement). Sama probleem mis SMS-iga.

### Lahendus
Avatud lähtekoodiga kolmanda osapoole äpp, mis möirgab läbi vaikse režiimi ja DND-d:
- **Android:** `USAGE_ALARM` notification channel `enableBypassDnd(true)`-ga + `ACCESS_NOTIFICATION_POLICY` permissioon
- **iOS:** APNs Critical Alerts entitlement (taotleme Apple'ilt)
- **Anonüümne** — pole sisselogimist, pole PII-d
- **Mittetululine** — MIT licence, github.com/marttirandma/droonialarm

### Pöördumine riigile
Saatsin ametliku AvTS § 14 pöördumise:
- Päästeametile (peadirektor Margo Klaos)
- RIA-le (peadirektor Joonas Heiter)
- SMIT-ile (peadirektor Kirke Saar)
- Häirekeskusele (1247)
- Siseministrile Igor Taro
- Justiits- ja digiministrile Liisa-Ly Pakosta
- Kaitseministrile Hanno Pevkur
- Õiguskantslerile Ülle Madise
- Andmekaitse Inspektsioonile
- Riigikogu komisjonidele

**Eesmärk koostöö-vaimus:** kui Eesti äpp ise lisab need parandused, mu projekt **muutub üleliigseks** ja sulgeme selle rõõmuga. Eesmärk pole konkureerida, eesmärk on et alarm jõuaks rohkemate inimesteni.

## Lugege rohkem

- [Pöördumine ametitele (täistekst)](letter-to-paasteamet/)
- [Tehniline analüüs — SITREP API](api-analysis/)
- [Reverse engineering tulemused](reverse-engineering/)
- [Privaatsuspõhimõte](privacy/)
- [Süsteemiarhitektuur](architecture/)

## ⚠️ Disclaimer

**MITTEAMETLIK.** Ametlik kanal on EE-ALARM (1247) ja Päästeameti SMS. See app on **täiendus**, mitte asendus. Ärge sõltuge ainult sellest oma turvalisuse otsustamisel.
