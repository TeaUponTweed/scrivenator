require "autobatch"

local camera = require("camera")
local ecs = require("ecs")
local vec = require("vector")
-- local kdtree = require("kdtree")
local QuadTree = require("quadtree")

local min = math.min
local max = math.max
local MAX_SPEED = 20
local delta = 0

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
    qtree = QuadTree.new(-1000000, -1000000, 2000000, 2000000)
    -- tick.rate = 1/12
 end


function love.update(dt)
    delta = delta + dt
    if delta < .1 then
        return
    end
    dt = delta
    qtree = QuadTree.new(-1000000, -1000000, 2000000, 2000000)
    ecs:process({'position'},
                function (p)
                    qtree:add(p)
                end)

    ecs:process({'position', 'velocity'},
                function (p, v)
                    p.x = p.x + v.vx * dt
                    p.y = p.y + v.vy * dt
                    for _, otherp in pairs(qtree:getIn({x=p.x-10, y=p.y-10, w=30, h=30})) do
                        local dx = p.x - otherp.x
                        local dy = p.y - otherp.y
                        local distance = math.sqrt(dx*dx + dy*dy)
                        if p ~= otherp and distance < 10 then
                            local dx = p.x - otherp.x - v.vx * dt
                            local dy = p.y - otherp.y - v.vy * dt
                            local distance = math.sqrt(dx*dx + dy*dy)
                            v.vx = -v.vx
                            v.vy = -v.vy
                            p.x = otherp.x + (10/distance * dx)
                            p.y = otherp.y + (10/distance * dy)
                            break
                        end
                    end
                end)

    ecs:process({'vitality'},
                function (v)
                  if v.health <= 0 or v.food <= 0 then
                    return ecs.KILL
                  end
                end)
    delta = 0
end

function love.draw()

    love.graphics.push()
    love.graphics.scale(1.0/camera.scale, 1.0/camera.scale)
    love.graphics.translate(-camera.x, -camera.y)
    if MOUSE_1_BOX and MOUSE_1_DOWN and love.mouse.isDown(1) then
        local absd = camera:abs(unpack(MOUSE_1_DOWN))
        local absb = camera:abs(unpack(MOUSE_1_BOX))
        x = min(absd[1], absb[1])
        y = min(absd[2], absb[2])
        w = math.abs(absd[1] - absb[1])
        h = math.abs(absd[2] - absb[2])
        for _, p in pairs(qtree:getIn({x=x, y=y, w=w, h=h})) do
            -- love.graphics.push()
            love.graphics.setColor(255, 0, 0)
            love.graphics.rectangle("line", p.x-2, p.y-2, 14, 14)
            -- love.graphics.pop()
        end
    end

    ecs:process({'position', 'velocity', 'drawer'},
                function (p, v, d)
                    d.draw(p.x+v.vx*delta, p.y+v.vy*delta)
                end )

    qtree:applyToLeaf(
        function (qt)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", qt.x, qt.y, qt.w, qt.h)
        end)

    love.graphics.pop()
    love.graphics.print(tostring(love.timer.getFPS( )), 10, 10)

end

MOUSE_1_DOWN = {0, 0}

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
    if love.mouse.isDown(2) then
        camera:move_pixels(-pdx, -pdy)
    end
    if love.mouse.isDown(1) then
        MOUSE_1_BOX = {px, py}
    end
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
                            love.graphics.push()
                            if isbear then
                                love.graphics.setColor(150, 75, 0)
                            else
                                love.graphics.setColor(255, 255, 255)
                            end
                            love.graphics.rectangle("fill", x, y, 10, 10)
                            love.graphics.pop()
                    end
        local dir = love.math.random() * 2 * math.pi
        local speed = love.math.random() * 200
        local vx = speed*math.cos(dir)
        local vy = speed*math.sin(dir)
        local px, py = unpack(camera:abs(mousex, mousey))
        px = px + (love.math.random()-.5)*200
        py = py + (love.math.random()-.5)*200
        ecs:new_entity():with('position', {px, py}):
                         with('velocity', {vx, vy}):
                         with('drawer', {draw_func})
     end
   end
    print(ecs.entity_num)
end


function love.resize(w, h)
  camera.pix_w = w
  camera.pix_h = h
end


