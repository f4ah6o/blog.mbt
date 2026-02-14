///|
pub enum PostStatus {
  Draft
  Published
} derive(Show, Eq)

///|
pub fn post_status_from_string(value : String) -> PostStatus {
  if value == "published" {
    PostStatus::Published
  } else {
    PostStatus::Draft
  }
}

///|
pub fn post_status_to_string(status : PostStatus) -> String {
  match status {
    Draft => "draft"
    Published => "published"
  }
}

///|
pub fn post_status_label(status : PostStatus) -> String {
  match status {
    Draft => "Draft"
    Published => "Published"
  }
}

///|
pub struct AdminPost {
  id : Int
  title : String
  slug : String
  excerpt : String
  content : String
  slide_flag : Bool
  status : PostStatus
  published_at : String?
  updated_at : String
} derive(Show)

///|
pub fn AdminPost::new(
  id : Int,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  slide_flag : Bool,
  status : PostStatus,
  published_at : String?,
  updated_at : String,
) -> AdminPost {
  {
    id,
    title,
    slug,
    excerpt,
    content,
    slide_flag,
    status,
    published_at,
    updated_at,
  }
}
