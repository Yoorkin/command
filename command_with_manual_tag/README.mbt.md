# Yoorkin/command

`command` uses `extenum` to model extensible managed effects. Package authors
define commands and register runtime-specific behavior through a `Handler`. If
the handler is public, downstream users can override it with `on_execute`.

```mbt nocheck
// in @http:

///|
pub extenum @command.Payload += {
  Get(String)
  Post(String, String)
}

///|
pub let handler : @command.Handler = @command.register(
  from_json=fn(json) {
    match json {
      { "method": "GET", "url": String(url), .. } => Get(url)
      { "method": "POST", "url": String(url), "body": String(body), .. } =>
        Post(url, body)
      _ => panic()
    }
  },
  to_json=fn(p) {
    match p {
      Get(url) => { "method": "GET", "url": url }
      Post(url, body) => { "method": "POST", "url": url, "body": body }
      _ => panic()
    }
  },
)

///|
fn init {
  handler.on_execute(fn(c) {
    match c {
      Get(url) => ...
      Post(url, body) => ...
      _ => panic()
    }
  })
}

///|
pub fn get(url : String) -> @command.Cmd {
  handler.create(Get(url))
}

///|
pub fn post(url : String, body : String) -> @command.Cmd {
  handler.create(Post(url, body))
}
```

Downstream users can replace the exported handler:

```mbt nocheck
@http.handler.on_execute(custom_http_handler)
```
