#!/bin/bash

# Detailed Flow Creation with Explanations
# This script creates a NiFi flow step-by-step with detailed explanations

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     NiFi Flow Creation - Step by Step with Explanations       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# STEP 1: Authentication
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 1: Authentication${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Explanation:"
echo "  - We need to authenticate with NiFi to get a JWT token"
echo "  - This token will be used in all subsequent API calls"
echo "  - Endpoint: POST /nifi-api/access/token"
echo "  - Credentials: username=admin, password=adminadminadmin"
echo ""
echo "Making API call..."

TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ Authentication failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Successfully authenticated!${NC}"
echo "  Token (first 50 chars): ${TOKEN:0:50}..."
echo ""
read -p "Press Enter to continue..."
echo ""

# STEP 2: Get Root Process Group
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 2: Get Root Process Group ID${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Explanation:"
echo "  - Every NiFi flow exists inside a Process Group"
echo "  - The 'root' process group is the top-level container"
echo "  - We need its ID to create child process groups and processors"
echo "  - Endpoint: GET /nifi-api/flow/process-groups/root"
echo ""
echo "Making API call..."

ROOT_RESPONSE=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESS_GROUP_ID=$(echo "$ROOT_RESPONSE" | jq -r '.processGroupFlow.id')

echo -e "${GREEN}✓ Retrieved root process group${NC}"
echo "  Process Group ID: ${PROCESS_GROUP_ID}"
echo ""
read -p "Press Enter to continue..."
echo ""

# STEP 3: Create Process Group for Our Flow
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 3: Create Process Group for Our Flow${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Explanation:"
echo "  - We'll create a dedicated process group to organize our flow"
echo "  - This keeps things organized in the UI"
echo "  - Name: 'Data Processing Flow'"
echo "  - Position: x=100, y=100 (for UI display)"
echo "  - Endpoint: POST /nifi-api/process-groups/{id}/process-groups"
echo ""
echo "JSON Payload:"
cat <<'EOF'
{
  "revision": {"version": 0},
  "component": {
    "name": "Data Processing Flow",
    "position": {"x": 100, "y": 100}
  }
}
EOF
echo ""
echo "Making API call..."

PG_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/process-groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "name": "Data Processing Flow",
      "position": {"x": 100, "y": 100}
    }
  }')

FLOW_PG_ID=$(echo "$PG_RESPONSE" | jq -r '.id')

echo -e "${GREEN}✓ Created process group${NC}"
echo "  Flow Process Group ID: ${FLOW_PG_ID}"
echo "  Name: Data Processing Flow"
echo ""
read -p "Press Enter to continue..."
echo ""

# STEP 4: Create ListenHTTP Processor
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 4: Create ListenHTTP Processor${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Explanation:"
echo "  - ListenHTTP creates an HTTP endpoint that receives data"
echo "  - Port: 9999"
echo "  - Path: /data"
echo "  - Full URL will be: http://localhost:9999/data"
echo "  - Processor type: org.apache.nifi.processors.standard.ListenHTTP"
echo "  - Bundle: nifi-standard-nar version 2.6.0"
echo ""
echo "Key Properties:"
echo "  - Listening Port: 9999"
echo "  - Base Path: data"
echo "  - HTTP Headers to receive as Attributes: .* (all headers)"
echo ""
echo "Making API call..."

LISTEN_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.ListenHTTP",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "Listen HTTP",
      "position": {"x": 200, "y": 100},
      "config": {
        "properties": {
          "Listening Port": "9999",
          "Base Path": "data",
          "HTTP Headers to receive as Attributes (Regex)": ".*"
        }
      }
    }
  }')

LISTEN_ID=$(echo "$LISTEN_RESPONSE" | jq -r '.id')

echo -e "${GREEN}✓ Created ListenHTTP processor${NC}"
echo "  Processor ID: ${LISTEN_ID}"
echo "  Listening on: http://localhost:9999/data"
echo ""
echo "What this does:"
echo "  When you send: curl -X POST http://localhost:9999/data -d 'test'"
echo "  NiFi creates a flowfile with the HTTP body as content"
echo ""
read -p "Press Enter to continue..."
echo ""

# STEP 5: Create RouteOnAttribute Processor
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 5: Create RouteOnAttribute Processor${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Explanation:"
echo "  - RouteOnAttribute routes flowfiles based on attributes"
echo "  - We'll route based on 'size' query parameter"
echo "  - If URL is: /data?size=large → routes to 'large' relationship"
echo "  - If URL is: /data?size=small → routes to 'small' relationship"
echo "  - Processor type: org.apache.nifi.processors.standard.RouteOnAttribute"
echo ""
echo "Key Properties:"
echo "  - Routing Strategy: Route to Property name"
echo "  - large: \${http.query.param.size:equals('large')}"
echo "  - small: \${http.query.param.size:equals('small')}"
echo ""
echo "Making API call..."

ROUTE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.RouteOnAttribute",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "Route On Attribute",
      "position": {"x": 200, "y": 300},
      "config": {
        "properties": {
          "Routing Strategy": "Route to Property name",
          "large": "${http.query.param.size:equals('"'"'large'"'"')}",
          "small": "${http.query.param.size:equals('"'"'small'"'"')}"
        },
        "autoTerminatedRelationships": ["unmatched"]
      }
    }
  }')

ROUTE_ID=$(echo "$ROUTE_RESPONSE" | jq -r '.id')

echo -e "${GREEN}✓ Created RouteOnAttribute processor${NC}"
echo "  Processor ID: ${ROUTE_ID}"
echo ""
echo "What this does:"
echo "  - Checks the 'size' query parameter from the HTTP request"
echo "  - Routes to 'large' or 'small' relationship accordingly"
echo "  - Unmatched requests are auto-terminated"
echo ""
read -p "Press Enter to continue..."
echo ""

# STEP 6: Create UpdateAttribute for Large Files
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 6: Create UpdateAttribute (Large Files)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Explanation:"
echo "  - UpdateAttribute adds or modifies flowfile attributes"
echo "  - This one handles 'large' files from routing"
echo "  - Adds metadata like category and timestamp"
echo "  - Processor type: org.apache.nifi.processors.standard.UpdateAttribute"
echo ""
echo "Attributes to Add:"
echo "  - category: 'large'"
echo "  - processing.time: Current timestamp"
echo "  - filename: Original filename + '.large' suffix"
echo ""
echo "Making API call..."

UPDATE_LARGE_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${FLOW_PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.UpdateAttribute",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "Update Large Files",
      "position": {"x": 50, "y": 500},
      "config": {
        "properties": {
          "category": "large",
          "processing.time": "${now():format('"'"'yyyy-MM-dd HH:mm:ss'"'"')}",
          "filename": "${filename:append('"'"'.large'"'"')}"
        }
      }
    }
  }')

UPDATE_LARGE_ID=$(echo "$UPDATE_LARGE_RESPONSE" | jq -r '.id')

echo -e "${GREEN}✓ Created UpdateAttribute (Large) processor${NC}"
echo "  Processor ID: ${UPDATE_LARGE_ID}"
echo ""
read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Flow creation in progress!${NC}"
echo ""
echo "Summary so far:"
echo "  ✓ Process Group Created"
echo "  ✓ ListenHTTP (receives HTTP POST)"
echo "  ✓ RouteOnAttribute (routes by size)"
echo "  ✓ UpdateAttribute for large files"
echo ""
echo "Next steps would create:"
echo "  - UpdateAttribute for small files"
echo "  - PutFile processor"
echo "  - All connections between processors"
echo ""
echo -e "${YELLOW}IDs for reference:${NC}"
echo "  Flow PG:       ${FLOW_PG_ID}"
echo "  ListenHTTP:    ${LISTEN_ID}"
echo "  Route:         ${ROUTE_ID}"
echo "  Update Large:  ${UPDATE_LARGE_ID}"
echo ""
echo -e "${CYAN}View in NiFi UI: https://localhost:8443/nifi${NC}"
echo ""
