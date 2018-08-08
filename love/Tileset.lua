local Tileset = {}
Tileset.class = 'Tileset'

function Tileset.__index(table, key)
  local value = rawget(table, key)
  if not value then
    value = rawget(Tileset, key)
  end
  if not value then
    value = rawget(Tileset, key)
  end
  if not value then
    error(
      'Attempt to access non-existant member ' .. key ..
      ' of class ' .. (rawget(Tileset, 'class') or 'UnkownClass'),
      2
    )
  end
  return value
end

local function init_chars(str)
  local t = {}
  for i = 1, #str do
    local c = str:sub(i, i)
    t[c] = i
  end
  return t
end

local defaultchars = init_chars' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌷'

Tileset.template = {
  characters = defaultchars,
}

function Tileset:new(template)
  template = template or {}
  local instance = {}

  for k, v in pairs(self.template) do
    instance[k] = v
  end

  for k, v in pairs(template) do
    if Tileset[k] then
      error('attempt to overwrite built-in ' .. k .. ' on class' .. Tileset.class, 2)
    end
    instance[k] = v
  end

  setmetatable(instance, Tileset)
  return instance
end

function Tileset:load(filename, width, height, palette)
  if not(filename and width and height and palette) then
    error('not enough arugments', 2)
  end
  local instance = Tileset:new{
    w = width,
    h = height,
    palette = palette,
  }

  instance.image = love.graphics.newImage(filename)

  local imgW, imgH = instance.image:getWidth(), instance.image:getHeight()

  instance.quad = love.graphics.newQuad(0, 0, width, height, imgW, imgH)

  instance.runWidth = math.floor(imgW / width)
  instance.runHeight = math.floor(imgH / height)

  instance.tiles = instance.runWidth * instance.runHeight

  return instance
end

function Tileset:packAttribute(rotation, flip, palette)
  return rotation + bit.lshift(flip, 2) + bit.lshift(palette, 3)
end

function Tileset:unpackAttribute(attribute)
  local rotation = bit.band(attribute, 3)
  local flip = bit.band(bit.rshift(attribute, 2), 1)
  local palette = bit.rshift(attribute, 3)
  return rotation, flip, palette
end

function Tileset:drawTile(tile, pos, attribute)
  local rotation, flip, palette = self:unpackAttribute(attribute)
  self.palette:set(palette)

  if tile < 0 or tile >= self.tiles then
    --error('Tile index ' .. tostring(tile) .. ' outside tileset range of 0 to ' .. tostring(self.tiles - 1) .. '.', 2)
    errorP(2, 'Tile index ', tile, ' outside tileset range of 0 to ', self.tiles - 1, '.')
  end

  --local sx, sy = tile % self.runWidth, math.floor(tile / self.runWidth)
  self.quad:setViewport(
    (tile % self.runWidth) * self.w,
    math.floor(tile / self.runWidth) * self.h,
    self.w,
    self.h
  )

  local halfw = math.floor(self.w / 2)
  local halfh = math.floor(self.h / 2)
  love.graphics.draw(
    self.image,
    self.quad,
    math.floor(pos.x),
    math.floor(pos.y),
    math.rad(90 * rotation),
    1,
    flip == 1 and -1 or 1,
    halfw, halfh
  )

  love.graphics.setShader()
end

function Tileset:setCharacters(str)
  self.characters = init_chars(str)
end

function Tileset:drawString(str, pos, attr, char_width)
  str = tostring(str)
  char_width = char_width or self.char_width or self.w
  local width = self.w / 2
  local height = self.h / 2
  for i = 1, #str do
    local tile = self.characters[str:sub(i, i)]
    if not tile then
      error('attempt to draw character outside charset', 2)
    else
      self:drawTile(tile - 1, pos + Vector:new{(i - 1) * char_width + width, height}, attr)
    end
  end
end

return Tileset
