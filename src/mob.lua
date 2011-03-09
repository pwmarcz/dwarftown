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
   -- regeneration rate: how many turns to full regeneration
   regen = 80,
   armor = 0,
   lightRadius = 0,

   fovRadiusLight = 10,
   fovRadiusDark = 4,

   speed = 0,
   energy = 0,
}

function Mob:init()
   self.hp = self.maxHp
end

function Mob._get:tile()
   assert(self.x and self.y)
   return map.get(self.x, self.y)
end

function Mob._get:visible()
   return self.tile.visible
end

function Mob:putAt(x, y)
   assert(not self.x and not self.y)
   self.x, self.y = x, y
   self.tile.mob = self
   map.addMob(self)
end

function Mob:remove()
   map.removeMob(self)
   self.tile.mob = nil
   self.x, self.y = nil, nil
end

function Mob:canWalk(dx, dy)
   local tile = map.get(self.x+dx, self.y+dy)
   return tile.walkable and not tile.mob
end

function Mob:canAttack(dx, dy)
   local tile = map.get(self.x+dx, self.y+dy)
   return tile.mob
end

function Mob:spendEnergy()
   self.energy = self.energy - 1
end

function Mob:wait()
   --
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

   -- Get energy
   local en = 1
   if self.speed > 0 then
      en = en + 0.15*self.speed
   elseif self.speed < 0 then
      en = en + 0.05*self.speed
   end
   self.energy = self.energy + en

   -- Regenerate HP
   local n = self.maxHp/self.regen -- how many HPs per turn
   local n1 = math.floor(n)
   local p = math.floor((n-n1)*100)
   self.hp = self.hp + n1
   if dice.roll {1, 100, 0} < p then
      self.hp = self.hp + 1
   end
   self.hp = math.min(self.hp, self.maxHp)
end

function Mob:act()
end

function Mob:die()
   self.dead = true
end

function Mob:attack(dx, dy)
   local mob = map.get(self.x+dx, self.y+dy).mob
   if mob.dead then
      return
   end
   local damage = dice.roll(self.attackDice)
   damage = math.max(0, damage - math.max(mob.armor, 0))
   self:onAttack(mob, damage)
   mob:receiveDamage(damage, self)
end

Player = Mob:subclass {
   glyph = {'@', C.white},
   isPlayer = true,
   name = 'you',
   descr = 'you',

   fovRadiusLight = 20,
   fovRadiusDark = 4,

   level = 1,
   exp = 0,
   --maxExp = 10,
   --hp = 10,
   --maxHp = 10,
   regen = 40,

   energy = 1,

   --attackDice = {1,3,1},

   maxItems = 10,

   nArtifacts = 0,
}

function Player:init()
   self.items = {}
   self.slots = {}
   self.boosts = {}
   self:calcStats()
   self.hp = self.maxHp
end

function Player._get:attackDice()
   local plus = self.level - 1
   if self.boosts.strength then
      plus = plus + self.level*2
   end
   if self.slots.weapon then
      a, b, c = unpack(self.slots.weapon.attackDice)
      return {a, b, c+plus}
   else
      return {1, 3, 1+plus}
   end
end

function Player:calcStats()
   self.maxExp = self.level * 10
   self.maxHp = 10 + (self.level-1) * 5
end

function Player:refundEnergy()
   self.energy = self.energy + 1
end

function Player:changeLightRadius(a)
   local x, y = self.x, self.y
   self:remove()

   self.lightRadius = self.lightRadius + a
   self:putAt(x, y)
end

function Player:recalcFov()
   local x, y = self.x, self.y
   self:remove()
   self:putAt(x, y)
end

function Player:canDig(dx, dy)
   if not self.digging then
      return false
   end
   return map.canDig(self.x+dx, self.y+dy)
end

function Player:dig(dx, dy)
   map.dig(self.x+dx, self.y+dy)
   self:recalcFov()
   ui.message('You dig.')
   self:onDig(dx, dy)
end

function Player:act()
   assert(false)
end

function Player:attack(dx, dy)
   local m = map.get(self.x+dx, self.y+dy).mob
   if not m.hostile then
      if not ui.promptYN('Attack %s? [yn]', m.descr_the) then
         self:refundEnergy()
         return
      end
   end
   return Mob.attack(self, dx, dy)
end

function Player:walk(dx, dy)
   if map.get(self.x+dx, self.y+dy).exit then
      if ui.promptYN('Leave? This will end the game. [yn]') then
         self.leaving = true
      end
   else
      return Mob.walk(self, dx, dy)
   end
end

function Player:tick()
   light = self.slots.light
   if light then
      light.turnsLeft = light.turnsLeft - 1
      if light.turnsLeft == 0 then
         ui.message('Your %s is extinguished.', light.descr)
         self:destroyItem(light)
      end
   end
   for k, v in pairs(self.boosts) do
      v = v - 1
      self.boosts[k] = v
      if v <= 0 then
         self.boosts[k] = nil
         local message
         if k == 'nightVision' then
            self.nightVision = false
            self:recalcFov()
            message = 'Your vision returns to normal.'
         elseif k == 'speed' then
            self.speed = self.speed - 2
            message = 'You slow down.'
         elseif k == 'strength' then
            message = 'You feel weaker.'
         end
         ui.message(C.yellow, message)
      end
   end
   Mob.tick(self)
end

function Player:destroyItem(it)
   if it.equipped then
      it:onUnequip(self)
      self.slots[it.slot] = nil
   end
   util.delete(self.items, it)
end

function Player:putAt(x, y)
   Mob.putAt(self, x, y)
   map.get(x, y):onPlayerEnter()
   map.computeFov()
end

function Player:remove()
   local x, y = self.x, self.y
   Mob.remove(self)
   map.eraseFov(x, y, self.fovRadiusLight)
end

function Player:receiveDamage(damage, from)
   self.hp = self.hp - damage
   if self.hp <= 0 then
      ui.message(C.red, 'You die...')
      self:die()
   end
end

function Player:pickUp(it)
   if #self.items > self.maxItems then
      ui.message('Your backpack is full!')
      self:refundEnergy()
   else
      ui.message('You pick up %s.', it.descr_the)
      self.tile:removeItem(it)
      table.insert(self.items, it)

      if it.artifact then
         self.nArtifacts = self.nArtifacts + 1

         if self.nArtifacts == item.N_ARTIFACTS then
            ui.promptEnter('[You have found the artifacts. ' ..
                           'Leave the Forest with them to win the game. ' ..
                           'Press ENTER]')
         end
      end
   end
end

function Player:drop(it)
   if it.equipped then
      unequip(it)
   end
   ui.message('You drop %s.', it.descr_the)
   util.delete(self.items, it)
   self.tile:addItem(it)

   if it.artifact then
      self.nArtifacts = self.nArtifacts - 1
   end
end

function Player:use(item)
   if item.equipped then
      self:unequip(item)
   elseif item.slot then
      self:equip(item)
   elseif item.onUse then
      item:onUse(self)
   else
      ui.message('You don\'t know how to use %s.', item.descr_the)
      self:refundEnergy()
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
end

function Player:unequip(item)
   assert(item.equipped)
   self.slots[item.slot] = nil
   ui.message('You unequip %s.', item.descr_the)
   item.equipped = false
   if item.onUnequip then
      item:onUnequip(self)
   end
end

function Player:onAttack(mob, damage)
   if damage > 0 then
      ui.message('You hit %s.', mob.descr_the)
   else
      ui.message('You fail to hurt %s.')
   end
end

function Player:addExp(level)
   local a = level
   if level > self.level then
      local b = level - self.level
      a = a + b*(b+1)
   end
   self.exp = self.exp + a
   while self.exp >= self.maxExp do
      self:advance()
   end
end

function Player:addBoost(boost, turns)
   local n = self.boosts[boost]
   if not n then
      n = 0
      local message
      if boost == 'nightVision' then
         self.nightVision = true
         self:recalcFov()
         message = 'You suddenly see more around yourself.'
      elseif boost == 'speed' then
         self.speed = self.speed + 2
         message = 'You feel yourself speed up!'
      elseif boost == 'strength' then
         -- attack dice code will handle this
         message = 'Your muscles bulge.'
      end
      ui.message(C.yellow, message)
   end
   self.boosts[boost] = n + turns
end

function Player:advance()
   self.exp = self.exp - self.maxExp
   self.level = self.level + 1
   self:calcStats()
   self.hp = self.maxHp
   ui.message(C.yellow,
              'Congratulations! You advance to level %d.', self.level)
end

Monster = Mob:subclass {
   hostile = true,
   level = 1,

   -- probability of dropping an item
   dropRate = 0,

   wanders = true
}

function Monster:receiveDamage(damage, from)
   self.hp = self.hp - damage
   if self.hp <= 0 then
      ui.message('%s is killed!', self.descr_the)
      self:die()
      if from.isPlayer then
         from:addExp(self.level)
      end
   else
      if from.isPlayer and not self.hostile then
         self.hostile = true
      end
   end
end

function Monster:die()
   if dice.getFloat(0, 1) < self.dropRate then
      self.tile:addItem(dice.choiceEx(item.Item.all, self.level):make())
   end
   self:remove()
   Mob.die(self)
end

function Monster:onAttack(mob, damage)
   if mob.isPlayer then
      if damage > 0 then
         ui.message('%s hits you.', self.descr_the)
      else
         ui.message('%s hits you, but your armor protects you.',
                    self.descr_the)
      end
   end
end

function Monster:act()
   if self.hostile and self:canSeePlayer() then
      if self.summonsTimes and self.summonsTimes > 0
         and dice.getInt(1,15) == 1
      then
         self.summonsTimes = self.summonsTimes - 1
         for x = self.x-2, self.x+2 do
            for y = self.y-2, self.y+2 do
               local tile = map.get(x, y)
               if not tile.empty and tile.walkable and not tile.mob then
                  if dice.getInt(1, 3) == 1 then
                     local m = dice.choice(self.summonedMonsters):make()
                     m:putAt(x, y)
                  end
               end
            end
         end
         ui.message('%s summons monsters!', self.descr_the)
      end

      local dx, dy = util.dirTowards(
         self.x, self.y, map.player.x, map.player.y)

      if self.x+dx == map.player.x and
         self.y+dy == map.player.y
      then
         self:attack(dx, dy)
         return
      elseif self:canWalk(dx, dy) then
         self:walk(dx, dy)
         return
      end
   elseif not self.wanders then
      -- non-wandering monsters stop when they don't see player
      self:wait()
      return
   end

   -- last known position?
   local dx, dy = util.randomDir()
   if self:canWalk(dx, dy) then
      self:walk(dx, dy)
   else
      self:wait()
   end
end

function Monster:canSeePlayer()
   -- cheating to get LOS with player
   if not self.tile.inFov then
      return false
   end
   local d = map.dist(self.x, self.y, map.player.x, map.player.y)
   if map.player.tile.light > 0 then
      return d <= self.fovRadiusLight
   else
      return d <= self.fovRadiusDark
   end
end

function Monster._get:descr()
   if self.visible then
      return self.name
   else
      return 'something'
   end
end

function Monster._get:descr_the()
   if self.visible then
      return util.descr_the(self.descr)
   else
      return 'something'
   end
end

GlowingFungus = Monster:subclass {
   glyph = {'F', C.lightGreen},
   name = 'glowing fungus',

   maxHp = 3,
   attackDice = {0, 0, 0},

   freq = 0.5,

   lightRadius = 4,
}

function GlowingFungus:act()
end

Mimic = Monster:subclass {
   name = 'mimic',

   attackDice = {1,6,0},
   maxHp = 10,

   awake = false,
}

function Mimic:init()
   self.item = dice.choiceEx(item.Item.all):make()
   self.glyph = self.item.glyph
   self.name = self.item.name
end

function Mimic:act()
   if self.awake then
      Monster.act(self)
   else
      self:wait()
   end
end

function Mimic:receiveDamage(damage, from)
   if from.isPlayer and not self.awake then
      ui.message('It\'s a mimic!')
      self:wakeUp()
   end
   Monster.receiveDamage(self, damage, from)
end

function Mimic:wakeUp()
   self.glyph = {'m', self.glyph[2]}
   self.name = self.class.name
   self.awake = true
end

Spectre = Monster:subclass {
   glyph = {'Z', C.white},
   name = 'spectre',

   attackDice = {1,5,0},
   maxHp = 10,

   level = 4,
}

function Spectre._get:visible()
   return self.tile.visible and self.tile.light == 0
end

Rat = Monster:subclass {
   glyph = {'r', C.darkOrange},
   name = 'rat',

   attackDice = {1,3,0},

   maxHp = 5,
   speed = 2,
}

GiantRat = Monster:subclass {
   glyph = {'R', C.darkOrange},
   name = 'giant rat',

   attackDice = {1,4,1},

   maxHp = 7,
}

Bear = Monster:subclass {
   glyph = {'B', C.darkOrange},
   name = 'bear',

   attackDice = {1,10,1},

   speed = -1,
   maxHp = 20,
   level = 3,
   hostile = false,
}

Squirrel = Monster:subclass {
   glyph = {'q', C.orange},
   name = 'squirrel',

   attackDice = {1,2,0},

   speed = 5,
   maxHp = 3,
   level = 0,
   hostile = false,
}

Goblin = Monster:subclass {
   glyph = {'g', C.darkGreen},
   name = 'goblin',

   attackDice = {1,6,0},

   maxHp = 10,
   level = 2,

   dropRate = 0.1,
}

Ogre = Monster:subclass {
   glyph = {'O', C.lightGreen},
   name = 'ogre',

   attackDice = {1,12,0},

   speed = -1,
   maxHp = 20,
   level = 4,

   freq = 0.5,
   dropRate = 0.2,
}

GoblinNecro = Monster:subclass {
   glyph = {'G', C.lightGreen},
   name = 'Goblin Necromancer',

   attackDice = {1,12,0},

   speed = -2,
   maxHp = 30,
   level = 5,

   summonedMonsters = { Rat, Spectre },
   summonsTimes = 3,

   wanders = false,

   exclude = true,
}

function GoblinNecro:die()
   self.tile:addItem(item.ArtifactWeapon:make())
   Monster.die(self)
end
