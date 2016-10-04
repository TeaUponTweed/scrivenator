GameObject = {}

function GameObject:new(o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function GameObject:draw(px, py, scale)
      love.graphics.draw(self.sprite.body, px, py)
      love.graphics.draw(self.sprite.hand, px + self.sprite.relx, py + self.sprite.rely)
end

return GameObject
