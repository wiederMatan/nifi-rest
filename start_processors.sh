#!/bin/bash

# Start all processors in root process group
# Usage: ./start_processors.sh

NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

echo "=== Starting All Processors ==="
echo ""

# Get token
echo "Getting authentication token..."
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

# Get all processors
echo "Getting processors..."
PROCESSORS=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/process-groups/root/processors" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESSOR_IDS=$(echo "$PROCESSORS" | jq -r '.processors[].id')

if [ -z "$PROCESSOR_IDS" ]; then
    echo "No processors found"
    exit 0
fi

echo "Found processors, starting them..."
echo ""

# Start each processor
for PROC_ID in $PROCESSOR_IDS; do
    # Get processor name
    PROC_NAME=$(echo "$PROCESSORS" | jq -r ".processors[] | select(.id==\"$PROC_ID\") | .component.name")

    # Start processor
    RESPONSE=$(curl -s -k -X PUT \
      "${NIFI_URL}/nifi-api/processors/${PROC_ID}/run-status" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"revision":{"version":0},"state":"RUNNING"}' 2>&1)

    if echo "$RESPONSE" | grep -q "\"state\":\"RUNNING\""; then
        echo "✓ Started: $PROC_NAME"
    else
        echo "✗ Failed to start: $PROC_NAME (may already be running)"
    fi
done

echo ""
echo "Done! View at: https://localhost:8443/nifi"
