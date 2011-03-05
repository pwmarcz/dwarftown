package.path = package.path .. ';src/?.lua;src/?/init.lua;wrapper/?.lua'

require 'game'
require 'mapgen'
require 'mapgen.tetris'

args = {...}

if args[1] == 'mapgen' then
   mapgen.tetris.test()
else
   game.init()
   game.mainLoop()
end
