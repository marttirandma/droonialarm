# Pöördumine: avalik EE-ALARM teavituste reaalajas-kanali loomine kolmanda osapoole hädaabi-äpi tarbeks

**Saatja:** Martti Randma, randma.martti@gmail.com, +372 5539649
**Kuupäev:** 5. mai 2026
**Õiguslik alus:** Avaliku teabe seadus § 6 lg 1 ja § 14 lg 1; Hädaolukorra seadus § 17 lg 1
**Projekti repo:** [github.com/marttirandma/droonialarm](https://github.com/marttirandma/droonialarm)

## Adressaadid

### Põhiadressaadid (operatiivne vastutus)

| Asutus | Kontakt |
|---|---|
| Päästeamet (peadirektor Margo Klaos) | rescue@rescue.ee |
| Riigi Infosüsteemi Amet RIA (peadirektor Joonas Heiter) | info@ria.ee |
| Siseministeeriumi infotehnoloogia- ja arenduskeskus SMIT (peadirektor Kirke Saar) | smit@smit.ee |
| Häirekeskus (1247) | 112@112.ee |

### Ministrid (poliitiline vastutus)

| Roll | Minister | Kontakt |
|---|---|---|
| Siseminister (Päästeamet, SMIT, Häirekeskus) | Igor Taro | info@siseministeerium.ee |
| Justiits- ja digiminister (vastutab RIA eest) | Liisa-Ly Pakosta | info@justdigi.ee |
| Kaitseminister (drooni-intsidendid) | Hanno Pevkur | info@kaitseministeerium.ee |
| Majandus- ja taristuminister (cell broadcast, sideregulatsioon) | Erkki Keldo / Kuldar Leis | info@mkm.ee |

### Järelevalve- ja konsultatsiooniorganid (info teadmiseks)

| Asutus | Kontakt |
|---|---|
| Õiguskantsler Ülle Madise | info@oiguskantsler.ee |
| Andmekaitse Inspektsioon | info@aki.ee |
| Riigikantselei valitsuse kommunikatsioonibüroo | riigikantselei@riigikantselei.ee |
| Riigikogu Riigikaitsekomisjon | riigikaitsekomisjon@riigikogu.ee |
| Riigikogu Põhiseaduskomisjon | pohiseaduskomisjon@riigikogu.ee |

---

## Lugupeetud adressaadid

Kirjutan teile ühe konkreetse avaliku ohutuse probleemi pärast, mille olen viimaste nädalate jooksul mitmest sõltumatust allikast kuulnud — sealhulgas oma perekonnast — ja mille tehnilist lahendamist tahan ette pakkuda.

### Probleem

EE-ALARM süsteem saadab praegu droonihäireid ja teisi hädaolukorra teavitusi **location-based SMS**'ide kaudu. Selle tehnoloogilise valiku puudus on, et **SMS ei läbi telefoni vaikset režiimi ega Do Not Disturb seadet** — telefon teeb tavalise (kui üldse) teavitusheli, mis ei ärata magajat ja jääb tavaliselt märkamata.

Olen ise praegu Balil, **mu tütar elab Eestis**. Pärast 25. märtsi Auvere droonirünnakut ja 31. märtsi üleriigilist häiret, ning eriti pärast 3. mai pühapäeva-varahommikust Võrumaa droonihäiret (03:23-05:30 EET), on vähemalt **kolm sõltumatut inimest minuga ühendust võtnud**, kes olid kohapeal aga **ei kuulnud SMS-i** — telefon oli vaiksel režiimil. Samuti on minu enda ema Eestis öelnud, et ei kuule neid teavitusi öösel.

Päästeamet ise on [avalikult tunnistanud](https://www.err.ee/1609984068/eesti-plaanib-aasta-parast-kasutusele-votta-vorgupohise-valkteavituse), et uus võrgupõhine ohuteavitus (cell broadcast) on **"oluliselt tõhusam kui praegused äpiteavitused ja SMS-id"**, ning et osa kasutajatest on Päästeametiga ühendust võtnud just selle pärast, et **SMS ei jõudnud kohale** (eri põhjustel). Cell broadcast'i hange (3,67 mln €) on käimas, esimene võimekus on planeeritud 2026. aasta sügiseks, täismahus 2027-l. Kuni selle ajani jääb avalik kasutaja praeguse, ebatõhusama kanali kätte.

### Tunnustus Eesti äpi disaini-otsusele

Tahan kiidelda ühte head tehnilist otsust, mille me [Eesti äpi avalikust lähtekoodist](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public/-/raw/main/lib/services/push_notifications_service.dart) leidsime: **Eesti äpis töötab "Külaline" režiim** ([pre_login_screen.dart:134-146](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public/-/raw/main/lib/views/screens/pre_login_screen.dart)) — kasutaja saab äpi paigaldada ja "Külaline" nupule vajutades pääseda otse HomeScreen'ile, ilma Mobiil-ID / Smart-ID / ID-kaardi sisselogimist. Sellisel külalisel **automaatselt** lülitatakse sisse SITREP topic-subscriptions ([push_notifications_service.dart:56-63, 110-113, 323-327](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public/-/raw/main/lib/services/push_notifications_service.dart)), ja tema FCM seade saab vastu kõik nationwide EE-ALARM teavitused.

See on **õige disain** — hädaolukorra teavitus jõuab igale seadmele, mis äpi paigaldab, sõltumata kasutaja autentimise-staatusest. See vastab täpselt põhimõttele, mille kohaselt sireenid, SMS ja cell broadcast töötavad: "alert jõuab igale, kes on raku all, ükskõik kes ta on."

### Tegelik probleem mida me lahendame

Eesti äpi kanal töötab autentimisvabalt — see on hea. Aga **silent mode ja Do Not Disturb probleem säilib mõlema ametliku kanali (SMS ja Eesti äpp) puhul** — vähemalt selle kohta, mille me oleme näinud:

**Mida me kontrollisime:** Eesti äpi versioon **1.22.0 (build 384)**, mis tõmbasime Play Store'i mirror'i kaudu mai alguses 2026. Lisaks vaatasime [koodivaramu](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public)'s avaldatud avalikku Flutter source koodi (mille viimane commit on **1. oktoober 2025** — 7 kuud tagasi). Tähelepanu väärib, et Play Store'is on praegu välja antud uuemad versioonid **1.23.0** ja **1.24.0**, mille avalikku lähtekoodi koodivaramus pole; nende uuemate versioonide notification-arhitektuuri me ei ole analüüsinud.

**1.22.0 leiud:**

- **Eesti äpi notification channel** kasutab Android'is vaikimisi `fcm_fallback_notification_channel = "Miscellaneous"` (audio attribute `USAGE_NOTIFICATION_EVENT`) — see ei läbi DND-d ega vaikset režiimi. Manifestis puuduvad `USE_FULL_SCREEN_INTENT`, `ACCESS_NOTIFICATION_POLICY` jt DND-bypass'iks vajalikud load. `flutter_local_notifications` plugin'i pole `pubspec.yaml`-is.
- **iOS Eesti äpi `Runner.entitlements`** ei sisalda `com.apple.developer.usernotifications.critical-alerts` entitlement'it. Seega isegi külaline-kasutaja saab FCM push'i, aga **kui telefon on hääletu või Focus mode'is, ei kuule ta seda**.

See on **täpselt sama probleem** mis SMS'iga: teavitus jõuab seadmesse, aga kasutaja seda ei kuule.

**Kui versioonis 1.23.0 või 1.24.0 olete need parandused juba teinud — palume sellest teada anda.** Sel juhul oleks meie projekt Android'i osas üleliigne ning saaksime keskenduda ainult iOS-le. Aga kuna avalik lähtekood on 7 kuud uuendamata ja avalikud teadaanded sellisest ümbertegemisest puuduvad, eeldame seni vana arhitektuuri jätkumist.

Lisaks: minu enda perekond (tütar Eestis, ema Eestis) ja kolm sõltumatut tunnistajat 3.05 Võrumaa alarmi kohta — nemad **kõik on potentsiaalselt Eesti äpi külalise-kasutajad**, aga ükski neist ei kuule alert'i, kui telefon on öösel hääletu. Sealtsamast SMS'st samade põhjustega: telefon ei möirga.

### Kus võiks Eesti äpp veelgi areneda

Kui teie sisemises plaanis on Eesti äpi edasi-arendamine, palume kaaluda **ohuteavituste eraldi notification channel'i** lisamist — sellise mille atribuudid tagavad, et alert läbib telefoni hääletu režiimi ja DND seaded:

- **Android'is:** uus `NotificationChannel` `USAGE_ALARM` audio-attributes'iga + `enableBypassDnd(true)` + manifestis `ACCESS_NOTIFICATION_POLICY` permissioon. Kasutaja annab Settings'is ühe korra loa, et see kanal võiks DND'd üle hääletada — pärast seda toimib igal vaikse režiimi tasemel.
- **iOS'is:** APNs Critical Alerts entitlement (`com.apple.developer.usernotifications.critical-alerts`), millele Apple annab heakskiidu government / public-safety äppidele tavaliselt 2-4 nädalaga. Eesti äpp on kahtlemata kvalifitseeritud taotleja.

Need on **suhteliselt väikesed kood-muudatused** Eesti äpis (~50 rida Dart + 1 manifestilisand Android'is, 1 entitlement iOS'is), aga muudaksid teie ametliku kanali samaks tasemeks mis cell broadcast saab olema 2027 — möirgavaks isegi hääletu telefoni peal.

Kui Eesti äpp neid ehitaks, **muutuks meie projekt suuresti üleliigseks** ja meil oleks heameel oma projekt sulgeda või panna pausile. Meie eesmärk pole olla teie konkurent — meie eesmärk on, et alert kuulutaks rohkemates telefonides.

### Mida me tahame ehitada

Avatud lähtekoodiga, mittetululine iOS- ja Android-rakendus, mis:

1. **Möirgab läbi vaikse režiimi ja Do Not Disturb** — Android'is `NotificationChannel` `USAGE_ALARM` audio-attributes'iga + `enableBypassDnd(true)` + `ACCESS_NOTIFICATION_POLICY` permissioon. iOS'is APNs Critical Alerts entitlement (`com.apple.developer.usernotifications.critical-alerts`), mille meie taotleme Apple'ilt enne avalikku launch'i. Apple annab seda entitlement'it ainult riigi-tasandi public-safety / health / emergency äppidele — meie taotluse põhjenduseks viitame just käesolevale teie pöördumisele ja Päästeameti enda tunnistusele, et SMS-kanal pole piisav. **Apple'i positiivne vastus on iOS App Store'i lansseerimise eeltingimus.**

2. **Töötab ka välismaal** olevatele eestlastele, kes tahavad olla teadlikud kodumaal toimuvast (mis SMS-süsteemiga pole võimalik, sest SMS jõuab ainult kohaliku raku peale).

3. **Töötab ka ilma internetita — Android'is (~56% Eesti nutitelefoni-kasutajatest, ~740 000 inimest)** — kui kasutaja annab Android'is loa lugeda EE-ALARM saatja SMS'e (`READ_SMS` permission), käivitame seadme alarmi otse SMS'i põhjal, ilma server'iga suhtlemiseta. Vajab Google Play Permissions Declaration Form'i läbimist, mille esitamine eeldab seda, et oleme kvalifitseeritud "safety/emergency tool" — mille tunnistuseks oleks ametlik koostöö Päästeameti või SMIT-iga.

   **iOS-il (~43% Eesti nutitelefoni-kasutajatest, ~570 000 inimest) sama lahendust ei ole praegu võimalik** ehitada — Apple ei eksponeeri ühtegi avalikku API'd, mis lubaks äpil kasutaja SMS'e lugeda (`ILMessageFilterExtension` on sandboxed klassifitseerija, mis ei saa parent-äpiga andmeid jagada ega alarmi käivitada). iOS-kasutajad on seetõttu **interneti-sõltuvad** meie backend-push'i kaudu, kuni Apple omakorda 2027. aastal saabuva Eesti cell broadcast'i ([WEA — Wireless Emergency Alerts](https://support.apple.com/en-us/102516)) natiivselt töödelda saab.

   **Me siiski otsime aktiivselt iOS-lahendusi** — sealhulgas:
   - **Apple Watch standalone watchOS-äpp** (cellular Watch'iga, oma võrgu kaudu) — võiks anda osalise katvuse Watch-kasutajatele;
   - **Lobby Apple'iga** spetsiaalse public-safety partnership entitlement'i jaoks (nt kui Päästeamet teeks Apple'ile co-signed partnership-päringu, oleks meil rohkem kaalu);
   - **Erijuhtumite skeemid** (näiteks Apple Wallet pass'id, geofence-event'id) — uurime, kas mõni neist mehhanismidest saab anda offline-võimaluse.
   
   Hetkel on aus tõdeda: **iOS offline-alarm on lahendamata, ja jääb selliseks kuni 2027 cell broadcast tuleb või Apple oma poliitikat muudab.**

4. **On läbipaistev** — kogu lähtekood avalik GitHub'is, sõnastusega selgelt "MITTEAMETLIK — ametlik kanal on EE-ALARM (1247) ja Päästeameti SMS." Kasutaja teab alati, et ta kasutab kolmanda osapoole teenust, ja et lõpliku otsuse ohu kohta langetab ta riigi ametliku kanali järgi.

5. **On Eesti elanike infoga ettevaatlik** — kasutaja ei pea logima sisse, ei küsi Smart-ID'd, ei kogu PII'd. Maakonna-valik tehakse anonüümselt, andmeid ei müüda.

### Katvuse hinnang

Eesti nutitelefoni-statistika ([StatCounter, aprill 2026](https://gs.statcounter.com/os-market-share/mobile/estonia); [DataReportal Digital 2025 Estonia](https://datareportal.com/reports/digital-2025-estonia)):

| Tase | Eesti kasutajaid | Meie äpp katab |
|---|---|---|
| Nutitelefoniga elanikud kokku (~97% penetratsioon) | ~1 310 000 | — |
| Android (56,5%) | ~740 000 | ✅ Online (USAGE_ALARM) + Offline (READ_SMS) |
| iOS (43,4%) | ~570 000 | ✅ Online (Critical Alerts, kui Apple lubab) — Offline puudub kuni 2027 |

**Kokkuvõttes:**
- **Online tähenduses (telefon võrgus, mis on enamikul ajast)** — meie äpp katab ~100% Eesti nutitelefoni-kasutajatest, **kui** Apple Critical Alerts entitlement'i annab ja **kui** Päästeamet/RIA meiega koostöö-vormis kokkuleppele jõuab.
- **Offline tähenduses (võrk maas, kuid SMS jõuab)** — Android-kasutajad (~740 000 = ~57% Eestist) saavad meie äpi kaudu siiski alarmi vastu, kui READ_SMS permission on antud. iOS-kasutajad jäävad selles olukorras kahjuks katmata, kuni cell broadcast 2027-l käivitub.

iOS'i osakaal on viimase 18 kuuga kasvanud ~36%-lt ~43%-ni ja kasvab jätkuvalt ~1 protsendipunkti kvartalis. Seetõttu on iOS-poole katvus pikaajaliselt eriti oluline — ja just **selle tõttu on Apple Critical Alerts entitlement Apple'ilt meie iOS-strateegia tuum**. Kui Apple ei luba, jääb Eesti iOS-osa täielikult katmata kuni 2027.

### Mida me oleme tehniliselt avastanud

Eesti äpi **avalikust Flutter source koodist** ([koodivaramu.eesti.ee/eesti.app/app-frontend-public](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public), mille RIA ise on avalikult kättesaadavaks teinud) leidsime järgmist:

1. Failis [`lib/services/api/sitrep_service.dart`](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public/-/raw/main/lib/services/api/sitrep_service.dart) on selgesõnaliselt kirjas endpoint:
   ```dart
   final data = await _httpService.get('/api/sitrep/v1/full-events');
   ```
2. Host nimi `api.app.eesti.ee` järgib levinud subdomeini-konventsiooni (kui rakendus elab `app.eesti.ee`'s, siis selle API tavaliselt `api.app.eesti.ee`'s) ja on lihtsalt veebibrauseris kontrollitav.

Kontrollisime endpoint'i avalikkust standardse `curl`-i abil:

- `GET https://api.app.eesti.ee/api/sitrep/v1/full-events` vastab **HTTP 200** ilma autentimiseta.
- Vastus on JSON, mis sisaldab 10 viimast SITREP event'i koos täieliku ET/EN/RU sisuga, GeoJSON polügoonidega ja alert state-tega.
- Latentsus on tegelik ~0 sekundit alarmi väljastamise hetkega, sest see on sama backend mis toimetab teavitusi Eesti äpi FCM topic'utele.

**Oluline tehniline täheldus:** see endpoint näib kandvat **ainult pikemalt aktiivseid suuremaid event'e** — näiteks 25.03 ja 31.03 nationwide/multi-region droonihäired on olemas, kuid 3.05 üksiku-maakonna (Võrumaa) lühikest häiret seal **ei ole**. Empiirika põhjal kannab see endpoint hinnanguliselt **~80%** EE-ALARM aktivatsioonidest; regionaalsed lühikesed alert'id (alla 2 tunni, üksik maakond) jäävad katmata. Selle põhjuse kinnitamine on üks taotluse eesmärke (vt **Taotlus 1**).

Selle empirika kontrollimiseks jookseb meil taustal Cloudflare Worker, mis pollib seda endpoint'i iga minut (Cloudflare cron'i miinimum) ja kogub andmeid avalikku andmebaasi. Worker'i lähtekood ja kogutud andmed on **täielikult avalikud** GitHub-is: [github.com/marttirandma/droonialarm](https://github.com/marttirandma/droonialarm) ja dashboard'i URL: [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev). Plaan on järgmiste nädalate jooksul mõõta:
- mitmel protsendil aktiivsetest EE-ALARM aktivatsioonidest see API kannab event'i,
- millal ja kui kaua need püsivad,
- kas regionaalsetel on EHAK koodid külge.

**Õiguslikust korrektsusest:** kogu meie tehniline analüüs põhineb (a) RIA enda avaldatud avalikul lähtekoodil ja (b) avalikul HTTPS endpoint'il, mis vastab autentimist mitte nõudvatele päringutele. Me ei ole läbinud ühtegi turvameedet ega autentimissüsteemi (KarS § 217 mõistes). Eesti äpi APK on avalikult Google Play'st saadav ning ühilduvuse tagamise eesmärgil dekompileerimine on lubatud Autoriõiguse seaduse § 25 alusel — meie tegevus jääb selle ulatusse.

### Mida me palume

Pöördume teie poole **koostöö-soovi** vaimus. Pakume välja mõned tehnilised võimalused — täpse kuju ja sobivuse otsustate teie. Kui mõni neist sobib, oleme valmis kohanduma teie tingimustele. Kui ükski neist ei sobi täpselt nii, kuid teil on muu nägemus kuidas me saaksime sama eesmärki — Eesti elanike paremat ohuteavitust — saavutada, oleme avatud arutelule.

**Võimalus 1 — avaliku SITREP feed'i kinnitus:** kas saaksite kinnitada, et `https://api.app.eesti.ee/api/sitrep/v1/full-events` on avalikuks kasutuseks mõeldud, ja kuidas see endpoint event'e valib (mis kriteeriumi alusel jäävad regionaalsed lühikesed alert'id sealt välja)? Kas pikemas perspektiivis oleks võimalik laiendada selle feed'i sisu nii, et see kataks ka regionaalseid alert'e? Selline kinnitus annaks meile (ja igale teisele potentsiaalsele kolmandale osapoolele) tehnilise selguse.

**Võimalus 2 — API dokumentatsioon:** kas saaksite jagada SITREP avaliku API (`/api/sitrep/v1/*` ja `/api/notification/v1/*`) OpenAPI / Swagger dokumentatsiooni? See aitaks meil olla teie tehniliste muudatustega hästi sünkroonis ja vältida juhuslikku ühilduvuse-vigu.

**Võimalus 3 — ametlik koostöölepe:** kui te peate seda mõistlikuks, oleme valmis sõlmima ametliku koostöölepe Päästeametiga, milles me kohustuksime:
- järgima teie kommunikatsioonipoliitikat (meie äpp kuvab alati ametliku 1247-numbri ja kriis.ee viite; ei lisa alert'idele omapoolset tõlgendust, vaid kuvab teie teksti muutmata kujul);
- mitte koguma kasutajaandmeid kommertsteenuste eesmärgil;
- jagama latentsus- ja kättetoimetatavus-statistikat teie tagasiside-võimalustena;
- järgima teie alert'i-eemaldamise / täpsustamise korraldusi viivitamata.

Selline kokkulepe võiks olla ka aluseks Google Play Permissions Declaration Form'is "safety/emergency tool" tunnistuse hankimisele.

**Võimalus 4 — Eesti äpi notification channel'i tugevdamine (eelistatud lõpplahendus):** kui see oleks teie sisemise arendusplaani osaks, palume tõsiselt kaaluda **eraldi `USAGE_ALARM` notification channel'i lisamist Eesti äpi Android'i versioonile** ja **APNs Critical Alerts entitlement'i taotlemist Apple'ilt** Eesti äpi iOS'i versiooni jaoks. See lahendaks ülal kirjeldatud silent-mode/DND probleemi **ilma, et oleks vaja kolmandaid osapooli**. Eesti äpp on Eesti riigi ametlik äpp ja kahtlemata kvalifitseeritud Apple'i Critical Alerts entitlement'i jaoks. Kui Eesti äpp seda ehitaks, **oleksime rõõmsad oma projekti sulgema** — meie eesmärk on lahendus, mitte oma kasutajaskond.

Kui teil on **muud nägemus** — näiteks oma plaan kolmandate osapoolte API-tarbimise kohta, või soov et me lihtsalt ootaks 2027 cell broadcast'i välja — andke palun teada. Eesmärk on **ühine** lahendus, mille teie peate tehniliselt ja kommunikatsioonipoliitiliselt vastuvõetavaks.

### Õiguslik alus

Avaliku teabe seaduse § 6 lg 1 alusel on iga isik kohustatud avaldama temale kuuluvat teavet. § 14 lg 1 alusel võin esitada teabenõude. SITREP-i sisaldab avalikku ohuteavitust, mille avalikkusele edastamine on Päästeameti otsene seadusest tulenev kohustus (Pääste­seadus § 5). Meie taotleme **mitte konfidentsiaalse infoanalüüsi**, vaid **lihtsalt sama avalikku alert-sisu reaalajas-jagamise lepingulist viisi**.

### Lubadus

Meie projekt on:
- **avatud lähtekoodiga** (MIT või sarnane litsents) — kogu kood avalik GitHub'is
- **mittetululine** — me ei kavatse ega luba äpi monetiseerimist
- **läbipaistev** — kõik andmed mis me kogume on avalikult dokumenteeritud
- **disclaimer'iga** — iga kasutaja näeb selgelt, et meie äpp **EI ASENDA** ametlikku EE-ALARM kanalit, vaid täiendab seda eksperimentaalse re-broadcast'iga

Eesti elanike ohutus on prioriteet ja oleme valmis kohanduma teie tehniliste või kommunikatsioonipoliitiliste nõudmistega.

### Vastuse ootus

Avaliku teabe seaduse § 18 lg 1 alusel ootame vastust 5 tööpäeva jooksul (kui pikenemine on vajalik, palun teavitada § 18 lg 2 alusel).

Lugupidamisega,

**Martti Randma**
randma.martti@gmail.com
+372 5539649
GitHub: [github.com/marttirandma/droonialarm](https://github.com/marttirandma/droonialarm)

---

### Lisad

- **Tehniline lisa A:** SITREP API uuringu Cloudflare Worker'i tulemused (URL antakse vastusele): polling-andmed mis näitavad mida endpoint reaalajas tagastab.
- **Tehniline lisa B:** Eesti äpi APK reverse-engineering tulemused, mis tõestavad, et `api.app.eesti.ee` endpoint on autentimist mitte nõudev.
- **Tehniline lisa C:** võrdlus Soome (Yle), Saksamaa (NINA/MoWaS), Rootsi (VMA), USA (WEA) süsteemidega — kõik need eksponeerivad reaalajas-feed'i kolmanda osapoole arendajatele.
