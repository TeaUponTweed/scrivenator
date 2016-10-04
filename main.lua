local camera = require("camera")
local Sprite = require("sprite")
local GameObject = require("game_object")

local allObjects = {}

function love.load()
	love.graphics.setBackgroundColor(54, 172, 248)
    -- TODO window resize
	camera.pix_w = love.graphics.getWidth()
	camera.pix_h = love.graphics.getHeight()
 end

function love.update(dt)

end

function love.draw()

   -- love.graphics.push()
   -- love.graphics.scale(0.5, 0.5)   -- reduce everything by 50% in both X and Y coordinates
   -- love.graphics.print("Scaled text", 50, 50)
   -- love.graphics.pop()
   -- love.graphics.print("Normal text", 50, 50)

	camera:draw(allObjects)
    love.graphics.print(camera.x, 10, 10)
    love.graphics.print(camera.y, 10, 30)
    love.graphics.print(camera.scale, 10, 50)
end

function love.mousepressed(px, py, button, istouch)
   if button == 2 then
        obj = GameObject:new({x=px*camera.scale + camera.x,
                              y=py*camera.scale + camera.y,
                              sprite=Sprite:from_paths("assets/circle.png", "assets/spear.png", 10, 50),
                              xsize=10,
                              ysize=10})
   		allObjects[#allObjects+1] = obj
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
