// Blackbox tests run against the package's public API. Use `@command` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
pub extenum @command.Payload += {
  Get(String)
  Post(String, String)
}

///|
let handler : @command.Handler = @command.register()

///|
fn init {
  handler
  ..from_json(json => {
    match json {
      { "method": "GET", "url": String(url), .. } => Get(url)
      { "method": "POST", "url": String(url), "body": String(body), .. } =>
        Post(url, body)
      _ => raise @command.Unhandled
    }
  })
  ..to_json(payload => {
    match payload {
      Get(url) => { "method": "GET", "url": url }
      Post(url, body) => { "method": "POST", "url": url, "body": body }
      _ => raise @command.Unhandled
    }
  })
  .execute(payload => {
    match payload {
      Get(url) => ... // @async.get
      Post(url, body) => ... // @async.post
      _ => raise @command.Unhandled
    }
  })
}

///|
pub fn get(url : String) -> @command.Cmd {
  handler.request(Get(url))
}

///|
pub fn post(url : String, body : String) -> @command.Cmd {
  handler.request(Post(url, body))
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

  handler.to_json(p => {
    guard p is Post(url, _) else { raise @command.Unhandled }
    { "method": "POST", "url": url, "body": "..." }
  })

  json_inspect(get("api/v0"), content={
    "id": { "gen": 0, "idx": 0 },
    "payload": { "method": "GET", "url": "api/v0" },
  })
  json_inspect(post("api/v0", "TOKEN"), content={
    "id": { "gen": 0, "idx": 0 },
    "payload": { "method": "POST", "url": "api/v0", "body": "..." },
  })
}
