#!/bin/bash

# Script to create a complete NiFi flow and push it via REST API
# This creates a more complex flow: HTTP → Route → Transform → Store
# Usage: ./create_and_push_flow.sh

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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            NiFi Flow Creator and Publisher                     ║${NC}"
echo -e "${BLUE}║  HTTP Listener → Route → Transform → PutFile                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# Step 1: Authenticate
echo -e "${YELLOW}[1/10] Authenticating...${NC}"
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo -e "${RED}Error: Failed to obtain access token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated successfully${NC}\n"

# Step 2: Get root process group
echo -e "${YELLOW}[2/10] Getting root process group...${NC}"
ROOT_PG=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESS_GROUP_ID=$(echo "$ROOT_PG" | jq -r '.processGroupFlow.id')
echo -e "${GREEN}✓ Process Group ID: ${PROCESS_GROUP_ID}${NC}\n"

# Step 3: Create Process Group for the flow
echo -e "${YELLOW}[3/10] Creating process group for flow...${NC}"

PG_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "name": "Data Processing Flow",
    "position": {
      "x": 100,
      "y": 100
    }
  }
}
EOF
)

PG_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/process-groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PG_PAYLOAD}")

FLOW_PG_ID=$(echo "$PG_RESPONSE" | jq -r '.id')
echo -e "${GREEN}✓ Flow Process Group created: ${FLOW_PG_ID}${NC}\n"

# Step 4: Create ListenHTTP processor
echo -e "${YELLOW}[4/10] Creating ListenHTTP processor...${NC}"

LISTEN_HTTP_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "type": "org.apache.nifi.processors.standard.ListenHTTP",
    "bundle": {
      "group": "org.apache.nifi",
      "artifact": "nifi-standard-nar",
      "version": "2.6.0"
    },
    "name": "Listen HTTP",
    "position": {
      "x": 200,
      "y": 100
    },
    "config": {
      "properties": {
        "Listening Port": "9999",
        "Base Path": "data",
        "HTTP Headers to receive as Attributes (Regex)": ".*"
      },
      "autoTerminatedRelationships": []
    }
  }
}
EOF
)

LISTEN_HTTP_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${LISTEN_HTTP_PAYLOAD}")

LISTEN_HTTP_ID=$(echo "$LISTEN_HTTP_RESPONSE" | jq -r '.id')
echo -e "${GREEN}✓ ListenHTTP created: ${LISTEN_HTTP_ID}${NC}\n"

# Step 5: Create RouteOnAttribute processor
echo -e "${YELLOW}[5/10] Creating RouteOnAttribute processor...${NC}"

ROUTE_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "type": "org.apache.nifi.processors.standard.RouteOnAttribute",
    "bundle": {
      "group": "org.apache.nifi",
      "artifact": "nifi-standard-nar",
      "version": "2.6.0"
    },
    "name": "Route On Attribute",
    "position": {
      "x": 200,
      "y": 300
    },
    "config": {
      "properties": {
        "Routing Strategy": "Route to Property name",
        "large": "\${http.query.param.size:equals('large')}",
        "small": "\${http.query.param.size:equals('small')}"
      },
      "autoTerminatedRelationships": ["unmatched"]
    }
  }
}
EOF
)

ROUTE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${ROUTE_PAYLOAD}")

ROUTE_ID=$(echo "$ROUTE_RESPONSE" | jq -r '.id')
echo -e "${GREEN}✓ RouteOnAttribute created: ${ROUTE_ID}${NC}\n"

# Step 6: Create UpdateAttribute for large files
echo -e "${YELLOW}[6/10] Creating UpdateAttribute (Large)...${NC}"

UPDATE_LARGE_PAYLOAD=$(cat <<EOF
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
    "name": "Update Large Files",
    "position": {
      "x": 50,
      "y": 500
    },
    "config": {
      "properties": {
        "category": "large",
        "processing.time": "\${now():format('yyyy-MM-dd HH:mm:ss')}",
        "filename": "\${filename:append('.large')}"
      },
      "autoTerminatedRelationships": []
    }
  }
}
EOF
)

UPDATE_LARGE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${UPDATE_LARGE_PAYLOAD}")

UPDATE_LARGE_ID=$(echo "$UPDATE_LARGE_RESPONSE" | jq -r '.id')
echo -e "${GREEN}✓ UpdateAttribute (Large) created: ${UPDATE_LARGE_ID}${NC}\n"

# Step 7: Create UpdateAttribute for small files
echo -e "${YELLOW}[7/10] Creating UpdateAttribute (Small)...${NC}"

UPDATE_SMALL_PAYLOAD=$(cat <<EOF
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
    "name": "Update Small Files",
    "position": {
      "x": 350,
      "y": 500
    },
    "config": {
      "properties": {
        "category": "small",
        "processing.time": "\${now():format('yyyy-MM-dd HH:mm:ss')}",
        "filename": "\${filename:append('.small')}"
      },
      "autoTerminatedRelationships": []
    }
  }
}
EOF
)

UPDATE_SMALL_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${UPDATE_SMALL_PAYLOAD}")

UPDATE_SMALL_ID=$(echo "$UPDATE_SMALL_RESPONSE" | jq -r '.id')
echo -e "${GREEN}✓ UpdateAttribute (Small) created: ${UPDATE_SMALL_ID}${NC}\n"

# Step 8: Create PutFile processor
echo -e "${YELLOW}[8/10] Creating PutFile processor...${NC}"

PUTFILE_PAYLOAD=$(cat <<EOF
{
  "revision": {
    "version": 0
  },
  "disconnectedNodeAcknowledged": false,
  "component": {
    "type": "org.apache.nifi.processors.standard.PutFile",
    "bundle": {
      "group": "org.apache.nifi",
      "artifact": "nifi-standard-nar",
      "version": "2.6.0"
    },
    "name": "Store Files",
    "position": {
      "x": 200,
      "y": 700
    },
    "config": {
      "properties": {
        "Directory": "/tmp/nifi-output/\${category}",
        "Conflict Resolution Strategy": "replace",
        "Create Missing Directories": "true"
      },
      "autoTerminatedRelationships": ["success", "failure"]
    }
  }
}
EOF
)

PUTFILE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PUTFILE_PAYLOAD}")

PUTFILE_ID=$(echo "$PUTFILE_RESPONSE" | jq -r '.id')
echo -e "${GREEN}✓ PutFile created: ${PUTFILE_ID}${NC}\n"

# Step 9: Create all connections
echo -e "${YELLOW}[9/10] Creating connections...${NC}"

# Connection 1: ListenHTTP -> RouteOnAttribute
CONN1=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"name\": \"HTTP to Route\",
      \"source\": {\"id\": \"${LISTEN_HTTP_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"destination\": {\"id\": \"${ROUTE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"selectedRelationships\": [\"success\"]
    }
  }")
echo -e "${GREEN}  ✓ Connection: ListenHTTP → RouteOnAttribute${NC}"

# Connection 2: RouteOnAttribute (large) -> UpdateAttribute Large
CONN2=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"name\": \"Large Route\",
      \"source\": {\"id\": \"${ROUTE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"destination\": {\"id\": \"${UPDATE_LARGE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"selectedRelationships\": [\"large\"]
    }
  }")
echo -e "${GREEN}  ✓ Connection: Route → UpdateAttribute (Large)${NC}"

# Connection 3: RouteOnAttribute (small) -> UpdateAttribute Small
CONN3=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"name\": \"Small Route\",
      \"source\": {\"id\": \"${ROUTE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"destination\": {\"id\": \"${UPDATE_SMALL_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"selectedRelationships\": [\"small\"]
    }
  }")
echo -e "${GREEN}  ✓ Connection: Route → UpdateAttribute (Small)${NC}"

# Connection 4: UpdateAttribute Large -> PutFile
CONN4=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"name\": \"Large to Storage\",
      \"source\": {\"id\": \"${UPDATE_LARGE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"destination\": {\"id\": \"${PUTFILE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"selectedRelationships\": [\"success\"]
    }
  }")
echo -e "${GREEN}  ✓ Connection: UpdateAttribute (Large) → PutFile${NC}"

# Connection 5: UpdateAttribute Small -> PutFile
CONN5=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"name\": \"Small to Storage\",
      \"source\": {\"id\": \"${UPDATE_SMALL_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"destination\": {\"id\": \"${PUTFILE_ID}\", \"groupId\": \"${FLOW_PG_ID}\", \"type\": \"PROCESSOR\"},
      \"selectedRelationships\": [\"success\"]
    }
  }")
echo -e "${GREEN}  ✓ Connection: UpdateAttribute (Small) → PutFile${NC}\n"

# Step 10: Display summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                Flow Created and Pushed Successfully!           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}Flow Summary:${NC}"
echo -e "  Flow Process Group ID:     ${FLOW_PG_ID}"
echo -e "  ListenHTTP ID:             ${LISTEN_HTTP_ID}"
echo -e "  RouteOnAttribute ID:       ${ROUTE_ID}"
echo -e "  UpdateAttribute (Large):   ${UPDATE_LARGE_ID}"
echo -e "  UpdateAttribute (Small):   ${UPDATE_SMALL_ID}"
echo -e "  PutFile ID:                ${PUTFILE_ID}"
echo -e ""

echo -e "${CYAN}Flow Structure:${NC}"
echo -e "  ${YELLOW}┌─────────────┐${NC}"
echo -e "  ${YELLOW}│ ListenHTTP  │${NC} (Port 9999, Path: /data)"
echo -e "  ${YELLOW}└──────┬──────┘${NC}"
echo -e "         │ success"
echo -e "         ▼"
echo -e "  ${YELLOW}┌─────────────────┐${NC}"
echo -e "  ${YELLOW}│ RouteOnAttribute│${NC} (Route by size parameter)"
echo -e "  ${YELLOW}└────┬───────┬────┘${NC}"
echo -e "       │       │"
echo -e "  large│       │small"
echo -e "       ▼       ▼"
echo -e "  ${YELLOW}┌────────┐ ┌────────┐${NC}"
echo -e "  ${YELLOW}│Update  │ │Update  │${NC} (Add attributes)"
echo -e "  ${YELLOW}│(Large) │ │(Small) │${NC}"
echo -e "  ${YELLOW}└───┬────┘ └───┬────┘${NC}"
echo -e "      │          │"
echo -e "      └────┬─────┘"
echo -e "           ▼"
echo -e "  ${YELLOW}┌─────────────┐${NC}"
echo -e "  ${YELLOW}│  PutFile    │${NC} (Save to /tmp/nifi-output/{category})"
echo -e "  ${YELLOW}└─────────────┘${NC}"
echo -e ""

echo -e "${CYAN}Next Steps:${NC}"
echo -e "  1. Start the flow:"
echo -e "     ${GREEN}./start_workflow.sh${NC}"
echo -e ""
echo -e "  2. Test with HTTP POST:"
echo -e "     ${GREEN}curl -X POST http://localhost:9999/data?size=large -d 'Large file content'${NC}"
echo -e "     ${GREEN}curl -X POST http://localhost:9999/data?size=small -d 'Small file content'${NC}"
echo -e ""
echo -e "  3. View flow in UI:"
echo -e "     ${GREEN}${NIFI_URL}/nifi${NC}"
echo -e ""
echo -e "  4. Export flow:"
echo -e "     ${GREEN}./export_flow.sh ${FLOW_PG_ID}${NC}"
echo -e ""

echo -e "${GREEN}Flow successfully created and pushed to NiFi!${NC}"
