-- GameObject = {}

-- function GameObject:new(o)
--   o = o or {}   -- create object if user does not provide one
--   setmetatable(o, self)
--   self.__index = self
--   return o
-- end

-- function GameObject:draw(px, py, scale)
--       love.graphics.draw(self.sprites.body, px, py)
--       love.graphics.draw(self.sprites.hand, px + self.sprites.relx, py + self.sprites.rely + 10*math.sin(self.sprites.t))
-- end

-- return GameObject
