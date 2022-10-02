local Gamestate = require("hump.gamestate")

local config = require("config")
local GameManager = require("game-manager")


function love.load()
  Gamestate.registerEvents()
  love.window.setMode(800, 600)
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setFullscreen(config.fullscreen)

  Gamestate.switch(GameManager)

  love.window.setTitle("House Hitman")
end

function setupWindow()
  love.window.setMode(800, 600)
end
