module('text', package.seeall)

require 'tcod'

local C = tcod.color

helpText = [[
--- Dwarftown ---

Dwarftown was once a rich, prosperous dwarven fortress. Unfortunately, a long
time ago it has fallen, conquered by goblins and other vile creatures.

Your task is to find Dwarftown and recover two legendary dwarven Artifacts
lost there. Good luck!

--- Keybindings ---

Move:  numpad,             Inventory:    i
       arrow keys,         Pick up:      g, ,
       yuhjklbn            Drop:         d
Wait:  5, .                Quit:         q, Esc
Look:  x                   Help:         ?
                           Screenshot:   F11
]]


title = 'Dwarftown v0.8'

function getTitleScreen()
   return {
      {C.white, title},
      '',
      {C.lightGrey, 'by hmp <humpolec@gmail.com>'},
      '',
      '',
      '[Press any key to continue]',
   }
end

function getLoadingScreen()
   local sc = getTitleScreen()
   sc[6] = '[Creating the world, please wait...]'
   return sc
end
