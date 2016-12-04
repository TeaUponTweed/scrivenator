require "autobatch"

local camera = require("camera")
local ecs = require("ecs")
-- local kdtree = require("kdtree")

local entities = {}
local positions = {}


function love.load()
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
                      function(grow_time, maxfood)
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
                  d.draw(p.x, p.y)
                end )
    love.graphics.pop()
    love.graphics.print(tostring(love.timer.getFPS( )), 10, 10)
end


function love.mousepressed(px, py, button, istouch)
    -- TODO serialize input
    if button == 2 then
        local isbear = love.math.random() <= .2
        local draw_func = function(x, y)
                            if isbear then
                                love.graphics.setColor(150, 75, 0)
                            else
                                love.graphics.setColor(255, 255, 255)
                            end
                            love.graphics.rectangle("fill", x, y, 10, 10)
                    end
        ecs:new_entity():with('position', {unpack(camera:abs(px, py))}):
                         with('velocity', {20*(love.math.random()-.5), 20*(love.math.random()-.5)}):
                         with('drawer', {draw_func})
   end
end


function love.mousemoved( px, py, pdx, pdy, istouch )
    if love.mouse.isDown(1) then
        camera:move_pixels(-pdx, -pdy)
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
   end
end
