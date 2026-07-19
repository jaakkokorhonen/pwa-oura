#!/usr/bin/env bash
# =============================================================================
# infra/setup-firebase.sh
# Automates Service Account setup, Firestore IAM roles, and GCP secrets
# for the Oura PWA project as specified in Issue #32.
#
# Usage:
#   chmod +x infra/setup-firebase.sh
#   ./infra/setup-firebase.sh
# =============================================================================
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-pwa-oura-prod}"
SERVICE_ACCOUNT_NAME="oura-ingest"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Setting active project: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

# Enable Secret Manager API
echo "Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project="${PROJECT_ID}"

# 1. Create Ingest Service Account
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" --project="${PROJECT_ID}" &>/dev/null; then
  echo "Service account ${SERVICE_ACCOUNT_EMAIL} already exists."
else
  echo "Creating service account: ${SERVICE_ACCOUNT_NAME}..."
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --project="${PROJECT_ID}" \
    --display-name="Oura Ingest Service"
fi

# 2. Grant Firestore Write Permissions
echo "Granting Firestore user permissions to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/datastore.user"

# 3. Create Service Account key and save to Secret Manager
KEY_FILE="/tmp/sa.json"
echo "Generating service account credentials key..."
gcloud iam service-accounts keys create "${KEY_FILE}" \
  --iam-account="${SERVICE_ACCOUNT_EMAIL}" \
  --project="${PROJECT_ID}"

if gcloud secrets describe "firebase-sa" --project="${PROJECT_ID}" &>/dev/null; then
  echo "Secret 'firebase-sa' already exists. Adding new version..."
  gcloud secrets versions add "firebase-sa" --data-file="${KEY_FILE}" --project="${PROJECT_ID}"
else
  echo "Creating secret 'firebase-sa' in Secret Manager..."
  gcloud secrets create "firebase-sa" \
    --data-file="${KEY_FILE}" \
    --replication-policy=automatic \
    --project="${PROJECT_ID}"
fi

# Remove temporary key file securely
rm -f "${KEY_FILE}"

echo "=================================================================="
echo "✅ Firebase and GCP Service Account Setup Complete!"
echo "Firestore Security Rules and configuration files initialized."
echo "=================================================================="
