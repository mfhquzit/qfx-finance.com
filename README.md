# QFX Finance - Full-Stack Investment Platform

A battle-tested, full-stack investment platform built for real-world usage — featuring crypto wallets, algorithmic bot trading, live asset exchange, KYC compliance, and a powerful admin panel.

## 🚀 Features

- **Crypto Wallets**: Secure wallet management with multiple blockchain support
- **Algorithmic Trading Bot**: Automated trading strategies with advanced risk management
- **Live Asset Exchange**: Real-time asset trading and portfolio management
- **KYC Compliance**: Complete Know-Your-Customer verification system
- **Admin Panel**: Comprehensive dashboard for platform management
- **WebSocket Support**: Real-time data streaming and notifications
- **JWT Authentication**: Secure token-based authentication
- **Two-Factor Authentication (2FA)**: Enhanced security with TOTP support
- **Rate Limiting**: Built-in throttling for API protection

## 📋 Prerequisites

- Node.js >= 20.19.0
- npm >= 10.0.0
- PostgreSQL (for database)
- Redis (for caching)
- Stripe account (for payments)

## 🛠️ Installation

### 1. Clone the repository

```bash
git clone https://github.com/mfhquzit/qfx-finance.com.git
cd qfx-finance.com
```

### 2. Install dependencies

```bash
npm install
```

### 3. Setup environment variables

```bash
cp .env.example .env
```

Then edit `.env` with your actual configuration values.

### 4. Setup database

```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# (Optional) Seed database with sample data
npm run prisma:seed
```

## 💻 Development

### Start development server with watch mode

```bash
npm run dev
```

The API will be available at `http://localhost:3000`

### Linting and Formatting

```bash
# Run ESLint with fixes
npm run lint

# Format code with Prettier
npm run format
```

### Testing

```bash
# Run tests
npm run test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:cov
```

## 🔨 Build and Production

### Build for production

```bash
npm run build
```

### Start production server

```bash
npm start
```

## 📊 Database

This project uses Prisma ORM with PostgreSQL.

### Generate Prisma Client

```bash
npm run prisma:generate
```

### Create new migration

```bash
npm run prisma:migrate
```

### Deploy migrations to production

```bash
npm run prisma:migrate:deploy
```

## 🔐 Security Features

- **JWT Authentication**: Stateless authentication
- **Two-Factor Authentication**: TOTP-based 2FA
- **Password Hashing**: bcrypt for secure password storage
- **Rate Limiting**: Throttling to prevent abuse
- **CORS Configuration**: Configurable cross-origin requests
- **Environment Variables**: Secure credential management

## 📡 API Endpoints

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/2fa/setup` - Setup 2FA
- `POST /auth/2fa/verify` - Verify 2FA code
- `POST /auth/refresh` - Refresh JWT token

### Wallets
- `GET /wallets` - List user wallets
- `POST /wallets` - Create new wallet
- `GET /wallets/:id` - Get wallet details
- `POST /wallets/:id/transactions` - Wallet transactions

### Trading
- `GET /trades` - List trades
- `POST /trades` - Create trade order
- `GET /trades/:id` - Get trade details
- `POST /trades/:id/cancel` - Cancel trade

### Admin
- `GET /admin/users` - List all users
- `GET /admin/analytics` - Platform analytics
- `POST /admin/compliance` - KYC management

## 🗂️ Project Structure

```
src/
├── auth/              # Authentication module
├── wallets/           # Wallet management
├── trading/           # Trading engine
├── compliance/        # KYC compliance
├── admin/             # Admin panel backend
├── common/            # Shared utilities
├── config/            # Configuration
└── main.ts            # Application entry point

prisma/
├── schema.prisma      # Database schema
└── migrations/        # Database migrations
```

## 🔄 CI/CD

The project includes GitHub Actions workflows for:
- Running tests on pull requests
- Building and deploying on merge to main

## 📝 Configuration Files

- `tsconfig.json` - TypeScript configuration
- `eslint.config.js` - ESLint rules (v9 flat config)
- `jest.config.js` - Jest testing configuration
- `.prettierrc` - Code formatting rules
- `prisma/schema.prisma` - Database schema

## 🐛 Troubleshooting

### Prisma Connection Issues
```bash
# Check database connection
DATABASE_URL="postgresql://user:password@host:5432/db" npm run prisma:generate
```

### ESLint Errors
```bash
# Clear cache and reinstall
npm run lint -- --reset-cache
```

### Port Already in Use
```bash
# Change APP_PORT in .env file
APP_PORT=3001
```

## 📚 Dependencies

- **@nestjs/common** v11.1.20 - NestJS framework
- **@prisma/client** v7.8.0 - ORM and database tools
- **typescript** v5.9.0 - TypeScript compiler
- **jest** v29.7.0 - Testing framework
- **eslint** v9.5.0 - Code linting
- **stripe** v15.0.0 - Payment processing

See `package.json` for complete dependency list.

## 📄 License

This project is private. All rights reserved.

## 👥 Contributors

- **mfhquzit** - Project owner

## 📞 Support

For issues and questions, please use GitHub Issues.

---

**Last Updated**: May 14, 2026
**Node.js**: >= 20.19.0
**npm**: >= 10.0.0
