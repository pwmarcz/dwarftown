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
   turns = 30,

   level = 2,
}

EmptyBottle = Item:subclass {
   glyph = {'!', C.grey},
   name = 'empty bottle',

   level = 1,
}

Weapon = Item:subclass {
   exclude = true,
   slot = 'weapon',
}

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
      player:destroyFromSlot('weapon')
   end
end

Armor = Item:subclass {
   armor = 0,
   exclude = true
}

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
