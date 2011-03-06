module('mapgen.world', package.seeall)

require 'mapgen'
require 'mapgen.cell'
require 'dice'

local sectors = {}

local world

-- Makes full game world, returns player x, y
function createWorld()
   world = mapgen.Room:make {
      sectorNames = {}
   }
   Marketplace:place(10, 10, 50, 30)
   RatCaves:place(10, 50, 50, 30)
   local forest = Forest:place(10, 90, 50, 60)
   --world:addWalls()
   world:floodConnect()
   world:placeOnMap(0, 0)
   world:print()
   map.sectorNames = world.sectorNames
   return forest:getStartingPoint()
end

Sector = class.Object:subclass {
   items = 0,
   itemsLevel = 1,

   monsters = 0,
   monstersLevel = 1,
   monstersCategory = false,
}

function Sector:place(x, y, w, h)
   local sector = self:make { x = x, y = y, w = w, h = h }
   if sector.items > 0 then
      sector.room:addItems(sector.items, sector.itemsLevel)
   end
   if sector.monsters > 0 then
      sector.room:addMonsters(
         sector.monsters, sector.monstersLevel, sector.monstersCategory)
   end
   sector.room:placeIn(world, x, y)
   table.insert(world.sectorNames, {x, y, w, h, sector.name})
   return sector
end

Forest = Sector:subclass {
   name = 'Forest',
   itemsLevel = 0,
   roadH = 20,

   monsters = 10,
   monstersLevel = false,
   monstersCategory = {mob.Bear, mob.Squirrel},
}

function Forest:init()
   self.room = mapgen.Room:make {
      w = self.w, h = self.h - self.roadH,
      floor = map.Grass,
      wall = map.TallTree,
   }
   self.room = mapgen.cell.makeCellRoom(self.room, true)

   local xc = math.floor(self.w/2)
   for y = self.h - self.roadH - 3, self.h - 1 do
      local d = dice.getInt(-1, 1)
      for x = xc - 3 + d, xc + 3 + d do
         tile = self.room.floor:make()
         self.room:set(x, y, tile)
      end
   end

   self.room:addWalls()
   self.room:addNearWalls(map.Tree)
   self.room:setLight(1)
   self.room:floodConnect()

   for x = 1, self.w - 1 do
      local tile = self.room:get(x, self.h - self.roadH + 6)
      if not tile.empty then
         tile.exit = true
      end
   end
end

function Forest:getStartingPoint()
   local x, y = self.room:findEmptyTile(1, self.h - self.roadH-4, self.w, 4)
   return x + self.x, y + self.y
end

RatCaves = Sector:subclass {
   name = 'Rat Caves',
   items = 10,
   itemsLevel = 1,

   monsters = 20,
   monstersLevel = false,
   monstersCategory = {mob.Rat, mob.GiantRat},
}

function RatCaves:init()
   self.room = mapgen.Room:make {
      w = self.w, h = self.h,
      wall = map.Stone,
   }
   self.room = mapgen.cell.makeCellRoom(self.room, false)

   return room
end

function makeShop(w, h)
   local room = mapgen.Room:make {
      wall = map.Wall,
   }
   room:setRect(1, 1, w, h, room.floor)
   room:addWalls()
   local a = dice.getInt(1, 4)
   if a == 1 then
      room:set(math.floor(w/2), 0, map.Lamp)
   elseif a == 2 then
      room:set(math.floor(w/2), h+1, map.Lamp)
   end
   if dice.getInt(1, 2) == 1 then
      -- put some items
      for x = 1,w do
         for y = 1,h do
            if dice.getInt(1, 5) == 1 then
               local it = dice.choiceLevel(
                  item.Item.all, 2):make()
               room:get(x, y):putItem(it)
            end
         end
      end
   end
   return room
end

Marketplace = Sector:subclass {
   name = 'Marketplace',
}

function Marketplace:init()
   self.room = mapgen.Room:make {
      wall = map.Stone,
   }
   for _ = 1, 100 do
      w1 = dice.getInt(5, 7)
      h1 = dice.getInt(3, 6)
      shop = makeShop(w1, h1)
      for _ = 1,100 do
         local x = dice.getInt(1, self.w-w1-1)
         local y = dice.getInt(1, self.h-h1-1)
         if shop:canPlaceIn(self.room, x, y, false) then
            shop:placeIn(self.room, x, y)
            break
         end
      end
   end
   self.room:floodConnect()
end