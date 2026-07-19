# Oura-sovelluksen käyttötapaukset

Tämä dokumentti kuvaa Oura-mobiiliappsin tunnetut käyttötapaukset ja niiden tieteelliset taustat.

---

## 1. Unenseuranta ja univaiheiden tunnistus

**Mitä mitataan:** Kokonaisuniaika, nukahtamisviive (Sleep Latency), unen tehokkuus (Sleep Efficiency), univaiheet (kevyt uni, syvä uni REM).

**Miten toimii:** Oura käyttää sormesta mitattavaa fotoplethysmografiaa (PPG), kiihtyvyysanturidataa ja ihon lämpötilaa. Sleep Staging Algorithm 2.0 (OSSA 2.0) luokittelee univaiheet jatkuvasti 5 minuutin epokeissa.

**Tieteellinen tausta:** OSSA 2.0 validoitiin polysomnografiaa (PSG, kliininen kultastandardi) vastaan Tokion yliopiston 96 henkilön tutkimuksessa, jossa analysoitiin 421 045 epokkia. Kokonaisunipituudessa, syvän unen ajassa ja heräämisviiveessä ei havaittu tilastollisesti merkitseviä eroja. Laitteiden välinen luotettavuus oli 94,8 % ja tarkkuus 91,7–91,8 %. Meta-analyysi (6 tutkimusta, n=388) vahvisti tulokset myös muissa väestöissä. Tieteellisenä viitekehyksenä toimii AASM:n (American Academy of Sleep Medicine) univaiheiden luokittelukriteeristö.

**Viitteet:**
- Chinoy et al. (2022), *Sleep* — PSG-validointi Gen3:lle
- de Zambotti et al. (2019), *Sleep Medicine Reviews* — yleinen PPG-pohjainen unenseuranta
- Tokion yliopiston validointitutkimus (2024), *JMIR*

---

## 2. Syke ja sykevälivaihtelu (HRV) yöaikaan

**Mitä mitataan:** Leposyke (RHR, Resting Heart Rate) ja HRV (RMSSD-metriikka) yöunen aikana.

**Miten toimii:** Sormesta mitattava PPG-signaali muunnetaan sydämen lyöntiväleiksi infrapunavaloantureiden avulla. HRV lasketaan RMSSD-menetelmällä (Root Mean Square of Successive Differences) erityisesti syvän unen ja REM-vaiheen aikana.

**Tieteellinen tausta:** Validointitutkimuksessa (n=49, ikäjakauma 15–72 v.) yöaikaisen HR:n korrelaatio EKG-goldstandardiin oli r²=0,996 ja HRV:n r²=0,980 — bias vain −0,63 bpm ja −1,2 ms. Vuoden 2025 vertailututkimus (*The Physiological Society*) osoitti Oura Ring 4:n ja Gen3:n parhaaksi HRV- ja RHR-tarkkuudessa verrattuna WHOOP 4.0:aan, Garmin Fenix 6:een ja Polar Grit X Pro:hon kotioloissa. Teoreettinen perusta pohjaa autonomisen hermoston vaihtelun malleihin: korkea HRV heijastaa parasympaattisen järjestelmän dominanssia ja palautumistilaa.

**Viitteet:**
- Hautala et al. (2020), *Frontiers in Physiology* — yöaikainen HR/HRV-validointi
- Hinde et al. (2025), *The Physiological Society* — kuluttajalaitteiden vertailu

---

## 3. Readiness Score – päivittäinen palautumisindeksi

**Mitä mitataan:** Yhdistelmäpisteet (0–100) kuvaamaan käyttäjän fysiologista valmiustilaa.

**Miten toimii:** Indeksi yhdistää lyhyen aikavälin mittarit (yön alin RHR ja sen ajoitus, ihon lämpötilan poikkeama peruslinjasta, unenlaatu, edellisen päivän liikuntakuorma) ja vertaa niitä 14 vrk:n painotettuun liukuvaan keskiarvoon sekä 2 kuukauden pitkän aikavälin peruslinjaan. Viimeiset 2–5 päivää saavat suuremman painotuksen.

**Tieteellinen tausta:** De Gruyter -katsaus (2025) tunnisti HRV:n (86 % laitteista), RHR:n (79 %), fyysisen aktiivisuuden (71 %) ja unen keston (71 %) toimialan yhdistelmäindeksien yleisimmiksi komponenteiksi, mutta yksikään valmistaja ei julkaise algoritmipainojaan avoimesti. Käyttäjätutkimukset (*Journal of Sports Sciences*, 2024) osoittivat, että harjoittelijat käyttävät Readiness-pisteitä harjoitusohjelman säätämiseen, yhdistäen ne koettuun itsetuntemukseen.

**Viitteet:**
- Wallen et al. (2025), *De Gruyter* — kuluttajalaitteiden yhdistelmäindeksien evaluointi
- Exploring Regular Exercisers' Experiences with Readiness Scores (2024), *PubMed*

---

## 4. Symptom Radar – varhainen sairauden tunnistus

**Mitä mitataan:** Hengitystiesairauden fysiologiset esioireet ennen subjektiivista oirehavaitsemista.

**Miten toimii:** Algoritmi vertaa yöaikaisia RHR-, HRV-, ihon lämpötila- ja hengitystaajuusarvoja käyttäjän yksilölliseen peruslinjaan. Poikkeamat useassa mittarissa samanaikaisesti laukaisevat Symptom Radar -hälytyksen. Oura ilmoittaa ominaisuuden tunnistavan oireet jopa 2 päivää ennen käyttäjän itseraportointia.

**Tieteellinen tausta:** UCSF:n TemPredict-tutkimus (2020–2022, n=3 318 osallistujaa) osoitti, että Oura-biossignaalit tunnistivat COVID-19-oireiden alkamisen keskimäärin 2,75 päivää ennen diagnostista testausta — tulokset julkaistiin *Nature Scientific Reports* -lehdessä. Scripps Researchin DETECT-tutkimus vahvisti vastaavasti RHR:n, unen ja aktiivisuuden yhdistelmän parantavan influenssakaltaisten sairauksien tunnistamista. Lisäksi DoD:n SAFER-tutkimuksessa (n=9 381, Oura + Garmin) koneoppimismalli ennusti SARS-CoV-2-infektion ennen testausta AUC-arvolla 0,82.

**Viitteet:**
- Quer et al. (2021), *Nature Scientific Reports* — TemPredict-tutkimus
- Mishra et al. (2020), *Nature Biomedical Engineering* — DETECT-tutkimus
- Cary et al. (2022), *PMC* — DoD SAFER-tutkimus

---

## 5. Kehon lämpötilan seuranta

**Mitä mitataan:** Yöaikainen ihon lämpötila (Skin Temperature) ja sen poikkeama käyttäjän henkilökohtaisesta peruslinjasta (°C).

**Miten toimii:** Infrapuna-anturi mittaa lämpötilaa jatkuvasti unen aikana. Sovellus näyttää trendejä ja poikkeamia, ei absoluuttisia arvoja (joilla on suuri yksilöllinen vaihtelu).

**Tieteellinen tausta:** Lämpötilaseuranta toimii kolmessa käyttötapauksessa tieteellisin perustein: (1) **Sairausdepunistus** — TemPredict-tutkimus osoitti, että lämpötilan nousu yli yksilöllisen peruslinjan ennakoi sairautta. (2) **Kuukautiskierron seuranta** — luteaalivaiheessa progesteroni nostaa kehon lämpötilaa 0,3–0,5 °C ovulaation jälkeen (klassinen basaalilämpötilaseurannan kirjallisuus, WHO 1981 alkaen). (3) **Yleinen palautuminen** — yöaikainen lämpötilapoikkeama on yksi Readiness Scoren komponenteista.

**Viitteet:**
- Bullock et al. (2022), *UCSF / Nature Scientific Reports* — lämpötila sairauden ennakoinnissa
- WHO (1981) & klassinen basaalilämpötilakirjallisuus — kierron vaiheiden tunnistus

---

## 6. Liikunta-aktiivisuus ja energiankulutus

**Mitä mitataan:** Askelmäärä, aktiivisuusminuutit, MET-arvo (Metabolic Equivalent of Task) ja päivittäinen energiankulutus (kJ/kcal).

**Miten toimii:** 3-akselinen kiihtyvyysanturi tunnistaa liikuntaa jatkuvasti. Oura tunnistaa automaattisesti yli 40 liikuntalajia ML-pohjaisesti.

**Tieteellinen tausta:** PMC-validointitutkimus (2023) totesi, että kaupalliset aktiivisuusmittarit ovat yleisesti vähemmän validoituja kuin tutkimuslaitteistot, mutta Oura suoriutui kohtuullisesti askelmäärässä ja kokonaiskalorien arvioinnissa. Activity Balance -komponentti Readiness Scoressa seuraa harjoituskuorman suhdetta pitkäaikaiseen tasoon — teoriapohja on urheilutieteellisessä kuormitus-palautuminen-tasapainomallissa.

**Viitteet:**
- Metsävainio & Tikkanen (2023), *PMC* — Oura-askelmäärän ja energiankulutuksen validointi

---

## 7. Resilience Score – stressinsietokyvyn indeksi (uudempi ominaisuus)

**Mitä mitataan:** Käyttäjän pitkäaikainen kyky sietää fysiologista stressiä ja palautua siitä.

**Miten toimii:** Resilience Score yhdistää stressin latausmittareita (syke, HRV-muutokset päivällä) ja palautumismittareita (yöaikainen HRV, uni) useamman päivän ajalta.

**Tieteellinen tausta:** Teoreettinen perusta on allostaasin ja allostaattisen kuorman käsitteissä (McEwen, 1998), jotka kuvaavat elimistön pitkäaikaista sopeutumista stressiin. HRV toimii tässä autonomisen hermoston palautumiskyvyn biomarkkerina. De Gruyter -katsaus (2025) tunnisti Resilience Scoren yhdeksi toimialan harvoista pitkän aikavälin yhdistelmäindekseistä.

**Viitteet:**
- McEwen (1998), *New England Journal of Medicine* — allostaasin teoria
- Wallen et al. (2025), *De Gruyter* — Resilience Score osana kuluttajalaitevertailua

---

## 8. Oura Ring 5 (2026) – tulevat ominaisuudet

Kesäkuussa 2026 julkaistu Oura Ring 5 lisäsi seuraavat ominaisuudet, jotka ovat toistaiseksi tutkimus- tai kehitysvaiheessa:

| Ominaisuus | Tila | Tieteellinen perusta |
|---|---|---|
| Verenpaineen signaali (Blood Pressure Signal) | Tutkimusvaihe | PPG-pohjainen cuffless BP-estimaatio |
| Laboratoriotulosten integraatio | Saatavilla | Kliininen data + wearable-konteksti |
| GLP-1-seuranta | Kehitysvaihe | Glukagoninkaltainen peptidi-1, paino ja metabolia |
| Aivoterveystutkimus (IRB-hyväksytty) | Rekrytointi auki | Kognitiivinen terveys + biossignaalit |

Näistä ominaisuuksista ei ole vielä julkaistu avoimia vertaisarvioituja validointitutkimuksia.

---

*Päivitetty: heinäkuu 2026*
