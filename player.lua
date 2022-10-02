local Class = require("hump.class")
local Bullet = require("bullet")

local Player = Class {
  init = function(self, game, world, x, y)
    self.game = game
    self.world = world
    self.image = love.graphics.newImage("assets/player.png")

    self.object = world:newCircleCollider(x, y, 16)
    self.object:setCollisionClass('Player')
    self.object:setObject(self)
    self.object:setFixedRotation(true)
    self.object:setLinearDamping(10)
  end,
  speed = 4000,
  fireRate = 0.15,
  health = 100,
  lastShot = 0,
  dead = false,
  destroyed = false,
}

function Player:destroy()
  if not self.destroyed then
    self.object:destroy()
    self.destroyed = true
  end
end

function Player:damage(dmg)
  self.health = self.health - 0.15 * dmg

  if not self.dead and self.health <= 0 then
    self.dead = true
    self.health = 0
    self.game:gameOver("killed")
  end
end

function Player:getX()
  return self.object:getX()
end

function Player:getY()
  return self.object:getY()
end

function Player:update(dt)
  if self.dead then
    return
  end

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

  local _, _, cx, cy = self.game:getMousePosition()
  local dx = cx - self:getX()
  local dy = cy - self:getY()
  local theta = math.atan2(dy, dx)

  self.object:setAngle(theta)

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
  if self.dead then
    return
  end

  love.graphics.push()

  -- Translate as we need to draw at 0,0 for rotation
  love.graphics.translate(self:getX(), self:getY())
  love.graphics.rotate(self.object:getAngle() - math.pi / 2)
  love.graphics.translate(-16, -16)

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image)
  -- love.graphics.rectangle("fill", 0, 0, 32, 32)

  love.graphics.pop()
end

return Player
