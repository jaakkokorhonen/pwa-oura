# GitHub Issues: Oura Weekly Cycle PWA (GraphQL API & GH Pages Compatible)

Tämä tiedosto sisältää kuvaukset 16 issuelle, jotka on sovitettu toimimaan staattisessa PWA-ympäristössä (GitHub Pages -isännöinti), jossa tietoliikenne ja tallennus tapahtuvat nopean **Firebase GraphQL API:n** kautta.

---

### Issue 1: [Feature] Readiness-kortti (Valmiuspisteet)
**Kuvaus:**  
Toteutetaan etusivun päävalmiuskortti, joka näyttää päivittäisen valmiuspisteen. Tiedot haetaan nopean GraphQL-rajapinnan kautta.

**Tekniset vaatimukset:**
*   Komponentti: Helsinki Blue Glass (`rgba(47, 74, 115, 0.15)`) pyöristetyillä kulmilla (`border-radius: 16px`).
*   Värilogiikka: 
    *   `score >= 85`: Ensō Blue (`#A2D3E8`) - Optimaalinen.
    *   `70 <= score < 85`: Sandstone (`#E6DED3`) - Kohtalainen.
    *   `score < 70`: Living Coral (`#FC6558`) - Huomioitavaa.
*   **GraphQL Query:**
    ```graphql
    query GetReadiness($date: String!) {
      getDayRecord(date: $date) {
        status
        metricsJson # Sisältää readiness_score-arvon
      }
    }
    ```

---

### Issue 2: [Feature] Readiness Contributors -paneeli
**Kuvaus:**  
Toteutetaan Readiness-kortin alle avautuva paneeli, joka visualisoi valmiuteen vaikuttavat osatekijät (leposyke, HRV-tasapaino, lämpötilapoikkeama).

**Tekniset vaatimukset:**
*   Visualisointi: Vaakasuuntaiset edistymispalkit (Progress Bars) käyttäen Sandstone- ja Ensō Blue -sävyjä.
*   **GraphQL Query:**
    ```graphql
    query GetContributors($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # Parsitaan contributors-kentät
      }
    }
    ```

---

### Issue 3: [Feature] Unen kestoindikaattori (Sleep Duration Card)
**Kuvaus:**  
Näytetään pääunijakson pituus tunteina ja minuutteina suhteessa unitavoitteeseen.

**Tekniset vaatimukset:**
*   Visualisointi: Rengaskaavio tai edistymispalkki (Ensō Blue `#A2D3E8`).
*   **GraphQL Query:**
    ```graphql
    query GetSleepDuration($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # sleep.duration
      }
    }
    ```

---

### Issue 4: [Feature] Unitehokkuus-mittari (Sleep Efficiency)
**Kuvaus:**  
Näytetään unitehokkuusprosentti (aika unessa vs. aika sängyssä).

**Tekniset vaatimukset:**
*   Visualisointi: Pieni numerokortti taustapalkilla.
*   **GraphQL Query:**
    ```graphql
    query GetSleepEfficiency($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # sleep.efficiency
      }
    }
    ```

---

### Issue 5: [Feature] REM-unen kesto ja osuus
**Kuvaus:**  
Visualisoidaan REM-unen kesto ja sen osuus kokonaisuniajasta.

**Tekniset vaatimukset:**
*   Visualisointi: Osio vaaka-palkissa, joka näyttää unijakauman (REM-osuus värillä `#A2D3E8` 0.7 opasiteetilla).
*   **GraphQL Query:**
    ```graphql
    query GetREMSleep($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # sleep.rem_sleep_duration
      }
    }
    ```

---

### Issue 6: [Feature] Syvän unen kesto ja osuus
**Kuvaus:**  
Visualisoidaan syvän unen kesto ja sen osuus fysiologisen palautumisen indikaattorina.

**Tekniset vaatimukset:**
*   Visualisointi: Osa unijakaumapalkkia.
*   **GraphQL Query:**
    ```graphql
    query GetDeepSleep($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # sleep.deep_sleep_duration
      }
    }
    ```

---

### Issue 7: [Feature] Yöaikainen HRV-trendiviiva
**Kuvaus:**  
Toteutetaan yönaikaisen sykevälivaihtelun (HRV) kulkua kuvaava trendiviiva.

**Tekniset vaatimukset:**
*   Visualisointi: Google Charts LineChart tai kevyt Chart.js-integraatio tummalla teemalla.
*   **GraphQL Query:**
    ```graphql
    query GetHRVTrend($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # hrv.items[] aikasarja
      }
    }
    ```

---

### Issue 8: [Feature] Alin leposyke (Resting HR)
**Kuvaus:**  
Näytetään yön alin syke ja indikaatio siitä, kuinka varhain yön aikana se saavutettiin.

**Tekniset vaatimukset:**
*   Visualisointi: Numerokortti ja pieni huomioteksti ("Leposyke laski alimmilleen klo 03:15").
*   **GraphQL Query:**
    ```graphql
    query GetRestingHR($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # sleep.lowest_heart_rate
      }
    }
    ```

---

### Issue 9: [Feature] Kofeiini-ikkuna ja Gap-näyttö
**Kuvaus:**  
Visualisoidaan viimeisen kofeiinitapahtuman ja pääunijakson alkamisen välinen aika.

**Tekniset vaatimukset:**
*   Visualisointi: Vaakasuora aikajana, joka näyttää tunnit kofeiinista uneen. Punainen (Living Coral `#FC6558`), jos väli on < 10h. Sininen (Ensō Blue `#A2D3E8`), jos väli on turvallinen.
*   **GraphQL Query:**
    ```graphql
    query GetCaffeineGap($start: String!, $end: String!) {
      getEventsRange(start: $start, end: $end) {
        timestamp
        type
        amount
        note
      }
    }
    ```
    *Huom: Verrataan saatua kofeiiniaikatietoa `getDayRecord` -unialkuaikaan.*

---

### Issue 10: [Feature] Alkoholitapahtuman pika-kirjaus (Fast Log)
**Kuvaus:**  
Lisätään painike alkoholiannosten nopeaan kirjaamiseen suoraan PWA-aloitusnäytöltä.

**Tekniset vaatimukset:**
*   Käyttöliittymä: Kelluva toimintapainike (FAB) tai yläpalkin "+ Alkoholi" -nappi.
*   **GraphQL Mutation:**
    ```graphql
    mutation LogAlcoholEvent($timestamp: String!, $amount: Float!, $note: String) {
      logEvent(type: alcohol, timestamp: $timestamp, amount: $amount, note: $note) {
        id
        timestamp
        type
        amount
      }
    }
    ```

---

### Issue 11: [Feature] Alkoholin vaikutuksen tulkintakortti
**Kuvaus:**  
Näytetään automaattinen tulkinta alkoholikirjauksen vaikutuksesta seuraavan yön palautumiseen (RHR ja HRV).

**Tekniset vaatimukset:**
*   Logiikka: Jos käyttäjällä on alkoholimerkintä, vertaillaan yön HRV-keskiarvoa ja alinta leposykettä peruslinjaan.
*   **GraphQL Query:**
    ```graphql
    query GetAlcoholRecoveryEffect($date: String!) {
      getDayRecord(date: $date) {
        status
        metricsJson # Sisältää alkoholivaikutusanalyysin
      }
    }
    ```

---

### Issue 12: [Feature] Päiväunien kirjaustoiminto (Nap Logging)
**Kuvaus:**  
Käyttäjä voi kirjata päiväunet ja niiden keston minuutteina.

**Tekniset vaatimukset:**
*   Käyttöliittymä: "+ Päiväunet" -pikakirjauspainike.
*   **GraphQL Mutation:**
    ```graphql
    mutation LogNapEvent($timestamp: String!, $amount: Float!, $note: String) {
      logEvent(type: nap, timestamp: $timestamp, amount: $amount, note: $note) {
        id
        timestamp
        type
        amount
      }
    }
    ```

---

### Issue 13: [Feature] Päiväunen palautusvaikutuksen analyysi (Nap Recovery Helper)
**Kuvaus:**  
Arvioi päiväunien ajoituksen ja pituuden perusteella sen vaikutusta univelkaan ja tulevaan yöuneen.

**Tekniset vaatimukset:**
*   **GraphQL Query:**
    ```graphql
    query GetNapRecovery($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # sleep.naps ja niiden ajoitus/vaikutustiedot
      }
    }
    ```

---

### Issue 14: [Feature] Recovery Cost -kuormitusmittari
**Kuvaus:**  
Näytetään päivittäiset Recovery Cost -pisteet, jotka kuvaavat kirjattujen stressitekijöiden vaikutusta.

**Tekniset vaatimukset:**
*   **GraphQL Query:**
    ```graphql
    query GetRecoveryCost($date: String!) {
      getDayRecord(date: $date) {
        metricsJson # recovery_cost pistemäärä
      }
    }
    ```

---

### Issue 15: [Feature] Viikonloppusykli-vertailu (La/Su/Ma)
**Kuvaus:**  
Toteutetaan vertailukortti, joka näyttää rinnakkain lauantain, sunnuntain ja maanantain Readiness- ja Sleep-pisteet.

**Tekniset vaatimukset:**
*   Visualisointi: Kolme rinnakkaista pylvästä (Google Charts tai CSS-grid) viikoittaisen palautumisrytmin kuvaamiseen.
*   **GraphQL Query:**
    ```graphql
    query GetWeekendCycle($start: String!, $end: String!) {
      getEventsRange(start: $start, end: $end) {
        type
        timestamp
      }
    }
    ```
    *Huom: Haetaan myös `getDayRecord` lauantaille, sunnuntaille ja maanantaille fysiologian vertailua varten.*

---

### Issue 16: [Feature] Oura-tietojen synkronoinnin käynnistys PWA-sovelluksesta (syncOuraData)
**Kuvaus:**  
Toteutetaan painike Oura-datan manuaalisen synkronoinnin käynnistämiseksi suoraan PWA-sovelluksesta. Kysely liipaisee Google Cloud Runissa sijaitsevan rikastusputken ja päivittää Firestoren JSON-tietueet.

**Tekniset vaatimukset:**
*   Käyttöliittymä: Synkronointipainike latausanimaatiolla.
*   **GraphQL Mutation:**
    ```graphql
    mutation SyncOura($date: String!) {
      syncOuraData(date: $date) {
        date
        status
        cycleState
        metricsJson
      }
    }
    ```
