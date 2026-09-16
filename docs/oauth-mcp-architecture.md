# OAuth and MCP implementation plan

## Current architecture findings

- The root module is `f4ah6o/blog.mbt`, JavaScript-targeted, with the worker package exporting `get_fetch_handler` to `src/worker-entry.ts`.
- `get_fetch_handler` sends `/admin...` requests to `admin.handle_admin_request` before public routing. Existing admin behavior must remain isolated from OAuth.
- Admin WebAuthn credentials and one-time challenges are stored in the `ADMIN_AUTH` KV binding. The admin session is a JWT in an HttpOnly `/admin` cookie, signed through WebCrypto FFI. This identity/session is not the OAuth resource-owner identity.
- Public posts and future OAuth/MCP state belong to the `BLOG_DB` D1 binding. The current schema only contains `posts`; there are no OAuth tables or migrations yet.
- `SITE_URL` is generated configuration and currently equals `https://blog.f12o.com`. It is the canonical issuer/resource origin until an explicit deployment configuration is introduced.
- TypeScript in `src/worker-entry.ts` is only the Vite/Cloudflare entry glue. MoonBit owns request routing and protocol behavior.
- The repository declares MoonBit dependencies in `moon.mod`; no project-level `moon.lock` is present. Build artifacts contain the resolved cache and must not be edited as source.

## First implementation slice

1. Add a small MoonBit `oauth` package for the four supported scopes, space-delimited scope validation, safe canonical URL construction, OAuth metadata models, and PKCE verifier/challenge validation.
2. Use one WebCrypto FFI function for SHA-256 plus base64url encoding. PKCE syntax and comparison policy remain MoonBit code.
3. Route GET `/.well-known/oauth-protected-resource` and GET `/.well-known/oauth-authorization-server` before the D1 availability check. The metadata uses the configured canonical origin, exact issuer/resource values, PKCE S256, and CIMD support. It does not advertise DCR in this slice.
4. Keep token issuance, authorization UI/WebAuthn linkage, D1 token tables, MCP tools, and deployment wiring for later slices.

## MCP 2026-07-28 implications

The current MCP revision is stateless at protocol level: do not build an SSE-first or handshake/session-required server. The future Streamable HTTP endpoint must require the per-request protocol metadata (`MCP-Protocol-Version`, `Mcp-Method`, and `Mcp-Name` for `tools/call`) and must not assume `initialize` or `Mcp-Session-Id`. Authorization must publish RFC 9728 protected-resource metadata, use RFC 8414 authorization-server metadata, validate the RFC 9207 issuer, bind authorization with resource indicators, and require PKCE S256.

CIMD is the preferred client-registration path. DCR is deprecated and should be added only as a narrowly scoped compatibility fallback if a real client requires it, with strict redirect URI and client metadata validation. No DCR endpoint is implemented here.

## Security and ownership decisions

- Future access and refresh tokens will be opaque, high-entropy random values. Only a hash of each token will be stored in D1; plaintext tokens are returned once and never persisted.
- D1 owns OAuth clients, grants, authorization codes, token hashes, scopes, expiry, revocation, and audit timestamps. KV remains appropriate for short-lived admin/WebAuthn challenges, not durable OAuth ownership.
- WebAuthn authentication under `src/admin` proves the separately configured blog administrator identity. A future OAuth authorization step may reuse a verified admin session, but must not conflate the admin JWT/cookie or credential records with OAuth client/user/token records.
- Issuer and protected-resource URLs must be stable and exact. The configured HTTPS `SITE_URL` is preferred over untrusted `Host` headers; request-derived origins can be added only with an explicit trusted-origin policy.

## Practical follow-up slices

- Add D1 OAuth schema and migrations, including hashed opaque tokens and one-time authorization codes.
- Add authorization endpoint and a WebAuthn-backed consent flow without changing `/admin` routes.
- Add CIMD client metadata fetch and validation; add opt-in DCR compatibility only when required.
- Add token endpoint with resource/audience binding, PKCE verification, rotation/revocation, and no token logging.
- Add stateless Streamable HTTP MCP routing and read-only blog tools first, then separately authorized write/publish tools.
- Add Cloudflare bindings/configuration, integration tests, and deployment checks after local protocol tests pass.

## Baseline dependency note

The reported baseline failure is in cached `mizchi/cbor` syntax under the current MoonBit release. This work does not modify `.mooncakes`. Dependency repair should be a separate, obvious change to `moon.mod` and its generated resolution only after a compatible published dependency is confirmed; otherwise the upstream package must be updated. OAuth changes should remain reviewable independently of that repair.
