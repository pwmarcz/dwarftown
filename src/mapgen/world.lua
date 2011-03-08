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
   local sectors = {Square, Marketplace, Graveyard, RatCaves, Forest}
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

   if dice.getInt(1, 1) == 1 then
      local w = math.floor(self.w/3)
      local lake = makeLake(w, math.floor(2*w/3))
      --lake:print()
      lake:placeIn(self.room, math.floor(self.w/3), math.floor((self.h-self.roadH)/4))
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

function makeLake(w, h)
   local room = mapgen.Room:make()
   room:setCircle(1, 1, w, h, map.Water, false)
   return room
end

RatCaves = Sector:subclass {
   name = 'Rat Caves',
   nItems = 10,
   itemsLevel = 1,

   nMonsters = 20,
   monsters = {mob.Rat, mob.GiantRat, mob.GlowingFungus},
}

function RatCaves:init()
   self.room = mapgen.Room:make {
      w = self.w, h = self.h,
      wall = map.Stone,
   }
   self.room = mapgen.cell.makeCellRoom(self.room, false)

   return room
end

Marketplace = Sector:subclass {
   name = 'Dwarftown Marketplace',
   nMonsters = 5,
   monsters = {mob.Rat, mob.Goblin},
}

function Marketplace:init()
   self.room = mapgen.Room:make {
      wall = map.Stone,
   }
   self.room:addRooms(
      1, 1, self.w, self.h,
      function()
         local w1 = dice.getInt(5, 7)
         local h1 = dice.getInt(3, 6)
         return makeShop(w1, h1)
      end,
      false)
   self.room:floodConnect()
   placeCaveIns(self.room, 10)
end

function placeCaveIns(room, n)
   room.wall = map.Stone
   for i = 1, n do
      local w = dice.getInt(3, 5)
      local h = dice.getInt(2, 4)
      local x = dice.getInt(1, room.w-w-1)
      local y = dice.getInt(1, room.h-h-1)

      room:setRect(x, y, w, h,
                   function()
                      local tile
                      if dice.getInt(1, 3) > 1 then
                         tile = room.floor:make()
                         if dice.getInt(1, 2) == 1 then
                            tile:addItem(item.Stone:make())
                         end
                      else
                         tile = room.wall:make()
                      end
                      return tile
                   end)
   end
   room:addWalls()
   room:floodConnect()
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
               room:get(x, y):addItem(it)
            elseif a == 50 then
               room:get(x, y).mob = mob.Mimic:make()
            end
         end
      end
   end
   return room
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
   local mw = CELL_W*3 - 1
   local mh = CELL_H*3 - 1
   mainRoom:setRect(1, 1, mw, mh, mainRoom.floor)
   mainRoom:get(math.floor(mw/2), math.floor(mh/2)).mob = mob.GoblinNecro:make()
   mainRoom:addWalls()

   local wCenter = math.floor(wCells/2-2)
   local hCenter = math.floor(hCells/2-2)
   mainRoom:placeIn(self.room, wCenter*CELL_W, hCenter*CELL_H)
   self.room = mapgen.tetris.makeTetrisDungeon(self.room, wCells, hCells)
   self.room:floodConnect()
end

Square = Sector:subclass {
   name = 'Dwarftown Square',

   nMonsters = 30,
   monsters = {mob.Ogre, mob.Goblin},
}

function Square:init()
   self.room = mapgen.Room:make {
      wall = map.Stone,
   }
   self.room:addRooms(
      1, 1, self.w-1, self.h-1,
      function()
         local room = mapgen.Room:make { wall = map.Wall }
         local w = dice.getInt(7, 10)
         local h = dice.getInt(6, 9)
         room:setRect(1, 1, w, h, self.room.floor)
         room:setEmptyRect(2, 2, w-1, h-1, room.wall)
         return room
      end,
      false)
   for x = 1, self.w-1 do
      for y = 1, self.h-1 do
         if self.room:get(x, y).empty then
            self.room:set(x, y, self.room.floor)
         end
      end
   end
   self.room:addWalls()
   self.room:floodConnect()
   placeCaveIns(self.room, 4)
end
