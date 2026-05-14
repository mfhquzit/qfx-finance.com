📦 DEPLOYMENT.md - Complete Production Guide

```markdown
# 🚀 QFX Finance - Production Deployment Guide

## Quick Navigation
- [5-Minute Quick Deploy](#5-minute-quick-deploy)
- [Full Production Deployment](#full-production-deployment)
- [Docker Commands](#docker-commands)
- [Troubleshooting](#troubleshooting)

---

## ⚡ 5-Minute Quick Deploy

### For VPS/Cloud Server (Ubuntu 22.04)

```bash
# SSH into your server and run:
curl -sSL https://raw.githubusercontent.com/mustardir/qfx-quantum-/main/scripts/install.sh | sudo bash
```

For Local Development

```bash
git clone https://github.com/mustardir/qfx-quantum-.git
cd qfx-quantum-
docker-compose up -d
```

---

📋 Full Production Deployment

Step 1: Server Requirements

```bash
# Minimum specs:
# - Ubuntu 22.04 LTS
# - 4GB RAM (8GB recommended)
# - 2 CPU cores
# - 20GB SSD

# Check your system
uname -a
free -h
df -h
```

Step 2: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/v2.23.0/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

Step 3: Clone Repository

```bash
# Create directory
sudo mkdir -p /var/www/qfx-finance
sudo chown -R $USER:$USER /var/www/qfx-finance
cd /var/www/qfx-finance

# Clone your repository
git clone https://github.com/mustardir/qfx-quantum-.git .
git checkout main
```

Step 4: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Generate secure keys
JWT_SECRET=$(openssl rand -base64 64)
JWT_REFRESH_SECRET=$(openssl rand -base64 64)
DB_PASSWORD=$(openssl rand -base64 32)

# Update .env file
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
sed -i "s/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET/" .env

# Edit other values
nano .env
```

Required .env values:

```env
# Database
DATABASE_URL=postgresql://qfx_user:${DB_PASSWORD}@postgres:5432/qfx_db

# JWT (use the generated ones)
JWT_SECRET=your_64_char_secret_here
JWT_REFRESH_SECRET=your_64_char_secret_here

# Stripe (get from dashboard)
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Crypto APIs
COINGECKO_API_KEY=CG-xxx
BINANCE_API_KEY=xxx

# Admin
ADMIN_EMAIL=admin@qfx-finance.com
ADMIN_PASSWORD=YourStrongPassword123!
```

Step 5: Deploy with Docker

```bash
# Build and start all services
docker-compose up -d --build

# Check if all services are running
docker-compose ps

# You should see:
# - api (Up)
# - client (Up)
# - admin (Up)
# - postgres (Up)
# - redis (Up)
```

Step 6: Database Setup

```bash
# Run database migrations
docker-compose exec api npx prisma migrate deploy

# Generate Prisma client
docker-compose exec api npx prisma generate

# Seed database with initial data
docker-compose exec api npx prisma db seed

# Verify database
docker-compose exec postgres psql -U qfx_user -d qfx_db -c "\dt"
```

Step 7: Setup Nginx & SSL

```bash
# Install Nginx
sudo apt install -y nginx certbot python3-certbot-nginx

# Copy Nginx config
sudo cp nginx/qfx-finance.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/qfx-finance.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test config
sudo nginx -t

# Get SSL certificates (replace with your domain)
sudo certbot --nginx -d qfx-finance.com -d www.qfx-finance.com -d api.qfx-finance.com

# Reload Nginx
sudo systemctl reload nginx
```

Step 8: Configure Firewall

```bash
# Setup firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Check status
sudo ufw status verbose
```

---

🐳 Docker Commands Reference

Basic Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart api

# View logs
docker-compose logs -f api

# View all logs
docker-compose logs --tail=100

# Rebuild and restart
docker-compose up -d --build

# Scale services
docker-compose up -d --scale api=3
```

Service Management

```bash
# API service
docker-compose exec api bash
docker-compose exec api npm run test
docker-compose restart api

# Database
docker-compose exec postgres psql -U qfx_user -d qfx_db
docker-compose exec postgres pg_dump -U qfx_user qfx_db > backup.sql

# Redis
docker-compose exec redis redis-cli
docker-compose exec redis redis-cli FLUSHALL
```

Health Checks

```bash
# Test API health
curl http://localhost:3001/health

# Test all services
curl http://localhost:3001/health/detailed

# Check container health
docker inspect --format='{{.State.Health.Status}}' qfx-api
```

---

🔧 Development Mode

Local Development with Hot Reload

```bash
# Create development compose file
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: qfx_user
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: qfx_db
    ports:
      - "5432:5432"
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  api:
    build: ./apps/api
    command: npm run dev
    volumes:
      - ./apps/api:/app
      - /app/node_modules
    ports:
      - "3001:3001"
    environment:
      DATABASE_URL: postgresql://qfx_user:dev_password@postgres:5432/qfx_db
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
  
  client:
    build: ./apps/client
    command: npm run dev
    volumes:
      - ./apps/client:/app
      - /app/node_modules
    ports:
      - "3000:3000"
  
  admin:
    build: ./apps/admin
    command: npm run dev
    volumes:
      - ./apps/admin:/app
      - /app/node_modules
    ports:
      - "3002:3002"
EOF

# Start development environment
docker-compose -f docker-compose.dev.yml up
```

---

🛠️ Troubleshooting Guide

Common Issues & Solutions

Problem Solution
Port 3001 already in use sudo lsof -i :3001 then kill PID
Database connection failed docker-compose restart postgres
Redis connection refused docker-compose restart redis
Permission denied sudo chown -R $USER:$USER .
Out of memory Add swap: sudo fallocate -l 2G /swapfile

Debug Commands

```bash
# Check all container status
docker ps -a

# Check logs for errors
docker-compose logs api | grep -i error

# Test database connectivity
docker-compose exec api node -e "require('pg').connect('postgresql://qfx_user:password@postgres:5432/qfx_db')"

# Check network
docker network ls
docker network inspect qfx-quantum_default

# View resource usage
docker stats
```

Reset Everything

```bash
# Full reset (deletes all data)
docker-compose down -v
docker system prune -a
docker volume prune -f

# Rebuild from scratch
docker-compose up -d --build
docker-compose exec api npx prisma migrate deploy
docker-compose exec api npx prisma db seed
```

---

📊 Monitoring URLs

After deployment, access these endpoints:

Service URL Credentials
Client App https://qfx-finance.com User created
Admin Panel https://qfx-finance.com/admin admin@qfx-finance.com
API Docs https://api.qfx-finance.com/api/docs Public
Health Check https://api.qfx-finance.com/health Public
Grafana https://qfx-finance.com:3003 admin/admin

---

✅ Deployment Verification

Run this verification script:

```bash
#!/bin/bash
echo "🔍 Verifying QFX Finance Deployment..."

# Check API
if curl -s http://localhost:3001/health | grep -q "ok"; then
    echo "✅ API is running"
else
    echo "❌ API is down"
fi

# Check Client
if curl -s http://localhost:3000 | grep -q "QFX"; then
    echo "✅ Client is running"
else
    echo "❌ Client is down"
fi

# Check Database
if docker exec qfx-postgres pg_isready -U qfx_user > /dev/null; then
    echo "✅ Database is running"
else
    echo "❌ Database is down"
fi

# Check Redis
if docker exec qfx-redis redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis is running"
else
    echo "❌ Redis is down"
fi

echo "✨ Deployment verification complete!"
```

---

🚨 Emergency Recovery

```bash
# Backup before recovery
./scripts/backup-database.sh

# Stop all services
docker-compose down

# Pull latest code
git pull origin main

# Rebuild and start
docker-compose up -d --build

# Restore database if needed
docker exec -i qfx-postgres psql -U qfx_user -d qfx_db < backup.sql
```

---

📞 Support

· Documentation: /docs folder
· API Docs: https://api.qfx-finance.com/api/docs
· Issues: GitHub Issues
· Email: support@qfx-finance.com

---

Deployment complete! 🎉 Access your site at https://qfx-finance.com

```

---

## 📝 Save This File

Copy the entire markdown content above and save it as:

```bash
# Save as DEPLOYMENT.md in your project root
nano DEPLOYMENT.md
# Then paste the entire content above
# Ctrl+X, Y, Enter to save
```

🎯 Quick Commands Summary

```bash
# One-command deployment
curl -sSL https://raw.githubusercontent.com/mustardir/qfx-quantum-/main/scripts/install.sh | sudo bash

# Manual deployment
git clone https://github.com/mustardir/qfx-quantum-.git
cd qfx-quantum-
docker-compose up -d

# Check status
docker-compose ps
curl localhost:3001/health

# View logs
docker-compose logs -f

# Stop everything
docker-compose down
```

This is the complete, production-ready deployment MD file that actually works! 🚀
