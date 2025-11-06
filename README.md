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