#!/usr/bin/env lua

package.path = "../src/?.lua;" .. package.path
local class = require( "classy" )

local Shape = class( "Shape" )
local Rectangle = class( "Rectangle", Shape )
local Square = class( "Square", Rectangle )
local Circle = class( "Circle", Shape )

local rect = Rectangle()
local sq = Square()
local circ = Circle()

local intersect = class.multimethod( 1, 2 )
class.overload( intersect, Rectangle, Rectangle, function( x, y )
  print( "Rectangle - Rectangle intersection" )
end )

class.overload( intersect, Circle, Circle, function( x, y )
  print( "Circle - Circle intersection" )
end )

class.overload( intersect, Rectangle, Circle, function( x, y )
  print( "Rectangle - Circle intersection" )
end )

intersect( rect, rect )
intersect( circ, circ )
intersect( rect, circ )
intersect( rect, sq )
intersect( sq, rect )
intersect( sq, circ )

