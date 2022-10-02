-- Using BSP to generate a very simple house
-- We start with a rectangle and then split into rooms up to specified level

-- Inspo: https://codereview.stackexchange.com/questions/4334/is-this-a-bsp-tree-am-i-missing-something

local Class = require("hump.class")
local config = require("config")
local inspect = require("inspect")
local House = require("house")

MAX_RECURSION = 5

TL = 1
BL = 2
BR = 3
TR = 4
minRoomSize = 6

minRooms = 2

local HouseGenerator = Class {
    init = function(self, world, level)
        self.world = world


        if level > config.levelGen.maxLevel then
            level = config.levelGen.maxLevel
        end


        local progress = (level - 1) / (config.levelGen.maxLevel - 1)
        self.maxRooms = (config.levelGen.rooms[2] - config.levelGen.rooms[1]) * progress + config.levelGen.rooms[1]
        self.enemyCount = (config.levelGen.enemies[2] - config.levelGen.enemies[1]) * progress +
            config.levelGen.enemies[1]
    end,
    grid = {
        id = 0,
        w = 100,
        h = 60,
        roomCount = 1,
        data = {},
        pos = function(self, x, y) return y * self.w + x end,
        get = function(self, x, y) return self.data[self:pos(x, y)] end,
        set = function(self, x, y, value) self.data[self:pos(x, y)] = value end,
        reset = function(self)
            for i = 0, self.w * self.h do
                self.data[i] = "0"
            end
        end,
    },
}

function HouseGenerator:generate()

    while true do
        self.grid:reset()
        self.roomCount = 1

        -- Create the root node
        local rect = {
            [TL] = { x = 0, y = 0 },
            [BL] = { x = 0, y = self.grid.h - 1 },
            [BR] = { x = self.grid.w - 1, y = self.grid.h - 1 },
            [TR] = { x = self.grid.w - 1, y = 0 }
        }

        local root = self:node(nil, rect)
        self:splitNode(root)

        local rooms = self:getRooms(root)
        local boundaries = self:getBoundaries(rooms)

        local selectedRooms, startingRoom = self:selectRooms(rooms, boundaries)
        if selectedRooms ~= nil then
            self.grid:reset()

            for _, room in ipairs(selectedRooms) do
                self:drawNode({
                    id = room.id,
                    rect = self:unscaleRect(room.rect),
                    x = room.gx,
                    y = room.gy,
                    w = room.gw,
                    h = room.gh,
                })
            end

            local selectedBoundaries = self:getBoundaries(selectedRooms)
            local walls, doors = self:getWallsAndDoors(selectedBoundaries)


            local enemyLocations = self:getEnemyLocations(selectedRooms)

            if self:isLayoutValid(selectedRooms, doors, startingRoom) then
                local config = {
                    rooms = selectedRooms,
                    walls = walls,
                    doors = doors,
                    grid = self.grid,
                    startingRoom = startingRoom,
                    enemyLocations = enemyLocations,
                }

                return config
            end
        end

    end
end

function HouseGenerator:getEnemyLocations(rooms)
    -- Just to ensure doesn't crash
    if #rooms == 1 and rooms[1].startingRoom then
        return {}
    end

    local allowedRooms = {}
    for _, room in ipairs(rooms) do
        if not room.startingRoom then
            table.insert(allowedRooms, room)
        end
    end

    local locations = {}

    for e = 1, self.enemyCount do
        -- Choose a random room
        local room = allowedRooms[love.math.random(1, #allowedRooms)]

        local minX = room.rect[1].x + 16
        local maxX = room.rect[1].x + room.w - 16

        local minY = room.rect[1].y + 16
        local maxY = room.rect[1].y + room.h - 16

        table.insert(locations, {
            x = love.math.random(minX, maxX),
            y = love.math.random(minY, maxY),
        })

    end

    return locations
end

function HouseGenerator:isLayoutValid(rooms, doors, startingRoom)
    if #rooms < minRooms then
        return false
    end

    local currentIDs = {
        [startingRoom.id] = true,
    }

    local count = 0
    while count < #doors do
        -- Loop through all doors, any door that has a entry in currentIDs, can be accessed
        -- So those room IDs can be added to the list
        for _, door in ipairs(doors) do
            if currentIDs[door.between[1]] or currentIDs[door.between[2]] then
                currentIDs[door.between[1]] = true
                currentIDs[door.between[2]] = true
            end
        end

        count = count + 1
    end

    local found = {}
    for k, _ in pairs(currentIDs) do
        table.insert(found, k)
    end

    if #rooms ~= #found then
        return false
    end

    -- Check rooms aren't weird sizes
    for _, room in ipairs(rooms) do
        if room.gw > config.generator.maxRoomWidth or room.gh > config.generator.maxRoomHeight or
            room.gw * room.gh > config.generator.maxRoomArea then
            return false
        end
    end

    return true
end

function HouseGenerator:chooseStartingRoom(rooms)
    return rooms[love.math.random(1, #rooms - 1)]
end

function HouseGenerator:selectRooms(rooms, boundaries)
    -- Uses the max room count to select rooms that are going to be used

    local startingRoom = self:chooseStartingRoom(rooms)
    startingRoom.startingRoom = true

    local roomCount = 1
    local selectedRoomIDs = { [startingRoom.id] = true }
    local noLoopy = 0

    while roomCount < self.maxRooms and noLoopy < 100 do
        -- Find all boundaries that include at least one of the selected room IDs
        local selectedBoundaries = {}

        for _, boundary in ipairs(boundaries) do
            for id, _ in pairs(selectedRoomIDs) do
                if boundary.between[1] == id or boundary.between[2] == id then
                    table.insert(selectedBoundaries, boundary)
                    break
                end
            end
        end

        local chosenBoundary = selectedBoundaries[love.math.random(1, #selectedBoundaries)]
        if not selectedRoomIDs[chosenBoundary.between[1]] then
            selectedRoomIDs[chosenBoundary.between[1]] = true
            roomCount = roomCount + 1
        elseif not selectedRoomIDs[chosenBoundary.between[2]] then
            selectedRoomIDs[chosenBoundary.between[2]] = true
            roomCount = roomCount + 1
        end

        noLoopy = noLoopy + 1
    end

    if noLoopy == 100 then
        return nil, nil
    end

    local selectedRooms = {}

    for id, _ in pairs(selectedRoomIDs) do
        for _, room in ipairs(rooms) do
            if room.id == id then
                table.insert(selectedRooms, room)
                break
            end
        end
    end

    return selectedRooms, startingRoom

end

function HouseGenerator:getBoundaries(rooms)
    -- Loop each room
    -- Check right edge of room to see what happens on the boundary.
    ---- If over grid width, then nothing there
    ---- If room ID changes between rows, then we know the boundary ended
    -- Repeat for bottom edge

    -- Keep track of all boundaries between rooms
    local boundaries = {}

    local gs = config.gridScale

    for _, room in ipairs(rooms) do
        -- print("Right edge for ", room.id, room.gx + room.gw, room.gx, room.gw)
        -- Right edge
        -- Get the x where the wall should start
        local x = room.gx + room.gw
        local y = room.gy

        -- We're in bounds, so should check this right edge
        if x < self.grid.w and y < self.grid.h then
            local count = 1
            local current = self.grid:get(x + 1, y)
            if x + 1 >= self.grid.w then
                current = "0"
            end

            local startY = y

            for by = 0, room.gh - 1, 1 do
                local nextRoom = self.grid:get(x + 1, y + by)
                if x + 1 >= self.grid.w then
                    nextRoom = "0"
                end

                -- If this room is different to what we saw before, then we have a new boundary
                if nextRoom ~= current or by == room.gh - 1 then
                    -- Push the boundary
                    -- if current ~= room.id then
                    local boundary = {
                        between = { room.id, current },
                        x = x,
                        y = startY,
                        length = count,
                        vertical = true,
                        outside = current == "0",
                    }

                    table.insert(boundaries, boundary)
                    -- end

                    current = nextRoom
                    startY = startY + count
                    count = 1
                else
                    count = count + 1
                end
            end
        end

        -- -- Bottom edge
        -- print("Bottom edge for ", room.id)
        -- Get the y where the wall should start
        local x = room.gx
        local y = room.gy + room.gh

        -- We're in bounds, so should check this bottom edge
        if x < self.grid.w and y < self.grid.h then
            local count = 1
            local current = self.grid:get(x, y + 1)
            if y + 1 >= self.grid.h then
                current = "0"
            end

            local startX = x

            for bx = 0, room.gw - 1, 1 do
                local nextRoom = self.grid:get(x + bx, y + 1)
                if y + 1 >= self.grid.h then
                    nextRoom = "0"
                end

                -- If this room is different to what we saw before, then we have a new boundary
                if nextRoom ~= current or bx == room.gw - 1 then
                    -- if current ~= room.id then
                    -- Push the boundary
                    local boundary = {
                        between = { room.id, current },
                        x = startX,
                        y = y,
                        length = count,
                        vertical = false,
                        outside = current == "0",
                    }

                    table.insert(boundaries, boundary)
                    -- end

                    current = nextRoom
                    startX = startX + count
                    count = 1
                else
                    count = count + 1
                end
            end
        end

        -- Top edge if top is 0 only
        local x = room.gx
        local y = room.gy

        -- We're in bounds, so should check this bottom edge
        if x < self.grid.w and y < self.grid.h then
            local count = 1
            local current = self.grid:get(x, y - 1)
            if y - 1 < 0 then
                current = "0"
            end

            local startX = x

            for bx = 1, room.gw, 1 do
                local nextRoom = self.grid:get(x + bx, y - 1)
                if y - 1 < 0 then
                    nextRoom = "0"
                end

                -- If this room is different to what we saw before, then we have a new boundary
                if nextRoom ~= current or bx == room.gw then
                    if current == "0" then
                        -- Push the boundary
                        local boundary = {
                            between = { room.id, current },
                            x = startX,
                            y = y,
                            length = count,
                            vertical = false,
                            outside = current == "0",
                        }

                        table.insert(boundaries, boundary)
                    end

                    current = nextRoom
                    startX = startX + count
                    count = 1
                else
                    count = count + 1
                end
            end
        end

        -- print("Left edge for ", room.id, room.gx + room.gw, room.gx, room.gw)
        -- Left edge if left is 0 only
        local x = room.gx
        local y = room.gy

        -- We're in bounds, so should check this right edge
        if x < self.grid.w and y < self.grid.h then
            local count = 1
            local current = self.grid:get(x - 1, y)
            if x - 1 < 0 then
                current = "0"
            end

            local startY = y

            for by = 1, room.gh, 1 do
                local nextRoom = self.grid:get(x - 1, y + by)
                if x - 1 < 0 then
                    nextRoom = "0"
                end

                -- If this room is different to what we saw before, then we have a new boundary
                if nextRoom ~= current or by == room.gh then
                    if current == "0" then
                        local boundary = {
                            between = { room.id, current },
                            x = x,
                            y = startY,
                            length = count,
                            vertical = true,
                            outside = current == "0",
                        }

                        table.insert(boundaries, boundary)
                    end

                    current = nextRoom
                    startY = startY + count
                    count = 1
                else
                    count = count + 1
                end
            end
        end
    end

    return boundaries
end

function HouseGenerator:getWallsAndDoors(boundaries)
    local walls = {}
    local doors = {}

    -- Convert the boundaries to walls and randomly add some doors
    for _, boundary in ipairs(boundaries) do
        -- Check if should add a door
        -- This is random and doesn't guarantee that all rooms are reachable
        local hasDoor = love.math.random(0, 4) >= 1 and boundary.length > config.doorWidth + 2

        if hasDoor and boundary.outside == false then
            -- local doorPosition = math.floor((boundary.length - config.doorWidth) / 2)
            local minDoorPosition = 2
            local maxDoorPosition = boundary.length - 2 - config.doorWidth
            local doorPosition = love.math.random(minDoorPosition, maxDoorPosition)

            if boundary.vertical then
                table.insert(walls, self:wall(boundary.x, boundary.y, doorPosition, true))
                table.insert(walls,
                    self:wall(boundary.x, boundary.y + doorPosition + config.doorWidth,
                        boundary.length - doorPosition - config.doorWidth,
                        true))

                table.insert(doors, self:door(boundary.between, boundary.x, boundary.y + doorPosition, true))

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

                table.insert(doors, self:door(boundary.between, boundary.x + doorPosition, boundary.y, false))

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

function HouseGenerator:door(between, x, y, vertical)
    local gs = config.gridScale
    return {
        x = x * gs,
        y = y * gs,
        vertical = vertical,
        between = between,
    }
end

function HouseGenerator:unscaleRect(rect)
    local gs = config.gridScale
    return {
        [TL] = { x = math.floor(rect[TL].x / gs), y = math.floor(rect[TL].y / gs) },
        [TR] = { x = math.floor(rect[TR].x / gs), y = math.floor(rect[TR].y / gs) },
        [BR] = { x = math.floor(rect[BR].x / gs), y = math.floor(rect[BR].y / gs) },
        [BL] = { x = math.floor(rect[BL].x / gs), y = math.floor(rect[BL].y / gs) },
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
            color = { love.math.random(), love.math.random(), love.math.random() },
            floor = config.floorTypes[love.math.random(1, #config.floorTypes)]
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
    for y = rect[TL].y, rect[BL].y - 1 do
        for x = rect[TL].x, rect[TR].x - 1 do
            -- if x==rect[TL].x or x==rect[TR].x or y==rect[TL].y or y==rect[BR].y then
            -- self.grid:set(x, y, "#")
            -- else
            self.grid:set(x, y, node.id)
            -- end
        end
    end
end

function HouseGenerator:draw()
    -- print("drawing")
    local line = ""
    local x, y
    for y = 0, self.grid.h - 1 do
        for x = 0, self.grid.w - 1 do
            line = "" .. line .. (self.grid.data[self.grid:pos(x, y)] or "wut")
        end
        print(line)
        line = ""
    end
end

return HouseGenerator
