local Class = require("hump.class")
local config = require("config")

local Door = Class {
    init = function(self, world, x, y, vertical)
        self.x = x
        self.y = y
        self.vertical = vertical

        local hinge = world:newCircleCollider(x, y, 2)
        hinge:setType('static')

        self.w = 47
        self.h = 2

        if vertical then
            self.w = 2
            self.h = 47
        end

        self.obj = world:newRectangleCollider(x, y, self.w, self.h)
        self.obj:setCollisionClass('Solid')

        world:addJoint('RevoluteJoint', hinge, self.obj, x, y, false)
    end,
}

function Door:getX()
    return self.obj:getX()
end

function Door:getY()
    return self.obj:getY()
end

function Door:draw()
    love.graphics.push()

    love.graphics.setColor(config.doorColor)
    -- Translate as we need to draw at 0,0 for rotation
    love.graphics.translate(self:getX(), self:getY())
    love.graphics.rotate(self.obj:getAngle())

    if self.vertical then
        love.graphics.translate(0, -(config.doorWidth * config.gridScale) / 2)
    else
        love.graphics.translate(-(config.doorWidth * config.gridScale) / 2, 0)
    end


    love.graphics.rectangle("fill", 0, 0, self.w, self.h)

    love.graphics.pop()
end

return Door
