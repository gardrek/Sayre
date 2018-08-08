local Tileset = require 'Tileset'
local Color = require 'Color'
local Vector = require 'Vector'

local Map = {}
Map.__index = Map

local function pack_index(x, y, z)
  return x + bit.lshift(y, 8) + bit.lshift(z, 16)
end

function Map:new(tileset, width, height, layers)
  width = type(width) == 'number' and width > 0 and width or 1
  height = type(height) == 'number' and height > 0 and height or 1
  layers = type(layers) == 'number' and layers > 0 and layers or 1

  local map = {
    --tileset = tileset,
    tile = {},
    attributes = {},
    collision = {},
    cache = {},
  }

  setmetatable(map, Map)

  map.width = width
  map.height = height
  map.layers = layers

  local i
  for zi = 0, map.layers - 1 do
    for yi = 0, map.height - 1 do
      for xi = 0, map.width - 1 do
        i = pack_index(xi, yi, zi)
        map.tile[i] = 0
        map.attributes[i] = 0--tileset:packAttribute(0, 0, 0)
      end
    end
  end

  map:setTileset(tileset)

  return map
end

function Map:setTileset(tileset)
  self.tileset = tileset
  for layer = 0, self.layers - 1 do
    self:initCacheLayer(layer)
    self:markDirty(layer)
    self:updateCacheLayer(layer)
  end
end

function Map:initCacheLayer(layer)
  local imageW = self.tileset.w * self.width
  local imageH = self.tileset.h * self.height
  local cache = {}
  self.cache[layer] = cache
  cache.canvas = love.graphics.newCanvas(imageW, imageH)
  cache.image = love.graphics.newImage(cache.canvas:newImageData())
  cache.clean = false
  self:markDirty(layer)
end

function Map:markDirty(layer)
  self.cache[layer].clean = false
end

function Map:getTile(x, y, z)
  z = z or 0
  return self.tile[pack_index(x, y, z)]
end

function Map:setTile(tile, x, y, z)
  z = z or 0
  self.tile[pack_index(x, y, z)] = tile
  self:markDirty(z)
end

function Map:getAttr(x, y, z)
  z = z or 0
  return self.attributes[pack_index(x, y, z)]
end

function Map:setAttr(attr, x, y, z)
  z = z or 0
  self.attributes[pack_index(x, y, z)] = attr
  self:markDirty(z)
end

function Map:remap(func, layer)
  layer = layer or 0
  local i
  local tileset = self.tileset
  local tile, attributes = self.tile, self.attributes
  local tl, attr
  for yi = 0, self.height - 1 do
    for xi = 0, self.width - 1 do
      i = pack_index(xi, yi, layer)
      tl, attr = func(Vector{xi, yi}, tile[i], attributes[i])
      if tl then
        tile[i] = tl
      end
      if attr then
        attributes[i] = attr
      end
    end
  end
  self:markDirty(layer)
end

function Map:drawLayer(layer, pos)
  local cache = self.cache[layer]
  if not cache.clean then
    self:updateCacheLayer(layer)
  end
  love.graphics.draw(cache.image, pos.x, pos.y)
end

function Map:drawLayerRaw(layer, pos)
  local dim = Vector:new{self.tileset.w, self.tileset.h}
  pos = pos + dim / 2
  for yi = 0, self.height - 1 do
    for xi = 0, self.width - 1 do
      local i = pack_index(xi, yi, layer)
      local tilePos = Vector:new{xi, yi}
      self.tileset:drawTile(
        self.tile[i],
        pos + tilePos * dim,
        self.attributes[i]
      )
    end
  end
end

function Map:updateCacheLayer(layer)
  local cache = self.cache[layer]

  cache.canvas:renderTo(function()
    love.graphics.clear(Color.Blank)
    self:drawLayerRaw(layer, Vector:new{0, 0})
  end)

  cache.image = love.graphics.newImage(cache.canvas:newImageData())
  --cache.image = cache.canvas -- NOTE: not sure why this is here
  cache.clean = true
end

function Map:save(filename, overwrite_protect)
  error'no map saving yet'
  if type(filename) ~= 'string' then
    error''
  end

  local mapdir = 'save/'

  local info = love.filesystem.getInfo(mapdir)
  if info then
    if info.type ~= 'directory' then
      error''
    end
  else
    love.filesystem.createDirectory(mapdir)
  end

  local fullpath = mapdir .. filename

  local info = love.filesystem.getInfo(fullpath)
  if info then
    if info.type == 'file' then
      if overwrite_protect then
        error''
      end
    else
      error''
    end
  end

  local data = ''

  local function write(n)
    data = data .. n
  end

  local function write_str(n)
    write(tostring(n))
  end

  local function write_n(n)
    write(tostring(n) .. '\n')
  end

  local function write_str_comma(n)
    write(tostring(n) .. ',')
  end

  write_n(self.width)
  write_n(self.height)
  write_n(self.layers)

  --for _, tile in ipairs{self.tile, self.attributes} do
  for _, tile in ipairs{'tile', 'attributes'} do
    --write_n(tile)
    for zi = 0, self.layers - 1 do
      --write_n('layer' .. tostring(zi))
      for yi = 0, self.height - 1 do
        for xi = 0, self.width - 1 do
          --write_str_comma(tile[pack_index(xi, yi, zi)])
          write_str_comma(self[tile][pack_index(xi, yi, zi)])
        end
        write'\n'
      end
      write'\n'
    end
    write'\n'
  end

  write_n'EOF'

  --print(data)

  return love.filesystem.write(fullpath, data)
end

function Map:load(filename, mapdir)
  if self == Map then
    self = Map:new()
  end
  if type(filename) ~= 'string' then
    error('filename is not a string', 2)
  end

  mapdir = mapdir or 'maps/'

  local info = love.filesystem.getInfo(mapdir)
  if not (info and info.type == 'directory') then
    return false, 'directory does not exist'
  end

  local fullpath = mapdir .. filename

  local info = love.filesystem.getInfo(fullpath)
  if not (info and info.type == 'file') then
    return false, 'map file does not exist'
  end

  local data = love.filesystem.read(fullpath)

  if not data then error'' end

  local lines = {}

  for s in data:gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end

  data = nil

  local line_index = 1

  local function read_number()
    local line = lines[line_index]
    local n = tonumber(line)
    line_index = line_index + 1
    return n
  end

  local function read_csv_line()
    local line = lines[line_index]
    if not line then return end
    local numbers = {}
    for s in line:gmatch("[^,]+") do
      table.insert(numbers, s)
    end
    line_index = line_index + 1
    if #numbers > 0 then
      return numbers
    end
  end

  for i, v in ipairs(lines) do
    --print(i, v)
  end

  self.width = read_number()
  self.height = read_number()
  self.layers = read_number()

  --for _, v in ipairs{self.width, self.height, self.layers} do
    --print(v, type(v))
  --end

  local csv = {}
  do
    local i = 1
    local number
    local line = read_csv_line()

    while line do
      for _, v in ipairs(line) do
        if v == 'EOF' then break end
        number = tonumber(v)
        if number then
          csv[i] = number
          i = i + 1
        else
          print(v, type(v))
        end
      end
      line = read_csv_line()
    end
  end

  --for i, v in ipairs(csv) do
    --print(i, v, type(v))
  --end

  local i = 1
  for _, tile in ipairs{'tile', 'attributes'} do
    for zi = 0, self.layers - 1 do
      for yi = 0, self.height - 1 do
        for xi = 0, self.width - 1 do
          self[tile][pack_index(xi, yi, zi)] = csv[i]
          i = i + 1
        end
      end
      self:initCacheLayer(zi)
      self:markDirty(zi)
    end
  end

  return true
end

return Map
