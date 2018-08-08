local Color = require 'Color'

local Map = {}
Map.__index = Map

local function pack_index(x, y, z)
  return x + bit.lshift(y, 8) + bit.lshift(z, 16)
end

function Map:pack_attribute(rotation, flip, palette)
  return rotation + bit.lshift(flip, 2) + bit.lshift(palette, 3)
end

function Map:unpack_attribute(attribute)
  local rotation = bit.band(attribute, 3)
  local flip = bit.band(bit.rshift(attribute, 2), 1)
  local palette = bit.rshift(attribute, 3)
  return rotation, flip, palette
end

--local function make_attributes(t)
  --local palette = t.palette or 0
  --local rotation = t.rotation or 0
  --local flip = t.flip or false
--end

function Map:new(tileset)
  local map = {
    tileset = tileset,
    tile = {},
    attributes = {},
    collision = {},
    cache = {},
  }

  setmetatable(map, Map)

  map.width = 24
  map.height = 16
  map.layers = 2

  for zi = 0, map.layers - 1 do
    for yi = 0, map.height - 1 do
      for xi = 0, map.width - 1 do
        local i = pack_index(xi, yi, zi)
        local m = (xi + yi) % 2
        local n = (xi * 2 + yi * 2) % 2
        local qqq = xi + yi * 8
        if zi == 0 then
          map.tile[i] = m + 4
          --if xi < 8 and yi < 8 then
            --map.tile[i] = xi + yi * 8
          --else
            --map.tile[i] = 2
          --end
        else
          map.tile[i] = 0--6--n + 6--m == 1 and 7 or 0
        end
        map.attributes[i] = Map:pack_attribute(0, 0, 0) -- rotation, flip, palette
      end
    end
  end

  local imageW = map.tileset.w * map.width
  local imageH = map.tileset.h * map.height

  for layer = 0, map.layers - 1 do
    local cache = {}
    map.cache[layer] = cache
    cache.canvas = love.graphics.newCanvas(imageW, imageH)
    cache.image = love.graphics.newImage(cache.canvas:newImageData())
    map:updateCacheLayer(layer)
  end

  love.graphics.newCanvas(1, 1):renderTo(function()
    for layer = 0, map.layers - 1 do
      map:drawLayer(layer, 0, 0)
    end
  end)

  return map
end

function Map:getTile(x, y, z)
  z = z or 0
  return self.tile[pack_index(x, y, z)]
end

function Map:setTile(tile, x, y, z)
  z = z or 0
  self.tile[pack_index(x, y, z)] = tile
  self.cache[z].clean = false
end

function Map:rotate(attr, rotation)
  local r, f, p = Map:unpack_attribute(attr)
  return Map:pack_attribute((r + rotation) % 4, f, p)
end

function Map:flip(attr)
  local r, f, p = Map:unpack_attribute(attr)
  return Map:pack_attribute(r, 1 - f, p)
end

function Map:resetRotationAndFlip(attr)
  local _r, _f, p = Map:unpack_attribute(attr)
  return Map:pack_attribute(0, 0, p)
end

function Map:recolor(attr, palette)
  local r, f, _p = Map:unpack_attribute(attr)
  return Map:pack_attribute(r, f, palette)
end

function Map:getAttr(x, y, z)
  z = z or 0
  return self.attributes[pack_index(x, y, z)]
end

function Map:setAttr(attr, x, y, z)
  z = z or 0
  self.attributes[pack_index(x, y, z)] = attr
  self.cache[z].clean = false
end

function Map:drawLayer(layer, x, y)
  local cache = self.cache[layer]
  if not cache.clean then
    self:updateCacheLayer(layer)
  end
  love.graphics.draw(cache.image, x, y)
end

function Map:drawLayerRaw(layer, x, y)
  local w, h = self.tileset.w, self.tileset.h
  x = x + w / 2
  y = y + h / 2
  for yi = 0, self.height - 1 do
    for xi = 0, self.width - 1 do
      local i = pack_index(xi, yi, layer)
      self.tileset:drawTile(
        self.tile[i],
        --8,
        x + xi * w, y + yi * h,
        --0, false, 0
        self.attributes[i]
        --0
      )
    end
  end
end

function Map:drawLayerTest(layer, x, y, tile)
  local w, h = self.tileset.w, self.tileset.h
  x = x + w / 2
  y = y + h / 2
  for yi = 0, self.height - 1 do
    for xi = 0, self.width - 1 do
      local i = pack_index(xi, yi, layer)
      self.tileset:drawTile(
        tile or self.tile[i],
        --8,
        x + xi * w, y + yi * h,
        --0, false, 0
        Map:resetRotationAndFlip(self.attributes[i])
        --0
      )
    end
  end
end

function Map:updateCacheLayer(layer)
  --local imageW = self.tileset.w * self.width
  --local imageH = self.tileset.h * self.height
  --local canvas = love.graphics.newCanvas(imageW, imageH)

  local cache = self.cache[layer]

  cache.canvas:renderTo(function()
    love.graphics.clear(Color.Blank)
    --if layer == 0 then
      --self:drawLayerTest(layer, 0, 0, 14)
    --end
    self:drawLayerRaw(layer, 0, 0)
  end)

  --cache.image = love.graphics.newImage(cache.canvas:newImageData())
  cache.image = cache.canvas
  cache.clean = true
end

function Map:save(filename, overwrite_protect)
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

  for _, v in ipairs{self.width, self.height, self.layers} do
    --print(v, type(v))
  end

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
      --i = i + 1
      line = read_csv_line()
    end
  end

  for i, v in ipairs(csv) do
    --print(i, v, type(v))
  end

  local i = 1
  for _, tile in ipairs{'tile', 'attributes'} do
    for zi = 0, self.layers - 1 do
      for yi = 0, self.height - 1 do
        for xi = 0, self.width - 1 do
          self[tile][pack_index(xi, yi, zi)] = csv[i]
          i = i + 1
        end
      end
      self.cache[zi].clean = false
      --self:updateCacheLayer(zi)
    end
  end

  --[[

  write_n(self.width)
  write_n(self.height)
  write_n(self.layers)

  --for _, tile in ipairs{self.tile, self.attributes} do
  for _, tile in ipairs{'tile', 'attributes'} do
    write_n(tile)
    for zi = 0, self.layers - 1 do
      write_n('layer' .. tostring(zi))
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
  --]]

  return true
end

return Map
