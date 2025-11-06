# DevOps Project

This repository contains the main DevOps project with a coffee delivery service.

## Infrastructure

**VCL Machines:**
- **VCL 1**: 152.7.178.184 (Routing and DNS)
- **VCL 2**: 152.7.178.106 (Primary server)
- **VCL 3**: 152.7.178.91 (Cold standby server)

## Quick Start with Docker

Run the coffee project with PostgreSQL database using Docker:

```bash
cd coffee_project
docker-compose up -d
```

This starts:
- Coffee app on http://localhost:3000
- PostgreSQL database on port 5432

### Test the app
```bash
# Get available coffees
curl http://localhost:3000/coffees

# Place an order
curl -X POST http://localhost:3000/order \
  -H "Content-Type: application/json" \
  -d '{"coffeeId": 1, "quantity": 2}'
```

### Stop containers
```bash
docker-compose down
```

## Database setup (PostgreSQL)

This project uses PostgreSQL for the `coffee_project` service. The app reads the connection from the `DATABASE_URL` environment variable. If `DATABASE_URL` is not set, the project defaults to:

```
postgresql://postgres:postgres@localhost:5432/coffee_dev
```

Quick start (Docker)

1. Start a local Postgres container:

```bash
docker run --name coffee-pg -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=coffee_dev -p 5432:5432 -d postgres:15
```

2. Install dependencies and run the migration to create tables and seed the coffee catalogue:

```bash
cd coffee_project
npm install
npm run migrate
```

3. Start the service:

```bash
npm start
# or run in a detached screen session:
screen -S coffee -dm sh -c 'npm start'
```

Using an existing / hosted database

If you have a hosted Postgres instance, set `DATABASE_URL` before running the migrate script or starting the server:

```bash
export DATABASE_URL='postgresql://USER:PASSWORD@HOST:PORT/DBNAME'
npm run migrate
npm start
```

CI (GitHub Actions) notes

If you run tests or migrations in GitHub Actions, start a Postgres service in the job and set `DATABASE_URL` to point to the service. Example snippet for a job in `.github/workflows/*.yml`:

```yaml
services:
	postgres:
		image: postgres:15
		env:
			POSTGRES_DB: coffee_test
			POSTGRES_USER: postgres
			POSTGRES_PASSWORD: postgres
		ports: ['5432:5432']
		options: >-
			--health-cmd pg_isready
			--health-interval 10s
			--health-timeout 5s
			--health-retries 5

env:
	DATABASE_URL: postgres://postgres:postgres@localhost:5432/coffee_test
```

Cleanup

To stop and remove the local docker container:

```bash
docker stop coffee-pg && docker rm coffee-pg
```

Questions or different DB?

If you'd prefer a different database (MySQL, MongoDB, etc.) I can adapt the code and migration script — tell me which one and I'll implement the change.

## Automated Deployment

The project uses GitHub Actions to automatically deploy to VCL 2 when code is merged to `main`.

### How it works

1. When a PR is merged to `main`, the deployment workflow triggers
2. The workflow (running on the self-hosted runner on VCL 1) SSHs into VCL 2
3. Pulls the latest code from the `main` branch
4. Stops old Docker containers
5. Rebuilds and starts new containers with the updated code
6. The app becomes accessible at **http://152.7.178.106:3000**

### Prerequisites for deployment

**On VCL 2 (152.7.178.106):**
- Docker and Docker Compose installed
- Project cloned at `~/devops-project`
- SSH access configured for GitHub Actions

**GitHub Repository Secrets (required):**
- `VCL2_SSH_PRIVATE_KEY` - SSH private key for accessing VCL 2
- `VCL2_SSH_KNOWN_HOSTS` - (optional) Host key for VCL 2

### Setting up SSH for GitHub Actions

1. Generate a dedicated SSH key pair:
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy_key
```

2. Copy the public key to VCL 2:
```bash
ssh-copy-id -i ~/.ssh/github_actions_deploy_key.pub vpatel29@152.7.178.106
```

3. Add the private key to GitHub Secrets:
```bash
# Copy the private key
cat ~/.ssh/github_actions_deploy_key

# Go to: Repository Settings → Secrets and variables → Actions
# Create secret: VCL2_SSH_PRIVATE_KEY
# Paste the entire private key content (including BEGIN/END lines)
```

4. (Optional) Add known hosts:
```bash
ssh-keyscan -H 152.7.178.106

# Add as secret: VCL2_SSH_KNOWN_HOSTS
```

### Manual deployment on VCL 2

If you need to deploy manually:

```bash
ssh vpatel29@152.7.178.106
cd ~/devops-project
git pull origin main
cd coffee_project
docker-compose down
docker-compose up -d --build
```

### Accessing the deployed app

Once deployed, the coffee delivery service is accessible at:
- **http://152.7.178.106:3000**

Test endpoints:
```bash
# Get available coffees
curl http://152.7.178.106:3000/coffees

# Place an order
curl -X POST http://152.7.178.106:3000/order \
  -H "Content-Type: application/json" \
  -d '{"coffeeId": 1, "quantity": 2}'

# View all orders
curl http://152.7.178.106:3000/orders
```