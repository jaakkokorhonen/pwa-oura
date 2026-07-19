#!/usr/bin/env bash
# =============================================================================
# pwa-oura — Cloud Run perustaminen
# Ajettava kerran per projekti / per environment.
#
# Esiehdot:
#   - gcloud CLI asennettu ja autentikoitu
#   - Firebase-projekti olemassa
#   - .env.infra täytetty (katso .env.infra.example)
#
# Käyttö:
#   chmod +x infra/setup-cloud-run.sh
#   source .env.infra && ./infra/setup-cloud-run.sh
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Muuttujat — aseta .env.infra-tiedostossa tai vie ymptäristömuuttujina
# ---------------------------------------------------------------------------
PROJECT_ID="${GCP_PROJECT_ID}"
REGION="${GCP_REGION:-europe-north1}"
INGEST_SERVICE="oura-ingest"
GRAPHQL_SERVICE="oura-graphql"
FIREBASE_PROJECT="${FIREBASE_PROJECT_ID:-$PROJECT_ID}"
MQTT_BROKER_URL="${MQTT_BROKER_URL}"          # esim. mqtt://broker.example.com:1883
MQTT_TOPIC_PREFIX="${MQTT_TOPIC_PREFIX:-oura}" # esim. oura/user/{uid}/metrics/{type}
OURA_CLIENT_ID="${OURA_CLIENT_ID}"
OURA_CLIENT_SECRET="${OURA_CLIENT_SECRET}"

echo "⭐  Projekti : $PROJECT_ID"
echo "⭐  Alue     : $REGION"

# ---------------------------------------------------------------------------
# 1. Ota tarvittavat API:t käyttöön
# ---------------------------------------------------------------------------
echo "\n→ Otetaan GCP API:t käyttöön..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  firestore.googleapis.com \
  --project="$PROJECT_ID"

# ---------------------------------------------------------------------------
# 2. Tallenna salaisuudet Secret Manageriin
# ---------------------------------------------------------------------------
echo "\n→ Tallennetaan salaisuudet Secret Manageriin..."

echo -n "$OURA_CLIENT_ID" | gcloud secrets create oura-client-id \
  --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
  echo -n "$OURA_CLIENT_ID" | gcloud secrets versions add oura-client-id \
    --data-file=- --project="$PROJECT_ID"

echo -n "$OURA_CLIENT_SECRET" | gcloud secrets create oura-client-secret \
  --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
  echo -n "$OURA_CLIENT_SECRET" | gcloud secrets versions add oura-client-secret \
    --data-file=- --project="$PROJECT_ID"

echo -n "$MQTT_BROKER_URL" | gcloud secrets create mqtt-broker-url \
  --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
  echo -n "$MQTT_BROKER_URL" | gcloud secrets versions add mqtt-broker-url \
    --data-file=- --project="$PROJECT_ID"

# ---------------------------------------------------------------------------
# 3. Service Account ingest-palvelulle
# ---------------------------------------------------------------------------
INGEST_SA="oura-ingest-sa@${PROJECT_ID}.iam.gserviceaccount.com"
echo "\n→ Luodaan service account: $INGEST_SA"
gcloud iam service-accounts create oura-ingest-sa \
  --display-name="Oura Ingest Service" \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (jo olemassa)"

# Oikeudet: Firestore + Secret Manager
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$INGEST_SA" \
  --role="roles/datastore.user" --condition=None

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$INGEST_SA" \
  --role="roles/secretmanager.secretAccessor" --condition=None

# ---------------------------------------------------------------------------
# 4. Service Account GraphQL-palvelulle
# ---------------------------------------------------------------------------
GRAPHQL_SA="oura-graphql-sa@${PROJECT_ID}.iam.gserviceaccount.com"
echo "\n→ Luodaan service account: $GRAPHQL_SA"
gcloud iam service-accounts create oura-graphql-sa \
  --display-name="Oura GraphQL Service" \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (jo olemassa)"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$GRAPHQL_SA" \
  --role="roles/datastore.user" --condition=None

# ---------------------------------------------------------------------------
# 5. Deploy ingest-palvelu Cloud Runiin
#    HUOM: rakentaa imagen Cloud Buildilla suoraan lähdekoodista
# ---------------------------------------------------------------------------
echo "\n→ Deploytaan $INGEST_SERVICE ..."
gcloud run deploy "$INGEST_SERVICE" \
  --source="./services/ingest" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --service-account="$INGEST_SA" \
  --no-allow-unauthenticated \
  --set-env-vars="FIREBASE_PROJECT=$FIREBASE_PROJECT,MQTT_TOPIC_PREFIX=$MQTT_TOPIC_PREFIX" \
  --set-secrets="OURA_CLIENT_ID=oura-client-id:latest,OURA_CLIENT_SECRET=oura-client-secret:latest,MQTT_BROKER_URL=mqtt-broker-url:latest" \
  --memory="512Mi" \
  --cpu="1" \
  --min-instances="1" \
  --max-instances="10" \
  --port="8080"

# ---------------------------------------------------------------------------
# 6. Deploy GraphQL-palvelu Cloud Runiin
# ---------------------------------------------------------------------------
echo "\n→ Deploytaan $GRAPHQL_SERVICE ..."
gcloud run deploy "$GRAPHQL_SERVICE" \
  --source="./services/graphql" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --service-account="$GRAPHQL_SA" \
  --allow-unauthenticated \
  --set-env-vars="FIREBASE_PROJECT=$FIREBASE_PROJECT" \
  --memory="256Mi" \
  --cpu="1" \
  --min-instances="0" \
  --max-instances="10" \
  --port="4000"

# ---------------------------------------------------------------------------
# 7. Tulosta palvelujen URL:t
# ---------------------------------------------------------------------------
echo "\n✅ Valmis!"
INGEST_URL=$(gcloud run services describe "$INGEST_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format="value(status.url)")
GRAPHQL_URL=$(gcloud run services describe "$GRAPHQL_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format="value(status.url)")

echo "  Ingest URL  : $INGEST_URL"
echo "  GraphQL URL : $GRAPHQL_URL"
echo ""
echo "Muista lisätä GraphQL URL Firebase Hosting rewrites -sääntöön (firebase.json):"
echo '  { "source": "/graphql", "run": { "serviceId": "oura-graphql" } }'
