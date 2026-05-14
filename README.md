```markdown
# 🚀 QFX Finance - Institutional Crypto Banking Platform

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/mfhquzit/qfx-finance.com)
[![Node](https://img.shields.io/badge/node-20.x-green.svg)](https://nodejs.org)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://docker.com)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)

## 📖 Overview

QFX Finance is a production‑grade **crypto banking and institutional wealth management platform** featuring:

- **Multi‑asset support** – Crypto, fiat, stablecoins  
- **Automated daily ROI** – 2%–8% daily returns on investment plans  
- **Web3 wallet integration** – MetaMask, WalletConnect  
- **Real‑time crypto prices** – WebSocket feeds from CoinGecko/Binance  
- **Enterprise security** – JWT + refresh tokens, 2FA (TOTP), rate limiting  
- **Complete KYC/AML workflow** – Document upload, approval queue  
- **Admin dashboard** – User management, transaction oversight, compliance tools  
- **CI/CD ready** – Docker Compose, GitHub Actions, Nginx + SSL  

---

## 🏗️ Tech Stack

| Layer       | Technologies                                                                 |
|-------------|------------------------------------------------------------------------------|
| **Backend** | NestJS, Prisma ORM, PostgreSQL, Redis, JWT, Speakeasy (2FA), Stripe          |
| **Frontend**| Next.js 15 (App Router), Zustand, TanStack Query, ApexCharts, Framer Motion  |
| **Web3**    | Wagmi, Web3Modal, viem                                                       |
| **DevOps**  | Docker Compose, Nginx, Certbot, GitHub Actions                               |
| **APIs**    | CoinGecko, Binance, Stripe, SMTP (SendGrid/AWS SES)                          |

---

## ✨ Features

### 👤 User Dashboard
- Real‑time portfolio balance & performance charts  
- Active investment plans with countdown timers  
- Transaction history (filter, export CSV)  
- One‑click deposit (Stripe) & withdrawal requests  
- Web3 wallet connection & verification  

### 📈 Investment Plans
| Plan     | Min Investment | Daily ROI | Duration | Total Return |
|----------|---------------|-----------|----------|--------------|
| Bronze   | $100          | 2.0%      | 30 days  | 160%         |
| Silver   | $1,000        | 3.5%      | 45 days  | 257.5%       |
| Gold     | $5,000        | 5.0%      | 60 days  | 400%         |
| VIP      | $20,000+      | 8.0%      | 90 days  | 720%         |

### 🔐 Security
- Password hashing (bcrypt, saltRounds=12)  
- JWT with refresh tokens (stored in Redis)  
- TOTP 2FA with backup codes  
- Account lockout after 5 failed attempts  
- Rate limiting (10 req/sec per IP)  
- Audit logging for all admin actions  

---

## 🚀 Quick Start

### Prerequisites
- Node.js 20+ & npm  
- Docker & Docker Compose (recommended)  
- PostgreSQL 15+ & Redis 7+ (if not using Docker)

### Clone & Install

```bash
git clone https://github.com/mfhquzit/qfx-finance.com.git
cd qfx-finance.com
cp .env.example .env
```

Edit .env with your own secrets (see Environment Variables).

Run with Docker (Production)

```bash
docker-compose up -d --build
docker-compose exec api npx prisma migrate deploy
docker-compose exec api npx prisma db seed
```

Access the services:

· Client: http://localhost:3000
· Admin: http://localhost:3002
· API: http://localhost:3001
· API Docs: http://localhost:3001/api/docs

Local Development (without Docker)

```bash
npm install
npx prisma generate
npx prisma migrate dev --name init
npx prisma db seed
npm run dev
```

---

🐳 Docker Deployment (Production)

One‑command server setup (Ubuntu 22.04)

```bash
curl -sSL https://raw.githubusercontent.com/mfhquzit/qfx-finance.com/main/scripts/install.sh | sudo bash
```

Manual deployment

```bash
# Clone on your VPS
git clone https://github.com/mfhquzit/qfx-finance.com.git /var/www/qfx-finance
cd /var/www/qfx-finance

# Configure environment
cp .env.example .env
nano .env   # add your keys

# Deploy
docker-compose up -d --build
docker-compose exec api npx prisma migrate deploy
docker-compose exec api npx prisma db seed

# Setup Nginx + SSL (replace with your domain)
sudo apt install -y nginx certbot python3-certbot-nginx
sudo cp nginx/qfx-finance.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/qfx-finance.conf /etc/nginx/sites-enabled/
sudo certbot --nginx -d qfx-finance.com -d api.qfx-finance.com
```

---

🔧 Environment Variables

Create a .env file in the root with at least these:

```env
# Database
DATABASE_URL=postgresql://qfx_user:${DB_PASSWORD}@postgres:5432/qfx_db

# JWT (generate with `openssl rand -base64 64`)
JWT_SECRET=your_64char_secret
JWT_REFRESH_SECRET=another_64char_secret

# Stripe (live keys)
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Crypto APIs
COINGECKO_API_KEY=CG-xxx
BINANCE_API_KEY=xxx
BINANCE_API_SECRET=xxx

# Admin account (created during seeding)
ADMIN_EMAIL=admin@qfx-finance.com
ADMIN_PASSWORD=YourStrongPass123!

# SMTP (for email verification & notifications)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=SG.xxx
SMTP_FROM=noreply@qfx-finance.com

# Web3
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=xxx
```

---

📊 API Documentation

Once running, interactive Swagger docs are available at:

· Local: http://localhost:3001/api/docs
· Production: https://api.qfx-finance.com/api/docs

Key endpoints:

Method Endpoint Description
POST /auth/register Create new user
POST /auth/login Login (returns JWT)
POST /auth/2fa/setup Enable TOTP 2FA
GET /users/me Get current user profile
POST /investments/activate Start an investment plan
GET /investments/my List user investments
POST /transactions/deposit Create Stripe deposit intent
GET /admin/users (Admin) List all users

---

🛠️ Maintenance & Health Checks

```bash
# Check all services health
curl http://localhost:3001/health/detailed

# View logs
docker-compose logs -f api

# Backup database
docker exec qfx-postgres pg_dump -U qfx_user qfx_db | gzip > backup.sql.gz

# Restore database
gunzip -c backup.sql.gz | docker exec -i qfx-postgres psql -U qfx_user -d qfx_db

# Run database migrations (after code update)
docker-compose exec api npx prisma migrate deploy
```

---

🔄 CI/CD Pipeline

The repository includes a GitHub Actions workflow (.github/workflows/deploy.yml) that automatically:

1. Runs tests on every push
2. Builds Docker images
3. Pushes images to Docker Hub
4. SSHs into your VPS and restarts containers with the new version

Required GitHub Secrets:

· VPS_HOST, VPS_USER, VPS_SSH_KEY, VPS_PORT
· DOCKER_USERNAME, DOCKER_PASSWORD

---

🧪 Testing

```bash
# Unit tests
npm run test --workspace=api

# E2E tests (requires Docker services running)
npm run test:e2e --workspace=api

# Test coverage
npm run test:cov --workspace=api
```

---

📁 Project Structure

```
qfx-finance.com/
├── apps/
│   ├── api/                # NestJS backend
│   ├── client/             # Next.js user dashboard
│   └── admin/              # Next.js admin portal
├── packages/
│   └── ui/                 # Shared UI components
├── prisma/
│   ├── schema.prisma       # Database models
│   └── seed.ts             # Initial data (admin, plans, wallets)
├── nginx/
│   └── qfx-finance.conf    # Reverse proxy + SSL config
├── scripts/
│   ├── deploy.sh
│   ├── backup-database.sh
│   └── health-check.sh
├── docker-compose.yml
├── .env.example
├── .github/workflows/deploy.yml
└── README.md
```

---

🤝 Contributing

Internal use only – this repository is proprietary.
For issues or feature requests, contact support@qfx-finance.com.

---

📄 License

Proprietary – all rights reserved.

---

🌐 Links

· Website: https://qfx-finance.com
· API Status: https://status.qfx-finance.com
· Documentation: https://docs.qfx-finance.com

---

Built with ❤️ by the QFX Finance Team
Last updated: 2024

```

---

## 📝 How to Use

1. **Replace** your existing `README.md` with the content above.  
2. **Adjust** domain names, email addresses, and any other placeholders as needed.  
3. **Commit and push**:

```bash
git add README.md
git commit -m "docs: complete production README"
git push origin main
```

This README is professional, detailed, and matches the actual QFX Finance platform. It includes everything from quick start to advanced deployment, making it easy for any developer or sysadmin to get the project running. 🚀
