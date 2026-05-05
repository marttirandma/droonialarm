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
| Riigi Infosüsteemi Amet RIA (peadirektor Joonas Heiter) | ria@ria.ee |
| Siseministeeriumi infotehnoloogia- ja arenduskeskus SMIT (peadirektor Kirke Saar) | smit@smit.ee |
| Häirekeskus (1247) | hairekeskus@112.ee |

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
| Riigikantselei valitsuse kommunikatsioonibüroo | strateegiline-kommunikatsioon@riigikantselei.ee |
| Riigikogu Riigikaitsekomisjon | riigikaitsekomisjon@riigikogu.ee |
| Riigikogu Põhiseaduskomisjon | pohiseaduskomisjon@riigikogu.ee |

---

## Lugupeetud adressaadid

Kirjutan teile ühe konkreetse avaliku ohutuse probleemi pärast, mille olen viimaste nädalate jooksul mitmest sõltumatust allikast kuulnud — sealhulgas oma perekonnast — ja mille tehnilist lahendamist tahan ette pakkuda.

### Probleem

EE-ALARM süsteem saadab praegu droonihäireid ja teisi hädaolukorra teavitusi **location-based SMS**'ide kaudu. Selle tehnoloogilise valiku puudus on, et **SMS ei läbi telefoni vaikset režiimi ega Do Not Disturb seadet** — telefon teeb tavalise (kui üldse) teavitusheli, mis ei ärata magajat ja jääb tavaliselt märkamata.

Olen ise praegu Balil, **mu tütar elab Eestis**. Pärast 25. märtsi Auvere droonirünnakut ja 31. märtsi üleriigilist häiret, ning eriti pärast 3. mai pühapäeva-varahommikust Võrumaa droonihäiret (03:23-05:30 EET), on vähemalt **kolm sõltumatut inimest minuga ühendust võtnud**, kes olid kohapeal aga **ei kuulnud SMS-i** — telefon oli vaiksel režiimil. Samuti on minu enda ema Eestis öelnud, et ei kuule neid teavitusi öösel.

Päästeamet on ise [avalikult tunnistanud](https://news.err.ee/1609984362/estonia-to-introduce-cell-broadcast-emergency-alert-system-in-2027), et 3-5% õppuse Siil 2025 ajal ei saanud SMS'i üldse, ja et SMS-süsteem on "liiga aeglane ja ebausaldusväärne". Cell broadcast'i hange (€3,7M) on käimas, operatiivne 2027. Kuni selle ajani jääb avalik kasutaja **ebausaldusväärse kanali** kätte vahele.

### Eraldi probleem: Eesti äpi sisselogimise-barjäär

Olen näinud, et üks võimalik vastuargument oleks: "kasutage Eesti äppi". Tahan juba ette välja tuua, miks see ei ole hädaolukorra-teavituste jaoks piisav lahendus, ning miks loodame, et te seda ka oma sisemises arutelus arvestate:

**1. Mul isiklikult ei ole võimalust Eesti äppi kasutada.** Mul ei ole hetkel ei Mobiil-ID'd, Smart-ID'd, ega Eesti ID-kaardi lugemisseadmega arvutit. Olen püsivalt välismaal, kus e-residentsuse-väliste lahenduste kasutuselevõtt pole praktiline. Eesti äpp nõuab autentimist nende meetodite kaudu — ja seetõttu ei avane mulle isegi see kanal, mille olemasolu te võiksite pakkuda lahendusena.

**2. See pole minu individuaalne probleem.** Sama olukorras on:
- **Lapsed ja noored alla 15-aastased**, kellel pole veel täisealist isikukoodi-põhist e-ID-d (nt minu tütar Eestis);
- **Eakad inimesed**, kes pole kunagi e-ID kasutamist omandanud (nt minu enda ema);
- **Välismaalt naasevad eestlased**, kelle Mobiil-ID on aegunud või kes ootavad uut SIM-kaarti;
- **Püsivad välismaal elavad eestlased**, kellel on huvi kodumaa hädaolukordade vastu (perekond, sõbrad, vara);
- **Eestis viibivad turistid, ajutised töötajad ja külalised**, kellel pole Eesti e-ID-d aga kes peavad samuti hädaolukorra teate vastu võtma.

Kõik need rühmad on seaduslikult Eesti raku all SMS-i saamiseks õigustatud, kuid jäävad Eesti äpi-põhise lahenduse väliste hulka.

**3. Hädaolukorra teavituse fundamentaalne loogika eeldab maksimaalset katvust ilma takistusteta.** Kui sireenid alla kärisevad, nad ei küsi kelleltki kes kuuleb. Kui SMS läheb, see läheb igale telefonile selles raku piirkonnas, sõltumata kasutaja identiteedist. EU Cell Broadcast standard (millele Eesti aastaks 2027 üle läheb) töötab samal põhimõttel: alert jõuab igale seadmele, mis on hetkel selle raku all, ilma et oleks vaja sisse logida.

**Hädaolukorra teavitus ei tohiks kunagi olla autentimise taga.** Eesmärk on **elusid päästa**, mitte konkreetset äppi turundada või kasutajaid mõnda riigi-portaali registreerida.

**4. Me palume kaaluda:** kui teie sisemises plaanis on Eesti äpi edasi-arendamine ohuteavituste paremaks saatmiseks, palun mõelge, et **see kanal — vähemalt ohuteavituste osas — võiks töötada ilma sisselogimiseta.** Eesti äpi muu funktsionaalsus (e-ID dokumendid, terviseandmed, jne) võib jääda autentimise taha — see on loomulik. Aga `/api/sitrep/v1/full-events` ja sellele tulevad alert'id peaksid olema kättesaadavad **igale seadmele, mis äpi paigaldab**, sõltumata kasutaja sisselogimise-staatusest.

Kui see oleks juba olemas, ei oleks kolmandate osapoolte projekte nagu meie oma vajalik. Aga praegu — ja võibolla pikas perspektiivis ka — on alternatiivse, autentimisvaba kanaliga kolmandate osapoolte rakendused **vajalik täiendus**, mitte konkureeriv lahendus.

### Mida me tahame ehitada

Avatud lähtekoodiga, mittetululine iOS- ja Android-rakendus, mis:

1. **Möirgab läbi vaikse režiimi ja Do Not Disturb** — Android'is `NotificationChannel` `USAGE_ALARM` audio-attributes'iga + `enableBypassDnd(true)` + `ACCESS_NOTIFICATION_POLICY` permissioon. iOS'is APNs Critical Alerts entitlement (`com.apple.developer.usernotifications.critical-alerts`), mille meie taotleme Apple'ilt enne avalikku launch'i. Apple annab seda entitlement'it ainult riigi-tasandi public-safety / health / emergency äppidele — meie taotluse põhjenduseks viitame just käesolevale teie pöördumisele ja Päästeameti enda tunnistusele, et SMS-kanal pole piisav. **Apple'i positiivne vastus on iOS App Store'i lansseerimise eeltingimus.**

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

**Võimalus 4 — Eesti äpis sisselogimisvaba alert-režiim:** kui te peate seda mõistlikuks oma sisemise arendusplaani osaks, palume kaaluda et Eesti äpis hädaolukorra teavitused (SITREP feed) töötaks **ka ilma kasutaja sisselogimiseta**. Eesti äpi muu funktsionaalsus võib jääda Mobiil-ID / Smart-ID taha — see on loomulik. Aga ohuteavituste osa võiks olla **vaikimisi sisse lülitatud iga äpi paigaldaja jaoks**, sõltumata e-ID-st. Selline lahendus kataks ka eelmainitud rühmad (lapsed, eakad, välismaalased, turistid) ja muudaks meie kolmandate osapoolte projekti suuremas osas üleliigseks. Kui te seda lahendust eelistate, oleme **rõõmsad oma projekti pausile panema või sulgema**, sest meie eesmärk pole olla Eesti äpi konkurent — meie eesmärk on, et alert jõuaks rohkemate inimesteni.

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
[telefon]
[GitHub: github.com/marttirandma/droonialarm — projekti repo]

---

### Lisad

- **Tehniline lisa A:** SITREP API uuringu Cloudflare Worker'i tulemused (URL antakse vastusele): polling-andmed mis näitavad mida endpoint reaalajas tagastab.
- **Tehniline lisa B:** Eesti äpi APK reverse-engineering tulemused, mis tõestavad, et `api.app.eesti.ee` endpoint on autentimist mitte nõudev.
- **Tehniline lisa C:** võrdlus Soome (Yle), Saksamaa (NINA/MoWaS), Rootsi (VMA), USA (WEA) süsteemidega — kõik need eksponeerivad reaalajas-feed'i kolmanda osapoole arendajatele.
