module('mapgen.tetris', package.seeall)

require 'mapgen'
require 'util'
require 'dice'

CELL_W, CELL_H = 4, 3

function makeTetrominoRooms(wall, floor)
   local function make(n, w, h, s)
      -- n = how many rooms (symmetry)
      -- w, h = dimensions
      -- s = configuration

      local W, H = CELL_W, CELL_H

      local rooms = {}
      for i = 1, n do
         rooms[i] = mapgen.Room:make{ wall = wall, floor = floor }
      end

      for i, line in ipairs(util.split(s,'|')) do
         for j = 1, line:len() do
            if line:sub(j, j) == '*' then
               rooms[1]:setRect(1+(j-1)*W, 1+(i-1)*H, W-1, H-1, map.Floor)
               if n > 1 then
                  rooms[2]:setRect(1+(h-i)*W, 1+(j-1)*H, W-1, H-1, map.Floor)
               end
               if n > 2 then
                  rooms[3]:setRect(1+(i-1)*W, 1+(w-j)*H, W-1, H-1, map.Floor)
                  rooms[4]:setRect(1+(w-j)*W, 1+(h-i)*H, W-1, H-1, map.Floor)
               end
            end
         end
      end
      for _, r in ipairs(rooms) do
         r.wCells = math.floor(r.w / W)
         r.hCells = math.floor(r.h / H)
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

-- w, h - dimensions (in tetromino cells)
function makeTetrisDungeon(dungeon, wCells, hCells)
   local rooms = makeTetrominoRooms(dungeon.wall, dungeon.floor)
   for _ = 1, 1000 do
      local room = dice.choice(rooms)
      local i = dice.getInt(0, wCells-1-room.wCells)
      local j = dice.getInt(0, hCells-1-room.hCells)
      local x, y = i*CELL_W, j*CELL_H
      if room:canPlaceIn(dungeon, x, y, true) then
         room = room:deepCopy()
         room:placeIn(dungeon, x, y, true)
         --print(_)
         --dungeon:print()
      end
   end
   dungeon:floodConnect(true)
   return dungeon
end

function test()
   makeTetrisDungeon(12, 6):print()
end
