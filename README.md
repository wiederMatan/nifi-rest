# NiFi REST API - Professional Setup

Enterprise-grade Apache NiFi 2.6.0 automation with organized scripts and comprehensive documentation.

## Quick Start

### Option 1: Shell Scripts (3 Commands)

```bash
# 1. Setup NiFi Docker container
./scripts/01_setup_nifi.sh

# 2. Create sample flow
./scripts/02_create_sample_flow.sh

# 3. Start the flow
./scripts/03_push_flow.sh
```

### Option 2: Python Library (NEW!)

```bash
# Install dependencies
pip install -r requirements.txt

# Run commands
python -m nifi_client.cli setup
python -m nifi_client.cli create-flow
python -m nifi_client.cli start-flow
```

Or use in Python scripts:
```python
from nifi_client import NiFiClient, Flow

client = NiFiClient()
flow = Flow(client)
flow.create_sample_flow()
flow.start_all_processors()
```

See [README_PYTHON.md](README_PYTHON.md) for complete Python documentation.

Then open: https://localhost:8443/nifi (Login: `admin` / `adminadminadmin`)

---

## Project Structure

```
nifi-rest/
├── scripts/                      # Shell scripts (Option 1)
│   ├── 01_setup_nifi.sh          # TASK 1: First-time setup
│   ├── 02_create_sample_flow.sh  # TASK 2: Create sample flow
│   ├── 03_push_flow.sh           # TASK 3: Start/push flow
│   ├── core/                     # Reusable flow creators
│   └── utils/                    # Helper utilities
├── nifi_client/                  # Python library (Option 2)
│   ├── __init__.py               # Package exports
│   ├── client.py                 # NiFiClient class
│   ├── processor.py              # Processor management
│   ├── flow.py                   # Flow creation
│   └── cli.py                    # CLI commands
├── docs/                         # Documentation
├── docker-compose.yml            # NiFi container config
├── requirements.txt              # Python dependencies
├── setup.py                      # Python package setup
├── README_PYTHON.md              # Python library docs
└── .env.example                  # Environment template
```

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) and [README_PYTHON.md](README_PYTHON.md) for details.

---

## Three Main Tasks

### Task 1: Setup & Connect NiFi

```bash
./scripts/01_setup_nifi.sh
```

**What it does:**
- ✅ Checks Docker prerequisites
- ✅ Creates `.env` file
- ✅ Starts NiFi container
- ✅ Waits for NiFi to initialize
- ✅ Tests API connection
- ✅ Verifies authentication

**Output:** NiFi running at https://localhost:8443

---

### Task 2: Create Sample Flow

```bash
./scripts/02_create_sample_flow.sh
```

**What it creates:**
```
┌──────────────────────┐
│ Generate Sample Data │  (1KB every 60 sec)
└──────────┬───────────┘
           │ success
           ▼
┌──────────────────────┐
│ Log Sample Data      │  (Logs to nifi-app.log)
└──────────────────────┘
```

**Output:** Flow created, IDs saved to `sample_flow_ids.txt`

---

### Task 3: Push/Start Flow

```bash
./scripts/03_push_flow.sh
```

**What it does:**
- ✅ Authenticates with NiFi
- ✅ Loads processor IDs (or finds all processors)
- ✅ Starts each processor
- ✅ Reports status

**Output:** Flow running and processing data

---

## Advanced Usage

### Core Scripts (scripts/core/)

**Create Basic Flow:**
```bash
./scripts/core/create_basic_flow.sh
```

**Create Advanced Flow:**
```bash
./scripts/core/create_and_push_flow.sh
```
Creates: HTTP → Route → Transform → Store

**Start All Processors:**
```bash
./scripts/core/start_processors.sh
```

### Utility Scripts (scripts/utils/)

**Get Authentication Token:**
```bash
TOKEN=$(./scripts/utils/get_token.sh)
```

**List All Processors:**
```bash
./scripts/utils/list_processors.sh
```

---

## Environment Configuration

1. Copy template:
   ```bash
   cp .env.example .env
   ```

2. Edit credentials (optional):
   ```bash
   nano .env
   ```

Default:
- Username: `admin`
- Password: `adminadminadmin` (min 12 chars)

---

## Common Commands

```bash
# Start NiFi
docker-compose up -d

# Stop NiFi
docker-compose down

# View logs
docker-compose logs -f nifi

# Restart NiFi
docker-compose restart nifi

# Complete reset (deletes data)
docker-compose down -v
```

---

## Documentation

- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Complete project organization
- **[docs/SETUP.md](docs/SETUP.md)** - Detailed setup guide
- **[docs/BASIC_FLOW_GUIDE.md](docs/BASIC_FLOW_GUIDE.md)** - Flow creation tutorial

---

## Workflow Examples

### Example 1: First Time User
```bash
./scripts/01_setup_nifi.sh          # Setup
./scripts/02_create_sample_flow.sh  # Create flow
./scripts/03_push_flow.sh           # Start flow
open https://localhost:8443/nifi    # View in browser
```

### Example 2: Create Multiple Flows
```bash
./scripts/02_create_sample_flow.sh  # Create flow 1
./scripts/core/create_basic_flow.sh # Create flow 2
./scripts/03_push_flow.sh           # Start all
```

### Example 3: Custom Development
```bash
TOKEN=$(./scripts/utils/get_token.sh)
./scripts/utils/list_processors.sh
# Build custom flow with API calls
./scripts/03_push_flow.sh
```

---

## API Integration

All scripts use NiFi REST API:

**Base URL:** `https://localhost:8443/nifi-api`

**Authentication:** JWT Bearer token

**Example:**
```bash
# Get token
TOKEN=$(curl -s -k -X POST \
  "https://localhost:8443/nifi-api/access/token" \
  -d "username=admin&password=adminadminadmin")

# List processors
curl -k -X GET \
  "https://localhost:8443/nifi-api/process-groups/root/processors" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Monitoring

**View NiFi logs:**
```bash
docker-compose logs -f nifi
```

**Check processor stats:**
```bash
./scripts/utils/list_processors.sh
```

**Web UI:**
```
https://localhost:8443/nifi
```

---

## Requirements

- Docker 20.10+
- Docker Compose 1.29+
- jq (JSON processor)
- curl

**Verify:**
```bash
docker --version
docker-compose --version
jq --version
```

---

## Troubleshooting

**NiFi won't start:**
```bash
docker-compose logs nifi
```

**Can't connect to API:**
```bash
# Wait 2-3 minutes after starting
./scripts/01_setup_nifi.sh  # Re-run setup
```

**Authentication fails:**
```bash
# Check credentials in .env
cat .env
```

**Reset everything:**
```bash
docker-compose down -v
rm -f sample_flow_ids.txt
./scripts/01_setup_nifi.sh
```

---

## Contributing

This project follows professional organization standards:

1. **Scripts** → `scripts/` (numbered tasks) or `scripts/core/`
2. **Utilities** → `scripts/utils/`
3. **Documentation** → `docs/`
4. **Examples** → `examples/`

---

## License

Apache License 2.0

---

## Quick Reference

| Task | Script | Time |
|------|--------|------|
| Setup NiFi | `./scripts/01_setup_nifi.sh` | 2-3 min |
| Create Flow | `./scripts/02_create_sample_flow.sh` | 5 sec |
| Start Flow | `./scripts/03_push_flow.sh` | 2 sec |

**Total:** ~3 minutes from zero to running flow! 🚀
