"""
NiFi REST API Client Library

A simple Python client for Apache NiFi REST API.
Provides classes for managing NiFi flows, processors, and connections.
"""

from .client import NiFiClient
from .processor import Processor
from .flow import Flow

__version__ = "1.0.0"
__all__ = ["NiFiClient", "Processor", "Flow"]
