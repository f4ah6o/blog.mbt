# MoonBit Blog System Commands

# Default target (js for Cloudflare Workers)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

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
build:
    moon build --target {{target}}

# Initialize local D1 database
init-db:
    npx wrangler d1 execute blog-db --local --file=schema.sql

# Run local development server
dev: build
    npx wrangler dev fixtures/worker.js

# Full sequence for local development
local: build init-db dev

# Deploy to Cloudflare
deploy: build
    npx wrangler deploy fixtures/worker.js
