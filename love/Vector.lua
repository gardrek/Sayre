-- Generic Vector class, with any number of elements
local Vector = {}
Vector.class = 'Vector'

setmetatable(Vector, {
  __call = function(self, ...)
    return self:new(...)
  end,
})

Vector.__call = function()
  -- in theory this should protect against accidentally calling individual vectors
  error('attempt to call vector as function', 2)
end

Vector.name = {
  x = 1, y = 2, z = 3,
}

Vector.__index = function(table, key)
  if Vector.name[key] then
    return rawget(table, Vector.name[key])
  elseif rawget(table, key) then
    return rawget(table, key)
  elseif rawget(Vector, key) then
    return rawget(Vector, key)
  end
end

function Vector:new(t)
  if type(t) == 'number' then
    return Vector:zero(t)
  elseif type(t) == 'table' then
    return Vector:init(t)
  else
    error('Bad argument to Vector:new() of type ' .. type(t), 2)
  end
end

function Vector:zero(n)
  local obj = {}
  for i = 1, n do
    obj[i] = 0
  end
  return Vector:init(obj)
end

function Vector:init(v)
  return setmetatable(Vector.dup(v), Vector)
end

function Vector:dup()
  local obj = {}
  for i = 1, #self do
    obj[i] = self[i]
    if type(obj[i]) ~= 'number' then error('non-number vectors not allowed') end
  end
  for n, i in pairs(Vector.name) do
    if self[Vector.name[n]] then
      obj[i] = self[Vector.name[n]]
    end
  end
  setmetatable(obj, getmetatable(self) or Vector)
  return obj
end

function Vector:mag()
  return math.sqrt(self:magsqr())
end

function Vector:magsqr()
  local m = 0
  for i = 1, #self do
    m = m + self[i] * self[i]
  end
  return m
end

function Vector:dot(other)
  if type(other) ~= 'table' or other.class ~= 'Vector' or #self ~= #other then
    error('attempt to take dot product of two unlike vectors or of a non-vector.', 2)
  end
  local r = 0
  for i = 1, #self do
    r = r + self[i] * other[i]
  end
  return r
end

function Vector:project2d(other)
  if type(other) == 'table' and other.class == 'Vector' and #other == 2 then
    local n = self:dot(other)
    n = n / other:magsqr()
    return Vector:new{n * other.x, n * other.y}
  else
    error('attempt to project in 2d a non-2d vector or a non-vector.', 2)
  end
end

function Vector:__add(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] + other
    end
  else
    if #self ~= #other then error('Attempt to add unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] + other[i]
    end
  end
  return r
end

function Vector:__sub(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] - other
    end
  elseif type(other) == 'table' and other.class == 'Vector' then
    if #self ~= #other then error('Attempt to subtract unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] - other[i]
    end
  else
    error(tostring(other), 2)
  end
  return r
end

function Vector:__mul(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] * other
    end
  elseif type(other) == 'table' and other.class == 'Vector' then
    if #self ~= #other then error('Attempt to multiply unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] * other[i]
    end
  end
  return r
end

function Vector:__div(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] / other
    end
  else
    if #self ~= #other then error('Attempt to divide unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] / other[i]
    end
  end
  return r
end

function Vector:__unm()
  local r = Vector:new(#self)
  for i = 1, #self do
    r[i] = -self[i]
  end
  return r
end

function Vector:norm()
  return self / self:mag()
end

function Vector:__tostring()
  local s = '('
  for i = 1, #self do
    s = s .. tostring(self[i])
    if i ~= #self then
      s = s .. ', '
    end
  end
  return s .. ')'
end

function Vector:__eq(other)
  if #self ~= #other then return false end
  for i= 1, #self do
    if self[i] ~= other[i] then
      return false
    end
  end
  return true
end

function Vector:unpack()
  local t = {}
  for i = 1, #self do
    t[i] = self[i]
  end
  return unpack(t)
end

function Vector:isNull()
  for i = 1, #self do
    if self[i] ~= 0 then return false end
  end
  return true
end

-- 2D-only functions

function Vector:rotate(angle)
  if #self ~= 2 then error('Rotation of non-2D Vectors not implemented', 2) end
  local cs, sn, nx, ny
  cs, sn = math.cos(angle), math.sin(angle)
  nx = self.x * cs - self.y * sn
  ny = self.x * sn + self.y * cs
  return Vector:new{nx, ny}
end

function Vector:rotate2(other)
  if #self ~= 2 then error('Rotation of non-2D Vectors not implemented', 2) end
  local nx, ny
  nx = self.x * other.x - self.y * other.y
  ny = self.x * other.y + self.y * other.x
  return Vector:new{nx, ny}
end

function Vector:abs()
  local v = Vector:new(#self)
  for i = 1, #self do
    v[i] = math.abs(self[i])
  end
  return v
end

function Vector:each(func)
  local v = Vector:new(#self)
  for i = 1, #self do
    v[i] = func(self[i])
  end
  return v
end

function Vector:draw(x, y, scale, arrow)
  scale = scale or 16
  arrow = arrow or 4
  if #self ~= 2 then error('Drawing of non-2D Vectors not implemented', 2) end
  if self:mag() ~= 0 then
    local t = self * scale
    if arrow > 0 then
      local a, b
      local m = t:mag() / arrow
      a = t:rotate(math.pi / 6):norm() * -m
      b = t:rotate(math.pi / -6):norm() * -m
      love.graphics.line(t.x + x, t.y + y, t.x + x + a.x, t.y + y + a.y)
      love.graphics.line(t.x + x, t.y + y, t.x + x + b.x, t.y + y + b.y)
    end
    love.graphics.line(x, y, t.x + x, t.y + y)
  end
end

return Vector
