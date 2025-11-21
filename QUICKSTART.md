# Quick Start Guide - NiFi Workflow Creation

This guide walks you through creating your first NiFi workflow using the REST API in just 5 minutes!

## Prerequisites Check

Before starting, make sure you have:

```bash
# Check Docker is installed
docker --version
# Should show: Docker version 20.10 or higher

# Check Docker Compose is installed
docker-compose --version
# Should show: docker-compose version 1.29 or higher
```

---

## Method 1: Automated Workflow (Recommended for Beginners)

### Step 1: Configure Credentials (30 seconds)

```bash
# Navigate to project directory
cd /Users/matanwieder/Projects/nifi-rest

# Copy environment template
cp .env.example .env

# (Optional) Edit credentials - default password works for local testing
# nano .env
```

Default credentials:
- Username: `admin`
- Password: `adminadminadmin` (must be 12+ characters)

### Step 2: Start NiFi (2-3 minutes)

```bash
# Start NiFi container
docker-compose up -d

# Output will show:
# Creating network "nifi-rest_nifi-network" ... done
# Creating volume "nifi-rest_nifi_database_repository" ... done
# Creating nifi ... done
```

**Wait for NiFi to initialize** (this takes 1-3 minutes):

```bash
# Watch logs until you see "NiFi has started"
docker-compose logs -f nifi

# Press Ctrl+C when you see:
# "NiFi has started. The UI is available at the following URLs:"
```

### Step 3: Create Sample Workflow (10 seconds)

```bash
# Run the workflow creation script
./create_sample_workflow.sh
```

**You'll see:**
```
╔════════════════════════════════════════════════════════════╗
║         NiFi Sample Workflow Creator                      ║
║  Creates: GenerateFlowFile -> LogAttribute -> Route       ║
╚════════════════════════════════════════════════════════════╝

[1/8] Obtaining access token...
✓ Token obtained

[2/8] Getting root process group ID...
✓ Process Group ID: abc-123-def-456

[3/8] Creating GenerateFlowFile processor...
✓ GenerateFlowFile created: proc-111-222

[4/8] Creating LogAttribute processor...
✓ LogAttribute created: proc-333-444

[5/8] Creating UpdateAttribute processor...
✓ UpdateAttribute created: proc-555-666

[6/8] Creating connections...
  ✓ Connection 1: GenerateFlowFile -> LogAttribute
  ✓ Connection 2: LogAttribute -> UpdateAttribute

[7/8] Configuring auto-termination...
✓ Auto-termination configured

╔════════════════════════════════════════════════════════════╗
║          Workflow Created Successfully!                    ║
╚════════════════════════════════════════════════════════════╝

Workflow Summary:
  Process Group ID:     abc-123-def-456
  GenerateFlowFile ID:  proc-111-222
  LogAttribute ID:      proc-333-444
  UpdateAttribute ID:   proc-555-666
```

### Step 4: Start the Workflow (5 seconds)

```bash
# Start all processors
./start_workflow.sh
```

**You'll see:**
```
=== NiFi Workflow Starter ===

Obtaining access token...
✓ Token obtained

Starting all processors in root process group...
  ✓ Started: GenerateFlowFile (proc-111-222)
  ✓ Started: LogAttribute (proc-333-444)
  ✓ Started: UpdateAttribute (proc-555-666)

All processors started!
```

### Step 5: View Your Workflow (in browser)

```bash
# Open NiFi UI in browser
open https://localhost:8443/nifi

# Or manually navigate to:
# https://localhost:8443/nifi
```

**Login:**
- Username: `admin`
- Password: `adminadminadmin` (or whatever you set in .env)

**You'll see your workflow running!**

### Step 6: Monitor Activity

**View logs in terminal:**
```bash
# See all NiFi logs
docker-compose logs -f nifi

# Or filter for your workflow
docker-compose logs -f nifi | grep "Sample Workflow"
```

**You'll see output like:**
```
nifi_1  | Sample Workflow: logging for flow file...
nifi_1  | --------------------------------------------------
nifi_1  | Standard FlowFile Attributes
nifi_1  | Key: 'filename'
nifi_1  |   Value: '123456789'
nifi_1  | Key: 'path'
nifi_1  |   Value: './'
```

### Step 7: Stop the Workflow (when done)

```bash
# Stop all processors
./stop_workflow.sh
```

**Complete cleanup:**
```bash
# Stop NiFi but keep data
docker-compose down

# Or stop NiFi and delete all data
docker-compose down -v
```

---

## Method 2: Using Thunder Client (For VS Code Users)

### Step 1: Install Thunder Client Extension

1. Open **VS Code**
2. Click **Extensions** icon (left sidebar) or press `Cmd+Shift+X` (Mac) / `Ctrl+Shift+X` (Windows)
3. Search for **"Thunder Client"**
4. Click **Install** on "Thunder Client" by Ranga Vadhineni
5. Click the **Thunder Client** icon that appears in the Activity Bar

### Step 2: Import Collection

1. In Thunder Client, click **"Collections"** tab
2. Click the **menu icon (⋮)** → **"Import"**
3. Navigate to: `/Users/matanwieder/Projects/nifi-rest/thunder-client/`
4. Select: **`thunder-collection_NiFi REST API.json`**
5. Click **Open**

You'll see folders appear:
- Authentication
- Processors
- Connections
- Workflow Management
- System & Diagnostics

### Step 3: Import Environment

1. In Thunder Client, click **"Env"** tab
2. Click the **menu icon (⋮)** → **"Import"**
3. Navigate to: `/Users/matanwieder/Projects/nifi-rest/thunder-client/`
4. Select: **`thunder-environment_NiFi Local.json`**
5. Click **Open**

### Step 4: Select Environment

1. At the top of Thunder Client, find the **dropdown** (shows "No Environment")
2. Click it and select **"NiFi Local"**

### Step 5: Authenticate

1. Make sure NiFi is running: `docker-compose up -d`
2. In Collections, expand **"Authentication"** folder
3. Click **"Get Access Token"**
4. Click the **"Send"** button

**Response appears in the Body tab** - a long string like:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**The token is automatically saved** to the environment variable `{{token}}`!

### Step 6: Get Process Group ID

1. In Collections, expand **"Processors"** folder
2. Click **"Get Root Process Group"**
3. Click **"Send"**

**Response shows** (in Body tab):
```json
{
  "processGroupFlow": {
    "id": "abc-123-def-456",
    ...
  }
}
```

**The ID is automatically saved** to `{{process_group_id}}`!

### Step 7: Create First Processor

1. In Processors folder, click **"Create GenerateFlowFile Processor"**
2. Review the Body tab (you can modify the JSON if you want)
3. Click **"Send"**

**Response:**
```json
{
  "id": "proc-111-222-333",
  "component": {
    "name": "GenerateFlowFile",
    ...
  }
}
```

**The ID is automatically saved** to `{{source_processor_id}}`!

### Step 8: Create Second Processor

1. Click **"Create LogAttribute Processor"**
2. Click **"Send"**

**The ID is automatically saved** to `{{dest_processor_id}}`!

### Step 9: Create Connection

1. In Collections, expand **"Connections"** folder
2. Click **"Create Connection"**
3. Click **"Send"**

**Response:**
```json
{
  "id": "conn-123-456",
  "component": {
    "source": {...},
    "destination": {...}
  }
}
```

**Connection created!** ✅

### Step 10: Start Processors

**Start first processor:**
1. In Collections, expand **"Workflow Management"** folder
2. Click **"Start Processor"**
3. In the **Body** tab, you'll see:
   ```json
   {
     "revision": {"version": 0},
     "state": "RUNNING"
   }
   ```
4. In the **URL bar**, change `{{processor_id}}` to `{{source_processor_id}}`
5. Click **"Send"**

**Start second processor:**
1. Change URL to use `{{dest_processor_id}}`
2. Click **"Send"**

### Step 11: View in UI

```bash
open https://localhost:8443/nifi
```

**Your workflow is running!**

---

## Method 3: Manual API Calls (Advanced)

### Using curl commands directly

```bash
# 1. Get token
TOKEN=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin")

echo "Token: $TOKEN"

# 2. Get process group ID
PG_ID=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.processGroupFlow.id')

echo "Process Group ID: $PG_ID"

# 3. Create GenerateFlowFile processor
GENERATE_RESPONSE=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "GenerateFlowFile",
      "position": {"x": 400, "y": 200},
      "config": {
        "properties": {
          "File Size": "1KB",
          "Batch Size": "1"
        },
        "schedulingPeriod": "60 sec"
      }
    }
  }')

GENERATE_ID=$(echo "$GENERATE_RESPONSE" | jq -r '.id')
echo "GenerateFlowFile ID: $GENERATE_ID"

# 4. Create LogAttribute processor
LOG_RESPONSE=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.LogAttribute",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "LogAttribute",
      "position": {"x": 400, "y": 400},
      "config": {
        "properties": {
          "Log Level": "info"
        }
      }
    }
  }')

LOG_ID=$(echo "$LOG_RESPONSE" | jq -r '.id')
echo "LogAttribute ID: $LOG_ID"

# 5. Create connection
curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"source\": {
        \"id\": \"${GENERATE_ID}\",
        \"groupId\": \"${PG_ID}\",
        \"type\": \"PROCESSOR\"
      },
      \"destination\": {
        \"id\": \"${LOG_ID}\",
        \"groupId\": \"${PG_ID}\",
        \"type\": \"PROCESSOR\"
      },
      \"selectedRelationships\": [\"success\"]
    }
  }"

echo "Connection created!"

# 6. Start processors
curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/processors/${GENERATE_ID}/run-status" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"revision": {"version": 0}, "state": "RUNNING"}'

curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/processors/${LOG_ID}/run-status" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"revision": {"version": 0}, "state": "RUNNING"}'

echo "Workflow started!"
```

---

## Troubleshooting

### NiFi won't start

```bash
# Check if port 8443 is already in use
lsof -i :8443

# Check Docker container status
docker-compose ps

# View logs for errors
docker-compose logs nifi
```

### Cannot connect / Authentication fails

```bash
# Wait for NiFi to fully start (1-3 minutes)
docker-compose logs -f nifi | grep "NiFi has started"

# Verify credentials in .env
cat .env

# Test connection
curl -k https://localhost:8443/nifi-api/about
```

### Script says "command not found"

```bash
# Make scripts executable
chmod +x *.sh

# Or run specific script
chmod +x create_sample_workflow.sh
```

### Token expired

```bash
# Get a fresh token
TOKEN=$(./get_token.sh)

# Or re-run the workflow script (it gets a new token automatically)
./create_sample_workflow.sh
```

---

## What's Next?

1. **Explore the UI**: https://localhost:8443/nifi
2. **Modify the workflow**: Edit processor properties in Thunder Client
3. **Read the guides**:
   - [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) - Detailed workflow patterns
   - [THUNDER_CLIENT_SETUP.md](THUNDER_CLIENT_SETUP.md) - Thunder Client tips
   - [API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md) - Complete API reference

## Summary of Commands

```bash
# Complete workflow in 4 commands:
docker-compose up -d              # Start NiFi
./create_sample_workflow.sh       # Create workflow
./start_workflow.sh               # Start processors
open https://localhost:8443/nifi  # View in browser

# Stop workflow:
./stop_workflow.sh                # Stop processors
docker-compose down               # Stop NiFi
```

---

**Need help?** Check the documentation files or the troubleshooting section above!
