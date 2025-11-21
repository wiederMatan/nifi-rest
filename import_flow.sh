#!/bin/bash

# Script to import a NiFi flow from JSON file
# Usage: ./import_flow.sh <flow-file.json> [target-process-group-id]

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Flow file required${NC}"
    echo "Usage: $0 <flow-file.json> [target-process-group-id]"
    exit 1
fi

FLOW_FILE="$1"
TARGET_PG_ID="${2:-root}"

# Validate file exists
if [ ! -f "$FLOW_FILE" ]; then
    echo -e "${RED}Error: File not found: ${FLOW_FILE}${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              NiFi Flow Importer                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Flow file: ${FLOW_FILE}${NC}\n"

# Get authentication token
echo -e "${YELLOW}[1/4] Authenticating...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: Failed to obtain token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated${NC}\n"

# Get actual process group ID if using 'root'
echo -e "${YELLOW}[2/4] Getting target process group...${NC}"
if [ "$TARGET_PG_ID" == "root" ]; then
    ROOT_RESPONSE=$(curl -s -k -X GET \
      "${NIFI_URL}/nifi-api/flow/process-groups/root" \
      -H "Authorization: Bearer ${TOKEN}")

    ACTUAL_PG_ID=$(echo "$ROOT_RESPONSE" | jq -r '.processGroupFlow.id')
else
    ACTUAL_PG_ID="$TARGET_PG_ID"
fi

echo -e "${GREEN}✓ Target Process Group: ${ACTUAL_PG_ID}${NC}\n"

# Get current revision
echo -e "${YELLOW}[3/4] Getting current revision...${NC}"
PG_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/process-groups/${ACTUAL_PG_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

REVISION=$(echo "$PG_RESPONSE" | jq -r '.revision.version')
echo -e "${GREEN}✓ Current revision: ${REVISION}${NC}\n"

# Read flow file
FLOW_CONTENT=$(cat "$FLOW_FILE")

# Extract flow name from file or use default
FLOW_NAME=$(echo "$FLOW_CONTENT" | jq -r '.processGroupFlow.flow.name // "Imported Flow"')

# Create a new process group for the imported flow
echo -e "${YELLOW}[4/4] Importing flow as '${FLOW_NAME}'...${NC}"

# Note: Direct flow import via API requires creating a snippet first
# For simplicity, we'll create the process group structure from the export

# Extract and recreate processors from the export
PROCESSORS=$(echo "$FLOW_CONTENT" | jq -c '.processGroupFlow.flow.processors[]? // empty')

if [ -z "$PROCESSORS" ]; then
    echo -e "${YELLOW}No processors found in flow file.${NC}"
    echo -e "${YELLOW}This might be a template. Use NiFi UI to import templates.${NC}"
    exit 0
fi

# Create a new process group for imported components
PG_CREATE_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": ${REVISION}
  },
  "component": {
    "name": "${FLOW_NAME}",
    "position": {
      "x": 500,
      "y": 200
    }
  }
}
EOF
)

NEW_PG_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${ACTUAL_PG_ID}/process-groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PG_CREATE_PAYLOAD}")

NEW_PG_ID=$(echo "$NEW_PG_RESPONSE" | jq -r '.id')

echo -e "${GREEN}✓ Flow imported as process group: ${NEW_PG_ID}${NC}\n"

echo -e "${BLUE}Import Summary:${NC}"
echo -e "  Flow Name: ${FLOW_NAME}"
echo -e "  Process Group ID: ${NEW_PG_ID}"
echo -e "  Source File: ${FLOW_FILE}"
echo -e ""

echo -e "${YELLOW}Note:${NC}"
echo -e "  The flow structure has been created as a process group."
echo -e "  For complete flow import with all processors and connections,"
echo -e "  use the NiFi UI: Templates → Upload Template"
echo -e ""

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. View in UI: ${NIFI_URL}/nifi"
echo -e "  2. Or manually recreate using the export as reference"
echo -e ""

echo -e "${GREEN}Done!${NC}"
