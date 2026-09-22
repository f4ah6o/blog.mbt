///|
/// A validated `tools/call` for one catalog tool. Argument parsing and schema
/// validation are completed here in pure MoonBit; the Cloudflare Worker bridge
/// turns each variant into exactly one D1 operation under the tool's scope.
/// There is no delete operation.
pub(all) enum McpToolCall {
  ListPosts(limit~ : Int, offset~ : Int)
  GetPost(id~ : Int)
  CreatePost(
    title~ : String,
    slug~ : String,
    excerpt~ : String,
    content~ : String,
    slide_flag~ : Bool
  )
  UpdatePost(
    id~ : Int,
    title~ : String,
    slug~ : String,
    excerpt~ : String,
    content~ : String,
    slide_flag~ : Bool
  )
  PublishPost(id~ : Int)
}

///|
pub fn McpToolCall::tool_name(self : McpToolCall) -> String {
  match self {
    ListPosts(..) => "list_posts"
    GetPost(..) => "get_post"
    CreatePost(..) => "create_post"
    UpdatePost(..) => "update_post"
    PublishPost(..) => "publish_post"
  }
}

///|
/// The catalog tool names in the same stable order as `tools/list`.
pub fn mcp_tool_names() -> Array[String] {
  ["list_posts", "get_post", "create_post", "update_post", "publish_post"]
}

///|
fn invalid_call_params(message : String) -> JsonRpcError {
  JsonRpcError::new(JSON_RPC_INVALID_PARAMS, "Invalid params: " + message)
}

///|
/// Every argument key must be declared by the tool's schema
/// (`additionalProperties: false`).
fn reject_unknown_arguments(
  arguments : Map[String, Json],
  allowed : Array[String],
) -> JsonRpcError? {
  for key in arguments.keys() {
    if !allowed.contains(key) {
      return Some(invalid_call_params("unknown argument " + key))
    }
  }
  None
}

///|
fn arg_integer(
  arguments : Map[String, Json],
  key : String,
  required~ : Bool,
) -> Result[Int?, JsonRpcError] {
  match arguments.get(key) {
    None =>
      if required {
        Err(invalid_call_params(key + " is required"))
      } else {
        Ok(None)
      }
    Some(Number(value, ..)) => {
      let int_value = value.to_int()
      if int_value.to_double() == value {
        Ok(Some(int_value))
      } else {
        Err(invalid_call_params(key + " must be an integer"))
      }
    }
    Some(_) => Err(invalid_call_params(key + " must be an integer"))
  }
}

///|
fn arg_string(
  arguments : Map[String, Json],
  key : String,
  required~ : Bool,
) -> Result[String?, JsonRpcError] {
  match arguments.get(key) {
    None =>
      if required {
        Err(invalid_call_params(key + " is required"))
      } else {
        Ok(None)
      }
    Some(String(value)) => Ok(Some(value))
    Some(_) => Err(invalid_call_params(key + " must be a string"))
  }
}

///|
fn arg_boolean(
  arguments : Map[String, Json],
  key : String,
  required~ : Bool,
) -> Result[Bool?, JsonRpcError] {
  match arguments.get(key) {
    None =>
      if required {
        Err(invalid_call_params(key + " is required"))
      } else {
        Ok(None)
      }
    Some(True) => Ok(Some(true))
    Some(False) => Ok(Some(false))
    Some(_) => Err(invalid_call_params(key + " must be a boolean"))
  }
}

///|
fn ranged_id(
  arguments : Map[String, Json],
  key : String,
) -> Result[Int, JsonRpcError] {
  match arg_integer(arguments, key, required=true) {
    Err(error) => Err(error)
    Ok(value) =>
      match value {
        Some(id) if id >= 1 => Ok(id)
        _ => Err(invalid_call_params(key + " must be at least 1"))
      }
  }
}

///|
fn list_posts_call(
  arguments : Map[String, Json],
) -> Result[McpToolCall, JsonRpcError] {
  match reject_unknown_arguments(arguments, ["limit", "offset"]) {
    Some(error) => return Err(error)
    None => ()
  }
  let limit = match arg_integer(arguments, "limit", required=false) {
    Err(error) => return Err(error)
    Ok(value) =>
      match value {
        Some(limit) if limit >= 1 && limit <= 100 => limit
        Some(_) =>
          return Err(invalid_call_params("limit must be between 1 and 100"))
        None => 20
      }
  }
  let offset = match arg_integer(arguments, "offset", required=false) {
    Err(error) => return Err(error)
    Ok(value) =>
      match value {
        Some(offset) if offset >= 0 => offset
        Some(_) => return Err(invalid_call_params("offset must be at least 0"))
        None => 0
      }
  }
  Ok(ListPosts(limit~, offset~))
}

///|
fn get_post_call(
  arguments : Map[String, Json],
) -> Result[McpToolCall, JsonRpcError] {
  match reject_unknown_arguments(arguments, ["id"]) {
    Some(error) => return Err(error)
    None => ()
  }
  match ranged_id(arguments, "id") {
    Err(error) => Err(error)
    Ok(id) => Ok(GetPost(id~))
  }
}

///|
fn create_post_call(
  arguments : Map[String, Json],
) -> Result[McpToolCall, JsonRpcError] {
  match
    reject_unknown_arguments(arguments, [
      "title", "slug", "excerpt", "content", "slide_flag",
    ]) {
    Some(error) => return Err(error)
    None => ()
  }
  let title = match arg_string(arguments, "title", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let slug = match arg_string(arguments, "slug", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let content = match arg_string(arguments, "content", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let excerpt = match arg_string(arguments, "excerpt", required=false) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap_or("")
  }
  let slide_flag = match arg_boolean(arguments, "slide_flag", required=false) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap_or(false)
  }
  Ok(CreatePost(title~, slug~, excerpt~, content~, slide_flag~))
}

///|
fn update_post_call(
  arguments : Map[String, Json],
) -> Result[McpToolCall, JsonRpcError] {
  match
    reject_unknown_arguments(arguments, [
      "id", "title", "slug", "excerpt", "content", "slide_flag",
    ]) {
    Some(error) => return Err(error)
    None => ()
  }
  let id = match ranged_id(arguments, "id") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let title = match arg_string(arguments, "title", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let slug = match arg_string(arguments, "slug", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let excerpt = match arg_string(arguments, "excerpt", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let content = match arg_string(arguments, "content", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  let slide_flag = match arg_boolean(arguments, "slide_flag", required=true) {
    Err(error) => return Err(error)
    Ok(value) => value.unwrap()
  }
  Ok(UpdatePost(id~, title~, slug~, excerpt~, content~, slide_flag~))
}

///|
fn publish_post_call(
  arguments : Map[String, Json],
) -> Result[McpToolCall, JsonRpcError] {
  match reject_unknown_arguments(arguments, ["id"]) {
    Some(error) => return Err(error)
    None => ()
  }
  match ranged_id(arguments, "id") {
    Err(error) => Err(error)
    Ok(id) => Ok(PublishPost(id~))
  }
}

///|
/// Parse and validate one `tools/call` request body. `params.name` and
/// `params.arguments` must satisfy the catalog schema for the named tool;
/// anything else is `-32602`. The `Mcp-Name` header equality is already
/// enforced upstream by `McpRequest::validate_headers`.
pub fn McpRequest::tools_call_plan(
  self : McpRequest,
) -> Result[McpToolCall, JsonRpcError] {
  let params = match self.params() {
    Some(Object(obj)) => obj
    _ => return Err(invalid_call_params("params must be an object"))
  }
  let name = match params.get("name") {
    Some(String(value)) => value
    Some(_) => return Err(invalid_call_params("name must be a string"))
    None => return Err(invalid_call_params("name is required"))
  }
  let arguments = match params.get("arguments") {
    None => Map::Map([])
    Some(Object(obj)) => obj
    Some(_) => return Err(invalid_call_params("arguments must be an object"))
  }
  match name {
    "list_posts" => list_posts_call(arguments)
    "get_post" => get_post_call(arguments)
    "create_post" => create_post_call(arguments)
    "update_post" => update_post_call(arguments)
    "publish_post" => publish_post_call(arguments)
    _ => Err(invalid_call_params("unknown tool " + name))
  }
}

///|
/// The JSON shape of one post inside a tool result. `published_at` is `null`
/// until the post is first published.
pub fn mcp_post_json(
  id : Int,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  slide_flag : Bool,
  status : String,
  published_at : String?,
  updated_at : String,
) -> Json {
  let published : Json = match published_at {
    Some(value) => value.to_json()
    None => null
  }
  (
    {
      "id": id,
      "title": title,
      "slug": slug,
      "excerpt": excerpt,
      "content": content,
      "slide_flag": slide_flag,
      "status": status,
      "published_at": published,
      "updated_at": updated_at,
    } : Json)
}

///|
/// Wrap a structured tool result in the JSON-RPC success envelope. The text
/// content mirrors `structuredContent` for clients that read only content
/// blocks.
pub fn tools_call_result(id : Json, structured : Json) -> String {
  let result : Json = {
    "content": [{ "type": "text", "text": structured.stringify() }],
    "structuredContent": structured,
  }
  ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "result": result } : Json).stringify()
}

///|
/// A `tools/call` execution failure is a successful JSON-RPC response whose
/// result carries `isError: true`, per the CallToolResult contract.
pub fn tools_call_error(id : Json, message : String) -> String {
  let result : Json = {
    "content": [{ "type": "text", "text": message }],
    "isError": true,
  }
  ({ "jsonrpc": JSON_RPC_VERSION, "id": id, "result": result } : Json).stringify()
}
