require "autobatch"

local camera = require("camera")
local ecs = require("ecs")
local vec = require("vector")
-- local kdtree = require("kdtree")
-- local QuadTree = require("quadtree").QuadTree
min = math.min
max = math.max
MAX_SPEED = 20

function love.load()
  love.window.setMode(0, 0, {resizable=true})
	love.graphics.setBackgroundColor(54, 172, 248)
    -- TODO window resize
	camera.pix_w = love.graphics.getWidth()
	camera.pix_h = love.graphics.getHeight()

    -- Initalize components
    ecs:new_component('position',
                      function(x, y)
                          local p = {}
                          p.x = x
                          p.y = y
                          return p
                      end )
    ecs:new_component('velocity',
                      function(vx, vy)
                          local v = {}
                          v.vx = vx
                          v.vy = vy
                          return v
                      end )
    ecs:new_component('plant_food',
                      function(growtime, maxfood)
                        local pf = {}
                        pf._growtime = growtime
                        pf._maxfood = maxfood
                        pf.timer = 0
                        return pf
                      end )
    ecs:new_component('vitality',
                      function (maxhealth, maxfood)
                        local v = {}
                        v._maxhealth = maxhealth
                        v._maxfood = maxfood
                        v.food = maxfood
                        v.health = maxhealth
                        return v
                      end )
    ecs:new_component('drawer',
                      function (drawfunc)
                        local d = {}
                        d.draw = drawfunc
                        return d
                      end )
 end


function love.update(dt)
    -- for _, p in pairs(ecs.components.position) do
    --     p.width = 10
    --     p.height = 10
    --     qtree:addObject(p)
    -- end
    -- function intersects(( ... )
        -- body
    -- end
    -- function  contains(p1, p2)
    --   if p1 == p2 then
    --     return false
    --   end
    --   return min(math.abs(p1.x + p1.width/2 - (p2.x + p2.width/2)),
    --              math.abs(p1.y + p1.height/2 - (p2.y + p2.height/2))) <= (min(p1.width, p1.height) + min(p2.width, p2.height))

    --     -- if p1.x < p2.x and p2.x <= p1.x + p1.width
    --     -- return p1.x <= p2.x and p2.x <= p1.x + p1.width and p1.y <= p2.y and p2.y <= p1.y + p1.height
    -- end
    -- function distance(p1, p2)
    --   dx = p1.x - p2.x
    --   dy = p1.y - p2.y
    --   return math.sqrt(dx*dx + dy*dy)
    -- end
    ecs:process({'position', 'velocity'},
                function (p, v)
                    for _, otherp in pairs(ecs.components.position) do
                    -- for _, otherp in pairs(qtree:getCollidableObjects(p, false)) do
                        local dx = p.x - otherp.x
                        local dy = p.y - otherp.y
                        local distance = math.sqrt(dx*dx + dy*dy)
                        if p ~= otherp and distance < 10 then
                            v.vx = -v.vx
                            v.vy = -v.vy
                            p.x = otherp.x + (10/distance * dx)
                            p.y = otherp.y + (10/distance * dy)
                            -- dx = p1.x - p2.x
                            break
                        end
                    end
                    p.x = p.x + v.vx * dt
                    p.y = p.y + v.vy * dt
                end)
    ecs:process({'vitality'},
                function (v)
                  if v.health <= 0 or v.food <= 0 then
                    return ecs.KILL
                  end
                end)
end

function love.draw() -- TODO use kd tree to find visible objects, requires ecs extension based on position
    local function my_bounds(o, min, max)
        min[1], min[2] = o.x, o.y
        max[1], max[2] = o.x+10, o.y+10
        return min, max
    end

    -- local tree = kdtree.build(my_bounds, 2, ecs.components.position)
    -- unpack(camera:abs(mousex, mousey))
    -- selected = {}
    -- print(ecs.components.position)
    -- for o in tree:query(camera:abs(unpack(MOUSE_1_DOWN)), camera:abs(unpack(MOUSE_1_BOX))) do
        -- selected[o] = true
  -- print("Found", tostring(o))
    -- end
    -- box_edges

    love.graphics.push()
    love.graphics.scale(1.0/camera.scale, 1.0/camera.scale)
    love.graphics.translate(-camera.x, -camera.y)
    ecs:process({'position', 'drawer'},
                function (p, d)
                    if MOUSE_1_BOX and MOUSE_1_DOWN then
                        local absd = camera:abs(unpack(MOUSE_1_DOWN))
                        local absb = camera:abs(unpack(MOUSE_1_BOX))
                        local t, r, b, l = min(absd[2], absb[2]), max(absd[1], absb[1]), max(absd[2], absb[2]), min(absd[1], absb[1])
                        selected = (l <= p.x and
                                    t <= p.y and
                                    r >= p.x and
                                    b >= p.y)
                        if selected and love.mouse.isDown(1) then
                            love.graphics.setColor(255, 0, 0)
                        else
                            love.graphics.setColor(255, 255, 255)
                        end
                    end
                    d.draw(p.x, p.y)
                end )
    love.graphics.pop()
    love.graphics.print(tostring(love.timer.getFPS( )), 10, 10)
    -- if love.mouse.isDown(1) then
        -- love.graphics.print(string.format('TL: (%s, %s), BR: (%s, %s)', MOUSE_1_DOWN[1], MOUSE_1_DOWN[2], MOUSE_1_BOX[1], MOUSE_1_BOX[2]), 10, 40)
        -- love.graphics.print(string.format('TL: (%s, %s), BR: (%s, %s)', TL[1], TL[2], BR[1], BR[2]), 10, 80)
    -- end
end

-- MOUSE_1_DOWN = {0, 0}

function love.mousepressed(px, py, button, istouch)
    -- TODO serialize input
    if button == 1 then
        MOUSE_1_DOWN = {px, py}
        MOUSE_1_BOX = nil
    end
end


MOUSE_1_BOX = {0, 0}
function love.mousemoved( px, py, pdx, pdy, istouch )
    mousex, mousey = px, py
    if love.mouse.isDown(1) then
        camera:move_pixels(-pdx, -pdy)
    end
    -- if love.mouse.isDown(1) then
    --     MOUSE_1_BOX = {px, py}
    -- end
end


function love.wheelmoved(_, dir)
	local mx, my = love.mouse.getPosition( )
    if dir > 0 then
    	camera:scale_around(17/16, mx, my)
    elseif dir < 0 then
    	camera:scale_around(15/16, mx, my)
    end
end


function love.keypressed(k)
   if k == 'escape' then
      love.event.quit()
   elseif k == 'space' then
      for _=1,20 do
        local isbear = love.math.random() <= .2
        local draw_func = function(x, y)
                            -- if isbear then
                            --     love.graphics.setColor(150, 75, 0)
                            -- else
                            --     love.graphics.setColor(255, 255, 255)
                            -- end
                            love.graphics.rectangle("fill", x, y, 10, 10)
                    end
        dir = love.math.random() * 2 * math.pi
        speed = love.math.random() * 100
        vx = speed*math.cos(dir)
        vy = speed*math.sin(dir)
        px, py = unpack(camera:abs(mousex, mousey))
        px = px + (love.math.random()-.5)*200
        py = py + (love.math.random()-.5)*200
        ecs:new_entity():with('position', {px, py}):
                         with('velocity', {vx, vy}):
                         with('drawer', {draw_func})
     end
   end
end


function love.resize(w, h)
  camera.pix_w = w
  camera.pix_h = h
end


