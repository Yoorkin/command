///|
let global_handlers : @slotmap.SlotMap[Entry] = @slotmap.SlotMap()

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
priv struct Entry {
  mut execute : (Payload) -> Unit raise Unhandled
  to_json : (Payload) -> Json raise Unhandled
  from_json : (Json) -> Payload raise Unhandled
  debug : (Payload) -> Repr raise Unhandled
}

///|
pub type Hook = ((Payload) -> Unit raise Unhandled) -> Unit

///|
pub fn Token::hook(self : Self) -> Hook {
  fn(f : (Payload) -> Unit raise Unhandled) -> Unit {
    let capability = global_handlers[self.id]
    let g = capability.execute
    capability.execute = p => f(p) catch { Unhandled => g(p) }
  }
}

///|
pub fn Token::request(self : Self, payload : Payload) -> Cmd {
  (self.injector)(payload)
}

///|
/// Full authority owned by the effect-defining package.
/// Keep this value private and expose only `Hook`. For example:
/// 
/// ```mbt nocheck
/// let token : @command.Token = @command.register(...)
/// pub let hook : @command.Hook = token.hook()
/// ```
struct Token {
  id : @slotmap.Id
  injector : (Payload) -> Cmd
}

///|
fn[A, B] fallback(_ : A) -> B raise Unhandled {
  raise Unhandled
}

///|
pub fn register(
  from_json? : (Json) -> Payload raise Unhandled = fallback,
  to_json? : (Payload) -> Json raise Unhandled = fallback,
  debug? : (Payload) -> Repr raise Unhandled = fallback,
  execute? : (Payload) -> Unit raise Unhandled = fallback,
) -> Token {
  let id = global_handlers.allocate_with(_ => {
    execute,
    from_json,
    to_json,
    debug,
  })
  { id, injector: payload => { id, payload } }
}

///|
pub fn run(cmd : Cmd) -> Unit raise Unhandled {
  (global_handlers[cmd.id].execute)(cmd.payload)
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
