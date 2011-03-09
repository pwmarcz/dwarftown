module('item', package.seeall)

require 'tcod'
require 'class'
require 'util'

local C = tcod.color

Item = class.Object:subclass {
   exclude = true,
   glyph = {'?'},
   name = '<item>',
   level = 1,
}

util.addRegister(Item)

function Item._get:descr()
   return self.name
end

function Item._get:descr_a()
   return util.descr_a(self.descr)
end

function Item._get:descr_the()
   return util.descr_the(self.descr)
end

LightSource = Item:subclass {
   exclude = true,
   slot = 'light',
}

function LightSource:init()
   self.turnsLeft = self.turns
end

function LightSource._get:descr()
   if self.turnsLeft < self.turns then
      return ('%s (%d/%d)'):format(
         self.name, self.turnsLeft, self.turns)
   else
      return self.name
   end
end

function LightSource:onEquip(player)
   player:changeLightRadius(self.lightRadius)
end

function LightSource:onUnequip(player)
   player:changeLightRadius(-self.lightRadius)
end

Torch = LightSource:subclass {
   glyph = {'/', C.darkerOrange},
   name = 'torch',
   lightRadius = 7,
   turns = 300,

   level = 2,
}

Weapon = Item:subclass {
   exclude = true,
   slot = 'weapon',
}

function Weapon:init()
   if self.artifact then
      return
   end
   if dice.getInt(1, 6) == 1 then
      local a, b, c = unpack(self.attackDice)
      if dice.getInt(1, 20) == 1 then
         a = a + 2
      else
         b = b + dice.getInt(-1, 1)
         c = c + dice.getInt(-1, 3)
      end
      self.attackDice = {a, b, c}
   end
end

function Weapon._get:descr()
   return ('%s (%s)'):format(
      Item._get.descr(self),
      dice.describe(self.attackDice))
end

Sword = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'sword',

   attackDice = {1, 6, 0},
   level = 2,
}

Dagger = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'dagger',

   attackDice = {1, 4, 1},
   level = 1,
}

BrokenDagger = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'broken dagger',

   attackDice = {1, 2, 1},
   level = 1,
}

PickAxe = Weapon:subclass {
   exclude = true,
   glyph = {'{', C.lightGrey},
   name = 'pick-axe',

   attackDice = {1, 4, 2},

   level = 3,
}

function PickAxe:onEquip(player)
   player.digging = true
   player.onDig = function(dir)
                     self:onDig(player, dir)
                  end
end

function PickAxe:onUnequip(player)
   player.digging = false
   player.onDig = nil
end


function PickAxe:onDig(player, dir)
   if dice.roll{1, 15, 0} == 1 then
      ui.message('Your %s breaks!', self.descr)
      player:destroyItem(self)
   end
end

Armor = Item:subclass {
   armor = 0,
   exclude = true
}

function Armor:init()
   if self.artifact then
      return
   end
   if dice.getInt(1, 20) == 1 then
      self.armor = self.armor + dice.getInt(-2, 3)
   end
end

function Armor._get:descr()
   return ('%s [+%d]'):format(
      Item._get.descr(self),
      self.armor)
end

function Armor:onEquip(player)
   player.armor = player.armor + self.armor
end

function Armor:onUnequip(player)
   player.armor = player.armor - self.armor
end

Helmet = Armor:subclass {
   armor = 1,
   glyph = {'[', C.grey},
   name = 'helmet',
   slot = 'helmet',

   level = 1,
}

EmptyBottle = Item:subclass {
   glyph = {'!', C.grey},
   name = 'empty bottle',

   level = 1,
}

Potion = Item:subclass {
   exclude = true,
}

function Potion:onUse(player)
   ui.message('You drink %s.', self.descr_the)
   self:onDrink(player)
   player:destroyItem(self)
end

PotionHealth = Potion:subclass {
   glyph = {'!', C.green},
   name = 'potion of health',

   level = 1,

   onDrink =
      function(self, player)
         player.hp = player.hp + math.floor(player.maxHp/2)
         player.hp = math.min(player.hp, player.maxHp)
      end,
}

BoostingPotion = Potion:subclass {
   exclude = true,
   onDrink =
      function(self, player)
         player:addBoost(self.boost, self.boostTurns)
      end
}

PotionNightVision = BoostingPotion:subclass {
   glyph = {'!', C.yellow},
   name = 'potion of night vision',

   boost = 'nightVision',
   boostTurns = 50,
   level = 3,
}

PotionSpeed = BoostingPotion:subclass {
   glyph = {'!', C.blue},
   name = 'potion of speed',

   boost = 'speed',
   boostTurns = 50,
   level = 4,
}

PotionStrength = BoostingPotion:subclass {
   glyph = {'!', C.red},
   name = 'potion of strength',

   boost = 'strength',
   boostTurns = 50,
   level = 4,
}

Stone = Item:subclass {
   glyph = {'*', C.darkGrey},
   name = 'stone',
   exclude = true,
}

ArtifactWeapon = Weapon:subclass {
   glyph = {'(', C.lighterBlue},
   name = 'Axe of Thorgrim',

   attackDice = {2, 10, 2},
   exclude = true,
   artifact = true,
}

ArtifactHelmet = Armor:subclass {
   glyph = {'[', C.lighterBlue},
   name = 'Helmet of Dwarven Kings',
   slot = 'helmet',

   armor = 5,
   exclude = true,
   artifact = true,
}

N_ARTIFACTS = 1
