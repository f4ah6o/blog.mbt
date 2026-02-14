///|
fn replace_plus(value : String) -> String {
  let sb = StringBuilder::new()
  for ch in value {
    if ch == '+' {
      sb.write_char(' ')
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn url_decode(value : String) -> String {
  decode_uri_component(replace_plus(value))
}

///|
pub fn parse_urlencoded(body : String) -> Map[String, String] {
  let params : Map[String, String] = {}
  if body == "" {
    return params
  }
  for part_view in body.split("&") {
    let part = part_view.to_string()
    if part == "" {
      continue
    }
    let split_pos = part.find("=")
    let (raw_key, raw_value) = match split_pos {
      Some(pos) => {
        let key_view = try! part[:pos]
        let value_view = try! part[pos + 1:]
        (key_view.to_string(), value_view.to_string())
      }
      None => (part, "")
    }
    let key = url_decode(raw_key)
    let value = url_decode(raw_value)
    params[key] = value
  }
  params
}

///|
fn form_value(form : Map[String, String], key : String) -> String {
  match form.get(key) {
    Some(value) => value
    None => ""
  }
}

///|
fn form_checked(form : Map[String, String], key : String) -> Bool {
  match form.get(key) {
    Some(value) => {
      let normalized = value.trim().to_lower()
      normalized != "0" && normalized != "false" && normalized != "off"
    }
    None => false
  }
}
