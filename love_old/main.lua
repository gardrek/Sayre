require 'noglobals'

math.randomseed(os.time())
--math.random(); math.random(); math.random(); 


io.stdout:setvbuf('no') -- enable normal use of the print() command
love.graphics.setDefaultFilter('nearest', 'nearest') -- Pixel scaling

require 'Constants' -- global setting

local Vector = require 'Vector'
local Color = require 'Color'

local Mob = require 'Mob'
local Enemy = require 'Enemy'
local Inventory = require 'Inventory'
local Item = require 'Item'
local Drop = require 'Drop'
local Sound = require 'Sound'
local Map = require 'Map'
local State = require 'State'

local Subscreen = require 'Subscreen'

local Spritesheet = require 'Spritesheet'

--local sort = table.sort
local sort = require 'shellsort'
--local sort = require 'quicksort'

do
  local Game = {
    x = 0,
    y = 0,
    scale = 3,
    width = 192,
    height = 160,
  }

  rawset(_G, 'Game', Game)
end

Game.screen = love.graphics.newCanvas(Game.width, Game.height)

--Game.screen:setFilter('linear', 'linear')
--Game.screen2 = love.graphics.newCanvas(64, 64)

---- 4 game-pixel wide border (8 total, 4 on each side)
--Game.minw = math.floor(Game.width / 8 + 1) * 8
--Game.minh = math.floor(Game.height / 8 + 1) * 8

-- 8 game-pixel wide border (16 total, 8 on each side)
Game.minw = math.floor(Game.width / 8 + 2) * 8
Game.minh = math.floor(Game.height / 8 + 2) * 8

-- no border
--Game.minw = Game.width
--Game.minh = Game.height

Game.center = Vector:new{
  math.floor(love.graphics.getWidth() / 2),
  math.floor(love.graphics.getHeight() / 2),
}

function Game:getMousePosition()
  local pos = Vector:new{self.x, self.y}
  local rawMouse = Vector:new{love.mouse.getPosition()}
  return (rawMouse - pos) / self.scale
end

--------

local pause_image = love.graphics.newImage'pause.png'

local DEBUG_MODE = true
local DRAW_HITBOXES = false
local AI_ENABLE = false

local Camera = {
  pos = Vector:new{0, 0},
  target = Vector:new{0, 0},
  offset = Vector:new{1 / 32, 1 / 32},
}

local function ease(x, tx, drag, min)
  drag = drag or 8
  min = min or 0.001
  local dx = (tx - x) / drag
  if math.abs(dx:mag()) < min then
    return tx
  else
    return x + dx
  end
end

function Camera:update()
  --self.pos = self.pos + (self.target - self.pos)
  self.pos = ease(self.pos, self.target + self.offset) - self.offset
end

local current_map = Map:new(maptiles)

do
  local success, msg = current_map:load('autosave.room', 'save/')
  if not success then
    print('map autoload unsuccessful:', msg)
    current_map = Map:new(maptiles)
    local success, msg = current_map:load('default.room', 'maps/')
    if not success then
      print('map autoload unsuccessful:', msg)
      current_map = Map:new(maptiles)
    end
  end
end

local moblist = {}

local player = Mob:new{
  name = 'player',
  team = 'player',
  hearts = 3,
  counter = {
    health = 0,
  },
--  damage_resistance = 0.125,
  floor = 0,
  dir = 1,
  take_damage_sound = Sound.player_hit,
  pos = Vector:new{6 * TILESIZE, 6 * TILESIZE},
  human = 1,
  speed = 1,
  sprite = TILE.PLAYER,
  palette = PALETTE.GREEN,
  invuln_palette = 14,
  rotation_type = 'add',
  projectile_cooldown = 0,
  anim = {
    timer = 0,
    state = 'walk',
    tile_offset = 0,
    start = true,

    states = {
      walk = {
        timer = 0,
        tick = function(self)
          if self.input.left == 1 or self.input.right == 1 or self.input.up == 1 or self.input.down == 1 then
            if self.anim.timer % 20 < 10 then
              self.anim.tile_offset = TILE.ANIM.STEP
            else
              self.anim.tile_offset = 0
            end
          else
            self.anim.timer = 10
            self.anim.tile_offset = 0
          end
        end,
      },
      attack = {
        timer = 12,
        tick = function(self)
          self.anim.tile_offset = TILE.ANIM.ATTACK
        end,
        finish = function(self)
          self:start_state'walk'
        end,
      },
      invuln = {
        timer = 32,
        finish = function(self)
          self:start_state'walk'
        end,
      },
    },
  },
  collision = {
    tags = {
      body = true,
    },
    hitbox = 10,
    onhit = function(self, other)
      if other.mob.team == 'item' then
        if other.tags.pickup then
          other.tags.pickup(other.mob, self.mob)
        end
      end
    end,
    screenborder_timer = 0,
    on_hit_env = function(self, hit, hitdir)
      if self.mob.input[dir_name[hitdir]] == 1 then
        self.screenborder_timer = self.screenborder_timer + 1
        if self.screenborder_timer > 8 then
          State:changescreen{hitdir}
          self.screenborder_timer = 0
        end
      end
    end,
  },
  inventory = Inventory:new(),
  edit = {
    tools = {
      'multi',
      'palette_painter',
    },
    tool = 'multi',
    current_tile = 0,
    current_attr = 0,
    current_layer = 0,
    brush = {
      size = 1,
    },
  },
}

player.subscreen = Subscreen:new(player)

function player:update()
  Mob.update(self)
  local n = 0
  if self.state == 'walk' then
    if self.input.use_left == 1 and self.input_last_frame.use_left == 0 then
      self:use_item(self.inventory.equipment.left_hand, 'left')
    elseif self.input.use_right == 1 and self.input_last_frame.use_right == 0 then
      self:use_item(self.inventory.equipment.right_hand, 'right')
    elseif self.input.use_left_reserve == 1 and self.input_last_frame.use_left_reserve == 0 then
      self:use_item(self.inventory.equipment.left_reserve, 'left')
    elseif self.input.use_right_reserve == 1 and self.input_last_frame.use_right_reserve == 0 then
      self:use_item(self.inventory.equipment.right_reserve, 'right')
    end
  elseif self.state == 'attack' then
  end
  
  --print(self.projectile_cooldown)
end

function player:use_item(item, hand)
  if hand ~= 'left' and hand ~= 'right' then
    error('unkown hand ' .. tostring(hand), 2)
  end
  if item then
    local mob = item:use(self, hand)
    if mob then
      if mob.class == 'Mob' then
        moblist:insert(mob)
      else
        for i, m in ipairs(mob) do
          moblist:insert(m)
        end
      end
    end
  end
end

function player:add_item(item, count)
  player.inventory:add_item(item, count)
  if item.equippable then
    local equipped_items = {}
    local equipment
    for _, slot_name in pairs{'left_hand', 'right_hand', 'left_reserve', 'right_reserve'} do
      equipment = player.inventory.equipment[slot_name]
      if equipment then
        table.insert(equipped_items, equipment)
      else
        local good = true
        for _, other_item in pairs(equipped_items) do
          if item:same_class(other_item) then good = false end
        end
        if good then
          player.inventory:equip(slot_name, item)
        end
        break
      end
    end
  end
end

function moblist:insert(mob)
  for i = #self, 1, -1 do
    if self[i] == mob then
      error'tried to insert mob twice'
    end
  end
  mob.moblist = self
  return table.insert(self, mob)
end

function moblist:remove(which)
  local mob
  if type(which) == 'number' then
    mob = table.remove(self, which)--self:removeAtIndex(which)--
  else
    -- search backwards; faster, assuming that older components are
    -- less likely to be deleted.
    for i = #self, 1, -1 do
      if self[i] == which then
        mob = table.remove(self, i)--self:removeAtIndex(i)--
        mob.moblist = false
        break -- it's faster because it stops iterating early
      end
    end
  end
  return mob
end

function moblist:remove_all()
  for i = #self, 1, -1 do
    self[i] = nil
  end
end

function moblist:handle_collision()
  local first, second
  local first_c, second_c
  for i1 = 1, #self do
    first = self[i1]
    first_c = first.collision
    if first_c then
      for i2 = i1 + 1, #self do
        second = self[i2]
        second_c = second.collision
        if second_c then
          if first:overlaps(second) then
            --print(first.name .. ' hit ' .. second.name .. '!')
            if type(first_c.onhit) == 'function' then
              first_c:onhit(second_c)
            end
            if type(second_c.onhit) == 'function' then
              second_c:onhit(first_c)
            end
          end
        end
      end
    end
  end
  self:remove_dead()
end

function moblist:remove_dead()
  for i, v in ipairs(self) do
    if v:is_dead() then
      local mobs = v:do_death()
      moblist:remove(i)
      for _, mob in ipairs(mobs) do
        moblist:insert(mob)
      end
    end
  end
end

moblist:insert(player)

moblist:insert(Item:pickup_from_base('sword', Vector:new{6 * TILESIZE, 4 * TILESIZE}))
--moblist:insert(Item:pickup_from_base('wand', Vector:new{6 * TILESIZE, 4 * TILESIZE}))
--moblist:insert(Item:pickup_from_base('bottle', Vector:new{6 * TILESIZE, 4 * TILESIZE}))

--[[
for yi = 2, 5 do
  --for xi = 1, 10 do
  do local xi = 11
    local mob = Drop.money:roll()
    --local mob = Drop.normal:roll()
    if mob then
      moblist:insert(mob:make_pickup(Vector:new{xi * TILESIZE, yi * TILESIZE} + HALFTILEVEC))
    end
  end
end
--]]

--moblist:insert(Item:pickup_from_base('knife', Vector:new{0 * TILESIZE, 2 * TILESIZE} + HALFTILEVEC))
--moblist:insert(Item:pickup_from_base('knife', Vector:new{0 * TILESIZE, 3 * TILESIZE} + HALFTILEVEC))
--moblist:insert(Item:pickup_from_base('heart', Vector:new{0 * TILESIZE, 4 * TILESIZE} + HALFTILEVEC))
--moblist:insert(Item:pickup_from_base('wand', Vector:new{7 * TILESIZE, 0 * TILESIZE} + HALFTILEVEC))

function Mob:draw(pos_offset)
  love.graphics.setColor(Color.FullBright)
  local tile_offset = 0
  local palette_offset = 0
  local rotation = 0
  local palette
  if self.state == 'invuln' and self.invuln_palette then
    --tile_offset = self.invuln_offset or 0
    palette = self.invuln_palette
  else
    palette = self.palette or 0
  end
  if self.rotation_type == 'add' then
    tile_offset = tile_offset + self.dir
  elseif self.rotation_type == 'rotate' then
    rotation = self.dir
  end
  if self.anim then
    if self.anim.tile_offset then
      tile_offset = tile_offset + self.anim.tile_offset
    end
    if self.anim.palette_offset then
      palette_offset = palette_offset + self.anim.palette_offset
    end
  end
  local half = TILESIZE / 2
  --sprites:drawSprite(self.sprite + offset, self.pos.x, self.pos.y, math.deg(90 * 1), 1, 1, half, half)
  if not self.sprite then error('tried to draw mob ' .. self.name .. ' but it has no sprite') end
  local pos = self.pos + pos_offset

  sprites:drawSpriteRecolor(palette + palette_offset, self.sprite + tile_offset, math.floor(pos.x), math.floor(pos.y), rotation)
end

function Mob:draw_hitbox()
  if self.collision then
    love.graphics.setColor(Color.Hitbox)
    local v = self.pos + self.collision.hitbox.corner
    local d = self.collision.hitbox.dim
    love.graphics.rectangle('fill', v.x, v.y, d.x, d.y)
  end
end

function Mob:draw_hearts_as_bar_and_numbers(x, y)
  local tile
  local health = self.counter and self.counter.health or self.health
  for i = 0, self.hearts - 1 do
    if health >= (i + 1) * HEART_VALUE then
      tile = TILE.BAR_FULL
    elseif health < i * HEART_VALUE then
      tile = TILE.BAR
    else
      tile = TILE.BAR + math.floor((health % HEART_VALUE))
    end
    sprites:drawSprite(tile, x + 8 * (i % 8), y - 8 * math.floor(i / 8), 0)
  end

  local place = 1
  for i = 0, 2 do
    place = place * 10
    sprites:drawSprite(TILE.NUMERALS + math.floor(health / (place / 10)) % 10, x - 4 * i + 32, y - 8, 0)
  end
end

function Mob:draw_hearts(x, y)
  local tile
  local health = self.counter and self.counter.health or self.health
  for i = 0, self.hearts - 1 do
    if health >= (i + 1) * HEART_VALUE then
      tile = TILE.HEART_FULL
    elseif health < i * HEART_VALUE then
      tile = TILE.HEART
    else
      tile = TILE.HEART + math.floor((health % HEART_VALUE) / 4)
    end
    sprites:drawSpriteRecolor(PALETTE.RED, tile, x + 8 * (i % 8), y - 8 * math.floor(i / 8), 0)
  end
end

function Mob:env_collision()
  local try_pos = self.pos + self.delta_pos
  local half = TILESIZE / 2

  -- screen extents/borders
  --local topleft = TILEVEC + HALFTILEVEC
  --local bottomright = Vector:new{10, 6} * TILEVEC + HALFTILEVEC
  local topleft = HALFTILEVEC
  local bottomright = Vector:new{11, 7} * TILEVEC + HALFTILEVEC

  local x, y = try_pos:unpack()
  --if x >= half and x <= 11 * TILESIZE + half and y >= half and y <= 7 * TILESIZE + half then
    --self.pos = try_pos
  --end
  if self.collision then
    if not self.collision.tags.leave_screen or type(self.collision.on_hit_env) == 'function' then
      local hit = false
      local hitdir
      if x < topleft.x then
        x = topleft.x
        hit = 'screenborder'
        hitdir = 2
      elseif x > bottomright.x then
        x = bottomright.x
        hit = 'screenborder'
        hitdir = 0
      end
      if y < topleft.y then
        y = topleft.y
        hit = 'screenborder'
        hitdir = 3
      elseif y > bottomright.y then
        y = bottomright.y
        hit = 'screenborder'
        hitdir = 1
      end
      if hit then
        if type(self.collision.on_hit_env) == 'function' then
          self.collision:on_hit_env(hit, hitdir)
        end
      else
        if self.collision.screenborder_timer then
          self.collision.screenborder_timer = 0
        end
      end
    else
      -- weapons, etc.
    end
  end
  self.pos = Vector:new{x, y}
  self.delta_pos = self.delta_pos / 2
  if self.delta_pos:mag() < 0.01 then self.delta_pos = Vector:new{0, 0} end
  return hit
end

function Mob:__lt(other)
  return self.draworder < other.draworder
end

--[[
    for level = 1, 100 do
      print(level, math.random(math.min(math.max(1, level - 4), 8), math.min(level, 8)))
    end
    love.event.quit()

--]]

local function LOAD_ENEMIES()
  if player.floor % 8 == 0 then
    -- treasure room
    local level = math.floor(player.floor / 8)
    local r = math.floor(level / 4)
    local treasure_count = math.min(r + 1, 8)
    for i = 0, treasure_count - 1 do
      local drop
      if level <= 32 then
        drop = Drop.super_money:roll()
      else
        drop = Drop.ultra_money:roll()
      end
      if drop then
        drop = drop:make_pickup(Vector:new{
          6.5 + i - treasure_count * 0.5,
          4}-- + (i / 8) * 8 - math.floor(treasure_count / 8) * 0.5}
        * TILESIZE)
        moblist:insert(drop)
      end
    end
  else
    -- enemies
    
    local e
    for i = 1, math.random(math.min(player.floor, 8), math.min(player.floor + 1, 8)) do
      local max_enemy = math.min(math.floor(math.sqrt(player.floor)), #Enemy.template)
      local which = math.random(1, max_enemy)
      e = Enemy.template[which]:dup()
      e.pos = Vector:new{math.random(2, 9), math.random(2, 4)} * TILESIZE + HALFTILEVEC
      e.palette = math.random(0, 9)
      moblist:insert(e)
    end
  end
end

function love.load()
  love.audio.setVolume(0.5)

  love.resize()

  do
    local w, h, f = love.window.getMode()
    f.minwidth = Game.minw
    f.minheight = Game.minh
    love.window.setMode(w, h, f)
  end
end

local SLOWMO = false

local dungeonPalette = PALETTE.GREY

function love.keypressed(key, scancode, isrepeat)
  if DEBUG_MODE then
    if key == 'tab' then
      SLOWMO = not SLOWMO
    elseif key == 'escape' then
      if State.state == 'play' then
        State:pause()
      elseif State.state == 'pause' or State.state == 'edit' then
        State:play()
      end
    elseif key == 'f1' then
      if State.state == 'play' then
        State:edit()
      elseif State.state == 'edit' then
        State:play()
      end
    elseif key == 'f2' then
      print(current_map:save'quicksave.room')
    elseif key == 'f3' then
      print(current_map:load('quicksave.room', 'save/'))
      --current_map = Map:new(maptiles)
    elseif key == 'f4' then
      --current_map = Map:new(maptiles)
      --player:add_item(Item:from_base'sword')
      --player:add_item(Item:from_base'knife', 20)
    elseif key == 'f5' then
      --[[
      local mob = Item:pickup_from_base(
        'bottle',
        Vector:new{math.random(2, 8), math.random(2, 6)} * TILESIZE + HALFTILEVEC
      )
      mob:inherit{
        count = 1,
        --pos = Vector:new{TILESIZE, TILESIZE},
      }
      moblist:insert(mob)
      --]]
      local mob = Item:pickup_from_base(
        'butterfly',
        Vector:new{math.random(2, 8), math.random(2, 6)} * TILESIZE + HALFTILEVEC
      )
      moblist:insert(mob)
    elseif key == 'f6' then
      for _, v in ipairs(moblist) do
        if v.team == 'enemy' then
          v:take_damage{tags = {damage = 10000}}
        end
      end
      player:heal()
      moblist:remove(player)
      moblist:insert(player)
    elseif key == 'f7' then
      player.pos = Vector:new{6 * TILESIZE, 6.5 * TILESIZE}
      player.dir = 3
      moblist:remove_all()
      moblist:insert(player)
      player.floor = player.floor + 1
      LOAD_ENEMIES()
    elseif key == 'f8' then
      love.event.quit'restart'
    elseif key == 'f9' then
      DRAW_HITBOXES = not DRAW_HITBOXES
    elseif key == 'f12' then
      --local e = Enemy.template[#Enemy.template]:dup()
      local e = Enemy.template[1]:dup()
      e.pos = Vector:new{math.random(2, 8), math.random(2, 4)} * TILESIZE + HALFTILEVEC
      e.hearts = 12
      e:heal()
      moblist:insert(e)

    ---[[
    elseif key == 'l' then
      State:changescreen{0}
    elseif key == 'k' then
      State:changescreen{1}
    elseif key == 'j' then
      State:changescreen{2}
    elseif key == 'i' then
      State:changescreen{3}
      --]]
    end

    if State.state == 'edit' then
      if key == '1' then
        player.edit.tool = player.edit.tools[1]
        love.mouse.setCursor(mouse_cursor_red)
      elseif key == '2' then
        player.edit.tool = player.edit.tools[2]
        love.mouse.setCursor(mouse_cursor_brush)
      elseif key == 'tab' then
        player.edit.current_layer = 1 - player.edit.current_layer
      elseif key == 'q' then
        player.edit.brush.size = math.max(1, player.edit.brush.size - 1)
      elseif key == 'w' then
        player.edit.brush.size = math.min(player.edit.brush.size + 1, 8)
      end
    end
  end
  if (not DEBUG_MODE and key == 'escape') or key == 'pause' or key == 'f10' then
    if State.state == 'play' then
      State:pause()
    elseif State.state == 'pause' then
      State:play()
    end
  elseif key == '0' then
    love.audio.setVolume(0)
  elseif key == '-' then
    love.audio.setVolume(math.max(love.audio.getVolume() - 0.05, 0.0))
  elseif key == '=' then
    love.audio.setVolume(math.min(love.audio.getVolume() + 0.05, 1.0))
  end
end

local function sleep(n)
  local t = os.clock()
  while os.clock() - t <= n do
    -- nothing
  end
end

function love.update(dt)
  if SLOWMO then
    sleep(0.1)
  end

  if State.state == 'play' then
    Camera:update()

    player:recieve_input()

    --prinspect(player.subscreen)
    player.subscreen:update()

    --print(enemy_count, enemy_spawn_timer)


    local enemy_count = 0

    for _, v in ipairs(moblist) do
      v:update()
      if v.team == 'enemy' then
        enemy_count = enemy_count + 1
      end
    end
    moblist:handle_collision()
    sort(moblist)

    if enemy_count <= 0 then
      --TODO: room system
      --DOOR_OPEN = true
    end

    --print(#moblist)
  elseif State.state == 'changescreen' then

    if State.previous_state == 'edit' then
      print'changed screen in edit mode'
      State:previous()
    else

      local dir = State.info[1]
      local dirvec = dir2vec[dir]
      local dirname = dir_name[dir]

      Camera:update()

      moblist:remove_all()
      moblist:insert(player)

      if State.timer == State.timer_max then
        player.input[dirname] = 1
        player:changeState'walk'
        player:update()
      end

      State.timer = math.max(State.timer - 1, 0)

      local scale = ROOM_DIMENSIONS * dir2vec[dir % 4]
      scale = math.max(math.abs(scale.x), math.abs(scale.y))

      local fraction = ((State.timer_max - State.timer) / State.timer_max)

      Camera.target = dirvec * fraction * scale

      --print(fraction)

      --player.pos =
        --Vector:new{0, fraction * 3 * TILESIZE} * dirvec
        --+ Vector:new{player.pos.x, 0}
        --- TILEVEC * 1.5 * dirvec

      local COORD = {
        [0] = Vector:new{1, 0},
        Vector:new{0, 1},
      }

  --[[
      player.pos =
        Vector:new{fraction * 1 * TILESIZE, fraction * 1 * TILESIZE} * dirvec
        + player.pos:dup() * dir2vec[(dir + 1) % 2]:abs()
        --+ Vector:new{player.pos.x, 0}
        - TILEVEC * 0.5 * dirvec
        --+ ROOM_DIMENSIONS * dir2vec[(dir) % 2]
        - ROOM_DIMENSIONS / 2
  --]]
      player.pos =
        (
          ROOM_DIMENSIONS / 2
          --+ (player.pos - ROOM_DIMENSIONS / 2) * dir2vec[(dir + 2) % 4] + ROOM_DIMENSIONS / 2
          - ROOM_DIMENSIONS / 2 * dir2vec[(dir + 2) % 4]
          + (Vector:new{fraction * 1 * TILESIZE, fraction * 1 * TILESIZE} - TILEVEC * 0.5) * dirvec
        ) * COORD[dir % 2]
        + player.pos * COORD[(dir + 1) % 2]

      player.anim.timer = player.anim.timer + 1
      player.anim.states.walk.tick(player)

      if State.timer == 0 and math.abs((Camera.pos - Camera.target):mag()) <= 1 then
        player.floor = player.floor + 1
        --player.pos = Vector:new{player.pos.x, TILESIZE * 7.5}
        player.pos = player.pos - ROOM_DIMENSIONS * dirvec-- - HALFTILEVEC * dirvec
        Camera.pos = Vector:new{0, 0}
        Camera.target = Vector:new{0, 0}
        LOAD_ENEMIES()
        State:previous()
      end

    end

  elseif State.state == 'edit' then
    player:recieve_input()
    local mouse_pos = Game:getMousePosition()
    --local tile_index = (mouse_pos / 8):each(math.floor)
    local tile_x, tile_y = (mouse_pos / 8):each(math.floor):unpack()
    local tile_inside =
      tile_x >= 0 and tile_x < current_map.width and
      tile_y >= 0 and tile_y < current_map.height
    local mb = {}
    for i = 1, 3 do
      mb[i] = love.mouse.isDown(i)
    end

    if player.edit.tool == 'multi' then
      if player.input_hold_time.right_shoulder == 0 then
        if player.input_hold_time.left_shoulder == 0 then
          -- shift not held, ctrl not held
          if mb[1] and tile_inside then
            current_map:setTile(player.edit.current_tile, tile_x, tile_y, player.edit.current_layer)
            current_map:setAttr(player.edit.current_attr, tile_x, tile_y, player.edit.current_layer)
          end
          if mb[2] and tile_inside then
            player.edit.current_tile = current_map:getTile(tile_x, tile_y, player.edit.current_layer)
            player.edit.current_attr = current_map:getAttr(tile_x, tile_y, player.edit.current_layer)
          end
          if player.input_hold_time.use_right == 1 then
            player.edit.current_tile = math.min(player.edit.current_tile + 1, 63)
          end
          if player.input_hold_time.use_left == 1 then
            player.edit.current_tile = math.max(0, player.edit.current_tile - 1)
          end
          if player.input_hold_time.use_right_reserve == 1 then
            player.edit.current_attr = Map:rotate(player.edit.current_attr, 1)
            --player.edit.current_attr = player.edit.current_attr + 1
          end
          if player.input_hold_time.use_left_reserve == 1 then
            player.edit.current_attr = Map:rotate(player.edit.current_attr, 3)
            --player.edit.current_attr = player.edit.current_attr - 1
          end
        else
          -- shift held, ctrl not
          if mb[1] and tile_inside then
            local _r, _f, palette = Map:unpack_attribute(player.edit.current_attr)
            current_map:setAttr(
              Map:recolor(current_map:getAttr(tile_x, tile_y, player.edit.current_layer), palette),
              tile_x, tile_y,
              player.edit.current_layer
            )
          end
          if mb[2] and tile_inside then
            --player.edit.current_tile = current_map:getTile(tile_x, tile_y, player.edit.current_layer)
            local _r, _f, p = Map:unpack_attribute(current_map:getAttr(tile_x, tile_y, player.edit.current_layer))
            local r, f, _p = Map:unpack_attribute(player.edit.current_attr)
            player.edit.current_attr = Map:pack_attribute(r, f, p)
          end
          if player.input_hold_time.use_right == 1 then
            local r, f, palette = Map:unpack_attribute(player.edit.current_attr)
            player.edit.current_attr = Map:pack_attribute(r, f, math.min(palette + 1, 15))
          end
          if player.input_hold_time.use_left == 1 then
            local r, f, palette = Map:unpack_attribute(player.edit.current_attr)
            player.edit.current_attr = Map:pack_attribute(r, f, math.max(0, palette - 1))
          end
          if player.input_hold_time.use_left_reserve == 1 then
            --player.edit.current_layer = 1 - player.edit.current_layer
          end
        end
      end
    elseif player.edit.tool == 'palette_painter' then
      if mb[1] and tile_inside then
        local _r, _f, palette = Map:unpack_attribute(player.edit.current_attr)
        current_map:setAttr(
          Map:recolor(current_map:getAttr(tile_x, tile_y, player.edit.current_layer), palette),
          tile_x, tile_y,
          player.edit.current_layer
        )
      end
      if mb[2] and tile_inside then
        --player.edit.current_tile = current_map:getTile(tile_x, tile_y, player.edit.current_layer)
        local _r, _f, p = Map:unpack_attribute(current_map:getAttr(tile_x, tile_y, player.edit.current_layer))
        local r, f, _p = Map:unpack_attribute(player.edit.current_attr)
        player.edit.current_attr = Map:pack_attribute(r, f, p)
      end
      
            --local r, f, palette = Map:unpack_attribute(player.edit.current_attr)
            --current_map:setAttr(
              --Map:pack_attribute(r, f, palette + 1),
              --tile_x, tile_y,
              --player.edit.current_layer
        --)
      if player.input_hold_time.use_right == 1 then
        local r, f, palette = Map:unpack_attribute(player.edit.current_attr)
        player.edit.current_attr = Map:pack_attribute(r, f, math.min(palette + 1, 15))
      end
      if player.input_hold_time.use_left == 1 then
        local r, f, palette = Map:unpack_attribute(player.edit.current_attr)
        player.edit.current_attr = Map:pack_attribute(r, f, math.max(0, palette - 1))
      end
    end

  end
end

function love.draw()
  love.graphics.clear(Color.ScreenBorder)

  Game.screen:renderTo(function()
    --love.graphics.setShader(paletteShader)
    if DEBUG_MODE then
      love.graphics.clear(Color.Magenta)
    end

    love.graphics.setColor(Color.FullBright)

    -- Draw screen map (layer 0)
    if State.state ~= 'edit' or player.edit.current_layer == 0 then
      current_map:drawLayer(0, -Camera.pos.x, -Camera.pos.y)
    end
    if State.state == 'changescreen' then
      local dir = State.info[1]
      local pos = -Camera.pos + dir2vec[dir] * ROOM_DIMENSIONS--Vector:new{12, 8} * TILESIZE
      current_map:drawLayer(0, pos.x, pos.y)
    end

    love.graphics.setColor(Color.FullBright)
    for _, v in ipairs(moblist) do
      v:draw(-Camera.pos)
    end

    -- Draw screen map top layer
    if State.state ~= 'edit' or player.edit.current_layer == 1 then
      current_map:drawLayer(1, -Camera.pos.x, -Camera.pos.y)
    end
    if State.state == 'changescreen' then
      local dir = State.info[1]
      local pos = -Camera.pos + dir2vec[dir] * ROOM_DIMENSIONS--Vector:new{12, 8} * TILESIZE
      current_map:drawLayer(1, pos.x, pos.y)
    end

    love.graphics.setColor(Color.FullBright)
    if State.state == 'pause' then
      love.graphics.draw(pause_image, TILESIZE * 3.75, TILESIZE * 3.25)
    end

    if State.state == 'edit' then
      player.subscreen:draw_edit_ui(0, 8 * TILESIZE)
    else
      player.subscreen:draw_status_bar(0, 8 * TILESIZE)
    end

    love.graphics.setShader()

    if DRAW_HITBOXES then
      for _, v in ipairs(moblist) do
        v:draw_hitbox()
      end
    end

  end)

  love.graphics.setColor(Color.FullBright)
  love.graphics.draw(Game.screen, Game.x, Game.y, 0, Game.scale, Game.scale)

  --Game.screen2:renderTo(function()
    --love.graphics.setColor(Color.FullBright)
    --love.graphics.draw(Game.screen, 0, 0, 0, 64 / 192, 64 / 160)
  --end)

  --love.graphics.draw(Game.screen2, Game.x, Game.y, 0, Game.scale * 192 / 64, Game.scale * 160 / 64)

  if DEBUG_MODE then
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print('Player pos: ' .. tostring(player.pos), 10, 30)
    love.graphics.print('Mobs: ' .. tostring(#moblist), 10, 50)
  end
end

function love.resize(w, h)
  w = w or love.graphics.getWidth()
  h = h or love.graphics.getHeight()
  Game.center.x = math.floor(w / 2)
  Game.center.y = math.floor(h / 2)
  local scale = 1
  Game.scale = math.floor(math.min(
    w / (Game.minw * scale),
    h / (Game.minh * scale)
  ))
  Game.scale = math.max(Game.scale, 1)
  Game.x = Game.center.x - math.floor(Game.width / 2) * Game.scale * scale
  Game.y = Game.center.y - math.floor(Game.height / 2) * Game.scale * scale
end

function love.quit()
  local abort = false
  print(current_map:save'autosave.room')
  return abort
end
