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
                          p = {}
                          p.x = x
                          p.y = y
                          return p
                      end )
    ecs:new_component('velocity',
                      function(vx, vy)
                          v = {}
                          v.vx = vx
                          v.vy = vy
                          return v
                      end )
 end

function love.update(dt)
    ecs:process({'position', 'velocity'},
                function (p, v)
                    p.x = p.x + v.vx
                    p.y = p.y + v.vy
                end)

end

function love.draw()
    love.graphics.push()
    love.graphics.scale(1.0/camera.scale, 1.0/camera.scale)
    love.graphics.translate(-camera.x, -camera.y)
    ecs:process('position',
                function (p)
                    love.graphics.rectangle("fill", p.x, p.y, 10, 10)
                end )
    love.graphics.pop()
end

function love.mousepressed(px, py, button, istouch)
    -- TODO serialize input
    if button == 2 then
        ecs:new_entity():with('position', {unpack(camera:abs(px, py))}):
                         with('velocity', {3, 1})
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
