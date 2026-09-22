///|
pub const MCP_SERVER_INFO_META_KEY : String = "io.modelcontextprotocol/serverInfo"

///|
/// `server/discover` is cacheable and contains no per-user data in this
/// server, so the result can be reused across authorization contexts.
pub const MCP_DISCOVER_TTL_MS : Int = 3600000

///|
/// Build the MCP 2026-07-28 discovery response. The `tools` capability is
/// advertised with a static `listChanged: false` because the catalog is
/// deterministic and never changes at runtime.
pub fn server_discover_response(
  id : Json,
  server_name : String,
  server_version : String,
) -> String {
  let result : Json = {
    "resultType": "complete",
    "supportedVersions": [MCP_PROTOCOL_VERSION],
    "capabilities": { "tools": { "listChanged": false } },
    "_meta": {
      "io.modelcontextprotocol/serverInfo": {
        "name": server_name,
        "version": server_version,
      },
    },
    "instructions": "server/discover, tools/list, and tools/call are available. tools/call additionally requires the per-tool OAuth scope.",
    "ttlMs": MCP_DISCOVER_TTL_MS,
    "cacheScope": "public",
  }
  ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "result": result } : Json).stringify()
}
