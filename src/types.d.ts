declare module "mbt:f4ah6o/blog.mbt/worker" {
  export function get_fetch_handler(): unknown;
}

declare module "/@markable/client" {}

declare module "virtual:blog-markable-source" {
  const source: string;
  export default source;
}
