module('mapgen.world', package.seeall)

require 'mapgen'
require 'mapgen.cell'
require 'dice'

local sectors = {}

-- Makes full game world, returns player x, y
function createWorld()
   local world = mapgen.Room:make() -- { w = map.WIDTH, h = map.HEIGHT }
   placeSector(world, sectors.ratCaves, 10, 10, 50, 50)
   placeSector(world, sectors.forest, 10, 50, 50, 50)
   --world:addWalls()
   world:placeOnMap(0, 0)
   world:floodConnect()
   return 20, 70
end

function placeSector(world, sector, x, y, w, h)
   local room = sector(w, h)
   room:placeIn(world, x, y)
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

   return room
end

function sectors.ratCaves(w, h)
   local room = mapgen.Room:make {
      w = w, h = h,
      wall = map.Stone,
   }
   room = mapgen.cell.makeCellRoom(room, false)

   room:print()
   return room
end
