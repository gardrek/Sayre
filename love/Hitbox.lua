local Hitbox = simpleClass'Hitbox'

function Hitbox:new(...)
  local obj = {}

  local numArgs = select('#', ...)
  if numArgs == 1 then
    local t = select(1, ...)
    if type(t) == 'table' then
      if t.pos and t.corner and t.dim then
        obj.pos = t.pos:dup()
        obj.corner = t.corner:dup()
        obj.dim = t.dim:dup()
      elseif #t == 2 then
        local v = Vector:new(t)
        obj.pos = Vector:new(2)
        obj.corner = -v / 2
        obj.dim = v
      else
        error''
      end
    end
  --elseif numArgs == 2 then
    --local a, b = select(1, ...)
    --if type(a) == 'table' and type(b) == 'table' then
      --if a.class == 'Vector' and b.class == 'Vector' then
        --obj.pos = Vector:new(2)
        --obj.corner = a:dup()
        --obj.dim = b:dup()
      --else
        --error''
      --end
    --else
      --error''
    --end
  else
    error''
  end

  setmetatable(obj, Hitbox)
  return obj
end

function Hitbox:dup()
  return Hitbox:new(self)
end

function Hitbox:setPos(v)
  if #v ~= 2 then
    error'Hitbox:setPos takes one vector of length 2'
  end
  self.pos = Vector:new(v)
end

function Hitbox:overlaps(other)
  local topleft0 = self.pos + self.corner
  local bottomright0 = topleft0 + self.dim

  local topleft1 = other.pos + other.corner
  local bottomright1 = topleft1 + other.dim

  local minkowski = {
    topleft = topleft0 - bottomright1,
    dim = self.dim + other.dim,
  }

  minkowski.bottomright = minkowski.topleft + minkowski.dim

  if
    minkowski.topleft.x < 0 and
    minkowski.topleft.y < 0 and
    minkowski.bottomright.x > 0 and
    minkowski.bottomright.y > 0 then
      return true -- return penetration vector instead?
  else
    return false
  end
end

-- untested function
function Hitbox:draw()
  local color = love.graphics.getColor()
  love.graphics.setColor(Color.Black)
  love.graphics.rectangle('fill', v.pos.x, v.pos.y - 1, 1, 3)
  love.graphics.rectangle('fill', v.pos.x - 1, v.pos.y, 3, 1)
  love.graphics.setColor(color)

  local c = self.pos + self.corner
  love.graphics.setColor(Color.Hitbox)
  love.graphics.rectangle('fill', c.x, c.y, self.dim.x, self.dim.y)
end

-- untested function
function Hitbox:originOutOfBounds()
  return
    self.corner.x > 0 or self.corner.y > 0 or
    self.pos.x > self.corner.x + self.dim.x or
    self.pos.y > self.corner.y + self.dim.y
end

return Hitbox
