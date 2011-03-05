module('map', package.seeall)

require 'class'
require 'tcod'

local C = tcod.color

WIDTH = 800
HEIGHT = 400

local tiles = {}
local tcodMap = nil

function init()
   tiles = {}
   tcodMap = tcod.Map(WIDTH, HEIGHT)

   for x = 1, 40 do
      for y = 1, 20 do
         local tile
         if x == 1 or x == 40 or y == 1 or y == 20 then
            tile = Wall:make()
         else
            tile = Floor:make()
         end
         set(x, y, tile)
      end
   end
   local lamp = Lamp:make()
   set(1,2,lamp)
   lamp:computeLight(1,2)
end

function get(x, y)
   return tiles[y*WIDTH + x]
end

function set(x, y, tile)
   tiles[y*WIDTH + x] = tile
   tcodMap:setProperties(x, y, tile.transparent, tile.walkable)
end

function eraseFov(x, y, radius)
   for _,_,tile in rect(x, y, radius) do
      if tile.visible then
         tile.memGlyph = tile:getTileGlyph()
         tile.memLight = tile.light
         tile.visible = false
      end
   end
end

function computeFov(x, y, radiusLight, radiusDark)
   tcodMap:computeFov(x, y, radiusLight)
   for x1,y1,tile,d in fovRect(x, y, radiusLight) do
      if tile.light > 0 then
         tile.visible = true
      else
         tile.visible = d <= radiusDark
      end
   end
end

function computeLight(x, y, radius, a)
   tcodMap:computeFov(x, y, radius)
   for _, _, tile, d in fovRect(x,y,radius) do
      tile.light = tile.light + a
   end
end

function rect(x, y, radius)
   function iter()
      for x1 = x-radius, x+radius do
         for y1 = y-radius, y+radius do
            local tile = get(x1, y1)
            if tile then
               coroutine.yield(x1, y1, tile)
            end
         end
      end
   end
   return coroutine.wrap(iter)
end

function fovRect(x, y, radius)
   tcodMap:computeFov(x, y, radius+1, true, tcod.FOV_PERMISSIVE_8)
   function iter()
      for x1, y1, tile in rect(x, y, radius) do
         if tcodMap:isInFov(x1, y1) then
            local d = dist(x1, y1, x, y)
            if d <= radius then
               coroutine.yield(x1, y1, tile, d)
            end
         end
      end
   end
   return coroutine.wrap(iter)
end

function dist(x1, y1, x2, y2)
   local dx = math.abs(x1-x2)
   local dy = math.abs(y1-y2)
   return (dx+dy+math.max(dx,dy))/2
end

Tile = class.Object:subclass {
   glyph = {'?'},
   transparent = false,
   walkable = false,

   visible = false,
   light = 0,
   memGlyph = {' ', C.black},
   memLight = 0,
}

-- tile glyph, sans mob
function Tile:getTileGlyph()
   return self.glyph
end

function Tile:getSeenGlyph()
   if self.mob then
      return self.mob.glyph
   else
      return self:getTileGlyph()
   end
end

Wall = Tile:subclass {
   glyph = {'#', C.grey},
}

Floor = Tile:subclass {
   glyph = {'.', C.grey},
   transparent = true,
   walkable = true,
}

LightSource = Tile:subclass {
   lightRadius = 6,
}

function LightSource:computeLight(x, y)
   computeLight(x, y, self.lightRadius, 1)
end

Lamp = LightSource:subclass {
   glyph = {'^', C.yellow},
}
