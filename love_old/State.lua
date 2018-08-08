local State = {}

local states = {
  'play',
  'pause',
  'changescreen',
  'edit',
}

for _, name in pairs(states) do
  State[name] = function(self, info)
    return self:changeState(name, info)
  end
end

do
  State.paletteShader = love.graphics.newShader--[[
    extern Image palettes;
    extern number offset;

    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      //vec4 pixel0 = Texel(palettes, texture_coords );//This is the current pixel color
      //vec4 pixel1 = Texel(texture, texture_coords );//This is the current pixel color
      //return pixel0 * pixel1 * color;

      vec4 outColor = Texel(texture, texture_coords);
      //if (_AlphaSplitEnabled)
      //  outColor.a = Texel(_AlphaTex, uv).r;

      //outColor.rgb *= outColor.a;

      vec4 swapCol = Texel(palettes, vec2(outColor.r, offset));
      vec4 final = swapCol;//lerp(outColor, swapCol, swapCol.a) * color;
      final.a = outColor.a;
      return final;
    }
  ]]
  [[
    extern Image palettes;
    extern number offset;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      //vec4 pixel0 = Texel(palettes, texture_coords );//This is the current pixel color
      //vec4 pixel1 = Texel(texture, texture_coords );//This is the current pixel color
      //return pixel0 * pixel1 * color;

      vec4 outColor = Texel(texture, texture_coords);
      //if (_AlphaSplitEnabled)
      //  outColor.a = Texel(_AlphaTex, uv).r;

      //outColor.rgb *= outColor.a;

      vec4 swapCol = Texel(palettes, vec2(outColor.r, offset));
      vec4 final = swapCol;//lerp(outColor, swapCol, swapCol.a) * color;
      final.a = outColor.a;
      return final;
    }
  ]]

  local palettes = love.graphics.newImage'palettes.png'

  State.paletteShader:send('palettes', palettes)
  State.paletteShader:send('offset', 0)
end

function State:setPalette(index)
  if type(index) ~= 'number' then
    index = PALETTE[index]
  end
  love.graphics.setShader(self.paletteShader)
  self.paletteShader:send('offset', index * 0x11 / 0xff)
end

State.music = love.audio.newSource('Zelda_-_Dark_Piano.mp3', 'static')

State.music:setVolume(0.5)
State.music:setLooping(true)

function State:changeState(state, info)
  if state == self.state then return end

  if love.mouse.isCursorSupported() then
    if state ~= 'edit' then
      love.mouse.setCursor()
    else
      love.mouse.setCursor(mouse_cursor_red)
    end
  end

  if state == 'changescreen' then
    if self.state == 'play' then
      self.timer_max = 60
      self.timer = self.timer_max
    elseif self.state == 'edit' then
      self.timer_max = 1
      self.timer = self.timer_max
    else
      error''
    end
  elseif state == 'pause' or state == 'edit' then
    self.music:pause()
  elseif state == 'play' then
    self.music:play()
  end

  self.info = info
  self.previous_state = self.state
  self.state = state
end

function State:previous()
  self:changeState(self.previous_state)
end

State:play()

State.music:setVolume(0.1)

return State
