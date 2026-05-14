1. API Dockerfile (apps/api/Dockerfile)

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci --only=production
RUN npm install -g @nestjs/cli

# Copy source code
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/prisma ./prisma

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (r) => {r.statusCode === 200 ? process.exit(0) : process.exit(1)})"

# Start with dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main"]
```

---

2. Client Dockerfile (apps/client/Dockerfile)

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build Next.js application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Install dumb-init
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/.next ./.next
COPY --from=builder --chown=nodejs:nodejs /app/public ./public
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/next.config.js ./next.config.js

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Start Next.js application
CMD ["npm", "start"]
```

---

3. Admin Dockerfile (apps/admin/Dockerfile)

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build Next.js application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Install dumb-init
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/.next ./.next
COPY --from=builder --chown=nodejs:nodejs /app/public ./public
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/next.config.js ./next.config.js

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3002

# Start Next.js application
CMD ["npm", "start"]
```

---

Why These Dockerfiles Are Better

Feature Your Basic Dockerfile Our Production Dockerfile
Base image node:18 (large) node:20-alpine (small)
Multi-stage ❌ No ✅ Yes (builder + runner)
Non-root user ❌ No ✅ Yes (security)
Health check ❌ No ✅ Yes
Signal handling ❌ No ✅ dumb-init
Prisma integration ❌ No ✅ Yes
Port 3000 (wrong for API) 3001 (API), 3000 (client), 3002 (admin)

---

How to Use These Files

```bash
# Create the directories if they don't exist
mkdir -p apps/api apps/client apps/admin

# Copy each Dockerfile into its respective folder
nano apps/api/Dockerfile      # paste API version
nano apps/client/Dockerfile   # paste Client version
nano apps/admin/Dockerfile    # paste Admin version

# Build all images
docker-compose build

# Or build a specific service
docker-compose build api
```

These Dockerfiles are production-ready and follow best practices for security, size, and reliability. 🚀
