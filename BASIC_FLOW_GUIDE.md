# How to Create a Basic NiFi Flow

This guide shows you how to create the simplest possible NiFi flow using the REST API.

## What You'll Create

```
┌─────────────────┐
│ Generate Test   │  (Creates test data every 60 seconds)
│ Data            │
└────────┬────────┘
         │ success
         ▼
┌─────────────────┐
│ Log Data        │  (Logs to nifi-app.log)
└─────────────────┘
```

---

## Quick Start (1 Command)

```bash
./create_basic_flow.sh
```

That's it! This creates:
1. **GenerateFlowFile** processor - Creates test data
2. **LogAttribute** processor - Logs the data
3. **Connection** between them

---

## Step-by-Step Manual Process

If you want to understand what's happening, here's the manual process:

### Step 1: Get Authentication Token

```bash
TOKEN=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin")

echo "Token: $TOKEN"
```

### Step 2: Get Root Process Group ID

```bash
ROOT_RESPONSE=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

PROCESS_GROUP_ID=$(echo "$ROOT_RESPONSE" | jq -r '.processGroupFlow.id')

echo "Process Group ID: $PROCESS_GROUP_ID"
```

### Step 3: Create GenerateFlowFile Processor

```bash
GENERATE_RESPONSE=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
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
      "name": "Generate Test Data",
      "position": {"x": 200, "y": 100},
      "config": {
        "properties": {
          "File Size": "1KB",
          "Batch Size": "1",
          "Data Format": "Text",
          "Custom Text": "Hello from NiFi API!"
        },
        "schedulingPeriod": "60 sec"
      }
    }
  }')

GENERATE_ID=$(echo "$GENERATE_RESPONSE" | jq -r '.id')
echo "GenerateFlowFile ID: $GENERATE_ID"
```

**What this does:**
- Creates a processor that generates test data
- Creates 1KB of text every 60 seconds
- Text content: "Hello from NiFi API!"

### Step 4: Create LogAttribute Processor

```bash
LOG_RESPONSE=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PROCESS_GROUP_ID}/processors" \
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
      "name": "Log Data",
      "position": {"x": 200, "y": 300},
      "config": {
        "properties": {
          "Log Level": "info",
          "Log Payload": "true"
        },
        "autoTerminatedRelationships": ["success"]
      }
    }
  }')

LOG_ID=$(echo "$LOG_RESPONSE" | jq -r '.id')
echo "LogAttribute ID: $LOG_ID"
```

**What this does:**
- Creates a processor that logs data
- Logs at INFO level
- Shows the actual data content (payload)
- Auto-terminates after logging (ends the flow)

### Step 5: Create Connection

```bash
CONNECTION_RESPONSE=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PROCESS_GROUP_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"source\": {
        \"id\": \"${GENERATE_ID}\",
        \"groupId\": \"${PROCESS_GROUP_ID}\",
        \"type\": \"PROCESSOR\"
      },
      \"destination\": {
        \"id\": \"${LOG_ID}\",
        \"groupId\": \"${PROCESS_GROUP_ID}\",
        \"type\": \"PROCESSOR\"
      },
      \"selectedRelationships\": [\"success\"]
    }
  }")

CONNECTION_ID=$(echo "$CONNECTION_RESPONSE" | jq -r '.id')
echo "Connection ID: $CONNECTION_ID"
```

**What this does:**
- Connects GenerateFlowFile to LogAttribute
- Routes via "success" relationship
- When GenerateFlowFile succeeds, flowfile goes to LogAttribute

---

## View Your Flow

```bash
open https://localhost:8443/nifi
```

Login: `admin` / `adminadminadmin`

You'll see:
- "Generate Test Data" processor (top)
- Arrow pointing down
- "Log Data" processor (bottom)

---

## Start the Flow

### Option 1: Via UI
1. Right-click "Generate Test Data"
2. Click "Start"
3. Right-click "Log Data"
4. Click "Start"

### Option 2: Via Script
```bash
./start_processors.sh
```

### Option 3: Via API

Get current revision first:
```bash
PROC_STATE=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${GENERATE_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

REVISION=$(echo "$PROC_STATE" | jq -r '.revision.version')
```

Start processor:
```bash
curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/processors/${GENERATE_ID}/run-status" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"revision\":{\"version\":${REVISION}},\"state\":\"RUNNING\"}"
```

---

## Monitor the Flow

### View Logs
```bash
docker-compose logs -f nifi | grep "Hello from NiFi API"
```

### Check Processor Stats
```bash
./list_processors.sh
```

### Via UI
- Watch the numbers on the connection change
- Green numbers = data flowing
- Right-click connection → "List queue" to see flowfiles

---

## Understanding the Flow

**Every 60 seconds:**
1. **GenerateFlowFile** creates a new flowfile
   - Content: "Hello from NiFi API!"
   - Size: 1KB

2. **Connection** queues the flowfile

3. **LogAttribute** receives it and:
   - Logs all attributes
   - Logs the content
   - Terminates the flowfile

**Check logs:**
```bash
docker-compose logs nifi | tail -20
```

You'll see:
```
LogAttribute: logging for flow file...
Standard FlowFile Attributes
Key: 'filename'
  Value: '12345678'
FlowFile Payload: Hello from NiFi API!
```

---

## Common Customizations

### Change Generation Frequency

Edit `schedulingPeriod` in the create call:
```json
"schedulingPeriod": "10 sec"  // Instead of "60 sec"
```

### Change Data Content

Edit `Custom Text` property:
```json
"Custom Text": "Your custom message here!"
```

### Change File Size

Edit `File Size` property:
```json
"File Size": "10KB"  // Instead of "1KB"
```

---

## What You Learned

✅ How to authenticate with NiFi API
✅ How to get process group IDs
✅ How to create processors via API
✅ How to configure processor properties
✅ How to create connections
✅ How to start processors
✅ How data flows through NiFi

---

## Next Steps

Try modifying the script to:
1. Add more processors
2. Change processor properties
3. Add different types of processors
4. Create multiple connections

Check `SETUP.md` for more details on available processors and configurations!
