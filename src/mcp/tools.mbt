///|
pub const MCP_TOOLS_TTL_MS : Int = 3600000

///|
fn tools_list_params_error(params : Json?) -> JsonRpcError? {
  match params {
    Some(Object(obj)) =>
      match obj.get("cursor") {
        Some(_) =>
          Some(
            JsonRpcError::new(
              JSON_RPC_INVALID_PARAMS,
              "Invalid params: tools/list pagination cursor is not supported",
            ),
          )
        None => None
      }
    _ =>
      Some(
        JsonRpcError::new(
          JSON_RPC_INVALID_PARAMS,
          "Invalid params: tools/list params must be an object",
        ),
      )
  }
}

///|
fn post_schema(properties : Json, required : Json) -> Json {
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": properties,
    "required": required,
    "additionalProperties": false,
  }
}

///|
fn tools_catalog() -> Json {
  let catalog : Json = [
    {
      "name": "list_posts",
      "title": "List posts",
      "description": "List blog posts using limit and offset.",
      "inputSchema": post_schema(
        {
          "limit": { "type": "integer", "minimum": 1, "maximum": 100 },
          "offset": { "type": "integer", "minimum": 0 },
        },
        [],
      ),
    },
    {
      "name": "get_post",
      "title": "Get a post",
      "description": "Get one blog post by its integer id.",
      "inputSchema": post_schema(
        { "id": { "type": "integer", "minimum": 1 } },
        ["id"],
      ),
    },
    {
      "name": "create_post",
      "title": "Create a post",
      "description": "Create a draft blog post.",
      "inputSchema": post_schema(
        {
          "title": { "type": "string" },
          "slug": { "type": "string" },
          "excerpt": { "type": "string" },
          "content": { "type": "string" },
          "slide_flag": { "type": "boolean" },
        },
        ["title", "slug", "content"],
      ),
    },
    {
      "name": "update_post",
      "title": "Update a post",
      "description": "Replace the editable fields of a post by integer id.",
      "inputSchema": post_schema(
        {
          "id": { "type": "integer", "minimum": 1 },
          "title": { "type": "string" },
          "slug": { "type": "string" },
          "excerpt": { "type": "string" },
          "content": { "type": "string" },
          "slide_flag": { "type": "boolean" },
        },
        ["id", "title", "slug", "excerpt", "content", "slide_flag"],
      ),
    },
    {
      "name": "publish_post",
      "title": "Publish a post",
      "description": "Publish a post by integer id.",
      "inputSchema": post_schema(
        { "id": { "type": "integer", "minimum": 1 } },
        ["id"],
      ),
    },
  ]
  catalog
}

///|
pub fn tools_list_response(
  id : Json,
  params : Json?,
  server_name : String,
  server_version : String,
) -> Result[String, JsonRpcError] {
  match tools_list_params_error(params) {
    Some(error) => Err(error)
    None => {
      let result : Json = {
        "resultType": "complete",
        "tools": tools_catalog(),
        "_meta": {
          "io.modelcontextprotocol/serverInfo": {
            "name": server_name,
            "version": server_version,
          },
        },
        "ttlMs": MCP_TOOLS_TTL_MS,
        "cacheScope": "public",
      }
      Ok(
        ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "result": result } : Json).stringify(),
      )
    }
  }
}
