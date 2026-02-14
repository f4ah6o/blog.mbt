///|
pub struct BlogPost {
  id : Int
  title : String
  slug : String
  excerpt : String
  content : String
  slide_flag : Bool
  published_at : String
  updated_at : String
} derive(Show, Eq)

///|
pub fn BlogPost::new(
  id : Int,
  title : String,
  slug : String,
  excerpt : String,
  content : String,
  slide_flag : Bool,
  published_at : String,
  updated_at : String,
) -> BlogPost {
  { id, title, slug, excerpt, content, slide_flag, published_at, updated_at }
}
