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

# Generate security keys if .env doesn't exist or keys are placeholder values
if [ ! -f .env ] || grep -q "your-secure-postgres-password-here" .env; then
    echo "🔐 Generating security keys..."

    # Generate secure passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    N8N_ENCRYPTION_KEY=$(openssl rand -hex 16)

    # Update .env file
    sed -i "s/your-secure-postgres-password-here/$POSTGRES_PASSWORD/" .env
    sed -i "s/your-n8n-encryption-key-here/$N8N_ENCRYPTION_KEY/" .env

    echo "✅ Security keys generated and updated in .env file"
else
    echo "✅ .env file already configured"
fi

# Start Docker service
echo "🔄 Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Start N8N services
echo "🎯 Starting N8N services..."
sudo docker compose up -d
