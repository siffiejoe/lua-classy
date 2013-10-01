package = "class"
version = "0.1-1"
source = {
  url = "git://github.com/siffiejoe/lua-class.git",
  tag = "v0.1"
}
description = {
  summary = "A small library for class-based OO.",
  detailed = [[
    This small Lua module provides a `class' function for defining
    classes in OO programming, featuring proper multiple inheritance
    with fast method lookups.
  ]],
  homepage = "https://github.com/siffiejoe/lua-class/",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1, < 5.3"
}
build = {
  type = "builtin",
  modules = {
    class = "src/class.lua"
  }
}

