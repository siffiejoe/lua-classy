-- class-based OO module for Lua

-- cache globals
local assert = assert
local _V = assert( _VERSION )
local setmetatable = assert( setmetatable )
local select = assert( select )
local pairs = assert( pairs )
local ipairs = assert( ipairs )
local next = assert( next )
local type = assert( type )
local error = assert( error )
local loadstring = assert( _V == "Lua 5.1" and loadstring or load )
local table = table
assert( type( table ) == "table" )
local string = string
assert( type( string ) == "table" )
local s_rep = assert( string.rep )
local t_concat = assert( table.concat )
local t_unpack = assert( _V == "Lua 5.1" and unpack or table.unpack )



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
--   -- a set of subclasses (value is "inheritance difference")
--   sub = { [ subcls1 ] = 1, [ subcls2 ] = 2 }, -- mode="k"
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
-- iteration (similar to a binary heap); also set the "inheritance
-- difference" in superclasses
local function linearize_ancestors( cls, super, ... )
  local n = select( '#', ... )
  for i = 1, n do
    local pcls = select( i, ... )
    assert( classinfo[ pcls ], "invalid class" )
    super[ i ] = pcls
  end
  super.n = n
  local diff, newn = 1, n
  for i,p in ipairs( super ) do
    local pinfo = classinfo[ p ]
    local psuper, psub = pinfo.super, pinfo.sub
    if not psub[ cls ] then psub[ cls ] = diff end
    for i = 1, psuper.n do
      super[ #super+1 ] = psuper[ i ]
    end
    newn = newn + psuper.n
    if i == n then
      n, diff = newn, diff+1
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
  linearize_ancestors( cls, info.super, ... )
  for i = #info.super, 1, -1 do
    for k,v in pairs( classinfo[ info.super[ i ] ].members ) do
      if k ~= "__init" then
        index[ k ] = v
      end
    end
  end
  classinfo[ cls ] = info
  return setmetatable( cls, info.c_meta )
end


-- the exported class module
local M = {}
setmetatable( M, { __call = create_class } )


-- returns the class of an object
function M.of( o )
  if o == nil then return nil end
  return instance2class[ o ]
end


-- returns the class name of an object or class
function M.name( oc )
  if oc == nil then return nil end
  oc = instance2class[ oc ] or oc
  local info = classinfo[ oc ]
  return info and info.name
end


-- checks if an object or class is in an inheritance
-- relationship with a given class
function M.is_a( oc, cls )
  if oc == nil then return nil end
  local info = assert( classinfo[ cls ], "invalid class" )
  oc = instance2class[ oc ] or oc
  if oc == cls then
    return 0
  end
  return info.sub[ oc ]
end


-- change the type of an object to the new class
function M.cast( o, newcls )
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
function M.delegate( cls, fieldname, ... )
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


-- multimethod stuff
do
  local MM = {}

  local errlvl = 3
  if _V == "Lua 5.1" then
    errlvl = 4
  end
  local function no_candidate2()
    error( "no matching multimethod overload", 2 )
  end
  local function no_candidate3()
    error( "no matching multimethod overload", errlvl )
  end

  local empty = {}   -- just an empty table used as dummy
  local FIRST_OL = 5 -- index of first overload specification


  -- create a multimethod using the parameter indices given
  -- as arguments for dynamic dispatch
  function M.multimethod( ... )
    local t, n = { ... }, select( '#', ... )
    assert( n >= 1, "no polymorphic parameter for multimethod" )
    local max = 0
    for i = 1, n do
      local x = t[ i ]
      max = assert( x > max and x % 1 == 0 and x,
                    "invalid parameter overload specification" )
    end
    local meta = {
      __index = MM,
      __call = no_candidate2,
    }
    return setmetatable( { t, max, meta, false }, meta )
  end


  -- clear all cached multimethod lookups
  function MM:clearcache()
    self[ 4 ] = {}
    return self
  end


  -- remove all registered overloads for this multimethod
  function MM:reset()
    self[ 3 ].__call = no_candidate2
    for i = #self, FIRST_OL, -1 do
      self[ i ] = nil
    end
    self[ 4 ] = {}
    return self
  end


  local function calculate_cost( ol, ... )
    local c, n = 0, select( '#', ... )
    for i = 1, n do
      local a, pt = ol[ i ], select( i, ... )
      local t = type( a )
      if t == "table" then -- class table
        local diff = (pt == a) and 0 or classinfo[ a ].sub[ pt ]
        if not diff then return nil end
        c = c + diff
      else -- type name
        if pt ~= a then return nil end
      end
    end
    return c
  end


  local function collect_type_checkers( mm, a )
    local funcs = {}, {}
    for i = FIRST_OL, #mm do
      local ol = mm[ i ]
      for k,v in next, ol do
        if type( k ) == "function" and
           (a == nil or v[ a ]) and
           not funcs[ k ] then
          local j = #funcs+1
          funcs[ j ] = k
          funcs[ k ] = j
        end
      end
    end
    return funcs
  end


  local function c_varlist( t, m, prefix )
    local n = #t
    if m >= 1 then
      t[ n+1 ] = prefix
      t[ n+2 ] = 1
    end
    for i = 2, m do
      local j = i*3+n
      t[ j-3 ] = ","
      t[ j-2 ] = prefix
      t[ j-1 ] = i
    end
  end

  local function c_typecheck( t, mm, funcs, j )
    local n, ai = #t, mm[ 1 ][ j ]
    t[ n+1 ] = "  local i"
    t[ n+2 ] = j
    t[ n+3 ] = "=(_"
    t[ n+4 ] = ai
    t[ n+5 ] = "~=nil and i2c[_"
    t[ n+6 ] = ai
    t[ n+7 ] = "]) or "
    local ltcs = collect_type_checkers( mm, j )
    local m = #ltcs
    for i = 1, m do
      local k = i*5+n+3
      t[ k ] = "tc"
      t[ k+1 ] = funcs[ ltcs[ i ] ]
      t[ k+2 ] = "(_"
      t[ k+3 ] = ai
      t[ k+4 ] = ") or "
    end
    n = m*5+n+8
    t[ n ] = "type(_"
    t[ n+1 ] = ai
    t[ n+2 ] = ")\n"
  end

  local function c_cache( t, mm )
    local c = #mm[ 1 ]
    local n = #t
    t[ n+1 ] = s_rep( "(", c-1 )
    t[ n+2 ] = "mm[4]"
    for i = 1, c-1 do
      local j = i*3+n
      t[ j ] = "[i"
      t[ j+1 ] = i
      t[ j+2 ] = "] or empty)"
    end
    local j = c*3+n
    t[ j ] = "[i"
    t[ j+1 ] = c
    t[ j+2 ] = "]"
  end

  local function c_costcheck( t, i, j )
    local n = #t
    t[ n+1 ] = "    ol,pt=mm["
    t[ n+2 ] = j+FIRST_OL-1
    t[ n+3 ] = "],i"
    t[ n+4 ] = j
    t[ n+5 ] = "\n    c=calculate_cost(ol,"
    c_varlist( t, i, "i" )
    t[ #t+1 ] = [=[)
    if c then
      if cost then
        if c < cost then
          cost,is_ambiguous,f=c,false,ol.func
        elseif c==cost then
          is_ambiguous=true
        end
      else
        cost,f=c,ol.func
      end
    end
]=]
  end

  local function c_updatecache( t, i )
    local n = #t
    t[ n+1 ] = "      if not t[i"
    t[ n+2 ] = i
    t[ n+3 ] = "] then t[i"
    t[ n+4 ] = i
    t[ n+5 ] = "]={} end\n      t=t[i"
    t[ n+6 ] = i
    t[ n+7 ] = "]\n"
  end


  local function recompile_and_call( mm, ... )
    local n = #mm[ 1 ]
    local tcs = collect_type_checkers( mm )
    local code = {
      "local i2c,empty,type,error,calculate_cost,no_candidate"
    }
    if #tcs >= 1 then
      code[ #code+1 ] = ","
    end
    c_varlist( code, #tcs, "tc" )
    code[ #code+1 ] = "=...\nreturn function(mm,"
    c_varlist( code, mm[ 2 ], "_" )
    code[ #code+1 ] = ",...)\n"
    for i = 1, n do
      c_typecheck( code, mm, tcs, i )
    end
    code[ #code+1 ] = "  local f="
    c_cache( code, mm )
    code[ #code+1 ] = [=[ --
  if f==nil then
    local is_ambiguous,cost,ol,pt,c
]=]
    for i = 1, #mm-FIRST_OL+1 do
      c_costcheck( code, n, i )
    end
    code[ #code+1 ] = [=[
    if f==nil then
      no_candidate()
    elseif is_ambiguous then
      error("ambiguous multimethod call",2)
    else
      local t = mm[4]
]=]
    for i = 1, n-1 do
      c_updatecache( code, i )
    end
    code[ #code+1 ] = "      t[i"
    code[ #code+1 ] = n
    code[ #code+1 ] = "]=f\n    end\n  end\n  return f("
    c_varlist( code, mm[ 2 ], "_" )
    code[ #code+1 ] = ",...)\nend\n"
    code = t_concat( code )
    --print( code ) -- XXX
    local f = assert( loadstring( code, "[multimethod]" ) )(
      instance2class, empty, type, error, calculate_cost, no_candidate3,
      t_unpack( tcs )
    )
    mm[ 3 ].__call = f
    mm[ 4 ] = {}
    return f( mm, ... )
  end


  -- register a new overload for this multimethod
  function MM:register( ... )
    local i, n = 1, select( '#', ... )
    local ol = {}
    assert( n >= 1, "missing function in overload specification" )
    local func = select( n, ... )
    assert( type( func ) == "function",
            "missing function in overload specification" )
    while i < n do
      local a = select( i, ... )
      local t = type( a )
      if t == "string" then
        ol[ #ol+1 ] = a
      elseif t == "table" then
        assert( classinfo[ a ], "invalid class" )
        ol[ #ol+1 ] = a
      else
        assert( t == "function", "invalid overload specification" )
        i = i + 1
        assert( i < n, "missing function in overload specification" )
        ol[ a ] = ol[ a ] or {}
        ol[ #ol+1 ] = select( i, ... )
        ol[ a ][ #ol ] = true
      end
      i = i + 1
    end
    assert( #self[ 1 ] == #ol, "wrong number of overloaded parameters" )
    ol.func = func
    self[ #self+1 ] = ol
    self[ 3 ].__call = recompile_and_call
    return self
  end

end


-- return module table
return M

