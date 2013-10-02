#         Class -- Lua Module for Class-Based OO Programming         #

##                           Introduction                           ##

Lua doesn't have classes and objects builtin, but provides mechanisms
to define your own helper functions for object oriented programming.
Many Lua programmers have done so, this module is one such attempt.

Features:

*   Simple object layout

    The objects are just tables with a common metatable per class for
    looking up methods. All instance variables are stored in the
    object table, and there are no `__index`-chains for inheritance.
    Therefore, there is very little overhead (both runtime, and
    memory).

*   Multiple inheritance

    A class can inherit from multiple base classes. The inherited
    methods are looked up in width first search order at class
    creation time (or when a base class is updated).

*   Simple object construction

    A `__call` metamethod is added to the class table so that an
    object can be created with something looking like a simple
    function call. You can define a constructor method which is called
    during object construction.

*   Easy definition of (meta-)methods

    Storing a new field in the class table will make it available in
    objects of this class and all derived classes. If the new field
    name is one of the valid metatable keys, the function is stored in
    the object's metatable instead. Only adding previously undefined
    metamethods is allowed this way, however (no overwriting of
    existing ones). So you can add *new* operator overloads to objects
    without direct access to their metatable.

*   Common utility functions

    The module provides common utility functions, for e.g. detecting
    the class of an object, or figuring out if a class inherits from a
    certain other class.


##                          Getting Started                         ##

This module doesn't set any global variables, so you have to store the
return value of `require` somewhere, e.g. a local variable `class`.

```lua
local class = require( "class" )
```

Result of the call to `require` is a [functable][1], a table that can
also be called like a function. The function call syntax is used for
defining classes, while the table holds the helper functions defined
by this OO module.

```lua
local SomeClass = class( "SomeClass" )
print( class.name( SomeClass ) )                 -->  SomeClass

local AnotherClass = class( "AnotherClass", SomeClass )
print( class.is_a( AnotherClass, SomeClass ) )   -->  true
```

When defining a class, the first argument is the class name, that can
be queried for a class/object table later using the `class.name()`
function. Additional arguments are base classes, which must be class
tables returned by previous calls to this module.

The resulting class tables have `__call` metamethods defined, so that
you can create an object of a class using function call syntax. You
can define methods simply by storing a function in the class table. Of
course, the usual colon-syntax is supported. If the class has an
`__init` method defined, this method is called during construction of
an object with the object as first argument, and any additional
arguments given to the call of the class table. The `__init` method is
never inherited by sub-classes, but you can of course call it via the
class table (e.g. in the constructor of a sub-class).

```lua
function SomeClass:__init( a, b )
  self.a, self.b = a, b
end

function AnotherClass:__init( a, b, c )
  SomeClass.__init( self, a, b )
  self.c = c
end

function AnotherClass:print()
  print( self.a, self.b, self.c )
end

local anObject = AnotherClass( 1, 2, 3 )
anObject:print()                     -->  1       2       3
```

Creating classes and defining methods (especially on classes deep down
the inheritance hierarchy) involve some bookkeeping, so that object
construction and method lookup on objects can be fast.

Adding methods to base classes will also make them available on
objects of derived classes. Metamethods are *not* inherited, however.

```lua
function SomeClass:say_hello()
  print( "hello from " .. class.name( self ) )
end

local someObject = SomeClass( 1, 2 )
someObject:say_hello()               -->  hello from SomeClass
anObject:say_hello()                 -->  hello from AnotherClass

function SomeClass:__add( rhs )
  return SomeClass( self.a + rhs.a, self.b, rhs.b )
end

local _ = someObject + someObject    -->  ok!
local _ = anObject + anObject        -->  error!
```

You can pretty much define any metamethod except `__index` (which
is already used for inheritance), and maybe `__gc` (works on tables
starting from Lua 5.2, and only for objects created *after* the `__gc`
metamethod has been set).

If you override a method in a sub-class, and you want to call the
method of the base class, you can use the class table of the base
class for that.

```lua
function AnotherClass:say_hello()
  SomeClass.say_hello( self )
  print( "good bye" )
end

anObject:say_hello()                 -->  hello from AnotherClass
                                     -->  good bye
```

And that's basically it!

  [1]: http://lua-users.org/wiki/FuncTables


##                             Reference                            ##

####                            class()                           ####

    class( class_name [, ...] ) ==> table
        class_name: string   -- name of the class
        ...       : table*   -- class tables for base classes

Calling the result of the require call (named `class` in the above
code snippet) creates a new class table. Zero or more base classes may
be given as extra arguments after the class name. There is no general
superclass like `Object` from which all classes inherit by default!

The resulting class has a `__call` metamethod defined for constructing
objects of this class, and basically acts like a normal table, except
that fields with metamethod-names don't end up in the class table.
Iteration via `pairs()` provides all available fields of the class
(including fields of base classes), but it only works for Lua 5.2.

####                          class.of()                          ####

    class.of( object ) ==> table/nil

The `of` function returns the class table of an object, or `nil` if
the argument isn't an object created via this module.

####                         class.name()                         ####

    class.name( obj_or_cls ) ==> string/nil
        obj_or_cls: table    -- an object table or a class table

The `name` function returns the class name specified during class
definition for a given object or class. If the argument is not a class
table created using this module or an object of such a class, this
function returns `nil`.

####                         class.is_a()                         ####

    class.is_a( obj_or_cls, base ) ==> boolean
        obj_or_cls: table    -- an object table or a class table
        base      : table    -- a class table

The `is_a` function checks if a given object or class is a sub-class
of certain class.

####                         class.cast()                         ####

    class.cast( object, class ) ==> object
        class: table         -- a class table

The `cast` function changes the class of a given object (or normal
table) to the given class (it replaces the metatable) and returns the
object. No constructors are called in the process, so the object might
be in an invalid state. If you want to prevent objects of a certain
class to be casted, define a `__metatable` field in the metatable.

####                       class.delegate()                       ####

    class.delegate( class, fname [, ...] ) ==> table
        class: table         -- a class table
        fname: string        -- name of a field in the objects
        ...  : table/string* -- vararg list or array of method names

The `delegate` function creates new methods for a class that forward
to equally named methods on an object stored inside of objects of this
class. The stored object can be found via the given fieldname. The
method names to delegate can be specified as varargs or in an array.
The class table is returned.


##                              Contact                             ##

Philipp Janda, siffiejoe(a)gmx.net

Comments and feedback are always welcome (especially proposals for a
proper project name -- "class" is *way* too ambiguous given the number
of different Lua OO libraries out there).


##                              License                             ##

class is *copyrighted free software* distributed under the MIT license
(the same license as Lua 5.1). The full license text follows:

    class (c) 2013 Philipp Janda

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDER BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

