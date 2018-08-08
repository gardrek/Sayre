local Vector = require 'Vector'

local Color = {
  Blank         = Vector:new{0.0,   0.0,   0.0,  0.0},
  FullBright    = Vector:new{1.0,   1.0,   1.0},
  ScreenBorder  = Vector:new{0.5,   0.5,   0.5},
  Hitbox        = Vector:new{0.75,  0.25,  0.25, 0.5},
  BG            = Vector:new{0.25,  0.75,  0.25},
  FG            = Vector:new{0.5,   0.75,  0.25},
  Magenta       = Vector:new{1.0,   0.0,   1.0},
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
    v = Vector:new{
      (math.floor(t / (256 * 256)) % 256) / 255,
      (math.floor(t / 256) % 256) / 255,
      (t % 256) / 255
    }
  end
  v.class = 'Color'
  return v
end

do
  local c = {
    Black = 0x000000,
    Steel = 0x445555,
    Fog = 0x778877,
    Dust = 0xaabb99,
    White = 0xeeeeee,

    Blue = 0x223388,
    Lavender = 0x8877aa,
    Plum = 0x552255,
    Red = 0xaa3322,
    Brown = 0x774422,
    Orange = 0xcc7733,
    Yellow = 0xddbb77,
    Spring = 0x669955,
    Forest = 0x337744,
    Seafoam = 0x44aa77,

    Sepia = 0x998866,
  }

  for k, v in pairs(c) do
    Color[k] = Color:new(v)
  end
end

--do
  --local c = {
    ----[0] =
    ----0xddeecc,
    ----0xccbb88,
    ----0x887788,
    ----0x884433,
    ----0x99bb99,
    ----0x668855,
    ----0x114455,
    ----0x001122,
    --[0] =
    --0xeeeeee,
    --0x000000,
    --0x000000,
    --0x000000,
    --0x000000,
    --0x000000,
    --0x000000,
    --0x000000,
    --0x000000,
  --}
  --for i = 0, #c do
    --Color[i] = Color:new(c[i])
  --end
--end

for index, color in pairs(Color) do
  if type(color) == 'table' and color.class == 'Vector' then
    color.class = 'Color'
  end
end

return Color
