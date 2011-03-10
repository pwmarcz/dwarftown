module('mapgen.world', package.seeall)

require 'mapgen'
require 'mapgen.cell'
require 'mapgen.tetris'
require 'mapgen.tree'
require 'dice'
require 'map'
require 'util'

local world

-- Makes full game world, returns player x, y
function createWorld()
   world = mapgen.Room:make {
      sectors = {},
   }

   local sectors = {
      g = Graveyard,
      s = Square,
      M = Mines,
      m = Marketplace,
      r = RatCaves,
      f = Forest,
   }

   local chart = {
      {false, 'g', false},
      {'M', 's', 'm'},
      {false, 'r'},
      {false, 'f'},
   }
   local W, H = 70, 40
   for j, row in ipairs(chart) do
      for i, k in ipairs(row) do
         if k then
            local x = (W+3)*(i-1)
            local y = (H+3)*(j-1)
            sectors[k] = sectors[k]:place(x, y, W, H)
         end
      end
   end

   --world:addWalls()
   --print('Connecting')
   world:floodConnect()
   --world:print()

   -- now close passage to the Mines
   for y = H+3, (H+3)*2 do
      for x = W-1, W+1 do
         if not world:get(x, y).empty then
            world:set(x, y, world.wall)
         end
      end
   end

   world:placeOnMap(0, 0)
   map.sectors = world.sectors
   return sectors['f']:getStartingPoint()
end

Sector = class.Object:subclass {
   nItems = 0,
   itemsLevel = 0,

   nMonsters = 0,
   monsters = nil,
}

function Sector:place(x, y, w, h)
   --print('Building ' .. self.name)
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

-- Forest is actually bigger: there are roadH road tiles on the bottom
Forest = Sector:subclass {
   name = 'Forest',

   roadH = 25,

   nMonsters = 20,
   monsters = {mob.Bear, mob.Squirrel},
}

function Forest:init()
   self.room = mapgen.Room:make {
      w = self.w, h = self.h,
      floor = map.Grass,
      wall = map.TallTree,
   }
   self.room = mapgen.cell.makeCellRoom(self.room, true)

   self.room:floodConnect()

   if dice.getInt(1, 5) == 1 then
      local w = math.floor(self.w/3)
      local lake = makeLake(w, math.floor(2*w/3))
      --lake:print()
      lake:placeIn(self.room, math.floor(self.w/3), math.floor((self.h-self.roadH)/4))
   end

   local xc = math.floor(self.w/2)
   for y = self.h - 3, self.h + self.roadH - 1 do
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
      local tile = self.room:get(x, self.h + 7)
      if not tile.empty then
         tile.exit = true
      end
   end
end

function Forest:getStartingPoint()
   local x, y = self.room:findEmptyTile(1, self.h + 2, self.w, 4)
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
   itemsLevel = 2,

   nMonsters = 25,
   monsters = {mob.Rat, mob.GiantRat, mob.Bat, mob.GlowingFungus},
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

   itemsLevel = 3,
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
         return makeShop(w1, h1, self.itemsLevel)
      end,
      false)
   self.room:floodConnect('mixed')
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

function makeShop(w, h, itemsLevel)
   local room = mapgen.Room:make {
      wall = map.Wall,
   }
   room:setRect(1, 1, w, h, room.floor)
   room:addWalls()
   if dice.getInt(1, 2) == 1 then
      local x, y = mapgen.randomWallCenter(0, 0, w+2, h+2)
      room:set(x, y, map.Lamp)
   end
   if dice.getInt(1, 2) == 1 then
      -- put some items
      for x = 1,w do
         for y = 1,h do
            a = dice.getInt(1, 50)
            if a < 10 then
               local it = dice.choiceEx(
                  item.Item.all, itemsLevel):make()
               room:get(x, y):addItem(it)
            elseif a < 15 then
               room:get(x, y).mob = mob.Mimic:make()
            end
         end
      end
   end
   return room
end

Graveyard = Sector:subclass {
   name = 'Dwarftown Graveyard',
   nMonsters = 35,
   monsters = {mob.Spectre, mob.Wight, mob.Skeleton},
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

   local function prepare(room)
      for x = 1, room.w-1 do
         for y = 1, room.h-1 do
            local tile = room:get(x, y)
            if not tile.empty and tile.type == '.' then
               if dice.getInt(1, 3) == 1 then
                  room:set(x, y, map.Grave:make())
               end
            end
         end
      end
   end
   self.room = mapgen.tetris.makeTetrisDungeon(
      self.room, wCells, hCells, prepare)
   self.room:floodConnect('closed')
end

Square = Sector:subclass {
   name = 'Dwarftown Square',

   --nMonsters = 30,
   -- monsters placed manually indoors
   monsters = {mob.Ogre, mob.Goblin},

   nItems = 15,
   itemsLevel = 5,
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
         local x, y = mapgen.randomWallCenter(2,2,w-1,h-1)
         room:set(x, y, map.Lamp)
         if dice.getInt(1, 2) == 1 then
            -- add some monsters
            for x = 3, w-2 do
               for y = 3, h-2 do
                  if dice.getInt(1, 2) == 1 then
                     room:get(x, y).mob = dice.choiceEx(self.monsters):make()
                  end
               end
            end
         end
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
   self.room:floodConnect('mixed')
   placeCaveIns(self.room, 4)
end

Mines = Sector:subclass {
   name = 'Dwarftown Mines',

   nMonsters = 60,
   monsters = {mob.Ogre, mob.Goblin, mob.Bugbear, mob.KillerBat},

   iItems = 20,
   itemsLevel = 8,
}

function Mines:init()
   self.room = mapgen.Room:make {
      wall = map.Stone,
   }
   mapgen.tree.makeTree(self.room, self.w, self.h,
                        self.w-3, math.floor(self.h/2),
                        util.dirs.w)

   self.room:addWalls()

   -- Now place boss in the left-most tile
   for x = 1, self.w-1 do
      for y = 1, self.h-1 do
         local tile = self.room:get(x, y)
         if not tile.empty and tile.type == '.' then
            tile.mob = mob.GoblinKing:make()
            return
         end
      end
   end
   assert(false)
end
