local Class = require("hump.class")
require("a-star")
local inspect = require("inspect")
local config = require("config")
local Wall = require("wall")
local Door = require("door")

local House = Class {
    init = function(self, world, config)
        self.world = world
        self.rooms = config.rooms
        self.grid = config.grid
        self.startingRoom = config.startingRoom
        self.enemyLocations = config.enemyLocations

        self.carpet = love.graphics.newImage("assets/carpet.png")
        self.carpet:setWrap("repeat", "repeat")

        self.tile = love.graphics.newImage("assets/kitchen.png")
        self.tile:setWrap("repeat", "repeat")

        self.wood = love.graphics.newImage("assets/wood.png")
        self.wood:setWrap("repeat", "repeat")

        self.startingPosition = {
            x = config.startingRoom.rect[1].x + config.startingRoom.w / 2,
            y = config.startingRoom.rect[1].y + config.startingRoom.h / 2,
        }

        self:setupWalls(config.walls)
        self:setupDoors(config.doors)
        self:generateNodes()
    end,
    nodes = {},
    walls = {},
    doors = {},
}

function House:destroy()
    for _, wall in ipairs(self.walls) do
        wall:destroy()
    end

    for _, door in ipairs(self.doors) do
        door:destroy()
    end
end

function House:generateNodes()
    for x = 1, self.grid.w do
        for y = 1, self.grid.h do
            table.insert(self.nodes, {
                x = x,
                y = y,
                value = self.grid:get(x, y),
            })
        end
    end
end

function House:getNode(x, y)
    for _, node in ipairs(self.nodes) do
        if node.x == x and node.y == y then
            return node
        end
    end

    return nil
end

function House:path(start, goal)
    local gs = config.gridScale
    local startNode = self:getNode(math.floor(start.x / gs), math.floor(start.y / gs))
    local goalNode = self:getNode(math.floor(goal.x / gs), math.floor(goal.y / gs))

    local valid_node_func = function(node, neighbour)
        if astar.dist_between(node, neighbour) > 1.5 then
            return false
        end

        if node.value ~= neighbour.value then
            if node.value == "d" or neighbour.value == "d" then
                return true
            end

            return false
        end

        return true
    end

    local gridPath = astar.path(startNode, goalNode, self.nodes, false, valid_node_func)
    if gridPath == nil then
        return nil
    end

    -- Scale the path to world x,y
    local path = {}
    for _, point in ipairs(gridPath) do
        table.insert(path, {
            x = point.x * gs,
            y = point.y * gs,
        })
    end

    return path
end

function House:setupWalls(walls)
    for _, wall in ipairs(walls) do
        local w = Wall(self.world, wall.x, wall.y, wall.w, wall.h)
        table.insert(self.walls, w)
    end
end

function House:setupDoors(doors)
    for _, door in ipairs(doors) do
        local d = Door(self.world, door.x, door.y, door.vertical)
        table.insert(self.doors, d)
    end
end

function House:update(dt)
    for _, door in ipairs(self.doors) do
        door:update(dt)
    end
end

function House:draw()
    -- Loop through the rooms and just draw them

    for _, room in ipairs(self.rooms) do
        love.graphics.setColor(1, 1, 1)
        local quad = love.graphics.newQuad(0, 0, room.w, room.h, 64, 64)
        local image = self.carpet
        if room.floor == "wood" then
            image = self.wood
        elseif room.floor == "tile" then
            image = self.tile
        end


        love.graphics.draw(image, quad, room.rect[1].x, room.rect[1].y)

    end


    for _, door in ipairs(self.doors) do
        door:draw()
    end

    for _, wall in ipairs(self.walls) do
        wall:draw()
    end
end

return House
