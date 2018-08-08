local Subscreen = {}
Subscreen.__index = Subscreen

local statusbar_image = love.graphics.newImage'statusbar.png'

local Color = require 'Color'
local Vector = require 'Vector'
local Sound = require 'Sound'
local State = require 'State'
local Map = require 'Map'

function Subscreen:new(player)
  local sub = {
    counter = {
      health = 0,
      money = 0,
    },
    player = player,
  }

  setmetatable(sub, Subscreen)
  return sub
end

function Subscreen:draw_hearts(x, y)
  local tile
  local health = self.counter.health or self.player.health
  for i = 0, self.player.hearts - 1 do
    if health >= (i + 1) * HEART_VALUE then
      tile = TILE.HEART_FULL
    elseif health < i * HEART_VALUE then
      tile = TILE.HEART
    else
      tile = TILE.HEART + math.ceil((health % HEART_VALUE) / 4)
    end
    sprites:drawSpriteRecolor(PALETTE.RED, TILE.HEART, x + 8 * (i % 8), y - 8 * math.floor(i / 8), 0)
    sprites:drawSpriteRecolor(PALETTE.RED, tile, x + 8 * (i % 8), y - 8 * math.floor(i / 8), 0)
  end
end

function Subscreen:update()
  if self.counter.health then
    self.counter.health = math.max(-self.player.hearts * HEART_VALUE, math.min(self.counter.health, self.player.hearts * HEART_VALUE))
    if self.player.health - self.counter.health > 0 then
      self.counter.health = self.counter.health + 1
      if self.counter.health % math.floor(HEART_VALUE / 2) == 0 then Sound.heart:replay() end
    elseif self.player.health - self.counter.health < 0 then
      self.counter.health = self.counter.health - 1
    end
  end

  if self.counter.money and self.player.inventory.ammo.knife then
    local money = self.player.inventory.ammo.knife
    if money - self.counter.money > 0 then
      self.counter.money = self.counter.money + 1
      Sound.pickup:replay()
    elseif money - self.counter.money < 0 then
      self.counter.money = money
      --self.counter.money = self.counter.money - 1
      --if self.counter.money % 2 == 0 then Sound.pickup:replay() end
    end
  end
end

function Subscreen:draw_status_bar(x, y)
  love.graphics.setColor(Color.FullBright)
  State:setPalette(0)
  love.graphics.draw(statusbar_image, x, y)

  local spacing = 2
  local offset = 0.25
  for i, name in pairs{'left_hand', 'right_hand', 'left_reserve', 'right_reserve'} do
    local item = self.player.inventory.equipment[name]
    love.graphics.setColor(Color.FullBright)
    sprites:drawSpriteRecolor(0, TILE.BRACKETS, x + ((i - 1) * spacing + offset + 0.25) * TILESIZE, y + 1 * TILESIZE)
    sprites:drawSpriteRecolor(0, TILE.BUTTON_LETTERS + i - 1, x + ((i - 1) * spacing + offset) * TILESIZE, y + 1 * TILESIZE)
    sprites:drawSpriteRecolor(0, TILE.BRACKETS + 1, x + ((i - 1) * spacing + offset + 1.25) * TILESIZE, y + 1 * TILESIZE)
    if item then
      item:draw_icon(sprites, x + ((i - 1) * spacing + offset + 0.75) * TILESIZE, y + 1 * TILESIZE)
      State:setPalette'RED'
      if item.has_count then
        love.graphics.setColor(Color.FullBright)
        local number = self.player.inventory.ammo[item.name]
        if number then
          local s
          if number < 1 then
            s = 'x'
          elseif number == 1 then
            s = ''
          else
            s = string.format("%02u", math.floor(number)):sub(-3)
          end
          numerals8x8:drawString(
            s,
            x + ((i - 1) * spacing + offset + 1 - #s / 4) * TILESIZE,
            y + 1.75 * TILESIZE
          )
        end
      end
    end
  end

  love.graphics.setColor(Color.FullBright)
  self:draw_hearts(x + 8.25 * TILESIZE, y + 1.75 * TILESIZE)

  love.graphics.setColor(Color.Black)

  if self.player.floor then
    numerals8x8:drawString(
      string.format("%02u", self.player.floor):sub(-3),
      x + 9.0 * TILESIZE,
      y + 0.5 * TILESIZE
    )
  end
end

local function draw_selector(palette, pos, dim)
  local cx, cy = pos.x, pos.y
  local width, height = dim.x / 2, dim.y / 2
  sprites:drawSpriteRecolor(palette, TILE.EDIT + 1, cx - width, cy - height)
  sprites:drawSpriteRecolor(palette, TILE.EDIT + 1, cx + width, cy - height, 1)
  sprites:drawSpriteRecolor(palette, TILE.EDIT + 1, cx + width, cy + height, 2)
  sprites:drawSpriteRecolor(palette, TILE.EDIT + 1, cx - width, cy + height, 3)
end

function Subscreen:draw_edit_ui(x, y)
  love.graphics.setColor(Color.FullBright)

  local palette = PALETTE.RED

  local mouse = Game:getMousePosition()

  local edit = self.player.edit

  if edit.brush.size > 1 then
    draw_selector(palette, ((mouse / 8):each(math.floor) + 0.5 + Vector:new{0.5, 0.5} * (1 - (edit.brush.size % 2))) * 8, Vector:new{edit.brush.size, edit.brush.size} * 8)
  end

  State:setPalette(0)
  love.graphics.draw(statusbar_image, x, y)
  local half = TILESIZE / 2
  sprites:drawSpriteRecolor(0, TILE.EDIT, x + half, y + half)

  local spacing = 2
  local offset = 0.25
  for i = 1, 1 do
    sprites:drawSpriteRecolor(0, TILE.BRACKETS, x + ((i - 1) * spacing + offset + 0.25) * TILESIZE, y + 1 * TILESIZE)
    sprites:drawSpriteRecolor(0, TILE.BUTTON_LETTERS + 4, x + ((i - 1) * spacing + offset) * TILESIZE, y + 1 * TILESIZE)
    sprites:drawSpriteRecolor(0, TILE.BRACKETS + 1, x + ((i - 1) * spacing + offset + 1.25) * TILESIZE, y + 1 * TILESIZE)

    love.graphics.setColor(Color.Magenta)
    love.graphics.rectangle(
      'fill',
      x + ((i - 1) * spacing + offset + 0.5) * TILESIZE, y + 0.75 * TILESIZE,
      8, 8
    )

    love.graphics.setColor(Color.FullBright)

    maptiles:drawTile(
      edit.current_tile,
      x + ((i - 1) * spacing + offset + 0.75) * TILESIZE, y + 1 * TILESIZE,
      edit.current_attr
    )

    local rotation, flip, palette = Map:unpack_attribute(edit.current_attr)
    sprites:drawTile(
      TILE.EDIT + 3,
      x + ((i - 1) * spacing + offset + 0.00) * TILESIZE, y + 1.75 * TILESIZE,
      Map:pack_attribute(rotation, flip, 0)
    )
    sprites:drawTile(
      TILE.EDIT + 4,
      x + ((i - 1) * spacing + offset + 1.00) * TILESIZE, y + 1.75 * TILESIZE,
      Map:pack_attribute(0, 0, palette)
    )
  end

  --sprites:drawSpriteRecolor(palette, TILE.EDIT + 2, mouse.x + half, mouse.y + half)
end

return Subscreen
