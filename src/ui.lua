module('ui', package.seeall)

require 'tcod'
require 'map'

WIDTH = 80
HEIGHT = 25

function init()
   tcod.console.setCustomFont(
      'fonts/terminal10x18.png', tcod.FONT_LAYOUT_ASCII_INROW)
   tcod.console.initRoot(
      WIDTH, HEIGHT, 'Dwarftown', false, tcod.RENDERER_SDL)
   rootConsole = tcod.console.getRoot()
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
         color = color * 0.3
      else
         color = color * 0.5
      end
   end

   return char, color
end

function drawMap()
   rootConsole:clear()
   for x = 0, WIDTH-1 do
      for y = 0, HEIGHT-1 do
         local tile = map.get(x, y)
         local char, color
         if tile then
            local char, color = tileAppearance(tile)
            rootConsole:putCharEx(x, y, char, color,
                                  tcod.color.black)
         end
      end
   end
end
