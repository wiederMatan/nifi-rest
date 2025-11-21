# NiFi REST API - Project Structure

Professional directory organization for NiFi REST API automation.

## Directory Tree

```
nifi-rest/
├── scripts/                    # All automation scripts
│   ├── 01_setup_nifi.sh       # TASK 1: First-time setup & connection
│   ├── 02_create_sample_flow.sh  # TASK 2: Create sample flow
│   ├── 03_push_flow.sh        # TASK 3: Start/push flow
│   │
│   ├── core/                  # Core workflow scripts
│   │   ├── create_basic_flow.sh      # Simple flow creator
│   │   ├── create_and_push_flow.sh   # Advanced flow creator
│   │   ├── create_connection.sh      # Connection builder
│   │   └── start_processors.sh       # Start all processors
│   │
│   └── utils/                 # Utility scripts
│       ├── get_token.sh       # Authentication helper
│       └── list_processors.sh # Processor listing
│
├── docs/                      # Documentation
│   ├── BASIC_FLOW_GUIDE.md   # Complete flow creation guide
│   └── SETUP.md              # Detailed setup instructions
│
├── examples/                  # Example flows and templates
│   └── (future: sample flows, templates)
│
├── docker-compose.yml         # NiFi container configuration
├── .env.example              # Environment template
├── .gitignore                # Git exclusions
├── LICENSE                   # Apache 2.0 license
├── README.md                 # Main documentation
└── PROJECT_STRUCTURE.md      # This file
```

## Script Organization

### Main Task Scripts (Start Here)

Located in `scripts/` directory:

| Script | Purpose | Usage |
|--------|---------|-------|
| `01_setup_nifi.sh` | First-time setup and connection test | `./scripts/01_setup_nifi.sh` |
| `02_create_sample_flow.sh` | Create basic sample flow | `./scripts/02_create_sample_flow.sh` |
| `03_push_flow.sh` | Start/push flow to production | `./scripts/03_push_flow.sh` |

### Core Scripts

Located in `scripts/core/` directory:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `create_basic_flow.sh` | Create simple 2-processor flow | Learning, testing |
| `create_and_push_flow.sh` | Create advanced multi-processor flow | Production-ready flows |
| `create_connection.sh` | Connect two specific processors | Custom flows |
| `start_processors.sh` | Start all processors in root group | After creating flows |

### Utility Scripts

Located in `scripts/utils/` directory:

| Script | Purpose | Usage |
|--------|---------|-------|
| `get_token.sh` | Get JWT authentication token | `TOKEN=$(./scripts/utils/get_token.sh)` |
| `list_processors.sh` | List all processors and IDs | `./scripts/utils/list_processors.sh` |

## Workflow Patterns

### Pattern 1: First-Time Setup
```bash
./scripts/01_setup_nifi.sh          # Setup Docker & test connection
```

### Pattern 2: Create & Run Sample Flow
```bash
./scripts/02_create_sample_flow.sh  # Create GenerateFlowFile -> LogAttribute
./scripts/03_push_flow.sh           # Start the flow
```

### Pattern 3: Advanced Flow
```bash
./scripts/core/create_and_push_flow.sh  # HTTP -> Route -> Transform -> Store
./scripts/03_push_flow.sh               # Start the flow
```

### Pattern 4: Custom Development
```bash
# Get authenticated
TOKEN=$(./scripts/utils/get_token.sh)

# List existing processors
./scripts/utils/list_processors.sh

# Create custom connections
./scripts/core/create_connection.sh
```

## Configuration Files

### `docker-compose.yml`
NiFi container configuration:
- Port mappings
- Volume mounts
- Environment variables
- Network settings

### `.env.example` → `.env`
Environment variables:
```
NIFI_USERNAME=admin
NIFI_PASSWORD=adminadminadmin
```

## Generated Files

During execution, scripts may create:

| File | Created By | Purpose |
|------|-----------|---------|
| `sample_flow_ids.txt` | `02_create_sample_flow.sh` | Stores component IDs |
| `.env` | `01_setup_nifi.sh` | Runtime credentials |

## Documentation Structure

### `README.md`
Quick start guide and basic usage

### `docs/SETUP.md`
Detailed setup instructions, troubleshooting

### `docs/BASIC_FLOW_GUIDE.md`
Step-by-step flow creation tutorial

### `PROJECT_STRUCTURE.md` (this file)
Complete project organization reference

## Design Principles

### 1. Separation of Concerns
- **Task scripts**: High-level workflows (numbered 01, 02, 03)
- **Core scripts**: Reusable flow creators
- **Utils**: Low-level helpers

### 2. Progressive Complexity
- Start with simple (01 → 02 → 03)
- Move to advanced when needed (core/)
- Use utilities for custom work (utils/)

### 3. Self-Documenting
- Script names indicate purpose
- Comments explain what/why
- Output shows progress

### 4. Production-Ready
- Error handling in all scripts
- Environment variable configuration
- Logging and monitoring support

## Common Commands

```bash
# First time setup
./scripts/01_setup_nifi.sh

# Create and start sample flow
./scripts/02_create_sample_flow.sh
./scripts/03_push_flow.sh

# View NiFi UI
open https://localhost:8443/nifi

# Monitor logs
docker-compose logs -f nifi

# Stop everything
docker-compose down
```

## Adding New Scripts

### For new task workflows:
Place in `scripts/` with number prefix:
```
scripts/04_your_new_task.sh
```

### For reusable components:
Place in `scripts/core/`:
```
scripts/core/create_custom_flow.sh
```

### For utilities:
Place in `scripts/utils/`:
```
scripts/utils/export_flow.sh
```

## Best Practices

1. **Always start with setup**: Run `01_setup_nifi.sh` first
2. **Use task scripts for workflows**: They handle dependencies
3. **Check documentation**: Read `docs/` before customizing
4. **Save IDs**: Scripts save component IDs for reuse
5. **Monitor logs**: Use `docker-compose logs -f nifi`

## Maintenance

### Update all scripts
```bash
git pull
chmod +x scripts/*.sh scripts/**/*.sh
```

### Clean restart
```bash
docker-compose down -v
./scripts/01_setup_nifi.sh
```

### Backup flows
```bash
# TODO: Export functionality
# ./scripts/utils/export_flow.sh > backup.json
```

## Future Enhancements

- [ ] Add export/import scripts to utils/
- [ ] Create example flow templates in examples/
- [ ] Add monitoring scripts
- [ ] Create CI/CD integration scripts
- [ ] Add flow validation utilities
