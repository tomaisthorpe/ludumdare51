local config = require("config")
local HouseGenerator = require("house-generator")
local wf = require("windfield")
local Player = require("player")
local Camera = require("Camera")
local inspect = require("inspect")
local Enemy = require("enemy")
local Gamestate = require("hump.gamestate")
local House = require("house")
local Class = require("hump.class")

local Game = Class {
  init = function(self)
    self.translate = { 0, 0 }
    self.scaling = 1
    self.lives = 3
  end,
}

function Game:init()
  -- Window setup
  Game:calculateScaling()

  self.font = love.graphics.newFont('assets/sharetech.ttf', 16)
  self.largeFont = love.graphics.newFont('assets/sharetech.ttf', 32)
  self.xlFont = love.graphics.newFont('assets/sharetech.ttf', 42)
  self.xxlFont = love.graphics.newFont('assets/sharetech.ttf', 52)

  self.liveImage = love.graphics.newImage("assets/heart.png")
end

function Game:enter(prev, level, lives)
  self.level = level
  self.lives = lives
  self.world = wf.newWorld(0, 0, true)
  self.world:addCollisionClass('Hinge')
  self.world:addCollisionClass('Door', { ignores = { 'Hinge' } })
  self.world:addCollisionClass('Solid', { ignores = { 'Hinge', 'Door' } })
  self.world:addCollisionClass('Player', { ignores = { 'Hinge' } })
  self.world:addCollisionClass('Enemy', { ignores = { 'Hinge' } })
  self.world:addCollisionClass('Bullet', { ignores = { 'Bullet', 'Solid', 'Enemy', 'Player' } })

  local houseGen = HouseGenerator(self.world, level)
  self.houseConfig = houseGen:generate()
  -- houseGen:draw()

  self.camera = Camera(0, 0, 800, 600)
  self.camera:setFollowStyle('TOPDOWN_TIGHT')

  self:setup()
end

function Game:setup(startStarted)
  self.house = House(self.world, self.houseConfig)

  self.player = Player(self, self.world, self.house.startingPosition.x, self.house.startingPosition.y)
  self.enemies = {}

  for _, enemy in ipairs(self.house.enemyLocations) do
    table.insert(self.enemies, Enemy(self, self.world, enemy.x, enemy.y))
  end

  self.entities = {}
  self.started = false
  if startStarted then
    self.started = true
  end
  self.paused = false
  self.timeLeft = 10

  self.hasWon = false
end

function Game:destroy()
  self.player:destroy()
  self.house:destroy()

  for _, enemy in ipairs(self.enemies) do
    enemy:destroy()
  end

  for _, entity in ipairs(self.entities) do
    entity:destroy()
  end
end

function Game:reset()
  -- Destroy everything
  self:destroy()

  self:setup(true)
end

function Game:leave()
  self:destroy()
end

function Game:keyreleased(key)
  if key == "space" then
    if self.hasWon then
      if self.level == config.levelGen.maxLevel then
        love.event.quit()
      else
        Gamestate.pop(self.lives)
      end
      return
    end

    if not self.started then
      self.started = true
    end

    if self.paused then
      if self.lives > 0 then
        self:reset()
      else
        Gamestate.pop(0)
      end
    end
  end

end

function Game:update(dt)
  self.camera:update(dt)
  self.camera:follow(self.player:getX(), self.player:getY())

  if self.hasWon or not self.started or self.paused then
    return
  end

  if #self.enemies == 0 then
    self.hasWon = true
    return
  end

  self.timeLeft = self.timeLeft - dt
  if self.timeLeft < 0 then
    self.timeLeft = 0
    self:gameOver("time")
    return
  end

  self.world:update(dt)

  self.house:update(dt)
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

  for _, entity in ipairs(self.entities) do
    if not entity.dead then
      entity:draw()
    end
  end

  for _, enemy in ipairs(self.enemies) do
    if not enemy.dead then
      enemy:draw()
    end
  end

  self.player:draw()

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

  love.graphics.translate(config.uiSizing.margin, config.uiSizing.margin)

  love.graphics.setFont(self.font)
  love.graphics.setColor(0.5, 0.5, 0.5)
  love.graphics.printf("Lives: " .. self.lives, 0, 1, config.windowWidth - config.uiSizing.margin * 2, "right")

  love.graphics.setColor(config.uiPalette.text)
  love.graphics.printf("Lives: " .. self.lives, 0, 0, config.windowWidth - config.uiSizing.margin * 2, "right")

  local barX = (config.windowWidth - config.uiSizing.margin * 2 - config.uiSizing.healthWidth) / 2
  self:drawBar("Health", barX, 6, config.uiSizing.healthWidth, config.uiPalette.health,
    self.player.health / 100)

  self:drawBar("Time Left", barX, config.uiSizing.barHeight + config.uiSizing.margin, config.uiSizing.healthWidth,
    config.uiPalette.timeLeft,
    self.timeLeft / 10)

  love.graphics.setFont(self.largeFont)
  love.graphics.setColor(0.5, 0.5, 0.5)
  love.graphics.printf("Level " .. self.level, 0, 1, config.windowWidth - config.uiSizing.margin * 2)

  love.graphics.setColor(config.uiPalette.text)
  love.graphics.printf("Level " .. self.level, 0, 0, config.windowWidth - config.uiSizing.margin * 2)

  if not self.started then
    love.graphics.setFont(self.xlFont)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Press space to start", 0, 501, config.windowWidth - config.uiSizing.margin * 2, "center")

    love.graphics.setColor(config.uiPalette.text)
    love.graphics.printf("Press space to start", 0, 500, config.windowWidth - config.uiSizing.margin * 2, "center")
  end

  if self.paused then
    local text = "You were killed!"
    if self.gameOverReason == "time" then
      text = "You ran out of time!"
    end

    if self.lives == 0 then
      love.graphics.setFont(self.xxlFont)
      love.graphics.setColor(0.5, 0.5, 0.5)
      love.graphics.printf("GAME OVER", 0, config.windowHeight - 96 - config.uiSizing.margin * 3 + 1,
        config.windowWidth - config.uiSizing.margin * 2, "center")

      love.graphics.setColor(config.uiPalette.gameOver)
      love.graphics.printf("GAME OVER", 0, config.windowHeight - 96 - config.uiSizing.margin * 3,
        config.windowWidth - config.uiSizing.margin * 2, "center")
    end

    love.graphics.setFont(self.xlFont)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf(text, 0, config.windowHeight - 52 - config.uiSizing.margin * 3 + 1,
      config.windowWidth - config.uiSizing.margin * 2, "center")

    love.graphics.setColor(config.uiPalette.gameOver)
    love.graphics.printf(text, 0, config.windowHeight - 52 - config.uiSizing.margin * 3,
      config.windowWidth - config.uiSizing.margin * 2, "center")

    local action = "try again"

    love.graphics.setFont(self.largeFont)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Press space to " .. action, 0, config.windowHeight - 32 - config.uiSizing.margin * 2 + 1,
      config.windowWidth - config.uiSizing.margin * 2, "center")

    love.graphics.setColor(config.uiPalette.mutedText)
    love.graphics.printf("Press space to " .. action, 0, config.windowHeight - 32 - config.uiSizing.margin * 2,
      config.windowWidth - config.uiSizing.margin * 2, "center")
  end

  if self.hasWon then
    local text = "House cleared!"
    local action = "continue"
    love.graphics.setFont(self.xlFont)

    if self.level == config.levelGen.maxLevel then
      action = "quit"
      love.graphics.setFont(self.largeFont)
      text = "Game complete! Thanks for playing!"
    end


    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf(text, 0, config.windowHeight - 52 - config.uiSizing.margin * 3 + 1,
      config.windowWidth - config.uiSizing.margin * 2, "center")

    love.graphics.setColor(config.uiPalette.gameOver)
    love.graphics.printf(text, 0, config.windowHeight - 52 - config.uiSizing.margin * 3,
      config.windowWidth - config.uiSizing.margin * 2, "center")


    love.graphics.setFont(self.largeFont)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Press space to " .. action, 0, config.windowHeight - 32 - config.uiSizing.margin * 2 + 1,
      config.windowWidth - config.uiSizing.margin * 2, "center")

    love.graphics.setColor(config.uiPalette.mutedText)
    love.graphics.printf("Press space to " .. action, 0, config.windowHeight - 32 - config.uiSizing.margin * 2,
      config.windowWidth - config.uiSizing.margin * 2, "center")
  end

  self:drawLives()

  love.graphics.pop()
end

function Game:drawLives()
  local start = config.startLives - self.lives

  for i = 0, self.lives - 1 do
    local y = config.uiSizing.margin
    local x = config.windowWidth - config.uiSizing.margin * 2 - 32 * config.startLives + 2

    love.graphics.draw(self.liveImage, x + 32 * i, y)
  end
end

function Game:drawBar(label, x, y, width, color, value)
  love.graphics.push()

  love.graphics.translate(x, y)
  love.graphics.setLineWidth(config.uiSizing.strokeWidth)

  local level = (width - config.uiSizing.barPadding * 2) * value

  love.graphics.setColor(color)

  love.graphics.rectangle("line", 0, 0, width, config.uiSizing.barHeight)
  love.graphics.rectangle("fill", config.uiSizing.barPadding, config.uiSizing.barPadding, level,
    config.uiSizing.barHeight - config.uiSizing.barPadding * 2)

  love.graphics.setColor(0.4, 0.4, 0.4)
  love.graphics.setFont(self.font)
  love.graphics.printf(label, 5, 4, 200)

  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.font)
  love.graphics.printf(label, 5, 3, 200)

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

function Game:gameOver(reason)
  self.paused = true
  self.gameOverReason = reason
  self.lives = self.lives - 1
end

return Game
