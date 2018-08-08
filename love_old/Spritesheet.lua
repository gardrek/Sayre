local State = require 'State'

local This = {}
This.class = 'Spritesheet'

function This.__index(table, key)
  local value = rawget(table, key)
  if not value then
    value = rawget(This, key)
  end
  if not value then
    value = rawget(This, key)
  end
  if not value then
    error(
      'Attempt to access non-existant member ' .. key ..
      ' of class ' .. (rawget(This, 'class') or 'UnkownClass'),
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

local defaultchars = init_chars' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'

This.template = {
  characters = defaultchars,
}

function This:new(template)
  template = template or {}
  local instance = {}

  for k, v in pairs(self.template) do
    instance[k] = v
  end

  for k, v in pairs(template) do
    if This[k] then
      error('attempt to overwrite built-in ' .. k .. ' on class' .. This.class, 2)
    end
    instance[k] = v
  end

  setmetatable(instance, This)
  return instance
end

function This.load(filename, width, height)
  local instance = This:new{
    w = width,
    h = height,
  }

  instance.image = love.graphics.newImage(filename)

  local imgW, imgH = instance.image:getWidth(), instance.image:getHeight()

  instance.quad = love.graphics.newQuad(0, 0, width, height, imgW, imgH)

  instance.runWidth = math.floor(imgW / width)
  instance.runHeight = math.floor(imgH / height)

  return instance
end

function This:drawSprite(spr, x, y, rotation, flip)
  rotation = rotation or 0
  flip = flip and -1 or 1
  local sx, sy = spr % self.runWidth, math.floor(spr / self.runWidth)
  self.quad:setViewport(sx * self.w, sy * self.h, self.w, self.h)
  --love.graphics.draw(self.image, self.quad, x, y)
  
  local halfw = self.w / 2
  local halfh = self.h / 2
  love.graphics.draw(self.image, self.quad, x, y, math.rad(90 * rotation), 1, flip, halfw, halfh)
end

function This:drawSpriteRecolor(palette, ...)
  State.paletteShader:send('offset', palette / 0xf)
  love.graphics.setShader(State.paletteShader)
  self:drawSprite(...)
  love.graphics.setShader()
end

function This:drawTile(spr, x, y, attributes)
  local rotation = bit.band(attributes, 3)
  local flip = bit.band(bit.rshift(attributes, 2), 1)
  local palette = bit.rshift(attributes, 3)
  State.paletteShader:send('offset', palette / 0xf)
  love.graphics.setShader(State.paletteShader)
  self:drawSprite(spr, x, y, rotation, flip == 1)
  love.graphics.setShader()
end

function This:setCharacters(str)
  self.characters = init_chars(str)
end

function This:drawString(str, x, y, line_length)
  line_length = line_length or 0
  for i = 1, #str do
    local tile = self.characters[str:sub(i, i)]
    if not tile then error'attempt to draw character outside charset' else
      self:drawSprite(tile - 1, x + (i - 1) * self.w, y)
    end
  end
end

return This
