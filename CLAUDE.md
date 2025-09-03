# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

```bash
# Initial setup
docker network create shark
docker compose up -d

# View logs for specific services
docker-compose logs n8n-autoscaler
docker-compose logs n8n-main

# Monitor Redis queue (for testing autoscaler)
docker-compose exec redis redis-cli LLEN bull:jobs:wait
docker-compose exec redis redis-cli LLEN bull:jobs:waiting

# Check service health
docker-compose ps
docker-compose exec redis redis-cli ping

# Restart autoscaler after code changes
docker-compose restart n8n-autoscaler

# Scale workers manually (for testing)
docker-compose up -d --scale n8n-worker=3

# Stop and clean up
docker-compose down
```

## Architecture Overview

This is a **microservices-based n8n autoscaling system** using Docker Compose. The core architecture:

```
n8n Main (Web UI) ←→ Redis Queue ←→ n8n Workers (Auto-scaled)
      ↓                    ↑              ↑
PostgreSQL           Autoscaler    Redis Monitor
      ↓                    ↓              ↓
Cloudflared ←→ Traefik (Load Balancer) ←→ External Access
```

### Key Services:
- **n8n-main**: Web interface and job dispatcher
- **n8n-worker**: Job executors (dynamically scaled 1-5 instances)
- **n8n-webhook**: Dedicated webhook handler 
- **n8n-autoscaler**: Custom Python autoscaler monitoring Redis queue
- **redis**: Job queue (BullMQ)
- **postgres**: Data persistence
- **traefik**: Load balancer with automatic SSL
- **cloudflared**: External access via Cloudflare tunnels

## Autoscaler Implementation

The autoscaler (`autoscaler/autoscaler.py`) implements intelligent scaling logic:

### Scaling Behavior:
- **Queue Monitoring**: Checks multiple Redis key patterns for BullMQ compatibility
  - `bull:jobs:wait` (BullMQ v3)
  - `bull:jobs:waiting` (BullMQ v4+)
  - `bull:jobs` (fallback)
- **Scale Up**: When queue length > `SCALE_UP_QUEUE_THRESHOLD` 
- **Scale Down**: When queue length < `SCALE_DOWN_QUEUE_THRESHOLD`
- **Incremental Scaling**: One container at a time
- **Cooldown Protection**: Prevents scaling oscillations

### Configuration (.env):
```
MIN_REPLICAS=1
MAX_REPLICAS=5  
SCALE_UP_QUEUE_THRESHOLD=5
SCALE_DOWN_QUEUE_THRESHOLD=1
POLLING_INTERVAL_SECONDS=10
COOLDOWN_PERIOD_SECONDS=10
```

## Docker Compose Patterns

### Shared Configuration:
- Uses `x-n8n` anchor for common n8n service configuration
- All services connect to external `shark` network
- Health checks determine startup order and readiness

### Volume Strategy:
- **postgres_data**: Database persistence
- **redis_data**: Queue persistence  
- **n8n_data**: Workflow and configuration data

### Service Dependencies:
Services use `depends_on` with health conditions to ensure proper startup sequencing.

## Key Configuration Files

- **.env**: Primary configuration for all services
- **docker-compose.yml**: Service orchestration and networking
- **autoscaler/autoscaler.py**: Core scaling logic
- **monitor/monitor_redis_queue.py**: Queue monitoring utilities

## Security Considerations

All services use environment-based secrets:
- `N8N_ENCRYPTION_KEY`: Workflow encryption
- `N8N_USER_MANAGEMENT_JWT_SECRET`: Authentication
- `N8N_RUNNERS_AUTH_TOKEN`: Worker authentication
- `POSTGRES_PASSWORD`: Database security

## External Access

The system provides secure external access through:
- **Webhooks**: `https://webhook.domain.com/webhook/{id}`
- **Web UI**: `https://n8n.domain.com`
- **Cloudflare Tunnels**: No port forwarding required
- **Traefik**: Automatic SSL termination and routing

## Monitoring and Debugging

Use the Redis monitor service to observe queue behavior:
```bash
# Check current queue length
docker-compose exec redis redis-cli LLEN bull:jobs:wait

# Monitor autoscaler decisions
docker-compose logs -f n8n-autoscaler

# Watch queue changes via autoscaler logs
docker-compose logs -f n8n-autoscaler
```

## Production Capabilities

This system is production-ready with:
- **Puppeteer Integration**: Chrome/Chromium for web scraping
- **Multi-worker Scaling**: Handles high-concurrency workloads
- **Graceful Shutdowns**: Configurable timeout for job completion
- **Health Monitoring**: All critical services have health checks
- **Network Isolation**: Internal Docker networking for security

The system has been validated to handle "hundreds of simultaneous executions" on an 8-core, 16GB RAM VPS.