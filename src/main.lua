package.path = package.path .. ';wrapper/?.lua'

require 'tcod'

tcod.console.initRoot(80,50,'test', false, tcod.RENDERER_SDL)
tcod.console.credits()