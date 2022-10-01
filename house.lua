local Class = require("hump.class")

local House = Class {
  init = function(self, world, rooms, walls)
    self.world = world
    self.rooms = rooms
    self.walls = walls

    self:setupWalls()
  end,
}

function House:setupWalls()

    for _, wall in ipairs(self.walls) do
        local obj = self.world:newRectangleCollider(wall.x, wall.y, wall.w, wall.h)
        obj:setCollisionClass('Solid')
        obj:setType('static')
    end
end

function House:draw()
    -- Loop through the rooms and just draw them

    for _, room in ipairs(self.rooms) do
        love.graphics.setColor(room.color[1],room.color[2],room.color[3])
        love.graphics.rectangle("fill", room.rect[1].x, room.rect[1].y, room.w, room.h)
    end
end

return House