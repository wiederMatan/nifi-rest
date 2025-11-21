#!/bin/bash

# Script to stop all processors in the workflow
# Usage: ./stop_workflow.sh [processor_id1] [processor_id2] ...
#        Or: ./stop_workflow.sh (to stop ALL processors in root process group)

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== NiFi Workflow Stopper ===${NC}\n"

# Get access token
echo -e "${YELLOW}Obtaining access token...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to obtain token"
    exit 1
fi
echo -e "${GREEN}✓ Token obtained${NC}\n"

# Function to stop a processor
stop_processor() {
  local processor_id=$1

  # Get current processor state
  local processor_state=$(curl -s -k -X GET \
    "${NIFI_URL}/nifi-api/processors/${processor_id}" \
    -H "Authorization: Bearer ${TOKEN}")

  local revision=$(echo "$processor_state" | jq -r '.revision.version')
  local name=$(echo "$processor_state" | jq -r '.component.name')
  local current_state=$(echo "$processor_state" | jq -r '.component.state')

  if [ "$current_state" == "STOPPED" ]; then
    echo -e "${GREEN}  ✓ ${name} is already stopped${NC}"
    return 0
  fi

  # Stop the processor
  local stop_payload=$(cat <<EOF
{
  "revision": {
    "version": ${revision}
  },
  "disconnectedNodeAcknowledged": false,
  "state": "STOPPED"
}
EOF
)

  curl -s -k -X PUT \
    "${NIFI_URL}/nifi-api/processors/${processor_id}/run-status" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${stop_payload}" > /dev/null

  echo -e "${GREEN}  ✓ Stopped: ${name} (${processor_id})${NC}"
}

# If processor IDs provided as arguments, stop those
if [ $# -gt 0 ]; then
  echo -e "${YELLOW}Stopping specified processors...${NC}"
  for processor_id in "$@"; do
    stop_processor "$processor_id"
  done
else
  # Stop all processors in root process group
  echo -e "${YELLOW}Stopping all processors in root process group...${NC}"

  # Get all processors
  PROCESSORS=$(curl -s -k -X GET \
    "${NIFI_URL}/nifi-api/process-groups/root/processors" \
    -H "Authorization: Bearer ${TOKEN}")

  # Extract processor IDs and stop each
  echo "$PROCESSORS" | jq -r '.processors[].id' | while read -r processor_id; do
    stop_processor "$processor_id"
  done
fi

echo -e "\n${GREEN}All processors stopped!${NC}"
