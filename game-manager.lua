local Gamestate = require("hump.gamestate")
local Game = require("game")

local GameManager = {
    lives = 3,
    level = 1,
}

function GameManager:enter()
    Gamestate.push(Game(), self.level, self.lives)
end

function GameManager:resume(prev, lives)
    self.lives = lives
    self.level = self.level + 1

    Gamestate.push(Game(), self.level, self.lives)
end

return GameManager
