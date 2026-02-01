///|
/// Credential repository using Cloudflare KV.
/// Stores WebAuthn credentials and challenges.

// =============================================================================
// KV Key Prefixes
// =============================================================================

///|
/// Key prefix for credentials: "credentials:{user_id}"
let credentials_key_prefix : String = "credentials:"

///|
/// Key prefix for challenges: "challenge:{user_id}:{challenge_id}"
let challenge_key_prefix : String = "challenge:"

///|
/// Challenge TTL in seconds (5 minutes)
let challenge_ttl_seconds : Int = 300

// =============================================================================
// Credential Types
// =============================================================================

///|
/// Stored credential in KV
struct StoredCredential {
  /// Credential ID (base64url encoded)
  id : String
  /// Public key (base64url encoded)
  public_key : String
  /// Signature counter
  counter : UInt
  /// Authenticator transports
  transports : Array[String]
  /// Human-readable name for the credential
  name : String
  /// Creation timestamp (ISO 8601)
  created_at : String
} derive(Show, ToJson, FromJson)

///|
/// Challenge stored in KV
struct StoredChallenge {
  /// The actual challenge bytes (base64url encoded)
  challenge : String
  /// Type of challenge: "registration" or "authentication"
  challenge_type : String
  /// Expiration timestamp (Unix seconds)
  expires_at : Int
} derive(Show, ToJson, FromJson)

// =============================================================================
// Credential Operations
// =============================================================================

///|
/// Build KV key for credentials
fn build_credentials_key(user_id : String) -> String {
  credentials_key_prefix + user_id
}

///|
/// Get all credentials for a user
async fn get_credentials(
  kv : @core.Any,
  user_id : String,
) -> Array[StoredCredential] {
  let key = build_credentials_key(user_id)
  let value = kv_get(kv, key).wait() // JS Promise needs .wait()
  match value {
    None => []
    Some(json_str) => {
      let parsed_result : Result[Json, _] = try? @json.parse(json_str)
      match parsed_result {
        Err(_) => []
        Ok(json) => {
          let creds_result : Result[Array[StoredCredential], _] = try? @json.from_json(
            json,
          )
          match creds_result {
            Ok(creds) => creds
            Err(_) => []
          }
        }
      }
    }
  }
}

///|
/// Save credentials for a user (replaces all existing)
async fn save_credentials(
  kv : @core.Any,
  user_id : String,
  credentials : Array[StoredCredential],
) -> Unit {
  let key = build_credentials_key(user_id)
  let json_arr : Array[Json] = credentials.map(fn(c) { c.to_json() })
  let json_str = Json::array(json_arr).stringify()
  kv_put(kv, key, json_str, 0).wait() // JS Promise needs .wait()
}

///|
/// Add a new credential for a user
async fn add_credential(
  kv : @core.Any,
  user_id : String,
  credential : StoredCredential,
) -> Unit {
  let existing : Array[StoredCredential] = get_credentials(kv, user_id) // async fn
  existing.push(credential)
  let _ : Unit = save_credentials(kv, user_id, existing)
  // async fn
}

///|
/// Find a credential by ID
async fn find_credential_by_id(
  kv : @core.Any,
  user_id : String,
  credential_id : String,
) -> StoredCredential? {
  let creds : Array[StoredCredential] = get_credentials(kv, user_id) // async fn
  for cred in creds {
    if cred.id == credential_id {
      return Some(cred)
    }
  }
  None
}

///|
/// Update credential counter after successful authentication
async fn update_credential_counter(
  kv : @core.Any,
  user_id : String,
  credential_id : String,
  new_counter : UInt,
) -> Unit {
  let creds : Array[StoredCredential] = get_credentials(kv, user_id) // async fn
  let updated : Array[StoredCredential] = []
  for cred in creds {
    if cred.id == credential_id {
      updated.push({
        id: cred.id,
        public_key: cred.public_key,
        counter: new_counter,
        transports: cred.transports,
        name: cred.name,
        created_at: cred.created_at,
      })
    } else {
      updated.push(cred)
    }
  }
  let _ : Unit = save_credentials(kv, user_id, updated)
  // async fn
}

// =============================================================================
// Challenge Operations
// =============================================================================

///|
/// Build KV key for challenge: "challenge:{user_id}:{challenge_id}"
fn build_challenge_key(user_id : String, challenge_id : String) -> String {
  challenge_key_prefix + user_id + ":" + challenge_id
}

///|
/// Save a challenge to KV with TTL
async fn save_challenge(
  kv : @core.Any,
  user_id : String,
  challenge_id : String,
  challenge : String,
  challenge_type : String,
) -> Unit {
  let key = build_challenge_key(user_id, challenge_id)
  let now = now_unix_seconds()
  let stored : StoredChallenge = {
    challenge,
    challenge_type,
    expires_at: now + challenge_ttl_seconds,
  }
  let json_str = stored.to_json().stringify()
  kv_put(kv, key, json_str, challenge_ttl_seconds).wait() // JS Promise
}

///|
/// Get a challenge from KV (validates expiration)
async fn get_challenge(
  kv : @core.Any,
  user_id : String,
  challenge_id : String,
) -> StoredChallenge? {
  let key = build_challenge_key(user_id, challenge_id)
  let value = kv_get(kv, key).wait() // JS Promise
  match value {
    None => None
    Some(json_str) => {
      let parsed_result : Result[Json, _] = try? @json.parse(json_str)
      match parsed_result {
        Err(_) => None
        Ok(json) => {
          let stored_result : Result[StoredChallenge, _] = try? @json.from_json(
            json,
          )
          match stored_result {
            Ok(stored) => {
              // Check if expired
              let now = now_unix_seconds()
              if now > stored.expires_at {
                // Expired, delete and return None
                let _ : Unit = delete_challenge(kv, user_id, challenge_id) // async fn
                return None
              }
              Some(stored)
            }
            Err(_) => None
          }
        }
      }
    }
  }
}

///|
/// Delete a challenge from KV
async fn delete_challenge(
  kv : @core.Any,
  user_id : String,
  challenge_id : String,
) -> Unit {
  let key = build_challenge_key(user_id, challenge_id)
  kv_delete(kv, key).wait() // JS Promise
}

///|
/// Verify and consume a challenge (get + delete in one operation)
/// Returns the challenge if valid, None if not found or expired
async fn consume_challenge(
  kv : @core.Any,
  user_id : String,
  challenge_id : String,
  expected_type : String,
) -> StoredChallenge? {
  let stored : StoredChallenge? = get_challenge(kv, user_id, challenge_id) // async fn
  match stored {
    None => None
    Some(s) => {
      // Check challenge type
      if s.challenge_type != expected_type {
        return None
      }
      //
      // Delete the challenge (one-time use)
      let _ : Unit = delete_challenge(kv, user_id, challenge_id) // async fn
      Some(s)
    }
  }
}
