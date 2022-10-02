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
    if lives == 0 then
        self.lives = 3
        self.level = 1
    else
        self.lives = lives
        self.level = self.level + 1
    end

    Gamestate.push(Game(), self.level, self.lives)
end

return GameManager
