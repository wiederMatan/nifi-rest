# NiFi REST API Connection Guide

Complete guide for connecting to Apache NiFi 2.6.0 via REST API, including authentication, workflows, client libraries, and troubleshooting.

## Table of Contents
- [Authentication Methods](#authentication-methods)
- [Connection Workflow](#connection-workflow)
- [Common API Endpoints](#common-api-endpoints)
- [Client Libraries](#client-libraries)
- [Troubleshooting](#troubleshooting)

---

## Authentication Methods

### Token-Based Authentication (JWT)

**Primary method for NiFi 2.x** - Used throughout this project.

#### How It Works
1. POST credentials to `/nifi-api/access/token`
2. Receive JWT token as plain text response
3. Include token in `Authorization: Bearer <token>` header for all subsequent requests

#### Example
```bash
# Obtain token
TOKEN=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin")

# Use token in requests
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}"
```

#### Using Project Scripts
```bash
# Get token using helper script
TOKEN=$(./get_token.sh)

# Or set environment variable
export TOKEN=$(./get_token.sh)
```

### Username/Password Authentication Flow

**Single User Mode** (default in this project):
- Configured via `SINGLE_USER_CREDENTIALS_USERNAME` and `SINGLE_USER_CREDENTIALS_PASSWORD` in docker-compose.yml
- Credentials set in `.env` file
- Minimum password length: 12 characters
- After obtaining JWT token, no further password exchanges needed

### Certificate-Based Authentication (mTLS)

For production deployments with enhanced security:

```bash
# Using client certificate with curl
curl -k \
  --key ./nifi-client.key \
  --cert ./nifi-client.crt \
  "https://nifi-host:8443/nifi-api/flow/process-groups/root"
```

**Requirements:**
- Client keystore with private key
- Client certificate trusted by NiFi
- Server certificate (NiFi) trusted by client
- Configure SSL Context Service in NiFi

### NiFi 1.x vs 2.x Authentication Differences

| Feature | NiFi 1.x | NiFi 2.x |
|---------|----------|----------|
| JWT Support | Added in 1.0+ | Standard |
| Single User Mode | Optional | Default option |
| Auth Endpoint | `/nifi-api/access/token` | Same |
| Token Format | JWT | JWT |
| Bearer Header | Supported | Required |

---

## Connection Workflow

### Step 1: Obtain Access Token

```bash
TOKEN=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${NIFI_USERNAME}&password=${NIFI_PASSWORD}")

# Verify token was obtained
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Failed to obtain token"
    exit 1
fi
```

### Step 2: Make Authenticated API Calls

```bash
# Get root process group
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

### Step 3: Parse Responses and Extract Data

```bash
# Extract process group ID
PG_ID=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.processGroupFlow.id')

echo "Process Group ID: ${PG_ID}"
```

### Token Expiration and Refresh

#### Check Token Expiration
```bash
# Get expiration timestamp (Unix milliseconds)
EXPIRATION=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/access/token/expiration" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.expiration')

# Convert to human-readable date
date -r $((EXPIRATION / 1000))
```

#### Automatic Refresh Pattern
```bash
get_valid_token() {
  local token="$1"

  # Check if token is still valid
  local response=$(curl -s -k -w "\n%{http_code}" -X GET \
    "https://localhost:8443/nifi-api/access" \
    -H "Authorization: Bearer ${token}")

  local http_code=$(echo "${response}" | tail -n1)

  if [ "${http_code}" == "200" ]; then
    echo "${token}"
  else
    # Token expired, get new one
    ./get_token.sh
  fi
}

# Usage
TOKEN=$(get_valid_token "${TOKEN}")
```

### Required Headers

**Minimum (GET requests):**
```bash
Authorization: Bearer <token>
```

**Recommended (POST/PUT/DELETE):**
```bash
Authorization: Bearer <token>
Content-Type: application/json
X-Requested-With: XMLHttpRequest
```

**Example from create_connection.sh:**
```bash
curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${CONNECTION_PAYLOAD}"
```

---

## Common API Endpoints

### System Diagnostics (Health Check)

```bash
# Check NiFi health - no authentication required
curl -k -f "https://localhost:8443/nifi-api/system-diagnostics"

# Response includes:
# - JVM memory usage
# - Garbage collection stats
# - CPU metrics
# - Disk utilization
```

Used in docker-compose.yml healthcheck.

### Access Token Endpoint

```bash
POST /nifi-api/access/token
Content-Type: application/x-www-form-urlencoded

username=admin&password=adminadminadmin
```

Response: Raw JWT token string (not JSON)

### Token Status Endpoints

```bash
# Verify token is valid
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/access" \
  -H "Authorization: Bearer ${TOKEN}"

# Response codes:
# 200: Token valid
# 401: Token invalid/expired
# 403: Insufficient permissions

# Get token expiration time
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/access/token/expiration" \
  -H "Authorization: Bearer ${TOKEN}"

# Response: {"expiration": 1234567890000}
```

### Flow/Process Groups Endpoint

```bash
# Get root process group (entry point for flow operations)
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# Response includes:
# - processGroupFlow.id (actual root PG ID)
# - processGroupFlow.processGroups[] (nested groups)
# - processGroupFlow.processors[] (processors in this group)
# - revision (required for modifications)
```

### Processor Endpoints

```bash
# List processors in a process group
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/processors" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# Get specific processor details
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# Check processor's available relationships
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.component.relationships[].name'
```

### Connection Endpoints

```bash
# Create connection between processors
curl -s -k -X POST \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "revision": {"version": 0},
    "component": {
      "source": {"id": "source-processor-id", "type": "PROCESSOR"},
      "destination": {"id": "dest-processor-id", "type": "PROCESSOR"},
      "selectedRelationships": ["success"]
    }
  }'

# List connections in process group
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}/connections" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

### About Endpoint (Version Info)

```bash
# Get NiFi version and build info - no authentication required
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/about" | jq '.'

# Response example:
# {
#   "version": "2.6.0",
#   "buildTag": "nifi-2.6.0",
#   "buildUrl": "...",
#   "buildBranch": "...",
#   "buildRevision": "...",
#   "buildDate": "..."
# }
```

### API Response Structure

Most NiFi API responses follow this pattern:
```json
{
  "revision": {
    "version": 0,
    "clientId": "client-id"
  },
  "id": "component-id",
  "uri": "https://localhost:8443/nifi-api/...",
  "component": {
    "id": "processor-id",
    "name": "Processor Name",
    "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
    "state": "RUNNING",
    "config": {...}
  }
}
```

**Key fields:**
- `revision.version`: Required for modifications (prevents conflicts)
- `id`: Component identifier
- `component`: Actual component data and configuration

---

## Client Libraries

### Python

#### nipyapi (Recommended)

High-level Python wrapper for NiFi REST API.

**Installation:**
```bash
pip install nipyapi
```

**Basic Usage:**
```python
import nipyapi
from nipyapi import config, utils

# Configure endpoint
config.nifi_config.host = 'https://localhost:8443/nifi-api'

# Authenticate
utils.set_endpoint(
    config.nifi_config.host,
    ssl=True,
    login=True,
    username='admin',
    password='adminadminadmin',
    verify_ssl=False  # For self-signed certs
)

# Get root process group
root_pg = nipyapi.flow.get_root_pg()
print(f"Root PG ID: {root_pg.id}")

# List all processors
processors = nipyapi.processors.list_all_processors()
for proc in processors:
    print(f"{proc.component.name}: {proc.component.state}")

# Create connection
connection = nipyapi.canvas.create_connection(
    source=source_processor,
    target=dest_processor,
    relationships=['success']
)
```

**Documentation:** https://nipyapi.readthedocs.io

#### Custom Python Client

```python
import requests
import json

class NiFiClient:
    def __init__(self, url, username, password, verify_ssl=False):
        self.url = url
        self.verify_ssl = verify_ssl
        self.token = self._get_token(username, password)

    def _get_token(self, username, password):
        response = requests.post(
            f"{self.url}/access/token",
            data={"username": username, "password": password},
            verify=self.verify_ssl
        )
        response.raise_for_status()
        return response.text

    def _headers(self):
        return {"Authorization": f"Bearer {self.token}"}

    def get_root_pg(self):
        response = requests.get(
            f"{self.url}/flow/process-groups/root",
            headers=self._headers(),
            verify=self.verify_ssl
        )
        return response.json()

    def list_processors(self, process_group_id):
        response = requests.get(
            f"{self.url}/process-groups/{process_group_id}/processors",
            headers=self._headers(),
            verify=self.verify_ssl
        )
        return response.json()

# Usage
client = NiFiClient(
    'https://localhost:8443/nifi-api',
    'admin',
    'adminadminadmin'
)

root = client.get_root_pg()
print(f"Root PG: {root['processGroupFlow']['id']}")

processors = client.list_processors('root')
for proc in processors['processors']:
    print(proc['component']['name'])
```

### JavaScript/TypeScript

#### Fetch-based Client

```typescript
class NiFiClient {
  private baseUrl: string;
  private token: string | null = null;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async authenticate(username: string, password: string): Promise<void> {
    const params = new URLSearchParams();
    params.append('username', username);
    params.append('password', password);

    const response = await fetch(`${this.baseUrl}/access/token`, {
      method: 'POST',
      body: params,
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });

    if (!response.ok) {
      throw new Error('Authentication failed');
    }

    this.token = await response.text();
  }

  private getHeaders(): HeadersInit {
    return {
      'Authorization': `Bearer ${this.token}`,
      'Content-Type': 'application/json'
    };
  }

  async getRootProcessGroup(): Promise<any> {
    const response = await fetch(
      `${this.baseUrl}/flow/process-groups/root`,
      { headers: this.getHeaders() }
    );
    return response.json();
  }

  async listProcessors(processGroupId: string): Promise<any> {
    const response = await fetch(
      `${this.baseUrl}/process-groups/${processGroupId}/processors`,
      { headers: this.getHeaders() }
    );
    return response.json();
  }

  async createConnection(
    processGroupId: string,
    sourceId: string,
    destId: string,
    relationship: string,
    revision: number = 0
  ): Promise<any> {
    const payload = {
      revision: { version: revision },
      component: {
        source: { id: sourceId, type: 'PROCESSOR' },
        destination: { id: destId, type: 'PROCESSOR' },
        selectedRelationships: [relationship]
      }
    };

    const response = await fetch(
      `${this.baseUrl}/process-groups/${processGroupId}/connections`,
      {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(payload)
      }
    );
    return response.json();
  }
}

// Usage
const client = new NiFiClient('https://localhost:8443/nifi-api');
await client.authenticate('admin', 'adminadminadmin');

const root = await client.getRootProcessGroup();
console.log(`Root PG ID: ${root.processGroupFlow.id}`);

const processors = await client.listProcessors('root');
processors.processors.forEach(proc => {
  console.log(`${proc.component.name}: ${proc.component.state}`);
});
```

#### Node.js Example

```javascript
const https = require('https');
const { URLSearchParams } = require('url');

// Disable certificate verification for self-signed certs
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

async function getToken(username, password) {
  const params = new URLSearchParams();
  params.append('username', username);
  params.append('password', password);

  const options = {
    hostname: 'localhost',
    port: 8443,
    path: '/nifi-api/access/token',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': params.toString().length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    });
    req.on('error', reject);
    req.write(params.toString());
    req.end();
  });
}

// Usage
const token = await getToken('admin', 'adminadminadmin');
console.log(`Token: ${token.substring(0, 20)}...`);
```

### Shell Scripts (Current Project)

This project uses shell scripts with curl and jq:

```bash
# Get token
TOKEN=$(./get_token.sh)

# List processors
./list_processors.sh

# Create connection (edit IDs first)
PROCESS_GROUP_ID="pg-id" \
SOURCE_PROCESSOR_ID="source-id" \
DESTINATION_PROCESSOR_ID="dest-id" \
./create_connection.sh
```

**Advantages:**
- No dependencies beyond curl and jq
- Direct HTTP control
- Easy to debug and modify
- Works in any Unix-like environment

---

## Troubleshooting

### SSL/TLS Certificate Issues

#### Problem: "certificate verify failed"

Self-signed certificate not trusted by system.

**Solutions:**

**Development - Skip verification:**
```bash
# curl: Use -k flag (current project default)
curl -k https://localhost:8443/nifi-api/flow/process-groups/root

# Python requests
requests.get(url, verify=False)

# Node.js
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
```

**Production - Import certificate:**
```bash
# Extract certificate from NiFi container
docker cp nifi:/opt/nifi/nifi-current/conf/certs/nifi-cert.pem ./

# Add to system truststore (macOS)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain nifi-cert.pem

# Add to system truststore (Linux)
sudo cp nifi-cert.pem /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Then remove -k from curl commands
curl https://localhost:8443/nifi-api/flow/process-groups/root
```

**Python with custom CA:**
```python
import requests
requests.get(url, verify='/path/to/nifi-cert.pem')

# Or set environment variable
import os
os.environ['REQUESTS_CA_BUNDLE'] = '/path/to/nifi-cert.pem'
```

#### Problem: Certificate hostname mismatch

Certificate issued for different hostname than accessed URL.

**Solutions:**
```bash
# View certificate details
openssl s_client -connect localhost:8443 -showcerts

# Options:
# 1. Use -k flag (development)
# 2. Access via hostname in certificate CN
# 3. Update /etc/hosts to match certificate
echo "127.0.0.1 nifi.local" | sudo tee -a /etc/hosts
```

### CORS Issues

#### Problem: "Invalid CORS request" or "No 'Access-Control-Allow-Origin'"

**Causes:**
- Browser-based requests to NiFi API
- Missing X-Requested-With header
- CSRF token required

**Solutions:**

**Add required headers:**
```bash
curl -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Requested-With: XMLHttpRequest" \
  -H "Content-Type: application/json" \
  https://localhost:8443/nifi-api/...
```

**Use server-side requests (recommended):**
- JavaScript in browser has CORS restrictions
- Use backend (Node.js, Python) as API proxy
- Server-to-server requests have no CORS issues

**Handle CSRF tokens (if enabled):**
```bash
# Extract CSRF token from cookies
CSRF_TOKEN=$(curl -s -k -c cookies.txt https://localhost:8443/nifi | \
  grep -o '__Secure-Request-Token[^;]*' | cut -d'=' -f2)

# Include in POST/PUT/DELETE requests
curl -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-CSRF-Token: ${CSRF_TOKEN}" \
  https://localhost:8443/nifi-api/...
```

### Authentication Failures

#### Problem: "Failed to obtain access token" or 401 Unauthorized

**Diagnosis:**
```bash
# Test authentication with verbose output
curl -v -k -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=wrongpassword"

# Expected on success: Raw JWT token string
# Expected on failure: Empty response or HTML error page
```

**Solutions:**

**1. Verify credentials:**
```bash
# Check .env file
cat .env | grep NIFI_

# Verify password length (minimum 12 characters)
echo "${NIFI_PASSWORD}" | wc -c
```

**2. Check NiFi status:**
```bash
# Verify NiFi is running and initialized
docker-compose ps
docker-compose logs nifi | grep "NiFi has started"

# Wait 1-3 minutes after startup for full initialization
```

**3. Check token expiration:**
```bash
# Verify token hasn't expired
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/access/token/expiration" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# If expired or past timestamp, obtain new token
TOKEN=$(./get_token.sh)
```

**4. URL encode special characters:**
```bash
# If password contains special characters
ENCODED_USER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$NIFI_USERNAME'))")
ENCODED_PASS=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$NIFI_PASSWORD'))")

curl -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -d "username=${ENCODED_USER}&password=${ENCODED_PASS}"
```

### Connection Timeout Issues

#### Problem: "Connection timed out" or "Unable to connect"

**Diagnosis:**
```bash
# Check if port is open
nc -zv localhost 8443

# Test with timeout
timeout 5 curl -k https://localhost:8443/nifi
```

**Solutions:**

**1. Verify NiFi is running:**
```bash
# Check container status
docker-compose ps nifi

# View recent logs
docker-compose logs nifi | tail -50

# Check port binding
lsof -i :8443
```

**2. Increase timeout values:**
```bash
# curl with extended timeouts
curl --connect-timeout 30 --max-time 60 \
  https://localhost:8443/nifi-api/...

# Python requests
requests.get(url, timeout=(30, 60))  # (connect, read)
```

**3. Check network connectivity:**
```bash
# Test DNS resolution
ping localhost

# Inspect Docker network
docker network ls
docker network inspect nifi-network

# Check container network
docker inspect nifi | jq '.[0].NetworkSettings'
```

**4. Check firewall:**
```bash
# macOS/Linux - check what's using port
sudo lsof -i :8443

# Verify Docker port mapping
docker ps | grep nifi
# Should show: 0.0.0.0:8443->8443/tcp
```

### API-Specific Issues

#### Problem: "Revision conflict" when modifying components

Component has been modified since you fetched it.

**Solution - Always fetch latest revision:**
```bash
# Get current revision before modifying
PG_INFO=$(curl -s -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

LATEST_REVISION=$(echo "$PG_INFO" | jq -r '.revision.version')

# Use latest revision in modification request
curl -s -k -X PUT \
  "https://localhost:8443/nifi-api/process-groups/${PG_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"revision\": {\"version\": ${LATEST_REVISION}},
    \"component\": {...}
  }"
```

**Implemented in create_connection.sh:**
```bash
# Script automatically fetches current revision
REVISION=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/process-groups/${PROCESS_GROUP_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.revision.version')
```

#### Problem: Processor not found or invalid relationship

**Solutions:**

**Verify processor exists:**
```bash
# Check if processor ID is valid
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}"

# If 404: Processor doesn't exist
# Use ./list_processors.sh to find correct ID
```

**Check available relationships:**
```bash
# Get processor's available relationships
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${PROCESSOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '.component.relationships[] | {name, description}'

# Use one of these relationship names in connection
```

**Verify both processors are in same process group:**
```bash
# Check source processor's group
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${SOURCE_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq -r '.component.parentGroupId'

# Check destination processor's group
curl -s -k -X GET \
  "https://localhost:8443/nifi-api/processors/${DEST_ID}" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq -r '.component.parentGroupId'

# Both must match to create connection
```

---

## Quick Reference

### This Project's Setup

- **NiFi Version:** 2.6.0
- **Authentication:** Single User Mode (JWT tokens)
- **URL:** https://localhost:8443
- **Default Credentials:** admin / adminadminadmin (from .env.example)
- **HTTPS:** Self-signed certificate (curl uses -k flag)
- **Token Endpoint:** `/nifi-api/access/token`
- **Entry Point:** `/nifi-api/flow/process-groups/root`

### Typical Workflow

```bash
# 1. Start NiFi
docker-compose up -d

# 2. Wait for startup (1-3 minutes)
docker-compose logs -f nifi

# 3. Get authentication token
TOKEN=$(./get_token.sh)

# 4. List processors and get IDs
./list_processors.sh

# 5. Create connections between processors
# Edit script with actual IDs first
./create_connection.sh
```

### Essential Commands

```bash
# Authentication
TOKEN=$(./get_token.sh)

# Get root process group ID
curl -s -k -X GET https://localhost:8443/nifi-api/flow/process-groups/root \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.processGroupFlow.id'

# List processors
./list_processors.sh

# Get processor details
curl -s -k -X GET https://localhost:8443/nifi-api/processors/${PROCESSOR_ID} \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# Create connection
./create_connection.sh
```

---

## Additional Resources

- [Apache NiFi REST API Documentation](https://nifi.apache.org/docs/nifi-docs/rest-api/index.html)
- [NiFi System Administrator's Guide](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html)
- [nipyapi Documentation](https://nipyapi.readthedocs.io)
- [SETUP.md](SETUP.md) - Installation and configuration guide
- [CLAUDE.md](CLAUDE.md) - Development guidance and architecture
