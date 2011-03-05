module('mapgen.tetris', package.seeall)

require 'mapgen'
require 'util'
require 'dice'

local Room = mapgen.Room

local CELL_W, CELL_H = 4, 3

function makeTetrominoRooms()
   local function make(n, w, h, s)
      -- n = how many rooms (symmetry)
      -- w, h = dimensions
      -- s = configuration

      local W, H = CELL_W, CELL_H

      local rooms = {}
      for i = 1, n do
         rooms[i] = Room:make()
      end

      for i, line in ipairs(util.split(s,'|')) do
         for j = 1, line:len() do
            if line:sub(j, j) == '*' then
               rooms[1]:setRect(1+(j-1)*W, 1+(i-1)*H, W-1, H-1, '.')
               if n > 1 then
                  rooms[2]:setRect(1+(h-i)*W, 1+(j-1)*H, W-1, H-1, '.')
               end
               if n > 2 then
                  rooms[3]:setRect(1+(i-1)*W, 1+(w-j)*H, W-1, H-1, '.')
                  rooms[4]:setRect(1+(w-j)*W, 1+(h-i)*H, W-1, H-1, '.')
               end
            end
         end
      end
      for _, r in ipairs(rooms) do
         r:addWalls()
         r:tearDownWalls()
      end
      return rooms
   end
   return util.flatten {
      make(2,4,1,'****'),
      make(1,2,2,'**|**'),
      make(4,3,2,'  *|***'),
      make(4,3,2,'*  |***'),
      make(4,3,2,' * |***'),
      make(4,3,2,'** | **'),
      make(4,3,2,' **|** '),
   }
end

function makeTetrisDungeon(w, h)
   -- w, h - dimensions (in tetromino cells)
   local rooms = makeTetrominoRooms()
   local dungeon = Room:make()
   for _ = 1, 1000 do
      local i = dice.roll {1, w, -1}
      local j = dice.roll {1, h, -1}
      local room = dice.choice(rooms)
      local x, y = i*CELL_W, j*CELL_H
      if room:canPlaceIn(dungeon, x, y, true) then
         room:placeIn(dungeon, x, y)
         --dungeon:print()
      end
   end
   dungeon:connect(true)
   return dungeon
end

function test()
   makeTetrisDungeon(16, 8):print()
end
