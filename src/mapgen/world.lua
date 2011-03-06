module('mapgen.world', package.seeall)

require 'mapgen'
require 'mapgen.cell'
require 'dice'

local sectors = {}

-- Makes full game world, returns player x, y
function createWorld()
   local world = mapgen.Room:make {
      sectorNames = {}
   }
   placeSector(world, sectors.marketplace, 10, 10, 50, 30)
   placeSector(world, sectors.ratCaves, 10, 50, 50, 30)
   placeSector(world, sectors.forest, 10, 90, 50, 30)
   --world:addWalls()
   world:floodConnect()
   world:placeOnMap(0, 0)
   map.sectorNames = world.sectorNames
   return 20, 20
end

function placeSector(world, sector, x, y, w, h)
   local room = sector(w, h)
   room:placeIn(world, x, y)
   table.insert(world.sectorNames, {x, y, w, h, room.name})
end

function sectors.forest(w, h)
   local room = mapgen.Room:make {
      w = w, h = h,
      floor = map.Grass,
      wall = map.TallTree,
   }
   room = mapgen.cell.makeCellRoom(room, true)
   room:addNearWalls(map.Tree)
   room:setLight(1)

   room:addWalls()

   room.name = 'Forest'
   return room
end

function sectors.ratCaves(w, h)
   local room = mapgen.Room:make {
      w = w, h = h,
      wall = map.Stone,
   }
   room = mapgen.cell.makeCellRoom(room, false)

   room.name = 'Rat Caves'
   return room
end

function makeShop(w, h)
   local room = mapgen.Room:make {
      wall = map.Wall,
   }
   room:setRect(1, 1, w, h, room.floor)
   room:addWalls()
   return room
end

function sectors.marketplace(w, h)
   local room = mapgen.Room:make {
      wall = map.Stone,
   }
   for _ = 1, 100 do
      w1 = dice.getInt(5, 7)
      h1 = dice.getInt(3, 6)
      shop = makeShop(w1, h1)
      for _ = 1,100 do
         local x = dice.getInt(1, w-w1-1)
         local y = dice.getInt(1, h-h1-1)
         if shop:canPlaceIn(room, x, y, false) then
            shop:placeIn(room, x, y)
            break
         end
      end
   end
   room:floodConnect()
   room.name = 'Marketplace'
   return room
end
