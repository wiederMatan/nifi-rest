"""
NiFi REST API Client

Main client class for authenticating and making API requests to NiFi.
"""

import requests
import urllib3

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class NiFiClient:
    """
    Simple NiFi REST API client.

    Handles authentication and provides methods for making API requests.
    """

    def __init__(self, base_url="https://localhost:8443", username="admin", password="adminadminadmin"):
        """
        Initialize NiFi client.

        Args:
            base_url: NiFi base URL (default: https://localhost:8443)
            username: NiFi username (default: admin)
            password: NiFi password (default: adminadminadmin)
        """
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.token = None
        self.root_pg_id = None

    def authenticate(self):
        """
        Authenticate with NiFi and get JWT token.

        Returns:
            str: JWT token

        Raises:
            Exception: If authentication fails
        """
        url = f"{self.base_url}/nifi-api/access/token"
        data = {
            "username": self.username,
            "password": self.password
        }

        response = requests.post(url, data=data, verify=False)

        if response.status_code == 201 or response.status_code == 200:
            self.token = response.text
            return self.token
        else:
            raise Exception(f"Authentication failed: {response.status_code} - {response.text}")

    def get_headers(self):
        """
        Get HTTP headers with authorization token.

        Returns:
            dict: Headers dictionary
        """
        if not self.token:
            self.authenticate()

        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def get(self, endpoint):
        """
        Make GET request to NiFi API.

        Args:
            endpoint: API endpoint (e.g., "/flow/process-groups/root")

        Returns:
            dict: Response JSON
        """
        url = f"{self.base_url}/nifi-api{endpoint}"
        response = requests.get(url, headers=self.get_headers(), verify=False)
        response.raise_for_status()
        return response.json()

    def post(self, endpoint, data):
        """
        Make POST request to NiFi API.

        Args:
            endpoint: API endpoint
            data: Request body (dict or JSON string)

        Returns:
            dict: Response JSON
        """
        url = f"{self.base_url}/nifi-api{endpoint}"
        response = requests.post(url, json=data, headers=self.get_headers(), verify=False)
        response.raise_for_status()
        return response.json()

    def put(self, endpoint, data):
        """
        Make PUT request to NiFi API.

        Args:
            endpoint: API endpoint
            data: Request body (dict or JSON string)

        Returns:
            dict: Response JSON
        """
        url = f"{self.base_url}/nifi-api{endpoint}"
        response = requests.put(url, json=data, headers=self.get_headers(), verify=False)
        response.raise_for_status()
        return response.json()

    def get_root_process_group_id(self):
        """
        Get the root process group ID.

        Returns:
            str: Root process group ID
        """
        if not self.root_pg_id:
            response = self.get("/flow/process-groups/root")
            self.root_pg_id = response["processGroupFlow"]["id"]

        return self.root_pg_id

    def get_nifi_version(self):
        """
        Get NiFi version information.

        Returns:
            str: NiFi version
        """
        response = self.get("/flow/about")
        return response["about"]["version"]

    def is_ready(self):
        """
        Check if NiFi is ready and responding.

        Returns:
            bool: True if NiFi is ready
        """
        try:
            url = f"{self.base_url}/nifi/"
            response = requests.get(url, verify=False, timeout=5)
            return response.status_code == 200
        except:
            return False
