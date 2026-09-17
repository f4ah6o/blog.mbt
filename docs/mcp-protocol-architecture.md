# MCP 2026-07-28 protocol primitives

This package (`f4ah6o/blog.mbt/mcp`) holds pure MoonBit primitives for the
stateless MCP 2026-07-28 revision. Cloudflare request/response construction and
database access remain in the thin Worker bridge; protocol parsing, validation,
dispatch, and response shaping stay in MoonBit. TypeScript protocol logic is
not involved; the existing `src/worker-entry.ts` glue is unchanged.

## Layout

- `jsonrpc.mbt` - JSON-RPC 2.0 constants, error object, request envelope
  parsing, and error-response shaping.
- `headers.mbt` - Streamable HTTP standard header names, a case-insensitive
  header list, and the `Mcp-Method` / `Mcp-Name` / `MCP-Protocol-Version`
  validators.
- `request.mbt` - the `McpRequest` envelope that binds a parsed JSON-RPC
  request to the required per-request `_meta`, plus the combined validation
  pipeline.
- `discover.mbt` - the minimal current `server/discover` result.
- `transport.mbt` - stateless request dispatch and HTTP status/body contract.

## Invariants

- **Stateless only.** The package models the 2026-07-28 revision. There is no
  `initialize` handshake, no `Mcp-Session-Id`, and no legacy SSE-first or
  stateful-session fallback.
- **Fail-closed parsing.** Malformed JSON maps to `-32700`; non-object bodies,
  wrong `jsonrpc`, missing `method`, bad `id`/`params` types, and response-shaped
  bodies (`result`/`error`) all map to `-32600`. Unknown top-level fields are
  ignored.
- **Request id preserved.** The id is retained as raw `Json`, so a string id
  stays a string and a number id stays a number when a response echoes it.
  Missing id means a notification and echoes `null`.
- **Protocol version in the body.** `params._meta` must carry
  `io.modelcontextprotocol/protocolVersion = "2026-07-28"`. Missing, malformed,
  metadata is `-32600`; a syntactically valid but unsupported version is the
  current `-32022 UnsupportedProtocolVersionError` and lists the supported
  version. Optional `io.modelcontextprotocol/clientInfo` and
  `io.modelcontextprotocol/clientCapabilities` are accepted only if they are
  objects.
- **Self-reported identity is not authority.** `clientInfo` and
  `clientCapabilities`
  are exposed for observability and MUST NOT be used for authentication or
  authorization. No code in this package treats them as trusted.
- **Header/body agreement.** `MCP-Protocol-Version` and `Mcp-Method` are
  required on every request. `Mcp-Name` is required only for `tools/call` and
  `prompts/get` (`params.name`) and `resources/read` (`params.uri`). Header
  names are case-insensitive and values are compared byte-for-byte after
  whitespace trimming. Sending `Mcp-Name` for a method that has no name source
  fails closed instead of being silently ignored.
- **One mismatch code.** Every header failure (`MissingHeader`,
  `HeaderValueMismatch`, `MissingBodyValue`, `UnexpectedHeader`) converts to
  JSON-RPC `-32020` `HeaderMismatch` via
  `McpHeaderError::to_json_rpc_error`.

## Not in this slice

Blog tools, the `tools/list` catalog, tool calls, database mutations, legacy
`initialize`/session compatibility, long-lived subscription streams, and
SSE response streaming are deliberately out of scope and arrive in later
slices.

## 2026-07-28 stateless HTTP discovery

The first HTTP slice exposes only `POST /mcp` and `server/discover`. It stays
stateless: there is no `initialize` / `initialized` exchange and no
`Mcp-Session-Id`. Each request carries the protocol version and self-reported
client metadata in `params._meta`, and the mirrored HTTP headers are validated
against the body before dispatch.

`server/discover` requires the repo-local `mcp:discover` OAuth scope. MCP does
not define a standard scope name for discovery; keeping it distinct from
`blog:read` preserves least privilege because discovery returns protocol/server
metadata rather than article content. Future tool methods can add their own
operation scopes without making discovery imply content access.

The discovery result advertises only what is implemented: protocol version
`2026-07-28`, an empty capabilities object, server identity in
`result._meta["io.modelcontextprotocol/serverInfo"]`, and cache hints. Tool
capabilities are not advertised until `tools/list` and execution exist.

## HTTP response contract

`/mcp` accepts only `POST` with `Content-Type: application/json`. The client
must send an `Accept` value covering both `application/json` and
`text/event-stream`, as required by the modern Streamable HTTP transport. This
slice returns JSON responses only; accepting `text/event-stream` does not add a
legacy SSE endpoint or protocol session. Request bodies are capped at 1 MiB of
UTF-8 data before protocol parsing.

Authentication happens at the HTTP protected-resource boundary before MCP
dispatch. Missing or invalid bearer credentials return HTTP 401 and a
RFC 6750 / RFC 9728 `WWW-Authenticate` challenge; insufficient scope returns
HTTP 403 with `error="insufficient_scope"`. These are OAuth/HTTP failures, not
JSON-RPC errors, and no bearer value or Authorization header is logged.

After authentication, malformed JSON / invalid JSON-RPC / unsupported protocol
version / header-body validation failures return HTTP 400 with a JSON-RPC error
body. `HeaderMismatch` remains `-32020`. An implemented protocol request for an
unknown RPC returns HTTP 404 with JSON-RPC `-32601 Method not found`.
`server/discover` returns HTTP 200 with `application/json`. Client-to-server
notifications are not part of the 2026-07-28 core Streamable HTTP surface, so
this slice rejects them with HTTP 400 rather than silently accepting them.

HTTP-shape failures are kept outside JSON-RPC: non-POST is 405, unsupported
content type is 415, an invalid modern `Accept` contract is 406, and an
oversized body is 413. No `Mcp-Session-Id`, GET stream endpoint, or legacy
`initialize` fallback is introduced.
