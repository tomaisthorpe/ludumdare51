local Class = require("hump.class")
require("a-star")
local inspect = require("inspect")
local config = require("config")

local House = Class {
    init = function(self, world, rooms, walls, doors, grid)
        self.world = world
        self.rooms = rooms
        self.walls = walls
        self.doors = doors
        self.grid = grid

        self:setupWalls()
        self:setupDoors()
        self:generateNodes()
    end,
    nodes = {},
}

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

function House:setupWalls()

    for _, wall in ipairs(self.walls) do
        local obj = self.world:newRectangleCollider(wall.x, wall.y, wall.w, wall.h)
        obj:setCollisionClass('Solid')
        obj:setType('static')
    end
end

function House:setupDoors()
    for _, door in ipairs(self.doors) do
        local hinge = self.world:newCircleCollider(door.x, door.y, 2)
        hinge:setType('static')

        local w = 47
        local h = 2

        if door.vertical then
            w = 2
            h = 47
        end

        local obj = self.world:newRectangleCollider(door.x, door.y, w, h)
        obj:setCollisionClass('Solid')

        self.world:addJoint('RevoluteJoint', hinge, obj, door.x, door.y, false)
    end

end

function House:draw()
    -- Loop through the rooms and just draw them

    for _, room in ipairs(self.rooms) do
        love.graphics.setColor(room.color[1], room.color[2], room.color[3])
        love.graphics.rectangle("fill", room.rect[1].x, room.rect[1].y, room.w, room.h)
    end
end

return House
