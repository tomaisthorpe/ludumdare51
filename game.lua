local config = require("config")
local HouseGenerator = require("house-generator")
local wf = require("windfield")
local Player = require("player")
local Camera = require("Camera")
local inspect = require("inspect")
local Enemy = require("enemy")

local Game = {
  translate = { 0, 0 },
  scaling = 1,
}

function Game:init()
  -- Window setup
  Game:calculateScaling()

end

function Game:enter()
  self.world = wf.newWorld(0, 0, true)
  self.world:addCollisionClass('Solid')
  self.world:addCollisionClass('Player')
  self.world:addCollisionClass('Enemy')
  self.world:addCollisionClass('Bullet', { ignores = { 'Bullet', 'Solid', 'Enemy', 'Player' } })

  local houseGen = HouseGenerator(self.world)
  self.house = houseGen:generate()
  houseGen:draw()

  self.player = Player(self, self.world)
  self.enemies = {}
  table.insert(self.enemies, Enemy(self, self.world, 32, 32))

  self.entities = {}

  self.camera = Camera(0, 0, 800, 600)
  self.camera:setFollowStyle('TOPDOWN_TIGHT')

  -- self.path = self.house:path(
  --   { x = 2, y = 2 }, { x = 30, y = 15 })
end

function Game:update(dt)
  self.world:update(dt)

  self.player:update(dt)

  for i, e in ipairs(self.enemies) do
    if e.dead then
      table.remove(self.enemies, i)
    else
      e:update(dt)
    end
  end

  for i, e in ipairs(self.entities) do
    if e.dead then
      table.remove(self.entities, i)
    else
      e:update(dt)
    end
  end

  self.camera:update(dt)
  self.camera:follow(self.player:getX(), self.player:getY())
end

function Game:draw()
  love.graphics.push()
  love.graphics.translate(Game.translate[1], Game.translate[2])
  love.graphics.scale(Game.scaling)

  love.graphics.setColor(1, 1, 1)

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, 800, 600)

  self.camera:attach()
  self:drawGame()
  self.camera:detach()

  self:drawUI()
  love.graphics.pop()

  -- Draw borders
  love.graphics.setColor(config.borderColor[1], config.borderColor[2], config.borderColor[3])
  love.graphics.rectangle("fill", 0, 0, Game.translate[1], love.graphics.getHeight())
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), Game.translate[2])
  love.graphics.rectangle("fill", love.graphics.getWidth() - Game.translate[1], 0, Game.translate[1],
    love.graphics.getHeight())
  love.graphics.rectangle("fill", 0, love.graphics.getHeight() - Game.translate[2], love.graphics.getWidth(),
    Game.translate[2])
end

function Game:drawGame()
  self.house:draw()

  for _, enemy in ipairs(self.enemies) do
    if not enemy.dead then
      enemy:draw()
    end
  end

  self.player:draw()

  for _, entity in ipairs(self.entities) do
    if not entity.dead then
      entity:draw()
    end
  end

  if config.physicsDebug then
    self.world:draw(1)
  end

  -- self:drawPath(self.path)
end

function Game:drawPath(path)
  if #path == 1 then
    return
  end

  love.graphics.setColor(1, 1, 1)
  local points = {}
  for _, p in ipairs(path) do
    table.insert(points, p.x)
    table.insert(points, p.y)
  end

  love.graphics.line(points)
end

function Game:drawUI()
  love.graphics.push()

  love.graphics.pop()
end

function Game:addEntity(entity)
  table.insert(self.entities, entity)
end

function Game:getMousePosition()
  local mx, my = love.mouse.getPosition()

  mx = (mx - self.translate[1]) / self.scaling
  my = (my - self.translate[2]) / self.scaling

  local cx, cy = self.camera:toWorldCoords(mx, my)

  return mx, my, cx, cy
end

function Game:resize()
  love.window.setMode(800, 600)
  Game:calculateScaling()
end

function Game:calculateScaling()
  local minEdge = love.graphics.getHeight()
  if minEdge < love.graphics.getWidth() then
    Game.scaling = minEdge / 600
    Game.translate = { (love.graphics.getWidth() - (800 * Game.scaling)) / 2, 0 }
  else
    Game.scaling = love.graphics.getWidth() / 800
  end
end

function Game:keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end

return Game
