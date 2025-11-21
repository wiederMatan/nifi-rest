# NiFi REST API - Python Client

Simple, clean Python library for automating Apache NiFi workflows.

## Features

- **Simple & Minimal**: Easy-to-understand class-based design
- **Fully Tested**: Works with NiFi 2.6.0
- **CLI & Library**: Use from command line OR import into Python scripts
- **No Breaking Changes**: Existing shell scripts still work

---

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Or install as package
pip install -e .
```

---

## Quick Start

### 1. Command Line Usage

```bash
# Check NiFi is ready
python -m nifi_client.cli setup

# Create sample flow
python -m nifi_client.cli create-flow

# Start the flow
python -m nifi_client.cli start-flow

# List all processors
python -m nifi_client.cli list

# Stop the flow
python -m nifi_client.cli stop-flow
```

### 2. Python Library Usage

```python
from nifi_client import NiFiClient, Flow

# Create client
client = NiFiClient(
    base_url="https://localhost:8443",
    username="admin",
    password="adminadminadmin"
)

# Create and start a flow
flow = Flow(client)
result = flow.create_sample_flow()
flow.start_all_processors()

print(f"Flow created with IDs: {result}")
```

---

## Python API Reference

### NiFiClient

Main client for authenticating and making API requests.

```python
from nifi_client import NiFiClient

client = NiFiClient(
    base_url="https://localhost:8443",
    username="admin",
    password="adminadminadmin"
)

# Authenticate
token = client.authenticate()

# Get NiFi version
version = client.get_nifi_version()

# Get root process group ID
root_pg = client.get_root_process_group_id()

# Check if NiFi is ready
if client.is_ready():
    print("NiFi is running!")

# Make custom API calls
response = client.get("/flow/about")
response = client.post("/process-groups/root/processors", data)
```

### Processor

Manage individual processors.

```python
from nifi_client import NiFiClient, Processor

client = NiFiClient()
processor = Processor(client)

# Create a processor
proc = processor.create(
    processor_type="org.apache.nifi.processors.standard.GenerateFlowFile",
    name="My Generator",
    properties={"File Size": "1KB"},
    scheduling_period="30 sec"
)

proc_id = proc["id"]

# Start processor
processor.start(proc_id)

# Get processor info
info = processor.get(proc_id)

# Stop processor
processor.stop(proc_id)

# List all processors
all_processors = processor.list_all()

# Delete processor (stops it first)
processor.delete(proc_id)
```

### Flow

High-level flow creation and management.

```python
from nifi_client import NiFiClient, Flow

client = NiFiClient()
flow = Flow(client)

# Create sample flow (GenerateFlowFile -> LogAttribute)
result = flow.create_sample_flow()
# Returns: {
#   "generate_id": "...",
#   "log_id": "...",
#   "connection_id": "...",
#   "process_group_id": "..."
# }

# Start all processors in flow
flow.start_all_processors()

# Stop all processors in flow
flow.stop_all_processors()

# Create custom connection
connection = flow.create_connection(
    source_id="source-processor-id",
    destination_id="dest-processor-id",
    relationships=["success"]
)
```

---

## Complete Examples

### Example 1: Simple Flow Creation

```python
from nifi_client import NiFiClient, Flow

# Initialize
client = NiFiClient()
flow = Flow(client)

# Create and start flow
print("Creating sample flow...")
result = flow.create_sample_flow()

print("Starting processors...")
flow.start_all_processors()

print("Done! View at https://localhost:8443/nifi")
```

### Example 2: Custom Flow

```python
from nifi_client import NiFiClient, Processor, Flow

client = NiFiClient()
processor_mgr = Processor(client)
flow = Flow(client)

# Create custom processors
gen = processor_mgr.create(
    processor_type="org.apache.nifi.processors.standard.GenerateFlowFile",
    name="Data Generator",
    properties={"File Size": "10KB", "Batch Size": "5"},
    position={"x": 100, "y": 100}
)

log = processor_mgr.create(
    processor_type="org.apache.nifi.processors.standard.LogAttribute",
    name="Logger",
    properties={"Log Level": "debug"},
    position={"x": 100, "y": 300},
    auto_terminated_relationships=["success"]
)

# Connect them
connection = flow.create_connection(
    source_id=gen["id"],
    destination_id=log["id"],
    relationships=["success"]
)

# Start both
processor_mgr.start(gen["id"])
processor_mgr.start(log["id"])

print("Custom flow created and running!")
```

### Example 3: List and Control Processors

```python
from nifi_client import NiFiClient, Processor

client = NiFiClient()
processor = Processor(client)

# Get all processors
all_procs = processor.list_all()

print(f"Found {len(all_procs)} processors:")

for proc in all_procs:
    name = proc["component"]["name"]
    state = proc["component"]["state"]
    proc_id = proc["id"]

    print(f"  - {name}: {state}")

    # Start if stopped
    if state == "STOPPED":
        processor.start(proc_id)
        print(f"    Started {name}")
```

---

## Environment Variables

Configure connection via environment variables:

```bash
export NIFI_URL="https://localhost:8443"
export NIFI_USERNAME="admin"
export NIFI_PASSWORD="adminadminadmin"

python -m nifi_client.cli setup
```

Or in Python:

```python
import os

os.environ["NIFI_URL"] = "https://nifi.example.com:8443"
os.environ["NIFI_USERNAME"] = "myuser"
os.environ["NIFI_PASSWORD"] = "mypassword"

from nifi_client import NiFiClient
client = NiFiClient()  # Uses environment variables
```

---

## CLI Commands Reference

```bash
# Setup & Health Check
python -m nifi_client.cli setup

# Flow Management
python -m nifi_client.cli create-flow
python -m nifi_client.cli start-flow
python -m nifi_client.cli stop-flow

# Information
python -m nifi_client.cli list
python -m nifi_client.cli version
python -m nifi_client.cli help
```

---

## Architecture

```
nifi_client/
├── __init__.py       # Package exports
├── client.py         # NiFiClient - auth & API requests
├── processor.py      # Processor - processor management
├── flow.py           # Flow - flow creation & connections
└── cli.py            # CLI - command line interface
```

**Design Principles:**
- Simple & minimal (no complex patterns)
- Each class has one clear responsibility
- Easy to extend and customize
- No breaking changes to existing shell scripts

---

## Comparison: Shell vs Python

### Shell Scripts (Still Available)

```bash
./scripts/01_setup_nifi.sh
./scripts/02_create_sample_flow.sh
./scripts/03_push_flow.sh
```

**Pros:** Simple, no dependencies, familiar
**Cons:** Limited reusability, harder to extend

### Python Library (New)

```python
from nifi_client import NiFiClient, Flow

client = NiFiClient()
flow = Flow(client)
flow.create_sample_flow()
flow.start_all_processors()
```

**Pros:** Reusable, extensible, better error handling
**Cons:** Requires Python

### Recommendation

- **Quick tasks**: Use shell scripts
- **Custom automation**: Use Python library
- **Both work together**: No conflicts!

---

## Troubleshooting

### Import Error

```python
# If you get import errors
import sys
sys.path.insert(0, '/path/to/nifi-rest')

from nifi_client import NiFiClient
```

Or install the package:
```bash
pip install -e .
```

### Connection Error

```python
client = NiFiClient()

# Check if NiFi is ready
if not client.is_ready():
    print("NiFi is not running!")
    print("Start it: docker-compose up -d")
```

### SSL Certificate Errors

SSL verification is disabled by default for self-signed certificates. This is safe for local development but should be enabled in production.

---

## Contributing

The Python library is designed to be simple and extensible. To add new features:

1. Add methods to appropriate class (client.py, processor.py, or flow.py)
2. Keep it simple - avoid complex patterns
3. Add CLI commands if needed (cli.py)
4. Test with actual NiFi instance

---

## License

Apache License 2.0

---

## Next Steps

- Try the examples above
- Create custom flows using the Processor class
- Explore the NiFi REST API: https://nifi.apache.org/docs/nifi-docs/rest-api/
- Extend the library for your use case

Happy automating! 🚀
