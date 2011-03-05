module('mob', package.seeall)

require 'class'
require 'tcod'
require 'map'

local C = tcod.color

Mob = class.Object:subclass {
   glyph = {'?'},
   name = '<mob>',
}

function Mob:putAt(x, y)
   assert(not self.x and not self.y)
   self.x, self.y = x, y
   map.get(x, y).mob = self
end

function Mob:remove()
   assert(self.x and self.y)
   map.get(self.x, self.y).mob = nil
   self.x, self.y = nil, nil
end

function Mob:canWalk(dx, dy)
   local tile = map.get(self.x+dx, self.y+dy)
   return tile and tile.walkable
end

function Mob:walk(dx, dy)
   local x, y = self.x, self.y
   self:remove()
   self:putAt(x+dx, y+dy)
end


Player = Mob:subclass {
   glyph = {'@', C.white},
   fovRadiusLight = 20,
   fovRadiusDark = 3,
}

function Player:putAt(x, y)
   map.computeFov(x, y, self.fovRadiusLight, self.fovRadiusDark)
   Mob.putAt(self, x, y)
end

function Player:remove()
   map.eraseFov(self.x, self.y, self.fovRadiusLight)
   Mob.remove(self)
end


Goblin = Mob:subclass {
   glyph = {'g', C.lighterBlue},
   name = 'goblin',
}
