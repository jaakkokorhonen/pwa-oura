# pwa-oura

PWA-sovellus Oura-terveysdatan visualisointiin ja tapahtumien kirjaukseen. Hakee datan GraphQL-rajapinnan kautta (GCP / Cloud Run / Apollo Server / Firestore).

## Tuetut alustat

| Alusta | Tuki | Huomiot |
|---|---|---|
| **Chrome Android** | ✅ Täysi tuki | Suositeltu pääalusta. PWA asentuu kotinäytölle, offline-tuki, Web Push |
| **Chrome Desktop** (Windows/macOS/Linux) | ✅ Täysi tuki | PWA asentuu, kaikki ominaisuudet toimivat |
| **Edge** (Chromium) | ✅ Täysi tuki | Sama kuin Chrome |
| **Firefox** | ⚠️ Osittainen | Service Worker toimii, PWA-installaatio rajoitettu |
| **iOS Safari** | ❌ Ei tueta | Puuttuu: luotettava IndexedDB-pysyvyys, OAuth popup standalone-tilassa |
| **Samsung Internet** | ⚠️ Osittainen | Chromium-pohjainen, pääosin toimii |

### Miksi iOS Safari ei ole tuettu

Sovellus käyttää Firebase SDK:n `enableIndexedDbPersistence()`-ominaisuutta offline-kirjauksiin. iOS Safari PWA standalone-tilassa ei tue OAuth popup-flowi, ja localStorage tyhjenee 7 vrk inaktiivisuuden jälkeen. Tämä on tietoinen rajaus — iOS-käyttäjille näytetään sovelluksessa selkeä ilmoitus.

## Arkkitehtuuri

### Tiedonkulku (Hybridi-malli)

```
Kirjaukset (kofeiini, alkoholi, päiväunet)
  └── Firebase SDK → Firestore
        └── Offline: SDK jonottaa automaattisesti IndexedDB:hen
        └── Online: Firestore trigger → Cloud Run / Skill → metricsJson-rikastus

Lukukyselyt (getDayRecord, getEventsRange, HRV-aikasarjat)
  └── Apollo Client → GraphQL API (Cloud Run) → Firestore
        └── apollo3-cache-persist → IndexedDB (offline fallback)

Reaaliaikaiset UI-päivitykset
  └── Firestore onSnapshot() → UI
        (automaattinen päivitys kun Skill on ajanut rikastuksen)
```

### Tallennuskerros

| Data | Tallennus | Offline-tuki |
|---|---|---|
| Kirjaukset (events) | Firestore via Firebase SDK | ✅ Automaattinen IndexedDB-jono |
| Lukukyselyt (GraphQL) | Apollo InMemoryCache + apollo3-cache-persist | ✅ IndexedDB |
| App shell (JS/CSS) | Workbox 7 / CacheFirst | ✅ Service Worker |
| Auth (JWT) | IndexedDB (ei localStorage) | ✅ Pysyvä |

> **localStorage ei käytössä** missään kohtaa. Kaikki persistointi IndexedDB:n kautta.
> **MQTT ei käytössä.** Reaaliaikaisuus toteutetaan Firestore `onSnapshot()`-kuuntelijoilla.

### Stack

```
Frontend:  Next.js + React + Apollo Client + Firebase SDK
Hosting:   GitHub Pages (gh-pages branch)
API:       Cloud Run / Apollo Server / GraphQL
DB:        Firestore
Auth:      Google OAuth 2.0 (Gmail SSO)
Caching:   Workbox 7 (@ducanh2912/next-pwa) + apollo3-cache-persist
```

## Kehitys

```bash
npm install
npm run dev
```

## Deploy

Deploy tapahtuu automaattisesti GitHub Actionsin kautta `main`-branchille pushaamalla.

## Linkit

- [Käyttötapaukset (USE-CASES.md)](./USE-CASES.md)
- [Visuaalinen suunnittelu (use_cases_visual_design.md)](./use_cases_visual_design.md)
- [Backend RFC (weekly-cycle-oura-skill #36)](https://github.com/jaakkokorhonen/weekly-cycle-oura-skill/issues/36)
- [Oura API v2 docs](https://cloud.ouraring.com/v2/docs)
