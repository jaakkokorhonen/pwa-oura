# pwa-oura

PWA-sovellus Oura-terveysdatan visualisointiin ja tapahtumien kirjaukseen. Hakee datan GraphQL-rajapinnan kautta (GCP / Cloud Run / Apollo Server / Firestore).

## Tuetut alustat

| Alusta | Tuki | Huomiot |
|---|---|---|
| **Chrome Android** | ✅ Täysi tuki | Suositeltu pääalusta. PWA asentuu kotinäytölle, Background Sync, Web Push |
| **Chrome Desktop** (Windows/macOS/Linux) | ✅ Täysi tuki | PWA asentuu, kaikki ominaisuudet toimivat |
| **Edge** (Chromium) | ✅ Täysi tuki | Sama kuin Chrome |
| **Firefox** | ⚠️ Osittainen | Service Worker toimii, PWA-installaatio rajoitettu |
| **iOS Safari** | ❌ Ei tueta | Puuttuu: Background Sync API, luotettava IndexedDB-pysyvyys, OAuth popup standalone-tilassa |
| **Samsung Internet** | ⚠️ Osittainen | Chromium-pohjainen, pääosin toimii |

### Miksi iOS Safari ei ole tuettu

Sovellus käyttää **Background Sync APIa** offline-kirjauksiin (kofeiini, alkoholi, päiväunet). iOS Safari ei tue tätä APIa, jolloin offline-tilassa tehdyt kirjaukset voivat kadota. Lisäksi iOS Safari PWA standalone-tilassa ei tue OAuth popup-flowi ja localStorage tyhjenee 7 vrk inaktiivisuuden jälkeen.

Tämä on tietoinen rajaus, ei bugi. iOS-käyttäjille näytetään sovelluksessa selkeä ilmoitus.

## Arkkitehtuuri

```
pwa-oura (tämä repo)
  └── PWA-client (Next.js / React + Apollo Client)
        ├── Gmail SSO → Google OAuth 2.0 (Bearer JWT)
        ├── GraphQL API → Cloud Run / Apollo Server
        │     ├── Kirjoittaa: logEvent(), saveDayRecord()
        │     └── Lukee: getDayRecord(), getEventsRange()
        └── Näyttää: Oura-datat, tagit, trendit, N-of-1-analytiikka
```

Hostataan: [GitHub Pages](https://jaakkokorhonen.github.io/pwa-oura/)

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
