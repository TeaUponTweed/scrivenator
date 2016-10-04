local camera = {}
camera.x = 0
camera.y = 0
camera.acc = 0
camera.scale = 10

function camera:scale_around(alpha, x, y)
  local dx = x*self.scale*(1-alpha)
  local dy = y*self.scale*(1-alpha)
  self.x = self.x + dx
  self.y = self.y + dy
  self.scale = self.scale*alpha
end

function camera:move_pixels(pdx, pdy)
  local dx = self.scale*pdx
  local dy = self.scale*pdy
  self.x = self.x + dx
  self.y = self.y + dy
end

function camera:draw(objects)
  love.graphics.push()
  love.graphics.scale(1/self.scale, 1/self.scale)
  for _, square in pairs(objects) do
    local dx = (square.x - self.x)
    local dy = (square.y - self.y)
    local pxsize = square.xsize
    local pysize = square.ysize

    -- if px < self.pix_w and py < self.pix_h and px + pxsize >= 0 and py + pysize >= 0 then
    square:draw(dx, dy, self.scale)
    -- love.graphics.rectangle("fill", px, py, pxsize, pysize)
    -- end
  end
  love.graphics.pop()
end

return camera
