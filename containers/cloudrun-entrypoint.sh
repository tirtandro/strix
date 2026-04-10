#!/bin/bash
set -e

# Configuration
CAIDO_PORT=48080
CAIDO_LOG="/tmp/caido_startup.log"
export TOOL_SERVER_PORT=48081
export STRIX_SANDBOX_MODE=true
export PYTHONPATH=/app
export HOME=/home/pentester

echo "[INFO] Starting Caido Proxy..."
/usr/local/bin/caido-cli --listen 0.0.0.0:${CAIDO_PORT} \
          --allow-guests \
          --no-logging \
          --no-open \
          --import-ca-cert /app/certs/ca.p12 \
          --import-ca-cert-pass "" > "$CAIDO_LOG" 2>&1 &

CAIDO_PID=$!

echo "[INFO] Waiting for Caido API..."
for i in {1..30}; do
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:${CAIDO_PORT}/graphql/ | grep -qE "^(200|400)$"; then
    echo "[INFO] Caido API is ready."
    break
  fi
  sleep 1
done

echo "[INFO] Initializing Caido Project..."
# Get Token
RESPONSE=$(curl -sL -X POST -H "Content-Type: application/json" -d '{"query":"mutation LoginAsGuest { loginAsGuest { token { accessToken } } }"}' http://localhost:${CAIDO_PORT}/graphql)
TOKEN=$(echo "$RESPONSE" | jq -r '.data.loginAsGuest.token.accessToken // empty')
export CAIDO_API_TOKEN=$TOKEN

# Create Project
CREATE_PROJECT_RESPONSE=$(curl -sL -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"query":"mutation CreateProject { createProject(input: {name: \"sandbox\", temporary: true}) { project { id } } }"}' http://localhost:${CAIDO_PORT}/graphql)
PROJECT_ID=$(echo $CREATE_PROJECT_RESPONSE | jq -r '.data.createProject.project.id')

# Select Project
curl -sL -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"query":"mutation SelectProject { selectProject(id: \"'$PROJECT_ID'\") { currentProject { project { id } } } }"}' http://localhost:${CAIDO_PORT}/graphql > /dev/null

echo "[INFO] Setting up Proxy Environment..."
# Set global proxy for all subsequent processes (running as root)
export http_proxy=http://127.0.0.1:${CAIDO_PORT}
export https_proxy=http://127.0.0.1:${CAIDO_PORT}
export HTTP_PROXY=http://127.0.0.1:${CAIDO_PORT}
export HTTPS_PROXY=http://127.0.0.1:${CAIDO_PORT}
export ALL_PROXY=http://127.0.0.1:${CAIDO_PORT}
export NO_PROXY="localhost,127.0.0.1,api.openai.com,generativelanguage.googleapis.com,oauth2.googleapis.com,googleapis.com"
export no_proxy="localhost,127.0.0.1,api.openai.com,generativelanguage.googleapis.com,oauth2.googleapis.com,googleapis.com"
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

echo "[INFO] Starting Tool Server..."
# Run tool server as root to avoid sudo-related "no new privileges" issues
if [ -z "$TOOL_SERVER_TOKEN" ]; then
    export TOOL_SERVER_TOKEN=$(openssl rand -base64 32)
fi

/app/.venv/bin/python -m strix.runtime.tool_server \
  --token="$TOOL_SERVER_TOKEN" \
  --host=0.0.0.0 \
  --port="$TOOL_SERVER_PORT" \
  --timeout=3600 > /tmp/tool_server.log 2>&1 &

echo "[INFO] Waiting for Tool Server (10s)..."
sleep 10

echo "[INFO] Starting Strix Agent..."
# Run the actual agent
exec /app/.venv/bin/python -m strix.interface.main "$@"
