///|
let global_handlers : Array[Handler] = []

///|
pub(all) extenum Cmd {}

///|
pub(all) suberror Unhandled

///|
struct Handler {
  mut execute : (Cmd) -> Unit raise Unhandled
  mut to_json : (Cmd) -> Json raise Unhandled
  mut from_json : (Json) -> Cmd raise Unhandled
  mut debug : (Cmd) -> Repr raise Unhandled
}

///|
fn[A, B] fallback(_ : A) -> B raise Unhandled {
  raise Unhandled
}

///|
/// extremely unstable 
fn unsafe_obj_block_tag(cmd : Cmd) -> Int = "%unsafe_obj_block_tag"

///|
let default_handler : Handler = {
  from_json: fallback,
  to_json: fallback,
  debug: fallback,
  execute: fallback,
}

///|
pub fn Handler::Handler(cases : Array[Cmd]) -> Handler {
  guard !(cases is [])
  let tags = cases.map(unsafe_obj_block_tag)..sort()
  global_handlers.resize(tags.last().unwrap() + 1, default_handler)
  let handler = Handler::{
    execute: fallback,
    from_json: fallback,
    to_json: fallback,
    debug: fallback,
  }
  for tag in tags {
    global_handlers[tag] = handler
  }
  handler
}

///|
fn[A, B] wrap_hook(
  f : (A) -> B raise Unhandled,
  g : (A) -> B raise Unhandled,
) -> (A) -> B raise Unhandled {
  a => f(a) catch { Unhandled => g(a) }
}

///|
pub fn Handler::from_json(
  self : Self,
  f : (Json) -> Cmd raise Unhandled,
) -> Unit {
  self.from_json = wrap_hook(f, self.from_json)
}

///|
pub fn Handler::to_json(self : Self, f : (Cmd) -> Json raise Unhandled) -> Unit {
  self.to_json = wrap_hook(f, self.to_json)
}

///|
pub fn Handler::debug(self : Self, f : (Cmd) -> Repr raise Unhandled) -> Unit {
  self.debug = wrap_hook(f, self.debug)
}

///|
pub fn Handler::execute(self : Self, f : (Cmd) -> Unit raise Unhandled) -> Unit {
  self.execute = wrap_hook(f, self.execute)
}

///|
fn get_handler(cmd : Cmd) -> Handler {
  global_handlers.get(unsafe_obj_block_tag(cmd)).unwrap_or(default_handler)
}

///|
pub fn run(cmd : Cmd) -> Unit raise Unhandled {
  (get_handler(cmd).execute)(cmd)
}

///|
pub impl ToJson for Cmd with fn to_json(cmd) {
  let to_json = get_handler(cmd).to_json
  let payload = to_json(cmd) catch { Unhandled => null }
  { "tag": unsafe_obj_block_tag(cmd), "payload": payload }
}

///|
pub impl FromJson for Cmd with fn from_json(json, path) {
  guard json is { "id": i, "payload": p, .. } &&
    @json.from_json(i) is Json::Number(tag, ..) &&
    global_handlers.get(tag.to_int()) is Some({ from_json, .. }) else {
    raise @json.JsonDecodeError((path, "unexpected input"))
  }
  from_json(p) catch {
    Unhandled => raise @json.JsonDecodeError((path, "unexpected input"))
  }
}

///|
pub impl Debug for Cmd with fn to_repr(cmd) {
  let to_repr = get_handler(cmd).debug
  to_repr(cmd) catch {
    Unhandled => Repr::omitted()
  }
}
