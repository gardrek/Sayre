local Palette = {}
Palette.__index = Palette

function Palette:new(filename, size, count)
  local instance = {}

  instance.shader = love.graphics.newShader[[
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

  instance.image = love.graphics.newImage(filename)

  instance.shader:send('palettes', instance.image)
  instance.shader:send('offset', 0)

  instance.size = size
  instance.count = count

  setmetatable(instance, Palette)

  return instance
end

function Palette:set(i)
  if i then
    self.shader:send('offset', i / (self.count - 1))
    love.graphics.setShader(self.shader)
  else
    love.graphics.setShader()
  end
end

return Palette
