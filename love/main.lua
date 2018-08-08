math.randomseed(os.time())
--math.random(); math.random(); math.random(); 

io.stdout:setvbuf('no') -- enable normal use of the print() command
love.graphics.setDefaultFilter('nearest', 'nearest') -- Pixel scaling

require 'Constants'

--------

local test_map = Map:new(mapTileset)--, 64, 64)

test_map:load'default.room'

--local test_map = Map:load'default.room'
--test_map.tileset = mapTileset


function Map:randomizeLayer(layer)
  layer = layer or 0
  self:remap(function(pos, tile, attr)
    return
      math.random(1, 31),--(0, self.tileset.tiles - 1),
      self.tileset:packAttribute(
        math.random(0, 3),
        math.random(0, 1),
        math.random(0, 7)--self.tileset.palette.count - 1)
      )
  end, layer)
end

--test_map:randomizeLayer()

test_map:remap(function(pos, tile, attr)
  local rot, flip, pal = test_map.tileset:unpackAttribute(attr)
  return
    nil,--math.random(1, 31),--(0, self.tileset.tiles - 1),
    test_map.tileset:packAttribute(
      rot,--math.random(0, 3),
      flip,--math.random(0, 1),
      math.random(0, 9)--self.tileset.palette.count - 1)
    )
end, 0)

local fontTiny = Tileset:load('tinyfont_outline.png', 5, 8, mainPalette)
fontTiny.char_width = 4

--------

local sprites_as_maps = {}
local mouse_mob

function love.load()
  love.audio.setVolume(0.5)

  for xi = 0, -11 do
  for yi = 0, -7 do
    local mob = {
      pos = Vector{xi, yi} * 16,
      map = Map:new(mapTileset, 2, 2, 8),
      layer = math.random(0, 7),
    }
    for layer = 0, 7 do
      mob.map:remap(function(pos, tile, attr)
        return
          math.random(6 * 8, 63),
          mob.map.tileset:packAttribute(
            math.random(0, 3),
            math.random(0, 1),
            math.random(0, 7)
          )
      end, layer)
    end
    table.insert(sprites_as_maps, mob)
  end
  end

  --for i = 1, 64 do
    --local mob = {
      --pos = Vector{math.random(1 * 16, 10 * 16), math.random(1 * 16, 6 * 16)},
      --map = Map:new(mapTileset, 2, 2, 8),
      --layer = math.random(0, 7),
    --}
    --for layer = 0, 7 do
      --mob.map:remap(function(pos, tile, attr)
        --return
          --math.random(6 * 8, 63),
          --mob.map.tileset:packAttribute(
            --math.random(0, 3),
            --math.random(0, 1),
            --math.random(0, 7)
          --)
      --end, layer)
    --end
    --table.insert(sprites_as_maps, mob)
  --end


  local mob = {
    pos = Vector{0, 0},
    map = Map:new(mapTileset, 2, 2, 8),
    layer = math.random(0, 7),
  }
  for layer = 0, 7 do
    mob.map:remap(function(pos, tile, attr)
      local t, rot, flip, pal = 0, 0, 0, 0
      if pos.x == 0 then
        t = (6 + pos.y) * 8 + 1
      else
        t = (6 + pos.y) * 8 + 1
        rot = 2
      end
      flip = pos.x
      if pos.y == 0 then
        pal = 7
      else
        pal = layer
      end
      return t, mob.map.tileset:packAttribute(rot, flip, pal)
    end, layer)
  end
  mouse_mob = mob
  table.insert(sprites_as_maps, mob)

  Screen:update_window()
  Screen:window_size(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.keypressed(key, scancode, isrepeat)
  if key == '`' then
    SLOWMO = not SLOWMO
  --elseif key == 'f5' then
  elseif key == 'f5' then
    Sound.pickup:replay()
  end
end

local function sleep(n)
  local t = os.clock()
  while os.clock() - t <= n do end
end

function love.update(dt)
  if SLOWMO then
    sleep(0.1)
  end

  Camera:update()

  --Camera.target = Camera.target + Vector:new{1, 1}

  -- do stuff here
end

function love.draw()
  love.graphics.clear(Color.ScreenBorder)

  Screen:renderTo(function()
    love.graphics.clear(Color.Magenta)

    love.graphics.setColor(Color.FullBright)
    --love.graphics.setShader(paletteset.shader)

    test_map:drawLayer(0, -Camera.pos)

    for i, v in ipairs(sprites_as_maps) do
      v.map:drawLayer(v.layer, v.pos)
    end

    -- draw stuff, at -Camera.pos if appropriate

    --test_map:drawLayerRaw(0, -Camera.pos.x, -Camera.pos.y)
    local pos = Screen:getMousePosition()

    mouse_mob.pos = pos

    test_map:drawLayer(1, -Camera.pos)

    love.graphics.setShader()
  end)

  love.graphics.setColor(Color.FullBright)
  love.graphics.draw(Screen.canvas, Screen.x, Screen.y, 0, Screen.scale, Screen.scale)

  if DEBUG_MODE then
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    --etc
  end
end

function love.resize(w, h)
  Screen:window_size(w, h)
end

function love.quit()
  local cancel = false
  --print(current_map:save'autosave.room')
  return cancel
end
