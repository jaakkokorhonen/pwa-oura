#!/usr/bin/env bash
# =============================================================================
# pwa-oura — Cloud Run -palvelujen poistaminen
# Käytä varoen — poistaa ingest- ja graphql-palvelut!
# =============================================================================
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID}"
REGION="${GCP_REGION:-europe-north1}"

echo "⚠ï¸  Poistetaan Cloud Run -palvelut projektista $PROJECT_ID (alue: $REGION)"
read -p "Oletko varma? (kirjoita 'kyllä'): " confirm
[[ "$confirm" == "kyllä" ]] || { echo "Keskeytetty."; exit 1; }

gcloud run services delete oura-ingest \
  --region="$REGION" --project="$PROJECT_ID" --quiet

gcloud run services delete oura-graphql \
  --region="$REGION" --project="$PROJECT_ID" --quiet

echo "✅ Palvelut poistettu."
