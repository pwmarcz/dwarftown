module('ui', package.seeall)

require 'tcod'
require 'map'
require 'util'
require 'text'

local C = tcod.color
local K = tcod.k

SCREEN_W = 80
SCREEN_H = 25

VIEW_W = 48
VIEW_H = 23

STATUS_W = 29
STATUS_H = 12

MESSAGES_W = 30
MESSAGES_H = 10

coloredMem = false

local viewConsole
local messagesConsole
local rootConsole
local statusConsole

messages = {}

local ord = string.byte
local chr = string.char

function init()
   tcod.console.setCustomFont(
      'fonts/terminal10x18.png', tcod.FONT_LAYOUT_ASCII_INROW, 16, 16)
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
   drawMap(map.player.x, map.player.y)
   drawMessages()
   drawStatus(map.player)
   blitConsoles()
end

function blitConsoles()
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
      msg.color = C.white
   else
      msg.text = string.format(...)
      msg.color = a or C.white
   end
   msg.text = util.capitalize(msg.text)
   table.insert(messages, msg)
   drawMessages()
end

-- ui.prompt({K.ENTER, K.KPENTER}, '[Game over. Press ENTER]')
function prompt(keys, ...)
   message(...)
   update()
   newTurn()
   while true do
      local key = tcod.console.waitForKeypress(true)
      for _, k in ipairs(keys) do
         if k == key.c or k == key.vk then
            return k
         elseif not k then
            return false
         end
      end
   end
end

function promptYN(...)
   local result = prompt({'y', false}, C.green, ...)
   --table.remove(messages)
   return result == 'y'
end

function promptEnter(...)
   prompt({tcod.k.ENTER, tcod.k.KPENTER}, C.yellow, ...)
end

function promptItems(items, ...)
   update()
   local text = string.format(...)
   itemConsole = tcod.Console(VIEW_W, #items + 2)
   itemConsole:setDefaultForeground(C.white)
   itemConsole:print(0, 0, text)

   local letter = ord('a')
   for i, it in ipairs(items) do
      local s
      local color
      if it.artifact then
         color = C.lightGreen
      else
         color = C.white
      end
      if it.equipped then
         s = ('%c *   %s'):format(letter+i-1, it.descr)
      else
         color = color * 0.5
         s = ('%c     %s'):format(letter+i-1, it.descr)
      end
      itemConsole:setDefaultForeground(color)
      itemConsole:print(0, i+1, s)

      local char, color = glyph(it.glyph)
      itemConsole:putCharEx(4, i+1, char, color,
                            C.black)
   end

   tcod.console.blit(itemConsole, 0, 0, VIEW_W, #items + 2,
             rootConsole, 1, 1)
   tcod.console.flush()
   local key = tcod.console.waitForKeypress(true)
   if ord(key.c) then
      local i = ord(key.c) - letter + 1
      if items[i] then
         return items[i]
      end
   end
end

function stringItems(items)
   local lines = {}
   for i, it in ipairs(items) do
      local letter = ord('a')-1+i
      local s
      if it.equipped then
         s = ('%c * %s %s'):format(letter, it.glyph[1], it.descr)
      else
         s = ('%c   %s %s'):format(letter, it.glyph[1], it.descr)
      end
      table.insert(lines, s)
   end
   return table.concat(lines, '\n')
end

function newTurn()
   local i = #messages
   while i > 0 and messages[i].new do
      messages[i].new = false
      i = i - 1
   end
end

function drawStatus(player)
   local sector = map.getSector(player.x, player.y)
   local sectorName, sectorColor
   if sector then
      sectorName = sector.name
      sectorColor = sector.color
   end
   local lines = {
      {sectorColor or C.white, sectorName or ''},
      {''},
      {'Turn     %d', game.turn},
      {''}, -- line 4: health bar
      {'HP       %d/%d', player.hp, player.maxHp},
      {'Level    %d (%d/%d)', player.level, player.exp, player.maxExp},
      {'Attack   %s', dice.describe(player.attackDice)},
   }

   if player.armor ~= 0 then
      table.insert(lines, {'Armor    %s', util.signedDescr(player.armor)})
   end
   if player.speed ~= 0 then
      table.insert(lines, {'Speed    %s', util.signedDescr(player.speed)})
   end

   statusConsole:clear()
   statusConsole:setDefaultForeground(C.lightGrey)
   for i, msg in ipairs(lines) do
      local s
      if type(msg[1]) == 'string' then
         statusConsole:setDefaultForeground(C.lightGrey)
         s = string.format(unpack(msg))
      else
         statusConsole:setDefaultForeground(msg[1])
         s = string.format(unpack(msg, 2))
      end
      statusConsole:print(0, i-1, s)
   end

   if player.hp < player.maxHp then
      drawHealthBar(3, player.hp / player.maxHp)
   end

   if player.enemy then
      local m = player.enemy
      if m.x and m.visible and
         map.dist(player.x, player.y, m.x, m.y) <= 2
      then
         local s = ('L%d %-18s %s'):format(
            m.level, m.descr, dice.describe(m.attackDice))
         statusConsole:setDefaultForeground(m.glyph[2])
         statusConsole:print(0, STATUS_H-2, s)
         if m.hp < m.maxHp then
            drawHealthBar(STATUS_H-1, m.hp/m.maxHp, m.glyph[2])
         end
      else
         player.enemy = nil
      end
   end
end

function drawHealthBar(y, fract, color)
   color = color or C.white
   local health = math.ceil((STATUS_W-2) * fract)
   statusConsole:putCharEx(0, y, ord('['), C.grey, C.black)
   statusConsole:putCharEx(STATUS_W - 1, y, ord(']'), C.grey, C.black)
   for i = 1, STATUS_W-2 do
      if i - 1 < health then
         statusConsole:putCharEx(i, y, ord('*'), color, C.black)
      else
         statusConsole:putCharEx(i, y, ord('-'), C.grey, C.black)
      end
   end
end


function drawMessages()
   messagesConsole:clear()

   local y = MESSAGES_H
   local i = #messages

   while y > 0 and i > 0 do
      local msg = messages[i]

      local color = msg.color
      if not msg.new then
         color = color * 0.6
      end

      messagesConsole:setDefaultForeground(color)
      local lines = splitMessage(msg.text, MESSAGES_W)
      for i, line in ipairs(lines) do
         local y1 = y - #lines + i - 1
         if y1 >= 0 then
            messagesConsole:print(0, y1, line)
         end
      end
      y = y - #lines
      i = i - 1
   end
end

function splitMessage(text, n)
   local lines = {}
   for _, w in ipairs(util.split(text, ' ')) do
      if #lines > 0 and w:len() + lines[#lines]:len() + 1 < n then
         lines[#lines] = lines[#lines] .. ' ' .. w
      else
         table.insert(lines, w)
      end
   end
   return lines
end

function drawMap(xPos, yPos)
   local xc = math.floor(VIEW_W/2)
   local yc = math.floor(VIEW_H/2)
   viewConsole:clear()
   for xv = 0, VIEW_W-1 do
      for yv = 0, VIEW_H-1 do
         local x = xv - xc + xPos
         local y = yv - yc + yPos
         local tile = map.get(x, y)
         if not tile.empty then
            local char, color = tileAppearance(tile)
            viewConsole:putCharEx(xv, yv, char, color,
                                  C.black)
         end
      end
   end
end

function glyph(g)
   local char = ord(g[1])
   local color = g[2] or C.pink
   return char, color
end

function tileAppearance(tile)
   local char, color

   if tile.visible then
      char, color = glyph(tile:getSeenGlyph())
      if map.player.nightVision then
         if tile.seenLight > 0 then
            color = color * 2
         end
      else
         if tile.seenLight == 0 then
            color = color * 0.7

            --[[
            local sat = color:getSaturation()
            local val = color:getValue()
            color = tcod.Color(color.r,color.g,color.b)
            color:setSaturation(sat*0.8)
            color:setValue(val*0.7)
            --]]
         end
      end
   else
      char, color = glyph(tile.memGlyph)
      if coloredMem then
         if tile.memLight == 0 then
            color = color * 0.35
         else
            color = color * 0.6
         end
      else
         if tile.memLight == 0 then
            color = C.darkerGrey * 0.6
         else
            color = C.darkerGrey
         end
      end
   end

   return char, color
end

function look()
   -- on-screen center
   local xc = math.floor(VIEW_W/2)
   local yc = math.floor(VIEW_H/2)
   -- on-map center
   local xPos, yPos = map.player.x, map.player.y
   -- on-screen cursor position
   local xv, yv = xc, yc

   local savedMessages = messages
   messages = {}

   ui.message('Look mode: use movement keys to look, ' ..
              'Alt-movement to jump.')
   ui.message('')
   local messagesLevel = #messages
   while true do

      -- Draw highlighted character
      local char = viewConsole:getChar(xv, yv)
      local color = viewConsole:getCharForeground(xv, yv)
      if char == ord(' ') then
         color = C.white
      end

      viewConsole:putCharEx(xv, yv, char, C.black, color)

      -- Describe position
      local x, y = xv - xc + xPos, yv - yc + yPos
      describeTile(map.get(x, y))

      blitConsoles()

      -- Clean up
      viewConsole:putCharEx(xv, yv, char, color, C.black)
      while #messages > messagesLevel do
         table.remove(messages, #messages)
      end

      -- Get keyboard input
      local key = tcod.console.waitForKeypress(true)
      local cmd = game.getCommand(key)
      if type(cmd) == 'table' and cmd[1] == 'walk' then
         local dx, dy = unpack(cmd[2])

         if key.lalt or key.ralt then
            dx, dy = dx*10, dy*10
         end

         if 0 <= xv+dx and xv+dx < VIEW_W and
            0 <= yv+dy and yv+dy < VIEW_H
         then
            xv, yv = xv+dx, yv+dy
         else -- try to scroll instead of moving the cursor
            if 0 <= xPos+dx and xPos+dx < map.WIDTH and
               0 <= yPos+dy and yPos+dy < map.HEIGHT
            then
               xPos = xPos + dx
               yPos = yPos + dy
               drawMap(xPos, yPos)
            end

         end

      elseif key.vk ~= K.SHIFT and key.vk ~= K.ALT and key.vk ~= K.CONTROL then
         break
      end
   end

   messages = savedMessages
   blitConsoles()
end

function describeTile(tile)
   if tile and tile.visible then
      message(tile.glyph[2], '%s.', tile.name)
      if tile.mob and tile.mob.visible then
         message(tile.mob.glyph[2], '%s.', tile.mob.descr)
      end
      if tile.items then
         for _, item in ipairs(tile.items) do
            message(item.glyph[2], '%s.', item.descr)
         end
      end
   else
      message(C.grey, 'Out of sight.')
   end
end

function help()
   rootConsole:clear()
   rootConsole:setDefaultForeground(C.lighterGrey)
   rootConsole:print(1, 1, text.helpText)
   tcod.console.flush()
   tcod.console.waitForKeypress(true)
end

function screenshot()
   tcod.system.saveScreenshot(nil)
end

function stringScreenshot()
   local lines = {}

   for y = 0, SCREEN_H-1 do
      local line = ''
      for x = 0, SCREEN_W-1 do
         line = line .. chr(rootConsole:getChar(x, y))
      end
      table.insert(lines, line)
   end

   local sep = ''
   for x = 0, SCREEN_W-1 do
      sep = sep .. '-'
   end
   table.insert(lines, sep)
   table.insert(lines, 1, sep)

   return table.concat(lines, '\n')
end

---[[
function mapScreenshot()
   local con = tcod.Console(map.WIDTH, map.HEIGHT)
   con:clear()
   ---[[
   for x = 0, map.WIDTH-1 do
      for y = 0, map.HEIGHT-1 do
         --print(x,y)
         local tile = map.get(x, y)
         if not tile.empty then
            local char, color = tileAppearance(tile)
            con:putCharEx(x, y, char, color, C.black)
         end
      end
   end
   --]]
   local image = tcod.Image(con)
   print(con:getWidth(), con:getHeight())
   --image:refreshConsole(con)
   image:save('map.png')
end
--]]

function drawScreen(sc)
   rootConsole:clear()
   local start = math.floor((SCREEN_H-#sc-1)/2)
   local center = math.floor(SCREEN_W/2)
   for i, line in ipairs(sc) do
      if type(line) == 'table' then
         local color
         color, line = unpack(line)
         rootConsole:setDefaultForeground(color)
      end
      rootConsole:printEx(center, start+i-1, tcod.BKGND_SET, tcod.CENTER,
                          line)
   end
   tcod.console.flush()
end
