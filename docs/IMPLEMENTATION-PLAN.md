# Toteutussuunnitelma — pwa-oura MVP

> Viimeksi päivitetty: 2026-07-20

Tämä dokumentti kuvaa MVP:n toteutusjärjestyksen, riippuvuudet ja hyväksymiskriteerit. Issut on järjestetty viiteen milestooneen kriittisen polun mukaan.

---

## Kriittinen polku

```
M0 (Infra/Auth)
  #32 Firebase + GCP setup
    └─► #29 Cloud Run (oura-ingest + oura-graphql)
          └─► #28 Auth: Google SSO + Oura OAuth
                └─► #18 PWA GH Pages -konfiguraatio
                      └─► #31 CI/CD GitHub Actions

M1 (Data pipeline) — rinnakkain M0:n kanssa
  #23 Firestore-skeema
    └─► #24 MQTT → Firestore ingest
          └─► #25 GraphQL schema + resolverit

M2 (Offline) — alkaa kun #20 + #19 valmis
  #20 Firebase SDK IndexedDB-persistointi
  #19 Apollo InMemoryCache + Workbox 7
  #21 iOS Safari -varoitusbanner

M3 (UI) — alkaa mock-datalla, kytkeytyy #25:een
  #30 Navigaatiorakenne (Today / Vitals / My Health)
    └─► #2  Readiness-kortti
    └─► #3  Readiness Contributors -paneeli
    └─► #4  Sleep Duration Card
    └─► #5  Sleep Efficiency
    └─► #6  REM-uni
    └─► #7  Deep Sleep
    └─► #8  HRV-trendiviiva
    └─► #9  Resting HR
    └─► #10 Kofeiini-ikkuna
    └─► #11 Alkoholi pika-kirjaus
    └─► #13 Päiväunet pika-kirjaus

M4 (Post-MVP)
  #12 Alkoholin vaikutustulkinta
  #14 Päiväunen palautusvaikutus
  #15 Recovery Cost
  #16 Viikonloppusyklivertailu
  #17 Manuaali-synkronointi
```

---

## M0 — Infra & Auth

**Blokkaava:** kaikki muut milestoonet riippuvat tästä.

### #32 Firebase + GCP setup

**Riippuvuudet:** —
**Blokoi:** #29, #28, #31

Toteutusjärjestys:
1. Luo Firebase-projekti `pwa-oura-prod`, aktivoi Firestore (`europe-north1`) ja Google SSO.
2. Luo ingest-SA (`oura-ingest@...`), anna `roles/datastore.user`.
3. Tallenna `firebase-sa`, `mqtt-broker-url`, `mqtt-user`, `mqtt-pass`, `oura-client-id`, `oura-client-secret` → GCP Secret Manager.
4. Tallenna `FIREBASE_CONFIG` ja `GCP_SA_KEY` → GitHub Secrets.
5. Julkaise Firestore-turvasäännöt (vain autentikoitu käyttäjä omaan dataan).

Hyväksymiskriteerit:
- [ ] Firebase Console: Firestore aktiivinen, Google-provider aktiivinen
- [ ] `gcloud secrets list --project=pwa-oura-prod` näyttää kaikki 6 salaisuutta
- [ ] GitHub repo → Settings → Secrets: `FIREBASE_CONFIG` ja `GCP_SA_KEY` näkyvissä

---

### #29 Cloud Run — oura-ingest + oura-graphql

**Riippuvuudet:** #32
**Blokoi:** #24, #25, #28

Toteutusjärjestys:
1. Luo Artifact Registry -repositorio `pwa-oura` (`europe-north1`).
2. Aja `infra/setup-artifact-registry.sh`.
3. Deploy `oura-ingest` (`--min-instances=1`, `--no-allow-unauthenticated`).
4. Deploy `oura-graphql` (portti 4000, `--allow-unauthenticated` + Firebase ID Token middleware).
5. Tallenna `oura-graphql` URL → `NEXT_PUBLIC_GRAPHQL_URL` GitHub Secretsiin.

Hyväksymiskriteerit:
- [ ] `gcloud run services list` näyttää molemmat palvelut `europe-north1`:ssä
- [ ] Smoke test: `curl https://oura-graphql-URL/graphql` palauttaa GraphQL introspection
- [ ] `oura-ingest` pysyy ylhäällä MQTT-yhteyden ajan (min-instances=1)

---

### #28 Auth — Google SSO + Oura OAuth 2.0

**Riippuvuudet:** #32, #29
**Blokoi:** #25 (autorisointi), #2–#13 (kaikki UI-featuret)

Toteutusjärjestys:
1. Rekisteröi Oura OAuth app: `https://cloud.ouraring.com/developers`
   - `redirect_uri` = `https://[CLOUD_RUN_URL]/auth/oura/callback`
   - Scope: `daily personal heartrate workout session spo2 tag`
2. Toteuta `/auth/oura/callback` Cloud Runissa (koodi issuessa #28).
3. Tallenna Oura-tokenit `users/{userId}/ouraToken` Firestoreen.
4. Luo Firebase Custom Token → lähetä frontille hash-parametrina.
5. Frontend: `signInWithCustomToken()` → Firebase ID Token.
6. Lisää token-refresh -logiikka ingest-palveluun (Oura 24 h expiry).

Hyväksymiskriteerit:
- [ ] Uusi käyttäjä voi kirjautua Google SSO:lla
- [ ] Oura OAuth flow onnistuu: `users/{userId}/ouraToken` kirjoitettu Firestoreen
- [ ] Firebase ID Token validoidaan Cloud Run -middlewaressa
- [ ] Logout poistaa ouraToken:in, kutsuu Firebase `signOut()`

---

### #18 PWA GH Pages -konfiguraatio

**Riippuvuudet:** #32 (FIREBASE_CONFIG)
**Blokoi:** #31

Toteutusjärjestys:
1. Päivitä `next.config.js`: `output: 'export'`, `basePath: '/pwa-oura'`, `assetPrefix: '/pwa-oura/'`.
2. Päivitä `public/manifest.json`: `start_url`, `scope`, `id` = `/pwa-oura/`.
3. Korjaa SW-rekisteröinti: `register('/pwa-oura/sw.js', { scope: '/pwa-oura/' })`.
4. Lisää `.nojekyll` → `out/`-kansioon deployssa.

Hyväksymiskriteerit:
- [ ] Lighthouse PWA audit: Installable-tarkistus vihreänä
- [ ] Sovellus asentuu kotinäytölle Android Chromessa
- [ ] SW rekisteröityy ilman 404-virheitä

---

### #31 CI/CD — GitHub Actions

**Riippuvuudet:** #18, #29
**Blokoi:** —

Toteutusjärjestys:
1. Luo `.github/workflows/ci.yml` (koodi issuessa #31).
2. Kolme jobbia: `test` (lint + typecheck + Firestore-emulaattori), `deploy-ingest` (Cloud Run), `deploy-pwa` (GH Pages).
3. Varmista `npm run lint`, `typecheck`, `build` toimivat lokaalisti ennen ensimmäistä CI-ajoa.

Hyväksymiskriteerit:
- [ ] PR → test-job menee läpi
- [ ] main-merge → deploy-ingest ja deploy-pwa käynnistyvät
- [ ] GH Pages päivittyy automaattisesti

---

## M1 — Data pipeline

**Voi alkaa M0:n kanssa rinnakkain** — Firestore-emulaattori riittää kehitykseen.

### #23 Firestore-skeema

**Riippuvuudet:** —
**Blokoi:** #24, #25

Toteutusjärjestys:
1. Vahvista kokoelmarakenne suhteessa GraphQL-skeemaan (#25) — ristiintarkistus ennen toteutusta.
2. Tallenna `firestore.indexes.json` repoon (sisältö issuessa #23).
3. Dokumentoi skeema → `docs/firestore-schema.md`.
4. Testaa Firestore-emulaattorilla.

Hyväksymiskriteerit:
- [ ] `firestore.indexes.json` commitoitu
- [ ] `docs/firestore-schema.md` kirjoitettu
- [ ] Emulaattoritestit vihreänä: kirjoitus + luku `dailyRecords`, `sleepSessions`, `events`

---

### #24 MQTT → Firestore ingest

**Riippuvuudet:** #23, #29 (Cloud Run), #32 (Secret Manager)
**Blokoi:** #25 (data täytyy olla Firestoressä ennen kuin resolverit voi testata)

Toteutusjärjestys:
1. Rekisteröi HiveMQ Cloud free tier: `https://console.hivemq.cloud`
2. Tallenna `MQTT_BROKER_URL`, `MQTT_USER`, `MQTT_PASS` → Secret Manager.
3. Luo `services/ingest/` (Node.js + TypeScript), toteuta `index.ts` (koodi issuessa #24).
4. Lisää Zod-validointi ennen Firestore-kirjoitusta.
5. Happy path ensin: `oura/user/{id}/daily/readiness` → `dailyRecords/{date}.readiness`.
6. Deploy Cloud Runiin `--min-instances=1`.

Hyväksymiskriteerit:
- [ ] `mqtt publish` → Firestore-emulaattori kirjoittaa oikein
- [ ] `merge: true` toimii (kaksoispublish ei ylikirjoita muita kenttiä)
- [ ] Dead-letter: virheelliset viestit logitetaan, eivät kaada palvelua
- [ ] Cloud Run pysyy ylhäällä MQTT-yhteyden ajan

---

### #25 GraphQL schema + resolverit

**Riippuvuudet:** #23, #24, #28
**Blokoi:** #2–#13 (kaikki UI-featuret tarvitsevat GraphQL:ää)

Toteutusjärjestys:
1. Lisää `src/graphql/schema.graphql` (skeema issuessa #25).
2. Toteuta resolverit järjestyksessä — aloita MVP-minimillä:
   - `dailyReadiness` → liittyy #2
   - `dailySleep` + `sleepSessions` → liittyy #4–#7
   - `dailyActivity` → liittyy #30
   - `dailyStress` → liittyy #30
   - `sleepTime` → liittyy #30
3. Jokainen resolveri validoi Firebase ID Tokenin, tarkistaa `uid === userId`.
4. Lisää `weeklyMetrics`-aggregaatti My Health -välilehteä varten (#30).

Hyväksymiskriteerit:
- [ ] `schema.graphql` commitoitu
- [ ] `dailyReadiness` palauttaa datan Firestoresta
- [ ] Autorisointi: väärällä UID:llä 403
- [ ] Kaikki MVP-queryt vastaavat (readiness, sleep, activity, stress, sleepTime, sleepSessions)

---

## M2 — Offline

**Alkaa kun M0 on käynnissä.** Voidaan kehittää M1:n kanssa rinnakkain.

### #20 Firebase SDK IndexedDB-persistointi

Toteutusjärjestys:
1. Lisää `enableIndexedDbPersistence(db)` client-initiin.
2. Toteuta `logEvent(type, amount, note)` Firebase SDK:lla (koodi issuessa #20).
3. Lisää `onSnapshot()` reaaliaikapäivityksille.
4. Poista vanha Background Sync / SW-jono.

Hyväksymiskriteerit:
- [ ] Kirjaus onnistuu offline-tilassa
- [ ] Kirjaus synkronoidaan kun yhteys palaa
- [ ] UUID-deduplikaatio toimii backendissä
- [ ] localStorage ei käytössä missaan kohtaa

---

### #19 Apollo InMemoryCache + Workbox 7

Toteutusjärjestys:
1. Lisää `apollo3-cache-persist` IndexedDB-adapterilla.
2. Kutsu `navigator.storage.persist()` app-initissä.
3. Konfiguroi Workbox 7 (`@ducanh2912/next-pwa`) CacheFirst/NetworkFirst (konfiguraatio issuessa #19).

Hyväksymiskriteerit:
- [ ] App shell latautuu offline-tilassa
- [ ] `getDayRecord` palauttaa cached datan verkottomassa tilassa
- [ ] Workbox 7 käytössä (ei vanha next-pwa)

---

### #21 iOS Safari -varoitusbanner

Toteutusjärjestys:
1. Lisää UA-tunnistus (koodi issuessa #21).
2. Näytä banner iOS Safarilla.
3. Dokumentoi tuetut alustat README.md:hen.

Hyväksymiskriteerit:
- [ ] iOS Safari tunnistetaan ja banneri näytetään
- [ ] Ei iOS-spesifistä workaround-koodia

---

## M3 — UI-komponentit

**Kehitys mock-datalla M1:n rinnalla. Kytketään GraphQL:ään kun #25 valmis.**

### #30 Navigaatiorakenne

Toteutusjärjestys:
1. Bottom tab bar: Today / Vitals / My Health.
2. Today-sivu: ScorePill × 3 + DayTimeline + QuickLogButton × 3.
3. Vitals-sivu: DateNavigator + MetricCard × 3 (Readiness, Sleep, Activity).
4. Sleep Detail overlay: SleepPhaseBar + SpO₂.
5. My Health: TrendChart (30 pv) + HealthAreaCard × 4.
6. Kytke Apollo Client kun #25 valmis.
7. Offline-tila: näytä cached data kun verkko poikki (#19, #20).

---

### #2 Readiness-kortti

Komponentti: `ScorePill` + värilogiikka (≥85 Ensō Blue, 70–84 Sandstone, <70 Living Coral).
GraphQL: `dailyReadiness(userId, date)` → `score`.
Firestore: `users/{userId}/dailyRecords/{date}.readiness.score`.

Toteutusjärjestys:
1. Rakenna komponentti mock-datalla.
2. Kytke `useQuery(GET_READINESS)` kun #25 valmis.
3. Lisää loading skeleton + error state.

---

### #3 Readiness Contributors -paneeli

Komponentti: Progress bars (Sandstone + Ensō Blue), 8 contributors.
GraphQL: `dailyReadiness.contributors.*`.
Firestore: `dailyRecords/{date}.readiness.contributors`.

---

### #4–#7 Sleep-kortit

| Issue | Feature | GraphQL | Firestore |
|---|---|---|---|
| #4 | Sleep Duration | `dailySleep.totalSleepDuration` | `dailyRecords/{date}.sleep` |
| #5 | Sleep Efficiency | `dailySleep.efficiency` | `dailyRecords/{date}.sleep` |
| #6 | REM Duration | `sleepSessions.remSleepDuration` | `sleepSessions/{id}` |
| #7 | Deep Sleep | `sleepSessions.deepSleepDuration` | `sleepSessions/{id}` |

Kaikki neljä voidaan kehittää rinnakkain — sama datasource, eri visualisointi.

---

### #8 HRV-trendiviiva

Komponentti: `TrendChart` (Chart.js / Recharts), tumma teema.
Data: `sleepSessions.hrv.items[]` (5 min epokit).
GraphQL: `sleepSessions(userId, start, end)` → `hrv.items`.

---

### #9 Resting HR

Komponentti: Numerokortti + aika-teksti.
Data: `sleepSessions.lowestHeartRate` + aikaleima.

---

### #10 Kofeiini-ikkuna

Komponentti: Vaakasuora aikajana (punainen <10h, sininen turvallinen).
GraphQL: `getEventsRange(start, end)` → kofeiini-tapahtumat + `sleepTime.bedtimeStart`.

---

### #11 Alkoholi pika-kirjaus

Komponentti: FAB tai yläpalkin nappi → modaali (määrä + aika).
GraphQL mutation: `logEvent(type: alcohol, timestamp, amount, note)`.
Firestore: `events/{eventId}` + `dailyRecords/{date}.eventSummary.alcoholTotal` päivitetään atomisesti.

---

### #13 Päiväunet pika-kirjaus

Komponentti: `QuickLogButton` → modaali (kesto minuutteina).
GraphQL mutation: `logEvent(type: nap, timestamp, amount, note)`.

---

## M4 — Post-MVP

Näitä ei toteuteta ennen kuin M0–M3 on tuotannossa ja vakaat.

| Issue | Feature | Esto |
|---|---|---|
| #12 | Alkoholin vaikutustulkinta | Vaatii `dailyRecords` baseline-aggregaatit |
| #14 | Päiväunen palautusvaikutus | Vaatii `sleepSessions.type: nap` + laskenta |
| #15 | Recovery Cost | Vaatii `metricsJson`-blobin poiston (#25 valmis) |
| #16 | Viikonloppusyklivertailu | Vaatii `weeklyAggregates.saturdayReadiness` |
| #17 | Manuaali-synkronointi | Vaatii Oura API poll -trigger |

---

## Tekninen velka — seuranta

| Kohde | Tila | Tiketti |
|---|---|---|
| `metricsJson`-blobin poisto | Poistetaan kun #25 resolverit tuotannossa | #23, #25 |
| `getDayRecord` → `dailyReadiness` + `dailySleep` (erilliset resolverit) | Kun #25 valmis | #2–#9 |
| Firestore-indeksit `firestore.indexes.json` | Commitoitava ennen tuotantoa | #23 |
| E2E-testit (Playwright) | Post-MVP | #31 |

---

## Ympäristömuuttujat ja salaisuudet

### GitHub Secrets (repo → Settings → Secrets and variables → Actions)

| Secret | Kuvaus |
|---|---|
| `GCP_SA_KEY` | Deploy-service accountin JSON (vain deploy-oikeudet) |
| `GRAPHQL_URL` | Cloud Run GraphQL-endpointin URL (päivitetään #29:n jälkeen) |
| `FIREBASE_CONFIG` | `firebaseConfig`-objekti JSON-stringinä |

### GCP Secret Manager (`pwa-oura-prod`)

| Secret | Kuvaus |
|---|---|
| `firebase-sa` | Ingest-service accountin JSON (Firestore-kirjoitusoikeus) |
| `mqtt-broker-url` | HiveMQ Cloud URL (`mqtts://...`) |
| `mqtt-user` | MQTT-käyttäjätunnus |
| `mqtt-pass` | MQTT-salasana |
| `oura-client-id` | Oura OAuth app client ID |
| `oura-client-secret` | Oura OAuth app client secret |

---

## Liittyvät dokumentit

- [README.md](../README.md) — projektin yleiskuvaus ja pika-aloitus
- [USE-CASES.md](../USE-CASES.md) — 18 käyttötapausta Oura API v2 -tietomalleineen
- [docs/architecture.md](architecture.md) — pipeline-kaavio ja ADR-viitteet
- [docs/firestore-schema.md](firestore-schema.md) — Firestore-kokoelmarakenne ja indeksit
