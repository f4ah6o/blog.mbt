///|
pub struct BlogPost {
  id : Int
  title : String
  slug : String
  excerpt : String
  content : String
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
  published_at : String,
  updated_at : String,
) -> BlogPost {
  { id, title, slug, excerpt, content, published_at, updated_at }
}
