local Class = require("hump.class")
local Bullet = require("bullet")

local Player = Class {
  init = function(self, game, world, x, y)
    self.game = game
    self.world = world

    self.object = world:newRectangleCollider(x, y, 32, 32)
    self.object:setCollisionClass('Player')
    self.object:setObject(self)
    self.object:setFixedRotation(true)
    self.object:setLinearDamping(5)
  end,
  speed = 4000,
  fireRate = 0.2,
  lastShot = 0,
  health = 100,
}

function Player:damage(dmg)
  self.health = self.health - 0.3 * dmg

  if self.health <= 0 then
    self.dead = true
    self.health = 0
    self.game:gameOver()
  end
end

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

  if love.keyboard.isDown('right') or love.keyboard.isDown('d') then
    self.object:applyForce(vx, 0)
  end

  if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
    self.object:applyForce(0, -vy)
  end

  if love.keyboard.isDown('down') or love.keyboard.isDown('s') then
    self.object:applyForce(0, vy)
  end

  if love.mouse.isDown(1) then
    self:shoot()
  end
end

function Player:shoot()
  -- Check the user can actually shoot
  if self.lastShot >= love.timer.getTime() - self.fireRate then
    return
  end

  self.lastShot = love.timer.getTime()

  local _, _, cx, cy = self.game:getMousePosition()

  local dx = cx - self:getX()
  local dy = cy - self:getY()
  local theta = math.atan2(dy, dx)

  local bullet = Bullet(self.game, self.world, self:getX(), self:getY(), theta, 'Enemy')
  self.game:addEntity(bullet)
end

function Player:draw()
  love.graphics.push()

  -- Translate as we need to draw at 0,0 for rotation
  love.graphics.translate(self:getX(), self:getY())
  love.graphics.rotate(self.object:getAngle() - math.pi / 2)
  love.graphics.translate(-16, -16)

  love.graphics.setColor(0, 1, 0)
  love.graphics.rectangle("fill", 0, 0, 32, 32)

  love.graphics.pop()
end

return Player
