#!/usr/bin/lua

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
local class = require( "class" )

local A = class "A"
function A:__init()
  print( "A:__init()", self )
end
function A:method1()
  print( "A:method1()" )
end
function A:method5()
  print( "A:method5()" )
end

local B = class( "B", A )
function B:__init()
  A.__init( self )
  print( "B:__init()", self )
end
function B:method2()
  print( "B:method2()" )
end
function B:method6()
  print( "B:method6()" )
end

local C = class "C"
function C:__init()
  print( "C:__init()", self )
end
function C:method3()
  print( "C:method3()" )
end
function C:method5()
  print( "C:method5()" )
end
function C:method6()
  print( "C:method6()" )
end

local D = class( "D", B, C )
function D:__init()
  B.__init( self )
  C.__init( self )
  print( "D:__init()", self )
end
function D:method4()
  print( "D:method4()" )
end

print( "testing A" )
local a = A()
print( class.name( A ), class.name( a ), class.of( a ) == A )
print( "a is_a A?", class.is_a( a, A ) )
a:method1()
a:method5()

print( "testing B" )
local b = B()
print( class.name( B ), class.name( b ), class.of( b ) == B )
print( "b is_a B?", class.is_a( b, B ) )
print( "b is_a A?", class.is_a( b, A ) )
b:method1()
b:method2()
b:method5()
b:method6()

print( "testing C" )
local c = C()
print( class.name( C ), class.name( c ), class.of( c ) == C )
print( "c is_a C?", class.is_a( c, C ) )
print( "c is_a B?", class.is_a( c, B ) )
print( "C is_a C?", class.is_a( C, C ) )
print( "C is_a B?", class.is_a( C, B ) )
c:method3()
c:method5()
c:method6()

print( "testing D" )
local d = D()
print( class.name( D ), class.name( d ), class.of( d ) == D )
print( "d is_a D?", class.is_a( d, D ) )
print( "d is_a C?", class.is_a( d, C ) )
print( "d is_a B?", class.is_a( d, B ) )
print( "d is_a A?", class.is_a( d, A ) )
d:method1()
d:method2()
d:method3()
d:method4()
print( "should be C:method5():" )
d:method5()
print( "should be B:method6():" )
d:method6()

do
  local temp = C.method5
  C.method5 = nil
  print( "should be A:method5():" )
  d:method5()
  C.method5 = temp
  print( "should be C:method5() again:" )
  d:method5()
end

do
  local temp = B.method6
  B.method6 = nil
  print( "should be C:method6():" )
  d:method6()
  B.method6 = temp
  print( "should be B:method6() again:" )
  d:method6()
end

function D:method1()
  print( "D:method1()" )
end
print( "should be D:method1()" )
d:method1()
print( "should be A:method1()" )
a:method1()

local E = class( "E", D )
print( "E.__init should be nil:", E.__init )
print( "testing E" )
local e = E()
print( class.name( E ), class.name( e ), class.of( e ) == E )
print( "e is_a E?", class.is_a( e, E ) )
print( "e is_a D?", class.is_a( e, D ) )

local F = class( "F", E )
function E:__init( id )
  D.__init( self )
  self.id = id
  print( "E:__init()", self, id )
end
print( "F.__init should be nil:", F.__init )
print( "testing F" )
local f = F()
print( class.name( F ), class.name( f ), class.of( f ) == F )
print( "f is_a F?", class.is_a( f, F ) )
print( "f is_a E?", class.is_a( f, E ) )

print( "testing __add metamethod for class E" )
function E.__add( a, b )
  print( "E + E" )
  return E( a.id + b.id )
end
local e1, e2 = E( 1 ), E( 2 )
local e3 = e1 + e2
print( "e3.id =", e3.id )

print( "testing class casting (cast f to E)" )
class.cast( f, E )
print( class.name( E ), class.name( f ), class.of( f ) == E )
print( "f is_a F?", class.is_a( f, F ) )
print( "f is_a E?", class.is_a( f, E ) )
f.id = 4
local e5 = e1 + f
print( "e5.id =", e5.id )

print( "methods in E" )
for k,v in pairs( E ) do
  print( k, v )
end

print( "method delegation" )
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

print( x1:get_a(), x2:get_a(), P:get_a() )
x1:set_a( 2 )
print( x1:get_a(), x2:get_a(), P:get_a() )

