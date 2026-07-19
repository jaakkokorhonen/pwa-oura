#!/usr/bin/env bash
# =============================================================================
# infra/setup-secrets.sh
# Luo Secret Manager -salaisuudet Cloud Run -palveluille.
#
# Salaisuudet:
#   - mqtt-broker-url      : MQTT-brokerin yhteysosoite (esim. mqtts://...)
#   - oura-oauth-client-id : Oura API OAuth 2.0 client ID
#   - oura-oauth-client-secret : Oura API OAuth 2.0 client secret
# =============================================================================
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"

gcloud config set project "${PROJECT_ID}"
gcloud services enable secretmanager.googleapis.com --project="${PROJECT_ID}"

create_or_update_secret() {
  local NAME=$1
  local PROMPT=$2

  echo -n "${PROMPT}: "
  read -rs VALUE
  echo ""

  if gcloud secrets describe "${NAME}" --project="${PROJECT_ID}" &>/dev/null; then
    echo "${VALUE}" | gcloud secrets versions add "${NAME}" --data-file=- --project="${PROJECT_ID}"
    echo "  ↳ Päivitetty: ${NAME}"
  else
    echo "${VALUE}" | gcloud secrets create "${NAME}" \
      --data-file=- \
      --replication-policy=automatic \
      --project="${PROJECT_ID}"
    echo "  ↳ Luotu: ${NAME}"
  fi
}

create_or_update_secret "mqtt-broker-url"           "MQTT Broker URL (esim. mqtts://broker.example.com:8883)"
create_or_update_secret "oura-oauth-client-id"      "Oura OAuth 2.0 Client ID"
create_or_update_secret "oura-oauth-client-secret"  "Oura OAuth 2.0 Client Secret"

echo ""
echo "✅  Salaisuudet luotu/päivitetty."
echo ""
echo "Lisää Cloud Run -palveluille pääsyoikeus salaisuuksiin:"
echo "  gcloud projects add-iam-policy-binding ${PROJECT_ID} \\"
echo "    --member=serviceAccount:<CLOUD-RUN-SA>@${PROJECT_ID}.iam.gserviceaccount.com \\"
echo "    --role=roles/secretmanager.secretAccessor"
