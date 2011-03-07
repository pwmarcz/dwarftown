module('mapgen.world', package.seeall)

require 'mapgen'
require 'mapgen.cell'
require 'mapgen.tetris'
require 'dice'

local world

-- Makes full game world, returns player x, y
function createWorld()
   world = mapgen.Room:make {
      sectors = {}
   }
   local sectors = {Marketplace, Graveyard, RatCaves, Forest}
   for i = 1, #sectors do
      sectors[i] = sectors[i]:place(10, 35*(i-1), 50, 30)
   end

   --world:addWalls()
   world:floodConnect()
   world:placeOnMap(0, 0)
   world:print()
   map.sectors = world.sectors
   return sectors[3]:getStartingPoint()
end

Sector = class.Object:subclass {
   nItems = 0,
   itemsLevel = 0,

   nMonsters = 0,
   monsters = nil,
}

function Sector:place(x, y, w, h)
   local sector = self:make { x = x, y = y, w = w, h = h }
   if sector.nItems > 0 then
      sector.room:addItems(sector.nItems, sector.itemsLevel)
   end
   if sector.nMonsters > 0 then
      sector.room:addMonsters(
         sector.nMonsters, sector.monstersLevel, sector.monsters or mob.Monster.all)
   end
   sector.room:placeIn(world, x, y)
   table.insert(world.sectors, sector)
   return sector
end

function Sector:getStartingPoint()
   local x, y = self.room:findEmptyTile()
   return x + self.x, y + self.y
end

Forest = Sector:subclass {
   name = 'Forest',

   roadH = 10,

   nMonsters = 10,
   monsters = {mob.Bear, mob.Squirrel},
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
   nItems = 10,
   itemsLevel = 1,

   nMonsters = 20,
   monsters = {mob.Rat, mob.GiantRat},
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
            a = dice.getInt(1, 50)
            if a < 10 then
               local it = dice.choiceEx(
                  item.Item.all, 2):make()
               room:get(x, y):putItem(it)
            elseif a == 50 then
               room:get(x, y).mob = mob.Mimic:make()
            end
         end
      end
   end
   return room
end

Marketplace = Sector:subclass {
   name = 'Dwarftown Marketplace',
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

Graveyard = Sector:subclass {
   name = 'Dwarftown Graveyard',
   nMonsters = 10,
   monsters = {mob.Spectre},
}

function Graveyard:init()
   local CELL_W, CELL_H = mapgen.tetris.CELL_W, mapgen.tetris.CELL_H
   local wCells = math.floor(self.w/CELL_W)
   local hCells = math.floor(self.h/CELL_H)
   self.room = mapgen.Room:make {
      wall = map.Stone,
   }

   local mainRoom = mapgen.Room:make {
      wall = map.MarbleWall,
   }
   mainRoom:setRect(1, 1, CELL_W*3-1, CELL_H*3-1, mainRoom.floor)
   mainRoom:addWalls()

   local wCenter = math.floor(wCells/2-2)
   local hCenter = math.floor(hCells/2-2)
   mainRoom:placeIn(self.room, wCenter*CELL_W, hCenter*CELL_H)
   self.room:print()
   self.room = mapgen.tetris.makeTetrisDungeon(self.room, wCells, hCells)
   self.room:floodConnect()
end
