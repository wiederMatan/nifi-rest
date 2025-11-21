# Apache NiFi 2.6.0 Docker Setup Guide

## Prerequisites

- Docker (version 20.10 or later)
- Docker Compose (version 1.29 or later)

Verify installation:
```bash
docker --version
docker-compose --version
```

## Installation Steps

### 1. Configure Environment Variables

Copy the example environment file and customize credentials:

```bash
cp .env.example .env
```

Edit `.env` and set your desired username and password:
```bash
NIFI_USERNAME=admin
NIFI_PASSWORD=your_secure_password_min_12_chars
```

**Important:** The password must be at least 12 characters long.

### 2. Start NiFi

```bash
docker-compose up -d
```

This will:
- Pull the `apache/nifi:2.6.0` image from Docker Hub
- Start NiFi container with persistent volumes
- Enable HTTPS on port 8443

### 3. Wait for NiFi to Start

NiFi takes 1-3 minutes to fully initialize. Monitor the logs:

```bash
docker-compose logs -f nifi
```

Look for the message indicating NiFi is ready:
```
NiFi has started. The UI is available at the following URLs:
```

Press `Ctrl+C` to exit log viewing.

### 4. Access NiFi UI

Open your browser and navigate to:
```
https://localhost:8443/nifi
```

**Note:** You'll see a security warning because NiFi uses a self-signed certificate. Click "Advanced" and proceed to the site.

Login with the credentials you set in `.env`:
- Username: `admin` (or your custom username)
- Password: Your configured password

## Common Commands

### Start NiFi
```bash
docker-compose up -d
```

### Stop NiFi
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f nifi
```

### Restart NiFi
```bash
docker-compose restart nifi
```

### Stop and Remove All Data
```bash
docker-compose down -v
```
**Warning:** This removes all volumes and will delete your flows and data!

## Obtaining API Access Token

NiFi 2.x requires authentication for REST API calls. To get an access token:

### Method 1: Using the provided script
```bash
./get_token.sh
```

### Method 2: Manual curl command
```bash
curl -k -X POST \
  https://localhost:8443/nifi-api/access/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin"
```

This returns a JWT token that you'll use in subsequent API calls.

## Getting Processor and Process Group IDs

### Get Root Process Group ID
```bash
TOKEN=$(curl -k -X POST https://localhost:8443/nifi-api/access/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin")

curl -k -X GET https://localhost:8443/nifi-api/flow/process-groups/root \
  -H "Authorization: Bearer $TOKEN" | jq -r '.processGroupFlow.id'
```

### List Processors in a Process Group
```bash
curl -k -X GET "https://localhost:8443/nifi-api/process-groups/{processGroupId}/processors" \
  -H "Authorization: Bearer $TOKEN" | jq '.processors[] | {id: .id, name: .component.name}'
```

## Troubleshooting

### Container won't start
Check logs for errors:
```bash
docker-compose logs nifi
```

### Can't access UI
- Ensure port 8443 is not already in use: `lsof -i :8443`
- Wait longer - NiFi startup can take 2-3 minutes
- Check container status: `docker-compose ps`

### Authentication fails
- Verify password is at least 12 characters
- Check credentials in `.env` file
- Restart container: `docker-compose restart nifi`

### API calls return 401 Unauthorized
- Token may have expired - obtain a new one
- Ensure you're using HTTPS (not HTTP)
- Verify the Bearer token is included in the Authorization header
