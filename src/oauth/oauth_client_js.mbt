///|
/// Narrow outbound fetch capability for CIMD. It performs a single anonymous
/// HTTPS GET with redirects disabled, a five second timeout, a 64 KiB size cap,
/// and a JSON content-type check. All parsing and validation stays in MoonBit.
extern "js" fn fetch_client_metadata_raw(
  url : String,
) -> @core.Promise[String?] =
  #| async (url) => {
  #|   try {
  #|     const controller = new AbortController();
  #|     const timer = setTimeout(() => controller.abort(), 5000);
  #|     const response = await fetch(url, {
  #|       method: "GET",
  #|       headers: { "Accept": "application/json" },
  #|       redirect: "error",
  #|       credentials: "omit",
  #|       signal: controller.signal,
  #|     });
  #|     clearTimeout(timer);
  #|     if (response.status !== 200) return undefined;
  #|     const contentType = (response.headers.get("content-type") || "")
  #|       .split(";", 1)[0].trim().toLowerCase();
  #|     const jsonType = contentType === "application/json" ||
  #|       (contentType.startsWith("application/") && contentType.endsWith("+json"));
  #|     if (!jsonType) return undefined;
  #|     const text = await response.text();
  #|     if (new TextEncoder().encode(text).byteLength > 65536) return undefined;
  #|     return text;
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
/// Fetch one CIMD document. A non-HTTPS or malformed identifier is rejected
/// before any outbound request is made.
pub async fn fetch_client_metadata_document(client_id : String) -> String? {
  if !validate_client_id_url(client_id) {
    return None
  }
  fetch_client_metadata_raw(client_id).wait()
}
