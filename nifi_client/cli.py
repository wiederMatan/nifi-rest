#!/usr/bin/env python3
"""
NiFi REST API Client - Command Line Interface

Simple CLI for managing NiFi flows from the command line.
"""

import sys
import os
from .client import NiFiClient
from .flow import Flow
from .processor import Processor


def print_usage():
    """Print CLI usage information."""
    print("""
NiFi REST API Client - CLI

Usage:
    python -m nifi_client.cli <command> [options]

Commands:
    setup          - Check if NiFi is ready and authenticate
    create-flow    - Create sample flow (GenerateFlowFile -> LogAttribute)
    start-flow     - Start all processors in the flow
    stop-flow      - Stop all processors in the flow
    list           - List all processors
    version        - Show NiFi version

Environment Variables:
    NIFI_URL       - NiFi URL (default: https://localhost:8443)
    NIFI_USERNAME  - Username (default: admin)
    NIFI_PASSWORD  - Password (default: adminadminadmin)

Examples:
    python -m nifi_client.cli setup
    python -m nifi_client.cli create-flow
    python -m nifi_client.cli start-flow
    """)


def get_client():
    """
    Create NiFi client from environment variables or defaults.

    Returns:
        NiFiClient: Configured client instance
    """
    url = os.getenv("NIFI_URL", "https://localhost:8443")
    username = os.getenv("NIFI_USERNAME", "admin")
    password = os.getenv("NIFI_PASSWORD", "adminadminadmin")

    return NiFiClient(base_url=url, username=username, password=password)


def cmd_setup():
    """Check if NiFi is ready and test authentication."""
    print("=" * 60)
    print(" NiFi Setup Check")
    print("=" * 60)
    print()

    client = get_client()

    print("Checking if NiFi is ready...")
    if not client.is_ready():
        print("✗ NiFi is not ready")
        print("  Make sure NiFi is running: docker-compose up -d")
        return 1

    print("✓ NiFi is ready")
    print()

    print("Authenticating...")
    try:
        token = client.authenticate()
        print("✓ Authentication successful")
        print(f"  Token (first 50 chars): {token[:50]}...")
        print()

        version = client.get_nifi_version()
        print(f"✓ NiFi version: {version}")
        print()

        root_pg = client.get_root_process_group_id()
        print(f"✓ Root process group ID: {root_pg}")
        print()

        print("Setup complete! NiFi is ready to use.")
        return 0

    except Exception as e:
        print(f"✗ Authentication failed: {e}")
        return 1


def cmd_create_flow():
    """Create sample NiFi flow."""
    print("=" * 60)
    print(" Create Sample Flow")
    print("=" * 60)
    print()

    client = get_client()
    flow = Flow(client)

    try:
        result = flow.create_sample_flow()

        print()
        print("Flow created successfully!")
        print()
        print("Component IDs:")
        print(f"  GenerateFlowFile: {result['generate_id']}")
        print(f"  LogAttribute:     {result['log_id']}")
        print(f"  Connection:       {result['connection_id']}")
        print()
        print("Next steps:")
        print(f"  • View in UI: {client.base_url}/nifi")
        print("  • Start flow: python -m nifi_client.cli start-flow")
        return 0

    except Exception as e:
        print(f"✗ Failed to create flow: {e}")
        import traceback
        traceback.print_exc()
        return 1


def cmd_start_flow():
    """Start all processors."""
    print("=" * 60)
    print(" Start Flow")
    print("=" * 60)

    client = get_client()
    processor_mgr = Processor(client)

    try:
        # Get all processors
        processors = processor_mgr.list_all()

        if not processors:
            print("\n✗ No processors found")
            print("  Create a flow first: python -m nifi_client.cli create-flow")
            return 1

        print(f"\nFound {len(processors)} processors")
        print()

        started = 0
        already_running = 0
        failed = 0

        for proc in processors:
            proc_id = proc["id"]
            proc_name = proc["component"]["name"]

            try:
                result = processor_mgr.start(proc_id)

                if result["status"] == "started":
                    print(f"  ✓ Started: {proc_name}")
                    started += 1
                elif result["status"] == "already_running":
                    print(f"  ⚠ Already running: {proc_name}")
                    already_running += 1

            except Exception as e:
                print(f"  ✗ Failed to start {proc_name}: {e}")
                failed += 1

        print()
        print(f"Summary: {started} started, {already_running} already running, {failed} failed")
        print()
        print("Flow is now running!")
        return 0

    except Exception as e:
        print(f"✗ Failed to start flow: {e}")
        import traceback
        traceback.print_exc()
        return 1


def cmd_stop_flow():
    """Stop all processors."""
    print("=" * 60)
    print(" Stop Flow")
    print("=" * 60)

    client = get_client()
    processor_mgr = Processor(client)

    try:
        # Get all processors
        processors = processor_mgr.list_all()

        if not processors:
            print("\n✗ No processors found")
            return 1

        print(f"\nFound {len(processors)} processors")
        print()

        stopped = 0
        already_stopped = 0
        failed = 0

        for proc in processors:
            proc_id = proc["id"]
            proc_name = proc["component"]["name"]

            try:
                result = processor_mgr.stop(proc_id)

                if result["status"] == "stopped":
                    print(f"  ✓ Stopped: {proc_name}")
                    stopped += 1
                elif result["status"] == "already_stopped":
                    print(f"  ⚠ Already stopped: {proc_name}")
                    already_stopped += 1

            except Exception as e:
                print(f"  ✗ Failed to stop {proc_name}: {e}")
                failed += 1

        print()
        print(f"Summary: {stopped} stopped, {already_stopped} already stopped, {failed} failed")
        return 0

    except Exception as e:
        print(f"✗ Failed to stop flow: {e}")
        return 1


def cmd_list():
    """List all processors."""
    print("=" * 60)
    print(" List Processors")
    print("=" * 60)
    print()

    client = get_client()
    processor_mgr = Processor(client)

    try:
        processors = processor_mgr.list_all()

        if not processors:
            print("No processors found")
            return 0

        print(f"Found {len(processors)} processors:")
        print()

        for proc in processors:
            proc_id = proc["id"]
            name = proc["component"]["name"]
            proc_type = proc["component"]["type"].split(".")[-1]
            state = proc["component"]["state"]

            state_icon = "▶" if state == "RUNNING" else "■"
            print(f"  {state_icon} {name}")
            print(f"    Type:  {proc_type}")
            print(f"    ID:    {proc_id}")
            print(f"    State: {state}")
            print()

        return 0

    except Exception as e:
        print(f"✗ Failed to list processors: {e}")
        return 1


def cmd_version():
    """Show NiFi version."""
    client = get_client()

    try:
        version = client.get_nifi_version()
        print(f"NiFi version: {version}")
        return 0
    except Exception as e:
        print(f"✗ Failed to get version: {e}")
        return 1


def main():
    """Main CLI entry point."""
    if len(sys.argv) < 2:
        print_usage()
        return 1

    command = sys.argv[1]

    commands = {
        "setup": cmd_setup,
        "create-flow": cmd_create_flow,
        "start-flow": cmd_start_flow,
        "stop-flow": cmd_stop_flow,
        "list": cmd_list,
        "version": cmd_version,
        "help": lambda: (print_usage(), 0)[1],
    }

    if command not in commands:
        print(f"Unknown command: {command}")
        print_usage()
        return 1

    return commands[command]()


if __name__ == "__main__":
    sys.exit(main())
