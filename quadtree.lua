local QuadTree = {}

QuadTree.__index = QuadTree

QuadTree.MAX_OBJECTS=5

function QuadTree.new(left, top, width, height)
    local self = setmetatable({}, QuadTree)
    self.x = left
    self.y = top
    self.w = width
    self.h = height
    self.children = nil
    self.objects = {}
    self.nobjects = 0
    return self
end

function QuadTree:contains(x, y)
    return (x >= self.x and self.x + self.w > x) and (y >= self.y and self.y + self.h > y)
end

function QuadTree:intersects(qt)
    return (self:contains(qt.x       , qt.y        ) or
            self:contains(qt.x + qt.w, qt.y        ) or
            self:contains(qt.x       , qt.y + qt.h ) or
            self:contains(qt.x + qt.w, qt.y + qt.h ) )
end

function QuadTree:relevantChild(x, y)
    assert(x >= self.x and self.x + self.width > x)
    assert(y >= self.y and self.y + self.height > y)
    local left  =  (x < self.x + self.width/2)
    local right = not left
    local upper =  (y < self.y + self.height/2)
    local lower = not upper
    if upper and left then
        return 1
    elseif upper and right then
        return 2
    elseif lower and left then
        return 3
    elseif lower and right then
        return 4
    end
end

function QuadTree:subdivide()
    if self.children then
        for _,child in pairs(self.children) do
            child:subdivide()
        end
    else
        local x = self.x
        local y = self.y
        local w = self.w / 2
        local h = self.h / 2
        self.children = {
            QuadTree.new(x    , y    , w, h),
            QuadTree.new(x + w, y    , w, h),
            QuadTree.new(x    , y + h, w, h),
            QuadTree.new(x + w, y + h, w, h)
        }
        local objects = self.objects
        self.objects = nil
        self.nobjects = 0
        for _, o in pairs(objects) do
            self:add(o)
        end
    end
end

function QuadTree:applyToLeaf(func)
    if self.children then
        assert(not self.objects)
        for _, child in pairs(self.children) do
            child:applyToLeaf(func)
        end
    else
        assert(self.objects)
        func(self)
    end
end


function QuadTree:add(o)
    -- assert(contains(self, o.x, o.y), self.x .. " " .. self.y .. " " .. self.w .. " " .. self.h)
    self:applyToLeaf(
        function (qt)
            if qt:contains(o.x, o.y) then
                -- print('ere')
                assert(not qt.objects[o], "cant add same object to quadtree twice")
                qt.objects[o] = o
                qt.nobjects = qt.nobjects + 1
                -- print(#qt.objects)
                if qt.nobjects > QuadTree.MAX_OBJECTS then
                    qt:subdivide()
                end
            end
        end)
end

function QuadTree:remove(o) -- TODO collapse tree as objects are removed?
    self:applyToLeaf(
        function (qt)
            if (qt.objects[o]) then
                qt.objects[o] = nil
                qt.nobjects = qt.nobjects - 1
            end
        end)
end

function QuadTree:update(o)
    self:remove(o)
    self:add(o)
end

function QuadTree:getIn(r)
    local ret = {}
    self:applyToLeaf(
        function (qt)
            if qt:intersects(r) then
                for _, o in qt.objects do
                    ret[#ret+1] = o
                end
            end
        end)
    return ret
end

return QuadTree
