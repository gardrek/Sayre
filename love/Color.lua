local Vector = require 'Vector'

local Color = {
  Blank         = Vector{0.0,   0.0,   0.0,   0.0},
  Black         = Vector{0.0,   0.0,   0.0},
  FullBright    = Vector{1.0,   1.0,   1.0},
  ScreenBorder  = Vector{0.5,   0.5,   0.5},
  Magenta       = Vector{1.0,   0.0,   1.0},
  Hitbox        = Vector{0.0,   0.0,   1.0,   0.5},
  HitboxHit     = Vector{1.0,   0.0,   0.0,   0.5},
}

function Color:new(t)
  local v
  if type(t) == 'table' then
    v = Vector:new(t)
  elseif type(t) == 'string' then
    t = tonumber(t, 16)
  elseif type(t) ~= 'number' then
    error'bad color init'
  end
  if type(t) == 'number' then
    v = Vector{
      (math.floor(t / (256 * 256)) % 256) / 255,
      (math.floor(t / 256) % 256) / 255,
      (t % 256) / 255
    }
  end
  v.class = 'Color'
  return v
end

function Color:addColors(colors)
  for k, v in pairs(colors) do
    Color[k] = Color:new(v)
  end
end

for index, color in pairs(Color) do
  if type(color) == 'table' and color.class == 'Vector' then
    color.class = 'Color'
  end
end

return Color
