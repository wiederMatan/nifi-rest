# NiFi REST API Integration

Docker-based Apache NiFi 2.6.0 setup with REST API automation scripts for managing flows and connections.

## Quick Start

1. **Configure credentials:**
   ```bash
   cp .env.example .env
   # Edit .env and set NIFI_USERNAME and NIFI_PASSWORD (min 12 chars)
   ```

2. **Start NiFi:**
   ```bash
   docker-compose up -d
   ```

3. **Access NiFi UI:**

   Open https://localhost:8443/nifi (accept self-signed certificate warning)

   Login with credentials from `.env`

4. **Create and Push a Flow:**

   **Option A: Complete Data Processing Flow** (Recommended)
   ```bash
   # Create production-ready HTTP → Route → Transform → Store flow
   ./create_and_push_flow.sh

   # Start the flow
   ./start_workflow.sh

   # Test with HTTP POST
   curl -X POST http://localhost:9999/data?size=large -d "test data"
   ```

   **Option B: Simple Sample Workflow**
   ```bash
   # Create basic workflow (GenerateFlowFile -> LogAttribute -> UpdateAttribute)
   ./create_sample_workflow.sh

   # Start the workflow
   ./start_workflow.sh

   # Stop the workflow
   ./stop_workflow.sh
   ```

   **Option C: Individual API Scripts**
   ```bash
   # Get authentication token
   ./get_token.sh

   # List processors
   ./list_processors.sh

   # Create connection (edit IDs in script first)
   ./create_connection.sh
   ```

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - ⭐ Start here! Complete beginner's guide
- **[SETUP.md](SETUP.md)** - Detailed installation and configuration guide
- **[FLOW_MANAGEMENT.md](FLOW_MANAGEMENT.md)** - Creating, pushing, and exporting flows
- **[WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)** - Complete workflow creation guide with sample workflows
- **[THUNDER_CLIENT_SETUP.md](THUNDER_CLIENT_SETUP.md)** - Thunder Client extension setup and usage guide
- **[API_CONNECTION_GUIDE.md](API_CONNECTION_GUIDE.md)** - Complete REST API connection guide with authentication and troubleshooting
- **[CLAUDE.md](CLAUDE.md)** - Development guidance and architecture overview

## What's Included

### Docker Configuration
- `docker-compose.yml` - NiFi 2.6.0 container with persistent volumes
- `.env.example` - Environment variables template

### Shell Scripts
- `get_token.sh` - Obtain JWT authentication token
- `list_processors.sh` - List all processors and their IDs
- `create_connection.sh` - Create connection between two processors
- `create_sample_workflow.sh` - Create simple test workflow
- `create_and_push_flow.sh` - Create production-ready data processing flow
- `start_workflow.sh` - Start processors in workflow
- `stop_workflow.sh` - Stop processors in workflow
- `export_flow.sh` - Export flow to JSON file
- `import_flow.sh` - Import flow from JSON file

### Thunder Client (VS Code Extension)
- `thunder-client/thunder-collection_NiFi REST API.json` - Complete API collection
- `thunder-client/thunder-environment_NiFi Local.json` - Environment variables

### Documentation
- `SETUP.md` - Installation and configuration guide
- `WORKFLOW_GUIDE.md` - Workflow creation and Thunder Client guide
- `API_CONNECTION_GUIDE.md` - REST API reference
- `CLAUDE.md` - Development guide

## Requirements

- Docker 20.10+
- Docker Compose 1.29+

## Project Structure

```
.
├── docker-compose.yml                    # NiFi container configuration
├── .env.example                         # Environment variables template
│
├── Shell Scripts
│   ├── get_token.sh                     # Get authentication token
│   ├── list_processors.sh               # List processors
│   ├── create_connection.sh             # Create single connection
│   ├── create_sample_workflow.sh        # Create complete workflow
│   ├── start_workflow.sh                # Start processors
│   └── stop_workflow.sh                 # Stop processors
│
├── Thunder Client
│   ├── thunder-collection_NiFi REST API.json   # API collection
│   └── thunder-environment_NiFi Local.json     # Environment variables
│
└── Documentation
    ├── README.md                        # This file
    ├── SETUP.md                         # Installation guide
    ├── WORKFLOW_GUIDE.md                # Workflow creation guide
    ├── API_CONNECTION_GUIDE.md          # API reference
    └── CLAUDE.md                        # Development guide
```

## Common Tasks

### Create and Run Sample Workflow
```bash
# Create workflow
./create_sample_workflow.sh

# Start all processors
./start_workflow.sh

# Monitor logs
docker-compose logs -f nifi | grep "Sample Workflow"

# Stop workflow
./stop_workflow.sh
```

### Using Thunder Client (VS Code)
1. Install Thunder Client extension in VS Code
2. Import collection: `thunder-client/thunder-collection_NiFi REST API.json`
3. Import environment: `thunder-client/thunder-environment_NiFi Local.json`
4. Run "Authentication → Get Access Token"
5. Explore API requests in organized folders

See [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) for detailed Thunder Client usage.

### View NiFi Logs
```bash
docker-compose logs -f nifi
```

### Stop NiFi
```bash
docker-compose down
```

### Reset Everything (removes all data)
```bash
docker-compose down -v
```

## API Scripts

All scripts use environment variables from `.env` or defaults:
- `NIFI_USERNAME` (default: admin)
- `NIFI_PASSWORD` (default: adminadminadmin)

Override per-script:
```bash
NIFI_USERNAME=myuser NIFI_PASSWORD=mypass ./get_token.sh
```

## Security Notes

- NiFi uses HTTPS with self-signed certificates by default
- Minimum password length: 12 characters
- Change default credentials for production use
- Never commit `.env` file with real credentials

## License

This project provides tooling for Apache NiFi. See [Apache NiFi](https://nifi.apache.org/) for NiFi licensing.
