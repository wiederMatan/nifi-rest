# Thunder Client Setup Guide

Quick guide to get started with Thunder Client for testing NiFi REST API.

## What is Thunder Client?

Thunder Client is a lightweight REST API client extension for VS Code. It's similar to Postman but integrated directly into VS Code.

**Advantages:**
- Lightweight and fast
- No account required
- VS Code integration
- Git-friendly (JSON files)
- Supports collections and environments
- Auto-saves requests

## Installation

### Step 1: Install Extension

1. Open VS Code
2. Click Extensions icon (or press `Cmd+Shift+X` / `Ctrl+Shift+X`)
3. Search for "Thunder Client"
4. Click "Install" on the Thunder Client extension by Ranga Vadhineni

### Step 2: Open Thunder Client

- Click the Thunder Client icon in the Activity Bar (left sidebar)
- Or use Command Palette: `Cmd+Shift+P` / `Ctrl+Shift+P` → "Thunder Client: Open"

## Import NiFi Collection

### Method 1: Import via UI

1. Open Thunder Client in VS Code
2. Click "Collections" tab
3. Click the menu icon (⋮) → "Import"
4. Navigate to and select: `thunder-client/thunder-collection_NiFi REST API.json`
5. Collection appears with folders:
   - Authentication
   - Processors
   - Connections
   - Workflow Management
   - System & Diagnostics

### Method 2: Import Environment

1. Click "Env" tab in Thunder Client
2. Click menu icon (⋮) → "Import"
3. Navigate to and select: `thunder-client/thunder-environment_NiFi Local.json`
4. Select "NiFi Local" from environment dropdown

## Using the Collection

### Step 1: Get Authentication Token

1. Ensure NiFi is running: `docker-compose up -d`
2. Select environment "NiFi Local" (top right dropdown)
3. Navigate to: **Authentication → Get Access Token**
4. Click "Send" button
5. Token is automatically saved to `{{token}}` variable
6. All subsequent requests use this token

### Step 2: Get Process Group ID

1. Navigate to: **Processors → Get Root Process Group**
2. Click "Send"
3. Process Group ID is auto-saved to `{{process_group_id}}`

### Step 3: Create Processors

**Create GenerateFlowFile:**
1. Navigate to: **Processors → Create GenerateFlowFile Processor**
2. Review JSON body (modify if needed)
3. Click "Send"
4. Copy the `id` from response
5. It's auto-saved to `{{source_processor_id}}`

**Create LogAttribute:**
1. Navigate to: **Processors → Create LogAttribute Processor**
2. Click "Send"
3. ID is auto-saved to `{{dest_processor_id}}`

### Step 4: Create Connection

1. Navigate to: **Connections → Create Connection**
2. Uses `{{source_processor_id}}` and `{{dest_processor_id}}`
3. Click "Send"
4. Connection is created

### Step 5: Start Processors

1. Navigate to: **Workflow Management → Start Processor**
2. Modify `{{processor_id}}` variable or use saved IDs
3. Click "Send"
4. Repeat for each processor

## Collection Structure

### Authentication Folder
- **Get Access Token** - Obtain JWT token (auto-saves to `{{token}}`)
- **Verify Token** - Check if token is valid
- **Get Token Expiration** - Get token expiration timestamp

### Processors Folder
- **Get Root Process Group** - Get root PG ID (auto-saves to `{{process_group_id}}`)
- **List Processors** - List all processors in a process group
- **Get Processor Details** - Get details of specific processor
- **Create GenerateFlowFile Processor** - Create test data generator
- **Create LogAttribute Processor** - Create logger processor

### Connections Folder
- **Create Connection** - Connect two processors
- **List Connections** - List all connections in process group

### Workflow Management Folder
- **Start Processor** - Start a processor
- **Stop Processor** - Stop a processor
- **Delete Processor** - Delete a processor

### System & Diagnostics Folder
- **System Diagnostics** - Get NiFi system health
- **About (Version Info)** - Get NiFi version
- **Cluster Summary** - Get cluster information

## Environment Variables

The "NiFi Local" environment includes:

| Variable | Default | Auto-populated | Description |
|----------|---------|----------------|-------------|
| `base_url` | `https://localhost:8443/nifi-api` | No | NiFi API base URL |
| `username` | `admin` | No | NiFi username |
| `password` | `adminadminadmin` | No | NiFi password (12+ chars) |
| `token` | (empty) | **Yes** | JWT token from login |
| `process_group_id` | (empty) | **Yes** | Root process group ID |
| `processor_id` | (empty) | No | Generic processor ID |
| `source_processor_id` | (empty) | **Yes** | Source for connections |
| `dest_processor_id` | (empty) | **Yes** | Destination for connections |

### Editing Variables

1. Click "Env" tab
2. Select "NiFi Local"
3. Click variable to edit
4. Click "Save"

### Using Variables in Requests

Variables use double curly braces: `{{variable_name}}`

**Example URL:**
```
{{base_url}}/processors/{{processor_id}}
```

Becomes:
```
https://localhost:8443/nifi-api/processors/abc-123
```

## Tips and Tricks

### View Auto-saved Variables

1. Send a request (e.g., "Get Access Token")
2. Click "Env" tab
3. See `{{token}}` is now populated
4. This token is used automatically in all authenticated requests

### Modify Request Body

1. Select a request (e.g., "Create GenerateFlowFile Processor")
2. Click "Body" tab
3. Edit JSON directly
4. Click "Send"

**Example - Change file size:**
```json
{
  "config": {
    "properties": {
      "File Size": "10KB"  // Changed from 1KB
    }
  }
}
```

### Save Custom Requests

1. Make any request
2. Click "Save" (disk icon)
3. Give it a name
4. Select folder (or create new)
5. Request is saved to collection

### Copy as cURL

1. Right-click any request
2. Select "Copy as cURL"
3. Paste into terminal

### Disable SSL Verification

Thunder Client automatically accepts self-signed certificates. No configuration needed.

### View Response

After sending a request:
- **Body tab:** JSON response (auto-formatted)
- **Headers tab:** Response headers
- **Cookies tab:** Any cookies set
- **Tests tab:** Variable extraction tests
- **Timeline tab:** Request timing breakdown

### Set Variables from Response

Thunder Client can auto-extract values from responses.

**Example - Extract token:**
1. In request, go to "Tests" tab
2. Test already configured: Extract `token` from response
3. Saved to `{{token}}` environment variable

## Workflow Example

Complete workflow using Thunder Client:

```
1. Authentication → Get Access Token
   → Token saved to {{token}}

2. Processors → Get Root Process Group
   → Process Group ID saved to {{process_group_id}}

3. Processors → Create GenerateFlowFile Processor
   → Processor ID saved to {{source_processor_id}}

4. Processors → Create LogAttribute Processor
   → Processor ID saved to {{dest_processor_id}}

5. Connections → Create Connection
   → Uses {{source_processor_id}} and {{dest_processor_id}}

6. Workflow Management → Start Processor
   → Set {{processor_id}} to {{source_processor_id}}
   → Send request

7. Workflow Management → Start Processor
   → Set {{processor_id}} to {{dest_processor_id}}
   → Send request

8. View in NiFi UI: https://localhost:8443/nifi
```

## Troubleshooting

### Cannot connect to NiFi

**Check NiFi is running:**
```bash
docker-compose ps
```

**Check NiFi logs:**
```bash
docker-compose logs nifi | grep "NiFi has started"
```

**Wait for initialization:**
NiFi takes 1-3 minutes to start fully.

### Authentication fails

**Verify credentials in environment:**
1. Click "Env" tab
2. Check `username` and `password`
3. Ensure password is 12+ characters
4. Match credentials in `.env` file

### Token expired

**Get new token:**
1. Run: **Authentication → Get Access Token**
2. Token auto-updates in environment

### Variable not populated

**Check Tests tab:**
1. Open request
2. Click "Tests" tab
3. Verify test is configured
4. Re-send request

### Request fails with 401

**Token missing or expired:**
1. Get new token: **Authentication → Get Access Token**
2. Retry failed request

## Comparison: Thunder Client vs Shell Scripts

| Feature | Thunder Client | Shell Scripts |
|---------|---------------|---------------|
| **Setup** | Install extension, import JSON | Already included |
| **UI** | Graphical interface | Command line |
| **Variables** | Auto-populated | Manual extraction |
| **Speed** | Click to send | Type command |
| **Debugging** | View response in tabs | Parse JSON manually |
| **Flexibility** | Easy to modify | Full scripting power |
| **Automation** | Manual clicks | Scriptable |
| **Best For** | Exploration, testing | Automation, CI/CD |

## Next Steps

1. Try the **Quick Start** workflow above
2. Modify processor configurations
3. Create your own requests
4. Explore [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) for workflow patterns
5. See [API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md) for API details

## Additional Resources

- [Thunder Client Documentation](https://www.thunderclient.com/docs)
- [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) - Workflow creation guide
- [API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md) - API reference
- [NiFi REST API Docs](https://nifi.apache.org/docs/nifi-docs/rest-api/)
