# N8N Project Documentation

This repository contains a simplified n8n automation platform deployment with AWS infrastructure provisioning via Terraform.

## Project Overview

This project provides:
- **Simplified n8n Docker setup** with PostgreSQL database
- **AWS Infrastructure** provisioned via Terraform
- **Production-ready deployment** on AWS EC2 with Application Load Balancer
- **SSL/TLS termination** and domain routing
- **Secure private subnet deployment** with optional bastion host access

## Architecture

```
Internet → ALB (HTTPS) → EC2 (Private Subnet) → n8n + PostgreSQL (Docker)
                                     ↑
                              Bastion Host (Optional)
```

### Infrastructure Components:
- **VPC**: Custom VPC with public/private subnets
- **ALB**: Application Load Balancer with SSL termination
- **EC2**: Ubuntu 24.04 LTS instance in private subnet
- **Route53**: DNS records for domain routing
- **Security Groups**: Properly configured network access
- **Bastion Host**: Optional SSH access to private instances

### Application Stack:
- **n8n**: Main automation platform (official Docker image)
- **PostgreSQL**: Database for workflow and execution data
- **Docker Compose**: Container orchestration

## Quick Start (Local Development)

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

## AWS Production Deployment

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (>= 1.0)
3. **Domain registered** with Route53 hosted zone
4. **SSL certificate** issued via AWS Certificate Manager
5. **SSH key pair** created in AWS EC2

### Step 1: Update Terraform Configuration

1. **Update domain configuration** in `main.tf`:
```hcl
locals {
  n8n_domain    = "your-domain.com"  # Update with your domain
  key_pair_name = "your-key-pair"    # Update with your SSH key pair name
}
```

2. **Update Route53 zone** in `main.tf`:
```hcl
data "aws_route53_zone" "main" {
  name         = "your-domain.com"  # Update with your domain
  private_zone = false
}
```

3. **Update ACM certificate** reference in `main.tf`:
```hcl
data "aws_acm_certificate" "wildcard_cert" {
  domain      = "your-domain.com"   # Update with your domain
  statuses    = ["ISSUED"]
  most_recent = true
  types       = ["AMAZON_ISSUED"]
}
```

### Step 2: Deploy Infrastructure

1. **Initialize Terraform**:
```bash
terraform init
```

2. **Plan the deployment**:
```bash
terraform plan
```

3. **Apply the infrastructure**:
```bash
terraform apply
```

4. **Note the outputs** - save the bastion host IP and n8n instance details.

### Step 3: Deploy Application

1. **Connect to the n8n instance** via bastion host:
```bash
# SSH to bastion host first
ssh -i your-key.pem ubuntu@<bastion-ip>

# From bastion, SSH to n8n instance
ssh ubuntu@<n8n-instance-private-ip>
```

2. **Install Docker and Docker Compose** on the n8n instance:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for group changes
exit
# SSH back in
```

3. **Clone the project repository**:
```bash
git clone <your-repository-url>
cd n8n-project/n8n
```

4. **Generate security keys**:
```bash
# Generate PostgreSQL password
openssl rand -base64 32

# Generate n8n encryption key
openssl rand -hex 16
```

5. **Update environment configuration**:
```bash
# Edit .env file
nano .env

# Update these values:
POSTGRES_PASSWORD=<your-generated-password>
N8N_ENCRYPTION_KEY=<your-generated-key>
N8N_HOST=<your-domain>  # e.g., n8n.yourdomain.com
```

6. **Start the application**:
```bash
docker-compose up -d
```

7. **Verify deployment**:
```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs n8n
docker-compose logs postgres
```

### Step 4: Access n8n

1. **Wait for health checks** - Allow 2-3 minutes for the ALB health checks to pass
2. **Access n8n** at `https://your-domain.com`
3. **Create admin user** when prompted

### Monitoring and Troubleshooting

#### Check Application Status:
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f n8n
docker-compose logs -f postgres

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

#### Common Issues:

1. **Health check failures**:
   - Ensure n8n is running: `docker-compose ps`
   - Check n8n logs: `docker-compose logs n8n`
   - Verify port 5678 is accessible: `curl http://localhost:5678/healthz`

2. **Database connection errors**:
   - Check PostgreSQL logs: `docker-compose logs postgres`
   - Verify database credentials in `.env`

3. **SSL/HTTPS issues**:
   - Verify ACM certificate is issued and valid
   - Check Route53 DNS records are pointing to ALB
   - Ensure domain matches the certificate

#### Updating the Application:
```bash
# Pull latest changes
git pull

# Restart containers
docker-compose down && docker-compose up -d
```

### Security Considerations

- **Private Subnet**: EC2 instance is deployed in private subnet for security
- **Bastion Host**: Provides secure SSH access to private instances
- **SSL Termination**: HTTPS enforced at ALB level
- **Security Groups**: Restrictive firewall rules
- **Environment Variables**: Sensitive data stored in `.env` file

### Scaling and Performance

- **Instance Type**: Default is `t3.large` - adjust based on workload
- **Storage**: Default 50GB GP3 volume - increase if needed
- **Database**: PostgreSQL runs on same instance - consider RDS for production scale
- **Health Checks**: Configured for reliability with appropriate timeouts

### Backup Strategy

1. **Database Backups**: 
```bash
# Manual backup
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql
```

2. **Volume Backups**:
```bash
# Backup n8n data
sudo tar -czf n8n-backup.tar.gz /var/lib/docker/volumes/
```

3. **Automated Backups**: Consider AWS Backup service for EBS volumes