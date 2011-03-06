module('map', package.seeall)

require 'class'
require 'tcod'

local C = tcod.color

WIDTH = 70
HEIGHT = 200

local tiles
local tcodMap
local mobs
sectors = nil
player = nil

function init()
   tiles = {}
   tcodMap = tcod.Map(WIDTH, HEIGHT)
   mobs = {}
   sectors = {}
end

function addMob(m)
   if m.lightRadius > 0 then
      computeLight(m.x, m.y, m.lightRadius, 1)
   end
   mobs[m] = true
end

function removeMob(m)
   if m.lightRadius > 0 then
      computeLight(m.x, m.y, m.lightRadius, -1)
   end
   mobs[m] = nil
end

function tick()
   for m, _ in pairs(mobs) do
      m:tick()
   end
end

function getSector(x1, y1)
   for _, sec in ipairs(sectors) do
      if sec.x <= x1 and x1 < sec.x+sec.w and
         sec.y <= y1 and y1 < sec.y+sec.h
      then
         return sec
      end
   end
end


function get(x, y)
   return tiles[y*WIDTH + x] or emptyTile
end

function set(x, y, tile)
   tiles[y*WIDTH + x] = tile
   tcodMap:setProperties(x, y, tile.transparent, tile.walkable)
end

function canDig(x, y)
   if x <= 0 or x >= WIDTH-1 or y <= 0 or y >= HEIGHT - 1 then
      return false
   end
   return get(x, y).diggable
end

function dig(x, y)
   set(x, y, Floor:make())
   for x1 = x-1, x+1 do
      for y1 = y-1, y+1 do
         if get(x1, y1).empty then
            set(x1, y1, Stone:make())
         end
      end
   end
end

function eraseFov(x, y, radius)
   for _,_,tile in rect(x, y, radius) do
      if tile.visible then
         tile.visible = false
         tile.inFov = false
      end
   end
end

function computeFov(x, y, radiusLight, radiusDark)
   tcodMap:computeFov(x, y, radiusLight)
   for x1,y1,tile,d in fovRect(x, y, radiusLight) do
      tile.inFov = true
      light = map.getLight(x1, y1, x, y)
      if light > 0 then
         tile.visible = true
      else
         tile.visible = d <= radiusDark
      end
      if tile.visible then
         tile.seenLight = light
         tile.memGlyph = tile:getTileGlyph()
         tile.memLight = light
      end
   end
end

function computeLight(x, y, radius, a)
   tcodMap:computeFov(x, y, radius)
   for _, _, tile, d in fovRect(x,y,radius) do
      if tile.transparent then
         tile.light = tile.light + a
      end
   end
end

-- Checks if a tile is lit.
function map.getLight(x, y, px, py)
   tile = get(x, y)
   if tile.transparent or tile.light > 0 then
      return tile.light
   else
      -- A wall is lit when we have LOS to any adjacent tile that is lit.
      local light = 0
      dx, dy = math.abs(px-x), math.abs(py-y)
      for dx1 = -1, 1 do
         for dy1 = -1, 1 do
            if tcodMap:isInFov(x+dx1, y+dy1) then
               light = math.max(light, get(x+dx1, y+dy1).light)
            end
         end
      end
      return light
   end
end

function rect(x, y, radius)
   function iter()
      for x1 = x-radius, x+radius do
         for y1 = y-radius, y+radius do
            local tile = get(x1, y1)
            if not tile.empty then
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
   -- Tile type is #, ., + (for map generator)
   type = '?',

   -- visible by player
   visible = false,
   -- in player's FOV - may be invisible because of darkness
   inFov = false,

   -- light and seenLight are different for walls,
   -- because wall can be lit from one side and not from another
   light = 0,
   seenLight = 0,
   memGlyph = {' ', C.black},
   memLight = 0,
}

-- tile glyph, sans mob
function Tile:getTileGlyph()
   if self.items then
      return self.items[#self.items].glyph
   else
      return self.glyph
   end
end

function Tile:getSeenGlyph()
   if self.mob and self.mob.visible then
      return self.mob.glyph
   else
      return self:getTileGlyph()
   end
end

function Tile:putItem(item)
   self.items = self.items or {}
   table.insert(self.items, item)
end

function Tile:removeItem(item)
   util.delete(self.items, item)
   if #self.items == 0 then
      self.items = nil
   end
end

function Tile:onPlayerEnter()
   if self.items then
      if #self.items == 1 then
         ui.message('%s is lying here.', self.items[1].descr_a)
      else
         ui.message('Several items are lying here.')
      end
   end
end

Empty = Tile:subclass {
   glyph = {' ', C.black},
   type = ' ',
   name = '<empty>',
   empty = true
}

emptyTile = Empty:make()

Wall = Tile:subclass {
   glyph = {'#', C.darkerOrange},
   type = '#',
   name = 'wooden wall',
   diggable = true,
}

MarbleWall = Tile:subclass {
   glyph = {'#', C.white},
   type = '#',
   name = 'marble wall',
   diggable = true,
}

Stone = Tile:subclass {
   glyph = {'#', C.darkGrey},
   type = '#',
   name = 'stone',
   diggable = true,
}


Door = Tile:subclass {
   glyph = {'^', C.darkerOrange},
   type = '+',
   name = 'door',
   walkable = true,
   transparent = true,
}

Floor = Tile:subclass {
   glyph = {'.', C.grey},
   type = '.',
   name = 'floor',
   transparent = true,
   walkable = true,
}

Grass = Floor:subclass {
   glyph = {'.', C.lightGreen},
   name = 'grass',
}

TallTree = Tile:subclass {
   glyph = {'#', C.darkerGreen},
   type = '#',
   name = 'tall tree',
}

Tree = Floor:subclass {
   glyph = {'&', C.darkGreen},
   name = 'tree',
}

LightSource = Tile:subclass {
   type = '^',
   lightRadius = 10,
   light = 1,
}

function LightSource:computeLight(x, y)
   computeLight(x, y, self.lightRadius, 1)
end

Lamp = LightSource:subclass {
   glyph = {'*', C.yellow},
   name = 'lamp',
}
