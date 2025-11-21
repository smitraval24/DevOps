#!/usr/bin/env bash
# test-failover.sh
# Test the failover mechanism
# Run this script from VCL1 or locally

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

VCL2_HOST="152.7.178.106"
VCL2_USER="vpatel29"
VCL3_HOST="152.7.178.91"
VCL3_USER="vpatel29"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Failover Test Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 1: Check VCL2 status
echo -e "${YELLOW}Test 1: Checking VCL2 current status...${NC}"
if curl -sf --connect-timeout 5 http://$VCL2_HOST:3000/coffees > /dev/null 2>&1; then
    echo -e "${GREEN}✓ VCL2 is currently running${NC}"
    VCL2_INITIAL_STATE="running"
else
    echo -e "${RED}✗ VCL2 is currently down${NC}"
    VCL2_INITIAL_STATE="down"
fi
echo ""

# Test 2: Check VCL3 status
echo -e "${YELLOW}Test 2: Checking VCL3 current status...${NC}"
if curl -sf --connect-timeout 5 http://$VCL3_HOST:3000/coffees > /dev/null 2>&1; then
    echo -e "${YELLOW}! VCL3 is currently running (should be standby)${NC}"
    VCL3_INITIAL_STATE="running"
else
    echo -e "${GREEN}✓ VCL3 is in standby mode${NC}"
    VCL3_INITIAL_STATE="standby"
fi
echo ""

# Test 3: Check failover monitor
echo -e "${YELLOW}Test 3: Checking VCL3 failover monitor...${NC}"
echo "This requires SSH access to VCL3"
echo "Command: ssh $VCL3_USER@$VCL3_HOST 'sudo systemctl status vcl-failover-monitor'"
echo ""

# Provide test options
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Failover Test Options${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Choose a test to run:"
echo ""
echo "1) Automatic Failover Test (recommended)"
echo "   - Stops VCL2 application"
echo "   - Waits for automatic failover to VCL3 (~90 seconds)"
echo "   - Verifies VCL3 is serving traffic"
echo "   - Restarts VCL2 and verifies recovery"
echo ""
echo "2) Manual Failover Test"
echo "   - Manually starts VCL3 application"
echo "   - Tests VCL3 endpoints"
echo "   - Stops VCL3 when done"
echo ""
echo "3) Status Check Only"
echo "   - Checks current status of both servers"
echo "   - No changes made"
echo ""
echo "4) Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}Starting Automatic Failover Test${NC}"
        echo -e "${YELLOW}========================================${NC}"
        echo ""

        if [ "$VCL2_INITIAL_STATE" != "running" ]; then
            echo -e "${RED}Error: VCL2 must be running to test automatic failover${NC}"
            exit 1
        fi

        echo "Step 1: Stopping VCL2 application..."
        echo "ssh $VCL2_USER@$VCL2_HOST 'cd ~/devops-project/coffee_project && sudo docker-compose down'"
        echo ""
        echo -e "${RED}WARNING: This will stop the VCL2 application!${NC}"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Test cancelled."
            exit 0
        fi

        ssh $VCL2_USER@$VCL2_HOST 'cd ~/devops-project/coffee_project && sudo docker-compose down'
        echo -e "${GREEN}✓ VCL2 stopped${NC}"
        echo ""

        echo "Step 2: Waiting for failover (3 failed checks = ~90 seconds)..."
        echo "Checking VCL3 status every 10 seconds..."
        echo ""

        for i in {1..15}; do
            echo -n "[$i/15] Checking VCL3... "
            if curl -sf --connect-timeout 5 http://$VCL3_HOST:3000/coffees > /dev/null 2>&1; then
                echo -e "${GREEN}VCL3 IS UP!${NC}"
                echo ""
                echo -e "${GREEN}✓ Automatic failover successful!${NC}"
                FAILOVER_SUCCESS=true
                break
            else
                echo "standby (waiting...)"
                sleep 10
            fi
        done

        if [ "${FAILOVER_SUCCESS:-false}" != "true" ]; then
            echo ""
            echo -e "${RED}✗ Failover did not occur within expected time${NC}"
            echo "Check VCL3 monitor logs: ssh $VCL3_USER@$VCL3_HOST 'tail -f /var/log/vcl-failover/monitor.log'"
            exit 1
        fi

        echo ""
        echo "Step 3: Testing VCL3 endpoints..."
        curl -s http://$VCL3_HOST:3000/coffees | head -n 5
        echo -e "${GREEN}✓ VCL3 is serving traffic${NC}"
        echo ""

        echo "Step 4: Restarting VCL2..."
        read -p "Restart VCL2 and test recovery? (yes/no): " restart
        if [ "$restart" = "yes" ]; then
            ssh $VCL2_USER@$VCL2_HOST 'cd ~/devops-project/coffee_project && sudo docker-compose up -d'
            echo -e "${GREEN}✓ VCL2 restarted${NC}"
            echo ""
            echo "Waiting for VCL2 to be ready (15 seconds)..."
            sleep 15

            echo "Waiting for automatic recovery (~30 seconds)..."
            sleep 30

            echo "Checking if VCL3 stopped automatically..."
            if curl -sf --connect-timeout 5 http://$VCL3_HOST:3000/coffees > /dev/null 2>&1; then
                echo -e "${YELLOW}! VCL3 is still running (may take longer to stop)${NC}"
            else
                echo -e "${GREEN}✓ VCL3 automatically stopped - recovery complete!${NC}"
            fi
        fi
        ;;

    2)
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}Starting Manual Failover Test${NC}"
        echo -e "${YELLOW}========================================${NC}"
        echo ""

        echo "Running manual failover script on VCL3..."
        ssh -t $VCL3_USER@$VCL3_HOST 'bash ~/devops-project/scripts/manual-failover-to-vcl3.sh'
        ;;

    3)
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}Status Check${NC}"
        echo -e "${YELLOW}========================================${NC}"
        echo ""

        echo "VCL2 Status:"
        if curl -sf --connect-timeout 5 http://$VCL2_HOST:3000/coffees > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Running${NC}"
        else
            echo -e "  ${RED}✗ Down${NC}"
        fi

        echo ""
        echo "VCL3 Status:"
        if curl -sf --connect-timeout 5 http://$VCL3_HOST:3000/coffees > /dev/null 2>&1; then
            echo -e "  ${YELLOW}! Running (active)${NC}"
        else
            echo -e "  ${GREEN}✓ Standby${NC}"
        fi

        echo ""
        echo "Monitor Status (requires SSH):"
        echo "  ssh $VCL3_USER@$VCL3_HOST 'sudo systemctl status vcl-failover-monitor'"
        ;;

    4)
        echo "Exiting."
        exit 0
        ;;

    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
