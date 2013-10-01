-- class-based OO module for Lua

-- cache globals
local assert = assert
local setmetatable = assert( setmetatable )
local select = assert( select )
local pairs = assert( pairs )
local ipairs = assert( ipairs )
local type = assert( type )


-- list of all metamethods that a user of this library is allowed to
-- add to a class
local allowed_metamethods = {
  __add = true, __sub = true, __mul = true, __div = true,
  __mod = true, __pow = true, __unm = true, __concat = true,
  __len = true, __eq = true, __lt = true, __le = true, __call = true,
  __tostring = true, __pairs = true, __ipairs = true, __gc = true,
  __newindex = true,
}

-- this metatable is (re-)used often:
local mode_k_meta = { __mode = "k" }

-- store information for every registered class (still in use)
-- [ cls ] = {
--   -- the name of the class
--   name = "clsname",
--   -- an array of superclasses in an order suitable for method
--   -- lookup, the first n are direct superclasses (parents)
--   super = { n = 2, super1, super2, super1_1, super1_2 },
--   -- a set of subclasses
--   sub = { [ subcls1 ] = true, [ subcls2 ] = true }, -- mode="k"
--   -- direct member functions/variables for this class
--   members = {},
--   -- the metatable for objects of this class
--   o_meta = { __index = {} },
--   -- the metatable for the class itself
--   c_meta = { __index = ..., __call = ..., __newindex = ... },
-- }
local classinfo = setmetatable( {}, mode_k_meta )
-- store class for every created object
local instance2class = setmetatable( {}, mode_k_meta )


-- object constructor for the class if no custom __init function is
-- defined
local function default_constructor( cls )
  local o = {}
  instance2class[ o ] = cls
  return setmetatable( o, classinfo[ cls ].o_meta )
end

-- object constructor for the class if a custom __init function is
-- available
local function init_constructor( cls, ... )
  local info = classinfo[ cls ]
  local o = {}
  instance2class[ o ] = cls
  setmetatable( o, info.o_meta )
  info.members.__init( o, ... )
  return o
end


-- propagate a changed method to a sub class
local function propagate_update( cls, key )
  local info = classinfo[ cls ]
  if info.members[ key ] ~= nil then
    info.o_meta.__index[ key ] = info.members[ key ]
  else
    for i = 1, #info.super do
      local val = classinfo[ info.super[ i ] ].members[ key ]
      if val ~= nil then
        info.o_meta.__index[ key ] = val
        return
      end
    end
    info.o_meta.__index[ key ] = nil
  end
end


-- __newindex handler for class proxy tables, allowing to set certain
-- metamethods, initializers, and normal members. updates sub classes!
local function class_newindex( cls, key, val )
  local info = classinfo[ cls ]
  if allowed_metamethods[ key ] and type( val ) == "function" then
    assert( info.o_meta[ key ] == nil,
            "overwriting metamethods not allowed" )
    info.o_meta[ key ] = val
  elseif key == "__init" then
    info.members.__init = val
    info.o_meta.__index.__init = val
    if type( val ) == "function" then
      info.c_meta.__call = init_constructor
    else
      info.c_meta.__call = default_constructor
    end
  else
    info.members[ key ] = val
    propagate_update( cls, key )
    for sub in pairs( info.sub ) do
      propagate_update( sub, key )
    end
  end
end


-- __pairs/__ipairs metamethods for iterating members of classes
local function class_pairs( cls )
  return pairs( classinfo[ cls ].o_meta.__index )
end

local function class_ipairs( cls )
  return ipairs( classinfo[ cls ].o_meta.__index )
end


-- put the inheritance tree into a flat array using a width-first
-- iteration (similar to a binary heap)
local function linearize_ancestors( super, ... )
  for i = 1, select( '#', ... ) do
    local pcls = select( i, ... )
    assert( classinfo[ pcls ], "invalid class" )
    super.n = i
    super[ i ] = pcls
  end
  for i,p in ipairs( super ) do
    local psuper = classinfo[ p ].super
    for i = 1, psuper.n do
      super[ #super+1 ] = psuper[ i ]
    end
  end
end


-- create the necessary metadata for the class, setup the inheritance
-- hierarchy, set a suitable metatable, and return the class
local function create_class( _, name, ... )
  assert( type( name ) == "string", "class name must be a string" )
  local cls, index = {}, {}
  local info = {
    name = name,
    super = { n = 0 },
    sub = setmetatable( {}, mode_k_meta ),
    members = {},
    o_meta = {
      __index = index,
    },
    c_meta = {
      __index = index,
      __newindex =  class_newindex,
      __call = default_constructor,
      __pairs = class_pairs,
      __ipairs = class_ipairs,
      __metatable = false,
    },
  }
  linearize_ancestors( info.super, ... )
  for i = #info.super, 1, -1 do
    local s_info = classinfo[ info.super[ i ] ]
    s_info.sub[ cls ] = true
    for k,v in pairs( s_info.members ) do
      if k ~= "__init" then
        index[ k ] = v
      end
    end
  end
  classinfo[ cls ] = info
  return setmetatable( cls, info.c_meta )
end


-- the exported class module
local class = {}
setmetatable( class, { __call = create_class } )


-- returns the class of an object
function class.of( o )
  return instance2class[ o ]
end


-- returns the class name of an object or class
function class.name( oc )
  oc = instance2class[ oc ] or oc
  local info = classinfo[ oc ]
  return info and info.name
end


-- checks if an object or class is in an inheritance
-- relationship with a given class
function class.is_a( oc, cls )
  local info = assert( classinfo[ cls ], "invalid class" )
  oc = instance2class[ oc ] or oc
  if oc == cls then
    return true
  end
  return info.sub[ oc ] or false
end


-- change the type of an object to the new class
function class.cast( o, newcls )
  local info = assert( classinfo[ newcls ], "invalid class" )
  setmetatable( o, info.o_meta )
  instance2class[ o ] = newcls
  return o
end


local function make_delegate( cls, field, method )
  cls[ method ] = function( self, ... )
    local obj = self[ field ]
    return obj[ method ]( obj, ... )
  end
end

-- create delegation methods
function class.delegate( cls, fieldname, ... )
  if type( (...) ) == "table" then
    for k,v in pairs( (...) ) do
      if cls[ k ] == nil and k ~= "__init" and
         type( v ) == "function" then
        make_delegate( cls, fieldname, k )
      end
    end
  else
    for i = 1, select( '#', ... ) do
      local k = select( i, ... )
      if cls[ k ] == nil and k ~= "__init" then
        make_delegate( cls, fieldname, k )
      end
    end
  end
  return cls
end


-- return class module
return class

