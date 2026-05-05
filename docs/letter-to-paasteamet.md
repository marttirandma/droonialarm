# Pöördumine: avalik EE-ALARM teavituste reaalajas-kanali loomine kolmanda osapoole hädaabi-äpi tarbeks

**Adressaat:** Päästeamet (info@rescue.ee), Riigi Infosüsteemi Amet (info@ria.ee), Siseministeeriumi infotehnoloogia- ja arenduskeskus (smit@smit.ee)

**Saatja:** Martti Randma, randma.martti@gmail.com
**Kuupäev:** 4. mai 2026
**Õiguslik alus:** Avaliku teabe seadus § 6 lg 1 ja § 14 lg 1

---

## Lugupeetud Päästeameti, RIA ja SMIT esindajad

Kirjutan teile ühe konkreetse avaliku ohutuse probleemi pärast, mille olen viimaste nädalate jooksul mitmest sõltumatust allikast kuulnud — sealhulgas oma perekonnast — ja mille tehnilist lahendamist tahan ette pakkuda.

### Probleem

EE-ALARM süsteem saadab praegu droonihäireid ja teisi hädaolukorra teavitusi **location-based SMS**'ide kaudu. Selle tehnoloogilise valiku puudus on, et **SMS ei läbi telefoni vaikset režiimi ega Do Not Disturb seadet** — telefon teeb tavalise (kui üldse) teavitusheli, mis ei ärata magajat ja jääb tavaliselt märkamata.

Olen ise praegu Balil, **mu tütar elab Eestis**. Pärast 25. märtsi Auvere droonirünnakut ja 31. märtsi üleriigilist häiret, ning eriti pärast 3. mai pühapäeva-varahommikust Võrumaa droonihäiret (03:23-05:30 EET), on vähemalt **kolm sõltumatut inimest minuga ühendust võtnud**, kes olid kohapeal aga **ei kuulnud SMS-i** — telefon oli vaiksel režiimil. Samuti on minu enda ema Eestis öelnud, et ei kuule neid teavitusi öösel.

Päästeamet on ise [avalikult tunnistanud](https://news.err.ee/1609984362/estonia-to-introduce-cell-broadcast-emergency-alert-system-in-2027), et 3-5% õppuse Siil 2025 ajal ei saanud SMS'i üldse, ja et SMS-süsteem on "liiga aeglane ja ebausaldusväärne". Cell broadcast'i hange (€3,7M) on käimas, operatiivne 2027. Kuni selle ajani jääb avalik kasutaja **ebausaldusväärse kanali** kätte vahele.

### Mida me tahame ehitada

Avatud lähtekoodiga, mittetululine iOS- ja Android-rakendus, mis:

1. **Möirgab läbi vaikse režiimi ja DND** — Android'is `USAGE_ALARM` audio-attributes'i ja `enableBypassDnd(true)` peal, iOS'is APNs Critical Alerts entitlement'i (mille me Apple'ilt taotleksime) või vahe-lahendusena CallKit "sissetuleva kõne" UI peal, mis süsteemiringtone mängib läbi vaikse režiimi.

2. **Töötab ka välismaal** olevatele eestlastele, kes tahavad olla teadlikud kodumaal toimuvast (mis SMS-süsteemiga pole võimalik, sest SMS jõuab ainult kohaliku raku peale).

3. **Töötab ka ilma internetita** — kui kasutaja annab Android'is loa lugeda EE-ALARM saatja SMS'e, käivitame seadme alarmi otse SMS'i põhjal, ilma server'iga suhtlemiseta. Vajab Google Play Permissions Declaration Form'i läbimist, mille esitamine eeldab seda, et oleme kvalifitseeritud "safety/emergency tool" — mille tunnistuseks oleks ametlik koostöö Päästeameti või SMIT-iga.

4. **On läbipaistev** — kogu lähtekood avalik GitHub'is, sõnastusega selgelt "MITTEAMETLIK — ametlik kanal on EE-ALARM (1247) ja Päästeameti SMS." Kasutaja teab alati, et ta kasutab kolmanda osapoole teenust, ja et lõpliku otsuse ohu kohta langetab ta riigi ametliku kanali järgi.

5. **On Eesti elanike infoga ettevaatlik** — kasutaja ei pea logima sisse, ei küsi Smart-ID'd, ei kogu PII'd. Maakonna-valik tehakse anonüümselt, andmeid ei müüda.

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

### Konkreetsed taotlused

Esitan tehnilisi võimalusi, mille mõni rahuldaks meie eesmärki — palun valida sobivaim, või öelda kui ükski ei sobi, et saaksime AvTS § 14 alusel täpsustada:

**Taotlus 1 (kõige lihtsam — eelistatav):** **Kinnitage, et `https://api.app.eesti.ee/api/sitrep/v1/full-events` on avalikuks kasutuseks mõeldud**, ja palun selgitage milline filter sellele rakendub (miks regionaalsed lühikesed alert'id sealt välja jäävad). Kas saaksime saada **kõikide** EE-ALARM aktivatsioonide reaalajas-feed'i (kvoot- ja rate-limit-piirangutega, mis teile sobib)?

**Taotlus 2:** **API spetsifikatsioon** — kas saaksime saada SITREP avaliku API (`/api/sitrep/v1/*` ja `/api/notification/v1/*`) OpenAPI / Swagger dokumentatsiooni? Praegu saame seda ainult libapp.so'st reverse-engineerida.

**Taotlus 3:** **Firebase Cloud Messaging topic'utele juurdepääs** — kas saaksite kaaluda, et lisate meie äpi (`ee.droonialarm` package) **lugemis-õigusega** RIA Firebase projekti FCM topic'utele (näiteks `prod-0086-et` Võru jne)? See võimaldaks meil otse vastu võtta sama push'i mis Eesti äpp saab, ilma Päästeameti backend'i kunagi ühenduma. Lugemis-juurdepääs ei anna meile õigust topic'utele midagi avaldada.

**Taotlus 4:** **Ametlik koostöölepe / partnership** — kui ülaltoodud tehnilised valikud ei sobi, oleme valmis sõlmima ametliku koostöölepe Päästeametiga, kus me kohustuksime:
- järgima Päästeameti kommunikatsioonipoliitikat (näiteks: meie äpp kuvab alati ametliku 1247-numbri ja kriis.ee viite; ei vahenda ühegi alert'i kohta omapoolset arvamust, ainult kuvab Päästeameti teksti)
- mitte koguma kasutajaandmeid kommertsteenuste eesmärgil
- viivitamata käsitlema alert'isuhinguid mis võivad tekitada paanika
- jagama oma latentsus- ja kättetoimetatavus-statistikat Päästeameti tagasiside-võimalustena

Sellise lepingu alusel oleks ka Google Play Permissions Declaration Form'i jaoks vajaliku "safety/emergency tool" tunnistuse hankimine kergem.

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
[telefon]
[GitHub: github.com/marttirandma/droonialarm — projekti repo]

---

### Lisad

- **Tehniline lisa A:** SITREP API uuringu Cloudflare Worker'i tulemused (URL antakse vastusele): polling-andmed mis näitavad mida endpoint reaalajas tagastab.
- **Tehniline lisa B:** Eesti äpi APK reverse-engineering tulemused, mis tõestavad, et `api.app.eesti.ee` endpoint on autentimist mitte nõudev.
- **Tehniline lisa C:** võrdlus Soome (Yle), Saksamaa (NINA/MoWaS), Rootsi (VMA), USA (WEA) süsteemidega — kõik need eksponeerivad reaalajas-feed'i kolmanda osapoole arendajatele.
