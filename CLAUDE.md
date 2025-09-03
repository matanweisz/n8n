# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

```bash
# Initial setup
docker network create shark
docker compose up -d

# View logs for specific services
docker-compose logs n8n
docker-compose logs n8n-worker

# Monitor Redis queue
docker-compose exec redis redis-cli LLEN bull:jobs:wait
docker-compose exec redis redis-cli LLEN bull:jobs:waiting

# Check service health
docker-compose ps
docker-compose exec redis redis-cli ping

# Restart services after changes
docker-compose restart n8n

# Scale workers manually
docker-compose up -d --scale n8n-worker=3

# Stop and clean up
docker-compose down
```

## Architecture Overview

This is a **production-ready n8n system** using Docker Compose with queue-based execution. The core architecture:

```
n8n Main (Web UI) ←→ Redis Queue ←→ n8n Workers (2 replicas)
      ↓                    ↑              ↑
PostgreSQL                              n8n Webhook
      ↓
ALB (Load Balancer) ←→ External Access
```

### Key Services:
- **n8n**: Web interface and job dispatcher
- **n8n-worker**: Job executors (2 replicas, manually scalable)
- **n8n-webhook**: Dedicated webhook handler 
- **redis**: Job queue (BullMQ)
- **postgres**: Data persistence
- **ALB**: AWS Application Load Balancer for external access

## Worker Scaling

The system uses 2 worker replicas by default for reliable job processing:

### Manual Scaling:
- **Scale Up**: `docker-compose up -d --scale n8n-worker=3`
- **Scale Down**: `docker-compose up -d --scale n8n-worker=1`
- **Monitor Queue**: Check Redis queue length to determine if scaling is needed
- **Queue Commands**: `docker-compose exec redis redis-cli LLEN bull:jobs:wait`

### Performance Configuration (.env):
```
N8N_CONCURRENCY_PRODUCTION_LIMIT=10
N8N_QUEUE_BULL_GRACEFULSHUTDOWNTIMEOUT=300
N8N_GRACEFUL_SHUTDOWN_TIMEOUT=300
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

# Monitor n8n main service
docker-compose logs -f n8n

# Monitor worker processes
docker-compose logs -f n8n-worker
```

## Production Capabilities

This system is production-ready with:
- **Puppeteer Integration**: Chrome/Chromium for web scraping
- **Multi-worker Scaling**: Handles high-concurrency workloads
- **Graceful Shutdowns**: Configurable timeout for job completion
- **Health Monitoring**: All critical services have health checks
- **Network Isolation**: Internal Docker networking for security

The system has been validated to handle "hundreds of simultaneous executions" on an 8-core, 16GB RAM VPS.