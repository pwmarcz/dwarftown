module('mapgen', package.seeall)

require 'class'
require 'dice'

local BIG_W = 65536

Room = class.Object:subclass {
   -- [0, w) x [0, h)
   -- Remember to leave place for walls!
   w = 0,
   h = 0,
}

function Room:getS(x, y)
   return self[BIG_W*y+x]
end

function Room:setS(x, y, s)
   self[BIG_W*y+x] = s
   self.w = math.max(self.w, x+1)
   self.h = math.max(self.h, y+1)
end

function Room:setRect(x, y, w, h, s)
   --print(x,y,w,h)
   for x1 = x, x+w-1 do
      for y1 = y, y+h-1 do
         self:setS(x1, y1, s)
      end
   end
end

function Room:print()
   for y = 0, self.h-1 do
      s = ''
      for x = 0, self.w-1 do
         s = s .. (self:getS(x, y) or ' ')
      end
      print(s)
   end
end

function Room:addWalls()
   for x = 0, self.w do
      for y = 0, self.h do
         if not self:getS(x, y) then
            for x1 = x-1, x+1 do
               for y1 = y-1, y+1 do
                  if self:getS(x1, y1) == '.' then
                     self:setS(x, y, '#')
                  end
               end
            end
         end
      end
   end
end

-- Tetris dungeon helper: tear down walls between two floor tiles.
function Room:tearDownWalls()
   for x = 1, self.w-1 do
      for y = 1, self.h-1 do
         if self:getS(x, y) == '#' then
            if ((self:getS(x-1, y) == '.' and self:getS(x+1, y) == '.') or
             (self:getS(x, y-1) == '.' and self:getS(x, y+1) == '.'))
            then
               self:setS(x, y, '.')
            end
         end
      end
   end
end

-- Checks if room can be placed in another
function Room:canPlaceIn(room2, x, y, ignoreWalls)
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         local c1 = self:getS(x1, y1)
         local c2 = room2:getS(x+x1, y+y1)
         if c1 and c2 then
            if not (ignoreWalls and c1 == '#' and c2 == '#') then
               return false
            end
         end
      end
   end
   return true
end

function Room:placeIn(room2, x, y)
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         local c = self:getS(x1, y1)
         if c then
            room2:setS(x+x1, y+y1, self:getS(x1, y1))
         end
      end
   end
end

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
   return dungeon
end

function test()
   makeTetrisDungeon(16, 8):print()
end
