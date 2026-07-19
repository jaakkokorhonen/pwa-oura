#!/usr/bin/env bash
# =============================================================================
# infra/deploy-graphql.sh
# Nopea uudelleendeploy pelkälle GraphQL-palvelulle.
# Käyttö: ./infra/deploy-graphql.sh [image-tag]
# =============================================================================
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-europe-north1}"
ARTIFACT_REPO="pwa-oura"
SERVICE="oura-graphql"
TAG="${1:-latest}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${SERVICE}:${TAG}"

gcloud config set project "${PROJECT_ID}"

echo "→ Rakennetaan: ${IMAGE}"
docker build -t "${IMAGE}" -f services/graphql/Dockerfile services/graphql/
docker push "${IMAGE}"

echo "→ Deployataan Cloud Run: ${SERVICE} @ ${REGION}"
gcloud run deploy "${SERVICE}" \
  --image="${IMAGE}" \
  --region="${REGION}" \
  --platform=managed

echo "✅  ${SERVICE} päivitetty."
