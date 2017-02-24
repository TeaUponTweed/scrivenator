require "autobatch"

local camera = require("camera")
local ecs = require("ecs")
local vec = require("vector")
-- local kdtree = require("kdtree")
local QuadTree = require("quadtree")

local min = math.min
local max = math.max
local MAX_SPEED = 20

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

 end


function love.update(dt)
    qtree = QuadTree.new(-1000000, -1000000, 2000000, 2000000)
    ecs:process({'position'},
                function (p)
                    qtree:add(p)
                end)

    ecs:process({'position', 'velocity'},
                function (p, v)
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

function love.draw()

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
                            love.graphics.push()
                            love.graphics.setColor(255, 0, 0)
                            love.graphics.rectangle("line", p.x-2, p.y-2, 14, 14)
                            love.graphics.pop()
                        end
                    end
                    d.draw(p.x, p.y)
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
        local speed = love.math.random() * 300
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
end


function love.resize(w, h)
  camera.pix_w = w
  camera.pix_h = h
end


