#!/usr/bin/env bash
# manual-failover-to-vcl3.sh
# Manually trigger failover to VCL3
# Run this script on VCL3 or from VCL1 via SSH

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Manual Failover to VCL3${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Confirm manual failover
echo -e "${RED}WARNING: This will start the application on VCL3${NC}"
echo "This should only be done when VCL2 is down or during planned maintenance."
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Failover cancelled."
    exit 0
fi

echo ""
echo "Step 1: Checking if VCL3 app is already running..."
if sudo docker ps --filter "name=coffee_app" --filter "status=running" -q | grep -q .; then
    echo -e "${YELLOW}VCL3 application is already running${NC}"
    read -p "Do you want to restart it? (y/N): " restart
    if [[ ! $restart =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 0
    fi
    echo "Stopping existing containers..."
    cd ~/devops-project/coffee_project
    sudo docker-compose down
fi
echo -e "${GREEN}✓ Ready to start VCL3${NC}"
echo ""

echo "Step 2: Pulling latest code from main branch..."
cd ~/devops-project
git pull origin main || echo -e "${YELLOW}Warning: Git pull failed, using existing code${NC}"
echo -e "${GREEN}✓ Code updated${NC}"
echo ""

echo "Step 3: Starting Docker containers on VCL3..."
cd ~/devops-project/coffee_project
if sudo docker-compose up -d --build; then
    echo -e "${GREEN}✓ Containers started${NC}"
else
    echo -e "${RED}✗ Failed to start containers${NC}"
    exit 1
fi
echo ""

echo "Step 4: Waiting for application to be ready..."
sleep 10

# Health check
echo "Step 5: Running health checks..."
if curl -sf --connect-timeout 5 http://localhost:3000/coffees > /dev/null 2>&1; then
    echo -e "${GREEN}✓ HTTP health check passed${NC}"
else
    echo -e "${RED}✗ HTTP health check failed${NC}"
    exit 1
fi

if sudo docker exec coffee_db pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database health check passed${NC}"
else
    echo -e "${RED}✗ Database health check failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Failover Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "VCL3 is now serving the application:"
echo "  - Local:  http://localhost:3000"
echo "  - Remote: http://152.7.178.91:3000"
echo ""
echo "Test endpoints:"
echo "  curl http://152.7.178.91:3000/coffees"
echo ""
echo "View containers:"
echo "  sudo docker-compose ps"
echo ""
echo "View logs:"
echo "  sudo docker-compose logs -f coffee_app"
echo ""
