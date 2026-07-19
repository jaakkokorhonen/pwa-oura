# MVP scope — pwa-oura

Päivitetty: 2026-07-20

## Tavoite

Ensimmäinen MVP on asennettava mobiili-PWA, jossa käyttäjä:

1. Kirjautuu sisään Google SSO:lla (Firebase Auth)
2. Yhdistää Oura-tilinsä (Oura OAuth 2.0)
3. Saa Oura-datansa sisään pipelinea pitkin:

   Oura API v2 → MQTT → ingest → Firestore → GraphQL → PWA UI

4. Näkee datansa kolmessa päätabissa: **Today**, **Vitals** ja **My Health**
5. Voi käyttää sovellusta myös heikolla verkolla / offline-näkymänä (viimeisin cached data)

## MVP:n tekninen scope

Seuraavat issuet muodostavat yhdessä MVP:n minimin:

- #32 Firebase + GCP ‑setup
- #28 Auth: Google SSO (Firebase Auth) + Oura OAuth 2.0 token management
- #24 MQTT → Firestore ingest service
- #23 Firestore schema for Oura-style data
- #29 Cloud Run setup: `oura-ingest` + `oura-graphql`
- #25 GraphQL schema and resolvers for Oura metrics (Query-only, ei Subscription)
- #30 PWA-UI: navigaatiorakenne ja MVP-näkymät (Today / Vitals / My Health + Sleep detail)
- #31 CI/CD: GitHub Actions — testit, ingest-deploy, PWA-deploy

Lisäksi MVP:hen kuuluu:

- Web App Manifest (nimi, ikonit, display: standalone, theme/splash-värit)
- Service worker (perus offline: viimeisin cached data pääqueryille)
- PWA:n asennettavuus (Chrome/Android + iOS “Add to Home Screen”)

## Rajaukset (ei MVP:hen)

Seuraavat asiat on päätetty jättää ensimmäisen MVP:n ulkopuolelle:

- **GraphQL Subscriptions / WebSocket / SSE**

  - MVP:ssä UI käyttää Apollo Clientin pollingia (esim. 5 min) `daily*`-queryille.
  - Skeema on Query-only; Subscription-tyyppiä ei määritellä.

- **Pub/Sub dead-letter queue ingest-palvelulle**

  - MVP:ssä virheelliset viestit kirjoitetaan Firestore-kokoelmaan `failedIngests`.
  - Pub/Sub DLQ arvioidaan erillisessä infra-issussa, jos ingest-volyymi kasvaa (esim. > 10k viestiä/päivä).

- **Laajat raportointi- ja jakotoiminnot**

  - Viikkoraportti voidaan aloittaa tekstipohjaisena yhteenvetona UI:ssa.
  - PDF-putki, mailijakelut ja laajat exportit eivät kuulu MVP:hen.

- **Push-notifikaatiot ja monimutkaiset asetussivut**

  - Ei FCM/Apns-push-kerrosta MVP:ssä.
  - Asetukset minimoidaan (kirjautuminen, Oura-yhteyden hallinta).

## Käyttäjäkokemus MVP:ssä

- **Today-tab**

  - Kolme score-pill-komponenttia: Readiness, Sleep, Activity (0–100, värikoodaus)
  - Päivän aikajana (aamu/päivä/ilta)
  - Nopeat kirjaukset: kofeiini, alkoholi, päiväunet (GraphQL-mutaationa)

- **Vitals-tab**

  - Päivämääränavigaatio
  - Readiness-, Sleep- ja Activity-kortit
  - Sleep detail -overlay: unen vaiheet aikajanana, HRV, HR, SpO₂

- **My Health-tab**

  - 30 päivän trendikaavio (HRV, RHR, Sleep Score)
  - Health Areas -kortit (Sleep Health, Stress Management, Heart Health, Activity Health)

Tämä tiedosto toimii yhtenä lähteenä sille, mitä “MVP valmis” tarkoittaa teknisesti ja UX-mielessä.
