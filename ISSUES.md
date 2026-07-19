# GitHub Issues: Oura Weekly Cycle PWA (GitHub Pages Compatible)

Tämä tiedosto sisältää kuvaukset 15 issuelle, jotka on sovitettu toimimaan puhtaasti staattisessa PWA-ympäristössä (esim. GitHub Pages -isännöinti), jossa ei käytetä erillistä GraphQL-palvelinta. Tiedot tallennetaan suoraan client-side Firebase Firestore SDK:lla ja synkronoidaan Oura API:n ja BigQueryn kanssa selaimesta käsin.

---

### Issue 1: [Feature] Readiness-kortti (Valmiuspisteet)
**Kuvaus:**  
Toteutetaan etusivun päävalmiuskortti, joka lukee käyttäjän päivittäisen valmiuspisteen suoraan Firestoresta (`/users/{email}/records/{date}`).

**Tekniset vaatimukset (GitHub Pages):**
*   Komponentti: Helsinki Blue Glass (`rgba(47, 74, 115, 0.15)`) pyöristetyillä kulmilla (`border-radius: 16px`).
*   Värilogiikka: 
    *   `score >= 85`: Ensō Blue (`#A2D3E8`) - Optimaalinen.
    *   `70 <= score < 85`: Sandstone (`#E6DED3`) - Kohtalainen.
    *   `score < 70`: Living Coral (`#FC6558`) - Huomioitavaa.
*   Ladataan Firestoresta reaaliaikaisella kuuntelijalla (`onSnapshot`).

---

### Issue 2: [Feature] Readiness Contributors -paneeli
**Kuvaus:**  
Toteutetaan Readiness-kortin alle avautuva paneeli, joka visualisoi valmiuteen vaikuttavat osatekijät (leposyke, HRV-tasapaino, lämpötilapoikkeama, aktiivisuuskuorma).

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Vaakasuuntaiset edistymispalkit (Progress Bars) käyttäen Sandstone- ja Ensō Blue -sävyjä.
*   Data: `DayRecord.metricsJson.contributors` Firestoresta.

---

### Issue 3: [Feature] Unen kestoindikaattori (Sleep Duration Card)
**Kuvaus:**  
Näytetään pääunijakson pituus tunteina ja minuutteina suhteessa asetettuun unitavoitteeseen.

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Rengaskaavio tai edistymispalkki (Ensō Blue `#A2D3E8`), joka kuvaa prosentuaalista tavoitteen saavuttamista.
*   Lähde: `metrics.sleep.duration` Firestoren päivittäisestä tietueesta.

---

### Issue 4: [Feature] Unitehokkuus-mittari (Sleep Efficiency)
**Kuvaus:**  
Näytetään unitehokkuusprosentti (aika unessa vs. aika sängyssä).

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Pieni numerokortti taustapalkilla.
*   Laskenta: `(total_sleep_duration / time_in_bed) * 100` suoraan asiakasohjelmassa, jos arvoa ei ole esilaskettu Firestore-tietueessa.

---

### Issue 5: [Feature] REM-unen kesto ja osuus
**Kuvaus:**  
Visualisoidaan REM-unen kesto ja sen osuus kokonaisuniajasta.

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Osio vaaka-palkissa, joka näyttää unijakauman (REM-osuus värillä `#A2D3E8` 0.7 opasiteetilla).
*   Data: `metrics.sleep.rem_sleep_duration`.

---

### Issue 6: [Feature] Syvän unen kesto ja osuus
**Kuvaus:**  
Visualisoidaan syvän unen kesto ja sen osuus fysiologisen palautumisen indikaattorina.

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Osa unijakaumapalkkia.
*   Data: `metrics.sleep.deep_sleep_duration`.

---

### Issue 7: [Feature] Yöaikainen HRV-trendiviiva
**Kuvaus:**  
Toteutetaan yönaikaisen sykevälivaihtelun (HRV) kulkua kuvaava trendiviiva.

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Google Charts LineChart tai kevyt Chart.js-integraatio tummalla teemalla.
*   Data: Haetaan Firestoren kautta JSON-aikasarjasta `hrv.items[]` tai suoraan BigQuery REST API:n kautta selaimesta Google SSO -tokenilla.

---

### Issue 8: [Feature] Alin leposyke (Resting HR)
**Kuvaus:**  
Näytetään yön alin syke ja indikaatio siitä, kuinka varhain yön aikana alin syke saavutettiin (palautumisen ajoitus).

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Numerokortti ja pieni huomioteksti ("Leposyke laski alimmilleen klo 03:15").
*   Data: `metrics.sleep.lowest_heart_rate`.

---

### Issue 9: [Feature] Kofeiini-ikkuna ja Gap-näyttö
**Kuvaus:**  
Visualisoidaan viimeisen kofeiinitapahtuman ja pääunijakson alkamisen välinen aika.

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Vaakasuora aikajana, joka laskee ja näyttää tunnit kofeiinista uneen.
*   Väritys: Punainen (Living Coral `#FC6558`), jos väli on < 10h. Sininen (Ensō Blue `#A2D3E8`), jos väli on suositeltu.
*   Laskenta: Asiakasohjelma hakee Firestoresta viimeisen `caffeine` -tapahtuman aikaleiman ja vertaa sitä unijakson alkuaikaan.

---

### Issue 10: [Feature] Alkoholitapahtuman pika-kirjaus (Fast Log)
**Kuvaus:**  
Lisätään painike alkoholiannosten nopeaan kirjaamiseen suoraan PWA-aloitusnäytöltä.

**Tekniset vaatimukset (GitHub Pages):**
*   Käyttöliittymä: Kelluva toimintapainike (FAB) tai yläpalkin "+ Alkoholi" -nappi. Avaa modalin annosten lukumäärälle.
*   Tallennus: Kirjoittaa suoraan Firestore-kokoelmaan `/users/{email}/events` dokumentin:
    ```json
    {
      "type": "alcohol",
      "timestamp": "ISO-TIMESTAMP",
      "amount": 2.0,
      "unit": "annos",
      "note": "PWA pika-kirjaus"
    }
    ```

---

### Issue 11: [Feature] Alkoholin vaikutuksen tulkintakortti
**Kuvaus:**  
Näytetään automaattinen tulkinta alkoholikirjauksen vaikutuksesta seuraavan yön palautumiseen (RHR ja HRV).

**Tekniset vaatimukset (GitHub Pages):**
*   Logiikka: Jos käyttäjä on kirjannut alkoholia edellisenä iltana, vertaillaan yön HRV-keskiarvoa ja alinta leposykettä 14 päivän keskiarvoon.
*   Visualisointi: Varoituskortti Living Coral -reunuksella.

---

### Issue 12: [Feature] Päiväunien kirjaustoiminto (Nap Logging)
**Kuvaus:**  
Käyttäjä voi kirjata päiväunet ja niiden keston minuutteina.

**Tekniset vaatimukset (GitHub Pages):**
*   Käyttöliittymä: "+ Päiväunet" -pikakirjauspainike.
*   Tallennus: Kirjoittaa Firestore-kokoelmaan `/users/{email}/events` tyypillä `nap`.

---

### Issue 13: [Feature] Päiväunen palautusvaikutuksen analyysi (Nap Recovery Helper)
**Kuvaus:**  
Arvioi päiväunien ajoituksen ja pituuden perusteella sen vaikutusta univelkaan ja tulevaan yöuneen.

**Tekniset vaatimukset (GitHub Pages):**
*   Sääntö: Jos päiväuni on kirjattu ennen klo 15:00 ja kesto on 15-25 minuuttia, näytetään positiivinen Ensō Blue -palaute (voimalaite). Muussa tapauksessa näytetään suositus lyhentää tai siirtää unia.

---

### Issue 14: [Feature] Recovery Cost -kuormitusmittari
**Kuvaus:**  
Näytetään päivittäiset Recovery Cost -pisteet, jotka kuvaavat kirjattujen stressitekijöiden (kofeiini liian myöhään, alkoholi jne.) vaikutusta.

**Tekniset vaatimukset (GitHub Pages):**
*   Laskenta: Asiakasohjelma laskee pisteet suoraan selaimessa tai lukee ne `weekly-cycle-oura-skill`:n Firestoreen kirjoittamasta `recovery_cost`-kentästä.

---

### Issue 15: [Feature] Viikonloppusykli-vertailu (La/Su/Ma)
**Kuvaus:**  
Toteutetaan vertailukortti, joka näyttää rinnakkain lauantain, sunnuntain ja maanantain Readiness- ja Sleep-pisteet.

**Tekniset vaatimukset (GitHub Pages):**
*   Visualisointi: Kolme rinnakkaista pylvästä (Google Charts tai CSS-grid), jotka havainnollistavat viikoittaista palautumisrytmiä.
*   Data: Haetaan Firestoresta viikonlopun ja maanantain tietueet yhdellä kyselyllä.
