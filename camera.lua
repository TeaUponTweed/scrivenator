local camera = {}
camera.x = 0
camera.y = 0
camera.acc = 0
camera.scale = 1

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
  for _, square in pairs(objects) do
    local px = (square.x - self.x)/self.scale
    local py = (square.y - self.y)/self.scale
    local pxsize = square.xsize/self.scale
    local pysize = square.ysize/self.scale
    love.graphics.push()
    -- love.graphics.scale(1/self.scale, 1/self.scale)
    if px < self.pix_w and py < self.pix_h and px + pxsize >= 0 and py + pysize >= 0 then
      square:draw(px, py, self.scale)
      -- print('i love being drawn')
      -- love.graphics.rectangle("fill", px, py, pxsize, pysize)
    end
    love.graphics.pop()
  end
  print('all done drawing')
end

return camera
