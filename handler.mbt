///|
let global_map : @slotmap.SlotMap[Capability] = @slotmap.SlotMap()

///|
pub(all) extenum Payload {}

///|
struct Cmd {
  id : @slotmap.Id
  payload : Payload
}

///|
priv struct Capability {
  mut execute : (Payload) -> Unit
  to_json : ((Payload) -> Json)?
  from_json : ((Json) -> Payload)?
  debug : ((Payload) -> Repr)?
}

///|
struct Handler(@slotmap.Id)

///|
pub fn Handler::create(self : Self, payload : Payload) -> Cmd {
  { id: self.0, payload }
}

///|
pub fn Handler::on_execute(self : Self, f : (Payload) -> Unit) -> Unit {
  global_map[self.0].execute = f
}

///|
pub fn register(
  from_json? : (Json) -> Payload,
  to_json? : (Payload) -> Json,
  debug? : (Payload) -> Repr,
) -> Handler {
  global_map.allocate_with(_ => { execute: _ => (), from_json, to_json, debug })
}

///|
pub fn run(cmd : Cmd) -> Unit {
  (global_map[cmd.id].execute)(cmd.payload)
}

///|
pub impl ToJson for Cmd with fn to_json(cmd) {
  guard global_map[cmd.id].to_json is Some(f)
  { "id": cmd.id, "payload": f(cmd.payload) }
}

///|
pub impl FromJson for Cmd with fn from_json(json, path) {
  guard json is { "id": i, "payload": p, .. } &&
    @json.from_json(i) is id &&
    global_map.get(id) is Some({ from_json: Some(f), .. }) else {
    raise @json.JsonDecodeError((path, "unexpected input"))
  }
  { id, payload: f(p) }
}

///|
pub impl Debug for Cmd with fn to_repr(cmd) {
  guard global_map[cmd.id].debug is Some(f)
  f(cmd.payload)
}
