///|
/// WebAuthn authentication and registration handling.
/// Uses simple-webauthn library for core WebAuthn operations.

// =============================================================================
// Response Types for API (for browser consumption)
// =============================================================================

///|
/// Authentication options response (sent to browser)
struct AuthOptionsResponse {
  /// The challenge bytes (base64url encoded)
  challenge : String
  /// Server-generated challenge ID for verification
  challenge_id : String
  /// Timeout in milliseconds
  timeout : Int
  /// Relying Party ID
  rp_id : String
  /// Allowed credentials (for non-discoverable flow)
  allow_credentials : Array[CredentialDescriptorJS]
  /// User verification requirement
  user_verification : String
} derive(Show, ToJson)

///|
/// Registration options response (sent to browser)
struct RegOptionsResponse {
  /// The challenge bytes (base64url encoded)
  challenge : String
  /// Server-generated challenge ID for verification
  challenge_id : String
  /// Timeout in milliseconds
  timeout : Int
  /// Relying Party info
  rp : RelyingPartyInfoJS
  /// User info
  user : UserInfoJS
  /// Supported public key algorithms
  pub_key_cred_params : Array[PubKeyCredParamJS]
  /// Credentials to exclude (prevent re-registration)
  exclude_credentials : Array[CredentialDescriptorJS]
  /// Authenticator selection criteria
  authenticator_selection : AuthenticatorSelectionJS
  /// Attestation conveyance preference
  attestation : String
} derive(Show, ToJson)

///|
/// Credential descriptor for allow/exclude lists (JavaScript-friendly format)
struct CredentialDescriptorJS {
  id : String
  type_ : String
  transports : Array[String]
} derive(Show, FromJson)

///|
/// ToJson impl for CredentialDescriptorJS to use "type" instead of "type_"
impl ToJson for CredentialDescriptorJS with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["id"] = self.id.to_json()
  obj["type"] = self.type_.to_json()
  obj["transports"] = Json::array(self.transports.map(fn(t) { t.to_json() }))
  Json::object(obj)
}

///|
/// Relying Party info for registration (JavaScript-friendly format)
struct RelyingPartyInfoJS {
  id : String
  name : String
} derive(Show, ToJson)

///|
/// User info for registration (JavaScript-friendly format)
struct UserInfoJS {
  id : String
  name : String
  display_name : String
} derive(Show)

///|
/// ToJson impl for UserInfoJS to use "displayName" instead of "display_name"
impl ToJson for UserInfoJS with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["id"] = self.id.to_json()
  obj["name"] = self.name.to_json()
  obj["displayName"] = self.display_name.to_json()
  Json::object(obj)
}

///|
/// Public key credential parameters (JavaScript-friendly format)
struct PubKeyCredParamJS {
  type_ : String
  alg : Int
} derive(Show)

///|
/// ToJson impl for PubKeyCredParamJS to use "type" instead of "type_"
impl ToJson for PubKeyCredParamJS with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["type"] = self.type_.to_json()
  obj["alg"] = self.alg.to_json()
  Json::object(obj)
}

///|
/// Authenticator selection criteria (JavaScript-friendly format)
struct AuthenticatorSelectionJS {
  authenticator_attachment : String?
  resident_key : String
  user_verification : String
} derive(Show)

///|
/// ToJson impl for AuthenticatorSelectionJS with camelCase keys
impl ToJson for AuthenticatorSelectionJS with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["residentKey"] = self.resident_key.to_json()
  obj["userVerification"] = self.user_verification.to_json()
  match self.authenticator_attachment {
    Some(a) => obj["authenticatorAttachment"] = a.to_json()
    None => ()
  }
  Json::object(obj)
}

// =============================================================================
// Authentication Options Generation
// =============================================================================

///|
/// Generate authentication options for WebAuthn login.
/// Saves challenge to KV and returns options for the browser.
async fn generate_auth_options(
  kv : @core.Any,
  user_id : String,
  rp_id : String,
) -> AuthOptionsResponse {
  // Get existing credentials for the user (async fn - call directly)
  let stored_creds = get_credentials(kv, user_id)
  //
  // Build allow_credentials list
  let allow_credentials : Array[CredentialDescriptorJS] = stored_creds.map(fn(
    cred : StoredCredential,
  ) {
    { id: cred.id, type_: "public-key", transports: cred.transports }
  })
  //
  // Generate random challenge (16 bytes)
  let challenge = generate_random_challenge()
  //
  // Generate challenge_id and save to KV (async fn - call directly)
  let challenge_id = generate_uuid()
  save_challenge(kv, user_id, challenge_id, challenge, "authentication")
  //
  // Build response
  {
    challenge,
    challenge_id,
    timeout: 60000,
    rp_id,
    allow_credentials,
    user_verification: "preferred",
  }
}

// =============================================================================
// Registration Options Generation
// =============================================================================

///|
/// Generate registration options for WebAuthn credential creation.
/// Saves challenge to KV and returns options for the browser.
async fn generate_reg_options(
  kv : @core.Any,
  user_id : String,
  user_name : String,
  rp_id : String,
  rp_name : String,
) -> RegOptionsResponse {
  // Get existing credentials to exclude (async fn - call directly)
  let stored_creds = get_credentials(kv, user_id)
  let exclude_credentials : Array[CredentialDescriptorJS] = stored_creds.map(fn(
    cred : StoredCredential,
  ) {
    { id: cred.id, type_: "public-key", transports: cred.transports }
  })
  //
  // Generate random challenge
  let challenge = generate_random_challenge()
  //
  // Generate challenge_id and save to KV (async fn - call directly)
  let challenge_id = generate_uuid()
  save_challenge(kv, user_id, challenge_id, challenge, "registration")
  //
  // Build response
  // Use user_id as the user handle (base64url encoded)
  let user_id_b64 = @webauthn_helpers.base64url_encode(
    Bytes::from_array(user_id.to_array().map(fn(c) { c.to_int().to_byte() })),
  )
  {
    challenge,
    challenge_id,
    timeout: 60000,
    rp: { id: rp_id, name: rp_name },
    user: { id: user_id_b64, name: user_name, display_name: user_name },
    pub_key_cred_params: [
      { type_: "public-key", alg: -7 }, // ES256
      { type_: "public-key", alg: -257 }, // RS256
    ],
    exclude_credentials,
    authenticator_selection: {
      authenticator_attachment: None,
      resident_key: "preferred",
      user_verification: "preferred",
    },
    attestation: "none",
  }
}

// =============================================================================
// Authentication Verification
// =============================================================================

///|
/// Authentication verification request from browser
struct AuthVerifyRequest {
  challenge_id : String
  credential_id : String
  raw_id : String
  client_data_json : String
  authenticator_data : String
  signature : String
} derive(Show, FromJson)

///|
/// Result of authentication verification
priv enum AuthVerifyResult {
  /// Authentication succeeded
  Success(UInt) // new counter value
  /// Challenge not found or expired
  ChallengeInvalid
  /// Credential not found
  CredentialNotFound
  /// Signature verification failed
  VerificationFailed(String)
}

///|
/// Verify authentication response from browser.
async fn verify_authentication(
  kv : @core.Any,
  user_id : String,
  rp_id : String,
  origin : String,
  request : AuthVerifyRequest,
) -> AuthVerifyResult {
  // 1. Consume challenge (validates and deletes) - async fn, call directly
  let challenge_result = consume_challenge(
    kv,
    user_id,
    request.challenge_id,
    "authentication",
  )
  let challenge = match challenge_result {
    None => return ChallengeInvalid
    Some(c) => c.challenge
  }
  //
  // 2. Find stored credential (async fn - call directly)
  let stored_cred = find_credential_by_id(kv, user_id, request.credential_id)
  let cred = match stored_cred {
    None => return CredentialNotFound
    Some(c) => c
  }
  //
  // 3. Decode base64url inputs
  let client_data_json = decode_base64url(request.client_data_json)
  let client_data_json_bytes = match client_data_json {
    None => return VerificationFailed("Invalid client_data_json base64url")
    Some(b) => b
  }
  let authenticator_data = decode_base64url(request.authenticator_data)
  let authenticator_data_bytes = match authenticator_data {
    None => return VerificationFailed("Invalid authenticator_data base64url")
    Some(b) => b
  }
  let signature = decode_base64url(request.signature)
  let signature_bytes = match signature {
    None => return VerificationFailed("Invalid signature base64url")
    Some(b) => b
  }
  let public_key = decode_base64url(cred.public_key)
  let public_key_bytes = match public_key {
    None => return VerificationFailed("Invalid stored public_key base64url")
    Some(b) => b
  }
  let challenge_bytes = decode_base64url(challenge)
  let challenge_decoded = match challenge_bytes {
    None => return VerificationFailed("Invalid challenge base64url")
    Some(b) => b
  }
  let credential_id = decode_base64url(cred.id)
  let credential_id_bytes = match credential_id {
    None => return VerificationFailed("Invalid credential_id base64url")
    Some(b) => b
  }
  //
  // 4. Build verification options with permissive sign count policy
  let authenticator_cred = @webauthn_server.AuthenticatorCredential::new(
    credential_id_bytes,
    public_key_bytes,
    cred.counter,
  )
  let verify_options = @webauthn_server.VerifyAuthenticationOptions::new(
    challenge_decoded, origin, rp_id, authenticator_cred,
  ).with_sign_count_policy_permissive() // AllowZero for iCloud Keychain compatibility
  //
  // 5. Verify using simple-webauthn (async fn - call directly, returns Result)
  let verify_result = @webauthn_server.verify_authentication_response_async(
    credential_id_bytes, client_data_json_bytes, authenticator_data_bytes, signature_bytes,
    verify_options,
  )
  match verify_result {
    Err(e) => VerificationFailed(auth_error_to_string(e))
    Ok(verified) => {
      // 6. Update counter in KV (async fn - call directly)
      let new_counter = verified.new_sign_count
      update_credential_counter(kv, user_id, request.credential_id, new_counter)
      Success(new_counter)
    }
  }
}

// =============================================================================
// Registration Verification
// =============================================================================

///|
/// Registration verification request from browser
struct RegVerifyRequest {
  challenge_id : String
  credential_id : String
  raw_id : String
  client_data_json : String
  attestation_object : String
  /// Optional human-readable name for the credential
  credential_name : String?
} derive(Show, FromJson)

///|
/// Result of registration verification
priv enum RegVerifyResult {
  /// Registration succeeded
  Success
  /// Challenge not found or expired
  ChallengeInvalid
  /// Verification failed
  VerificationFailed(String)
}

///|
/// Verify registration response from browser.
async fn verify_registration(
  kv : @core.Any,
  user_id : String,
  rp_id : String,
  origin : String,
  request : RegVerifyRequest,
) -> RegVerifyResult {
  // 1. Consume challenge (validates and deletes) - async fn, call directly
  let challenge_result = consume_challenge(
    kv,
    user_id,
    request.challenge_id,
    "registration",
  )
  let challenge = match challenge_result {
    None => return ChallengeInvalid
    Some(c) => c.challenge
  }
  //
  // 2. Decode base64url inputs
  let client_data_json = decode_base64url(request.client_data_json)
  let client_data_json_bytes = match client_data_json {
    None => return VerificationFailed("Invalid client_data_json base64url")
    Some(b) => b
  }
  let attestation_object = decode_base64url(request.attestation_object)
  let attestation_object_bytes = match attestation_object {
    None => return VerificationFailed("Invalid attestation_object base64url")
    Some(b) => b
  }
  let challenge_bytes = decode_base64url(challenge)
  let challenge_decoded = match challenge_bytes {
    None => return VerificationFailed("Invalid challenge base64url")
    Some(b) => b
  }
  //
  // 3. Build verification options
  let verify_options = @webauthn_server.VerifyRegistrationOptions::new(
    challenge_decoded, origin, rp_id,
  )
  //
  // 4. Verify using simple-webauthn
  let verify_result : Result[@webauthn_server.VerifiedRegistration, _] = try? @webauthn_server.verify_registration_response(
    client_data_json_bytes, attestation_object_bytes, verify_options,
  )
  match verify_result {
    Err(e) => VerificationFailed(reg_error_to_string(e))
    Ok(verified) => {
      // 5. Store the new credential
      let now_str = now_iso()
      let credential_name = match request.credential_name {
        Some(n) if n != "" => n
        _ => {
          // Default name with date
          let date_part = if now_str.length() >= 10 {
            now_str[:10].to_string()
          } else {
            now_str
          }
          "Passkey " + date_part
        }
      }
      let new_cred : StoredCredential = {
        id: request.credential_id,
        public_key: @webauthn_helpers.base64url_encode(
          verified.credential_public_key,
        ),
        counter: verified.sign_count,
        transports: [], // Browser doesn't always provide these
        name: credential_name,
        created_at: now_str,
      }
      // async fn - call directly
      add_credential(kv, user_id, new_cred)
      Success
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Convert AuthenticationVerifyError to string message
fn auth_error_to_string(
  e : @webauthn_server.AuthenticationVerifyError,
) -> String {
  match e {
    @webauthn_server.AuthenticationVerifyError::InvalidClientDataType(msg) =>
      "Invalid client data type: " + msg
    @webauthn_server.AuthenticationVerifyError::ChallengeMismatch(msg) =>
      "Challenge mismatch: " + msg
    @webauthn_server.AuthenticationVerifyError::OriginMismatch(msg) =>
      "Origin mismatch: " + msg
    @webauthn_server.AuthenticationVerifyError::RpIdHashMismatch(msg) =>
      "RP ID hash mismatch: " + msg
    @webauthn_server.AuthenticationVerifyError::UserNotPresent =>
      "User not present"
    @webauthn_server.AuthenticationVerifyError::UserVerificationRequired =>
      "User verification required"
    @webauthn_server.AuthenticationVerifyError::CredentialNotAllowed(msg) =>
      "Credential not allowed: " + msg
    @webauthn_server.AuthenticationVerifyError::SignatureVerificationFailed(msg) =>
      "Signature verification failed: " + msg
    @webauthn_server.AuthenticationVerifyError::SignCountInvalid(msg) =>
      "Sign count invalid: " + msg
    @webauthn_server.AuthenticationVerifyError::ClientDataParseError(msg) =>
      "Client data parse error: " + msg
    @webauthn_server.AuthenticationVerifyError::AuthenticatorDataParseError(msg) =>
      "Authenticator data parse error: " + msg
    @webauthn_server.AuthenticationVerifyError::Base64DecodeError(msg) =>
      "Base64 decode error: " + msg
    @webauthn_server.AuthenticationVerifyError::InvalidPublicKey(msg) =>
      "Invalid public key: " + msg
    @webauthn_server.AuthenticationVerifyError::ValidationError(msg) =>
      "Validation error: " + msg
  }
}

///|
/// Convert RegistrationVerifyError to string message
fn reg_error_to_string(e : @webauthn_server.RegistrationVerifyError) -> String {
  match e {
    @webauthn_server.RegistrationVerifyError::InvalidClientDataType(msg) =>
      "Invalid client data type: " + msg
    @webauthn_server.RegistrationVerifyError::ChallengeMismatch(msg) =>
      "Challenge mismatch: " + msg
    @webauthn_server.RegistrationVerifyError::OriginMismatch(msg) =>
      "Origin mismatch: " + msg
    @webauthn_server.RegistrationVerifyError::RpIdHashMismatch(msg) =>
      "RP ID hash mismatch: " + msg
    @webauthn_server.RegistrationVerifyError::UserNotPresent =>
      "User not present"
    @webauthn_server.RegistrationVerifyError::UserVerificationRequired =>
      "User verification required"
    @webauthn_server.RegistrationVerifyError::AttestedCredentialDataMissing =>
      "Attested credential data missing"
    @webauthn_server.RegistrationVerifyError::InvalidCredentialId(msg) =>
      "Invalid credential ID: " + msg
    @webauthn_server.RegistrationVerifyError::InvalidPublicKey(msg) =>
      "Invalid public key: " + msg
    @webauthn_server.RegistrationVerifyError::UnsupportedAttestationFormat(msg) =>
      "Unsupported attestation format: " + msg
    @webauthn_server.RegistrationVerifyError::AttestationSignatureInvalid(msg) =>
      "Attestation signature invalid: " + msg
    @webauthn_server.RegistrationVerifyError::SignatureVerificationNotImplemented =>
      "Signature verification not implemented"
    @webauthn_server.RegistrationVerifyError::ClientDataParseError(msg) =>
      "Client data parse error: " + msg
    @webauthn_server.RegistrationVerifyError::AttestationObjectParseError(msg) =>
      "Attestation object parse error: " + msg
    @webauthn_server.RegistrationVerifyError::Base64DecodeError(msg) =>
      "Base64 decode error: " + msg
    @webauthn_server.RegistrationVerifyError::ValidationError(msg) =>
      "Validation error: " + msg
  }
}

///|
/// Generate a random challenge (base64url encoded)
extern "js" fn generate_random_challenge() -> String =
  #| () => {
  #|   const bytes = new Uint8Array(32);
  #|   crypto.getRandomValues(bytes);
  #|   let str = '';
  #|   for (let i = 0; i < bytes.length; i++) {
  #|     str += String.fromCharCode(bytes[i]);
  #|   }
  #|   return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  #| }

///|
/// Decode a base64url string to bytes
fn decode_base64url(s : String) -> Bytes? {
  let result = try? @webauthn_helpers.base64url_decode(s)
  match result {
    Ok(bytes) => Some(bytes)
    Err(_) => None
  }
}
