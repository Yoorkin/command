// Blackbox tests run against the package's public API. Use `@command` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
pub extenum @command.Payload += {
  Get(String)
  Post(String, String)
}

///|
let handler : @command.Handler = @command.register(
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
#cfg(target="js")
fn init {
  handler.on_execute(fn(c) {
    match c {
      Get(url) => ... // js fetch
      Post(url, body) => ... // js fetch
      _ => panic()
    }
  })
}

///|
#cfg(target="native")
fn init {
  handler.on_execute(fn(c) {
    match c {
      Get(url) => ... // @async.get
      Post(url, body) => ... // @async.post
      _ => panic()
    }
  })
}

///|
pub fn get(url : String) -> Cmd {
  handler.create(Get(url))
}

///|
pub fn post(url : String, body : String) -> Cmd {
  handler.create(Post(url, body))
}

///|
test {
  json_inspect(get("api/v0"), content={
    "id": { "gen": 0, "idx": 0 },
    "payload": { "method": "GET", "url": "api/v0" },
  })
  json_inspect(post("api/v0", "text"), content={
    "id": { "gen": 0, "idx": 0 },
    "payload": { "method": "POST", "url": "api/v0", "body": "text" },
  })
}
