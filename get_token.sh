#!/bin/bash

# Script to obtain NiFi API access token
# Usage: ./get_token.sh

set -e

# Configuration
NIFI_URL="https://localhost:8443"
USERNAME="${NIFI_USERNAME:-admin}"
PASSWORD="${NIFI_PASSWORD:-adminadminadmin}"

# Obtain access token
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=${USERNAME}&password=${PASSWORD}")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to obtain access token. Check credentials."
    exit 1
fi

echo "$TOKEN"
