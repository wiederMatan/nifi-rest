#!/bin/bash

# Script to export a NiFi flow/process group to JSON
# Usage: ./export_flow.sh [process-group-id]
#        ./export_flow.sh (exports root process group)

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Process group to export (default to root)
PROCESS_GROUP_ID="${1:-root}"

# Output directory
OUTPUT_DIR="./flows"
mkdir -p "$OUTPUT_DIR"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              NiFi Flow Exporter                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Get authentication token
echo -e "${YELLOW}[1/3] Authenticating...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to obtain token"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated${NC}\n"

# Get actual process group ID if using 'root'
if [ "$PROCESS_GROUP_ID" == "root" ]; then
    echo -e "${YELLOW}[2/3] Getting root process group ID...${NC}"
    ROOT_RESPONSE=$(curl -s -k -X GET \
      "${NIFI_URL}/nifi-api/flow/process-groups/root" \
      -H "Authorization: Bearer ${TOKEN}")

    ACTUAL_PG_ID=$(echo "$ROOT_RESPONSE" | jq -r '.processGroupFlow.id')
    PG_NAME="root"
else
    ACTUAL_PG_ID="$PROCESS_GROUP_ID"

    # Get process group name
    echo -e "${YELLOW}[2/3] Getting process group details...${NC}"
    PG_RESPONSE=$(curl -s -k -X GET \
      "${NIFI_URL}/nifi-api/process-groups/${ACTUAL_PG_ID}" \
      -H "Authorization: Bearer ${TOKEN}")

    PG_NAME=$(echo "$PG_RESPONSE" | jq -r '.component.name' | tr ' ' '_')
fi

echo -e "${GREEN}✓ Process Group: ${PG_NAME} (${ACTUAL_PG_ID})${NC}\n"

# Export the flow
echo -e "${YELLOW}[3/3] Exporting flow...${NC}"

FLOW_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/process-groups/${ACTUAL_PG_ID}/download" \
  -H "Authorization: Bearer ${TOKEN}")

# Generate filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${OUTPUT_DIR}/${PG_NAME}_${TIMESTAMP}.json"

# Save to file
echo "$FLOW_RESPONSE" | jq '.' > "$FILENAME"

echo -e "${GREEN}✓ Flow exported successfully${NC}\n"

# Display summary
FILE_SIZE=$(du -h "$FILENAME" | cut -f1)
PROCESSOR_COUNT=$(echo "$FLOW_RESPONSE" | jq '[.. | .processors? // empty | .[]] | length')
CONNECTION_COUNT=$(echo "$FLOW_RESPONSE" | jq '[.. | .connections? // empty | .[]] | length')

echo -e "${BLUE}Export Summary:${NC}"
echo -e "  Process Group: ${PG_NAME}"
echo -e "  File: ${FILENAME}"
echo -e "  Size: ${FILE_SIZE}"
echo -e "  Processors: ${PROCESSOR_COUNT}"
echo -e "  Connections: ${CONNECTION_COUNT}"
echo -e ""

echo -e "${YELLOW}To import this flow:${NC}"
echo -e "  1. Use NiFi UI: Upload Template"
echo -e "  2. Or use: ${GREEN}./import_flow.sh ${FILENAME}${NC}"
echo -e ""

echo -e "${GREEN}Done!${NC}"
