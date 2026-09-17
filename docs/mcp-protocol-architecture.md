# MCP 2026-07-28 protocol primitives

This package (`f4ah6o/blog.mbt/mcp`) holds pure MoonBit primitives for the
stateless MCP 2026-07-28 revision. It is intentionally transport-agnostic and
has no Cloudflare, database, or route dependencies yet. TypeScript is not
involved; the existing `src/worker-entry.ts` glue is unchanged.

## Layout

- `jsonrpc.mbt` - JSON-RPC 2.0 constants, error object, request envelope
  parsing, and error-response shaping.
- `headers.mbt` - Streamable HTTP standard header names, a case-insensitive
  header list, and the `Mcp-Method` / `Mcp-Name` / `MCP-Protocol-Version`
  validators.
- `request.mbt` - the `McpRequest` envelope that binds a parsed JSON-RPC
  request to the required per-request `_meta`, plus the combined validation
  pipeline.

## Invariants

- **Stateless only.** The package models the 2026-07-28 revision. There is no
  `initialize` handshake, no `Mcp-Session-Id`, no SSE, and no `server/discover`
  implementation here.
- **Fail-closed parsing.** Malformed JSON maps to `-32700`; non-object bodies,
  wrong `jsonrpc`, missing `method`, bad `id`/`params` types, and response-shaped
  bodies (`result`/`error`) all map to `-32600`. Unknown top-level fields are
  ignored.
- **Request id preserved.** The id is retained as raw `Json`, so a string id
  stays a string and a number id stays a number when a response echoes it.
  Missing id means a notification and echoes `null`.
- **Protocol version in the body.** `params._meta` must carry
  `io.modelcontextprotocol/protocolVersion = "2026-07-28"`. Missing, malformed,
  or unsupported metadata is `-32600`. Optional
  `io.modelcontextprotocol/clientInfo` and `io.modelcontextprotocol/capabilities`
  are accepted only if they are objects.
- **Self-reported identity is not authority.** `clientInfo` and `capabilities`
  are exposed for observability and MUST NOT be used for authentication or
  authorization. No code in this package treats them as trusted.
- **Header/body agreement.** `MCP-Protocol-Version` and `Mcp-Method` are
  required on every request. `Mcp-Name` is required only for `tools/call` and
  `prompts/get` (`params.name`) and `resources/read` (`params.uri`). Header
  names are case-insensitive and values are compared byte-for-byte after
  whitespace trimming.
- **One mismatch code.** Every header failure (`MissingHeader`,
  `HeaderValueMismatch`, `MissingBodyValue`) converts to JSON-RPC `-32020`
  `HeaderMismatch` via `McpHeaderError::to_json_rpc_error`.

## Not in this slice

Blog tools, the `tools/list` catalog, tool calls, database mutations,
`server/discover`, legacy `initialize`/session compatibility, SSE, and route
wiring are deliberately out of scope and arrive in later slices.
