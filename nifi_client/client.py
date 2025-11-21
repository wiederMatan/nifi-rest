"""
NiFi REST API Client

Main client class for authenticating and making API requests to NiFi.
"""

import requests
import urllib3
import warnings


class NiFiError(Exception):
    """Base exception for NiFi client errors."""
    pass


class AuthenticationError(NiFiError):
    """Raised when authentication fails."""
    pass


class APIError(NiFiError):
    """Raised when API request fails."""
    pass


class NiFiClient:
    """
    Simple NiFi REST API client.

    Handles authentication and provides methods for making API requests.
    """

    def __init__(self, base_url="https://localhost:8443", username="admin", password="adminadminadmin",
                 verify_ssl=False, cert_path=None):
        """
        Initialize NiFi client.

        Args:
            base_url: NiFi base URL (default: https://localhost:8443)
            username: NiFi username (default: admin)
            password: NiFi password (default: adminadminadmin)
            verify_ssl: Verify SSL certificates (default: False for development)
            cert_path: Path to CA bundle for SSL verification (optional)

        Security Warning:
            - Default password should be changed in production
            - verify_ssl=False should only be used in development
            - Always use HTTPS URLs in production
        """
        # Enforce HTTPS
        if not base_url.startswith('https://'):
            warnings.warn(
                "HTTP URLs are not secure. Use HTTPS in production.",
                SecurityWarning,
                stacklevel=2
            )

        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.verify_ssl = cert_path if cert_path else verify_ssl
        self.token = None
        self.root_pg_id = None

        # Disable SSL warnings only if user explicitly disabled verification
        if not verify_ssl and not cert_path:
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            warnings.warn(
                "SSL certificate verification is disabled. This is insecure and should only be used in development.",
                SecurityWarning,
                stacklevel=2
            )

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

        response = requests.post(url, data=data, verify=self.verify_ssl)

        if response.status_code in (200, 201):
            self.token = response.text
            return self.token
        else:
            raise AuthenticationError(f"Authentication failed: {response.status_code} - {response.text}")

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

    def get(self, endpoint, timeout=30):
        """
        Make GET request to NiFi API.

        Args:
            endpoint: API endpoint (e.g., "/flow/process-groups/root")
            timeout: Request timeout in seconds (default: 30)

        Returns:
            dict: Response JSON

        Raises:
            APIError: If request fails
        """
        url = f"{self.base_url}/nifi-api{endpoint}"
        try:
            response = requests.get(url, headers=self.get_headers(), verify=self.verify_ssl, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise APIError(f"GET {endpoint} failed: {e}") from e

    def post(self, endpoint, data, timeout=30):
        """
        Make POST request to NiFi API.

        Args:
            endpoint: API endpoint
            data: Request body (dict or JSON string)
            timeout: Request timeout in seconds (default: 30)

        Returns:
            dict: Response JSON

        Raises:
            APIError: If request fails
        """
        url = f"{self.base_url}/nifi-api{endpoint}"
        try:
            response = requests.post(url, json=data, headers=self.get_headers(), verify=self.verify_ssl, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise APIError(f"POST {endpoint} failed: {e}") from e

    def put(self, endpoint, data, timeout=30):
        """
        Make PUT request to NiFi API.

        Args:
            endpoint: API endpoint
            data: Request body (dict or JSON string)
            timeout: Request timeout in seconds (default: 30)

        Returns:
            dict: Response JSON

        Raises:
            APIError: If request fails
        """
        url = f"{self.base_url}/nifi-api{endpoint}"
        try:
            response = requests.put(url, json=data, headers=self.get_headers(), verify=self.verify_ssl, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise APIError(f"PUT {endpoint} failed: {e}") from e

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
            response = requests.get(url, verify=self.verify_ssl, timeout=5)
            return response.status_code == 200
        except (requests.exceptions.RequestException, Exception):
            return False
