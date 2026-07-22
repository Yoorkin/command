// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Yoorkin/command"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/Yoorkin/command"

license = "Apache-2.0"

keywords = [ "command", "managed-effect", "extenum", "handler" ]

preferred_target = "native"

description = "Extensible managed effects with runtime-configurable handlers for MoonBit."

import {
  "Yoorkin/slotmap@0.2.4",
}
