module('mob', package.seeall)

require 'class'
require 'tcod'
require 'map'
require 'dice'
require 'util'

local C = tcod.color

Mob = class.Object:subclass {
   glyph = {'?'},
   name = '<mob>',
}

function Mob:init()
   self.hp = self.maxHp
end

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
   return tile and tile.walkable and not tile.mob
end

function Mob:canAttack(dx, dy)
   local tile = map.get(self.x+dx, self.y+dy)
   return tile and tile.mob
end

function Mob:walk(dx, dy)
   local x, y = self.x, self.y
   self:remove()
   self:putAt(x+dx, y+dy)
end

function Mob:attack(dx, dy)
   local mob = map.get(self.x+dx, self.y+dy).mob
   local damage = dice.roll(self.attackDice)
   self:onHit(mob, damage)
   mob:receiveDamage(damage, self)
end

Player = Mob:subclass {
   glyph = {'@', C.white},
   isPlayer = true,

   fovRadiusLight = 20,
   fovRadiusDark = 3,

   level = 1,
   exp = 0,
   hp = 10,
   maxHp = 10,

   attackDice = {1,3,1},
}

function Player:putAt(x, y)
   map.computeFov(x, y, self.fovRadiusLight, self.fovRadiusDark)
   Mob.putAt(self, x, y)
   map.get(x, y):onPlayerEnter()
end

function Player:remove()
   map.eraseFov(self.x, self.y, self.fovRadiusLight)
   Mob.remove(self)
end

function Player:receiveDamage(damage, from)
   self.hp = self.hp - damage
   if self.hp < 0 then
      ui.message(C.red, 'You die...')
      self:die()
   end
end

function Player:onHit(mob, damage)
   ui.message('You hit %s.', mob.descr_the)
end

function Player:die()
   self.dead = true
end

Monster = Mob:subclass()

function Monster:receiveDamage(damage, from)
   self.hp = self.hp - damage
   if self.hp < 0 then
      ui.message('%s is killed!', self.descr_the)
      self:die()
   end
end

function Monster:die()
   self:remove()
   map.removeMonster(self)
end

function Monster:onHit(mob, damage)
   if mob.isPlayer then
      ui.message('%s hits you.', self.descr_the)
   end
end

local DIRS = {
   {-1,-1}, {-1,0}, {-1,1},
   {0,-1}, {0,1},
   {1,-1}, {1,0}, {1,1}
}

function Monster:act()
   dx, dy = unpack(dice.choice(DIRS))
   if self:canAttack(dx, dy) then
      self:attack(dx, dy)
   elseif self:canWalk(dx, dy) then
      self:walk(dx, dy)
   end
end

function Monster.get:descr()
   return self.name
end

function Monster.get:descr_the()
   return util.descr_the(self.descr)
end


Goblin = Monster:subclass {
   glyph = {'g', C.lighterBlue},
   name = 'goblin',

   attackDice = {1,4,1},

   maxHp = 5,
}
