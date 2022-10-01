-- Using BSP to generate a very simple house
-- We start with a rectangle and then split into rooms up to specified level

-- Inspo: https://codereview.stackexchange.com/questions/4334/is-this-a-bsp-tree-am-i-missing-something

local Class = require("hump.class")
local config = require("config")

MAX_RECURSION = 3
TL = 1
BL = 2
BR = 3
TR = 4
minRoomSize = 3

local HouseGenerator = Class {
  init = function(self)
    self:generate()
  end,
  grid = {
    w = 60,
    h = 20,
    roomCount = 1,
    data = {},
    pos = function (self, x, y) return (x * self.w + y) + 1 end,
    get = function (self, x, y) return self.data[self:pos(x, y)] end,
    set = function (self, x, y, value) self.data[self:pos(x, y)] = value end,
    reset = function(self) 
        for i = 1, self.w * self.h do
            self.data[i] = " "
        end
    end,
  },
}

function HouseGenerator:generate()
    self.grid:reset()
    self.roomCount = 1

    -- Create the root node
    local rect = {
        [TL] = {x = 0, y = 0},
        [BL] = {x=0,y=self.grid.h},
        [BR] = {x=self.grid.w,y=self.grid.h},
        [TR] = {x=self.grid.w,y=0}
    }
    local root = self:node(nil, rect)
    self:splitNode(root)

end

function HouseGenerator:splitNode(node)
    -- If we don't need to split anymore, then we have a room!
    if node.level >= MAX_RECURSION then
        node.id = self.roomCount
        self.roomCount = self.roomCount + 1
        return
    end

    local split = self:whereDoSplit(node)

    -- If no split was returned, then we can't go further, so just finish
    if split == nil then
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
        local rect1 = {[TL] = t[TL], [BL] = t[BL], [TR] = {x=split,y=t[TR].y}, [BR] = {x=split,y=t[BR].y}}
        local rect2 = {[TL] = {x=split,y=t[TL].y}, [BL] = {x=split,y=t[BL].y}, [TR] = t[TR], [BR] = t[BR]}
        return rect1,rect2
    else
        local rect1 = {[TL]=t[TL],[TR] = t[TR],[BL]={x=t[BL].x,y=split}, [BR]={x=t[BR].x,y=split}}
        local rect2 = {[TL]={x=t[TL].x,y=split},[TR]={x=t[TR].x,y=split},[BL]=t[BL],[BR] = t[BR]}
        return rect1,rect2
    end
end

function HouseGenerator:whereDoSplit(node) 
    if node.vertical_split then
        local size = math.floor((math.random(20, 80)/ 100) * node.w)

        -- Ensure split rooms aren't going to be less than minimum
        if size < minRoomSize or size > node.w - minRoomSize then
            return nil
        end

        -- Split at this x
        return node.rect[TL].x + size
    else
        local size = math.floor((math.random(20, 80)/ 100) * node.h)

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
        left = nil,
        right = nil,
        rect = rect,
        parent = parent,
        level = level,
        vertical_split = love.math.random(0, 1) > 0 and true or false,
        w = rect[TR].x-rect[TL].x,
        h = rect[BL].y-rect[TL].y 
    }

    self:drawNode(n)

    return n
end

function HouseGenerator:drawNode(node)
    local rect = node.rect
    for y = rect[TL].y, rect[BL].y do
        for x = rect[TL].x, rect[TR].x do
            if x==rect[TL].x or x==rect[TR].x or y==rect[TL].y or y==rect[BR].y then
                self.grid:set(x, y, "#")
            else
                self.grid:set(x, y, ".")
            end
        end
    end
end


function HouseGenerator:draw()
    print("drawing")
    local line = ""
    local x,y
    for y = 0, self.grid.h do
        for x = 0, self.grid.w do
            line = ""..line..(self.grid.data[self.grid:pos(x,y)] or 0)
        end
        print(line)
        line = ""
    end
end

return HouseGenerator