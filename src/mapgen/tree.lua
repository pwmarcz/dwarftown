module('mapgen.tree', package.seeall)

require 'mapgen'
require 'util'
require 'dice'

-- Tree dungeon. Works by tracing corridors with a 2x2 brush.
-- The resulting structure is tree-like, but sometimes we join the
-- corridors to make exploration easier.

-- The algorithm has some flaws - sometimes it stops too early.

BRUSH_W, BRUSH_H = 2, 2

function makeTree(room, w, h, x, y, dir)
   local xLast, yLast
   local toFork = dice.getInt(3,10)
   while true do
      local dx, dy = unpack(util.dirs[dir])

      xLast, yLast = x, y
      x = x + dx
      y = y + dy

      if x < 1 or x+BRUSH_W-1 >= w-2 or
         y < 1 or y+BRUSH_H-1 >= h-2
      then
         break
      end

      local deadEnd = false
      for x1 = x-1, x+BRUSH_W do
         for y1 = y-1, y+BRUSH_H do
            if x1 < xLast-1 or x1 > xLast+BRUSH_W or
               y1 < yLast-1 or y1 > yLast+BRUSH_H
            then
               if not room:get(x1, y1).empty then
                  deadEnd = true
               end
            end
         end
      end

      -- we stop when we reach a dead end, but not always
      if deadEnd and dice.getInt(1, 7) <= 5 then
         return
      end

      room:setRect(x, y, BRUSH_W, BRUSH_H, room.floor)
      --room:setEmptyRect(x-2, y-2, 5, 5, room.wall)

      if dice.getInt(1, 15) == 1 then -- bend
         dir = util.dirs.add(dir, dice.getSign())
      end

      toFork = toFork - 1
      if toFork == 0 then
         toFork = dice.getInt(5, 12)

         --local dir1 = util.dirs.add(dir, dice.getSign()*2)
         local a1 = dice.getInt(1,2)
         local a2 = dice.getInt(-2,-1)
         if dice.getInt(1,2) == 1 then
            -- to ensure symmetry
            a1, a2 = a2, a1
         end
         makeTree(room, w, h, x, y, util.dirs.add(dir,a1))
         makeTree(room, w, h, x, y, util.dirs.add(dir,a2))
      end
   end
end

function test()
   local w, h = 70, 70
   local room = mapgen.Room:make { w = w, h = h }
   makeTree(room, w, h, w-5, math.floor(h/2), util.dirs.w)
   room:addWalls()
   room:print()
end
