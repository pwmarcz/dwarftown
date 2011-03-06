package.path = package.path .. ';src/?.lua;src/?/init.lua;wrapper/?.lua'

require 'game'
require 'mapgen'
require 'mapgen.tetris'
require 'mapgen.cell'

local args = {...}

function main()
   if args[1] == 'mapgen' then
      mapgen.tetris.test()
      mapgen.cell.test()
   else
      if args[1] == 'wizard' then
         game.wizard = true
      end
      game.init()
      game.mainLoop()
   end
end

function handler(message)
   s = message .. '\n' .. debug.traceback()
   f = io.open('log.txt', 'w')
   f:write(s)
   print(s)
   return true
end

xpcall(main, handler)
