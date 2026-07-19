# Arkkitehtuuri

## Pipeline-yleiskuva

```
Oura API v2
    │
    ▼
MQTT broker
    │
    ▼
Ingest-palvelu  (Node.js / Go / Cloud Run)
    │  parsii, validoi, kirjoittaa
    ▼
Firestore
    │
    ▼
GraphQL API  (Apollo Server / Cloud Run)
    │
    ▼
PWA-client  (Apollo Client)
```

---

## Rajapintaperiaatteet

| Polku | Teknologia | Vastuu |
|---|---|---|
| Oura-data sisään | MQTT | Telemetria, raakadata, ingest |
| Payload-datan luku ja kirjoitus | GraphQL | Kaikki sovellusdata (queryt + mutaatiot) |
| Autentikointi | Firebase Auth SDK | `signInWithGoogle()`, `onAuthStateChanged()` |
| Realtime-kuuntelu (tarvittaessa) | Firestore SDK `onSnapshot()` | Live-päivitykset UI:ssa |
| Offline-persistointi | Firestore SDK `enableIndexedDbPersistence()` | Paikallinen jono |
| Push-notifikaatiot | FCM SDK | `getToken()`, `onMessage()` |
| Tiedostot | Storage SDK | `uploadBytes()`, `getDownloadURL()` |

**Firebase SDK ja Apollo Client elävät rinnakkain clientissä.**  
SDK:n `onAuthStateChanged()` antaa tokenin, joka liitetään Apollo-linkissä GraphQL-pyyntöjen `Authorization`-headeriin.  
SDK hoitaa infrastruktuurin — GraphQL hoitaa sovellusdatan.

---

## Pääasiallinen datavirta

### Luku (UI hakee päivädatan)

```
Apollo Client
  → getDayRecord(date: "2026-07-20")  [GraphQL query]
    → Apollo Server / resolveri
      → Firestore: users/{userId}/dailyRecords/{date}  [1 luku]
        → palauttaa DailyRecord-objektin
```

### Kirjoitus (käyttäjä kirjaa tapahtuman)

```
Apollo Client
  → logEvent(type: "caffeine", amount: 150)  [GraphQL mutaatio]
    → Apollo Server / resolveri
      → Firestore batch write:
          events/{eventId}  +  dailyRecords/{date}.eventSummary
```

### Ingest (Oura-data sisään)

```
Oura API v2 webhook / polling
  → MQTT topic: oura/user/{userId}/metrics/{type}
    → Ingest-palvelu
      → validoi + parsii
        → Firestore: users/{userId}/dailyRecords/{date}  (update)
                     users/{userId}/sleepSessions/{id}   (set)
```

---

## Tietoturva

- **Autentikointi:** Firebase Auth (Google Sign-In)
- **GraphQL:** JWT-token headerissa, resolveri tarkistaa `userId`
- **Firestore Security Rules:** lukee ja kirjoittaa vain oman `userId`:n alle — suojaa suoran SDK-käytön ja ingest-palvelun palvelutiliä lukuun ottamatta
- **Ingest-palvelu:** käyttää Firebase Admin SDK:ta palvelutilillä, ei loppukäyttäjän tokenia

---

## Viitteet

- [ADR: MQTT ingest, GraphQL API](../issues/22) — issue #22
- [Firestore-skeema](./firestore-schema.md)
- [USE-CASES.md](../USE-CASES.md)
