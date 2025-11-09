#!/usr/bin/env bash
# setup-replication.sh - Quick setup for DB replication VCL2 → VCL3
# Run this on VCL2

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Coffee DB Replication Setup${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running on VCL2
HOSTNAME=$(hostname)
if [[ ! "$HOSTNAME" =~ "178-106" ]]; then
    echo -e "${YELLOW}Warning: This script should be run on VCL2 (152.7.178.106)${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Creating log directory..."
sudo mkdir -p /var/log/coffee-replication
sudo chown $USER:$USER /var/log/coffee-replication
echo -e "${GREEN}✓ Log directory created${NC}"
echo ""

echo "Step 2: Making replication script executable..."
chmod +x ~/devops-project/scripts/replicate-db.sh
echo -e "${GREEN}✓ Script is executable${NC}"
echo ""

echo "Step 3: Setting up SSH key for VCL3..."
if [ ! -f ~/.ssh/vcl3_replication_key ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/vcl3_replication_key -N "" -C "replication@vcl2"
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "${YELLOW}! SSH key already exists${NC}"
fi
echo ""

echo "Step 4: Testing replication script..."
if ~/devops-project/scripts/replicate-db.sh; then
    echo -e "${GREEN}✓ Replication test successful!${NC}"
else
    echo -e "${RED}✗ Replication test failed${NC}"
    echo "Please check the error messages above and fix before continuing."
    exit 1
fi
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Copy SSH key to VCL3:"
echo "   ssh-copy-id -i ~/.ssh/vcl3_replication_key.pub vpatel29@152.7.178.91"
echo ""
echo "2. Choose scheduling method:"
echo ""
echo "   Option A - Using Cron (simple):"
echo "   crontab -e"
echo "   # Add this line:"
echo "   */2 * * * * /home/vpatel29/devops-project/scripts/replicate-db.sh >> /var/log/coffee-replication/replicate.log 2>&1"
echo ""
echo "   Option B - Using Systemd Timer (recommended):"
echo "   sudo cp ~/devops-project/scripts/systemd/*.service /etc/systemd/system/"
echo "   sudo cp ~/devops-project/scripts/systemd/*.timer /etc/systemd/system/"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable --now coffee-replication.timer"
echo ""
echo "3. Monitor replication:"
echo "   tail -f /var/log/coffee-replication/replicate.log"
echo ""
