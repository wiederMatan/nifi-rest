# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project provides Docker-based setup and REST API integration scripts for Apache NiFi 2.6.0. It enables automated management of NiFi flows through the NiFi REST API, including creating connections between processors, managing process groups, and administering authentication.

## Architecture

### Docker Setup
- **NiFi Version**: 2.6.0 from Docker Hub (`apache/nifi:2.6.0`)
- **Authentication**: Single user mode with username/password stored in `.env`
- **Networking**: HTTPS on port 8443 (NiFi default secure configuration)
- **Persistence**: Docker volumes for all NiFi repositories:
  - `nifi_database_repository`: Internal database
  - `nifi_flowfile_repository`: Active flowfiles
  - `nifi_content_repository`: Flowfile content storage
  - `nifi_provenance_repository`: Data provenance records
  - `nifi_state`: Component state
  - `nifi_conf`: Configuration files
  - `nifi_logs`: Application logs

### NiFi REST API Authentication
NiFi 2.x requires JWT bearer tokens for all API calls:
1. Obtain token via POST to `/nifi-api/access/token` with username/password
2. Include token in `Authorization: Bearer <token>` header for all subsequent requests
3. Tokens expire and must be refreshed periodically

### Key API Patterns
- **Process Groups**: Containers for processors and connections. Root process group ID obtained via `/nifi-api/flow/process-groups/root`
- **Processors**: Individual processing units. Listed via `/nifi-api/process-groups/{id}/processors`
- **Connections**: Link processors via relationships (success, failure, etc.). Created via `/nifi-api/process-groups/{id}/connections`
- **Revisions**: All modification operations require current revision version to prevent conflicts

## Common Commands

### Starting and Stopping NiFi
```bash
# Start NiFi (pulls image on first run)
docker-compose up -d

# Stop NiFi (preserves data)
docker-compose down

# Stop and remove all data volumes
docker-compose down -v

# Restart NiFi
docker-compose restart nifi

# View logs
docker-compose logs -f nifi
```

### REST API Operations
```bash
# Get authentication token
./get_token.sh
# OR
TOKEN=$(./get_token.sh)

# List all processors in root process group
./list_processors.sh

# List processors in specific process group
./list_processors.sh <process-group-id>

# Create connection between processors
# Edit environment variables or script placeholders first
./create_connection.sh
```

### Manual API Calls
```bash
# Get token
TOKEN=$(curl -k -X POST https://localhost:8443/nifi-api/access/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin")

# Get root process group ID
curl -k -X GET https://localhost:8443/nifi-api/flow/process-groups/root \
  -H "Authorization: Bearer $TOKEN" | jq -r '.processGroupFlow.id'

# List processors
curl -k -X GET https://localhost:8443/nifi-api/process-groups/{id}/processors \
  -H "Authorization: Bearer $TOKEN" | jq

# Get processor details
curl -k -X GET https://localhost:8443/nifi-api/processors/{id} \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Development Workflow

### Adding New API Scripts
1. Create new shell script in project root
2. Include authentication token retrieval pattern from `get_token.sh`
3. Use `-k` flag with curl for self-signed certificates
4. Parse JSON responses with `jq` for readability
5. Include error handling for failed authentication and API errors
6. Make script executable: `chmod +x script_name.sh`

### Connection Creation Requirements
To create a connection, you need:
- Source processor ID
- Destination processor ID
- Process group ID (both processors must be in same group)
- Relationship name (e.g., "success", "failure")
- Current revision version of the process group

### API Response Patterns
Most NiFi API responses follow this structure:
```json
{
  "revision": {
    "version": 0,
    "clientId": "..."
  },
  "id": "component-id",
  "component": {
    // Actual component data
  }
}
```

Modification requests typically require:
```json
{
  "revision": {
    "version": current_version
  },
  "component": {
    // Modified component data
  }
}
```

## Environment Configuration

### Required Environment Variables
Set in `.env` file:
- `NIFI_USERNAME`: Admin username (default: admin)
- `NIFI_PASSWORD`: Admin password (minimum 12 characters, default: adminadminadmin)

### Optional Docker Override
Override any docker-compose settings by creating `docker-compose.override.yml` (automatically merged, not tracked in git).

## Security Notes

- NiFi uses self-signed certificates by default (hence `-k` flag in curl commands)
- For production, configure proper TLS certificates in NiFi configuration
- Never commit `.env` file with real credentials
- API tokens expire - scripts must handle re-authentication
- Default password (`adminadminadmin`) should be changed for non-development use

## Troubleshooting

### NiFi Not Starting
- Check logs: `docker-compose logs nifi`
- Verify Java heap settings in docker-compose.yml are appropriate for your system
- Ensure port 8443 is not already in use: `lsof -i :8443`

### API Authentication Failures
- Verify credentials in `.env` match what you're using in scripts
- Ensure password is at least 12 characters
- Wait 1-3 minutes after starting NiFi for full initialization
- Check if token has expired - obtain new token

### Connection Creation Fails
- Verify both processors exist and IDs are correct
- Ensure both processors are in the same process group
- Check that the relationship name (e.g., "success") is valid for the source processor
- Verify revision version is current by fetching latest before attempting modification
