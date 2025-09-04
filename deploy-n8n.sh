#!/bin/bash

# =============================================================================
# N8N AWS Deployment Script
# =============================================================================

set -e # Exit on any error

echo "🚀 Starting N8N deployment on AWS EC2..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root"
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &>/dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed successfully"
else
    echo "✅ Docker Compose already installed"
fi

# Create .env file from example
echo "📝 Creating .env file..."
cp .env.example .env

# Generate and replace security keys
echo "🔐 Generating security keys..."
POSTGRES_PASSWORD=$(openssl rand -base64 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 16)

# Use | as delimiter to avoid issues with special characters
sed -i "s|your-secure-postgres-password-here|${POSTGRES_PASSWORD}|g" .env
sed -i "s|your-n8n-encryption-key-here|${N8N_ENCRYPTION_KEY}|g" .env

echo "✅ Security keys generated and updated in .env file"

# Start Docker service
echo "🔄 Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Start N8N services
echo "🎯 Starting N8N services..."
docker compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to become healthy..."
sleep 30

# Check service status
echo "📊 Service Status:"
docker compose ps

# Test local health endpoint
echo "🏥 Testing health endpoint..."
if curl -f http://localhost:5678/healthz >/dev/null 2>&1; then
    echo "✅ N8N health check passed"
else
    echo "⚠️  N8N health check failed - check logs with: docker compose logs n8n"
fi

echo "✅ N8N Deployment Completed!"
echo ""
echo "🌐 Access N8N: https://n8n.matanweisz.xyz"
echo "🔗 Webhooks will be available at: https://n8n.matanweisz.xyz/webhook/*"
echo ""
echo "📝 Useful commands:"
echo "  - View logs: docker compose logs -f n8n"
echo "  - Restart n8n: docker compose restart n8n"
echo "  - Check status: docker compose ps"
