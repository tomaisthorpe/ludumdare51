local Class = require("hump.class")

require("a-star")

local Enemy = Class {
  init = function(self, game, world, x, y)
    self.game = game

    self.object = world:newRectangleCollider(x, y, 32, 32)
    self.object:setCollisionClass('Enemy')
    self.object:setObject(self)
    self.object:setFixedRotation(true)
    self.object:setLinearDamping(5)

    self.health = 100
  end,
  speed = 1000,
  path = nil,
  dead = false,
}

function Enemy:getX()
  return self.object:getX()
end

function Enemy:getY()
  return self.object:getY()
end

function Enemy:destroy()
  if self.dead == false and self.object then
    self.object:destroy()
    self.dead = true
  end
end

function Enemy:damage(dmg)
  self.health = self.health - 0.3 * dmg

  if self.health <= 0 then
    self:destroy()
    self.health = 0
  end
end

function Enemy:moveTo(dt, x, y, modifier)
  local dx = x - self:getX()
  local dy = y - self:getY()
  local theta = math.atan2(dy, dx)

  self.object:setAngle(theta)
  self.object:applyForce(math.cos(theta) * self.speed * modifier, math.sin(theta) * self.speed * modifier)
end

function Enemy:update(dt)
  local vx = self.speed * self.object:getMass()
  local vy = self.speed * self.object:getMass()

  if self.path == nil and
      astar.dist_between({ x = self:getX(), y = self:getY() },
        { x = self.game.player:getX(), y = self.game.player:getY() }) < 300 then
    self.path = self.game.house:path(
      { x = self:getX(), y = self:getY() },
      { x = self.game.player:getX(), y = self.game.player:getY() }
    )
  end

  if self.path then
    if astar.dist_between(self.path[1], { x = self:getX(), y = self:getY() }) < 16 then
      table.remove(self.path, 1)
    end

    if #self.path == 0 then
      self.path = nil
    else
      local target = self.path[1]
      self:moveTo(dt, target.x, target.y, 1)
    end
  end
end

function Enemy:draw()
  love.graphics.push()

  -- Translate as we need to draw at 0,0 for rotation
  love.graphics.translate(self:getX(), self:getY())
  love.graphics.rotate(self.object:getAngle() - math.pi / 2)
  love.graphics.translate(-16, -16)

  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", 0, 0, 32, 32)

  love.graphics.pop()

  if self.path then
    self.game:drawPath(self.path)
  end
end

return Enemy
