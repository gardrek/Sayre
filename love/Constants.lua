local mt = {
  __index = function(t, k)
    local v = rawget(t, k)
    if not v then error('Attempt to access non-existant constant ' .. tostring(k) .. ' in constant table ' .. tostring('') .. '.', 2) end
    return v
  end,
}

require 'global'

-- Functions and Constants --------

global('callback', function(f, ...)
  if f then
    if type(f) ~= 'function' then
      local mt = getmetatable(f)
      if not (type(mt) == 'table' and mt.__call) then
        error('callback is not a function and cannot be called', 2)
      end
    end
    return f(...)
  end
end)

global('recursive_copy', function(t, d)
  d = d or 0
  local new = {}
  for k, v in pairs(t) do
    if type(v) == 'table' then
      if d > 10 then error('breaking potential loop in recursive copy') end
      if type(v.dup) == 'function' then
        local d = v:dup()
        if d == nil then error'' end
        new[k] = d
      else
        new[k] = recursive_copy(v, d + 1)
      end
    else
      new[k] = v
    end
  end
  return new
end)

global('simpleClass', function(name)
  local c = {}
  c.class = name
  c.__index = function(table, key)
    local value = rawget(table, key)
    if not value then
      value = rawget(c, key)
    end
    if not value then
      value = rawget(c, key)
    end
    if not value then
      error(
        'Attempt to access non-existant member ' .. key ..
        ' of class ' .. (rawget(c, 'class') or 'UnkownClass'),
        2
      )
    end
    return value
  end
  return c
end)

global('buildString', function(...)
  local t = {}
  local n = select('#', ...)
  if n == 0 then return '' end
  for i = 1, n do
    t[i] = select(i, ...)
  end
  return table.concat(t)
end)

global('errorP', function(level, ...)
  error(buildString(...), level)
end)

requireGlobal 'inspect'

requireGlobal 'Class'

requireGlobal 'Vector'

global('Screen', require('Screen'):new(192, 160, 8, 'palette.png'))

requireGlobal 'Color'

requireGlobal 'Palette'
requireGlobal 'Tileset'
requireGlobal 'Map'

requireGlobal 'Camera'

requireGlobal 'Sound'

requireGlobal 'Attack'
requireGlobal 'Hitbox'

requireGlobal'Input'

global('DEBUG_MODE', true)
global('SLOWMO', false)

global('HEART_VALUE', 16)

global('TILESIZE', 16)
global('TILEVEC', Vector{TILESIZE, TILESIZE})
global('HALFTILEVEC', TILEVEC / 2)
global('ROOM_DIMENSIONS', Vector{TILESIZE * 12, TILESIZE * 8})

requireGlobal'Mob'

requireGlobal'Moblist'

local smallTile = 8
local bigTile = smallTile * 2

global('mainPalette', Palette:new('palette8.png', 8, 16))
global('mainTileset', Tileset:load('tileset.png', smallTile, smallTile, mainPalette))

--global('fontItalic', Tileset:load('font_italic_8x16.png', TILESIZE / 2, TILESIZE))

--local maptiles = Tileset:load('maptiles8x8.png', 8, 8)
--global('maptiles', maptiles)


--if love.mouse.isCursorSupported() then
  --local scale = 3
  --local mouse_cursor_red = love.mouse.newCursor('mouse_red.png', 0.5 * scale, 0.5 * scale)
  --global('mouse_cursor_red', mouse_cursor_red)

  --local mouse_cursor_brush = love.mouse.newCursor('mouse_brush.png', 7.5 * scale, 0.5 * scale)
  --global('mouse_cursor_brush', mouse_cursor_brush)

  --local mouse_cursor_wand = love.mouse.newCursor('mouse_wand.png', 2.5 * scale, 2.5 * scale)
  --global('mouse_cursor_wand', mouse_cursor_wand)
--end

--------

global('prinspect', function (...)
  print(inspect(...))
end)

global('dir_name', setmetatable({
  [0] = 'right',
  'down',
  'left',
  'up',
}, mt))

global('dir2vec', {
  ['right'] = Vector{1, 0},
  ['down'] = Vector{0, 1},
  ['left'] = Vector{-1, 0},
  ['up'] = Vector{0, -1},
})

global('vec2dir', function (vec)
  local axis
  if math.abs(vec.x) > math.abs(vec.y) then
    axis = 0
  elseif math.abs(vec.x) < math.abs(vec.y) then
    axis = 1
  else
    return
  end
  if vec[axis + 1] > 0 then
    return 0 + axis
  elseif vec[axis + 1] < 0 then
    return 2 + axis
  else
    return
  end
end)

for i = 0, 3 do
  dir2vec[i] = dir2vec[dir_name[i]]
end

setmetatable(dir2vec, mt)

global('hold_offset', {
  left = {
    [0] = Vector:new{-4, -1},
    Vector:new{2, -4},
    Vector:new{4, 3},
    Vector:new{-2, 4},
  },
  right = {
    [0] = Vector:new{-4, 3},
    Vector:new{-2, -4},
    Vector:new{4, -1},
    Vector:new{2, 4},
  },
})

setmetatable(hold_offset, mt)
setmetatable(hold_offset.left, mt)
setmetatable(hold_offset.right, mt)

--------

global('TILE', setmetatable({
  PLAYER = 0x00,

  SWORD = 0x80,
  KNIFE = 0x81,
  KNIFE_MULT = 0x89,
  WAND = 0x84,
  WAND_BLAST = 0x85,
  HEALTH_UP = 0x8c,
  BOTTLE_SMALL = 0xa8,
  BOTTLE_LARGE = 0xab,
  
  BUTTERFLY = 0xa0,

  HEART = 0x40,
  HEART_FULL = 0x44,

  BRACKETS = 0x48,
  BUTTON_LETTERS = 0x4a,

  BAR = 0x50,
  BAR_FULL = 0x49,

  NUMERALS = 0x60,

  EDIT = 0x70,

  PUFF = 0xb0,

  BLOCK = 0xc0,
  DOOR = 0xc8,

  DOOR_LOCKED_2X = 0xc9,
  DOOR_CLOSED = 0xcb,

  OVERHANG = 0xcc,

  ENEMY_BLOB_SMALL = 0x100,
  ENEMY_BLOB = 0x108,
  ENEMY_DEMON_BLOB = 0x110,
  ENEMY_SHOOTING_BLOB = 0x118,

  SHOOTING_SEED = 0x120,

  TEST = 0x47,

  ANIM = setmetatable({
    STEP = 4,
    ATTACK = 4,
    FLASH1 = 16,
    FLASH2 = 8,
  }, mt),
}, mt))

--------

global('PALETTE', setmetatable({
  GREY = 0,
  GREEN = 1,
  CYAN = 2,
  BLUE = 3,
  REDPURPLE = 4,
  RED = 5,
  YELLOW = 6,
  SILVER = 7,
  PURPLE = 8,
  BROWN = 9,
  FLASH1 = 14,
  FLASH2 = 15,
}, mt))
