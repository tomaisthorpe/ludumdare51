local Class = require("hump.class")
local config = require("config")

local Wall = Class {
    init = function(self, world, x, y, w, h)
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.obj = world:newRectangleCollider(x, y, w, h)
        self.obj:setCollisionClass('Solid')
        self.obj:setType('static')
    end,
}

function Wall:draw()
    love.graphics.setColor(config.wallColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Wall
