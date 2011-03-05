module('game', package.seeall)

require 'tcod'

require 'ui'
require 'map'
require 'mob'

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
local command = {}
local done = false

function init()
   ui.init()
   map.init()

   player = mob.Player:make()
   player:putAt(3, 3)

   done = false
end

function mainLoop()
   while not done do
      ui.message('Welcome to Dwarftown!')
      ui.update(player)
      ui.newTurn()
      local key = tcod.console.waitForKeypress(true)
      executeCommand(key)
   end
end

function executeCommand(key)
   for keys, cmd in pairs(keybindings) do
      for _, k in ipairs(keys) do
         if ((type(k) == 'string' and key.c == k) or
          (type(k) == 'number' and key.vk == k)) then

            if type(cmd) == 'table' then
               command[cmd[1]](unpack(cmd[2]))
            else
               command[cmd]()
            end
            return
         end
      end
   end
end

function command.walk(dx, dy)
   if player:canWalk(dx, dy) then
      player:walk(dx, dy)
   end
end

function command.quit()
   done = true
end

function command.wait()
   -- ...
end
