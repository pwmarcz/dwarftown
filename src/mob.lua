module('mob', package.seeall)

require 'class'
require 'tcod'
require 'map'
require 'dice'
require 'util'
require 'game'

local C = tcod.color

Mob = class.Object:subclass {
   glyph = {'?'},
   name = '<mob>',
   -- regeneration rate: how many turns to full regeneration
   regen = 80,
   armor = 0,
}

function Mob:init()
   self.hp = self.maxHp
end

function Mob.get:tile()
   assert(self.x and self.y)
   return map.get(self.x, self.y)
end

function Mob:putAt(x, y)
   map.addMob(self)
   assert(not self.x and not self.y)
   self.x, self.y = x, y
   self.tile.mob = self
end

function Mob:remove()
   map.removeMob(self)
   self.tile.mob = nil
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

function Mob:tick()
   if self.dead then
      return
   end
   local n = self.maxHp/self.regen -- how many HPs per turn
   local n1 = math.floor(n)
   local p = math.floor((n-n1)*100)
   self.hp = self.hp + n1
   if dice.roll {1, 100, 0} < p then
      self.hp = self.hp + 1
   end
   self.hp = math.min(self.hp, self.maxHp)
end

function Mob:attack(dx, dy)
   local mob = map.get(self.x+dx, self.y+dy).mob
   local damage = dice.roll(self.attackDice)
   damage = math.max(0, damage - mob.armor)
   self:onAttack(mob, damage)
   mob:receiveDamage(damage, self)
end

Player = Mob:subclass {
   glyph = {'@', C.white},
   isPlayer = true,
   name = 'you',
   descr = 'you',

   fovRadiusLight = 20,
   fovRadiusDark = 3,

   level = 1,
   exp = 0,
   hp = 10,
   maxHp = 10,
   regen = 40,

   --attackDice = {1,3,1},

   maxItems = 10,
}

function Player:init()
   self.items = {}
   self.slots = {}
end

function Player.get:attackDice()
   local plus = self.level * 2 - 2
   if self.slots.weapon then
      a, b, c = unpack(self.slots.weapon.attackDice)
      return {a, b, c+plus}
   else
      return {1, 3, 1+plus}
   end
end

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
   if self.hp <= 0 then
      ui.message(C.red, 'You die...')
      self:die()
   end
end

function Player:pickUp(item)
   if #self.items > self.maxItems then
      ui.message('Your backpack is full!')
   else
      ui.message('You pick up %s.', item.descr_a)
      self.tile:removeItem(item)
      table.insert(self.items, item)
      return true
   end
end

function Player:drop(item)
   if item.equipped then
      unequip(item)
   end
   ui.message('You drop %s.', item.descr_the)
   util.delete(self.items, item)
   self.tile:putItem(item)
   return true
end

function Player:use(item)
   if item.equipped then
      self:unequip(item)
      return true
   elseif item.slot then
      self:equip(item)
      return true
   end
end

function Player:equip(item)
   if self.slots[item.slot] then
      self:unequip(self.slots[item.slot])
   end
   ui.message('You equip %s.', item.descr_the)
   self.slots[item.slot] = item
   item.equipped = true
   if item.onEquip then
      item:onEquip(self)
   end
   return true
end

function Player:unequip(item)
   assert(item.equipped)
   self.slots[item.slot] = nil
   ui.message('You unequip %s.', item.descr_the)
   item.equipped = false
   if item.onUnequip then
      item:onUnequip(self)
   end
   return true
end

function Player:onAttack(mob, damage)
   if damage > 0 then
      ui.message('You hit %s.', mob.descr_the)
   else
      ui.message('You fail to hurt %s.')
   end
end

function Player:die()
   self.dead = true
end

Monster = Mob:subclass()

function Monster:receiveDamage(damage, from)
   self.hp = self.hp - damage
   if self.hp <= 0 then
      ui.message('%s is killed!', self.descr_the)
      self:die()
   end
end

function Monster:die()
   self:remove()
end

function Monster:onAttack(mob, damage)
   if mob.isPlayer then
      if damage > 0 then
         ui.message('%s hits you.', self.descr_the)
      else
         ui.message('%s hits you, but your armor protects you.')
      end
   end
end

function Monster:tick()
   Mob.tick(self)

   if self:canSeePlayer() then
      dx, dy = util.dirTowards(
         self.x, self.y, game.player.x, game.player.y)
   else
      -- TODO last known position
      dx, dy = util.randomDir()
   end

   if self.x+dx == game.player.x and
      self.y+dy == game.player.y
   then
      self:attack(dx, dy)
   elseif self:canWalk(dx, dy) then
      self:walk(dx, dy)
   end
end

function Monster:canSeePlayer()
   -- TODO proper monster FOV (incl. lights)
   return self.tile.inFov
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
