#!/bin/bash

# TASK 3: Push/Start the Flow
# Starts processors in the sample flow or any flow you specify

set -e

NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  TASK 3: Push/Start NiFi Flow                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Authenticate
echo "[1/3] Authenticating..."
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to authenticate"
    exit 1
fi
echo "✓ Authenticated"
echo ""

# Check if we have saved IDs from sample flow
if [ -f "sample_flow_ids.txt" ]; then
    echo "[2/3] Loading sample flow IDs..."
    source sample_flow_ids.txt
    echo "✓ Loaded IDs from sample_flow_ids.txt"

    PROCESSOR_IDS=("$GENERATE_ID" "$LOG_ID")
else
    echo "[2/3] Getting all processors in root process group..."

    PROCESSORS=$(curl -s -k -X GET \
      "${NIFI_URL}/nifi-api/process-groups/root/processors" \
      -H "Authorization: Bearer ${TOKEN}")

    PROCESSOR_IDS=($(echo "$PROCESSORS" | jq -r '.processors[].id'))

    if [ ${#PROCESSOR_IDS[@]} -eq 0 ]; then
        echo "❌ No processors found"
        echo "   Create a flow first: ./02_create_sample_flow.sh"
        exit 1
    fi

    echo "✓ Found ${#PROCESSOR_IDS[@]} processors"
fi
echo ""

# Start each processor
echo "[3/3] Starting processors..."

SUCCESS_COUNT=0
ALREADY_RUNNING=0
FAILED_COUNT=0

for PROC_ID in "${PROCESSOR_IDS[@]}"; do
    # Get processor info
    PROC_INFO=$(curl -s -k -X GET \
      "${NIFI_URL}/nifi-api/processors/${PROC_ID}" \
      -H "Authorization: Bearer ${TOKEN}")

    PROC_NAME=$(echo "$PROC_INFO" | jq -r '.component.name')
    PROC_STATE=$(echo "$PROC_INFO" | jq -r '.component.state')
    REVISION=$(echo "$PROC_INFO" | jq -r '.revision.version')

    # Check if already running
    if [ "$PROC_STATE" == "RUNNING" ]; then
        echo "  ⚠ Already running: $PROC_NAME"
        ALREADY_RUNNING=$((ALREADY_RUNNING + 1))
        continue
    fi

    # Start the processor
    START_RESPONSE=$(curl -s -k -X PUT \
      "${NIFI_URL}/nifi-api/processors/${PROC_ID}/run-status" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"revision\":{\"version\":${REVISION}},\"state\":\"RUNNING\"}")

    NEW_STATE=$(echo "$START_RESPONSE" | jq -r '.component.state')

    if [ "$NEW_STATE" == "RUNNING" ]; then
        echo "  ✓ Started: $PROC_NAME"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ❌ Failed: $PROC_NAME"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

echo ""

# Summary
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Flow Push Complete!                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Status:"
echo "  ✓ Started: $SUCCESS_COUNT"
if [ $ALREADY_RUNNING -gt 0 ]; then
    echo "  ⚠ Already running: $ALREADY_RUNNING"
fi
if [ $FAILED_COUNT -gt 0 ]; then
    echo "  ❌ Failed: $FAILED_COUNT"
fi
echo ""
echo "Your flow is now running!"
echo ""
echo "Monitor activity:"
echo "  • UI: ${NIFI_URL}/nifi"
echo "  • Logs: docker-compose logs -f nifi"
echo "  • Stats: ./list_processors.sh"
echo ""
echo "To stop flow:"
echo "  docker-compose down"
echo ""
