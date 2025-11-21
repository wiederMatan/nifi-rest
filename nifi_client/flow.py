"""
NiFi Flow Management

Class for creating and managing NiFi flows (processors + connections).
"""

from .processor import Processor


class Flow:
    """
    Manages NiFi flows.

    Provides high-level methods for creating complete flows with processors and connections.
    """

    def __init__(self, client):
        """
        Initialize Flow manager.

        Args:
            client: NiFiClient instance
        """
        self.client = client
        self.processor = Processor(client)
        self.created_processors = []
        self.created_connections = []

    def create_sample_flow(self, process_group_id=None):
        """
        Create a sample flow: GenerateFlowFile -> LogAttribute

        This creates a simple flow that generates sample data every 60 seconds
        and logs it to the NiFi application log.

        Args:
            process_group_id: Process group ID (default: root)

        Returns:
            dict: Dictionary with created processor IDs and connection ID
        """
        if not process_group_id:
            process_group_id = self.client.get_root_process_group_id()

        print("Creating sample flow...")

        # Create GenerateFlowFile processor
        print("  [1/3] Creating GenerateFlowFile processor...")
        generate_proc = self.processor.create(
            processor_type="org.apache.nifi.processors.standard.GenerateFlowFile",
            name="Generate Sample Data",
            process_group_id=process_group_id,
            position={"x": 300, "y": 200},
            properties={
                "File Size": "1KB",
                "Batch Size": "1"
            },
            scheduling_period="60 sec"
        )
        generate_id = generate_proc["id"]
        self.created_processors.append(generate_id)
        print(f"     Created: {generate_id}")

        # Create LogAttribute processor
        print("  [2/3] Creating LogAttribute processor...")
        log_proc = self.processor.create(
            processor_type="org.apache.nifi.processors.standard.LogAttribute",
            name="Log Sample Data",
            process_group_id=process_group_id,
            position={"x": 300, "y": 400},
            properties={
                "Log Level": "info",
                "Log Payload": "true"
            },
            auto_terminated_relationships=["success"]
        )
        log_id = log_proc["id"]
        self.created_processors.append(log_id)
        print(f"     Created: {log_id}")

        # Create connection
        print("  [3/3] Creating connection...")
        connection = self.create_connection(
            source_id=generate_id,
            destination_id=log_id,
            relationships=["success"],
            process_group_id=process_group_id
        )
        connection_id = connection["id"]
        self.created_connections.append(connection_id)
        print(f"     Created: {connection_id}")

        print("\nSample flow created successfully!")

        return {
            "generate_id": generate_id,
            "log_id": log_id,
            "connection_id": connection_id,
            "process_group_id": process_group_id
        }

    def create_connection(self, source_id, destination_id, relationships, process_group_id=None):
        """
        Create a connection between two processors.

        Args:
            source_id: Source processor ID
            destination_id: Destination processor ID
            relationships: List of relationships (e.g., ["success"])
            process_group_id: Process group ID (default: root)

        Returns:
            dict: Created connection response
        """
        if not process_group_id:
            process_group_id = self.client.get_root_process_group_id()

        data = {
            "revision": {"version": 0},
            "component": {
                "source": {
                    "id": source_id,
                    "groupId": process_group_id,
                    "type": "PROCESSOR"
                },
                "destination": {
                    "id": destination_id,
                    "groupId": process_group_id,
                    "type": "PROCESSOR"
                },
                "selectedRelationships": relationships
            }
        }

        response = self.client.post(f"/process-groups/{process_group_id}/connections", data)
        return response

    def start_all_processors(self):
        """
        Start all processors that were created by this flow instance.

        Returns:
            dict: Summary of started, already running, and failed processors
        """
        print(f"\nStarting {len(self.created_processors)} processors...")

        started = []
        already_running = []
        failed = []

        for proc_id in self.created_processors:
            try:
                result = self.processor.start(proc_id)
                proc_name = result["processor"]["component"]["name"]

                if result["status"] == "started":
                    print(f"  ✓ Started: {proc_name}")
                    started.append(proc_id)
                elif result["status"] == "already_running":
                    print(f"  ⚠ Already running: {proc_name}")
                    already_running.append(proc_id)
            except Exception as e:
                print(f"  ✗ Failed to start {proc_id}: {e}")
                failed.append(proc_id)

        print(f"\nSummary: {len(started)} started, {len(already_running)} already running, {len(failed)} failed")

        return {
            "started": started,
            "already_running": already_running,
            "failed": failed
        }

    def stop_all_processors(self):
        """
        Stop all processors that were created by this flow instance.

        Returns:
            dict: Summary of stopped processors
        """
        print(f"\nStopping {len(self.created_processors)} processors...")

        stopped = []
        already_stopped = []
        failed = []

        for proc_id in self.created_processors:
            try:
                result = self.processor.stop(proc_id)
                proc_name = result["processor"]["component"]["name"]

                if result["status"] == "stopped":
                    print(f"  ✓ Stopped: {proc_name}")
                    stopped.append(proc_id)
                elif result["status"] == "already_stopped":
                    print(f"  ⚠ Already stopped: {proc_name}")
                    already_stopped.append(proc_id)
            except Exception as e:
                print(f"  ✗ Failed to stop {proc_id}: {e}")
                failed.append(proc_id)

        print(f"\nSummary: {len(stopped)} stopped, {len(already_stopped)} already stopped, {len(failed)} failed")

        return {
            "stopped": stopped,
            "already_stopped": already_stopped,
            "failed": failed
        }
