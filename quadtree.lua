QuadTree = {}
QuadTree.MAX_OBJECTS=5


function QuadTree.new(left, top, width, height)
    o = {}
    setmetatable(o, self)
    self.x = left
    self.y = top
    self.w = width
    self.h = height
    self.children = nil
    self.objects = {}
    return o
end


function contains(qt, x, y)
    return (x >= qt.x and qt.x + qt.width > x) and (y >= qt.y and qt.y + qt.height > y)
end


function intersects(qt1, qt2)
    return (contains(qt1, qt2.x        , qt2.y         ) or
            contains(qt1, qt2.x + qt2.w, qt2.y         ) or
            contains(qt1, qt2.x        , qt2.y + qt2.h ) or
            contains(qt1, qt2.x + qt2.w, qt2.y + qt2.h ) )
end


function QuadTree:subdivide()
    if self.children then
        for i,child in pairs(self.children) do
            child:subdivide()
        end
    else
        local x = self.x
        local y = self.y
        local w = self.width / 2
        local h = self.height / 2
        self.children = {
            QuadTree.new(x    , y    , w, h),
            QuadTree.new(x + w, y    , w, h),
            QuadTree.new(x    , y + h, w, h),
            QuadTree.new(x + w, y + h, w, h)
        }
        objects = self.objects
        self.objects = nil
        for _, o in pairs(objects) do
            self:add(o)
        end
    end
end


function QuadTree:applyToLeaf(func)
    if self.children then
        for _, child in pairs(self.children) do
            child:applyToLeaf(func)
        end
    else
        leafFunc(self)
    end
end


function QuadTree:add(o)
    assert(contains(self, o.x, o.y))
    self:applyToLeaf(
        function (qt)
            if contains(qt, o.x, o.y) then
                qt.objects[o] = o
                if #qt.objects > QuadTree.MAX_OBJECTS then
                    qt:subdivide()
                end
            end
        end)
end


function QuadTree:remove(o) -- TODO collapse tree as objects are removed
    self:applyToLeaf(
        function (qt)
            qt.objects[o] = nil
        end)
end


function QuadTree:update(o)
    self:remove(o)
    self:add(o)
end


function QuadTree:getIn(r)
    ret = {}
    self:applyToLeaf(
        function (qt)
            if intersect(qt, r) then
                for _, o in qt.objects do
                    ret[#ret+1] = o
                end
            end
        end)
end


return QuadTree
