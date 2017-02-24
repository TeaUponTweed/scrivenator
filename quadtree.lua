QuadTree = {}
Quadtree.MAX_OBJECTS=5


function QuadTree.new(left, top, width, height)
    o = {}
    o.x = left
    o.y = top
    o.w = width
    o.h = height
    children = nil
    objects = {}
end



-- function Quadtree:relevantChild(x, y)
--     assert(x >= self.x and self.x + self.width > x)
--     assert(y >= self.y and self.y + self.height > y)
--     local left  =  (x < self.x + self.width/2)
--     local right = not left
--     local upper =  (y < self.y + self.height/2)
--     local lower = not upper
--     if upper and left
--         return 1
--     elseif upper and right
--         return 2
--     elseif lower and left
--         return 3
--     elseif lower and right
--         return 4
--     end
-- end

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

-- function Quadtree:add(o)
--     if not self.children
--         assert(self.objects)
--         self.objects[o] = o
--         if #self.objects > Quadtree.MAX_OBJECTS
--             self:subdivide()
--         end
--     else
--         assert(not self.objects)
--         self.chidren[self.relevantChild(o.x, o.y)]:add(o)
-- end




function Quadtree:applyToLeaf(leafFunc, childRelevant):
    if self.children
        for _, child in pairs(self.children) do
            if childRelevant(child) then
                child:applyToLeaf(leafFunc, childRelevant)
            end
        end
    else
        leafFunc(self)
    end
end

function Quadtree:add(o)
    self:applyToLeaf(
        function (qt)
            contains(qt, o.x, o.y),
        end,
        function (qt)
            qt.objects[o] = o
            if #qt.objects > Quadtree.MAX_OBJECTS
                qt:subdivide()
            end
        end)
end


function Quadtree:remove(o) -- TODO collapse tree
    self:applyToLeaf(function (qt) contains(qt, o.x, o.y),
        function (qt)
            qt.objects[o] = nil
        end)
end

function Quadtree:getIn(r)
    ret = {}

end
-- function QuadTree:check(object, func, x, y)
--     local oleft   = x or object.x
--     local otop    = y or object.y
--     local oright  = oleft + object.width - 1
--     local obottom = otop + object.height - 1

--     for i,child in pairs(self.children) do
--         local left   = child.left
--         local top    = child.top
--         local right  = left + child.width - 1
--         local bottom = top  + child.height - 1

--         if oright < left or obottom < top or oleft > right or otop > bottom then
--             -- Object doesn't intersect quadrant
--         else
--             func(child)
--         end
--     end
-- end

        -- end
    else
        self:check(object, function(child) child:addObject(object) end)
    end
end

function QuadTree:removeObject(object, usePrevious)
    if not self.children then
        self.objects[object] = nil
    else
        -- if 'usePrevious' is true then use prev_x/y else use x/y
        local x = (usePrevious and object.prev_x) or object:getX()
        local y = (usePrevious and object.prev_y) or object:getY()
        self:check(object,
            function(child)
                child:removeObject(object, usePrevious)
            end, x, y)
    end
end

function QuadTree:updateObject(object)
    self:removeObject(object, true)
    self:addObject(object)
end

function QuadTree:removeAllObjects()
    if not self.children then
        self.objects = {}
    else
        for i,child in pairs(self.children) do
            child:removeAllObjects()
        end
    end
end

function QuadTree:getCollidableObjects(object, moving)
    if not self.children then
        return self.objects
    else
        local quads = {}

        self:check(object, function (child) quads[child] = child end)
        if moving then
            self:check(object, function (child) quads[child] = child end,
                object.prev_x, object.prev_y)
        end

        local near = {}
        for q in pairs(quads) do
            for i,o in pairs(q:getCollidableObjects(object, moving)) do
                -- Make sure we don't return the object itself
                if i ~= object then
                    table.insert(near, o)
                end
            end
        end

        return near
    end
end

QuadTree_mt.__index = QuadTree
