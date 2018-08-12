local Tileset = require 'Tileset'
local Color = require 'Color'
local Vector = require 'Vector'

local Map = simpleClass'Map'

--local function pack_index(x, y, z)
  --return x + bit.lshift(y, 8) + bit.lshift(z, 16)
--end

function Map:pack_index(x, y, z)
  if not self:inBounds(x, y, z) then error('index out of bounds', 2) end
  return x + bit.lshift(y, 8) + bit.lshift(z, 16)
end

function Map:inBounds(x, y, z)
  return
    x >= 0 and x < self.width and
    y >= 0 and y < self.height and
    z >= 0 and z < self.layers
end

function Map:new(tileset, width, height, layers)
  width = type(width) == 'number' and width > 0 and width or 1
  height = type(height) == 'number' and height > 0 and height or 1
  layers = type(layers) == 'number' and layers > 0 and layers or 1

  local map = {
    tile = {},
    attributes = {},
    collision = {},
    cache = {},
    tileOffset = 0,
    drawZero = false,
  }

  setmetatable(map, Map)

  map.width = width
  map.height = height
  map.layers = layers

  local i
  for zi = 0, map.layers - 1 do
    for yi = 0, map.height - 1 do
      for xi = 0, map.width - 1 do
        i = map:pack_index(xi, yi, zi)
        map.tile[i] = 0
        map.attributes[i] = 0--tileset:packAttribute(0, 0, 0)
      end
    end
  end

  map:setTileset(tileset)

  return map
end

function Map:dup()
  local map = Map:new(self.tileset, self.width, self.height, self.layers)
  for layer = 1, self.layers - 1 do
    map:remap(function(pos, tile, attr)
      return self:getTile(pos.x, pos.y, layer), self:getAttr(pos.x, pos.y, layer)
    end, layer)
  end
  return map
end

function Map:setTileset(tileset)
  self.tileset = tileset
  self.totalWidth = self.tileset.w * self.width
  self.totalHeight = self.tileset.h * self.height
  for layer = 0, self.layers - 1 do
    self:initCacheLayer(layer)
    --self:markDirty(layer)
    self:updateCacheLayer(layer)
  end
end

function Map:initCacheLayer(layer)
  if layer >= self.layers then error'layer outside of bounds' end
  local cache = {}
  self.cache[layer] = cache
  cache.canvas = love.graphics.newCanvas(self.totalWidth, self.totalHeight)
  cache.image = love.graphics.newImage(cache.canvas:newImageData())
  --cache.clean = false
  self:markDirty(layer)
end

function Map:markDirty(layer)
  self.cache[layer].clean = false
end

function Map:getTile(x, y, z)
  z = z or 0
  return self.tile[self:pack_index(x, y, z)]
end

function Map:setTile(tile, x, y, z)
  z = z or 0
  self.tile[self:pack_index(x, y, z)] = tile
  self:markDirty(z)
end

function Map:getAttr(x, y, z)
  z = z or 0
  return self.attributes[self:pack_index(x, y, z)]
end

function Map:setAttr(attr, x, y, z)
  z = z or 0
  self.attributes[self:pack_index(x, y, z)] = attr
  self:markDirty(z)
end

-- callback function(pos, tile, attr) return new_tile, new_attr end
function Map:remap(func, layer)
  layer = layer or 0
  if layer >= self.layers then error'layer outside of bounds' end
  local i
  local tileset = self.tileset
  local tile, attributes = self.tile, self.attributes
  local tl, attr
  for yi = 0, self.height - 1 do
    for xi = 0, self.width - 1 do
      i = self:pack_index(xi, yi, layer)
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

function Map:arrayRemap(array)
  for zi = 1, #array do
    self:remap(function(pos)
      local layer = array[zi + 1]
      if not layer then return end
      prinspect(layer)
      local row = layer[pos.y + 1]
      if not row then return end
      prinspect(row)
      local tile = row[pos.x + 1]
      if not tile then return end
      prinspect(tile)
      return unpack(tile)
    end, zi)
  end
end

function Map:drawLayer(layer, pos)
  if layer >= self.layers then error'layer outside of bounds' end
  local cache = self.cache[layer]
  if not cache.clean then
    self:updateCacheLayer(layer)
  end
  love.graphics.draw(cache.image, pos.x, pos.y)
end

function Map:drawLayerRaw(layer, pos)
  if layer >= self.layers then error'layer outside of bounds' end
  local dim = Vector:new{self.tileset.w, self.tileset.h}
  pos = pos + dim / 2
  local tile
  for yi = 0, self.height - 1 do
    for xi = 0, self.width - 1 do
      local i = self:pack_index(xi, yi, layer)
      tile = self.tile[i]
      if tile ~= 0 or self.drawZero then
        local tilePos = Vector:new{xi, yi}
        self.tileset:drawTile(
          tile + self.tileOffset,
          pos + tilePos * dim,
          self.attributes[i]
        )
      end
    end
  end
end

function Map:updateCacheLayer(layer)
  if layer >= self.layers then error'layer outside of bounds' end
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
          write_str_comma(self[tile][self:pack_index(xi, yi, zi)])
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

  return self:loadString(data)

  --[===[
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
          self[tile][self:pack_index(xi, yi, zi)] = csv[i]
          i = i + 1
        end
      end
      self:initCacheLayer(zi)
      self:markDirty(zi)
    end
  end

  return true
  --]===]
end

function Map:loadString(data)
  if self == Map then
    self = Map:new()
  end

  if type(data) ~= 'string' then
    error('argument must be a string', 2)
  end

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

  local magic = read_number()
  local version

  if magic == 0 then
    version = read_number()
    self.width = read_number()
  else
    version = 1
    self.width = magic
  end

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
  local function read_layer(layer, type)
    for yi = 0, self.height - 1 do
      for xi = 0, self.width - 1 do
        self[type][self:pack_index(xi, yi, layer)] = csv[i]
        i = i + 1
      end
    end
    self:initCacheLayer(layer)
    self:markDirty(layer)
  end

  if version == 1 then
    for _, type in ipairs{'tile', 'attributes'} do
      for layer = 0, self.layers - 1 do
        read_layer(layer, type)
      end
    end
  else
    for layer = 0, self.layers - 1 do
      for _, type in ipairs{'tile', 'attributes'} do
        read_layer(layer, type)
      end
    end
  end

  return self
end

return Map
