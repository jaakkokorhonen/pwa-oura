#!/usr/bin/env bash
# =============================================================================
# infra/deploy-ingest.sh
# Nopea uudelleendeploy pelkälle ingest-palvelulle (ilman GraphQL-uudelleenrakennusta).
# Käyttö: ./infra/deploy-ingest.sh [image-tag]
# =============================================================================
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-europe-north1}"
ARTIFACT_REPO="pwa-oura"
SERVICE="oura-ingest"
TAG="${1:-latest}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${SERVICE}:${TAG}"

gcloud config set project "${PROJECT_ID}"

echo "→ Rakennetaan: ${IMAGE}"
docker build -t "${IMAGE}" -f services/ingest/Dockerfile services/ingest/
docker push "${IMAGE}"

echo "→ Deployataan Cloud Run: ${SERVICE} @ ${REGION}"
gcloud run deploy "${SERVICE}" \
  --image="${IMAGE}" \
  --region="${REGION}" \
  --platform=managed

echo "✅  ${SERVICE} päivitetty."
