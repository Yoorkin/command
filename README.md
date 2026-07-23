# Yoorkin/command

`command` uses `extenum` to model extensible managed effects. Effect packages
define commands and install environment-specific handlers. They may expose an
extension point so downstream packages can prepend overrides; `Unhandled`
delegates to the previous handler.

## Implementations

- [`command_with_manual_tag`](./command_with_manual_tag/) keeps the effect
  identity in a private `Token`.
- [`command_with_unsafe_tag`](./command_with_unsafe_tag/) makes `Cmd` itself
  extensible and finds its `Handler` through the runtime object tag. Its API is
  more direct, but it depends on unstable runtime details.

Both implementations include an HTTP example.
