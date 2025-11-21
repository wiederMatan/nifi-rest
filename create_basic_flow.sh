#!/bin/bash

# Create a simple basic NiFi flow: GenerateFlowFile -> LogAttribute
# This is the simplest possible flow to demonstrate API usage

set -e

NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

echo "=== Creating Basic NiFi Flow ==="
echo ""

# Step 1: Get Token
echo "[1/5] Getting authentication token..."
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to get token"
    exit 1
fi
echo "✓ Got token"
echo ""

# Step 2: Get Root Process Group
echo "[2/5] Getting root process group..."
ROOT_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESS_GROUP_ID=$(echo "$ROOT_RESPONSE" | jq -r '.processGroupFlow.id')
echo "✓ Process Group ID: ${PROCESS_GROUP_ID}"
echo ""

# Step 3: Create GenerateFlowFile Processor
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
      "name": "Generate Test Data",
      "position": {"x": 200, "y": 100},
      "config": {
        "properties": {
          "File Size": "1KB",
          "Batch Size": "1",
          "Data Format": "Text",
          "Custom Text": "Hello from NiFi API!"
        },
        "schedulingPeriod": "60 sec"
      }
    }
  }')

GENERATE_ID=$(echo "$GENERATE_RESPONSE" | jq -r '.id')
echo "✓ GenerateFlowFile ID: ${GENERATE_ID}"
echo ""

# Step 4: Create LogAttribute Processor
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
      "name": "Log Data",
      "position": {"x": 200, "y": 300},
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
echo "✓ LogAttribute ID: ${LOG_ID}"
echo ""

# Step 5: Create Connection
echo "[5/5] Creating connection between processors..."
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
echo "✓ Connection ID: ${CONNECTION_ID}"
echo ""

# Summary
echo "╔═══════════════════════════════════════════════════╗"
echo "║          Basic Flow Created Successfully!         ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
echo "Flow Structure:"
echo "  ┌─────────────────┐"
echo "  │ Generate Test   │  (Creates 1KB file every 60 sec)"
echo "  │ Data            │"
echo "  └────────┬────────┘"
echo "           │ success"
echo "           ▼"
echo "  ┌─────────────────┐"
echo "  │ Log Data        │  (Logs to nifi-app.log)"
echo "  └─────────────────┘"
echo ""
echo "Component IDs:"
echo "  GenerateFlowFile: ${GENERATE_ID}"
echo "  LogAttribute:     ${LOG_ID}"
echo "  Connection:       ${CONNECTION_ID}"
echo ""
echo "Next steps:"
echo "  1. View in UI: https://localhost:8443/nifi"
echo "  2. Start processors:"
echo "     curl -k -X PUT \\"
echo "       'https://localhost:8443/nifi-api/processors/${GENERATE_ID}/run-status' \\"
echo "       -H 'Authorization: Bearer YOUR_TOKEN' \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"revision\":{\"version\":0},\"state\":\"RUNNING\"}'"
echo ""
echo "Done!"
