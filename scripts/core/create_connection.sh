#!/bin/bash

# Script to create a connection between two NiFi processors using REST API
# Usage: ./create_connection.sh

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Placeholder IDs (replace with actual IDs from your NiFi instance)
PROCESS_GROUP_ID="${PROCESS_GROUP_ID:-a1b2c3d4-0000-0000-0000-000000000000}"
SOURCE_PROCESSOR_ID="${SOURCE_PROCESSOR_ID:-e5f6g7h8-1111-1111-1111-111111111111}"
DESTINATION_PROCESSOR_ID="${DESTINATION_PROCESSOR_ID:-i9j0k1l2-2222-2222-2222-222222222222}"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== NiFi Connection Creator ===${NC}\n"

# Step 1: Obtain access token
echo -e "${YELLOW}[1/3] Obtaining access token...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo -e "${RED}Error: Failed to obtain access token. Check credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Token obtained successfully${NC}\n"

# Step 2: Get the current revision for the process group
echo -e "${YELLOW}[2/3] Fetching process group revision...${NC}"
REVISION_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

REVISION=$(echo "$REVISION_RESPONSE" | jq -r '.revision.version')

if [ -z "$REVISION" ] || [ "$REVISION" == "null" ]; then
    echo -e "${RED}Error: Failed to fetch process group revision.${NC}"
    echo "Response: $REVISION_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Current revision: ${REVISION}${NC}\n"

# Step 3: Create the connection
echo -e "${YELLOW}[3/3] Creating connection...${NC}"

CONNECTION_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": ${REVISION}
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "name": "Connection",
    "source": {
      "id": "${SOURCE_PROCESSOR_ID}",
      "groupId": "${PROCESS_GROUP_ID}",
      "type": "PROCESSOR"
    },
    "destination": {
      "id": "${DESTINATION_PROCESSOR_ID}",
      "groupId": "${PROCESS_GROUP_ID}",
      "type": "PROCESSOR"
    },
    "selectedRelationships": ["success"],
    "flowFileExpiration": "0 sec",
    "backPressureDataSizeThreshold": "1 GB",
    "backPressureObjectThreshold": "10000",
    "prioritizers": [],
    "bends": []
  }
}
EOF
)

RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${CONNECTION_PAYLOAD}")

# Check if connection was created successfully
CONNECTION_ID=$(echo "$RESPONSE" | jq -r '.id')

if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" == "null" ]; then
    echo -e "${RED}Error: Failed to create connection.${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Connection created successfully!${NC}"
echo -e "${GREEN}Connection ID: ${CONNECTION_ID}${NC}\n"

# Display connection details
echo -e "${YELLOW}Connection Details:${NC}"
echo "  Source Processor:      ${SOURCE_PROCESSOR_ID}"
echo "  Destination Processor: ${DESTINATION_PROCESSOR_ID}"
echo "  Relationship:          success"
echo "  Process Group:         ${PROCESS_GROUP_ID}"
echo ""
echo -e "${GREEN}Done!${NC}"
