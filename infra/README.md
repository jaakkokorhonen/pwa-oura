# infra/ — Cloud Run -infrastruktuuriskriptit

Tämä kansio sisältää shell-skriptit `pwa-oura`-projektin GCP-infrastruktuurin pystyttämiseen.

## Palvelut

| Palvelu | Cloud Run -nimi | Portti | Rooli |
|---|---|---|---|
| MQTT → Firestore ingest | `oura-ingest` | 8080 | Tilaa MQTT-topicit, kirjoittaa Firestoreen |
| GraphQL API | `oura-graphql` | 4000 | Apollo Server, lukee Firestorea, vaatii Firebase ID Token |

## Järjestys ensiasennuksessa

```bash
# 1. Luo Artifact Registry -repositorio (kerran)
chmod +x infra/*.sh
./infra/setup-artifact-registry.sh

# 2. Tallenna salaisuudet Secret Manageriin
./infra/setup-secrets.sh

# 3. Rakenna kuvat ja deployaa molemmat palvelut
./infra/setup-cloud-run.sh
```

## Päivitys yksittäiselle palvelulle

```bash
# Vain ingest
./infra/deploy-ingest.sh

# Vain GraphQL (vaihtoehtoinen tagi)
./infra/deploy-graphql.sh v1.2.3
```

## Ympäristömuuttujat

| Muuttuja | Pakollinen | Oletusarvo | Kuvaus |
|---|---|---|---|
| `GCP_PROJECT_ID` | ✅ | `your-gcp-project-id` | GCP-projektin tunnus |
| `GCP_REGION` | | `europe-north1` | GCP-alue (Helsinki) |
| `MQTT_BROKER_URL` | ✅ ingest | — | MQTT-brokerin URL, esim. `mqtts://...` |

## Liittyy

- Issue #24 — MQTT → Firestore ingest-palvelu
- Issue #25 — GraphQL API
- Issue #28 — Google SSO + Oura OAuth
- Issue #22 — ADR arkkitehtuuripäätöksestä
