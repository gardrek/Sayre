--[[

== mob components ==

all mobs have these:
position (2D vector) - where it is on screen
velocity? (2D vector) - movement vector (direction and speed)

some mobs have these:
health (integer number of max hearts and integer current health) - for combat
pickup - data for if the mob can be picked up
ai - ???

]]

local FSM = require'FSM'

local Mob =  Class'Mob'

Mob.template = {
  name = 'no-name-mob',
  team = 'none',
  tilemap = false,
  tileindex = 0,
  pos = Vector{0, 0},
  delta_pos = Vector{0, 0},
  speed = 1,
  draworder = 0,
  human = 0, -- whether this mob is controlled by a player
    -- 0 is AI, 1+ is that player's number
  rotation_type = 'rotate',
    -- TODO: should these instead be incorporated when building the tilemap
      -- and essentially always operate in "add" mode? probably
    -- rotation_types:
    -- none - no rotation
    -- add - dir number is added to tilemap index
    -- rotate - sprite is rotated normally
    -- flip - sprite is flipped across x/y axis
  dir = 0,
  hearts = 1,
  health = false,
  input = false,
  state = false,
    -- either false or a state machine
}

function Mob:init(template)
  if self.hearts and not self.health then
    self.health = self.hearts * HEART_VALUE
  end
end

function Mob:newMobFSM()
  if self == Mob then error'' end
  self.state = FSM:new(function(action, arg)
    local state = 'move'
    while true do
      if action then
        print(action, arg)
        if action == 'use' then
          assert(type(arg) == 'string')
          local prev_state = state
          state = 'attack'
          local i = 0
          while i < 12 do
            action, arg = coroutine.yield(state)
            if not action then i = i + 1 end
            print(i)
          end
          --action, arg = coroutine.yield(prev_state)
          state = prev_state
        else
          print(action)
        end
      end
      action, arg = coroutine.yield(state)
    end
  end)
  return self
end

do
  local n = 0

  function Mob:newPlayer(template)
    n = n + 1
    return Mob.inherit(Mob:new{
      name = 'player' .. tostring(n),
      team = 'player',
      hearts = 3,
      human = n,
      rotation_type = 'add',
    }, template):newMobFSM() -- FIXME: HAX
  end

  --function player:add_item(item, count)
    --player.inventory:add_item(item, count)
    --if item.equippable then
      --local equipped_items = {}
      --local equipment
      --for _, slot_name in pairs{'left_hand', 'right_hand', 'left_reserve', 'right_reserve'} do
        --equipment = player.inventory.equipment[slot_name]
        --if equipment then
          --table.insert(equipped_items, equipment)
        --else
          --local good = true
          --for _, other_item in pairs(equipped_items) do
            --if item:same_class(other_item) then good = false end
          --end
          --if good then
            --player.inventory:equip(slot_name, item)
          --end
          --break
        --end
      --end
    --end
  --end

end

do
  local function alignmove(b, m, bspd, mspd, align)
    -- b = base axis, m = second axis, spd = speed, align = grid size
    local off = b % align
    local half = math.floor(align / 2)
    local dir
    if off == 0 then
      m = m + mspd
      if mspd > 0 then dir = 1 end
      if mspd < 0 then dir = -1 end
    elseif off < half then
      b = b - bspd
      if b % align > half then b = math.floor(b / align) * align + align end
      dir = -1
    elseif off >= half then
      b = b + bspd
      if b % align < half then b = math.floor(b / align) * align end
      dir = 1
    end
    return b, m, dir
  end

  local function alignvec(pos, delta, align)
    local x, y = self.pos:unpack()
    local mx, my = delta:unpack()
    local dir = vec2dir(delta)
    if math.abs(mx) > math.abs(my) then
      --TODO: actually make this function if deemed necessary
      y, x, dir = alignmove(y, x, math.abs(mx), mx, 8)
      self.pos = Vector{x, y}
    elseif math.abs(my) > math.abs(mx) then
      x, y, dir = alignmove(x, y, math.abs(my), my, 8)
      self.pos = Vector{x, y}
    end
  end

  local dir

  function Mob:update()
    if self.human == 0 then
      if self.ai and not self.ai.disabled then
        self.ai.tick(self)
      end
    end

    --[[
    if self:has'projectile_cooldown' and self.projectile_cooldown > 0 then
      self.projectile_cooldown = self.projectile_cooldown - 1
    end
    --]]

    if self.input then
      self.input:update()
    end

    if self.state then
      self.state:update()
      local state = self.state:get()
      --print(state)
      if state == 'move' then
        if self.input then
          local value = self.input.value
          local move = Vector{
            value.right - value.left,
            value.down - value.up,
          }
          self.dir = vec2dir(move) or self.dir
          if not move:isNull() then
            self.delta_pos = dir2vec[self.dir] * self.speed
          else
            self.delta_pos = Vector{0, 0}
          end
          local n = 0
          if self.input.hold_time.action_a == 1 then
            self.state:action('use', 'right')
            --self:use_item(self.inventory.equipment.right_hand, 'right')
          elseif self.input.hold_time.action_b == 1 then
            self.state:action('use', 'left')
            --print'use left'
            --self:use_item(self.inventory.equipment.left_hand, 'left')
          elseif self.input.hold_time.action_x == 1 then
            print'use right reserve'
            --self:use_item(self.inventory.equipment.right_reserve, 'right')
          elseif self.input.hold_time.action_y == 1 then
            print'use left reserve'
            --self:use_item(self.inventory.equipment.left_reserve, 'left')
          end
        end

        --[[
        self.knockback_delta = self.knockback_delta or Vector:new{0, 0}
        self.delta_pos = self.delta_pos + (Vector:new{x, y} - self.pos) * self.speed + self.knockback_delta
        self.knockback_delta = self.knockback_delta / 2
        if self.knockback_delta:mag() < 0.01 then self.knockback_delta = Vector:new{0, 0} end
        --]]
      elseif state == 'attack' then
        -- do attack stuff i guess
        self.delta_pos = Vector{0, 0}
      else
        error('mob in invalid state "' .. tostring(state) .. '"')
      end
    end

    self.pos = self.pos + self.delta_pos

    if self.rotation_type == 'add' then
      self.tileindex = self.dir
    end

    self:setDrawOrder()

if true then return end
----------------------------------------------------------------
--============================================================--
-- The rest of this function is old and not yet re-written    --
--============================================================--
----------------------------------------------------------------

    if self.anim and self.anim.states then
      local current = self.anim.states[self.state]
      if current then
        if self.anim.start then
          self.anim.start = false
          self.anim.timer = current.timer
        else
          self.anim.timer = self.anim.timer - 1
          if type(current.tick) == 'function' then
            current.tick(self)
          end
          if self.anim.timer <= 0 and type(current.finish) == 'function' then
            current.finish(self)
          end
        end
      else
        --print('warning: ' .. self.name .. ' has no animation for state ' .. tostring(self.state))
      end
    end

    self:env_collision()

    --print(self.name .. ' ' .. self.state .. ' ' .. self.health)
  end
end

function Mob:setDrawOrder()
  self.draworder = self.pos.y * 512 + self.pos.x
end

function Mob:take_damage(attack)
  if self:isInvuln() then
  else
    local multiplier = {} or self.multiplier
    local resistance = {} or self.resistance
    local damages = {}
    for type, v in pairs(attack.damage) do
      damages[type] = attack:calculate_damage(type, multiplier[type], resistance[type])
    end
    local effects = {}
    for type, v in pairs(attack.damage) do
      effects[type] = attack:calculate_effect(type, multiplier[type], resistance[type])
    end
    print('damage and stuff ', inspect(damages) , inspect(effects))
  end
end

function Mob:heal(amount)
  amount = amount or self.hearts * HEART_VALUE
  self.health = math.min(self.health + amount, self.hearts * HEART_VALUE)
end

function Mob:isDead()
  return self.health <= 0
end

function Mob:changeState(state)
  error'not implemented'
  self.state = state
  if self.anim then
    if self.anim.states[state] and self.anim.states[state] then
      self.anim.state = self.anim.states[state]
      self.anim.timer = 0
      self.anim.start = true
    else
      self.anim.state = false
      self.anim.timer = 0
      self.anim.start = false
    end
  end
end

function Mob:isInvuln()
  return self.state == 'invuln'
end

function Mob:doDeath()
  error'not implemented'
  local mobs = {}
  if self.drops then
    for _, v in pairs(self.drops) do
      local item = v:roll()
      if item then
        table.insert(mobs, item:make_pickup(self.pos))
      end
    end
  end
  if self.on_death then
    local mobs2 = self:on_death()
    if mobs2 then
      for _, v in ipairs(mobs2) do
        table.insert(mobs, v)
      end
    end
  end
  return mobs
end

function Mob:draw(pos_offset)
  pos_offset = pos_offset or Vector{0, 0}
  local half_size = Vector{self.tilemap.totalWidth, self.tilemap.totalHeight} / 2
  self.tilemap:drawLayer(self.tileindex, self.pos + pos_offset - half_size)
end

--[=======[

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
--]=======]


return Mob
