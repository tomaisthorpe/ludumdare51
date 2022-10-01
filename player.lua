local Class = require("hump.class")

local Player = Class {
  init = function (self, game, world)
    self.game = game

    self.object = world:newRectangleCollider(400, 200, 32, 32)
    self.object:setCollisionClass('Player')
    self.object:setObject(self)
    self.object:setFixedRotation(true)
    self.object:setLinearDamping(5)
  end,
  speed = 4000,
}

function Player:getX() 
  return self.object:getX()
end

function Player:getY() 
  return self.object:getY()
end

function Player:update(dt)
    local vx = self.speed * self.object:getMass();
    local vy = self.speed * self.object:getMass();

    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
      self.object:applyForce(-vx, 0)
    end

    if love.keyboard.isDown('right') or love.keyboard.isDown('d')  then
      self.object:applyForce(vx, 0)
    end

    if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
      self.object:applyForce(0, -vy)
    end

    if love.keyboard.isDown('down') or love.keyboard.isDown('s') then
      self.object:applyForce(0, vy)
    end
end

function Player:draw()
  love.graphics.push()

  -- Translate as we need to draw at 0,0 for rotation
  love.graphics.translate(self:getX(), self:getY())
  love.graphics.rotate(self.object:getAngle() - math.pi / 2)
  love.graphics.translate(-16, -16)

  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", 0, 0, 32, 32)
  
  love.graphics.pop()
end

return Player