# MoonBit Blog System Commands

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
    moon check --deny-warn --target js
    pnpm exec vp check src/worker-entry.ts src/client/markable.ts src/types.d.ts vite.config.ts vite.markable.config.ts package.json tsconfig.json

# Run tests
test:
    moon test --target js
    node --test scripts/*.test.mjs

# Update snapshot tests
test-update:
    moon test --update --target js

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean

# Pre-release check
release-check:
    moon fmt
    moon info
    moon check --deny-warn --target js
    moon test --target js
    pnpm exec vp build -c vite.markable.config.ts
    pnpm exec vp check src/worker-entry.ts src/client/markable.ts src/types.d.ts vite.config.ts vite.markable.config.ts package.json tsconfig.json
    pnpm exec vp build

# Build for Cloudflare Workers
build: gen-config
    pnpm exec vp build -c vite.markable.config.ts
    moon build --release --target js
    pnpm exec vp build
    node scripts/patch_worker_global_init.mjs

# Initialize local D1 database
init-db:
    npx wrangler d1 execute blog-db --local --file=schema.sql

# Migrate local D1 database to content v0.4 schema
migrate-db:
    npx wrangler d1 execute blog-db --local --file=migrate_admin_v03.sql
    npx wrangler d1 execute blog-db --local --file=migrate_content_v04.sql

# Validate the private OKF bundle configured by BLOG_KNOWLEDGE_DIR
content-check:
    node scripts/okf_content.mjs validate

# Project the private OKF bundle configured by BLOG_KNOWLEDGE_DIR into local D1
content-sync:
    node scripts/okf_content.mjs sync

# Export current D1 articles to a new OKF bundle; pass --remote for production
content-export output_dir mode="--local":
    node scripts/export_posts.mjs --output-dir {{output_dir}} {{mode}}

# Run the full blog locally from an OKF bundle and sync changes on save
preview: build init-db
    node scripts/preview.mjs

# Seed local D1 database
seed-db:
    npx wrangler d1 execute blog-db --local --file=seed.sql

# Run local development server
dev: gen-config
    pnpm exec vp build -c vite.markable.config.ts
    moon build --release --target js
    pnpm exec vp dev

# Full sequence for local development
local: build init-db seed-db dev

item_title := "blog"

# Deploy to Cloudflare (production via 1Password)
deploy: build
    opz run {{item_title}} -- sh -c 'printf "%s" "$ADMIN_USER_ID" | npx wrangler secret put ADMIN_USER_ID --env production'
    opz run {{item_title}} -- sh -c 'printf "%s" "$JWT_SECRET" | npx wrangler secret put JWT_SECRET --env production'
    opz run {{item_title}} -- sh -c 'printf "%s" "$ADMIN_SETUP_TOKEN" | npx wrangler secret put ADMIN_SETUP_TOKEN --env production'
    opz run {{item_title}} -- npx wrangler deploy --env production

# Deploy to Cloudflare without secrets (uses local env)
deploy-local: build
    npx wrangler deploy

# Initialize remote D1 database (production)
deploy-db:
    npx wrangler d1 execute blog-db --remote --file=schema.sql

# Migrate remote D1 database to content v0.4 schema
deploy-migrate-db:
    npx wrangler d1 execute blog-db --remote --file=migrate_admin_v03.sql
    npx wrangler d1 execute blog-db --remote --file=migrate_content_v04.sql
