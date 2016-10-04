Sprite = {}

function Sprite:new(o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function Sprite:from_paths(body, hand, relx, rely)
    print 'ere'
    print(body)
    local s = {}
    s.body = love.graphics.newImage(body)
    s.hand = love.graphics.newImage(hand)
    s.relx = relx
    s.rely = rely
    return s
    -- for _, path in pairs({...}) do
    --     print(path)
    -- end
end

return Sprite
