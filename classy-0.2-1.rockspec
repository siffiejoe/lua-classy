package = "classy"
version = "0.2-1"
source = {
  url = "git://github.com/siffiejoe/lua-classy.git",
  tag = "v0.2"
}
description = {
  summary = "A small library for class-based OO.",
  detailed = [[
    This small Lua module provides a `class' function for defining
    classes in OO programming, featuring proper multiple inheritance
    with fast method lookups, and multimethods.
  ]],
  homepage = "https://github.com/siffiejoe/lua-classy/",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1, < 5.3"
}
build = {
  type = "builtin",
  modules = {
    class = "src/classy.lua"
  }
}

