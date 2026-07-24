///|
let global_handlers : @slotmap.SlotMap[Handler] = @slotmap.SlotMap()

///|
pub(all) extenum Payload {}

///|
pub struct Cmd {
  priv id : @slotmap.Id
  payload : Payload
}

///|
pub(all) suberror Unhandled

///|
struct Handler {
  id : @slotmap.Id?
  mut execute : (Payload) -> Unit raise Unhandled
  mut to_json : (Payload) -> Json raise Unhandled
  mut from_json : (Json) -> Payload raise Unhandled
  mut debug : (Payload) -> Repr raise Unhandled
}

///|
pub fn Handler::request(self : Self, payload : Payload) -> Cmd {
  { id: self.id.unwrap(), payload }
}

///|
fn[A, B] fallback(_ : A) -> B raise Unhandled {
  raise Unhandled
}

///|
let default_handler : Handler = {
  id: None,
  from_json: fallback,
  to_json: fallback,
  debug: fallback,
  execute: fallback,
}

///|
pub fn register() -> Handler {
  // copy the handler
  let id = global_handlers.allocate_with(id => {
    ..default_handler,
    id: Some(id),
  })
  global_handlers[id]
}

///|
pub impl ToJson for Cmd with fn to_json(cmd) {
  let to_json = global_handlers[cmd.id].to_json
  let payload = to_json(cmd.payload) catch { Unhandled => null }
  { "id": cmd.id, "payload": payload }
}

///|
pub impl FromJson for Cmd with fn from_json(json, path) {
  guard json is { "id": i, "payload": p, .. } &&
    @json.from_json(i) is id &&
    global_handlers.get(id) is Some({ from_json, .. }) else {
    raise @json.JsonDecodeError((path, "unexpected input"))
  }
  let payload = from_json(p) catch {
    Unhandled => raise @json.JsonDecodeError((path, "unexpected input"))
  }
  { id, payload }
}

///|
pub impl Debug for Cmd with fn to_repr(cmd) {
  let to_repr = global_handlers[cmd.id].debug
  to_repr(cmd.payload) catch {
    Unhandled => Repr::omitted()
  }
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
  f : (Json) -> Payload raise Unhandled,
) -> Unit {
  self.from_json = wrap_hook(f, self.from_json)
}

///|
pub fn Handler::to_json(
  self : Self,
  f : (Payload) -> Json raise Unhandled,
) -> Unit {
  self.to_json = wrap_hook(f, self.to_json)
}

///|
pub fn Handler::debug(
  self : Self,
  f : (Payload) -> Repr raise Unhandled,
) -> Unit {
  self.debug = wrap_hook(f, self.debug)
}

///|
pub fn Handler::execute(
  self : Self,
  f : (Payload) -> Unit raise Unhandled,
) -> Unit {
  self.execute = wrap_hook(f, self.execute)
}

///|
pub fn run(cmd : Cmd) -> Unit raise Unhandled {
  (global_handlers[cmd.id].execute)(cmd.payload)
}
