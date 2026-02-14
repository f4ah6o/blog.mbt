# MoonBit Blog System Commands

# Default target (js for Cloudflare Workers)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Generate config bindings from TOML
gen-config:
    node scripts/gen_config.mjs

# Type check
check:
    moon check --deny-warn --target {{target}}

# Run tests
test:
    moon test --target {{target}}

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean

# Pre-release check
release-check: fmt info check test

# Build for Cloudflare Workers
build: gen-config
    moon build --target {{target}}

# Initialize local D1 database
init-db:
    npx wrangler d1 execute blog-db --local --file=schema.sql

# Migrate local D1 database to admin v0.3 schema
migrate-db:
    npx wrangler d1 execute blog-db --local --file=migrate_admin_v03.sql

# Seed local D1 database
seed-db:
    npx wrangler d1 execute blog-db --local --file=seed.sql

# Run local development server
dev: build
    npx wrangler dev fixtures/worker.js

# Full sequence for local development
local: build init-db seed-db dev

item_title := "blog"

# Deploy to Cloudflare (production via 1Password)
deploy: build
    opz run {{item_title}} -- sh -c 'printf "%s" "$ADMIN_USER_ID" | npx wrangler secret put ADMIN_USER_ID --env production'
    opz run {{item_title}} -- sh -c 'printf "%s" "$JWT_SECRET" | npx wrangler secret put JWT_SECRET --env production'
    opz run {{item_title}} -- sh -c 'printf "%s" "$ADMIN_SETUP_TOKEN" | npx wrangler secret put ADMIN_SETUP_TOKEN --env production'
    opz run {{item_title}} -- npx wrangler deploy fixtures/worker.js --env production

# Deploy to Cloudflare without secrets (uses local env)
deploy-local: build
    npx wrangler deploy fixtures/worker.js

# Initialize remote D1 database (production)
deploy-db:
    npx wrangler d1 execute blog-db --remote --file=schema.sql

# Migrate remote D1 database to admin v0.3 schema
deploy-migrate-db:
    npx wrangler d1 execute blog-db --remote --file=migrate_admin_v03.sql
