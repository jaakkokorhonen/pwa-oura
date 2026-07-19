# Firestore-skeema

Perustuu [USE-CASES.md](../USE-CASES.md):n Oura API v2 -endpointteihin ja feature-issueihin (#2–#17).  
Kirjoituspolku: MQTT → ingest-palvelu (#24) → Firestore.  
Lukupolku ja käyttäjäkirjaukset: GraphQL (#25) → Firestore → UI.

---

## Kokoelmarakenne

```
users/{userId}/
  dailyRecords/{date}            YYYY-MM-DD  — päivätason aggregaatti
  sleepSessions/{sleepId}        Oura sleep id — unisessiot + aikasarjat
  events/{eventId}               UUID — käyttäjän kirjaamat tapahtumat
  workouts/{workoutId}           Oura workout id
  mindfulnessSessions/{id}       Oura mindfulness id
  tags/{tagId}                   Oura tag id
  weeklyAggregates/{weekId}      YYYY-Www (ISO 8601)
```

---

## `dailyRecords/{date}`

Yksi dokumentti per päivä. Yksi Firestore-luku kattaa koko `getDayRecord(date)` GraphQL-queryn.

```typescript
{
  date: string,               // "YYYY-MM-DD" — dokumentin ID
  userId: string,
  updatedAt: Timestamp,
  syncedAt: Timestamp,

  readiness: {
    score: number,
    temperatureDeviation: number,
    temperatureTrendDeviation: number,
    contributors: {
      activityBalance: number,
      bodyTemperature: number,
      hrvBalance: number,
      previousDayActivity: number,
      previousNight: number,
      recoveryIndex: number,
      restingHeartRate: number,
      sleepBalance: number,
    }
  },

  sleep: {
    score: number | null,
    contributors: {
      deepSleep: number,
      efficiency: number,
      latency: number,
      longUninterruptedSleep: number,
      lowMovement: number,
      remSleep: number,
      restfulness: number,
      timing: number,
      totalSleep: number,
    }
  },

  activity: {
    score: number | null,
    steps: number,
    activeCalories: number,
    totalCalories: number,
    equivalentWalkingDistance: number,
    highActivityTime: number,
    mediumActivityTime: number,
    lowActivityTime: number,
    sedentaryTime: number,
    inactivityAlerts: number,
    averageMetMinutes: number,
    contributors: {
      meetDailyTargets: number,
      moveEveryHour: number,
      recoveryTime: number,
      stayActive: number,
      trainingFrequency: number,
      trainingVolume: number,
    }
  },

  stress: {
    stressHigh: number,
    recoveryHigh: number,
    daySummary: "restored" | "normal" | "stressful" | null,
  },

  resilience: {
    level: "exceptional" | "strong" | "solid" | "adequate" | "limited" | null,
    contributors: {
      sleepRecovery: number,
      daytimeRecovery: number,
      stress: number,
    }
  },

  spo2: {
    average: number | null,
  },

  vo2Max: number | null,
  cardiovascularAge: number | null,

  sleepTimeRecommendation: {
    status: string | null,
    optimalBedtime: string | null,
    bedtimeStart: string | null,
    bedtimeEnd: string | null,
  } | null,

  // Denormalisoitu pikakatsaus — GraphQL-mutaatio (logEvent) päivittää
  eventSummary: {
    caffeineTotal: number,
    alcoholTotal: number,
    lastCaffeineTimestamp: string | null,
    napCount: number,
  },

  cycleState: string | null,
  status: string | null,
  metricsJson: string | null,   // Poistetaan kun GraphQL-resolverit (#25) valmiit
}
```

---

## `sleepSessions/{sleepId}`

Aikasarjat suoraan dokumenttiin — 5 min epokeilla 8h uni = ~96 arvoa ≈ 1–2 KB, hyvin alle Firestore 1 MiB -rajan.

```typescript
{
  id: string,
  userId: string,
  date: string,
  type: "long_sleep" | "rest" | "late_nap" | "nap",
  bedtimeStart: Timestamp,
  bedtimeEnd: Timestamp,
  totalSleepDuration: number,
  timeInBed: number,
  deepSleepDuration: number,
  lightSleepDuration: number,
  remSleepDuration: number,
  awakeTime: number,
  latency: number,
  efficiency: number,
  restlessPeriods: number,
  averageHeartRate: number,
  lowestHeartRate: number,
  averageHrv: number,
  averageBreath: number,
  readinessScoreDelta: number | null,
  sleepAlgorithmVersion: string | null,
  sleepPhase5Min: string | null,
  hrv: { interval: number, items: number[] } | null,
  heartRate: { interval: number, items: number[] } | null,
  syncedAt: Timestamp,
}
```

---

## `events/{eventId}`

Käyttäjän kirjaamat tapahtumat. **Kirjoitetaan GraphQL-mutaatiolla** (`logEvent`) — ei Firebase SDK:lla suoraan clientistä.

```typescript
{
  id: string,               // crypto.randomUUID()
  userId: string,
  type: "caffeine" | "alcohol" | "meal" | "nap",
  timestamp: Timestamp,
  date: string,             // "YYYY-MM-DD"
  amount: number | null,
  unit: string | null,
  note: string | null,
  source: "user" | "oura",
  createdAt: Timestamp,
}
```

---

## `workouts/{workoutId}`

```typescript
{
  id: string,
  userId: string,
  date: string,
  activity: string,
  intensity: "easy" | "moderate" | "hard" | null,
  label: string | null,
  source: "manual" | "detected",
  startDatetime: Timestamp,
  endDatetime: Timestamp,
  calories: number | null,
  distance: number | null,
  syncedAt: Timestamp,
}
```

---

## `mindfulnessSessions/{id}`

```typescript
{
  id: string,
  userId: string,
  date: string,
  type: "breathing" | "meditation" | "nap" | "rest" | "body_status",
  startDatetime: Timestamp,
  endDatetime: Timestamp,
  averageHeartRate: number | null,
  averageHrv: number | null,
  motionCount: number | null,
  syncedAt: Timestamp,
}
```

---

## `tags/{tagId}`

```typescript
{
  id: string,
  userId: string,
  tagTypeCode: string,
  text: string | null,
  timestamp: Timestamp,
  date: string,
  startTime: Timestamp | null,
  endTime: Timestamp | null,
  source: string | null,
  category: string | null,
  subCategory: string | null,
  syncedAt: Timestamp,
}
```

---

## `weeklyAggregates/{weekId}`

`weekId` = `"YYYY-Www"` (ISO 8601). Lasketaan Cloud Functionissa kun viikon viimeinen `dailyRecord` kirjoitetaan.

```typescript
{
  weekId: string,
  userId: string,
  startDate: string,
  endDate: string,
  avgReadinessScore: number | null,
  avgSleepScore: number | null,
  avgActivityScore: number | null,
  avgHrv: number | null,
  avgLowestHr: number | null,
  totalSteps: number,
  totalActiveCalories: number,
  totalAlcohol: number,
  totalCaffeineDays: number,
  saturdayReadiness: number | null,
  sundayReadiness: number | null,
  mondayReadiness: number | null,
  dayCount: number,
  updatedAt: Timestamp,
}
```

---

## Firestore-indeksit

Tallenna tiedostoon `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "sleepSessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "weeklyAggregates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "weekId", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tags",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## Suunnittelupäätökset

**Yksi `dailyRecords`-dokumentti per päivä** — `getDayRecord(date)` hakee käytännössä aina kaiken päivän datan kerralla. 1 Firestore-luku vs. 5–7 rinnakkaista.

**Aikasarjat suoraan dokumenttiin** — 5 min epokeilla 8h uni ≈ 1–2 KB. Subcollection vasta tarpeen jos siirrytään sekuntitason raakadataan.

**GraphQL hoitaa payload-datan, Firebase SDK infrastruktuurin** — autentikointi, offline-persistointi ja realtime-kuuntelu pysyvät SDK:lla. Sovellusdata (Oura-metriikat, käyttäjäkirjaukset) kulkee GraphQL:n kautta.

**`metricsJson` poistetaan asteittain** — vaihe 1: ingest kirjoittaa molemmat; vaihe 2: resolverit siirtyvät strukturoituihin kenttiin; vaihe 3: blob poistetaan.

---

## Viitteet

- [ADR #22](https://github.com/jaakkokorhonen/pwa-oura/issues/22)
- [Issue #23](https://github.com/jaakkokorhonen/pwa-oura/issues/23) — Firestore schema
- [Issue #24](https://github.com/jaakkokorhonen/pwa-oura/issues/24) — MQTT ingest
- [Issue #25](https://github.com/jaakkokorhonen/pwa-oura/issues/25) — GraphQL schema
- [architecture.md](./architecture.md)
