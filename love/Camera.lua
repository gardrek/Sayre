local Vector = require 'Vector'

local Camera = {
  pos = Vector:new{0, 0},
  target = Vector:new{0, 0},
  offset = Vector:new{1 / 32, 1 / 32},
}

local function ease(x, tx, drag, min)
  drag = drag or 8
  min = min or 0.001
  local dx = (tx - x) / drag
  if math.abs(dx:mag()) < min then
    return tx
  else
    return x + dx
  end
end

function Camera:update()
  --self.pos = self.pos + (self.target - self.pos)
  self.pos = ease(self.pos, self.target + self.offset) - self.offset
end

return Camera
