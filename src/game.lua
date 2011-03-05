module('game', package.seeall)

require 'tcod'

require 'ui'
require 'map'
require 'mob'
require 'item'

local K = tcod.k

local keybindings = {
   [{'y', '7'}] = {'walk', {-1, -1}},
   [{'k', '8', K.UP}] = {'walk', {0, -1}},
   [{'u', '9'}] = {'walk', {1, -1}},
   [{'h', '4', K.LEFT}] = {'walk', {-1, 0}},
   [{'.', '5'}] = 'wait',
   [{'l', '6', K.RIGHT}] = {'walk', {1, 0}},
   [{'b', '1'}] = {'walk', {-1, 1}},
   [{'j', '2', K.DOWN}] = {'walk', {0, 1}},
   [{'n', '3'}] = {'walk', {1, 1}},
   [{'q'}] = 'quit',
}

player = nil
turn = 0
local command = {}
local done = false

function init()
   ui.init()
   map.init()

   player = mob.Player:make()
   player:putAt(3, 3)

   gobbo = mob.Goblin:make()
   gobbo:putAt(5, 5)
   map.addMonster(gobbo)

   sword = item.Sword:make()
   map.get(7, 7):putItem(sword)

   turn = 0
   done = false
end

function mainLoop()
   ui.message('Welcome to Dwarftown!')
   while not done do
      ui.update()
      ui.newTurn()
      local key = tcod.console.waitForKeypress(true)
      if executeCommand(key) then
         turn = turn + 1
         map.act()
      end
      if player.dead then
         ui.prompt({K.ENTER, K.KPENTER}, '[Game over. Press ENTER]')
         done = true
      end
   end
end

-- Returns true if player spent a turn
function executeCommand(key)
   for keys, cmd in pairs(keybindings) do
      for _, k in ipairs(keys) do
         if ((type(k) == 'string' and key.c == k) or
          (type(k) == 'number' and key.vk == k)) then

            if type(cmd) == 'table' then
               return command[cmd[1]](unpack(cmd[2]))
            else
               return command[cmd]()
            end
         end
      end
   end
end

function command.walk(dx, dy)
   if player:canAttack(dx, dy) then
      player:attack(dx, dy)
      return true
   elseif player:canWalk(dx, dy) then
      player:walk(dx, dy)
      return true
   end
end

function command.quit()
   if ui.prompt({'y', 'n'}, 'Quit? [yn]') == 'y' then
      done = true
   end
end

function command.wait()
   -- ...
end