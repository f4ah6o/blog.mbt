# OAuth and MCP implementation plan

## Current architecture findings

- The root module is `f4ah6o/blog.mbt`, JavaScript-targeted, with the worker package exporting `get_fetch_handler` to `src/worker-entry.ts`.
- `get_fetch_handler` sends `/admin...` requests to `admin.handle_admin_request` before public routing. Existing admin behavior must remain isolated from OAuth.
- Admin WebAuthn credentials and one-time challenges are stored in the `ADMIN_AUTH` KV binding. The admin session is a JWT in an HttpOnly `/admin` cookie, signed through WebCrypto FFI. This identity/session is not the OAuth resource-owner identity.
- Public posts and future OAuth/MCP state belong to the `BLOG_DB` D1 binding. OAuth v0.1 adds durable code/token tables to this same database; CIMD client validation/cache is explicitly deferred and there is no `oauth_clients` table yet.
- `SITE_URL` is generated configuration and currently equals `https://blog.f12o.com`. It is the canonical issuer/resource origin until an explicit deployment configuration is introduced.
- TypeScript in `src/worker-entry.ts` is only the Vite/Cloudflare entry glue. MoonBit owns request routing and protocol behavior.
- The repository declares MoonBit dependencies in `moon.mod`; no project-level `moon.lock` is present. Build artifacts contain the resolved cache and must not be edited as source.

## OAuth storage slice

- `oauth_authorization_codes` stores only a unique `code_hash`, exact `client_id`, `redirect_uri`, `resource`, and validated `scope`, plus integer epoch `created_at`, `expires_at`, and nullable `consumed_at`. Redemption is a conditional update requiring every binding value, `expires_at > now`, and `consumed_at IS NULL`; success is determined from D1's changed-row count.
- `oauth_access_tokens` stores only a unique `token_hash`, `client_id`, `resource`, validated `scope`, integer epoch creation/expiry, and nullable `revoked_at`. Resource-server lookup requires the opaque token hash plus exact resource, an unexpired row, no revocation, and MoonBit scope containment; the stored `client_id` is returned as token metadata rather than required from the protected-resource request. Expiry/revocation and hash lookup indexes support cleanup and validation.
- `oauth_refresh_tokens` stores only a unique `token_hash`, a `family_hash`, exact client/resource/scope, integer epoch creation/expiry, nullable `consumed_at`/`revoked_at`, and a unique nullable `replacement_token_hash`. Rotation batches the conditional old-token claim with an insert guarded by that claim. A later consumed row is returned as a distinct replay result so the caller can revoke its family.
- No plaintext code or token column exists. All repository SQL uses bound parameters. `oauth_clients` is deferred because no storage API needs it before CIMD client validation/cache is implemented.

## First implementation slice

1. Add a small MoonBit `oauth` package for the four supported scopes, space-delimited scope validation, safe canonical URL construction, OAuth metadata models, and PKCE verifier/challenge validation.
2. Use WebCrypto FFI only for CSPRNG bytes and SHA-256 digest capability. Opaque secrets are 32 random bytes encoded as unpadded base64url; persistence uses lowercase SHA-256 hex. Secret syntax, bearer parsing, expiry, scope checks, and single-use/rotation decisions remain MoonBit code.
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

The current full worker/project check remains blocked before this OAuth slice by `f4ah6o/simple-webauthn@0.1.0 -> mizchi/cbor@0.1.1`, whose cached source uses the obsolete MoonBit `suberror CborError String` form. No `.mooncakes` repair is included here.
