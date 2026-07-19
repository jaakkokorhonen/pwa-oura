# infra/ — Cloud Run -perustaminen

Tämä hakemisto sisältää shell-skriptit `pwa-oura`-backendin perustamiseen Google Cloud Runiin.

## Palvelut

| Palvelu | Polku | Kuvaus |
|---|---|---|
| `oura-ingest` | `services/ingest/` | Pollaa Oura API v2:ta, lähettää MQTT:lle, kirjoittaa Firestoreen |
| `oura-graphql` | `services/graphql/` | GraphQL-API Firestore-datan päällä |

## Käyttö

```bash
# 1. Kopioi ymptäristömuuttujat
cp infra/.env.infra.example .env.infra
# Täytä arvot .env.infra-tiedostoon

# 2. Aja setup
chmod +x infra/setup-cloud-run.sh infra/teardown-cloud-run.sh
source .env.infra && ./infra/setup-cloud-run.sh
```

## Esiehdot

- `gcloud` CLI asennettu: https://cloud.google.com/sdk/docs/install
- Autentikoitu: `gcloud auth login && gcloud auth application-default login`
- Firebase-projekti olemassa
- Oura API OAuth -sovellus rekisteröity: https://cloud.ouraring.com/oauth/applications

## Hakemistorakenne

```
infra/
├── setup-cloud-run.sh       # Perustaa molemmat palvelut
├── teardown-cloud-run.sh    # Poistaa palvelut
├── .env.infra.example       # Ymptäristömuuttujien malli
└── README.md                # Tämä tiedosto
```

## Liittyy issueihin

- [#22](../../../issues/22) ADR: arkkitehtuuripäätös
- [#24](../../../issues/24) MQTT → Firestore ingest-palvelu
- [#25](../../../issues/25) GraphQL-skeema ja resolverit
- [#28](../../../issues/28) Autentikointi
