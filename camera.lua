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

function camera:abs(px, py)
    return {px*self.scale + self.x, py*self.scale + self.y}
end

return camera
