--[[
  Cellular automata dungeon generator, as described by Jim Babcock at
  http://roguebasin.roguelikedevelopment.org/
  index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels
--]]

module('mapgen.cell', package.seeall)

require 'mapgen'
require 'tcod'
require 'dice'

function cellStep(room, cutoff1, cutoff2)
   local room2 = mapgen.Room:make { w = room.w, h = room.h }
   for x = 1, room.w-1 do
      for y = 1, room.h-1 do
         local n1, n2 = 0, 0
         for x1 = x-2, x+2 do
            for y1 = y-2, y+2 do
               if room:getS(x1, y1) ~= '.' then
                  if math.abs(x1-x) < 2 and math.abs(y1-y) < 2 then
                     n1 = n1 + 1
                  else
                     n2 = n2 + 1
                  end
               end
            end
         end
         if n1 < cutoff1 and n2 >= cutoff2 then
            room2:setS(x, y, '.')
         end
      end
   end
   return room2
end

function repeatCellStep(n, room, ...)
   for _ = 1, n do
      room = cellStep(room, ...)
   end
   return room
end

function makeCellRoom(w, h)
   local room = mapgen.Room:make { w = w, h = h }
   for x = 1, w-1 do
      for y = 1, h-1 do
         if dice.roll{1, 100, 0} > 40 then
            room:setS(x, y, '.')
         end
      end
   end
   room = repeatCellStep(4, room, 5, 5)
   room = repeatCellStep(2, room, 5, 1)
   room:addWalls()
   room:floodConnect()
   return room
end

function test()
   makeCellRoom(50, 50):print()
end
