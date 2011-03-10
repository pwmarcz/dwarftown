module('game', package.seeall)

require 'tcod'

require 'ui'
require 'map'
require 'mob'
require 'item'
require 'mapgen.world'
require 'text'

local K = tcod.k
local C = tcod.color

local keybindings = {
   [{'y', '7', K.KP7}] = {'walk', {-1, -1}},
   [{'k', '8', K.KP8, K.UP}] = {'walk', {0, -1}},
   [{'u', '9', K.KP9}] = {'walk', {1, -1}},
   [{'h', '4', K.KP4, K.LEFT}] = {'walk', {-1, 0}},
   [{'.', '5', K.KP5}] = 'wait',
   [{'l', '6', K.KP6, K.RIGHT}] = {'walk', {1, 0}},
   [{'b', '1', K.KP1}] = {'walk', {-1, 1}},
   [{'j', '2', K.KP2, K.DOWN}] = {'walk', {0, 1}},
   [{'n', '3', K.KP3}] = {'walk', {1, 1}},

   [{'g', ','}] = 'pickUp',
   [{'d'}] = 'drop',
   [{'i'}] = 'inventory',
   [{'c'}] = 'close',
   [{'x', ';'}] = 'look',
   [{'q', K.ESCAPE}] = 'quit',
   [{'?'}] = 'help',
   [{K.F11}] = 'screenshot',
   --[{K.F12}] = 'mapScreenshot',
}

player = nil
turn = 0
wizard = false
local command = {}
local done = false

function init()
   ui.init()
   map.init()

   ui.drawScreen(text.getLoadingScreen())
   local x, y = mapgen.world.createWorld()
   ui.drawScreen(text.getTitleScreen())
   tcod.console.waitForKeypress(true)

   player = mob.Player:make()

   local startingItems
   if not wizard then
      startingItems = {
         item.Torch,
         item.PotionHealing,
      }
   else
      startingItems = {
         item.PotionNightVision,
         item.PickAxe,
         item.Lamp,
         item.ArtifactWeapon,
      }
   end
   for _, icls in ipairs(startingItems) do
      table.insert(player.items, icls:make())
   end

   map.player = player
   player:putAt(x, y)

   turn = 0
   done = false
   leaving = false
end

function mainLoop()
   ui.message('Find Dwarftown!')
   ui.message('Press ? for help.')
   while not done do
      ui.update()
      ui.newTurn()
      local key = tcod.console.waitForKeypress(true)
      executeCommand(key)
      while player.energy <= 0 and not player.dead do
         map.tick()
         turn = turn + 1
      end
      if player.dead then
         if game.wizard then
            if not ui.promptYN('Die? [yn]') then
               player.hp = player.maxHp
               player.dead = false
            end
         end
         if player.dead then
            ui.promptEnter('[Game over. Press ENTER]')
            done = true
         end
      elseif player.leaving then
         done = true
      end
   end
   tcod.console.flush()
end

-- Returns true if player spent a turn
function executeCommand(key)
   local cmd = getCommand(key)
   if type(cmd) == 'table' then
      command[cmd[1]](unpack(cmd[2]))
   elseif type(cmd) == 'string' then
      command[cmd]()
   end
end

function getCommand(key)
   for keys, cmd in pairs(keybindings) do
      for _, k in ipairs(keys) do
         if ((type(k) == 'string' and key.c == k) or
          (type(k) == 'number' and key.vk == k)) then
            return cmd
         end
      end
   end
end

function command.walk(dx, dy)
   player:spendEnergy()
   if player:canAttack(dx, dy) then
      player:attack(dx, dy)
   elseif player:canWalk(dx, dy) then
      player:walk(dx, dy)
   elseif player:canOpen(dx, dy) then
      player:open(dx, dy)
   elseif player:canDig(dx, dy) then
      player:dig(dx, dy)
   else
      player:refundEnergy()
   end
end

function command.close(dx, dy)
   local dirs = {}
   for _, d in ipairs(util.dirs) do
      if player:canClose(d[1], d[2]) then
         table.insert(dirs, d)
      end
   end
   if #dirs == 0 then
      ui.message('There is no door here you can close.')
   elseif #dirs == 1 then
      player:spendEnergy()
      player:close(dirs[1][1], dirs[1][2])
   else
      ui.message('In what direction?')
      ui.newTurn()
      ui.update()
      local key = tcod.console.waitForKeypress(true)
      local cmd = getCommand(key)
      if type(cmd) == 'table' and cmd[1] == 'walk' then
         local dx, dy = unpack(cmd[2])
         if player:canClose(dx, dy) then
            player:spendEnergy()
            player:close(dx, dy)
         end
      end
   end
end

function command.quit()
   if ui.promptYN('Quit? [yn]') then
      done = true
   end
end

function command.wait()
   player:spendEnergy()
   player:wait()
end

function command.pickUp()
   player:spendEnergy()
   local items = player.tile.items
   if items then
      if #items == 1 then
         player:pickUp(items[1])
         return
      end
      local item = ui.promptItems(items, 'Pick up:')
      if item then
         player:pickUp(item)
         return
      else
         player:refundEnergy()
      end
   else
      ui.message('There is nothing here.')
      player:refundEnergy()
   end
end

function command.drop()
   local item = ui.promptItems(player.items, 'Drop:')
   if item then
      player:drop(item)
      player:spendEnergy()
   end
end

function command.inventory()
   local item = ui.promptItems(player.items, 'Use:')
   if item then
      player:use(item)
      player:spendEnergy()
   end
end

function command.look()
   ui.look()
end

function command.help()
   ui.help()
end

function command.screenshot()
   ui.screenshot()
   ui.message(C.green, 'Screenshot saved.')
end

function command.mapScreenshot()
   ui.message('Saving map screenshot...')
   ui.mapScreenshot()
   ui.message(C.green, 'Map screenshot saved.')
end
