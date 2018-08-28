---[[
local TICKRATE = 1 / 60
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end

  local previous = love.timer.getTime()
  local lag = 0.0

  -- Main loop time.
  return function()
    -- Process events.
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end

    love.timer.step()
    local current = love.timer.getTime()
    local elapsed = current - previous
    previous = current
    lag = lag + elapsed

    -- Call update and draw

    while lag >= TICKRATE do
      if love.update then love.update(TICKRATE) end
      lag = lag - TICKRATE
    end

    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())

      -- Normalized difference between real time and the last update
      if love.draw then love.draw(lag / TICKRATE) end

      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.001) end
  end
end
--]]


math.randomseed(os.time())
--math.random(); math.random(); math.random(); 

io.stdout:setvbuf('no') -- enable normal use of the print() command
love.graphics.setDefaultFilter('nearest', 'nearest') -- Pixel scaling

require 'Constants'

--------

local player

local test_map = Map:new(mainTileset, 24, 16, 0)

test_map:load'default.room'

test_map.tileOffset = 0x180

--local fontTiny = Tileset:load('tinyfont_outline.png', 5, 8, mainPalette)
--fontTiny.char_width = 4

local test_explosion_palette = Palette:new('explosion_palette.png', 256, 1)

--------

local moblist = Moblist:new{}

function love.load()
  love.audio.setVolume(0.5)

  local input = Input:new()
  input:setPlayer1Binding_TEST()
  player = Mob:newPlayer{
    pos = Vector{12, 8} * 8,
    tilemap = Map:new(mainTileset, 2, 2, 8),
    --tileindex = 0, --math.random(0, 7),
    input = input,
  }
  player.tilemap:loadString[[
0
2
2
2
4
96,97,112,113, 8,14,8,14,
98,98,114,114, 8,14,8,14,
97,96,113,112, 8,14,8,14,
99,99,115,115, 8,14,8,14,
]]
  --local bomb_anim = Map:new(mainTileset, 1, 2, 7)
  local bomb_anim, message = Map:load('bomb.map', 'maps/items/', mainTileset)
  if not bomb_anim then error('map loading error: ' .. tostring(message)) end
  player.tileAnimOffset = 0
  player.update = function(self)
    Mob.update(self)
    --self.tileAnimOffset = (self.tileAnimOffset + 0.125) % self.tilemap.layers
    --self.tileindex = math.floor(self.tileAnimOffset)
  end
  --[[
  for layer = 0, 7 do
    player.tilemap:remap(function(pos, tile, attr)
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
      return t, Tileset:packAttribute(rot, flip, pal)
    end, layer)
  end
  --]]
  moblist:insert(player)

  Screen:update_window()
  Screen:window_size(love.graphics.getWidth(), love.graphics.getHeight())
end

local test_explosion_effect = false

function love.keypressed(key, scancode, isrepeat)
  if key == '`' then
    SLOWMO = not SLOWMO
    if SLOWMO then
      TICKRATE = 1 / 6
    else
      TICKRATE = 1 / 60
    end
  elseif key == 'f5' then
    --Sound.pickup:replay()
    test_explosion_effect = 4
  end
end

function love.update(dt)
  --if SLOWMO then
    --love.timer.sleep(0.1)
  --end

  Camera:update()

  print(inspect(player.input.hold_time))

  --Camera.target = Camera.target + Vector:new{1, 1}

  -- do stuff here

  for i, v in ipairs(moblist) do
    v:update()
  end

end

function love.draw(delta)
  love.graphics.clear(Color.ScreenBorder)

  Screen:renderTo(function()
    if DEBUG_MODE then
      love.graphics.clear(Color.Magenta)
      --love.graphics.clear(Color.Border)
    end

    love.graphics.setColor(Color.FullBright)

    if test_explosion_effect then
      if test_explosion_effect % 3 <= 1 then
        test_explosion_palette:set(0)
      end
      test_explosion_effect = test_explosion_effect - 1
      if test_explosion_effect < 0 then
        test_explosion_effect = false
      end
    end
    test_map:drawRectRaw(0, -Camera.pos, Vector{16, 0}, Vector{10, 10})
    --test_map:drawLayer(0, -Camera.pos)
--print(delta)
    for i, v in ipairs(moblist) do
      if v.tilemap then
        --v.tilemap:drawLayer(v.tileindex, v.pos)
        v:draw( (v.delta_pos or Vector{0, 0}) * (delta - 1) )
      end
    end

    -- draw stuff, at -Camera.pos if appropriate

    --test_map:drawLayerRaw(0, -Camera.pos.x, -Camera.pos.y)
    local pos = Screen:getMousePosition()

    --mouse_mob.pos = pos

    --test_map:drawLayer(1, -Camera.pos)

    Palette:set()
    for i = 1, (test_map.layers - 1) do
      test_map:drawLayer(i, -Camera.pos)-- + Vector{math.random(0, 7), math.random(0, 7)})
    end

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
