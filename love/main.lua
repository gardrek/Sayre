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
  local bomb_anim = Map:new(mainTileset, 1, 2, 7)
  local pBlue = mainTileset:packAttribute(0, 0, PALETTE.BLUE)
  local pRed = mainTileset:packAttribute(0, 0, PALETTE.RED)
  bomb_anim:loadString([[
0
2
1
2
7
]] ..
'261,277, ' .. pRed .. ',' .. pBlue .. ',' ..
'262,277, ' .. pRed .. ',' .. pBlue .. ',' ..
'263,277, ' .. pRed .. ',' .. pBlue .. ',' ..
'264,277, ' .. pRed .. ',' .. pBlue .. ',' ..
'265,277, ' .. pRed .. ',' .. pBlue .. ',' ..
'266,277, ' .. pRed .. ',' .. pBlue .. ',' ..
'261,277, ' .. pRed .. ',' .. pBlue .. ',')
  player.tilemap = bomb_anim
  player.tileAnimOffset = 0
  player.update = function(self)
    --Mob.update(self)
    self.tileAnimOffset = (self.tileAnimOffset + 0.125) % 7
    self.tileindex = math.floor(self.tileAnimOffset)
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

function love.keypressed(key, scancode, isrepeat)
  if key == '`' then
    SLOWMO = not SLOWMO
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

  for i, v in ipairs(moblist) do
    v:update()
  end

end

local n = 0

function love.draw()
  n = n + 0.125
  love.graphics.clear(Color.ScreenBorder)

  Screen:renderTo(function()
    if DEBUG_MODE then
      love.graphics.clear(Color.Magenta)
    end

    love.graphics.setColor(Color.FullBright)
    --love.graphics.setShader(paletteset.shader)

    test_map:drawLayer(0, -Camera.pos)

    for i, v in ipairs(moblist) do
      if v.tilemap then
        --v.tilemap:drawLayer(v.tileindex, v.pos)
        v:draw()
      end
    end

    -- draw stuff, at -Camera.pos if appropriate

    --test_map:drawLayerRaw(0, -Camera.pos.x, -Camera.pos.y)
    local pos = Screen:getMousePosition()

    --mouse_mob.pos = pos

    --test_map:drawLayer(1, -Camera.pos)

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
