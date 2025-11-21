# How to Create and Push a NiFi Flow

**Quick answer:** Run this command:

```bash
./create_and_push_flow.sh
```

That's it! This creates a complete production-ready flow and pushes it to NiFi via the REST API.

---

## What Gets Created

The script creates this flow:

```
┌─────────────┐
│ ListenHTTP  │  Listens on port 9999 at /data endpoint
└──────┬──────┘
       │ success
       ▼
┌─────────────────┐
│ RouteOnAttribute│  Routes based on 'size' query parameter
└────┬───────┬────┘
     │       │
large│       │small
     ▼       ▼
┌────────┐ ┌────────┐
│Update  │ │Update  │  Adds category and timestamp attributes
│(Large) │ │(Small) │
└───┬────┘ └───┬────┘
    │          │
    └────┬─────┘
         ▼
┌─────────────┐
│  PutFile    │  Saves to /tmp/nifi-output/{category}/
└─────────────┘
```

---

## Step-by-Step Instructions

### 1. Start NiFi (if not already running)

```bash
cd /Users/matanwieder/Projects/nifi-rest
docker-compose up -d
```

Wait 2-3 minutes for NiFi to initialize:
```bash
docker-compose logs -f nifi | grep "NiFi has started"
# Press Ctrl+C when you see the message
```

### 2. Create and Push the Flow

```bash
./create_and_push_flow.sh
```

**Output you'll see:**
```
╔════════════════════════════════════════════════════════════════╗
║            NiFi Flow Creator and Publisher                     ║
║  HTTP Listener → Route → Transform → PutFile                  ║
╚════════════════════════════════════════════════════════════════╝

[1/10] Authenticating...
✓ Authenticated successfully

[2/10] Getting root process group...
✓ Process Group ID: abc-123-def-456

[3/10] Creating process group for flow...
✓ Flow Process Group created: flow-pg-123

[4/10] Creating ListenHTTP processor...
✓ ListenHTTP created: listen-http-456

[5/10] Creating RouteOnAttribute processor...
✓ RouteOnAttribute created: route-789

[6/10] Creating UpdateAttribute (Large)...
✓ UpdateAttribute (Large) created: update-l-012

[7/10] Creating UpdateAttribute (Small)...
✓ UpdateAttribute (Small) created: update-s-345

[8/10] Creating PutFile processor...
✓ PutFile created: putfile-678

[9/10] Creating connections...
  ✓ Connection: ListenHTTP → RouteOnAttribute
  ✓ Connection: Route → UpdateAttribute (Large)
  ✓ Connection: Route → UpdateAttribute (Small)
  ✓ Connection: UpdateAttribute (Large) → PutFile
  ✓ Connection: UpdateAttribute (Small) → PutFile

╔════════════════════════════════════════════════════════════════╗
║                Flow Created and Pushed Successfully!           ║
╚════════════════════════════════════════════════════════════════╝

Flow successfully created and pushed to NiFi!
```

### 3. Start the Flow

```bash
./start_workflow.sh
```

This starts all processors in the flow.

### 4. Test the Flow

**Important:** First, expose port 9999 in docker-compose.yml:

```bash
# Edit docker-compose.yml and add port 9999
nano docker-compose.yml
```

Add this line under `ports:`:
```yaml
ports:
  - "8443:8443"
  - "9999:9999"  # Add this line
```

Restart NiFi:
```bash
docker-compose down
docker-compose up -d
# Wait 2-3 minutes for restart
```

Now test:
```bash
# Test large file routing
curl -X POST http://localhost:9999/data?size=large \
  -H "Content-Type: text/plain" \
  -d "This is large file content"

# Test small file routing
curl -X POST http://localhost:9999/data?size=small \
  -H "Content-Type: text/plain" \
  -d "This is small file content"
```

### 5. Verify Files Were Created

```bash
# Check output directory
ls -la /tmp/nifi-output/large/
ls -la /tmp/nifi-output/small/

# View file contents
cat /tmp/nifi-output/large/*.large
cat /tmp/nifi-output/small/*.small
```

### 6. View in UI

```bash
open https://localhost:8443/nifi
```

Login with:
- Username: `admin`
- Password: `adminadminadmin`

You'll see your "Data Processing Flow" process group!

---

## What Happened Behind the Scenes

The `create_and_push_flow.sh` script:

1. ✅ **Authenticated** with NiFi using username/password
2. ✅ **Created Process Group** to organize the flow
3. ✅ **Created 5 Processors**:
   - ListenHTTP (receives HTTP requests)
   - RouteOnAttribute (routes by size parameter)
   - UpdateAttribute x2 (adds metadata)
   - PutFile (saves to disk)
4. ✅ **Created 5 Connections** between processors
5. ✅ **Configured routing logic** and auto-termination
6. ✅ **Returned all IDs** for reference

All via NiFi REST API! No manual UI clicking required.

---

## Export Your Flow

To save your flow as a JSON file:

```bash
# Export the flow
./export_flow.sh <process-group-id>

# Or export root
./export_flow.sh
```

Output saved to `./flows/` directory.

---

## Common Issues

### Issue: "Connection refused" when testing HTTP

**Solution:** Add port 9999 to docker-compose.yml:
```yaml
ports:
  - "8443:8443"
  - "9999:9999"
```

Then restart:
```bash
docker-compose down && docker-compose up -d
```

### Issue: Files not appearing in /tmp/nifi-output/

**Cause:** PutFile runs inside Docker container.

**Solution:** Access files inside container:
```bash
docker exec -it nifi ls -la /tmp/nifi-output/large/
docker exec -it nifi cat /tmp/nifi-output/large/filename.large
```

Or mount a volume in docker-compose.yml:
```yaml
volumes:
  - ./output:/tmp/nifi-output
```

### Issue: Processors showing validation errors

**Solution:** Check processor configuration:
```bash
TOKEN=$(./get_token.sh)
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.component.validationErrors'
```

---

## Next Steps

1. **View flow in UI** - See visual representation
2. **Monitor activity** - Watch flowfiles move through
3. **Modify properties** - Change routing logic, file paths, etc.
4. **Export flow** - Save your work
5. **Create your own flow** - Customize the script for your needs

---

## Learn More

- **[FLOW_MANAGEMENT.md](FLOW_MANAGEMENT.md)** - Complete flow management guide
- **[WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)** - Workflow patterns and best practices
- **[QUICKSTART.md](QUICKSTART.md)** - Beginner's guide
- **[API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md)** - API reference

---

**That's it!** You've created and pushed a complete NiFi flow using the REST API. 🎉
