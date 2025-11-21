# VCL3 Automatic Failover Setup

This document describes the automatic failover system that switches from VCL2 (primary) to VCL3 (standby) when VCL2 crashes or becomes unreachable.

## Overview

**Architecture:**
- **VCL2 (152.7.178.106)**: Primary server with auto-deployment
- **VCL3 (152.7.178.91)**: Standby server with automatic failover
- **Database Replication**: VCL2 → VCL3 every 2 minutes (already configured)

**How It Works:**
1. VCL3 continuously monitors VCL2's health (every 30 seconds)
2. When VCL2 fails 3 consecutive health checks (~90 seconds), VCL3 automatically starts the application
3. VCL3 serves traffic using the replicated database (always in sync)
4. When VCL2 recovers, VCL3 automatically stops and VCL2 becomes primary again

## Setup Instructions

### Prerequisites

**On VCL3:**
- Docker and Docker Compose installed
- Project cloned at `~/devops-project`
- Database replication already configured from VCL2

### Step 1: Setup Failover Monitoring on VCL3

SSH into VCL3:
```bash
ssh vpatel29@152.7.178.91
```

Run the setup script:
```bash
cd ~/devops-project
git pull origin main  # Get the latest failover scripts
chmod +x scripts/setup-vcl3-failover.sh
./scripts/setup-vcl3-failover.sh
```

This will:
- Create log directory `/var/log/vcl-failover/`
- Install systemd service `vcl-failover-monitor`
- Start monitoring VCL2 automatically
- Enable auto-start on boot

### Step 2: Verify Installation

Check that the monitor is running:
```bash
sudo systemctl status vcl-failover-monitor
```

View live monitoring logs:
```bash
tail -f /var/log/vcl-failover/monitor.log
```

Or use journalctl:
```bash
sudo journalctl -u vcl-failover-monitor -f
```

## Testing Failover

### Automatic Test (Recommended)

From VCL1 or your local machine:
```bash
cd ~/devops-project
chmod +x scripts/test-failover.sh
./scripts/test-failover.sh
```

Choose option 1 for automatic failover test. This will:
1. Stop VCL2 application
2. Wait for automatic failover (~90 seconds)
3. Verify VCL3 is serving traffic
4. Restart VCL2 and verify recovery

### Manual Failover Test

To manually trigger failover on VCL3:
```bash
ssh vpatel29@152.7.178.91
cd ~/devops-project
chmod +x scripts/manual-failover-to-vcl3.sh
./scripts/manual-failover-to-vcl3.sh
```

### Simulating VCL2 Crash

**Option A: Stop the Docker containers**
```bash
ssh vpatel29@152.7.178.106
cd ~/devops-project/coffee_project
sudo docker-compose down
```

**Option B: Stop the entire VM**
```bash
# From VCL web interface
# Or via SSH:
ssh vpatel29@152.7.178.106 'sudo poweroff'
```

Wait ~90 seconds (3 failed health checks), then:

**Verify VCL3 took over:**
```bash
curl http://152.7.178.91:3000/coffees
```

**Check monitor logs:**
```bash
ssh vpatel29@152.7.178.91
tail -f /var/log/vcl-failover/monitor.log
```

## Monitoring & Operations

### Check System Status

**VCL2 Status:**
```bash
curl http://152.7.178.106:3000/coffees
```

**VCL3 Status:**
```bash
curl http://152.7.178.91:3000/coffees
```

**Monitor Service Status:**
```bash
ssh vpatel29@152.7.178.91
sudo systemctl status vcl-failover-monitor
```

### View Logs

**Monitor logs (file):**
```bash
tail -f /var/log/vcl-failover/monitor.log
```

**Monitor logs (systemd):**
```bash
sudo journalctl -u vcl-failover-monitor -f
```

**Show last 50 lines:**
```bash
sudo journalctl -u vcl-failover-monitor -n 50
```

### Service Management

**Stop monitoring:**
```bash
sudo systemctl stop vcl-failover-monitor
```

**Start monitoring:**
```bash
sudo systemctl start vcl-failover-monitor
```

**Restart monitoring:**
```bash
sudo systemctl restart vcl-failover-monitor
```

**Disable auto-start:**
```bash
sudo systemctl disable vcl-failover-monitor
```

**Enable auto-start:**
```bash
sudo systemctl enable vcl-failover-monitor
```

## Configuration

### Health Check Settings

Edit `scripts/monitor-vcl2-health.sh` to adjust:

```bash
CHECK_INTERVAL=30    # seconds between health checks
MAX_FAILURES=3       # consecutive failures before failover
```

After editing, restart the service:
```bash
sudo systemctl restart vcl-failover-monitor
```

### Monitored Endpoints

The monitor checks:
1. **HTTP endpoint**: `http://152.7.178.106:3000/coffees`
2. **Ping fallback**: `ping 152.7.178.106`

Both must fail for failover to trigger.

## Failover Behavior

### When VCL2 Fails

1. Monitor detects 3 consecutive failures (~90 seconds)
2. VCL3 automatically:
   - Pulls latest code from git
   - Starts Docker containers
   - Runs health checks
   - Logs success/failure
3. VCL3 serves traffic at `http://152.7.178.91:3000`

### When VCL2 Recovers

1. Monitor detects VCL2 is healthy again
2. VCL3 automatically:
   - Stops Docker containers
   - Returns to standby mode
3. VCL2 resumes as primary

### If Failover Fails

If VCL3 fails to start the application:
- Error is logged
- Monitor continues checking VCL2
- Will retry failover on next detection

## Accessing the Application

### During Normal Operation (VCL2)
```bash
http://152.7.178.106:3000
```

### During Failover (VCL3)
```bash
http://152.7.178.91:3000
```

### Test Endpoints
```bash
# Get coffees
curl http://152.7.178.91:3000/coffees

# Place order
curl -X POST http://152.7.178.91:3000/order \
  -H "Content-Type: application/json" \
  -d '{"coffeeId": 1, "quantity": 2}'

# View orders
curl http://152.7.178.91:3000/orders
```

## Troubleshooting

### Monitor not starting

Check service status:
```bash
sudo systemctl status vcl-failover-monitor
sudo journalctl -u vcl-failover-monitor -n 50
```

Common issues:
- Script not executable: `chmod +x ~/devops-project/scripts/monitor-vcl2-health.sh`
- Docker not running: `sudo systemctl start docker`
- Permissions issue: Check log directory ownership

### Failover not triggering

Check monitor logs:
```bash
tail -f /var/log/vcl-failover/monitor.log
```

Verify:
- Monitor service is running
- VCL2 is actually unreachable
- At least 3 consecutive failures occurred

### VCL3 started but not responding

Check Docker containers:
```bash
sudo docker-compose ps
sudo docker-compose logs coffee_app
```

Check database:
```bash
sudo docker exec coffee_db pg_isready -U postgres
```

### Recovery not working

Check logs for recovery process:
```bash
grep "RECOVERY" /var/log/vcl-failover/monitor.log
```

Manually stop VCL3 if needed:
```bash
cd ~/devops-project/coffee_project
sudo docker-compose down
```

## Integration with Traffic Routing

Currently, failover is automatic but traffic routing is manual. To access VCL3 during failover:

1. **Direct access**: Use VCL3 IP directly: `http://152.7.178.91:3000`
2. **Update DNS** (future): Configure VCL1 to route traffic to VCL3
3. **Load Balancer** (future): Implement health-check aware load balancing

## Files Created

```
scripts/
├── monitor-vcl2-health.sh       # Main monitoring script
├── setup-vcl3-failover.sh       # Setup script for VCL3
├── manual-failover-to-vcl3.sh   # Manual failover trigger
└── test-failover.sh             # Automated testing script

/etc/systemd/system/
└── vcl-failover-monitor.service # Systemd service

/var/log/vcl-failover/
└── monitor.log                  # Monitor logs

/var/tmp/
└── vcl2-monitor-state           # State file
```

## Next Steps

After setting up failover:

1. **Test the failover**: Run `./scripts/test-failover.sh`
2. **Monitor logs**: Verify health checks are running
3. **Set up traffic routing**: Configure VCL1 or DNS to route to VCL3 when needed
4. **Set up alerts**: Add email/Slack notifications for failover events
5. **Document runbook**: Create procedures for common scenarios

## Important Notes

- Database replication must be running for VCL3 to have current data
- Failover happens automatically - no manual intervention required
- VCL3 only serves traffic when VCL2 is down
- Monitor service starts automatically on boot
- Traffic routing (DNS/load balancer) is separate from failover
