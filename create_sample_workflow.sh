#!/bin/bash

# Script to create a complete sample NiFi workflow using REST API
# Workflow: GenerateFlowFile -> LogAttribute -> UpdateAttribute -> Success/Failure Routing
# Usage: ./create_sample_workflow.sh

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
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         NiFi Sample Workflow Creator                      ║${NC}"
echo -e "${BLUE}║  Creates: GenerateFlowFile -> LogAttribute -> Route       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Step 1: Obtain access token
echo -e "${YELLOW}[1/8] Obtaining access token...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo -e "${RED}Error: Failed to obtain access token. Check credentials.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Token obtained${NC}\n"

# Step 2: Get root process group ID
echo -e "${YELLOW}[2/8] Getting root process group ID...${NC}"
ROOT_PG_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESS_GROUP_ID=$(echo "$ROOT_PG_RESPONSE" | jq -r '.processGroupFlow.id')
echo -e "${GREEN}✓ Process Group ID: ${PROCESS_GROUP_ID}${NC}\n"

# Step 3: Create GenerateFlowFile processor
echo -e "${YELLOW}[3/8] Creating GenerateFlowFile processor...${NC}"

GENERATE_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
    "bundle": {
      "group": "org.apache.nifi",
      "artifact": "nifi-standard-nar",
      "version": "2.6.0"
    },
    "name": "GenerateFlowFile",
    "position": {
      "x": 400,
      "y": 200
    },
    "config": {
      "properties": {
        "File Size": "1KB",
        "Batch Size": "1",
        "Data Format": "Text",
        "Unique FlowFiles": "false",
        "Custom Text": "Sample data generated at \${now():format('yyyy-MM-dd HH:mm:ss')}"
      },
      "schedulingPeriod": "60 sec",
      "schedulingStrategy": "TIMER_DRIVEN",
      "concurrentlySchedulableTaskCount": "1",
      "autoTerminatedRelationships": []
    }
  }
}
EOF
)

GENERATE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${GENERATE_PAYLOAD}")

GENERATE_ID=$(echo "$GENERATE_RESPONSE" | jq -r '.id')
if [ -z "$GENERATE_ID" ] || [ "$GENERATE_ID" == "null" ]; then
    echo -e "${RED}Error: Failed to create GenerateFlowFile processor${NC}"
    echo "Response: $GENERATE_RESPONSE"
    exit 1
fi
echo -e "${GREEN}✓ GenerateFlowFile created: ${GENERATE_ID}${NC}\n"

# Step 4: Create LogAttribute processor
echo -e "${YELLOW}[4/8] Creating LogAttribute processor...${NC}"

LOG_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "type": "org.apache.nifi.processors.standard.LogAttribute",
    "bundle": {
      "group": "org.apache.nifi",
      "artifact": "nifi-standard-nar",
      "version": "2.6.0"
    },
    "name": "LogAttribute",
    "position": {
      "x": 400,
      "y": 400
    },
    "config": {
      "properties": {
        "Log Level": "info",
        "Log Payload": "false",
        "Attributes to Log": ".*",
        "Attributes to Log by Comma Separated List": "",
        "Log Prefix": "Sample Workflow: "
      },
      "autoTerminatedRelationships": []
    }
  }
}
EOF
)

LOG_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${LOG_PAYLOAD}")

LOG_ID=$(echo "$LOG_RESPONSE" | jq -r '.id')
if [ -z "$LOG_ID" ] || [ "$LOG_ID" == "null" ]; then
    echo -e "${RED}Error: Failed to create LogAttribute processor${NC}"
    exit 1
fi
echo -e "${GREEN}✓ LogAttribute created: ${LOG_ID}${NC}\n"

# Step 5: Create UpdateAttribute processor
echo -e "${YELLOW}[5/8] Creating UpdateAttribute processor...${NC}"

UPDATE_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "type": "org.apache.nifi.processors.standard.UpdateAttribute",
    "bundle": {
      "group": "org.apache.nifi",
      "artifact": "nifi-standard-nar",
      "version": "2.6.0"
    },
    "name": "UpdateAttribute",
    "position": {
      "x": 400,
      "y": 600
    },
    "config": {
      "properties": {
        "workflow.name": "Sample REST API Workflow",
        "processing.timestamp": "\${now():format('yyyy-MM-dd HH:mm:ss')}",
        "processed.by": "NiFi REST API"
      },
      "autoTerminatedRelationships": ["failure"]
    }
  }
}
EOF
)

UPDATE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${UPDATE_PAYLOAD}")

UPDATE_ID=$(echo "$UPDATE_RESPONSE" | jq -r '.id')
if [ -z "$UPDATE_ID" ] || [ "$UPDATE_ID" == "null" ]; then
    echo -e "${RED}Error: Failed to create UpdateAttribute processor${NC}"
    exit 1
fi
echo -e "${GREEN}✓ UpdateAttribute created: ${UPDATE_ID}${NC}\n"

# Step 6: Create connections
echo -e "${YELLOW}[6/8] Creating connections...${NC}"

# Connection 1: GenerateFlowFile -> LogAttribute
CONNECTION1_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "name": "GenerateFlowFile/success/LogAttribute",
    "source": {
      "id": "${GENERATE_ID}",
      "groupId": "${PROCESS_GROUP_ID}",
      "type": "PROCESSOR"
    },
    "destination": {
      "id": "${LOG_ID}",
      "groupId": "${PROCESS_GROUP_ID}",
      "type": "PROCESSOR"
    },
    "selectedRelationships": ["success"],
    "flowFileExpiration": "0 sec",
    "backPressureDataSizeThreshold": "1 GB",
    "backPressureObjectThreshold": "10000"
  }
}
EOF
)

CONN1_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${CONNECTION1_PAYLOAD}")

CONN1_ID=$(echo "$CONN1_RESPONSE" | jq -r '.id')
echo -e "${GREEN}  ✓ Connection 1: GenerateFlowFile -> LogAttribute (${CONN1_ID})${NC}"

# Connection 2: LogAttribute -> UpdateAttribute
CONNECTION2_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "name": "LogAttribute/success/UpdateAttribute",
    "source": {
      "id": "${LOG_ID}",
      "groupId": "${PROCESS_GROUP_ID}",
      "type": "PROCESSOR"
    },
    "destination": {
      "id": "${UPDATE_ID}",
      "groupId": "${PROCESS_GROUP_ID}",
      "type": "PROCESSOR"
    },
    "selectedRelationships": ["success"],
    "flowFileExpiration": "0 sec",
    "backPressureDataSizeThreshold": "1 GB",
    "backPressureObjectThreshold": "10000"
  }
}
EOF
)

CONN2_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${CONNECTION2_PAYLOAD}")

CONN2_ID=$(echo "$CONN2_RESPONSE" | jq -r '.id')
echo -e "${GREEN}  ✓ Connection 2: LogAttribute -> UpdateAttribute (${CONN2_ID})${NC}\n"

# Step 7: Auto-terminate UpdateAttribute success relationship
echo -e "${YELLOW}[7/8] Configuring auto-termination...${NC}"

# Get current UpdateAttribute state
UPDATE_STATE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/processors/${UPDATE_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

UPDATE_REVISION=$(echo "$UPDATE_STATE" | jq -r '.revision.version')

UPDATE_CONFIG=$(cat <<EOF
{
  "revision": {
    "version": ${UPDATE_REVISION}
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "id": "${UPDATE_ID}",
    "config": {
      "autoTerminatedRelationships": ["success", "failure"]
    }
  }
}
EOF
)

curl -s -k -X PUT \
  "${NIFI_URL}/nifi-api/processors/${UPDATE_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${UPDATE_CONFIG}" > /dev/null

echo -e "${GREEN}✓ Auto-termination configured${NC}\n"

# Step 8: Display summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Workflow Created Successfully!            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Workflow Summary:${NC}"
echo -e "  Process Group ID:     ${PROCESS_GROUP_ID}"
echo -e "  GenerateFlowFile ID:  ${GENERATE_ID}"
echo -e "  LogAttribute ID:      ${LOG_ID}"
echo -e "  UpdateAttribute ID:   ${UPDATE_ID}"
echo -e ""
echo -e "${YELLOW}Flow Structure:${NC}"
echo -e "  1. GenerateFlowFile (generates 1KB flowfile every 60 seconds)"
echo -e "     ↓ (success)"
echo -e "  2. LogAttribute (logs all attributes)"
echo -e "     ↓ (success)"
echo -e "  3. UpdateAttribute (adds workflow metadata)"
echo -e "     ↓ (success/failure auto-terminated)"
echo -e ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. View workflow in UI: ${NIFI_URL}/nifi"
echo -e "  2. Start processors:"
echo -e "     ./start_workflow.sh ${GENERATE_ID} ${LOG_ID} ${UPDATE_ID}"
echo -e "  3. Monitor logs: docker-compose logs -f nifi"
echo -e ""
echo -e "${GREEN}Done!${NC}"
