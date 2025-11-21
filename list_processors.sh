#!/bin/bash

# Script to list all processors in a NiFi process group
# Usage: ./list_processors.sh [process-group-id]
#        If no ID provided, lists processors in root process group

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Use provided process group ID or default to root
PROCESS_GROUP_ID="${1:-root}"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== NiFi Processor Lister ===${NC}\n"

# Obtain access token
echo -e "${YELLOW}Obtaining access token...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to obtain access token. Check credentials."
    exit 1
fi

echo -e "${GREEN}✓ Token obtained${NC}\n"

# Get process group info
echo -e "${YELLOW}Fetching processors in process group: ${PROCESS_GROUP_ID}${NC}\n"
RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}")

# Display processors
echo "$RESPONSE" | jq -r '.processors[] | "ID: \(.id)\nName: \(.component.name)\nType: \(.component.type)\nState: \(.component.state)\n---"'

# Also show the actual process group ID if we queried root
if [ "$PROCESS_GROUP_ID" == "root" ]; then
    PG_RESPONSE=$(curl -s -k -X GET \
      "${NIFI_URL}/nifi-api/flow/process-groups/root" \
      -H "Authorization: Bearer ${TOKEN}")

    ACTUAL_PG_ID=$(echo "$PG_RESPONSE" | jq -r '.processGroupFlow.id')
    echo -e "\n${GREEN}Root Process Group ID: ${ACTUAL_PG_ID}${NC}"
fi
