```bash
#!/bin/bash
# deploy-and-verify.sh – Full deployment & verification for QFX Finance
set -e

# ===========================
# CONFIGURATION (edit these)
# ===========================
REPO_URL="https://github.com/mfhquzit/qfx-finance.com.git"
BRANCH="main"
DEPLOY_DIR="/var/www/qfx-finance"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Service URLs for verification
API_HEALTH_URL="http://localhost:3001/health"
CLIENT_URL="http://localhost:3000"
ADMIN_URL="http://localhost:3002"

# ===========================
# FUNCTIONS
# ===========================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log "ERROR: $1 is not installed. Exiting."
        exit 1
    fi
}

# ===========================
# PREREQUISITES CHECK
# ===========================
log "🔍 Checking prerequisites..."
check_command git
check_command docker
check_command docker-compose

# ===========================
# DEPLOYMENT
# ===========================
# 1. Clone or update repository
if [ -d "$DEPLOY_DIR/.git" ]; then
    log "📂 Updating existing repository..."
    cd "$DEPLOY_DIR"
    git pull origin "$BRANCH"
else
    log "📥 Cloning repository..."
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown -R $USER:$USER "$DEPLOY_DIR"
    git clone "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

# 2. Environment file
if [ ! -f "$ENV_FILE" ]; then
    log "🔧 Creating .env file from .env.example..."
    cp .env.example .env
    # Generate random secrets if not already set
    JWT_SECRET=$(openssl rand -base64 64)
    JWT_REFRESH_SECRET=$(openssl rand -base64 64)
    DB_PASSWORD=$(openssl rand -base64 32)
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    sed -i "s/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET/" .env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
    log "✅ .env created with strong secrets."
else
    log "⚠️  .env already exists – using existing configuration."
fi

# 3. Stop old containers (graceful)
log "🛑 Stopping old containers (if any)..."
docker-compose down

# 4. Build and start services
log "🏗️ Building and starting Docker services..."
docker-compose up -d --build

# 5. Wait for database to be healthy
log "⏳ Waiting for PostgreSQL..."
until docker-compose exec -T postgres pg_isready -U qfx_user &> /dev/null; do
    sleep 2
done
log "✅ PostgreSQL is ready."

# 6. Run database migrations
log "🗄️ Running Prisma migrations..."
docker-compose exec -T api npx prisma migrate deploy

# 7. Seed the database (admin, investment plans, wallets)
log "🌱 Seeding database..."
docker-compose exec -T api npx prisma db seed

# ===========================
# VERIFICATION
# ===========================
log "🔍 Verifying deployment..."

# 7.1 API health check
if curl -f -s "$API_HEALTH_URL" | grep -q '"status":"ok"'; then
    log "✅ API is healthy"
else
    log "❌ API health check failed"
    docker-compose logs --tail=50 api
    exit 1
fi

# 7.2 Client availability
if curl -f -s -o /dev/null "$CLIENT_URL"; then
    log "✅ Client is reachable"
else
    log "❌ Client is not responding"
    exit 1
fi

# 7.3 Admin availability
if curl -f -s -o /dev/null "$ADMIN_URL"; then
    log "✅ Admin portal is reachable"
else
    log "❌ Admin portal is not responding"
    exit 1
fi

# 7.4 Database connection from API
if docker-compose exec -T api npx prisma db execute --stdin <<< "SELECT 1" &> /dev/null; then
    log "✅ API can connect to database"
else
    log "❌ API database connection failed"
    exit 1
fi

# 7.5 Redis connection check
if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
    log "✅ Redis is responding"
else
    log "❌ Redis is not responding"
    exit 1
fi

# ===========================
# FINAL STATUS
# ===========================
log "🎉 Deployment and verification completed successfully!"
log "🌍 Client:      $CLIENT_URL"
log "🛠️ Admin:       $ADMIN_URL"
log "📡 API:         http://localhost:3001"
log "📚 API Docs:    http://localhost:3001/api/docs"
log ""
log "💡 Next steps:"
log "   - Set up SSL with Certbot (if domain is pointed)."
log "   - Configure Stripe, CoinGecko, Binance keys in .env and restart."
log "   - Create admin user via the registration endpoint or seeding."
```

---

How to Use

1. Save the script as deploy-and-verify.sh in your project root or on your server.
   ```bash
   nano deploy-and-verify.sh
   ```
   Paste the content.
2. Make it executable:
   ```bash
   chmod +x deploy-and-verify.sh
   ```
3. Run it:
   ```bash
   ./deploy-and-verify.sh
   ```
4. Optional – edit the configuration variables at the top of the script if your paths or URLs differ.

---

What This Script Fixes vs. Your Original

Your original script This script
Copies dist/ files manually Uses Docker Compose to build and run containers
No database, no Redis Starts PostgreSQL and Redis, runs migrations + seeding
Hardcoded placeholders (/path/to/...) Uses real repository URL and deployment directory
Only HTTP 200 check Checks API health, client, admin, DB connection, Redis
Ignores environment variables Creates .env from template and generates strong secrets
No rollback or error handling Graceful shutdown, exit on failure, helpful logs

This script fully automates the production deployment described in the master prompt and matches the architecture of QFX Finance. 🚀
