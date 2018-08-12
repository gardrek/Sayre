local Mob =  Class 'Mob'

Mob.template = {
  name = 'no-name-mob',
  team = 'none',
  tilemap = false,
  tileindex = 0,
  pos = Vector{0, 0},
  delta_pos = Vector{0, 0},
  draworder = 0,
  human = 0, -- whether this mob is controlled by a player
    -- 0 is AI, anything else is that player's number
  rotation_type = 'rotate',
    -- TODO: should these instead be incorporated when building the tilemap
      -- and essentially always operate in "add" mode? probably
    -- rotation_types:
    -- add - dir number is added to tilemap index
    -- rotate - sprite is rotated normally
    -- flip - sprite is flipped across x/y axis
  dir = 0,
  hearts = 1,
  health = false,
  input = false,
}

function Mob:init(template)
  if self.hearts and not self.health then
    self.health = self.hearts * HEART_VALUE
  end
end

do
  local n = 0

  function Mob:newPlayer(template)
    n = n + 1
    return Mob.inherit(Mob:new{
      name = 'player' .. tostring(n),
      team = 'player',
      hearts = 3,
      human = 1,
      --[[
      update = function(self)
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
      end,
      ]]
    }, template)
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

  local dir

  function Mob:update()
    if self.input then
      self.input:update()
      local value = self.input.value
      local move = Vector{
        value.right - value.left,
        value.down - value.up,
      }
      self.dir = vec2dir(move) or self.dir
      if not move:isNull() then
        self.pos = self.pos + move
      end
    end

    --if self.rotation_type == 'add' then
      self.tileindex = self.dir
    --end

    if true then return end

    self.delta_pos = Vector:new{0, 0}
    --[[
    if self.collision then
      --FIXME: rotating hitboxes only work for direction zero!?
      local hb = self.collision.rotating_hitbox
      if hb then
        print('oy', math.random())
        self.collision.hitbox = new_hitbox{
          corner = hb.corner:rotate2(dir2vec[self.dir]),
          dim = hb.dim:rotate2(dir2vec[self.dir]),
        }
      end
    end
    --]]

    if self.human == 0 then
      if self.ai and not self.ai.disabled then
        self.ai.tick(self)
      end
    end
    --[[
    if self.counter then
      if self.counter.health then
        self.counter.health = math.max(-self.hearts * HEART_VALUE, math.min(self.counter.health, self.hearts * HEART_VALUE))
        if self.health - self.counter.health > 0 then
          self.counter.health = self.counter.health + 1
          if self.counter.health % 4 == 0 then Sound.heart:replay() end
        elseif self.health - self.counter.health < 0 then
          self.counter.health = self.counter.health - 1
        end
      end
    end
    --]]

    self:setDrawOrder()

    if self.projectile_cooldown and self.projectile_cooldown > 0 then
      self.projectile_cooldown = self.projectile_cooldown - 1
    end


    if self.state == 'walk' or self.state == 'invuln' then
      local delta = Vector:new{
        self.input.right - self.input.left,
        self.input.down - self.input.up,
      }
      local grid = 8
      local xdir, ydir = 0, 0
      local x, y
      if math.abs(delta.x) > math.abs(delta.y) then
        y, x, xdir = alignmove(self.pos.y, self.pos.x, math.abs(delta.x), delta.x, grid)
      else -- by not handling x == y separately we have one axis (y) which is favored when a diagonal is pressed
        x, y, ydir = alignmove(self.pos.x, self.pos.y, math.abs(delta.y), delta.y, grid)
      end

      self.knockback_delta = self.knockback_delta or Vector:new{0, 0}
      self.delta_pos = self.delta_pos + (Vector:new{x, y} - self.pos) * self.speed + self.knockback_delta
      self.knockback_delta = self.knockback_delta / 2
      if self.knockback_delta:mag() < 0.01 then self.knockback_delta = Vector:new{0, 0} end


      local prevdir = self.dir

      --FIXME: makes for sliding, but you face the right way so
      xdir, ydir = delta:unpack()
      if xdir > 0 then xdir = 1 end
      if xdir < 0 then xdir = -1 end
      if ydir > 0 then ydir = 1 end
      if ydir < 0 then ydir = -1 end
      if ydir == 0 then
        if xdir == 1 then
          self.dir = 0
        elseif xdir == -1 then
          self.dir = 2
        end
      else
        if ydir == 1 then
          self.dir = 1
        elseif ydir == -1 then
          self.dir = 3
        end
      end

    elseif self.state == 'attack' then
    else
      error('mob in invalid state "' .. tostring(self.state) .. '"')
    end

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
