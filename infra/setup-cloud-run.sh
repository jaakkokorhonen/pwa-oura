#!/usr/bin/env bash
# =============================================================================
# infra/setup-cloud-run.sh
# Perustaa Cloud Run -palvelut pwa-oura -projektille.
#
# Käyttö:
#   chmod +x infra/setup-cloud-run.sh
#   ./infra/setup-cloud-run.sh
#
# Esivaatimukset:
#   - gcloud CLI asennettu ja autentikoitu (gcloud auth login)
#   - PROJECT_ID asetettu alla tai ympäristömuuttujana
#   - Artifact Registry -repositorio luotu (tai aja setup-artifact-registry.sh ensin)
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Konfiguraatio — muuta tarvittaessa
# ---------------------------------------------------------------------------
PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-europe-north1}"          # Helsinki
ARTIFACT_REPO="pwa-oura"
IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}"

INGEST_SERVICE="oura-ingest"
GRAPHQL_SERVICE="oura-graphql"

# Firestore/MQTT -ympäristömuuttujat — täytä tai vie Secret Manageriin
MQTT_BROKER_URL="${MQTT_BROKER_URL:-mqtt://localhost:1883}"
FIREBASE_PROJECT="${PROJECT_ID}"

# ---------------------------------------------------------------------------
echo "[1/5] Asetetaan aktiivinen projekti: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

# ---------------------------------------------------------------------------
echo "[2/5] Aktivoidaan tarvittavat API:t"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com \
  cloudscheduler.googleapis.com \
  --project="${PROJECT_ID}"

# ---------------------------------------------------------------------------
echo "[3/5] Rakennetaan ja pushataan Docker-kuvat Artifact Registryyn"

# Ingest-palvelu
echo "  → Rakennetaan ${INGEST_SERVICE}"
docker build \
  -t "${IMAGE_BASE}/${INGEST_SERVICE}:latest" \
  -f services/ingest/Dockerfile \
  services/ingest/
docker push "${IMAGE_BASE}/${INGEST_SERVICE}:latest"

# GraphQL-palvelu
echo "  → Rakennetaan ${GRAPHQL_SERVICE}"
docker build \
  -t "${IMAGE_BASE}/${GRAPHQL_SERVICE}:latest" \
  -f services/graphql/Dockerfile \
  services/graphql/
docker push "${IMAGE_BASE}/${GRAPHQL_SERVICE}:latest"

# ---------------------------------------------------------------------------
echo "[4/5] Deployataan Cloud Run -palvelut"

# Ingest — tarvitsee MQTT-osoitteen ja Firestore-projektin
gcloud run deploy "${INGEST_SERVICE}" \
  --image="${IMAGE_BASE}/${INGEST_SERVICE}:latest" \
  --region="${REGION}" \
  --platform=managed \
  --no-allow-unauthenticated \
  --set-env-vars="MQTT_BROKER_URL=${MQTT_BROKER_URL},FIREBASE_PROJECT=${FIREBASE_PROJECT}" \
  --memory=256Mi \
  --cpu=1 \
  --min-instances=1 \
  --max-instances=3 \
  --port=8080

# GraphQL — julkinen endpoint (autentikointi Firebase ID Tokenilla middlewaressa)
gcloud run deploy "${GRAPHQL_SERVICE}" \
  --image="${IMAGE_BASE}/${GRAPHQL_SERVICE}:latest" \
  --region="${REGION}" \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="FIREBASE_PROJECT=${FIREBASE_PROJECT}" \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=5 \
  --port=4000

# ---------------------------------------------------------------------------
echo "[5/5] Haetaan palveluiden URL:t"
INGEST_URL=$(gcloud run services describe "${INGEST_SERVICE}" \
  --region="${REGION}" --format='value(status.url)')
GRAPHQL_URL=$(gcloud run services describe "${GRAPHQL_SERVICE}" \
  --region="${REGION}" --format='value(status.url)')

echo ""
echo "=================================================================="
echo "✅  Cloud Run -palvelut käynnissä:"
echo "   Ingest:   ${INGEST_URL}"
echo "   GraphQL:  ${GRAPHQL_URL}/graphql"
echo "=================================================================="
echo ""
echo "Seuraavat vaiheet:"
echo "  1. Tallenna GraphQL URL ympäristömuuttujaan NEXT_PUBLIC_GRAPHQL_URL"
echo "  2. Lisää MQTT_BROKER_URL Secret Manageriin (ks. infra/setup-secrets.sh)"
echo "  3. Tarkista IAM: ingest-palvelulla oikeus kirjoittaa Firestoreen"
