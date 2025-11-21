# NiFi Flow Management Guide

Complete guide for creating, pushing, exporting, and managing NiFi flows via REST API.

## Table of Contents
- [Creating and Pushing Flows](#creating-and-pushing-flows)
- [Exporting Flows](#exporting-flows)
- [Flow Testing](#flow-testing)
- [Flow Patterns](#flow-patterns)
- [Best Practices](#best-practices)

---

## Creating and Pushing Flows

### Quick Start: Create Complete Flow

The easiest way to create and push a complete flow:

```bash
# Create a complete data processing flow
./create_and_push_flow.sh
```

This creates a production-ready flow:

```
┌─────────────┐
│ ListenHTTP  │  (Receives HTTP POST on port 9999)
└──────┬──────┘
       │ success
       ▼
┌─────────────────┐
│ RouteOnAttribute│  (Routes by 'size' query parameter)
└────┬───────┬────┘
     │       │
large│       │small
     ▼       ▼
┌────────┐ ┌────────┐
│Update  │ │Update  │  (Adds metadata and category)
│(Large) │ │(Small) │
└───┬────┘ └───┬────┘
    │          │
    └────┬─────┘
         ▼
┌─────────────┐
│  PutFile    │  (Saves to /tmp/nifi-output/{category})
└─────────────┘
```

### What the Script Does

1. **Authenticates** with NiFi
2. **Creates Process Group** named "Data Processing Flow"
3. **Creates Processors**:
   - ListenHTTP (port 9999, path /data)
   - RouteOnAttribute (routes by size parameter)
   - UpdateAttribute x2 (for large and small)
   - PutFile (stores files by category)
4. **Creates Connections** between all processors
5. **Returns IDs** for all components

### Starting the Flow

```bash
# Start all processors in the flow
./start_workflow.sh

# Or start specific processors
./start_workflow.sh <processor-id-1> <processor-id-2>
```

### Testing the Flow

```bash
# Test with large files
curl -X POST http://localhost:9999/data?size=large \
  -d 'This is large file content'

# Test with small files
curl -X POST http://localhost:9999/data?size=small \
  -d 'This is small file content'

# Check output files
ls -la /tmp/nifi-output/large/
ls -la /tmp/nifi-output/small/
```

**Note:** The ListenHTTP processor listens on port 9999 within the Docker container. You may need to map this port in docker-compose.yml:

```yaml
ports:
  - "8443:8443"
  - "9999:9999"  # Add this line
```

Then restart NiFi:
```bash
docker-compose down
docker-compose up -d
```

---

## Exporting Flows

### Export Entire Flow

```bash
# Export root process group
./export_flow.sh

# Export specific process group
./export_flow.sh <process-group-id>
```

**Output:**
```
╔════════════════════════════════════════════════════════════╗
║              NiFi Flow Exporter                            ║
╚════════════════════════════════════════════════════════════╝

[1/3] Authenticating...
✓ Authenticated

[2/3] Getting process group details...
✓ Process Group: Data_Processing_Flow (abc-123-def)

[3/3] Exporting flow...
✓ Flow exported successfully

Export Summary:
  Process Group: Data_Processing_Flow
  File: ./flows/Data_Processing_Flow_20251121_120000.json
  Size: 45K
  Processors: 5
  Connections: 5

To import this flow:
  1. Use NiFi UI: Upload Template
  2. Or use: ./import_flow.sh ./flows/Data_Processing_Flow_20251121_120000.json
```

### Export Output

Flows are exported to `./flows/` directory with timestamp:
- `root_20251121_120000.json`
- `Data_Processing_Flow_20251121_120000.json`

### What's Exported

The export includes:
- All processors with full configuration
- All connections
- All relationships
- Processor positions (for UI display)
- Custom properties
- Auto-termination settings

### Export Format

The exported JSON follows NiFi's Flow Definition format:

```json
{
  "processGroupFlow": {
    "id": "abc-123",
    "uri": "https://localhost:8443/nifi-api/...",
    "breadcrumb": {...},
    "flow": {
      "processGroups": [],
      "processors": [
        {
          "id": "proc-123",
          "component": {
            "name": "ListenHTTP",
            "type": "org.apache.nifi.processors.standard.ListenHTTP",
            "config": {
              "properties": {
                "Listening Port": "9999",
                "Base Path": "data"
              }
            }
          }
        }
      ],
      "connections": [...]
    }
  }
}
```

---

## Flow Testing

### Manual Testing Workflow

**1. Create the flow:**
```bash
./create_and_push_flow.sh
```

**2. Start processors:**
```bash
./start_workflow.sh
```

**3. Send test data:**
```bash
# Test large routing
curl -X POST http://localhost:9999/data?size=large \
  -H "Content-Type: text/plain" \
  -d "Large file test data $(date)"

# Test small routing
curl -X POST http://localhost:9999/data?size=small \
  -H "Content-Type: text/plain" \
  -d "Small file test data $(date)"
```

**4. Verify output:**
```bash
# Check files were created
ls -lR /tmp/nifi-output/

# View file contents
cat /tmp/nifi-output/large/*.large
cat /tmp/nifi-output/small/*.small
```

**5. Monitor in UI:**
```bash
open https://localhost:8443/nifi
```

### Monitoring Flow Activity

**View processor statistics:**
```bash
TOKEN=$(./get_token.sh)

curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.status.aggregateSnapshot'
```

**Output:**
```json
{
  "bytesIn": 1024,
  "bytesOut": 1024,
  "flowFilesIn": 5,
  "flowFilesOut": 5,
  "bytesRead": 0,
  "bytesWritten": 1024,
  "activeThreadCount": 0
}
```

**View connection queues:**
```bash
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.connections[] | {
    name: .component.name,
    queued: .status.aggregateSnapshot.queued
  }'
```

**View NiFi logs:**
```bash
# All logs
docker-compose logs -f nifi

# Filter for specific processor
docker-compose logs -f nifi | grep "ListenHTTP"

# Filter for errors
docker-compose logs -f nifi | grep -i error
```

---

## Flow Patterns

### Pattern 1: HTTP → Process → Store

**Use Case:** Receive data via HTTP, process, and store

```bash
./create_and_push_flow.sh
```

**Components:**
- ListenHTTP: Receives data
- RouteOnAttribute: Routes based on criteria
- UpdateAttribute: Adds metadata
- PutFile: Stores to filesystem

### Pattern 2: Generate → Transform → Route

**Use Case:** Generate test data, transform, route to destinations

```bash
./create_sample_workflow.sh
```

**Components:**
- GenerateFlowFile: Creates test data
- LogAttribute: Logs for debugging
- UpdateAttribute: Transforms data
- Auto-terminate: Ends flow

### Pattern 3: Custom Flow via API

Create your own flow programmatically:

```bash
#!/bin/bash

TOKEN=$(./get_token.sh)
PG_ID=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.processGroupFlow.id')

# Create processor
PROCESSOR=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.GetFile",
      "bundle": {
        "group": "org.apache.nifi",
        "artifact": "nifi-standard-nar",
        "version": "2.6.0"
      },
      "name": "Get Files",
      "config": {
        "properties": {
          "Input Directory": "/tmp/input",
          "Keep Source File": "false"
        }
      }
    }
  }')

echo $PROCESSOR | jq '.'
```

### Available Processor Types

Common NiFi processors you can use:

**Data Ingestion:**
- `org.apache.nifi.processors.standard.GetFile` - Read from filesystem
- `org.apache.nifi.processors.standard.ListenHTTP` - HTTP endpoint
- `org.apache.nifi.processors.standard.GetHTTP` - HTTP client
- `org.apache.nifi.processors.standard.ListenTCP` - TCP listener
- `org.apache.nifi.processors.standard.ConsumeKafka` - Kafka consumer

**Data Transformation:**
- `org.apache.nifi.processors.standard.UpdateAttribute` - Modify attributes
- `org.apache.nifi.processors.standard.ReplaceText` - Text transformation
- `org.apache.nifi.processors.standard.ConvertRecord` - Format conversion
- `org.apache.nifi.processors.standard.JoltTransformJSON` - JSON transformation
- `org.apache.nifi.processors.script.ExecuteScript` - Custom scripts

**Data Routing:**
- `org.apache.nifi.processors.standard.RouteOnAttribute` - Attribute-based routing
- `org.apache.nifi.processors.standard.RouteOnContent` - Content-based routing
- `org.apache.nifi.processors.standard.DistributeLoad` - Load balancing

**Data Output:**
- `org.apache.nifi.processors.standard.PutFile` - Write to filesystem
- `org.apache.nifi.processors.standard.InvokeHTTP` - HTTP requests
- `org.apache.nifi.processors.standard.PutKafka` - Kafka producer
- `org.apache.nifi.processors.standard.PutSQL` - Database insert

**Utility:**
- `org.apache.nifi.processors.standard.LogAttribute` - Logging
- `org.apache.nifi.processors.standard.GenerateFlowFile` - Test data
- `org.apache.nifi.processors.standard.Wait` - Synchronization
- `org.apache.nifi.processors.standard.Notify` - Signaling

---

## Best Practices

### Flow Design

**1. Use Process Groups:**
Group related processors together for organization:

```bash
# Create process group first
PG_RESPONSE=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${ROOT_PG_ID}/process-groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "name": "My Data Pipeline",
      "position": {"x": 100, "y": 100}
    }
  }')

NEW_PG_ID=$(echo "$PG_RESPONSE" | jq -r '.id')

# Then create processors inside it
# ...
```

**2. Name Components Descriptively:**
```json
{
  "component": {
    "name": "Extract Customer Data",  // Good
    // vs
    "name": "Processor 1"  // Bad
  }
}
```

**3. Auto-terminate Unused Relationships:**
```json
{
  "config": {
    "autoTerminatedRelationships": ["failure", "unmatched"]
  }
}
```

**4. Set Appropriate Queue Limits:**
```json
{
  "component": {
    "backPressureDataSizeThreshold": "1 GB",
    "backPressureObjectThreshold": "10000",
    "flowFileExpiration": "60 min"
  }
}
```

### Performance

**1. Use Batching:**
```json
{
  "properties": {
    "Batch Size": "1000"
  },
  "schedulingPeriod": "0 sec",
  "concurrentlySchedulableTaskCount": "4"
}
```

**2. Optimize Scheduling:**
- `0 sec` - Maximum throughput (CPU intensive)
- `1 sec` - Balanced
- `60 sec` - Low frequency checks

**3. Control Concurrency:**
```json
{
  "config": {
    "concurrentlySchedulableTaskCount": "4"
  }
}
```

### Error Handling

**1. Route Failures:**
Always connect failure relationships:

```bash
# Create failure path
curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": 0},
    \"component\": {
      \"source\": {\"id\": \"${PROCESSOR_ID}\"},
      \"destination\": {\"id\": \"${ERROR_HANDLER_ID}\"},
      \"selectedRelationships\": [\"failure\"]
    }
  }"
```

**2. Log Errors:**
Add LogAttribute processors on failure paths:

```json
{
  "type": "org.apache.nifi.processors.standard.LogAttribute",
  "config": {
    "properties": {
      "Log Level": "error",
      "Log Prefix": "FAILURE: "
    }
  }
}
```

### Security

**1. Don't Hardcode Credentials:**
Use NiFi variables or parameter contexts:

```json
{
  "properties": {
    "Username": "#{db_username}",
    "Password": "#{db_password}"
  }
}
```

**2. Validate Input:**
Use processors like ValidateRecord before processing untrusted data.

**3. Use HTTPS:**
Always use HTTPS in production (included in this setup).

### Version Control

**1. Export Regularly:**
```bash
# Export after changes
./export_flow.sh <process-group-id>

# Commit to git
git add flows/
git commit -m "Updated data processing flow"
```

**2. Name Exports Meaningfully:**
```bash
mv flows/root_20251121_120000.json \
   flows/customer_pipeline_v1.0.json
```

**3. Document Changes:**
Add comments to connection names:
```json
{
  "component": {
    "name": "Success → Store (v2.1 - Added retry logic)"
  }
}
```

---

## Troubleshooting

### Flow Won't Start

**Check validation errors:**
```bash
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.component.validationErrors'
```

**Common issues:**
- Missing required properties
- Invalid file paths
- Port already in use
- Insufficient permissions

### Flowfiles Stuck in Queue

**View queue:**
```bash
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/connections/${CONNECTION_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.status.aggregateSnapshot'
```

**Solutions:**
- Check downstream processor is running
- Check for backpressure
- Empty queue via UI if needed

### HTTP Endpoint Not Accessible

**For ListenHTTP processor:**

1. **Map port in docker-compose.yml:**
```yaml
services:
  nifi:
    ports:
      - "8443:8443"
      - "9999:9999"  # Add this
```

2. **Restart container:**
```bash
docker-compose down
docker-compose up -d
```

3. **Test connection:**
```bash
curl -v http://localhost:9999/data
```

### Export/Import Issues

**Export fails:**
- Verify process group ID is correct
- Check authentication token is valid
- Ensure output directory exists: `mkdir -p flows`

**Import limitations:**
- Full flow import requires NiFi UI
- REST API import recreates structure only
- Use templates for complete import/export

---

## Next Steps

1. **Create your first flow:**
   ```bash
   ./create_and_push_flow.sh
   ```

2. **Test it:**
   ```bash
   ./start_workflow.sh
   curl -X POST http://localhost:9999/data?size=large -d "test"
   ```

3. **Export it:**
   ```bash
   ./export_flow.sh
   ```

4. **Customize it:**
   - Modify processor properties
   - Add more processors
   - Change routing logic

## Additional Resources

- [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) - Basic workflow patterns
- [API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md) - Complete API reference
- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
- [Apache NiFi Documentation](https://nifi.apache.org/docs.html)
