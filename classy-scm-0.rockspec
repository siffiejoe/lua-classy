package = "classy"
version = "scm-0"
source = {
  url = "git://github.com/siffiejoe/lua-classy.git",
}
description = {
  summary = "A library for class-based OO.",
  detailed = [[
    This Lua module provides a functable for defining classes in OO
    programming, featuring multiple inheritance with fast method
    lookups, and multimethods.
  ]],
  homepage = "https://github.com/siffiejoe/lua-classy/",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1, < 5.5"
}
build = {
  type = "builtin",
  modules = {
    classy = "src/classy.lua"
  }
}

