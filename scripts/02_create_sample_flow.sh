#!/bin/bash

# TASK 2: Create Sample NiFi Flow
# Creates: GenerateFlowFile -> LogAttribute (simplest possible flow)

set -e

NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  TASK 2: Create Sample NiFi Flow                         ║"
echo "║  Flow: GenerateFlowFile -> LogAttribute                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Authenticate
echo "[1/5] Authenticating..."
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to authenticate"
    echo "   Make sure NiFi is running: ./01_setup_nifi.sh"
    exit 1
fi
echo "✓ Authenticated"
echo ""

# Get Root Process Group
echo "[2/5] Getting root process group..."
ROOT_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESS_GROUP_ID=$(echo "$ROOT_RESPONSE" | jq -r '.processGroupFlow.id')
echo "✓ Process Group ID: ${PROCESS_GROUP_ID}"
echo ""

# Create GenerateFlowFile Processor
echo "[3/5] Creating GenerateFlowFile processor..."
GENERATE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "Generate Sample Data",
      "position": {"x": 300, "y": 200},
      "config": {
        "properties": {
          "File Size": "1KB",
          "Batch Size": "1",
          "Data Format": "Text",
          "Custom Text": "Sample data created at ${now():format('yyyy-MM-dd HH:mm:ss')}"
        },
        "schedulingPeriod": "60 sec"
      }
    }
  }')

GENERATE_ID=$(echo "$GENERATE_RESPONSE" | jq -r '.id')
echo "✓ GenerateFlowFile created"
echo "  ID: ${GENERATE_ID}"
echo ""

# Create LogAttribute Processor
echo "[4/5] Creating LogAttribute processor..."
LOG_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.LogAttribute",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "Log Sample Data",
      "position": {"x": 300, "y": 400},
      "config": {
        "properties": {
          "Log Level": "info",
          "Log Payload": "true"
        },
        "autoTerminatedRelationships": ["success"]
      }
    }
  }')

LOG_ID=$(echo "$LOG_RESPONSE" | jq -r '.id')
echo "✓ LogAttribute created"
echo "  ID: ${LOG_ID}"
echo ""

# Create Connection
echo "[5/5] Creating connection..."
CONNECTION_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"source\": {
        \"id\": \"${GENERATE_ID}\",
        \"groupId\": \"${PROCESS_GROUP_ID}\",
        \"type\": \"PROCESSOR\"
      },
      \"destination\": {
        \"id\": \"${LOG_ID}\",
        \"groupId\": \"${PROCESS_GROUP_ID}\",
        \"type\": \"PROCESSOR\"
      },
      \"selectedRelationships\": [\"success\"]
    }
  }")

CONNECTION_ID=$(echo "$CONNECTION_RESPONSE" | jq -r '.id')
echo "✓ Connection created"
echo "  ID: ${CONNECTION_ID}"
echo ""

# Save IDs to file for later use
echo "# Sample Flow Component IDs" > sample_flow_ids.txt
echo "GENERATE_ID=${GENERATE_ID}" >> sample_flow_ids.txt
echo "LOG_ID=${LOG_ID}" >> sample_flow_ids.txt
echo "CONNECTION_ID=${CONNECTION_ID}" >> sample_flow_ids.txt
echo "PROCESS_GROUP_ID=${PROCESS_GROUP_ID}" >> sample_flow_ids.txt

echo "✓ Saved component IDs to: sample_flow_ids.txt"
echo ""

# Summary
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Sample Flow Created!                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Flow Structure:"
echo "  ┌──────────────────────┐"
echo "  │ Generate Sample Data │  (Creates 1KB every 60 sec)"
echo "  └──────────┬───────────┘"
echo "             │ success"
echo "             ▼"
echo "  ┌──────────────────────┐"
echo "  │ Log Sample Data      │  (Logs to nifi-app.log)"
echo "  └──────────────────────┘"
echo ""
echo "Component IDs saved to: sample_flow_ids.txt"
echo ""
echo "Next steps:"
echo "  1. View flow in UI: ${NIFI_URL}/nifi"
echo "  2. Start flow: ./03_push_flow.sh"
echo "  3. Monitor logs: docker-compose logs -f nifi"
echo ""
