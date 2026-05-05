# Reverse engineering tulemused — Eesti äpp ja Ole valmis äpp

**Eesmärk:** kontrollida, kas Eesti riigi praegused ametlikud äpid (`ee.ria.eesti.app` ja `ee.naiskodukaitse.olevalmis`) suudavad alertida läbi telefoni vaikse režiimi ja Do Not Disturb seade. Selle põhjal otsustada, kas lahendus juba eksisteerib või on vaja kolmandat osapoolt.

**Tulemus:** **Kumbki ametlik äpp ei suuda hääletu režiimi läbida.**

**Reprodutseerimine:** APK-d, decompiled puu ja libapp.so binaarid on `.gitignore`'is — repos neid pole, sest tegu on Eesti äpi ja Ole valmis äpi avalike artifaktidega, mille iga huviline saab APKCombo / APKPure / APKMirror'ist ise tõmmata ja meie tulemusi reprodutseerida [Reproduktsiooni-juhiste järgi](#4-reproduktsiooni-juhised).

---

## 1. Eesti äpp v1.22.0 — analüüs

**Allikas:** APKCombo, build 384, paigaldatud 4. mai 2026.
**APK SHA-256:** `55390e57b83417ed07e36a304af48102cc5802be18659dfc0b7b406f01778501`

### Permissioonid (manifestist)

✅ Olemas:
- `POST_NOTIFICATIONS` (Android 13+ basic notification permission)
- `WAKE_LOCK`
- `c2dm.permission.RECEIVE` (FCM)

❌ **PUUDU — kõik DND-bypass'iks vajalikud:**
- `USE_FULL_SCREEN_INTENT`
- `SCHEDULE_EXACT_ALARM`
- `ACCESS_NOTIFICATION_POLICY` (DND-override õigus)
- `FOREGROUND_SERVICE`
- `RECEIVE_BOOT_COMPLETED`

Manifest target SDK: 36 (Android 16) — kaasaegne.

### Plugin'id (Flutter)

```
firebase_core
firebase_messaging
```

❌ **PUUDU:** `flutter_local_notifications` — see on plugin, mis on vajalik custom `NotificationChannel`'i loomiseks `USAGE_ALARM` audio attributes'iga.

### Notification channel

```kotlin
// strings.xml
<string name="fcm_fallback_notification_channel_label">Miscellaneous</string>
```

Ainult vaike-FCM `fcm_fallback_notification_channel` (madal prioriteet, USAGE_NOTIFICATION_EVENT, ei läbi DND'd).

Mitte ühtegi custom-kanalit, ei `setUsage(USAGE_ALARM)`'it ega `enableBypassDnd(true)`'d kuskil app-koodis.

### Sisu

- `res/raw/` puudub täielikult — null heli-faili
- Stringides null mainimist: drone, drooni, EE-ALARM, ohuteavitus, õhuhäire, kärje, hädaolukord, siren, alarm

### iOS pool

iOS `Runner.entitlements` (vt avalikust source'ist):
- ❌ **Puudub** `com.apple.developer.usernotifications.critical-alerts`
- ❌ **Puudub** `time-sensitive-notifications`

### Järeldus

Eesti äpp **ei ole disainitud** alarmi-stiilis teavitama. See on tavaline notification-äpp, mille push'id käituvad nagu kõik teised teavitused: kui telefon on hääletu, on ka teavitus hääletu.

---

## 2. Ole valmis! v3.0.1 — analüüs

**Allikas:** APKCombo, paigaldatud 4. mai 2026.
**APK SHA-256:** `0d9d51ad95736cf2c06303712efdb2cc1090677fd403c5f51f49be712ff44ae6`
**Publisher:** Naiskodukaitse (mitte Päästeamet, mu varasem oletus oli vale)

### Tehnoloogia

Cordova + Ionic Angular hybrid app. `targetSdkVersion=31` (Android 12) — vananenud, ei targeti Android 13+.

### Permissioonid

❌ **PUUDU samad kui Eesti äpil**: `USE_FULL_SCREEN_INTENT`, `SCHEDULE_EXACT_ALARM`, `ACCESS_NOTIFICATION_POLICY`. WAKE_LOCK ja FOREGROUND_SERVICE on olemas, aga ainult marianhello/bgloc background location plugin'i jaoks (asukohaseire), mitte alertimiseks.

### Plugin'id

```
cordova-plugin-fcm-with-dependecy-updated 7.8.0
cordova-plugin-firebasex 14.2.1
cordova-background-geolocation-plugin 2.0.7
```

### Notification channel

`org/apache/cordova/firebase/FirebasePlugin.java:332-403` (cordova-plugin-firebasex 14.2.1, decompileerituna) loob Default kanali järgmiste vaikeväärtustega:

- `importance=4` (HIGH) ✅
- **`usage=6`** (`USAGE_NOTIFICATION_EVENT`) ❌ — peab olema `4` (`USAGE_ALARM`) DND-bypass'iks
- `sound="default"` (RingtoneManager.TYPE_NOTIFICATION) ❌ — peab olema custom alarm

### Rakenduse enda kood

`main.js` (kogu Ionic bundle):
- **Üks** kõne: `fcm.subscribeToTopic('notifications')`
- Null kõnet `createChannel`'le custom konfiguratsiooniga
- Null hädaolukorra-spetsiifilist kanalit

### Järeldus

**Ole valmis pole alerting-kanal — see on staatiline juhend** (kontroll-listid, peatükid, kursused) väikeste FCM-broadcastidega ühel topicul. Kui telefon hääletu, jääb teavitus hääletuks.

---

## 3. Eesti äpi push-rada — täielik analüüs

Avalikust Flutter source'ist [`push_notifications_service.dart`](https://koodivaramu.eesti.ee/eesti.app/app-frontend-public/-/raw/main/lib/services/push_notifications_service.dart) lugemise tulemus:

```
[1] Alert SITREP backendis (Päästeamet)
       ↓
[2] Backend saadab FCM push'i topic'utele:
    - üleriigiline (ee-all-et / ee-all-en / ee-all-ru)
    - maakond-spetsiifiline (EHAK koodi alusel)
       ↓
[3] FCM toimetab subscribereiеthele
       ↓
[4] Eesti äpp võtab vastu — JA SISU ON KOHE PAYLOAD'IS:
    data['title']                    täielik EE tekst
    data['body']                     täielik kehad
    data['location.county']          "Võrumaa"
    data['location.settlementUnits'] EHAK nimed
       ↓
[5] Süsteem näitab teavitust (vaike-kanali peal)
```

**Kriitiline avastus:** `_parsePushNotification` ei tee mingit follow-up API kõnet. Kogu sisu tuleb FCM payload'iga. **Kui sa missisid push'i, pole ühtegi rada hiljem kätte saamiseks.**

`/api/sitrep/v1/full-events` on **AINULT in-app "ohuteavituste loend"** vaade, mitte reaalajas-kohaletoimetamise tee. Filter: `endDate > now` — seetõttu lühikesed regionaalsed alert'id (nagu 3.05 Võru) **kaovad sealt** kui nende endDate on möödunud.

---

## 4. Reproduktsiooni-juhised

Et Päästeamet/SMIT/RIA või sõltumatu auditeerija saaks meie tulemused üle kontrollida:

### Eesti äpi APK tõmbamine ja decompile

```bash
mkdir -p research/eestiapp && cd research/eestiapp

# Paigalda jadx
brew install jadx

# Lae alla XAPK avalikust mirror'ist (APKCombo, APKPure jne)
# Palun teha käsitsi brauseris — APK mirror'id ei luba head'ess curl'i
# Salvesta failina: eestiapp-1.22.0.xapk

# Verify hash
shasum -a 256 eestiapp-1.22.0.xapk
# Expected: 55390e57b83417ed07e36a304af48102cc5802be18659dfc0b7b406f01778501

# Extract base.apk and arm64 split
unzip -o eestiapp-1.22.0.xapk ee.ria.eesti.app.apk config.arm64_v8a.apk

# Decompile
jadx -d decompiled --no-debug-info ee.ria.eesti.app.apk

# Inspect
cat decompiled/resources/AndroidManifest.xml | grep "uses-permission"
grep -rE "USE_FULL_SCREEN_INTENT|USAGE_ALARM|enableBypassDnd" decompiled/sources/

# Native Flutter binary strings
unzip -o config.arm64_v8a.apk lib/arm64-v8a/libapp.so
strings lib/arm64-v8a/libapp.so | grep -E "/api/" | sort -u
```

Tulemus peab vastama selle dokumendi väidetele.

### Ole valmis APK

Sama protsess. Hash: `0d9d51ad95736cf2c06303712efdb2cc1090677fd403c5f51f49be712ff44ae6`.

### Cloudflare Worker logger

Vt [`logger/README.md`](../logger/README.md). Live: [droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev](https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev).

---

## 5. Mida see kõik kokku tähendab

1. **Praegu ükski Eesti riigi äpp** ei suuda telefoni hääletust režiimist välja tuua hädaolukorra teavituse jaoks
2. **Tehniliselt on see VÄGA lihtsalt teostatav** — Eesti äpil tuleks lisada üks notification channel `USAGE_ALARM`'iga, üks `enableBypassDnd(true)` kõne, üks `ACCESS_NOTIFICATION_POLICY` permissioon, ja taotleda iOS Critical Alerts entitlement (Apple annab seda government-issuer'idele kahe nädalaga)
3. **Põhiline takistus on poliitiline / kommunikatsioonipoliitiline**, mitte tehniline
4. **Vahepeal vajame kolmandat osapoolt**, kes need lihtsad sammud astub. See projekt on selleks.
