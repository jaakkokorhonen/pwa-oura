#!/usr/bin/env bash
# =============================================================================
# infra/setup-artifact-registry.sh
# Luo Artifact Registry -repositorion Docker-kuville.
# Aja kerran ennen setup-cloud-run.sh:ta.
# =============================================================================
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-europe-north1}"
REPO_NAME="pwa-oura"

gcloud config set project "${PROJECT_ID}"

gcloud services enable artifactregistry.googleapis.com --project="${PROJECT_ID}"

# Luo repositorio jos ei ole olemassa
if ! gcloud artifacts repositories describe "${REPO_NAME}" \
     --location="${REGION}" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="pwa-oura Docker images" \
    --project="${PROJECT_ID}"
  echo "✅  Artifact Registry repositorio luotu: ${REPO_NAME}"
else
  echo "ℹ️   Repositorio '${REPO_NAME}' on jo olemassa."
fi

# Autentikoi Docker Artifact Registryyn
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "Voit nyt ajaa: ./infra/setup-cloud-run.sh"
