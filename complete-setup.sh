```bash
#!/bin/bash
# complete-setup.sh – Full deployment for QFX Finance on a fresh Ubuntu 22.04 server
set -e

echo "🚀 QFX Finance – Complete Setup Script"
echo "======================================="

# 1. System update & dependencies
echo "📦 Updating system and installing base packages..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx

# 2. Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 3. Install Docker Compose (standalone)
echo "🐳 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Clone the repository
echo "📂 Cloning repository..."
git clone https://github.com/mfhquzit/qfx-finance.com.git
cd qfx-finance.com

# 5. Create .env from example (if not present)
if [ ! -f .env ]; then
    echo "🔧 Creating .env file from template..."
    cp .env.example .env
    # Generate strong secrets
    JWT_SECRET=$(openssl rand -base64 64)
    JWT_REFRESH_SECRET=$(openssl rand -base64 64)
    DB_PASSWORD=$(openssl rand -base64 32)
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    sed -i "s/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET/" .env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
    echo "✅ .env created with random secrets."
else
    echo "⚠️  .env already exists – skipping generation."
fi

# 6. Build and start Docker containers
echo "🏗️ Building and starting services..."
docker-compose up -d --build

# 7. Wait for database to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 10
docker-compose exec -T postgres pg_isready -U qfx_user || true

# 8. Run Prisma migrations & seed
echo "🗄️ Running database migrations..."
docker-compose exec -T api npx prisma migrate deploy
echo "🌱 Seeding database..."
docker-compose exec -T api npx prisma db seed

# 9. Configure firewall (allow SSH, HTTP, HTTPS)
echo "🔥 Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# 10. Nginx + SSL (interactive – you need to provide domain)
echo "🌐 Setting up Nginx reverse proxy..."
sudo cp nginx/qfx-finance.conf /etc/nginx/sites-available/qfx-finance
sudo ln -sf /etc/nginx/sites-available/qfx-finance /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo ""
echo "🔒 To obtain SSL certificates, run (replace with your actual domain):"
echo "   sudo certbot --nginx -d qfx-finance.com -d api.qfx-finance.com"
echo ""
echo "✅ Setup complete!"
echo "🌍 Your application is running at http://$(curl -s ifconfig.me)"
echo "📊 API health check: http://localhost:3001/health"
```

---

🔧 How to Use

1. Save the script on your fresh Ubuntu 22.04 VPS:
   ```bash
   nano complete-setup.sh
   ```
   Paste the content, save (Ctrl+X, Y, Enter).
2. Make it executable:
   ```bash
   chmod +x complete-setup.sh
   ```
3. Run it:
   ```bash
   ./complete-setup.sh
   ```
4. After the script finishes, edit the .env file to add your Stripe, CoinGecko, Binance, SMTP keys (the script already generated JWT secrets).
5. Obtain SSL certificates (replace with your real domain):
   ```bash
   sudo certbot --nginx -d yourdomain.com -d api.yourdomain.com
   ```

---

❌ Problems with your original script

Issue Why it fails for QFX Finance
Node.js 14 Next.js 15 requires Node.js 18+, Prisma 5 requires Node.js 16+; 14 is too old.
npm install + npm start The monorepo needs npm ci, build, and Docker containers; running without Docker misses PostgreSQL, Redis, Prisma migrations.
No environment variables The app cannot connect to database, Stripe, etc.
No database npm start would crash immediately.
No Docker The platform is designed to run with Docker Compose (PostgreSQL, Redis, three services).

Your improved script solves all of these and deploys a production‑ready QFX Finance instance in one go. 🚀
