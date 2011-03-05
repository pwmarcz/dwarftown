module('ui', package.seeall)

require 'tcod'
require 'map'
require 'game'
require 'util'

SCREEN_W = 80
SCREEN_H = 25

VIEW_W = 48
VIEW_H = 23

STATUS_W = 30
STATUS_H = 10

MESSAGES_W = 30
MESSAGES_H = 6

local viewConsole
local messagesConsole
local rootConsole
local statusConsole

local messages

function init()
   tcod.console.setCustomFont(
      'fonts/terminal10x18.png', tcod.FONT_LAYOUT_ASCII_INROW)
   tcod.console.initRoot(
      SCREEN_W, SCREEN_H, 'Dwarftown', false, tcod.RENDERER_SDL)
   rootConsole = tcod.console.getRoot()
   viewConsole = tcod.Console(VIEW_W, VIEW_H)
   messagesConsole = tcod.Console(MESSAGES_W, MESSAGES_H)
   statusConsole = tcod.Console(STATUS_W, STATUS_H)

   messages = {}
end

function update()
   rootConsole:clear()
   drawMap(game.player.x, game.player.y)
   drawMessages()
   drawStatus(game.player)
   tcod.console.blit(
      viewConsole, 0, 0, VIEW_W, VIEW_H,
      rootConsole, 1, 1)
   tcod.console.blit(
      statusConsole, 0, 0, STATUS_W, STATUS_H,
      rootConsole, 1+VIEW_W+1, 1)
   tcod.console.blit(
      messagesConsole, 0, 0, MESSAGES_W, MESSAGES_H,
      rootConsole, 1+VIEW_W+1, 1+STATUS_H+1)
   tcod.console.flush()
end

-- ui.message(color, format, ...)
-- ui.message(format, ...)
function message(a, ...)
   local msg = {new = true}
   if type(a) == 'string' then
      msg.text = string.format(a, ...)
      msg.color = tcod.color.white
   else
      msg.text = string.format(...)
      msg.color = a
   end
   msg.text = util.capitalize(msg.text)

   table.insert(messages, msg)
   ui.update()
end

-- ui.prompt({K.ENTER, K.KPENTER}, '[Game over. Press ENTER]')
function prompt(keys, ...)
   message(...)
   newTurn()
   while true do
      local key = tcod.console.waitForKeypress(true)
      for _, k in ipairs(keys) do
         if k == key.c or k == key.vk then
            return k
         end
      end
   end
end

function promptItems(items, ...)
   update()
   local text = string.format(...)
   itemConsole = tcod.Console(VIEW_W, #items + 2)
   itemConsole:setDefaultForeground(tcod.color.white)
   itemConsole:printEx(
      0, 0, tcod.BKGND_NONE, tcod.LEFT, text)

   itemConsole:setDefaultForeground(tcod.color.lightGrey)

   local letter = string.byte('a')
   for i, item in ipairs(items) do
      local s = string.format(' %c   %s', letter+i-1, item.descr)
      itemConsole:printEx(
         0, i+1, tcod.BKGND_NONE, tcod.LEFT, s)

      local char, color = glyph(item.glyph)
      itemConsole:putCharEx(3, i+1, char, color,
                            tcod.color.black)
   end

   tcod.console.blit(itemConsole, 0, 0, VIEW_W, #items + 2,
             rootConsole, 1, 1)
   tcod.console.flush()
   local key = tcod.console.waitForKeypress(true)
   local i = string.byte(key.c) - letter + 1
   if items[i] then
      return items[i]
   end
end

function newTurn()
   local i = #messages
   while i > 0 and messages[i].new do
      messages[i].new = false
      i = i - 1
   end
end

function drawStatus(player)
   local lines = {
      {'Turn %d', game.turn},
      {''},
      {'Level %d', player.level},
      {'HP: %d/%d', player.hp, player.maxHp},
   }

   statusConsole:clear()
   statusConsole:setDefaultForeground(tcod.color.lightGrey)
   for i, msg in ipairs(lines) do
      statusConsole:printEx(
         0, i-1, tcod.BKGND_NONE, tcod.LEFT, string.format(unpack(msg)))
   end
end

function drawMessages()
   messagesConsole:clear()
   local n = math.min(#messages, MESSAGES_H)
   for i = 1, n do
      local msg = messages[#messages-n+i]
      local color = msg.color
      if not msg.new then
         color = color * 0.6
      end
      messagesConsole:setDefaultForeground(color)
      messagesConsole:printEx(
         0, i-1, tcod.BKGND_NONE, tcod.LEFT, msg.text)
   end
end

function drawMap(xPos, yPos)
   xc = math.floor(VIEW_W/2)
   yc = math.floor(VIEW_H/2)
   viewConsole:clear()
   for xv = 0, VIEW_W-1 do
      for yv = 0, VIEW_H-1 do
         local x = xv - xc + xPos
         local y = yv - yc + yPos
         local tile = map.get(x, y)
         local char, color
         if tile then
            local char, color = tileAppearance(tile)
            viewConsole:putCharEx(xv, yv, char, color,
                                  tcod.color.black)
         end
      end
   end
end

function glyph(g)
   local char = string.byte(g[1])
   local color = g[2] or tcod.color.pink
   return char, color
end

function tileAppearance(tile)
   local char, color

   if tile.visible then
      char, color = glyph(tile:getSeenGlyph())
      if tile.light == 0 then
         color = color * 0.75
      end
   else
      char, color = glyph(tile.memGlyph)
      if tile.memLight == 0 then
         color = color * 0.4
      else
         color = color * 0.6
      end
   end

   return char, color
end

