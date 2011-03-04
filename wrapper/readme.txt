This is a quick-and-dirty, but hopefully useful Lua wrapper for libtcod. It has been adapted from donblas's SWIG wrapper.

To use it, you need to have 
 - libtcodlua dynamic library in your Lua package.cpath
 - tcod.lua in your Lua package.path
 - libtcod libraries (including the libtcodxx under Linux) in your system path (LD_LIBRARY_PATH under Linux)
 
(Having the relevant files in your current directory satisfies the first two conditions).

Then just "require 'tcod'". Look into api.txt for a list of library names, and of course read the libtcod documentation. Most functions also give helpful SWIG-generated messages when called with wrong parameters.

Callback support for tcod.line and tcod.path is experimental. To use it, you have to create a tcod.path.Callback / tcod.line.Listener from your function:
  
  local listener = tcod.line.Listener(function(x,y) ... end)
  tcod.line.line(..., listener)

Due to complications with memory management, you MUST ENSURE that the listener object is alive during the libtcod call. Put it into a local variable, table field, anything: I'm not sure, but I think that in some cases "tcod.line.line(..., tcod.line.Listener(...))" may cause Lua to GC the whole callback object prematurely, crashing your program.

  hmp <humpolec@gmail.com>
