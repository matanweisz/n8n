# n8n Production Setup - Complete Step-by-Step Guide

This guide walks you through every step of deploying n8n on your AWS EC2 instance, with detailed explanations of what each step does and why it's needed.

## Prerequisites

Before starting, ensure you have:
- AWS infrastructure deployed with your Terraform configuration
- SSH key pair for accessing EC2 instances
- Bastion host and n8n EC2 instance running
- Domain configured with Route53 and ACM certificate

## Step 1: Connect to Your EC2 Instance

### 1.1 SSH to Bastion Host
```bash
ssh -i ~/.ssh/your-terraform-key.pem ubuntu@<bastion-public-ip>
```
**Why:** Your n8n server is in a private subnet for security. The bastion host is your secure gateway.

### 1.2 From Bastion, SSH to n8n Server
```bash
ssh -i ~/.ssh/your-terraform-key.pem ubuntu@<n8n-private-ip>
```
**Why:** This connects you to the actual server where n8n will run.

**Finding IPs:**
- Bastion IP: Check AWS EC2 console or Terraform outputs
- n8n Private IP: Check AWS EC2 console for the "n8n-server" instance

## Step 2: Prepare the Server

### 2.1 Update the System
```bash
sudo apt update && sudo apt upgrade -y
```
**Why:** Ensures you have the latest security patches and package versions.

### 2.2 Install Docker
```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (avoids needing sudo for docker commands)
sudo usermod -aG docker ubuntu
newgrp docker

# Install Docker Compose plugin
sudo apt install docker-compose-plugin -y
```
**Why:** Docker runs your n8n containers, Docker Compose orchestrates multiple services together.

### 2.3 Verify Installation
```bash
docker --version
docker compose version
```
**Expected output:** Version numbers for both Docker and Docker Compose.

## Step 3: Get Your n8n Project

### 3.1 Clone the Repository
```bash
git clone <your-repo-url> n8n-production
cd n8n-production
```
**Replace `<your-repo-url>`** with your actual GitHub repository URL.

### 3.2 List Project Files
```bash
ls -la
```
**You should see:**
- `docker-compose.yml` - Service definitions
- `.env.example` - Environment template
- `Dockerfile` - n8n container configuration
- `README.md` - Documentation

## Step 4: Understanding Docker Networking

### 4.1 No External Network Required

**Great news!** This setup has been simplified - you **don't need** to create any external networks.

### 4.2 How Docker Networking Works Here

Docker Compose automatically creates a default bridge network for your services:

1. **Automatic Network**: Docker Compose creates a network named `<project>_default`
2. **Service Discovery**: All services can communicate using service names (e.g., `postgres`, `redis`)
3. **Isolation**: Your n8n services are isolated from other Docker containers
4. **Simplicity**: No manual network management required

**What this means:**
- n8n can connect to `postgres` by hostname
- Workers can connect to `redis` by hostname  
- All internal communication "just works"
- External access only through exposed ports (5678, 5679)

## Step 5: Configure Environment Variables

### 5.1 Copy Environment Template
```bash
cp .env.example .env
```

### 5.2 Generate Required Secrets

You need to generate secure values for several environment variables:

#### **POSTGRES_PASSWORD**
```bash
# Generate a secure database password (32 characters)
openssl rand -base64 32
```
**What this is:** Password for your PostgreSQL database
**Example:** `kJ8mN2pQ4rT6wY9bC3eF7gH0iL5oP8sV1uX4z7A`

#### **N8N_ENCRYPTION_KEY**
```bash
# Generate a 32-character encryption key
openssl rand -hex 16
```
**What this is:** n8n uses this to encrypt sensitive workflow data
**Example:** `a1b2c3d4e5f6789012345678901234ab`
**Important:** Never lose this key - you won't be able to decrypt existing workflows!

#### **N8N_USER_MANAGEMENT_JWT_SECRET**
```bash
# Generate JWT secret (32 characters)
openssl rand -base64 32
```
**What this is:** Used for user authentication and session management
**Example:** `mK9nP3qR5tU7wZ0cE4fG8hI2jL6nQ9rT5uX8z1B`

#### **N8N_RUNNERS_AUTH_TOKEN**
```bash
# Generate runner authentication token (32 characters)
openssl rand -base64 32
```
**What this is:** Authenticates worker containers with the main n8n instance
**Example:** `pL7mO1qS4tW8yA3cF6gI9jM2nP5rU8xZ0bE3f7G`

### 5.3 Edit the Environment File
```bash
nano .env
```

### 5.4 Complete .env Configuration

Replace the placeholder values with your generated secrets and configuration:

```env
# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=<paste-your-postgres-password-here>
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
PGDATA=/var/lib/postgresql/data

# =============================================================================
# N8N SECURITY KEYS (GENERATE THESE!)
# =============================================================================
N8N_ENCRYPTION_KEY=<paste-your-32-char-encryption-key-here>
N8N_USER_MANAGEMENT_JWT_SECRET=<paste-your-jwt-secret-here>
N8N_RUNNERS_AUTH_TOKEN=<paste-your-runners-auth-token-here>

# =============================================================================
# N8N DOMAIN CONFIGURATION (MATCH YOUR TERRAFORM)
# =============================================================================
N8N_HOST=n8n.matanweisz.xyz
N8N_PROTOCOL=https
N8N_WEBHOOK_URL=https://api.n8n.matanweisz.xyz/
WEBHOOK_URL=https://api.n8n.matanweisz.xyz/

# =============================================================================
# N8N BASIC CONFIGURATION
# =============================================================================
N8N_LOG_LEVEL=info
N8N_DIAGNOSTICS_ENABLED=false
N8N_METRICS=false
N8N_BASIC_AUTH_ACTIVE=false
N8N_USER_FOLDER=/n8n
N8N_SECURE_COOKIE=true
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false

# =============================================================================
# QUEUE CONFIGURATION (ENABLES WORKER MODE)
# =============================================================================
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis
QUEUE_HEALTH_CHECK_ACTIVE=true
OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true

# =============================================================================
# REDIS CONFIGURATION
# =============================================================================
REDIS_HOST=redis
REDIS_PORT=6379
QUEUE_NAME_PREFIX=bull
QUEUE_NAME=jobs

# =============================================================================
# PERFORMANCE TUNING
# =============================================================================
N8N_CONCURRENCY_PRODUCTION_LIMIT=10
N8N_QUEUE_BULL_GRACEFULSHUTDOWNTIMEOUT=300
N8N_GRACEFUL_SHUTDOWN_TIMEOUT=300

# =============================================================================
# TASK RUNNER CONFIGURATION
# =============================================================================
N8N_TASK_BROKER_URL=redis://redis:6379
N8N_COMMAND_RESPONSE_URL=redis://redis:6379
N8N_TASK_BROKER_PORT=6379

# =============================================================================
# DATABASE CONNECTION FOR N8N
# =============================================================================
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=<same-postgres-password-as-above>

# =============================================================================
# DOCKER COMPOSE CONFIGURATION
# =============================================================================
COMPOSE_PROJECT_NAME=n8n-production
```

### 5.5 Understanding Key Environment Variables

| Variable | Purpose | Where Value Comes From |
|----------|---------|----------------------|
| `POSTGRES_PASSWORD` | Database security | Generate with `openssl rand -base64 32` |
| `N8N_ENCRYPTION_KEY` | Encrypts workflow data | Generate with `openssl rand -hex 16` |
| `N8N_HOST` | Your main domain | From your Terraform configuration |
| `N8N_WEBHOOK_URL` | Webhook endpoint | From your Terraform configuration |
| `EXECUTIONS_MODE=queue` | Enables worker mode | Required for multi-container setup |
| `N8N_CONCURRENCY_PRODUCTION_LIMIT` | Jobs per worker | Start with 10, increase if needed |

**Save and exit nano:** `Ctrl+X`, then `Y`, then `Enter`

## Step 6: Deploy n8n Services

### 6.1 Start All Services
```bash
docker compose up -d
```
**What this does:**
- Downloads required Docker images
- Creates and starts all containers
- Creates default bridge network automatically
- Mounts persistent volumes for data

### 6.2 Verify Services are Running
```bash
docker compose ps
```
**Expected output:** All services should show "Up" status:
- n8n (main service)
- n8n-webhook
- n8n-worker (2 replicas)
- postgres
- redis

### 6.3 Check Service Logs
```bash
# Check main n8n service
docker compose logs n8n

# Check workers
docker compose logs n8n-worker

# Check database
docker compose logs postgres

# Check Redis
docker compose logs redis
```

**Look for:**
- n8n: "Server ready for connections"
- postgres: "database system is ready to accept connections"
- redis: "Ready to accept connections"

## Step 7: Verify Deployment

### 7.1 Test Database Connection
```bash
docker compose exec postgres psql -U n8n -d n8n -c "SELECT version();"
```
**Expected:** PostgreSQL version information

### 7.2 Test Redis Connection
```bash
docker compose exec redis redis-cli ping
```
**Expected:** `PONG`

### 7.3 Check n8n Health Endpoint
```bash
curl -I http://localhost:5678/healthz
```
**Expected:** `HTTP/1.1 200 OK`

### 7.4 Monitor Queue System
```bash
# Check if job queue is working
docker compose exec redis redis-cli LLEN bull:jobs:wait
```
**Expected:** `0` (no jobs queued initially)

## Step 8: Access n8n

### 8.1 Wait for Load Balancer Health Checks

Before accessing n8n, wait for AWS ALB health checks to pass:

1. Go to AWS Console → EC2 → Target Groups
2. Find your n8n target groups
3. Wait for both to show "healthy" status

**This usually takes 2-3 minutes.**

### 8.2 Access n8n Web Interface

Open your browser and go to: `https://n8n.matanweisz.xyz`

### 8.3 Complete Initial Setup

1. **Set up admin user account**
2. **Configure your organization settings**
3. **Test webhook endpoint:** `https://api.n8n.matanweisz.xyz/webhook/test`

## Step 9: Test Your Setup

### 9.1 Create a Test Workflow
1. Create a simple workflow with a webhook trigger
2. Save and activate it
3. Test the webhook URL

### 9.2 Monitor Worker Activity
```bash
# Watch worker logs while testing
docker compose logs -f n8n-worker
```

### 9.3 Check Queue Processing
```bash
# Monitor queue length during workflow execution
watch "docker compose exec redis redis-cli LLEN bull:jobs:wait"
```

## Step 10: Production Checklist

### 10.1 Security Verification
- [ ] n8n accessible only through ALB (not direct IP)
- [ ] Database not exposed externally
- [ ] All secrets properly configured
- [ ] HTTPS working correctly

### 10.2 Performance Verification
- [ ] Both workers processing jobs
- [ ] Queue system working
- [ ] Database connections stable
- [ ] Memory usage reasonable

### 10.3 Backup Strategy
```bash
# Create database backup
docker compose exec postgres pg_dump -U n8n n8n > n8n-backup-$(date +%Y%m%d).sql
```

## Troubleshooting Common Issues

### Issue: Services Won't Start
```bash
# Check specific service logs
docker compose logs <service-name>

# Verify network exists
docker network ls | grep shark

# Check disk space
df -h
```

### Issue: Can't Access n8n
```bash
# Check if n8n is responding locally
curl -I http://localhost:5678/healthz

# Verify ALB target group health in AWS console
# Check security group rules allow ALB → EC2 traffic
```

### Issue: Database Connection Failed
```bash
# Test database manually
docker compose exec postgres psql -U n8n -d n8n

# Check if postgres is running
docker compose ps postgres

# Verify environment variables
docker compose exec n8n env | grep DB_
```

### Issue: Workers Not Processing Jobs
```bash
# Check worker logs
docker compose logs n8n-worker

# Verify Redis connection from workers
docker compose exec n8n-worker redis-cli -h redis ping

# Check queue configuration
docker compose exec redis redis-cli keys "bull:*"
```

## Daily Operations

### Starting Services
```bash
cd n8n-production
docker compose up -d
```

### Stopping Services
```bash
docker compose down
```

### Viewing Logs
```bash
docker compose logs -f n8n        # Main service
docker compose logs -f n8n-worker # Workers
```

### Scaling Workers (if needed)
```bash
docker compose up -d --scale n8n-worker=3  # Scale to 3 workers
docker compose up -d --scale n8n-worker=2  # Scale back to 2
```

### Updating n8n
```bash
docker compose pull  # Download latest images
docker compose up -d  # Restart with new images
```

## Important Notes

1. **Never lose your `N8N_ENCRYPTION_KEY`** - it's needed to decrypt existing workflows
2. **Backup your `.env` file** - it contains all your configuration
3. **Monitor disk space** - Docker logs and database can grow over time
4. **Regular updates** - Keep Docker images and system packages updated
5. **Monitor performance** - Watch CPU/memory usage and scale workers if needed

Your n8n production environment is now ready! 🎉