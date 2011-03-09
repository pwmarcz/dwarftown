package.path = package.path .. ';src/?.lua;src/?/init.lua;wrapper/?.lua'

require 'game'
require 'mapgen'
require 'mapgen.tree'

local args = {...}

function main()
   if args[1] == 'mapgen' then
      mapgen.tree.test()
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
os.exit(0)
