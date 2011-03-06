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

   -- what tiles to use
   wall = map.Wall,
   floor = map.Floor,
}

function Room:get(x, y)
   return self[BIG_W*y+x] or map.emptyTile
end

function Room:set(x, y, tile)
   if type(tile) == 'function' then
      tile = tile()
   elseif type(tile) == 'table' and not tile.class then
      tile = tile:make()
   end
   self[BIG_W*y+x] = tile
   self.w = math.max(self.w, x+1)
   self.h = math.max(self.h, y+1)
end

function Room:setRect(x, y, w, h, tcls)
   --print(x,y,w,h)
   for x1 = x, x+w-1 do
      for y1 = y, y+h-1 do
         self:set(x1, y1, tcls)
      end
   end
end

function Room:print()
   for y = 0, self.h-1 do
      s = ''
      for x = 0, self.w-1 do
         s = s .. self:get(x, y).glyph[1]
      end
      print(s)
   end
end

function Room:addWalls(tcls)
   self:addWithTest(tcls or self.wall,
                    function(c) return c == ' ' end,
                    function(c) return c == '.' or c == '+' end)
end

-- Add tiles near wall tiles. Used for adding trees.
function Room:addNearWalls(tcls)
   self:addWithTest(tcls,
                    function(c) return c == '.' end,
                    function(c) return c == '#' end)
end


-- Add tiles to squares filtered by test1, if any of the adjacent
-- tiles is confirmed by test2
function Room:addWithTest(tcls, test1, test2)
   for x = 0, self.w do
      for y = 0, self.h do
         if test1(self:get(x, y).type) then
            local add = false
            for x1 = x-1, x+1 do
               for y1 = y-1, y+1 do
                  add = add or test2(self:get(x1, y1).type)
               end
            end
            if add then
               self:set(x, y, tcls)
            end
         end
      end
   end
end

function Room:setLight(light)
   for x = 0, self.w-1 do
      for y = 0, self.h-1 do
         local tile = self:get(x, y)
         if tile.type == '.' then
            tile.light = light
         end
      end
   end
end

-- Tetris dungeon helper: tear down walls between two floor tiles.
function Room:tearDownWalls()
   for x = 1, self.w-1 do
      for y = 1, self.h-1 do
         if self:get(x, y).type == '#' then
            if ((self:get(x-1, y).type == '.' and self:get(x+1, y).type == '.') or
             (self:get(x, y-1).type == '.' and self:get(x, y+1).type == '.'))
            then
               self:set(x, y, self.floor)
            end
         end
      end
   end
end

-- Checks if room can be placed in another
function Room:canPlaceIn(room2, x, y, ignoreWalls)
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         local c1 = self:get(x1, y1).type
         local c2 = room2:get(x+x1, y+y1).type
         if c1 ~= ' ' and c2 ~= ' ' then
            if not (ignoreWalls and c1 == '#' and c2 == '#') then
               return false
            end
         end
      end
   end
   return true
end

function Room:placeIn(room, x, y)
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         local tile = self:get(x1, y1)
         local tile2 = room:get(x+x1, y+y1)
         if tile2.empty or tile.type == '.' then
            if not tile.empty then
               room:set(x+x1, y+y1, tile)
            end
         end
      end
   end
end

function Room:placeOnMap(x, y)
   for x1 = 0, self.w-1 do
      for y1 = 0, self.h-1 do
         if not self:get(x1,y1).empty then
            map.set(x+x1, y+y1, self:get(x1, y1))
         end
      end
   end
end

-- connect all room.points
function Room:connect(points, makeDoors)
   local callback = tcod.path.Callback(
      function(_, _, x, y) return self:walkCost(x, y) end)

   local path = tcod.Path(self.w, self.h, callback, nil, 0)

   while #points > 1 do
      local x1, y1 = unpack(points[#points])
      local x2, y2 = unpack(points[#points-1])
      --print(self:get(x1, y1), self:get(x2, y2), x1, y1, x2, y2)

      table.remove(points)
      path:compute(x1, y1, x2, y2)
      local n = path:size()
      for i = 0, n-1 do
         local x, y = path:get(i)
         local c = self:get(x, y).type
         if c == '+' or c == '.' then
            -- pass
         elseif c == '#' and makeDoors then
            self:set(x, y, map.Door)
         else
            self:set(x, y, self.floor)
         end
      end
   end
   self:addWalls()
end

function Room:floodConnect(...)
   local points = {}
   for x = 1, self.w-1 do
      for y = 1, self.h-1 do
         local tile = self:get(x, y)
         if tile.type == '.' and not tile.accessible then
            self:floodFill(x, y)
            table.insert(points, {x, y})
         end
      end
   end
   --print('Found ' .. #points .. ' components')
   dice.shuffle(points)
   self:connect(points, ...)
end

function Room:floodFill(x, y)
   local tile = self:get(x, y)
   if tile.type == '.' and not tile.accessible then
      tile.accessible = true

      self:floodFill(x+1, y)
      self:floodFill(x-1, y)
      self:floodFill(x, y+1)
      self:floodFill(x, y-1)
   end
end

function Room:walkCost(x, y)
   if x == 0 or x == self.w or y == 0 or y == self.h then
      -- we don't want to step outside the boundaries
      return 0
   end
   local c = self:get(x, y).type
   return ({['.'] = 1,
            ['+'] = 1,
            ['#'] = 35,
            [' '] = 20})[c] or 0
end
