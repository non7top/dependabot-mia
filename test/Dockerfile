# ============================================
# Stage 1: Install all dependencies (for building)
# ============================================
FROM node:20-alpine AS deps

WORKDIR /app

COPY package.json ./
COPY package-lock.json* ./

RUN npm install --ignore-scripts

# ============================================
# Stage 2: Install production-only dependencies
# ============================================
FROM node:20-alpine AS prod-deps

WORKDIR /app

COPY package.json ./
COPY package-lock.json* ./

RUN npm install --omit=dev --ignore-scripts

# ============================================
# Stage 3: Build the application
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build:frontend && npm run build:backend

RUN test -d dist/frontend && test -d dist/backend

# ============================================
# Stage 4: Production server
# ============================================
FROM node:20-alpine AS production

LABEL org.opencontainers.image.source="https://github.com/example-org/sample-project"
LABEL org.opencontainers.image.description="Sample Web Application"
LABEL org.opencontainers.image.licenses="MIT"

RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy production dependencies only
COPY --from=prod-deps /app/node_modules ./node_modules

# Copy built artifacts
COPY --from=builder /app/dist ./dist

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/api/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

ENV NODE_ENV=production
ENV PORT=3001

CMD ["node", "dist/backend/index.js"]
