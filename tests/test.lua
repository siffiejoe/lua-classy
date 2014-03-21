#!/usr/bin/env lua

-- inheritance tree:
--       F
--       |
--       E
--       |
--       D
--      / \
--     B   C
--     |
--     A

package.path = "../src/?.lua;" .. package.path
local class = require( "classy" )

local function dprint( ... ) end
--dprint = print -- uncomment for debug output

local A = class "A"
function A:__init()
  self.A = true
  dprint( "A:__init()", self )
end
function A:method1()
  dprint( "A:method1()" )
  return "A:method1()"
end
function A:method5()
  dprint( "A:method5()" )
  return "A:method5()"
end

local B = class( "B", A )
function B:__init()
  A.__init( self )
  self.B = true
  dprint( "B:__init()", self )
end
function B:method2()
  dprint( "B:method2()" )
  return "B:method2()"
end
function B:method6()
  dprint( "B:method6()" )
  return "B:method6()"
end

local C = class "C"
function C:__init()
  self.C = true
  dprint( "C:__init()", self )
end
function C:method3()
  dprint( "C:method3()" )
  return "C:method3()"
end
function C:method5()
  dprint( "C:method5()" )
  return "C:method5()"
end
function C:method6()
  dprint( "C:method6()" )
  return "C:method6()"
end

local D = class( "D", B, C )
function D:__init()
  B.__init( self )
  C.__init( self )
  self.D = true
  dprint( "D:__init()", self )
end
function D:method4()
  dprint( "D:method4()" )
  return "D:method4()"
end

print( "testing non-class parameters" )
assert( class.name( nil ) == nil )
assert( class.of( nil ) == nil )
assert( class.is_a( nil, A ) == nil )
assert( class.name( {} ) == nil )
assert( class.of( {} ) == nil )
assert( class.is_a( {}, A ) == nil )

print( "testing A" )
local a = A()
assert( a.A )
assert( class.name( A ) == "A" )
assert( class.name( a ) == "A" )
assert( class.of( a ) == A )
assert( class.is_a( a, A ) == 0 )
assert( a:method1() == "A:method1()" )
assert( a:method5() == "A:method5()" )

print( "testing B" )
local b = B()
assert( b.B )
assert( b.A )
assert( class.name( B ) == "B" )
assert( class.name( b ) == "B" )
assert( class.of( b ) == B )
assert( class.is_a( b, B ) == 0 )
assert( class.is_a( b, A ) == 1 )
assert( b:method1() == "A:method1()" )
assert( b:method2() == "B:method2()" )
assert( b:method5() == "A:method5()" )
assert( b:method6() == "B:method6()" )

print( "testing C" )
local c = C()
assert( c.C )
assert( class.name( C ) == "C" )
assert( class.name( c ) == "C" )
assert( class.of( c ) == C )
assert( class.is_a( c, C ) == 0 )
assert( not class.is_a( c, B ) )
assert( class.is_a( C, C ) == 0 )
assert( not class.is_a( C, B ) )
assert( c:method3() == "C:method3()" )
assert( c:method5() == "C:method5()" )
assert( c:method6() == "C:method6()" )

print( "testing D" )
local d = D()
assert( d.D )
assert( d.C )
assert( d.B )
assert( d.A )
assert( class.name( D ) == "D" )
assert( class.name( d ) == "D" )
assert( class.of( d ) == D )
assert( class.is_a( d, D ) == 0 )
assert( class.is_a( d, C ) == 1 )
assert( class.is_a( d, B ) == 1 )
assert( class.is_a( d, A ) == 2 )
assert( d:method1() == "A:method1()" )
assert( d:method2() == "B:method2()" )
assert( d:method3() == "C:method3()" )
assert( d:method4() == "D:method4()" )
assert( d:method5() == "C:method5()" )
assert( d:method6() == "B:method6()" )

do
  local temp = C.method5
  C.method5 = nil
  assert( d:method5() == "A:method5()" )
  C.method5 = temp
  assert( d:method5() == "C:method5()" )
end

do
  local temp = B.method6
  B.method6 = nil
  assert( d:method6() == "C:method6()" )
  B.method6 = temp
  assert( d:method6() == "B:method6()" )
end

function D:method1()
  dprint( "D:method1()" )
  return "D:method1()"
end
assert( d:method1() == "D:method1()" )
assert( a:method1() == "A:method1()" )

local E = class( "E", D )
assert( E.__init == nil )
print( "testing E" )
local e = E()
assert( not e.D )
assert( class.name( E ) == "E" )
assert( class.name( e ) == "E" )
assert( class.of( e ) == E )
assert( class.is_a( e, E ) == 0 )
assert( class.is_a( e, D ) == 1 )
assert( class.is_a( e, C ) == 2 )
assert( class.is_a( e, B ) == 2 )
assert( class.is_a( e, A ) == 3 )

local F = class( "F", E )
function E:__init( id )
  D.__init( self )
  self.E = true
  self.id = id
  dprint( "E:__init()", self, id )
end
assert( F.__init == nil )
print( "testing F" )
local f = F()
assert( not f.F )
assert( not f.E )
assert( class.name( F ) == "F" )
assert( class.name( f ) == "F" )
assert( class.of( f ) == F )
assert( class.is_a( f, F ) == 0 )
assert( class.is_a( f, E ) == 1 )
assert( class.is_a( f, D ) == 2 )
assert( class.is_a( f, C ) == 3 )
assert( class.is_a( f, B ) == 3 )
assert( class.is_a( f, A ) == 4 )

print( "testing __add metamethod for class E" )
function E.__add( a, b )
  dprint( "E + E" )
  return E( a.id + b.id )
end
local e1, e2 = E( 1 ), E( 2 )
local e3 = e1 + e2
assert( e1.E )
assert( e1.D )
assert( e2.E )
assert( e2.D )
assert( e3.id == 3 )
assert( e3.E )
assert( e3.D )

print( "testing class casting (cast f to E)" )
class.cast( f, E )
assert( class.name( f ) == "E" )
assert( class.of( f ) == E )
assert( not class.is_a( f, F ) )
assert( class.is_a( f, E ) == 0 )
assert( class.is_a( f, D ) == 1 )
f.id = 4
local e5 = e1 + f
assert( e5.E )
assert( e5.D )
assert( e5.id == 5 )

print( "listing methods in E (only works in Lua 5.2 and up)" )
for k,v in pairs( E ) do
  print( "", k, v )
end

print( "testing method delegation" )
local P = {
  a = 1,
  set_a = function( self, v )
    self.a = v
  end,
  get_a = function( self )
    return self.a
  end
}

local X = class "X"
class.delegate( X, "p", "set_a", "get_a" )

function X:__init()
  self.p = P
end

local x1 = X()
local x2 = X()

assert( x1:get_a() == 1 )
assert( x2:get_a() == 1 )
assert( P:get_a() == 1 )
x1:set_a( 2 )
assert( x1:get_a() == 2 )
assert( x2:get_a() == 2 )
assert( P:get_a() == 2 )

print( "testing multimethods" )
local mm = class.multimethod( 1, 3 )
dprint( pcall( mm, a, b, c ) )
--mm( a, b, c )  -- for figuring out error stack levels
assert( not pcall( mm, a, b, c ) )
class.overload( mm, "string", io.type, "file", function( a, _, b )
  dprint( "func(string,_,file):", a, b )
  return "string,file"
end )
assert( mm( "xy", nil, io.stdout ) == "string,file" )
dprint( pcall( mm, 1, nil, io.stdout ) )
--mm( 1, nil, io.stdout ) -- for figuring out error stack levels
assert( not pcall( mm, 1, nil, io.stdout ) )
dprint( pcall( mm, "xy", nil, nil ) )
--mm( "xy", nil, nil ) -- for figuring out error stack levels
assert( not pcall( mm, "xy", nil, nil ) )
class.overload( mm, B, E, function( a, _, b )
  dprint( "func(B,_,E):", a, b )
  return "B,E"
end )
assert( mm( "xy", nil, io.stdout ) == "string,file" )
assert( mm( b, nil, e ) == "B,E" )
assert( mm( e, nil, e ) == "B,E" )
class.overload( mm, E, E, function( a, _, b )
  dprint( "func(E,_,E):", a, b )
  return "E,E"
end )
assert( mm( b, nil, e ) == "B,E" )
assert( mm( d, nil, e ) == "B,E" )
assert( mm( e, nil, e ) == "E,E" )
class.overload( mm, C, E, function( a, _, b )
  dprint( "func(C,_,E):", a, b )
  return "C,E"
end )
assert( mm( b, nil, e ) == "B,E" )
assert( mm( c, nil, e ) == "C,E" )
assert( mm( e, nil, e ) == "E,E" )
dprint( pcall( mm, d, nil, e ) )
--mm( d, nil, e ) -- for figuring out error stack levels
assert( not pcall( mm, d, nil, e ) )
class.overload( mm, B, "number", function( a, _, b )
  dprint( "func(B,_,number):", a, b )
  return "B,number"
end )
class.overload( mm, A, "number", function( a, _, b )
  dprint( "func(A,_,number):", a, b )
  return "A,number"
end )
assert( mm( a, nil, 1 ) == "A,number" )
assert( mm( b, nil, 1 ) == "B,number" )
assert( mm( d, nil, 1 ) == "B,number" )
assert( mm( "xy", nil, io.stdout ) == "string,file" )
assert( mm( b, nil, e ) == "B,E" )
assert( mm( c, nil, e ) == "C,E" )
assert( mm( e, nil, e ) == "E,E" )

print( "ok" )

