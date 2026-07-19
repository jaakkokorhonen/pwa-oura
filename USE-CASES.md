# Oura-sovelluksen käyttötapaukset

Tämä dokumentti kuvaa Oura-mobiiliappsin tunnetut käyttötapaukset, niiden tieteelliset taustat sekä **Oura API v2 -tietomallit** — mitä dataa kukin käyttötapaus tuottaa ja mitä kenttiä API palauttaa.

API-dokumentaatio: https://cloud.ouraring.com/v2/docs

---

## 1. Unenseuranta ja univaiheiden tunnistus

**Mitä mitataan:** Kokonaisuniaika, nukahtamisviive (Sleep Latency), unen tehokkuus (Sleep Efficiency), univaiheet (kevyt uni, syvä uni, REM).

**Miten toimii:** Oura käyttää sormesta mitattavaa fotoplethysmografiaa (PPG), kiihtyvyysanturidataa ja ihon lämpötilaa. Sleep Staging Algorithm 2.0 (OSSA 2.0) luokittelee univaiheet jatkuvasti 5 minuutin epokeissa.

**Tieteellinen tausta:** OSSA 2.0 validoitiin polysomnografiaa (PSG, kliininen kultastandardi) vastaan Tokion yliopiston 96 henkilön tutkimuksessa (421 045 epokkia). Tarkkuus 91,7–91,8 %, laitteiden välinen luotettavuus 94,8 %. Meta-analyysi (6 tutkimusta, n=388) vahvisti tulokset. Viitekehyksenä AASM:n univaiheiden luokittelukriteeristö.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/sleep`  
**Endpoint (päivätaso):** `GET /v2/usercollection/daily_sleep`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Unisession tunniste |
| `day` | date | Päivämäärä (YYYY-MM-DD) |
| `bedtime_start` | datetime | Vuoteeseen meno (ISO 8601) |
| `bedtime_end` | datetime | Heräämisaika (ISO 8601) |
| `total_sleep_duration` | integer | Kokonaisuniaika (sekuntia) |
| `time_in_bed` | integer | Vuoteessaoloaika (sekuntia) |
| `latency` | integer | Nukahtamisviive (sekuntia) |
| `efficiency` | integer | Unen tehokkuus (%) |
| `deep_sleep_duration` | integer | Syvän unen kesto (sekuntia) |
| `light_sleep_duration` | integer | Kevyen unen kesto (sekuntia) |
| `rem_sleep_duration` | integer | REM-unen kesto (sekuntia) |
| `awake_time` | integer | Hereillä oloaika (sekuntia) |
| `restless_periods` | integer | Levottomien jaksojen lukumäärä |
| `average_heart_rate` | float | Yöaikainen keskisyke (bpm) |
| `lowest_heart_rate` | integer | Yön alin syke (bpm) |
| `average_hrv` | integer | Yöaikainen HRV RMSSD (ms) |
| `average_breath` | float | Hengitystaajuus (krt/min) |
| `sleep_phase_5_min` | string | Univaihejärjestys 5 min epokeissa (1=wake, 2=REM, 3=light, 4=deep) |
| `movement_30_sec` | string | Liikesignaali 30 s epokeissa |
| `heart_rate` | object | HR-aikasarja (interval + items) |
| `hrv` | object | HRV-aikasarja (interval + items) |
| `sleep_algorithm_version` | string | Algoritmin versio (esim. "v2") |
| `readiness_score_delta` | integer | Unen vaikutus Readiness Scoreen |
| `sleep_score_delta` | integer | Muutos uniskoreen |
| `type` | enum | `long_sleep` / `rest` / `late_nap` / `nap` |

**Viitteet:**
- Chinoy et al. (2022), *Sleep*
- Tokion yliopiston validointitutkimus (2024), *JMIR*

---

## 2. Syke ja sykevälivaihtelu (HRV) yöaikaan

**Mitä mitataan:** Leposyke (RHR) ja HRV (RMSSD) yöunen aikana; myös päiväaikainen jatkuva sydämen syke.

**Miten toimii:** PPG-signaali sormesta → IBI (inter-beat interval) → RMSSD. HRV lasketaan erityisesti syvän unen ja REM-vaiheen aikana.

**Tieteellinen tausta:** Validointitutkimuksessa (n=49) HR:n korrelaatio EKG:hen r²=0,996, HRV:n r²=0,980, bias −0,63 bpm / −1,2 ms. Vuoden 2025 vertailututkimus (*The Physiological Society*) osoitti Oura Ring 4:n parhaaksi HRV- ja RHR-tarkkuudessa verrattuna WHOOP 4.0:aan, Garmin Fenix 6:een ja Polar Grit X Pro:hon.

### API v2 — tietomallit

**Endpoint (aikasarja):** `GET /v2/usercollection/heartrate`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `bpm` | integer | Syke (lyöntiä/min) |
| `source` | enum | `awake` / `rest` / `sleep` / `session` / `live` |
| `timestamp` | datetime | Mittausaika (ISO 8601) |

> Huom: HRV-aikasarja tulee `sleep`-endpointilta kentistä `average_hrv` ja `hrv.items[]`.

**Viitteet:**
- Hautala et al. (2020), *Frontiers in Physiology*
- Hinde et al. (2025), *The Physiological Society*

---

## 3. Readiness Score — päivittäinen palautumisindeksi

**Mitä mitataan:** Yhdistelmäpisteet (0–100) käyttäjän fysiologisesta valmiustilasta.

**Miten toimii:** Indeksi yhdistää lyhyen aikavälin mittarit (yön alin RHR ja sen ajoitus, ihon lämpötilan poikkeama, unenlaatu, edellisen päivän liikuntakuorma) ja vertaa niitä 14 vrk:n painotettuun liukuvaan keskiarvoon sekä 2 kuukauden peruslinjaan. Viimeiset 2–5 päivää saavat suuremman painotuksen.

**Tieteellinen tausta:** De Gruyter -katsaus (2025) tunnisti HRV:n (86 % laitteista), RHR:n (79 %), fyysisen aktiivisuuden (71 %) ja unen keston (71 %) yleisimmiksi komponenteiksi. Yksikään valmistaja ei julkaise algoritmipainojaan. Käyttäjätutkimukset (*PubMed*, 2024) osoittivat, että harjoittelijat käyttävät pisteitä harjoitusohjelman säätämiseen.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/daily_readiness`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `score` | integer | Readiness Score 0–100 |
| `temperature_deviation` | float | Lämpötilan poikkeama peruslinjasta (°C) |
| `temperature_trend_deviation` | float | Lämpötilatrendin poikkeama (°C) |
| `contributors.activity_balance` | integer | Aktiivisuustasapaino (0–100) |
| `contributors.body_temperature` | integer | Kehon lämpötila (0–100) |
| `contributors.hrv_balance` | integer | HRV-tasapaino (0–100) |
| `contributors.previous_day_activity` | integer | Edellisen päivän aktiivisuus (0–100) |
| `contributors.previous_night` | integer | Edellinen yö (0–100) |
| `contributors.recovery_index` | integer | Palautumisindeksi (0–100) |
| `contributors.resting_heart_rate` | integer | Leposyke (0–100) |
| `contributors.sleep_balance` | integer | Unitasapaino (0–100) |

**Viitteet:**
- Wallen et al. (2025), *De Gruyter*
- Exploring Regular Exercisers' Experiences with Readiness Scores (2024), *PubMed*

---

## 4. Symptom Radar — varhainen sairauden tunnistus

**Mitä mitataan:** Hengitystiesairauden fysiologiset esioireet ennen subjektiivista oirehavaitsemista.

**Miten toimii:** Algoritmi vertaa yöaikaisia RHR-, HRV-, ihon lämpötila- ja hengitystaajuusarvoja käyttäjän yksilölliseen peruslinjaan. Poikkeamat useassa mittarissa samanaikaisesti laukaisevat hälytyksen. Oura ilmoittaa ominaisuuden tunnistavan oireet jopa 2 päivää ennen käyttäjän itseraportointia.

**Tieteellinen tausta:** UCSF:n TemPredict-tutkimus (2020–2022, n=3 318) tunnisti COVID-19-oireet keskim. 2,75 päivää ennen diagnostista testausta (*Nature Scientific Reports*). DoD:n SAFER-tutkimuksessa (n=9 381) koneoppimismalli saavutti AUC 0,82.

### API v2 — tietomallit

Symptom Radar ei ole erillinen API-endpoint — se rakentuu seuraavien endpointtien yhdistelmästä:

| Signaali | Endpoint | Kenttä |
|---|---|---|
| Leposyke | `/daily_readiness` | `contributors.resting_heart_rate` |
| HRV-poikkeama | `/daily_readiness` | `contributors.hrv_balance` |
| Lämpötilapoikkeama | `/daily_readiness` | `temperature_deviation` |
| Hengitystaajuus | `/sleep` | `average_breath` |
| Aktiivisuuslasku | `/daily_activity` | `score` |

Sovellus laskee algoritmin näistä arvoista client-puolella tai Oura-pilvessä — tulosta ei palauteta suoraan APIsta erillisenä kentänä.

**Viitteet:**
- Quer et al. (2021), *Nature Scientific Reports*
- Cary et al. (2022), *PMC*

---

## 5. Kehon lämpötilan seuranta

**Mitä mitataan:** Yöaikainen ihon lämpötila ja sen poikkeama (°C) käyttäjän henkilökohtaisesta peruslinjasta.

**Miten toimii:** Infrapuna-anturi mittaa lämpötilaa jatkuvasti unen aikana. Sovellus näyttää poikkeamia peruslinjasta, ei absoluuttisia arvoja (suuri yksilöllinen vaihtelu).

**Tieteellinen tausta:** Kolme käyttötapausta: (1) **Sairauden ennakointi** — TemPredict-tutkimus. (2) **Kuukautiskierron seuranta** — progesteroni nostaa lämpötilaa 0,3–0,5 °C ovulaation jälkeen (WHO 1981 alkaen). (3) **Yleinen palautuminen** — lämpötilapoikkeama on yksi Readiness Scoren komponenteista.

### API v2 — tietomallit

Lämpötiladata tulee kahdesta paikasta:

**Endpoint (Readiness):** `GET /v2/usercollection/daily_readiness`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `temperature_deviation` | float | Poikkeama peruslinjasta (°C) |
| `temperature_trend_deviation` | float | Trendimäinen poikkeama (°C) |

> Absoluuttinen ihon lämpötila-arvo ei ole saatavilla API:n kautta — ainoastaan poikkeama.

**Viitteet:**
- Bullock et al. (2022), *UCSF / Nature Scientific Reports*

---

## 6. Liikunta-aktiivisuus ja energiankulutus

**Mitä mitataan:** Askelmäärä, aktiivisuusminuutit, MET-arvo ja päivittäinen energiankulutus (kkal).

**Miten toimii:** 3-akselinen kiihtyvyysanturi tunnistaa liikuntaa jatkuvasti. Oura tunnistaa automaattisesti yli 40 liikuntalajia ML-pohjaisesti.

**Tieteellinen tausta:** PMC-validointitutkimus (2023) osoitti Ouran suoriutuvan kohtuullisesti askelmäärässä ja energiankulutuksen arvioinnissa. Activity Balance Readiness Scoressa perustuu urheilutieteelliseen kuormitus-palautuminen-tasapainomalliin.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/daily_activity`  
**Endpoint (yksittäinen treeni):** `GET /v2/usercollection/workout`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `score` | integer | Aktiivisuuspisteet 0–100 |
| `steps` | integer | Askelmäärä |
| `active_calories` | integer | Aktiivisuuden kuluttamat kalorit (kkal) |
| `total_calories` | integer | Kokonaiskalorit (kkal) |
| `equivalent_walking_distance` | integer | Vastaava kävelymatka (metriä) |
| `high_activity_time` | integer | Kova aktiivisuus (sekuntia) |
| `medium_activity_time` | integer | Kohtalainen aktiivisuus (sekuntia) |
| `low_activity_time` | integer | Matala aktiivisuus (sekuntia) |
| `sedentary_time` | integer | Istumaistunto (sekuntia) |
| `resting_time` | integer | Lepotila (sekuntia) |
| `non_wear_time` | integer | Rengas ei käytössä (sekuntia) |
| `average_met_minutes` | float | Keskimääräinen MET-minuutit |
| `met.items[]` | float[] | MET-aikasarja (5 min epokit) |
| `target_calories` | integer | Kaloritavoite |
| `target_meters` | integer | Metritavoite |
| `inactivity_alerts` | integer | Passiivisuushälytykset (kpl) |
| `class_5_min` | string | Aktiivisuusluokka 5 min epokeissa |
| `contributors.meet_daily_targets` | integer | Päivätavoitteiden saavutus (0–100) |
| `contributors.move_every_hour` | integer | Tuntiaktiivisuus (0–100) |
| `contributors.recovery_time` | integer | Palautumisaika (0–100) |
| `contributors.stay_active` | integer | Aktiivisuuden ylläpito (0–100) |
| `contributors.training_frequency` | integer | Harjoitustiheys (0–100) |
| `contributors.training_volume` | integer | Harjoitusvolyymi (0–100) |

**Workout-endpoint lisäkentät:**

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `activity` | string | Lajityyppi (esim. `running`, `cycling`) |
| `calories` | float | Kalorit treenissä |
| `distance` | float | Matka (metriä) |
| `intensity` | enum | `easy` / `moderate` / `hard` |
| `label` | string | Käyttäjän antama nimi |
| `source` | enum | `manual` / `detected` |
| `start_datetime` | datetime | Aloitusaika |
| `end_datetime` | datetime | Lopetusaika |

**Viitteet:**
- Metsävainio & Tikkanen (2023), *PMC*

---

## 7. Resilience Score — stressinsietokyvyn indeksi

**Mitä mitataan:** Käyttäjän pitkäaikainen kyky sietää fysiologista stressiä ja palautua siitä.

**Miten toimii:** Yhdistää stressin latausmittareita (syke, HRV-muutokset päivällä) ja palautumismittareita (yöaikainen HRV, uni) useiden päivien ajalta.

**Tieteellinen tausta:** Teoreettinen perusta on allostaasin ja allostaattisen kuorman käsitteissä (McEwen, 1998). HRV toimii autonomisen hermoston palautumiskyvyn biomarkkerina. De Gruyter -katsaus (2025) tunnisti Resilience Scoren yhdeksi toimialan harvoista pitkän aikavälin yhdistelmäindekseistä.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/daily_resilience`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `level` | enum | `exceptional` / `strong` / `solid` / `adequate` / `limited` |
| `contributors.sleep_recovery` | float | Unen palautumisvaikutus |
| `contributors.daytime_recovery` | float | Päiväaikainen palautuminen |
| `contributors.stress` | float | Stressikomponentti |

**Viitteet:**
- McEwen (1998), *New England Journal of Medicine*
- Wallen et al. (2025), *De Gruyter*

---

## 8. Stressi (Daily Stress)

**Mitä mitataan:** Päivittäinen stressitaso autonomisen hermoston indikaattoreiden perusteella.

**Miten toimii:** Oura arvioi päiväaikaista stressiä syke- ja HRV-muutosten perusteella verrattuna käyttäjän peruslinjaan.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/daily_stress`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `stress_high` | integer | Korkean stressin aika (sekuntia) |
| `recovery_high` | integer | Korkean palautumisen aika (sekuntia) |
| `day_summary` | enum | `restored` / `normal` / `stressful` |

---

## 9. SpO2 — veren happikyllästyneisyys

**Mitä mitataan:** Yöaikainen veren happipitoisuus (SpO2, %).

**Miten toimii:** PPG-anturi mittaa valon absorptiota eri aallonpituuksilla (punainen + infrapuna) hemoglobiinin happikyllästymisen arvioimiseksi yön aikana.

**Tieteellinen tausta:** SpO2-lasku yöllä voi indikoida uniapneaa tai muita hengityshäiriöitä. Oura-sovelluksessa SpO2 toimii seulontamittarina — se ei korvaa kliinistä oksimetriä.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/daily_spo2`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `spo2_percentage.average` | float | Yön keskiarvo SpO2 (%) |

---

## 10. VO2 max — aerobinen kunto

**Mitä mitataan:** Maksimaalinen hapenottokyvyn arvio (ml/kg/min).

**Miten toimii:** Arvioidaan sydämen sykkeen ja liikuntaintensieetin suhteesta. Oura laskee arvion juoksulenkkien tai muun aerobisen harjoittelun HR-datasta.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/vo2_max`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `vo2_max` | float | VO2 max -arvio (ml/kg/min) |
| `timestamp` | datetime | Mittausaika |

---

## 11. Kardiovaskulaarinen ikä (Cardiovascular Age)

**Mitä mitataan:** Sydän- ja verisuonijärjestelmän arvioitu toiminnallinen ikä suhteessa kronologiseen ikään.

### API v2 — tietomallit

**Endpoint:** `GET /v2/usercollection/daily_cardiovascular_age`

| Kenttä | Tyyppi | Kuvaus |
|---|---|---|
| `id` | string | Tietueen tunniste |
| `day` | date | Päivämäärä |
| `vascular_age` | integer | Arvioitu verisuonisto-ikä (vuotta) |

---

## 12. Oura Ring 5 (2026) — uudet ominaisuudet

Kesäkuussa 2026 julkaistu Oura Ring 5 lisäsi seuraavat ominaisuudet, jotka ovat toistaiseksi tutkimus- tai kehitysvaiheessa:

| Ominaisuus | API-tila | Tieteellinen perusta |
|---|---|---|
| Verenpaineen signaali | Ei vielä APIssa | PPG-pohjainen cuffless BP-estimaatio |
| Laboratoriotulosten integraatio | Saatavilla sovelluksessa | Kliininen data + wearable-konteksti |
| GLP-1-seuranta | Kehitysvaihe | Glukagoninkaltainen peptidi-1, paino ja metabolia |
| Aivoterveystutkimus (IRB) | Rekrytointi auki | Kognitiivinen terveys + biossignaalit |

Näistä ominaisuuksista ei ole vielä julkaistu avoimia vertaisarvioituja validointitutkimuksia eikä virallisia API-endpointteja.

---

## API v2 — endpointtien yhteenveto

| Käyttötapaus | Endpoint | Avainkenttä(t) |
|---|---|---|
| Uni | `/daily_sleep`, `/sleep` | `total_sleep_duration`, `deep_sleep_duration`, `sleep_phase_5_min` |
| Syke / HRV | `/heartrate`, `/sleep` | `bpm`, `average_hrv`, `hrv.items[]` |
| Readiness | `/daily_readiness` | `score`, `contributors.*`, `temperature_deviation` |
| Symptom Radar | (yhdistelmä) | `temperature_deviation`, `average_breath`, `contributors.hrv_balance` |
| Lämpötila | `/daily_readiness` | `temperature_deviation`, `temperature_trend_deviation` |
| Aktiivisuus | `/daily_activity`, `/workout` | `steps`, `active_calories`, `met.items[]`, `activity` |
| Resilience | `/daily_resilience` | `level`, `contributors.*` |
| Stressi | `/daily_stress` | `stress_high`, `recovery_high`, `day_summary` |
| SpO2 | `/daily_spo2` | `spo2_percentage.average` |
| VO2 max | `/vo2_max` | `vo2_max` |
| Kardiovaskulaarinen ikä | `/daily_cardiovascular_age` | `vascular_age` |

---

*Päivitetty: heinäkuu 2026 — Oura API v2*
