// Blackbox tests run against the package's public API. Use `@command` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

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
test {
  json_inspect(get("api/v0"), content={
    "tag": 0,
    "payload": { "method": "GET", "url": "api/v0" },
  })
  json_inspect(post("api/v0", "text"), content={
    "tag": 1,
    "payload": { "method": "POST", "url": "api/v0", "body": "text" },
  })

  handler.to_json(p => {
    guard p is Post(url, _) else { raise @command.Unhandled }
    { "method": "POST", "url": url, "body": "..." }
  })

  json_inspect(get("api/v0"), content={
    "tag": 0,
    "payload": { "method": "GET", "url": "api/v0" },
  })
  json_inspect(post("api/v0", "TOKEN"), content={
    "tag": 1,
    "payload": { "method": "POST", "url": "api/v0", "body": "..." },
  })
}

///|
pub fn get(url : String) -> @command.Cmd {
  Get(url)
}

///|
pub fn post(url : String, body : String) -> @command.Cmd {
  Post(url, body)
}
