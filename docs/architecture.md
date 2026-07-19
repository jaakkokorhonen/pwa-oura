# Arkkitehtuuri — pwa-oura

> ADR: [#22](https://github.com/jaakkokorhonen/pwa-oura/issues/22)

## Pipeline

```
Oura API v2
  └─► MQTT broker (HiveMQ Cloud)
        └─► oura-ingest (Cloud Run, min-instances=1)
              └─► Firestore (europe-north1)
                    └─► oura-graphql (Cloud Run, Apollo Server)
                          └─► PWA client (Next.js, GitHub Pages)
```

## Roolijako

| Polku | Teknologia | Vastuu |
|---|---|---|
| Oura-data sisään | MQTT | Telemetria, raakadata, ingest |
| Sovellusdatan luku | GraphQL (Apollo) | Queryt: readiness, sleep, activity... |
| Sovellusdatan kirjoitus | GraphQL mutation | `logEvent`, `saveDayRecord` |
| Autentikointi | Firebase Auth SDK | `signInWithGoogle()`, `signInWithCustomToken()` |
| Offline-persistointi | Firestore SDK | `enableIndexedDbPersistence()` |
| Realtime-kuuntelu | Firestore SDK | `onSnapshot()` |
| App shell cache | Workbox 7 (CacheFirst) | JS/CSS/HTML |
| GraphQL cache | Apollo InMemoryCache + apollo3-cache-persist | IndexedDB, 5 MB |

## Autentikaatioarkkitehtuuri

```
Käyttäjä → Google SSO (Firebase Auth)
  └─► Oura OAuth 2.0 (Authorization Code Grant)
        └─► Cloud Run /auth/oura/callback
              └─► Oura access + refresh token → Firestore users/{uid}/ouraToken
              └─► Firebase Custom Token → frontend
                    └─► signInWithCustomToken() → Firebase ID Token
                          └─► kaikki Cloud Run -pyynnöt
```

## Palvelukartta

| Palvelu | Cloud Run -nimi | Alue | Auth |
|---|---|---|---|
| MQTT → Firestore | `oura-ingest` | europe-north1 | --no-allow-unauthenticated |
| GraphQL API | `oura-graphql` | europe-north1 | Firebase ID Token middleware |

## Ei-tuettu alusta

**iOS Safari** ei ole tuettu (ks. [#21](https://github.com/jaakkokorhonen/pwa-oura/issues/21)). Tuettu alusta: Chrome Android, Chrome Desktop.

## ADR-viitteet

- [#22](https://github.com/jaakkokorhonen/pwa-oura/issues/22) — MQTT sisään, GraphQL ulos
- [#20](https://github.com/jaakkokorhonen/pwa-oura/issues/20) — Firebase SDK IndexedDB korvaa Background Sync
- [#19](https://github.com/jaakkokorhonen/pwa-oura/issues/19) — Apollo InMemoryCache + Workbox 7
