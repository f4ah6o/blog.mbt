///|
pub const MCP_SERVER_INFO_META_KEY : String = "io.modelcontextprotocol/serverInfo"

///|
/// `server/discover` is cacheable and contains no per-user data in this
/// server, so the result can be reused across authorization contexts.
pub const MCP_DISCOVER_TTL_MS : Int = 3600000

///|
/// Build the MCP 2026-07-28 discovery response. The empty capabilities object
/// is intentional: the catalog is available through tools/list, but execution
/// is not implemented and must not be advertised as a callable capability.
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
    "instructions": "server/discover and tools/list are available; tools/call and database operations are not implemented.",
    "ttlMs": MCP_DISCOVER_TTL_MS,
    "cacheScope": "public",
  }
  ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "result": result } : Json).stringify()
}
