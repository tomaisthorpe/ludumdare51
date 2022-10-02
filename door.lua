local Class = require("hump.class")
local config = require("config")
local inspect = require("inspect")

local Door = Class {
    init = function(self, world, x, y, vertical)
        self.x = x
        self.y = y
        self.vertical = vertical

        self.hinge = world:newCircleCollider(x, y, 2)
        self.hinge:setCollisionClass('Hinge')
        self.hinge:setType('static')


        self.w = 48
        self.h = 4

        if vertical then
            self.w = 4
            self.h = 48
            x = x - 2
        else
            y = y - 2
        end

        self.obj = world:newRectangleCollider(x, y, self.w, self.h)
        self.obj:setCollisionClass('Door')
        self.obj:setMass(1)
        self.obj:setLinearDamping(4)

        self.joint = world:addJoint('RevoluteJoint', self.hinge, self.obj, x + 2, y + 2, true)

        self.joint:setMaxMotorTorque(5000)
        self.joint:setMotorEnabled(true)

        self.joint:setLimits(-math.pi * 0.7, math.pi * 0.7)
        self.joint:setLimitsEnabled(true)
    end,
    dead = false,
}

function Door:destroy()
    if not self.dead then
        self.joint:destroy()
        self.obj:destroy()
        self.hinge:destroy()
        self.dead = true
    end
end

function Door:getX()
    return self.obj:getX()
end

function Door:getY()
    return self.obj:getY()
end

function Door:update(dt)
    if self.dead then
        return
    end

    -- Target is 0 so don't need to compare
    local diff = self.obj:getAngle()

    self.joint:setMotorSpeed(-diff * 50)
end

function Door:draw()
    if self.dead then
        return
    end

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
