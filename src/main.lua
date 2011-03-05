package.path = package.path .. ';src/?.lua;wrapper/?.lua'

require 'game'

game.init()
game.mainLoop()
