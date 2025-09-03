# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start

1. Generate security keys:
```bash
# Generate a 32-character password for PostgreSQL
openssl rand -base64 32

# Generate a 32-character encryption key for n8n
openssl rand -hex 16
```

2. Update `.env` file with the generated keys
3. Start the services:
```bash
docker compose up -d
```

4. Access n8n at `http://localhost:5678`

## Common Development Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs n8n
docker compose logs postgres

# Check service status
docker compose ps

# Restart n8n after configuration changes
docker compose restart n8n

# Stop all services
docker compose down

# Stop and remove all data (WARNING: This deletes all workflows!)
docker compose down -v
```

## Architecture Overview

This is a **simplified n8n system** using Docker Compose with basic database persistence:

```
n8n (Web UI + Executions) ←→ PostgreSQL (Data Storage)
```

### Key Services:
- **n8n**: Main n8n service (web interface + workflow execution)
- **postgres**: Database for workflow and execution data

## Configuration

### Environment Variables (.env):
- `POSTGRES_PASSWORD`: Database password (required)
- `N8N_ENCRYPTION_KEY`: n8n encryption key (required)
- `POSTGRES_DB`: Database name (default: n8n)
- `POSTGRES_USER`: Database user (default: n8n)
- `N8N_PROTOCOL`: Protocol for n8n (default: http)
- `N8N_HOST`: Host for n8n (default: 0.0.0.0)
- `N8N_SECURE_COOKIE`: Cookie security (default: false for local)

### Volume Strategy:
- **postgres_data**: Database persistence
- **n8n_data**: Workflow and configuration data

## Initial Setup

1. **Clone and navigate to the project:**
```bash
git clone <repository-url>
cd n8n-project/n8n
```

2. **Generate security keys:**
```bash
# PostgreSQL password
openssl rand -base64 32
# n8n encryption key  
openssl rand -hex 16
```

3. **Update .env file:**
Replace the placeholder values in `.env`:
- Set `POSTGRES_PASSWORD` to your generated password
- Set `N8N_ENCRYPTION_KEY` to your generated encryption key

4. **Start services:**
```bash
docker compose up -d
```

5. **Access n8n:**
Open http://localhost:5678 in your browser

6. **First-time setup:**
Create your admin user account when prompted

## Troubleshooting

### Service Health Check:
```bash
# Check if services are running
docker compose ps

# Check service logs
docker compose logs n8n
docker compose logs postgres
```

### Common Issues:
- **Port 5678 not accessible**: Ensure no other service is using the port
- **Database connection errors**: Check PostgreSQL is healthy with `docker compose logs postgres`
- **n8n won't start**: Verify `.env` file has proper encryption key and database password

### Reset Everything:
```bash
# This will delete ALL data and workflows
docker compose down -v
docker compose up -d
```

## Security Notes

- This simplified setup is intended for development/testing
- Uses HTTP instead of HTTPS (suitable for private networks)
- For production use, enable HTTPS and use proper domain configuration
- Always use strong, unique passwords and encryption keys