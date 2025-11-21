# NiFi Workflow Creation Guide

Complete guide for creating and managing NiFi workflows using the REST API and Thunder Client extension.

## Table of Contents
- [Sample Workflow Overview](#sample-workflow-overview)
- [Using Shell Scripts](#using-shell-scripts)
- [Using Thunder Client](#using-thunder-client)
- [Workflow Operations](#workflow-operations)
- [Understanding the Workflow](#understanding-the-workflow)

---

## Sample Workflow Overview

This project includes a sample workflow that demonstrates common NiFi patterns:

```
┌──────────────────┐
│ GenerateFlowFile │  (Generates test data every 60 seconds)
└────────┬─────────┘
         │ success
         ▼
┌──────────────────┐
│  LogAttribute    │  (Logs all flowfile attributes)
└────────┬─────────┘
         │ success
         ▼
┌──────────────────┐
│ UpdateAttribute  │  (Adds workflow metadata)
└────────┬─────────┘
         │ success/failure
         ▼
    (terminated)
```

### Workflow Components

**1. GenerateFlowFile Processor**
- **Purpose:** Creates test flowfiles with sample data
- **Schedule:** Every 60 seconds
- **Output:** 1KB text file with timestamp
- **Configuration:**
  - File Size: 1KB
  - Batch Size: 1
  - Custom Text: Timestamped message

**2. LogAttribute Processor**
- **Purpose:** Logs all flowfile attributes for debugging
- **Log Level:** INFO
- **Configuration:**
  - Logs all attributes (regex: `.*`)
  - Does not log payload (performance)
  - Log prefix for identification

**3. UpdateAttribute Processor**
- **Purpose:** Adds workflow metadata to flowfiles
- **Added Attributes:**
  - `workflow.name`: "Sample REST API Workflow"
  - `processing.timestamp`: Current timestamp
  - `processed.by`: "NiFi REST API"
- **Auto-terminated:** success, failure

---

## Using Shell Scripts

### Quick Start

```bash
# 1. Start NiFi
docker-compose up -d

# Wait 1-3 minutes for NiFi to initialize
docker-compose logs -f nifi | grep "NiFi has started"

# 2. Create the sample workflow
./create_sample_workflow.sh

# 3. Start all processors
./start_workflow.sh

# 4. View in UI
open https://localhost:8443/nifi

# 5. Stop workflow when done
./stop_workflow.sh
```

### Script Details

#### create_sample_workflow.sh

Creates the complete workflow with all processors and connections.

**What it does:**
1. Obtains authentication token
2. Gets root process group ID
3. Creates GenerateFlowFile processor
4. Creates LogAttribute processor
5. Creates UpdateAttribute processor
6. Creates connections between processors
7. Configures auto-termination
8. Displays summary with all IDs

**Output:**
```
╔════════════════════════════════════════════════════════════╗
║         NiFi Sample Workflow Creator                      ║
║  Creates: GenerateFlowFile -> LogAttribute -> Route       ║
╚════════════════════════════════════════════════════════════╝

[1/8] Obtaining access token...
✓ Token obtained

[2/8] Getting root process group ID...
✓ Process Group ID: abc123...

[3/8] Creating GenerateFlowFile processor...
✓ GenerateFlowFile created: def456...

[4/8] Creating LogAttribute processor...
✓ LogAttribute created: ghi789...

[5/8] Creating UpdateAttribute processor...
✓ UpdateAttribute created: jkl012...

[6/8] Creating connections...
  ✓ Connection 1: GenerateFlowFile -> LogAttribute
  ✓ Connection 2: LogAttribute -> UpdateAttribute

[7/8] Configuring auto-termination...
✓ Auto-termination configured

╔════════════════════════════════════════════════════════════╗
║          Workflow Created Successfully!                    ║
╚════════════════════════════════════════════════════════════╝
```

#### start_workflow.sh

Starts processors in the workflow.

**Usage:**
```bash
# Start all processors in root process group
./start_workflow.sh

# Start specific processors by ID
./start_workflow.sh <processor_id1> <processor_id2> <processor_id3>
```

**Example:**
```bash
# Start specific processors from workflow creation output
./start_workflow.sh def456 ghi789 jkl012
```

#### stop_workflow.sh

Stops processors in the workflow.

**Usage:**
```bash
# Stop all processors
./stop_workflow.sh

# Stop specific processors
./stop_workflow.sh <processor_id1> <processor_id2>
```

### Environment Variables

All scripts respect these environment variables:

```bash
# Override default credentials
export NIFI_USERNAME="myuser"
export NIFI_PASSWORD="mysecurepassword"

# Or use inline
NIFI_USERNAME=admin NIFI_PASSWORD=test123456789 ./create_sample_workflow.sh
```

---

## Using Thunder Client

Thunder Client is a lightweight REST API client extension for VS Code.

### Installation

1. Open VS Code
2. Go to Extensions (Cmd+Shift+X / Ctrl+Shift+X)
3. Search for "Thunder Client"
4. Click Install

### Import Collection and Environment

**Method 1: Automatic Import (VS Code)**

1. Open Thunder Client in VS Code
2. Click "Collections" tab
3. Click "Menu" (⋮) → "Import"
4. Select `thunder-client/thunder-collection_NiFi REST API.json`
5. Click "Env" tab
6. Click "Menu" (⋮) → "Import"
7. Select `thunder-client/thunder-environment_NiFi Local.json`

**Method 2: Manual Setup**

The Thunder Client files are located in:
- Collection: `thunder-client/thunder-collection_NiFi REST API.json`
- Environment: `thunder-client/thunder-environment_NiFi Local.json`

### Thunder Client Collection Structure

The collection is organized into folders:

**1. Authentication**
- Get Access Token
- Verify Token
- Get Token Expiration

**2. Processors**
- Get Root Process Group
- List Processors
- Get Processor Details
- Create GenerateFlowFile Processor
- Create LogAttribute Processor

**3. Connections**
- Create Connection
- List Connections

**4. Workflow Management**
- Start Processor
- Stop Processor
- Delete Processor

**5. System & Diagnostics**
- System Diagnostics
- About (Version Info)
- Cluster Summary

### Using Thunder Client Workflow

**Step 1: Authenticate**

1. Select environment "NiFi Local" in Thunder Client
2. Open request "Authentication → Get Access Token"
3. Click "Send"
4. Token is automatically saved to `{{token}}` variable

**Step 2: Get Process Group ID**

1. Open "Processors → Get Root Process Group"
2. Click "Send"
3. Process Group ID is automatically saved to `{{process_group_id}}`

**Step 3: Create Processors**

1. Open "Processors → Create GenerateFlowFile Processor"
2. Click "Send"
3. Processor ID is saved to `{{source_processor_id}}`

4. Open "Processors → Create LogAttribute Processor"
5. Click "Send"
6. Processor ID is saved to `{{dest_processor_id}}`

**Step 4: Create Connection**

1. Open "Connections → Create Connection"
2. Click "Send"
3. Connection is created between the two processors

**Step 5: Start Processors**

1. Open "Workflow Management → Start Processor"
2. Set `{{processor_id}}` to your processor ID (or use saved IDs)
3. Click "Send"
4. Repeat for each processor

### Thunder Client Variables

The environment includes these variables:

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `base_url` | `https://localhost:8443/nifi-api` | NiFi API base URL |
| `username` | `admin` | NiFi username |
| `password` | `adminadminadmin` | NiFi password |
| `token` | (empty) | JWT token (auto-populated) |
| `process_group_id` | (empty) | Process group ID (auto-populated) |
| `processor_id` | (empty) | Generic processor ID |
| `source_processor_id` | (empty) | Source processor for connections |
| `dest_processor_id` | (empty) | Destination processor for connections |

**Customizing Variables:**

1. Click "Env" tab in Thunder Client
2. Select "NiFi Local" environment
3. Edit variable values
4. Click "Save"

### Thunder Client Tips

**Auto-populate variables:**
Many requests include "Tests" that automatically extract values from responses and save them to environment variables.

**Example:** "Get Access Token" extracts the token and saves it to `{{token}}`

**View response:**
- Body tab: JSON response
- Headers tab: Response headers
- Tests tab: Variable extraction tests
- Timeline tab: Request timing

**SSL Certificate:**
Thunder Client automatically accepts self-signed certificates (no additional configuration needed).

---

## Workflow Operations

### View Workflow Status

**Shell Script:**
```bash
./list_processors.sh
```

**Thunder Client:**
- Request: "Processors → List Processors"
- Shows all processors with IDs, names, types, and states

**curl:**
```bash
TOKEN=$(./get_token.sh)
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/root/processors" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.processors[] | {id, name: .component.name, state: .component.state}'
```

### Monitor Workflow Activity

**View NiFi Logs:**
```bash
docker-compose logs -f nifi
```

**Filter for LogAttribute output:**
```bash
docker-compose logs -f nifi | grep "Sample Workflow"
```

**View in UI:**
```bash
open https://localhost:8443/nifi
```

### Manage Processor State

**Start a processor:**
```bash
# Using script
./start_workflow.sh <processor_id>

# Using Thunder Client
# Request: "Workflow Management → Start Processor"
# Set {{processor_id}} variable

# Using curl
curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}/run-status" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"revision": {"version": 0}, "state": "RUNNING"}'
```

**Stop a processor:**
```bash
# Using script
./stop_workflow.sh <processor_id>

# Using Thunder Client
# Request: "Workflow Management → Stop Processor"

# Using curl
curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}/run-status" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"revision": {"version": 0}, "state": "STOPPED"}'
```

### Delete Workflow

**Delete a processor:**
```bash
# Must be stopped first
./stop_workflow.sh <processor_id>

# Using Thunder Client
# Request: "Workflow Management → Delete Processor"

# Using curl (must know current revision)
curl -s -k -X DELETE \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}?version=0" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Note:** Delete connections before deleting processors.

### Clean Up Everything

```bash
# Stop all processors
./stop_workflow.sh

# Delete NiFi and all data
docker-compose down -v

# Start fresh
docker-compose up -d
```

---

## Understanding the Workflow

### Processor Properties

Each processor is configured via the REST API with these key fields:

**Type and Bundle:**
```json
{
  "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
  "bundle": {
    "group": "org.apache.nifi",
    "artifact": "nifi-standard-nar",
    "version": "2.6.0"
  }
}
```

**Position (for UI display):**
```json
{
  "position": {
    "x": 400,
    "y": 200
  }
}
```

**Configuration:**
```json
{
  "config": {
    "properties": {
      "File Size": "1KB",
      "Batch Size": "1"
    },
    "schedulingPeriod": "60 sec",
    "schedulingStrategy": "TIMER_DRIVEN",
    "autoTerminatedRelationships": ["success"]
  }
}
```

### Connection Properties

Connections link processors via relationships:

```json
{
  "component": {
    "source": {
      "id": "source-processor-id",
      "groupId": "process-group-id",
      "type": "PROCESSOR"
    },
    "destination": {
      "id": "dest-processor-id",
      "groupId": "process-group-id",
      "type": "PROCESSOR"
    },
    "selectedRelationships": ["success"],
    "backPressureDataSizeThreshold": "1 GB",
    "backPressureObjectThreshold": "10000",
    "flowFileExpiration": "0 sec"
  }
}
```

**Key Fields:**
- `selectedRelationships`: Which relationships to route (success, failure, etc.)
- `backPressureDataSizeThreshold`: Max data size in queue before backpressure
- `backPressureObjectThreshold`: Max flowfile count before backpressure
- `flowFileExpiration`: How long flowfiles can sit in queue

### Revision Control

NiFi uses optimistic locking via revision numbers:

```json
{
  "revision": {
    "version": 0
  }
}
```

**When creating:** version = 0
**When updating:** Use current version from GET request

This prevents concurrent modification conflicts.

### Processor States

| State | Description |
|-------|-------------|
| `STOPPED` | Processor is not running |
| `RUNNING` | Processor is actively processing |
| `DISABLED` | Processor cannot be started |
| `VALIDATING` | Processor is validating configuration |

### Relationships

Each processor has defined relationships for routing:

**Common relationships:**
- `success`: Successful processing
- `failure`: Processing failed
- `original`: Original flowfile (for processors that create copies)
- `matched`: Matched a condition
- `unmatched`: Did not match condition

**Auto-termination:**
Relationships can be auto-terminated (flowfiles are deleted) instead of requiring a connection.

---

## Customizing the Workflow

### Add More Processors

**Available Standard Processors:**
- `GenerateFlowFile` - Test data generation
- `LogAttribute` - Logging and debugging
- `UpdateAttribute` - Add/modify attributes
- `RouteOnAttribute` - Conditional routing
- `ReplaceText` - Text transformation
- `ConvertRecord` - Format conversion
- `PutFile` - Write to filesystem
- `GetFile` - Read from filesystem
- `InvokeHTTP` - HTTP requests

### Example: Add RouteOnAttribute

```bash
curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
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
      "name": "RouteOnAttribute",
      "position": {"x": 700, "y": 400},
      "config": {
        "properties": {
          "Routing Strategy": "Route to Property name",
          "large": "${fileSize:gt(1000)}",
          "small": "${fileSize:le(1000)}"
        }
      }
    }
  }'
```

### Modify Processor Configuration

1. Get current processor state (includes revision)
2. Modify properties
3. PUT updated configuration with current revision

**Example:**
```bash
# Get current state
PROC_STATE=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

REVISION=$(echo "$PROC_STATE" | jq -r '.revision.version')

# Update configuration
curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": ${REVISION}},
    \"component\": {
      \"id\": \"${PROCESSOR_ID}\",
      \"config\": {
        \"schedulingPeriod\": \"30 sec\"
      }
    }
  }"
```

---

## Troubleshooting

### Workflow doesn't start

**Check processor validation:**
```bash
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.component.validationErrors'
```

**Common issues:**
- Missing required properties
- Invalid property values
- Relationships not configured

### Flowfiles stuck in queue

**View connection queue:**
```bash
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/connections/${CONNECTION_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.status.aggregateSnapshot'
```

**Solutions:**
- Check downstream processor is running
- Check for validation errors
- Increase backpressure thresholds
- Empty queue via UI if needed

### Cannot delete processor

**Error:** "Processor has incoming connections"

**Solution:** Delete connections first:
```bash
# List connections
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.connections[].id'

# Delete each connection
curl -s -k -X DELETE \
  "https://localhost:8443/nifi-api/connections/${CONNECTION_ID}?version=0" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Script fails with revision conflict

**Cause:** Processor was modified between GET and PUT

**Solution:** Always fetch latest revision immediately before update:
```bash
REVISION=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.revision.version')

# Use $REVISION immediately in next request
```

---

## Next Steps

1. **Explore NiFi UI:** https://localhost:8443/nifi
2. **View API documentation:** https://localhost:8443/nifi-docs/rest-api/
3. **Read processor documentation:** Click processor → View Details → Documentation
4. **Experiment with Thunder Client:** Modify requests and create your own
5. **Build custom workflows:** Combine different processors for your use case

## Additional Resources

- [API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md) - Detailed API reference
- [SETUP.md](SETUP.md) - Installation and configuration
- [CLAUDE.md](CLAUDE.md) - Development guidance
- [Apache NiFi Documentation](https://nifi.apache.org/docs.html)
- [NiFi Expression Language Guide](https://nifi.apache.org/docs/nifi-docs/html/expression-language-guide.html)
