module('mapgen', package.seeall)

require 'tcod'
require 'class'
require 'dice'

local BIG_W = 65536

Room = class.Object:subclass {
   -- [0, w) x [0, h)
   -- Remember to leave place for walls!
   w = 0,
   h = 0,
}

function Room:init()
   -- points to connect using pathfinding
   self.points = {}
end

function Room:get(x, y)
   return self[BIG_W*y+x]
end

function Room:set(x, y, s)
   self[BIG_W*y+x] = s
   self.w = math.max(self.w, x+1)
   self.h = math.max(self.h, y+1)
end

function Room:setRect(x, y, w, h, s)
   --print(x,y,w,h)
   for x1 = x, x+w-1 do
      for y1 = y, y+h-1 do
         self:set(x1, y1, s)
      end
   end
end

function Room:print()
   for y = 0, self.h-1 do
      s = ''
      for x = 0, self.w-1 do
         s = s .. (self:get(x, y) or ' ')
      end
      print(s)
   end
end

function Room:addWalls()
   for x = 0, self.w do
      for y = 0, self.h do
         if not self:get(x, y) then
            for x1 = x-1, x+1 do
               for y1 = y-1, y+1 do
                  local c = self:get(x1, y1)
                  if c and c ~= '#' then
                     self:set(x, y, '#')
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
         if self:get(x, y) == '#' then
            if ((self:get(x-1, y) == '.' and self:get(x+1, y) == '.') or
             (self:get(x, y-1) == '.' and self:get(x, y+1) == '.'))
            then
               self:set(x, y, '.')
            end
         end
      end
   end
end

-- Checks if room can be placed in another
function Room:canPlaceIn(room2, x, y, ignoreWalls)
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         local c1 = self:get(x1, y1)
         local c2 = room2:get(x+x1, y+y1)
         if c1 and c2 then
            if not (ignoreWalls and c1 == '#' and c2 == '#') then
               return false
            end
         end
      end
   end
   return true
end

function Room:findPoint()
   for x = 0, self.w-1 do
      for y = 0, self.h-1 do
         if self:get(x, y) == '.' then
            return x, y
         end
      end
   end
end

function Room:placeIn(room2, x, y)
   if #self.points == 0 then
      local xp, yp = self:findPoint()
      self.points[1] = {xp, yp}
   end
   for _, p in ipairs(self.points) do
      table.insert(room2.points, {p[1]+x, p[2]+y})
   end
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         local c = self:get(x1, y1)
         if c then
            room2:set(x+x1, y+y1, self:get(x1, y1))
         end
      end
   end
end

-- connect all room.points
function Room:connect(makeDoors)
   local callback = tcod.path.Callback(
      function(_, _, x, y) return self:walkCost(x, y) end)

   local path = tcod.Path(self.w, self.h, callback, nil, 0)

   while #self.points > 1 do
      local x1, y1 = unpack(self.points[#self.points])
      local x2, y2 = unpack(self.points[#self.points-1])
      --print(self:get(x1, y1), self:get(x2, y2), x1, y1, x2, y2)

      table.remove(self.points)
      path:compute(x1, y1, x2, y2)
      local n = path:size()
      for i = 0, n-1 do
         local x, y = path:get(i)
         local c = self:get(x, y) or ' '
         if c == '+' then
            -- pass
         elseif c == '#' and makeDoors then
            c = '+'
         else
            c = '.'
         end
         self:set(x, y, c)
      end
   end
   self:addWalls()
end

function Room:floodConnect(room2)
   room2 = room2 or Room:make {w = self.w, h = self.h}
   for x = 1, self.w-1 do
      for y = 1, self.h-1 do
         local c1 = self:get(x, y)
         local c2 = room2:get(x, y)
         if c1 == '.' and not c2 then
            self:floodFill(room2, x, y)
            table.insert(self.points, {x, y})
         end
      end
   end
   --print('Found ' .. #self.points .. ' components')
   dice.shuffle(self.points)
   self:connect()
end

function Room:floodFill(room2, x, y)
   if room2:get(x, y) or self:get(x, y) ~= '.' then
      return
   else
      room2:set(x, y, '*')
      self:floodFill(room2, x+1, y)
      self:floodFill(room2, x-1, y)
      self:floodFill(room2, x, y+1)
      self:floodFill(room2, x, y-1)
   end
end

function Room:walkCost(x, y)
   if x == 0 or x == self.w or y == 0 or y == self.h then
      -- we don't want to step outside the boundaries
      return 0
   end
   local c = self:get(x, y) or ' '
   return ({['.'] = 1,
            ['+'] = 1,
            ['#'] = 35,
            [' '] = 20})[c] or 0
end
