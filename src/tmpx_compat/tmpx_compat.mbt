///|
pub type Node = @tmpx_core.Node

///|
pub type Attr = @tmpx_core.Attr

///|
pub type Part = @tmpx_core.Part

///|
pub type MxSwap = @tmpx_core.MxSwap

///|
pub fn inner_html() -> MxSwap {
  @tmpx_core.InnerHTML
}

///|
fn build_parts(attrs : Array[Attr], children : Array[Node]) -> Array[Part] {
  let parts : Array[Part] = []
  for attr in attrs {
    parts.push(@tmpx_core.part_attr(attr))
  }
  for child in children {
    parts.push(@tmpx_core.part_child(child))
  }
  parts
}

///|
pub fn attr(name : String, value : String) -> Attr {
  @tmpx_core.attr(name, value)
}

///|
pub fn bool_attr(name : String) -> Attr {
  @tmpx_core.bool_attr(name)
}

///|
pub fn class_(value : String) -> Attr {
  @tmpx_core.class_(value)
}

///|
pub fn class_list(values : Array[String]) -> Attr {
  @tmpx_core.class_list(values)
}

///|
pub fn href(value : String) -> Attr {
  @tmpx_core.href(value)
}

///|
pub fn src(value : String) -> Attr {
  @tmpx_core.src(value)
}

///|
pub fn alt(value : String) -> Attr {
  @tmpx_core.alt(value)
}

///|
pub fn id_(value : String) -> Attr {
  @tmpx_core.id_(value)
}

///|
pub fn lang_attr(value : String) -> Attr {
  @tmpx_core.attr("lang", value)
}

///|
pub fn data_attr(name : String, value : String) -> Attr {
  @tmpx_core.attr("data-" + name, value)
}

///|
pub fn method_(value : String) -> Attr {
  @tmpx_core.attr("method", value)
}

///|
pub fn action(value : String) -> Attr {
  @tmpx_core.attr("action", value)
}

///|
pub fn name_(value : String) -> Attr {
  @tmpx_core.attr("name", value)
}

///|
pub fn type_(value : String) -> Attr {
  @tmpx_core.attr("type", value)
}

///|
pub fn value_(value : String) -> Attr {
  @tmpx_core.attr("value", value)
}

///|
pub fn content(value : String) -> Attr {
  @tmpx_core.attr("content", value)
}

///|
pub fn charset(value : String) -> Attr {
  @tmpx_core.attr("charset", value)
}

///|
pub fn rel(value : String) -> Attr {
  @tmpx_core.attr("rel", value)
}

///|
pub fn for_(value : String) -> Attr {
  @tmpx_core.attr("for", value)
}

///|
pub fn placeholder(value : String) -> Attr {
  @tmpx_core.attr("placeholder", value)
}

///|
pub fn disabled() -> Attr {
  @tmpx_core.bool_attr("disabled")
}

///|
pub fn mx_get(value : String) -> Attr {
  @tmpx_core.mx_get(value)
}

///|
pub fn mx_post(value : String) -> Attr {
  @tmpx_core.mx_post(value)
}

///|
pub fn mx_target(value : String) -> Attr {
  @tmpx_core.mx_target(value)
}

///|
pub fn mx_trigger(value : String) -> Attr {
  @tmpx_core.mx_trigger(value)
}

///|
pub fn mx_swap(value : MxSwap) -> Attr {
  @tmpx_core.mx_swap(value)
}

///|
pub fn mx_push_url_custom(value : String) -> Attr {
  @tmpx_core.attr("mx-push-url", value)
}

///|
pub fn text(value : String) -> Node {
  @tmpx_core.text(value)
}

///|
pub fn raw_html(value : String) -> Node {
  @tmpx_core.raw(value)
}

///|
pub fn fragment(nodes : Array[Node]) -> Node {
  @tmpx_core.fragment(nodes)
}

///|
pub fn render(node : Node) -> String {
  @tmpx_core.render(node)
}

///|
pub fn html_(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.html_parts(build_parts(attrs, children))
}

///|
pub fn head(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.head_parts(build_parts(attrs, children))
}

///|
pub fn body(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.body_parts(build_parts(attrs, children))
}

///|
pub fn header_(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.header_parts(build_parts(attrs, children))
}

///|
pub fn main_(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.main_parts(build_parts(attrs, children))
}

///|
pub fn nav(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.nav_parts(build_parts(attrs, children))
}

///|
pub fn article(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.article_parts(build_parts(attrs, children))
}

///|
pub fn section(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.section_parts(build_parts(attrs, children))
}

///|
pub fn div(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.div_parts(build_parts(attrs, children))
}

///|
pub fn span(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.span_parts(build_parts(attrs, children))
}

///|
pub fn p(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.p_parts(build_parts(attrs, children))
}

///|
pub fn h1(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.h1_parts(build_parts(attrs, children))
}

///|
pub fn h2(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.h2_parts(build_parts(attrs, children))
}

///|
pub fn h3(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.h3_parts(build_parts(attrs, children))
}

///|
pub fn h4(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.h4_parts(build_parts(attrs, children))
}

///|
pub fn h5(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.h5_parts(build_parts(attrs, children))
}

///|
pub fn h6(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.h6_parts(build_parts(attrs, children))
}

///|
pub fn strong(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.strong_parts(build_parts(attrs, children))
}

///|
pub fn em(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.em_parts(build_parts(attrs, children))
}

///|
pub fn pre(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.pre_parts(build_parts(attrs, children))
}

///|
pub fn code(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.code_parts(build_parts(attrs, children))
}

///|
pub fn ul(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.ul_parts(build_parts(attrs, children))
}

///|
pub fn ol(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.ol_parts(build_parts(attrs, children))
}

///|
pub fn li(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.li_parts(build_parts(attrs, children))
}

///|
pub fn a(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.a_parts(build_parts(attrs, children))
}

///|
pub fn time(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.time_parts(build_parts(attrs, children))
}

///|
pub fn form(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.form_parts(build_parts(attrs, children))
}

///|
pub fn label(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.label_parts(build_parts(attrs, children))
}

///|
pub fn textarea(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.textarea_parts(build_parts(attrs, children))
}

///|
pub fn button(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.button_parts(build_parts(attrs, children))
}

///|
pub fn table(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.table_parts(build_parts(attrs, children))
}

///|
pub fn thead(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.thead_parts(build_parts(attrs, children))
}

///|
pub fn tbody(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.tbody_parts(build_parts(attrs, children))
}

///|
pub fn tr(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.tr_parts(build_parts(attrs, children))
}

///|
pub fn th(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.th_parts(build_parts(attrs, children))
}

///|
pub fn td(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.td_parts(build_parts(attrs, children))
}

///|
pub fn footer(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.footer_parts(build_parts(attrs, children))
}

///|
pub fn title(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.title_parts(build_parts(attrs, children))
}

///|
pub fn meta(attrs : Array[Attr]) -> Node {
  @tmpx_core.meta_attrs(attrs)
}

///|
pub fn link(attrs : Array[Attr]) -> Node {
  @tmpx_core.link_attrs(attrs)
}

///|
pub fn input_(attrs : Array[Attr]) -> Node {
  @tmpx_core.input_attrs(attrs)
}

///|
pub fn img(attrs : Array[Attr]) -> Node {
  @tmpx_core.img_attrs(attrs)
}

///|
pub fn script(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.unsafe_custom_element("script", build_parts(attrs, children))
}

///|
pub fn iframe(attrs : Array[Attr], children : Array[Node]) -> Node {
  @tmpx_core.iframe_parts(build_parts(attrs, children))
}
