# Contributing to Droonialarm

Tere — kui soovite kaasa lüüa, oleme tänulikud iga panuse eest.

## Põhimõtted

1. **Kasutaja ohutus on alati prioriteet.** Iga muudatus, mis võib mõjutada alert-kättetoimetatavuse, vajab eraldi inspekteerimist.
2. **Avatud lähtekood ja avalik andmestik.** Kui saate ligipääsu mõnele andmestikule, mida teised ei näe, palun avalikustage.
3. **Mitteametlik staatus säilib.** Kõik UI-tekstid peavad selgitama, et see app on **MITTEAMETLIK** ja et ametlik kanal on EE-ALARM (1247).
4. **Privaatsus by design.** Iga uue funktsioonidisaini juures küsige: "kas see kogub mõne andme mida varem ei kogunud?"

## Kuidas alustada

### Logger
```bash
cd logger
npm install
npm run dev   # local development
```

### Backend
```bash
cd backend
go mod download
go run .
```

### Flutter app
```bash
cd app
flutter pub get
flutter run -d <android_emulator|ios_simulator>
```

## Branch strategy

- `main` — alati deploy'imisvõimas
- `dev/<feature>` — feature-arendus
- Pull request avate `dev/X` → `main` peale code review't

## Code style

- **Go:** `gofmt`, `go vet`, `golangci-lint run`
- **TypeScript / Worker:** Prettier vaikimisi
- **Dart / Flutter:** `dart format` + `dart analyze`
- **Eesti keele tekstid UI-s:** kontrollime üle õigekirja kontrolliga (Filosoft sõnastikuga)

## Pull request'i template

Iga PR peab kirjeldama:
1. **Mida muudab** — lühike kokkuvõte
2. **Miks** — millist probleemi lahendab
3. **Kuidas testitud** — käsitsi testimine, automaattestid, telefoni-test
4. **Mõju kasutajale** — kas alert-kättetoimetatavus muutub kuidagi?
5. **Privacy review** — kas kogume mõne uue andme tüübi?

## Testing

Eriti tähtis on testida:
- DND-bypass tegelikult töötab (Android USAGE_ALARM, iOS CallKit) — vajab füüsilist seadet
- False-positive määr — me ei tohi alert'ida tavapärase Päästeameti uudise peale (nt "Sireeni-test toimub kell 12.00"). Kasutage logger'i andmetest reaal-juhtumeid testimiseks.
- Latentsus — keskmine kättetoimetamise aeg poll'ist push'ini < 5s

## Issue'ide märgendid

- `bug` — toimib teisiti kui ootame
- `feature` — uus funktsioon
- `safety` — võib mõjutada alert-kättetoimetatavuse
- `privacy` — PII / andmete kogumise küsimus
- `phase-1.0` / `phase-1.1` / `phase-2` — millise faasi osa
- `paasteamet` — vajab Päästeameti / SMIT / RIA tähelepanu
- `good-first-issue` — sobib uuele kontributor'ile

## Käitumisreeglid

[Code of Conduct](CODE_OF_CONDUCT.md) — Contributor Covenant 2.1 alusel.

## Litsents

Iga panus avaldatakse [MIT License](LICENSE) all.
