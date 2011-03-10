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
   local s = self.name
   if self.attackDice then
      s = s .. (' (%s)'):format(dice.describe(self.attackDice))
   end
   if self.armor and self.armor ~= 0 then
      s = s .. (' [%s]'):format(util.signedDescr(self.armor))
   end
   if self.speed and self.speed ~= 0 then
      s = s .. (' [Sp%s]'):format(util.signedDescr(self.speed))
   end
   return s
end

function Item:onEquip(player)
   if self.armor then
      player.armor = player.armor + self.armor
   end
   if self.speed then
      player.speed = player.speed + self.speed
   end
end

function Item:onUnequip(player)
   if self.armor then
      player.armor = player.armor - self.armor
   end
   if self.speed then
      player.speed = player.speed - self.speed
   end
end

function Item._get:descr_a()
   if self.plural then
      return self.descr
   else
      return util.descr_a(self.descr)
   end
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
   Item.onEquip(self, player)
   player:changeLightRadius(self.lightRadius)
end

function LightSource:onUnequip(player)
   player:changeLightRadius(-self.lightRadius)
   Item.onUnequip(self, player)
end

Torch = LightSource:subclass {
   glyph = {'/', C.darkerOrange},
   name = 'torch',
   lightRadius = 7,
   turns = 50,

   level = 2,
}

Lamp = LightSource:subclass {
   glyph = {']', C.yellow},
   name = 'lamp',
   lightRadius = 9,
   turns = 300,

   level = 6,
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

Sword = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'sword',

   attackDice = {1, 6, 0},
   level = 2,
}

Dagger = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'dagger',

   attackDice = {1, 4, 0},
   level = 1,
}

BrokenDagger = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'broken dagger',

   attackDice = {1, 2, 1},
   level = 1,
}

LongSword = Weapon:subclass {
   glyph = {'(', C.white},
   name = 'long sword',

   attackDice = {1, 8, 0},
   level = 4,
}

Spear = Weapon:subclass {
   glyph = {'|', C.white},
   name = 'spear',

   attackDice = {1, 6, 3},
   level = 5,
}

LargeHammer = Weapon:subclass {
   glyph = {'(', C.darkGrey},
   name = 'large hammer',

   attackDice = {1, 12, 0},
   level = 5,
}

TwoHandedSword = Weapon:subclass {
   glyph = {'(', C.lightGrey},
   name = 'two-handed sword',

   attackDice = {2, 10, 0},
   level = 7,
}


PickAxe = Weapon:subclass {
   exclude = true,
   glyph = {'{', C.lightGrey},
   name = 'pick-axe',

   attackDice = {1, 4, 2},

   level = 5,
}

function PickAxe:onEquip(player)
   Item.onEquip(self, player)
   player.digging = true
   player.onDig = function(dir)
                     self:onDig(player, dir)
                  end
end

function PickAxe:onUnequip(player)
   player.digging = false
   player.onDig = nil
   Item.onUnequip(self, player)
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

Helmet = Armor:subclass {
   armor = 1,
   glyph = {'[', C.grey},
   name = 'helmet',
   slot = 'helmet',

   level = 1,
}

HornedHelmet = Armor:subclass {
   armor = 2,
   glyph = {'[', C.white},
   name = 'horned helmet',
   slot = 'helmet',

   level = 3,
}

LeatherArmor = Armor:subclass {
   armor = 1,
   glyph = {'[', C.darkOrange},
   name = 'leather armor',
   slot = 'mail',

   level = 3,
}

UglyClothes = Armor:subclass {
   armor = 0,
   glyph = {'[', C.green},
   name = 'leather armor',
   slot = 'mail',

   level = 1,
}

PlateMail = Armor:subclass {
   speed = -3,
   armor = 4,
   glyph = {'[', C.lightBlue},
   name = 'plate mail',
   slot = 'mail',

   level = 6,
}

LeatherBoots = Armor:subclass {
   armor = 1,
   glyph = {'[', C.darkOrange},
   name = 'leather boots',
   plural = true,

   slot = 'boots',

   level = 3,
}

HeavyBoots = Armor:subclass {
   armor = 2,
   speed = -1,
   glyph = {'[', C.grey},
   name = 'heavy boots',
   plural = true,

   slot = 'boots',

   level = 4,
}


BootsSpeed = Armor:subclass {
   armor = -1,
   speed = 3,
   glyph = {'[', C.darkGrey},
   name = 'boots of speed',
   plural = true,

   slot = 'boots',

   level = 6,
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

   speed = 3,
}

ArtifactHelmet = Armor:subclass {
   glyph = {'[', C.lighterBlue},
   name = 'Helmet of the Dwarven Kings',
   slot = 'helmet',

   armor = 6,
   exclude = true,
   artifact = true,
}

N_ARTIFACTS = 2
