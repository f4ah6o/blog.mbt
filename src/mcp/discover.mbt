///|
pub const MCP_SERVER_INFO_META_KEY : String = "io.modelcontextprotocol/serverInfo"

///|
/// `server/discover` is cacheable and contains no per-user data in this
/// server, so the result can be reused across authorization contexts.
pub const MCP_DISCOVER_TTL_MS : Int = 3600000

///|
/// Build the minimal MCP 2026-07-28 discovery response for the surface that is
/// actually implemented today. An empty capabilities object is intentional:
/// tool listing/execution is not advertised until that later slice exists.
pub fn server_discover_response(
  id : Json,
  server_name : String,
  server_version : String,
) -> String {
  let result : Json = {
    "resultType": "complete",
    "supportedVersions": [MCP_PROTOCOL_VERSION],
    "capabilities": ({} : Json),
    "_meta": {
      "io.modelcontextprotocol/serverInfo": {
        "name": server_name,
        "version": server_version,
      },
    },
    "instructions": "Only server/discover is currently available; tool discovery and execution are not yet exposed.",
    "ttlMs": MCP_DISCOVER_TTL_MS,
    "cacheScope": "public",
  }
  ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "result": result } : Json).stringify()
}
