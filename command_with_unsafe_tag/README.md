# command_with_unsafe_tag

This experimental implementation makes `Cmd` an extensible enum. An effect
package creates a `Handler` for its cases, then installs environment-specific
execution, JSON, and debug behavior in `fn init`.

New handlers run first. Raising `Unhandled` delegates to the previously
registered handler, so an exported `handler` can be extended downstream.

```mbt nocheck
///|
pub(all) extenum @command.Cmd += {
  Get(String)
  Post(String, String)
}

///|
pub let handler : @command.Handler = Handler([
  Get(Default::default()),
  Post(Default::default(), Default::default()),
])

///|
pub fn get(url : String) -> @command.Cmd {
  Get(url)
}

///|
pub fn post(url : String, body : String) -> @command.Cmd {
  Post(url, body)
}
```

The exported handler can override only the cases it recognizes:

```mbt nocheck
handler.to_json(p => {
  guard p is Post(url, _) else { raise @command.Unhandled }
  { "method": "POST", "url": url, "body": "..." }
})
```

See the complete [HTTP example](./example_http/http.mbt).

This package depends on the internal `%unsafe_obj_block_tag` primitive. Runtime
tags and backend support are not stable API guarantees; do not use the numeric
tag as a persistent or network protocol identifier.
