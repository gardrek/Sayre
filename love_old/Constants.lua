local mt = {
  __index = function(t, k)
    local v = rawget(t, k)
    if not v then error('non-existant constant ' .. tostring(k), 2) end
    return v
  end,
}

--------

local Vector = require 'Vector'

rawset(_G, 'HEART_VALUE', 16)

rawset(_G, 'ZEROVEC', Vector:new{0, 0})

rawset(_G, 'TILESIZE', 16)
rawset(_G, 'TILEVEC', Vector:new{TILESIZE, TILESIZE})
rawset(_G, 'HALFTILEVEC', TILEVEC / 2)


rawset(_G, 'ROOM_DIMENSIONS', Vector:new{TILESIZE * 12, TILESIZE * 8})

--------

rawset(_G, 'inspect', require 'inspect')
rawset(_G, 'prinspect', function (...)
  print(inspect(...))
end)

rawset(_G, 'dir_name', {
  [0] = 'right',
  'down',
  'left',
  'up',
})

local dir2vec = {
  ['right'] = Vector:new{1, 0},
  ['down'] = Vector:new{0, 1},
  ['left'] = Vector:new{-1, 0},
  ['up'] = Vector:new{0, -1},
}

for i = 0, 3 do
  dir2vec[i] = dir2vec[dir_name[i]]
end

setmetatable(dir2vec, mt)

rawset(_G, 'dir2vec', dir2vec)

local function callback(f, ...)
  if f then
    if type(f) ~= 'function' then
      error('attempt to call non-function callback', 2)
    end
    return f(...)
  end
end

local function recursive_copy(t, d)
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
end

rawset(_G, 'recursive_copy', recursive_copy)

--------

local Spritesheet = require 'Spritesheet'

local sprites = Spritesheet.load('tileset.png', TILESIZE, TILESIZE)
--local sprites = Spritesheet.load('test.png', TILESIZE, TILESIZE)
rawset(_G, 'sprites', sprites)

local numerals8x8 = Spritesheet.load('numbers8x8.png', TILESIZE / 2, TILESIZE / 2)
numerals8x8:setCharacters'0123456789-xc.ef'
rawset(_G, 'numerals8x8', numerals8x8)

local font8x16 = Spritesheet.load('font_italic_8x16.png', TILESIZE / 2, TILESIZE)
rawset(_G, 'font8x16', font8x16)

local maptiles = Spritesheet.load('maptiles8x8.png', 8, 8)
rawset(_G, 'maptiles', maptiles)


if love.mouse.isCursorSupported() then
  local scale = 3
  local mouse_cursor_red = love.mouse.newCursor('mouse_red.png', 0.5 * scale, 0.5 * scale)
  rawset(_G, 'mouse_cursor_red', mouse_cursor_red)

  local mouse_cursor_brush = love.mouse.newCursor('mouse_brush.png', 7.5 * scale, 0.5 * scale)
  rawset(_G, 'mouse_cursor_brush', mouse_cursor_brush)

  local mouse_cursor_wand = love.mouse.newCursor('mouse_wand.png', 2.5 * scale, 2.5 * scale)
  rawset(_G, 'mouse_cursor_wand', mouse_cursor_wand)
end

rawset(_G, 'TILE', setmetatable({
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

rawset(_G, 'PALETTE', setmetatable({
  GREY = 0,
  GREEN = 1,
  CYAN = 2,
  BLUE = 3,
  PURPLE = 4,
  REDPURPLE = 5,
  RED = 6,
  BROWN = 7,
  YELLOW = 8,
}, mt))
