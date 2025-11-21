# NiFi REST API - Basic Setup

Simple Docker-based Apache NiFi 2.6.0 setup with REST API scripts.

## Quick Start

1. **Start NiFi:**
   ```bash
   docker-compose up -d
   ```

2. **Wait 2-3 minutes for NiFi to start**

3. **Access NiFi UI:**
   ```
   https://localhost:8443/nifi
   ```
   Login: `admin` / `adminadminadmin`

## API Usage

### Get Authentication Token
```bash
./get_token.sh
```

### List Processors
```bash
./list_processors.sh
```

### Create Flow
```bash
./create_and_push_flow.sh
```
Creates: HTTP Listener → Route → Transform → Store flow

### Create Connection Between Processors
```bash
./create_connection.sh
```
Edit the script to set your processor IDs first.

## Files

- `docker-compose.yml` - NiFi 2.6.0 container setup
- `.env.example` - Environment variables (copy to `.env`)
- `get_token.sh` - Get JWT authentication token
- `list_processors.sh` - List all processors
- `create_and_push_flow.sh` - Create complete data flow
- `create_connection.sh` - Connect two processors
- `SETUP.md` - Detailed setup instructions

## Environment Variables

Copy `.env.example` to `.env` and customize:
```bash
cp .env.example .env
```

Default credentials:
- Username: `admin`
- Password: `adminadminadmin` (min 12 chars)

## Common Commands

```bash
# Start NiFi
docker-compose up -d

# Stop NiFi
docker-compose down

# View logs
docker-compose logs -f nifi

# Get token
TOKEN=$(./get_token.sh)

# Use token in API calls
curl -k -X GET https://localhost:8443/nifi-api/flow/process-groups/root \
  -H "Authorization: Bearer $TOKEN"
```

## Requirements

- Docker 20.10+
- Docker Compose 1.29+

## License

Apache License 2.0
