package.path = package.path .. ';src/?.lua;src/?/init.lua;wrapper/?.lua'

require 'game'
require 'mapgen'
require 'mapgen.tetris'
require 'mapgen.cell'

args = {...}

if args[1] == 'mapgen' then
   mapgen.tetris.test()
   mapgen.cell.test()
else
   game.init()
   game.mainLoop()
end
