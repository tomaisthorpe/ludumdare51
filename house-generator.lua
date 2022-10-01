-- Using BSP to generate a very simple house
-- We start with a rectangle and then split into rooms up to specified level

-- Inspo: https://codereview.stackexchange.com/questions/4334/is-this-a-bsp-tree-am-i-missing-something

local Class = require("hump.class")
local config = require("config")
local inspect = require("inspect")
local House = require("house")

MAX_RECURSION = 2

TL = 1
BL = 2
BR = 3
TR = 4
minRoomSize = 2

local HouseGenerator = Class {
    init = function(self, world)
        self.world = world
    end,
    grid = {
        id = 0,
        w = 40,
        h = 30,
        roomCount = 1,
        data = {},
        pos = function(self, x, y) return (x * self.w + y) + 1 end,
        get = function(self, x, y) return self.data[self:pos(x, y)] end,
        set = function(self, x, y, value) self.data[self:pos(x, y)] = value end,
        reset = function(self)
            for i = 1, self.w * self.h do
                self.data[i] = "0"
            end
        end,
    },
}

function HouseGenerator:generate()
    self.grid:reset()
    self.roomCount = 1

    -- Create the root node
    local rect = {
        [TL] = { x = 0, y = 0 },
        [BL] = { x = 0, y = self.grid.h },
        [BR] = { x = self.grid.w, y = self.grid.h },
        [TR] = { x = self.grid.w, y = 0 }
    }
    local root = self:node(nil, rect)
    self:splitNode(root)

    local rooms = self:getRooms(root)
    local walls, doors = self:getWallsAndDoors(rooms)

    local house = House(self.world, rooms, walls, doors, self.grid)

    return house
end

function HouseGenerator:getWallsAndDoors(rooms)
    -- Loop each room
    -- Check right edge of room to see what happens on the boundary.
    ---- If over grid width, then nothing there
    ---- If room ID changes between rows, then we know the boundary ended
    -- Repeat for bottom edge

    -- Keep track of all boundaries between rooms
    local boundaries = {}

    local gs = config.gridScale

    for _, room in ipairs(rooms) do
        print("Right edge for ", room.id)
        -- Right edge
        -- Get the x where the wall should start
        local x = room.gx + room.gw
        local y = room.gy

        -- We're in bounds, so should check this right edge
        if x < self.grid.w and y < self.grid.h then
            local count = 1
            local current = self.grid:get(x, y)
            local startY = y

            for by = 1, room.gh, 1 do
                local nextRoom = self.grid:get(x, y + by)

                -- If this room is different to what we saw before, then we have a new boundary
                if nextRoom ~= current or by == room.gh then
                    -- Push the boundary
                    local boundary = {
                        between = { room.id, current },
                        x = x,
                        y = startY,
                        length = count,
                        vertical = true,
                    }

                    table.insert(boundaries, boundary)
                    current = nextRoom
                    startY = y + by
                    count = 1
                else
                    count = count + 1
                end
            end
        end

        -- Bottom edge
        print("Bottom edge for ", room.id)
        -- Get the y where the wall should start
        local x = room.gx
        local y = room.gy + room.gh

        -- We're in bounds, so should check this bottom edge
        if x < self.grid.w and y < self.grid.h then
            local count = 1
            local current = self.grid:get(x, y)
            local startX = x

            for bx = 1, room.gw, 1 do
                local nextRoom = self.grid:get(x + bx, y)

                -- If this room is different to what we saw before, then we have a new boundary
                if nextRoom ~= current or bx == room.gw then
                    -- Push the boundary
                    local boundary = {
                        between = { room.id, current },
                        x = startX,
                        y = y,
                        length = count,
                        vertical = false,
                    }

                    table.insert(boundaries, boundary)
                    current = nextRoom
                    count = 1
                    startX = x + bx
                else
                    count = count + 1
                end
            end
        end
    end

    local walls = {}
    local doors = {}

    -- Convert the boundaries to walls and randomly add some doors
    for _, boundary in ipairs(boundaries) do
        -- Check if should add a door
        -- This is random and doesn't guarantee that all rooms are reachable
        local hasDoor = love.math.random(0, 4) >= 0 and boundary.length > config.doorWidth + 2

        if hasDoor then
            local doorPosition = math.floor(boundary.length / 2)

            if boundary.vertical then
                table.insert(walls, self:wall(boundary.x, boundary.y, doorPosition, true))
                table.insert(walls,
                    self:wall(boundary.x, boundary.y + doorPosition + config.doorWidth,
                        boundary.length - doorPosition - config.doorWidth,
                        true))

                table.insert(doors, self:door(boundary.x, boundary.y + doorPosition, true))

                -- Update the grid with the door so pathfinding knows the enemy can traverse here
                self.grid:set(boundary.x, boundary.y + doorPosition, "d")
                self.grid:set(boundary.x, boundary.y + doorPosition + 1, "d")
                self.grid:set(boundary.x - 1, boundary.y + doorPosition, "d")
                self.grid:set(boundary.x - 1, boundary.y + 1 + doorPosition, "d")
            else
                table.insert(walls, self:wall(boundary.x, boundary.y, doorPosition, false))
                table.insert(walls,
                    self:wall(boundary.x + doorPosition + config.doorWidth, boundary.y,
                        boundary.length - doorPosition - config.doorWidth,
                        false))

                table.insert(doors, self:door(boundary.x + doorPosition, boundary.y, false))

                -- Update the grid with the door so pathfinding knows the enemy can traverse here
                self.grid:set(boundary.x + doorPosition, boundary.y, "d")
                self.grid:set(boundary.x + 1 + doorPosition, boundary.y, "d")
                self.grid:set(boundary.x + doorPosition, boundary.y - 1, "d")
                self.grid:set(boundary.x + 1 + doorPosition, boundary.y - 1, "d")
            end

        else
            table.insert(walls, self:wall(boundary.x, boundary.y, boundary.length, boundary.vertical))
        end
    end

    -- Add outside walls
    table.insert(walls, self:wall(0, 0, self.grid.w, false))
    table.insert(walls, self:wall(0, self.grid.h, self.grid.w, false))
    table.insert(walls, self:wall(0, 0, self.grid.h, true))
    table.insert(walls, self:wall(self.grid.w, 0, self.grid.h, true))

    return walls, doors
end

function HouseGenerator:wall(x, y, length, vertical)
    local gs = config.gridScale

    if vertical then
        return {
            x = x * gs,
            y = y * gs,
            w = config.wallWidth,
            h = length * gs,
        }
    end

    return {
        x = x * gs,
        y = y * gs,
        w = length * gs,
        h = config.wallWidth,
    }
end

function HouseGenerator:door(x, y, vertical)
    local gs = config.gridScale
    return {
        x = x * gs,
        y = y * gs,
        vertical = vertical,
    }
end

function HouseGenerator:scaleRect(rect)
    local gs = config.gridScale
    return {
        [TL] = { x = rect[TL].x * gs, y = rect[TL].y * gs },
        [TR] = { x = rect[TR].x * gs, y = rect[TR].y * gs },
        [BR] = { x = rect[BR].x * gs, y = rect[BR].y * gs },
        [BL] = { x = rect[BL].x * gs, y = rect[BL].y * gs },
    }
end

function HouseGenerator:getRooms(node)
    if node.id ~= 0 then
        return { {
            id = node.id,
            rect = self:scaleRect(node.rect),
            w = node.w * config.gridScale,
            h = node.h * config.gridScale,
            gx = node.rect[TL].x,
            gy = node.rect[TL].y,
            gw = node.w,
            gh = node.h,
            color = { love.math.random(), love.math.random(), love.math.random() }
        } }
    end

    local rooms = {}
    if node.left then
        local leftRooms = self:getRooms(node.left)
        for _, v in ipairs(leftRooms) do
            table.insert(rooms, v)
        end
    end

    if node.right then
        local leftRooms = self:getRooms(node.right)
        for _, v in ipairs(leftRooms) do
            table.insert(rooms, v)
        end
    end

    return rooms
end

function HouseGenerator:splitNode(node)
    -- If we don't need to split anymore, then we have a room!
    if node.level >= MAX_RECURSION then
        node.id = self.roomCount
        self.roomCount = self.roomCount + 1
        self:drawNode(node)
        return
    end

    local split = self:whereDoSplit(node)

    -- If no split was returned, then we can't go further, so just finish
    if split == nil then
        node.id = self.roomCount
        self.roomCount = self.roomCount + 1
        self:drawNode(node)
        return
    end

    local rect1, rect2 = self:splitRectangles(node, split)
    node.left = self:node(node, rect1)
    node.right = self:node(node, rect2)

    -- Split the two new nodes
    self:splitNode(node.left)
    self:splitNode(node.right)
end

function HouseGenerator:splitRectangles(node, split)
    local t = node.rect
    if node.vertical_split then
        local rect1 = { [TL] = t[TL], [BL] = t[BL], [TR] = { x = split, y = t[TR].y }, [BR] = { x = split, y = t[BR].y } }
        local rect2 = { [TL] = { x = split, y = t[TL].y }, [BL] = { x = split, y = t[BL].y }, [TR] = t[TR], [BR] = t[BR] }
        return rect1, rect2
    else
        local rect1 = { [TL] = t[TL], [TR] = t[TR], [BL] = { x = t[BL].x, y = split }, [BR] = { x = t[BR].x, y = split } }
        local rect2 = { [TL] = { x = t[TL].x, y = split }, [TR] = { x = t[TR].x, y = split }, [BL] = t[BL], [BR] = t[BR] }
        return rect1, rect2
    end
end

function HouseGenerator:whereDoSplit(node)
    if node.vertical_split then
        local size = math.floor((math.random(20, 80) / 100) * node.w)

        -- Ensure split rooms aren't going to be less than minimum
        if size < minRoomSize or size > node.w - minRoomSize then
            return nil
        end

        -- Split at this x
        return node.rect[TL].x + size
    else
        local size = math.floor((math.random(20, 80) / 100) * node.h)

        -- Ensure split rooms aren't going to be less than minimum
        if size < minRoomSize or size > node.h - minRoomSize then
            return nil
        end

        -- Split at this y
        return node.rect[TL].y + size
    end
end

function HouseGenerator:node(parent, rect)
    local level = 0
    if parent ~= nil then
        level = parent.level + 1
    end

    local n = {
        id = 0,
        left = nil,
        right = nil,
        rect = rect,
        parent = parent,
        level = level,
        vertical_split = love.math.random(0, 1) > 0 and true or false,
        w = rect[TR].x - rect[TL].x,
        h = rect[BL].y - rect[TL].y
    }


    return n
end

function HouseGenerator:drawNode(node)
    local rect = node.rect
    for y = rect[TL].y, rect[BL].y do
        for x = rect[TL].x, rect[TR].x do
            -- if x==rect[TL].x or x==rect[TR].x or y==rect[TL].y or y==rect[BR].y then
            -- self.grid:set(x, y, "#")
            -- else
            self.grid:set(x, y, node.id)
            -- end
        end
    end
end

function HouseGenerator:draw()
    print("drawing")
    local line = ""
    local x, y
    for y = 0, self.grid.h do
        for x = 0, self.grid.w do
            line = "" .. line .. (self.grid.data[self.grid:pos(x, y)] or 0)
        end
        print(line)
        line = ""
    end
end

return HouseGenerator
