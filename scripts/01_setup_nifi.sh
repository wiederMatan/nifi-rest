#!/bin/bash

# TASK 1: First-Time Setup to Connect NiFi Docker Container
# This script sets up NiFi in a Docker container and verifies the connection

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  TASK 1: First-Time NiFi Docker Setup                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check Prerequisites
echo "Step 1: Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✓ Docker installed: $(docker --version)"
echo "✓ Docker Compose installed: $(docker-compose --version)"
echo ""

# Step 2: Create .env file if it doesn't exist
echo "Step 2: Setting up environment variables..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created .env file from .env.example"
    echo "  Default credentials: admin / adminadminadmin"
else
    echo "✓ .env file already exists"
fi
echo ""

# Step 3: Start NiFi container
echo "Step 3: Starting NiFi Docker container..."
docker-compose up -d

if [ $? -eq 0 ]; then
    echo "✓ NiFi container started successfully"
else
    echo "❌ Failed to start NiFi container"
    exit 1
fi
echo ""

# Step 4: Wait for NiFi to initialize
echo "Step 4: Waiting for NiFi to initialize (this takes 1-3 minutes)..."
echo "  Checking every 10 seconds..."

NIFI_URL="https://localhost:8443"
MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))

    # Try to connect to NiFi API
    if curl -k -s -f "${NIFI_URL}/nifi-api/system-diagnostics" > /dev/null 2>&1; then
        echo "✓ NiFi is ready!"
        break
    fi

    echo "  Attempt $ATTEMPT/$MAX_ATTEMPTS - NiFi is still starting..."
    sleep 10
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "❌ NiFi did not start within expected time"
    echo "   Check logs: docker-compose logs nifi"
    exit 1
fi
echo ""

# Step 5: Test API Connection
echo "Step 5: Testing API connection..."

# Get authentication token
TOKEN=$(curl -s -k -X POST \
  "${NIFI_URL}/nifi-api/access/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin&password=adminadminadmin")

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get authentication token"
    exit 1
fi

echo "✓ Successfully authenticated with NiFi API"
echo "  Token (first 50 chars): ${TOKEN:0:50}..."
echo ""

# Step 6: Get NiFi version info
echo "Step 6: Getting NiFi information..."

VERSION_INFO=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/about" \
  -H "Authorization: Bearer ${TOKEN}")

NIFI_VERSION=$(echo "$VERSION_INFO" | jq -r '.about.version')

echo "✓ Connected to NiFi version: ${NIFI_VERSION}"
echo ""

# Step 7: Get root process group
ROOT_PG=$(curl -s -k -X GET \
  "${NIFI_URL}/nifi-api/flow/process-groups/root" \
  -H "Authorization: Bearer ${TOKEN}")

ROOT_PG_ID=$(echo "$ROOT_PG" | jq -r '.processGroupFlow.id')

echo "✓ Root Process Group ID: ${ROOT_PG_ID}"
echo ""

# Summary
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Setup Complete!                              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "NiFi is now running and accessible at:"
echo "  URL: ${NIFI_URL}/nifi"
echo "  Username: admin"
echo "  Password: adminadminadmin"
echo ""
echo "Connection verified:"
echo "  ✓ Docker container running"
echo "  ✓ NiFi API responding"
echo "  ✓ Authentication working"
echo "  ✓ Version: ${NIFI_VERSION}"
echo ""
echo "Next steps:"
echo "  1. Open browser: ${NIFI_URL}/nifi"
echo "  2. Create a flow: ./02_create_sample_flow.sh"
echo "  3. View logs: docker-compose logs -f nifi"
echo ""
echo "To stop NiFi: docker-compose down"
echo "To restart: docker-compose restart nifi"
