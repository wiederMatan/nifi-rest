"""
NiFi Processor Management

Class for creating and managing NiFi processors.
"""


class Processor:
    """
    Represents a NiFi processor.

    Provides methods for creating, starting, stopping, and querying processors.
    """

    def __init__(self, client):
        """
        Initialize Processor manager.

        Args:
            client: NiFiClient instance
        """
        self.client = client

    def create(self, processor_type, name, process_group_id=None, position=None, properties=None,
               scheduling_period="60 sec", auto_terminated_relationships=None):
        """
        Create a new processor.

        Args:
            processor_type: Processor type (e.g., "org.apache.nifi.processors.standard.GenerateFlowFile")
            name: Processor name
            process_group_id: Process group ID (default: root)
            position: Position dict with x, y coordinates (default: {x: 300, y: 200})
            properties: Processor properties dict
            scheduling_period: Scheduling period (default: "60 sec")
            auto_terminated_relationships: List of relationships to auto-terminate

        Returns:
            dict: Created processor response with ID
        """
        if not process_group_id:
            process_group_id = self.client.get_root_process_group_id()

        if not position:
            position = {"x": 300, "y": 200}

        if not properties:
            properties = {}

        config = {
            "properties": properties,
            "schedulingPeriod": scheduling_period
        }

        if auto_terminated_relationships:
            config["autoTerminatedRelationships"] = auto_terminated_relationships

        data = {
            "revision": {"version": 0},
            "component": {
                "type": processor_type,
                "name": name,
                "position": position,
                "config": config
            }
        }

        response = self.client.post(f"/process-groups/{process_group_id}/processors", data)
        return response

    def get(self, processor_id):
        """
        Get processor information.

        Args:
            processor_id: Processor ID

        Returns:
            dict: Processor information
        """
        return self.client.get(f"/processors/{processor_id}")

    def start(self, processor_id):
        """
        Start a processor.

        Args:
            processor_id: Processor ID

        Returns:
            dict: Updated processor information
        """
        proc_info = self.get(processor_id)
        revision = proc_info["revision"]["version"]
        state = proc_info["component"]["state"]

        if state == "RUNNING":
            return {"status": "already_running", "processor": proc_info}

        data = {
            "revision": {"version": revision},
            "state": "RUNNING"
        }

        response = self.client.put(f"/processors/{processor_id}/run-status", data)
        return {"status": "started", "processor": response}

    def stop(self, processor_id):
        """
        Stop a processor.

        Args:
            processor_id: Processor ID

        Returns:
            dict: Updated processor information
        """
        proc_info = self.get(processor_id)
        revision = proc_info["revision"]["version"]
        state = proc_info["component"]["state"]

        if state == "STOPPED":
            return {"status": "already_stopped", "processor": proc_info}

        data = {
            "revision": {"version": revision},
            "state": "STOPPED"
        }

        response = self.client.put(f"/processors/{processor_id}/run-status", data)
        return {"status": "stopped", "processor": response}

    def list_all(self, process_group_id=None):
        """
        List all processors in a process group.

        Args:
            process_group_id: Process group ID (default: root)

        Returns:
            list: List of processors
        """
        if not process_group_id:
            process_group_id = "root"

        response = self.client.get(f"/process-groups/{process_group_id}/processors")
        return response.get("processors", [])

    def delete(self, processor_id):
        """
        Delete a processor (requires processor to be stopped first).

        Args:
            processor_id: Processor ID

        Returns:
            dict: Deletion response
        """
        # First stop the processor
        self.stop(processor_id)

        # Get current revision
        proc_info = self.get(processor_id)
        revision = proc_info["revision"]["version"]

        # Delete using DELETE request (note: requests library handles this)
        import requests
        url = f"{self.client.base_url}/nifi-api/processors/{processor_id}?version={revision}"
        headers = self.client.get_headers()
        response = requests.delete(url, headers=headers, verify=False)
        response.raise_for_status()
        return response.json()
