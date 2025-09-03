#!/bin/bash

# =============================================================================
# N8N AWS Deployment Script
# =============================================================================

set -e  # Exit on any error

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
if ! command -v docker &> /dev/null; then
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
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed successfully"
else
    echo "✅ Docker Compose already installed"
fi

# Install Git if not present
echo "📝 Installing Git..."
if ! command -v git &> /dev/null; then
    sudo apt install -y git
    echo "✅ Git installed successfully"
else
    echo "✅ Git already installed"
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

# Check if user needs to be added to docker group
if ! groups $USER | grep -q docker; then
    echo "👤 Adding user to docker group..."
    echo "⚠️  You'll need to log out and log back in for group changes to take effect"
    echo "⚠️  After logging back in, run this script again to continue"
    exit 0
fi

# Start Docker service
echo "🔄 Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Check if Docker is working
if ! docker ps &> /dev/null; then
    echo "❌ Docker is not running properly. Please check the installation."
    exit 1
fi

# Start N8N services
echo "🎯 Starting N8N services..."
docker-compose down 2>/dev/null || true  # Stop if already running
docker-compose pull  # Pull latest images
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "🔍 Checking service status..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ N8N services are running!"
    
    # Show service status
    docker-compose ps
    
    echo ""
    echo "🎉 N8N deployment completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Ensure your ALB health checks pass (may take 2-3 minutes)"
    echo "  2. Access N8N at your configured domain"
    echo "  3. Create your admin user account"
    echo ""
    echo "🔧 Useful commands:"
    echo "  - Check logs: docker-compose logs -f n8n"
    echo "  - Check status: docker-compose ps"
    echo "  - Restart services: docker-compose restart"
    echo "  - Stop services: docker-compose down"
    echo ""
    echo "🌐 Health check URL: http://localhost:5678/healthz"
    
    # Test health check
    sleep 10
    if curl -s http://localhost:5678/healthz > /dev/null; then
        echo "✅ Health check passed - N8N is responding correctly!"
    else
        echo "⚠️  Health check failed - check logs with: docker-compose logs n8n"
    fi
    
else
    echo "❌ Services failed to start properly. Check logs:"
    docker-compose logs
    exit 1
fi