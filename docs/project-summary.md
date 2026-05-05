# Droonialarm — projekti kokkuvõte

**MITTEAMETLIK** kolmanda osapoole avatud lähtekoodiga rakendus, mis re-broadcast'ib EE-ALARM teavitusi viisil, mis läbib telefoni vaikse režiimi ja Do Not Disturb seaded.

## Probleem

Eesti riigi praegune EE-ALARM süsteem saadab droonihäireid SMS'ide kaudu (location-based SMS). SMS'i puudus on, et:
- See ei läbi telefoni vaikset režiimi
- See ei läbi Do Not Disturb seadeid
- See ei ärata magajat
- See toimib ainult kohaliku raku piirkonnas (välismaal eestlased ei saa)

Päästeamet on ise tunnistanud, et 3-5% testil ei saanud SMS'i üldse ja et süsteem on "liiga aeglane ja ebausaldusväärne". Cell broadcast tuleb 2027.

**Vahepealse aja jooksul** on Eesti elanikud — eriti une ajal, vaikse režiimi peal ja välismaal viibivad eestlased — **olukorras, kus nad ei saa hädaolukorra teateid kätte ka siis, kui need on saadetud**.

## Lahendus

iOS- ja Android-rakendus, mis:

| Funktsioon | Tehnoloogia |
|---|---|
| Möirgab läbi vaikse režiimi ja DND (Android) | `NotificationChannel` `USAGE_ALARM` audio-attributes'iga + `enableBypassDnd(true)` + `ACCESS_NOTIFICATION_POLICY` permissioon |
| Möirgab läbi vaikse režiimi ja DND (iOS) | APNs Critical Alerts entitlement (`com.apple.developer.usernotifications.critical-alerts`) — Apple'ilt taotletud, iOS launch'i eeltingimus |
| Töötab välismaal | Push-teavitus läbi APNs/FCM, ei sõltu Eesti raku-piirkonnast |
| Töötab ka ilma internetita (Android-only) | Android'is `READ_SMS` luba EE-ALARM saatja peal — nõuab Google Play Permissions Declaration ja koostööd Päästeametiga. iOS-il pole Apple SMS-lugemise API'd, see funktsioon on ainult Android'il. |
| Maakonna-valik | EHAK koodi alusel, anonüümselt, ilma sisselogimiseta |
| Avalik lähtekood | MIT licence GitHub'is — kogu kood, dokumentatsioon, andmed avatud |

## Andmeallikas

`https://api.app.eesti.ee/api/sitrep/v1/full-events` — RIA / SMIT proxy SITREP süsteemi peale. Avalikuks kasutuseks (autentimist mitte nõudev), latentsus ~0s SMS-ist.

**Piirang:** API kannab ainult pikemalt aktiivseid suuremaid event'e (~80% katvus). Regionaalseid lühikesi alert'e (üksik maakond, alla 2 tunni) sealt ei tule.

Regionaalsete alertide täielik katmine eeldaks koostööd Päästeameti / RIA / SMIT-iga — täpne tehniline lahendus on ametiasutuste otsustada (vt [letter-to-paasteamet](letter-to-paasteamet.md)).

## Tegelik probleem mida me lahendame

Eesti äpp lubab "Külaline" režiimis (ilma sisselogimiseta) nationwide ohuteavitusi vastu võtta — see on õige disain. **Aga vaikne režiim ja DND lõhuvad selle kanali**, sest Eesti äpp kasutab Android'is vaikimisi notification channel'it (`USAGE_NOTIFICATION_EVENT`, ei läbi DND-d) ja iOS'is puudub Critical Alerts entitlement.

Tulemus: alert jõuab külalise telefonisse, aga öösel hääletu peal ta seda ei kuule — täpselt nagu SMS-iga.

Meie äpp lahendab just selle puuduva osa: **kuulmise**. Kasutame Android'is `USAGE_ALARM` notification channel'i `enableBypassDnd(true)`'ga ja iOS'is APNs Critical Alerts entitlement'i (Apple'ilt taotletud). Ei küsime sisselogimist, ei kogume PII'd — sama põhimõte mis Eesti äpi külaline-režiimil.

## Privaatsus

- Ei küsi sisselogimist
- Ei küsi PII'd
- Maakonna-eelistus salvestub kohalikult, ei saadeta serverile
- FCM/APNs token'id salvestuvad serveris ainult anonüümselt
- Server-pool on samuti avatud lähtekoodiga, käib Cloudflare Worker'is + D1
- Kasutaja saab äpi igal hetkel kustutada → kogu data kadub

## Mittekommertslik

- Pole tasulisi funktsioone
- Pole reklaami
- Pole andmemüüki
- Hosting Cloudflare'i tasuta tier'is + üks Hetzner CCX13 ($5/kuu, mu enda taskust)

## Disclaimer

Iga ekraani peal:

> **MITTEAMETLIK**
> Ametlik kanal on EE-ALARM (1247) ja Päästeameti SMS.
> See app kasutab avalikku api.app.eesti.ee andmevoogu —
> RIA, Päästeamet ega SMIT ei vastuta selle töökindluse eest.

## Avalik kontakt

- E-post: randma.martti@gmail.com
- GitHub: github.com/marttirandma/droonialarm (peagi)
- Eesti äpi alternatiiv ametliku rolli — Päästeamet 1247
