package.path = package.path .. ';src/?.lua;wrapper/?.lua'

require 'game'
require 'mapgen'

args = {...}

if args[1] == 'mapgen' then
   mapgen.test()
else
   game.init()
   game.mainLoop()
end
