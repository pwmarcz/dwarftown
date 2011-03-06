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
   local room2 = mapgen.Room:make {
      w = room.w, h = room.h,
      wall = room.wall, floor = room.floor
   }
   for x = 1, room.w-1 do
      for y = 1, room.h-1 do
         local n1, n2 = 0, 0
         for x1 = x-2, x+2 do
            for y1 = y-2, y+2 do
               if room:get(x1, y1).type ~= '.' then
                  if math.abs(x1-x) < 2 and math.abs(y1-y) < 2 then
                     n1 = n1 + 1
                  else
                     n2 = n2 + 1
                  end
               end
            end
         end
         if n1 < cutoff1 and n2 >= cutoff2 then
            room2:set(x, y, room2.floor)
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

function makeCellRoom(room, smooth)
   for x = 1, room.w-1 do
      for y = 1, room.h-1 do
         if dice.roll{1, 100, 0} > 40 then
            room:set(x, y, room.floor)
         end
      end
   end
   if smooth then
      room = repeatCellStep(1, room, 5, 5)
      room = repeatCellStep(3, room, 5, 0)
   else
      room = repeatCellStep(4, room, 5, 5)
      room = repeatCellStep(1, room, 5, 1)
   end
   room:addWalls()
   room:floodConnect()
   return room
end

function test()
   local room = mapgen.Room:make { w = 60, h = 20 }
   room = makeCellRoom(room, true)
   --room:addNearWalls('&')
   room:print()
end
