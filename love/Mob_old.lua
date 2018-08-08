local Mob = {}
Mob.class = 'Mob'

function Mob.__index(table, key)
  local value = rawget(table, key)
  if not value then
    value = rawget(Mob, key)
  end
  --[[if not value then
    error(
      'Attempt to access non-existant member ' .. key ..
      ' of class ' .. (rawget(Mob, 'class') or 'UnkownClass'),
      2
    )
  end]]
  return value
end

Mob.template = {
  name = 'no-name-mob',
  team = 'none',
  tile = 0,
  tileAttribute = 0,
  pos = Vector{0, 0},
  delta_pos = Vector{0, 0},
  draworder = 0,
  human = 0, -- whether this mob is controlled by a player
    -- 0 is AI, anything else is that player's number
  rotation_type = 'rotate', -- rotation_types:
    -- add - dir number is added to tile index
    -- rotate - sprite is rotated numerically
  dir = 0,
  hearts = 1,
  input = {
    left = 0,
    right = 0,
    up = 0,
    down = 0,
  },
  input_hold_time = {},
  --[[collision = {
    tags = {},
    hitbox = 16,
  },]]
  state = 'walk',
}

function Mob:dup()
  return Mob.inherit({}, self)
end

local function new_hitbox(arg)
  local x, y, w, h
  if type(arg) == 'table' then
    if arg.corner and arg.dim then
      return {corner = arg.corner:dup(), dim = arg.dim:dup()}
    elseif #arg == 2 then
      w, h = unpack(arg)
      x, y = -w / 2, -h / 2
    elseif #arg == 4 then
      x, y, w, h = unpack(arg)
    else
      prinspect(arg)
      error'invalid mob template hitbox argument'
    end
  elseif type(arg) == 'number' then
    local width = arg
    local half_width = width / 2
    x, y, w, h =
      -half_width, -half_width, width, width
  end
  return {
    corner = Vector:new{x, y},
    dim = Vector:new{w, h},
  }
end

function Mob:inherit(template)
  for k, v in pairs(template) do
    if type(v) == 'table' then
      if k == 'collision' then
        local c = {
          tags = v.tags and recursive_copy(v.tags) or {},
          mob = self,
          onhit = v.onhit,
          on_hit_env = v.on_hit_env,
          screenborder_timer = v.screenborder_timer,
        }
        if v.rotating_hitbox then
          c.rotating_hitbox = new_hitbox(v.rotating_hitbox)
          c.hitbox = new_hitbox(v.rotating_hitbox)
        end
        if v.hitbox then
          c.hitbox = new_hitbox(v.hitbox)
        end
        self[k] = c
      elseif type(v.dup) == 'function' then
        self[k] = v:dup()
      else
        self[k] = recursive_copy(v)
      end
    else
      self[k] = v
    end
  end

  if self.hearts and not self.health then
    self.health = self.hearts * 16
  end

  setmetatable(self, Mob)
  return self
end

function Mob:new(template)
  return Mob.inherit(recursive_copy(Mob.template), template)
end

do
  local function alignmove(b,m,bspd,mspd,align)
    -- b = base axis, m = second axis, spd = speed, align = grid size
    local off=b%align
    local half=math.floor(align/2)
    local dir
    if off==0 then
      m=m+mspd
      if mspd > 0 then dir = 1 end
      if mspd < 0 then dir = -1 end
    elseif off<half then
      b=b-bspd
      if b%align>half then b=math.floor(b/align)*align+align end
      dir = -1
    elseif off>=half then
      b=b+bspd
      if b%align<half then b=math.floor(b/align)*align end
      dir = 1
    end
    return b,m, dir
  end

  function Mob:update()
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

    --[[
      if xdir == 0 then
        if ydir == 1 then
          self.dir = 1
        elseif ydir == -1 then
          self.dir = 3
        end
      end

      if ydir == 0 then
        if xdir == 1 then
          self.dir = 0
        elseif xdir == -1 then
          self.dir = 2
        end
      end

      if prevdir ~= self.dir then
        print(xdir, ydir)
        print(prevdir)
        print(self.dir)
        print'--------'
      end
      --]]
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

function Mob:take_damage(col)
  if self.state ~= 'invuln' then
    local damage = 0
    if type(col) == 'number' then
      damage = col
    else
      if col.tags.damage then
        damage = col.tags.damage
      end
      local knockback
      if col.tags.knockback then
        if col.tags.knockbacktype == 'parent_dir' then
          knockback = self.pos - col.mob.pos
          if knockback == Vector:new{0, 0} then
            knockback = dir2vec[math.random(0, 3)]
          else
            if math.abs(knockback.x) > math.abs(knockback.y) then
              knockback = dir2vec[0] * (knockback.x > 0 and 1 or -1)
            else
              knockback = dir2vec[1] * (knockback.y > 0 and 1 or -1)
            end
          end
          --print(knockback)
        elseif col.tags.knockbacktype == 'opposite_dir' then
          knockback = -dir2vec[self.dir] * col.tags.knockback
        elseif col.tags.knockbacktype == 'self_dir' then
          knockback = dir2vec[col.mob.dir] * col.tags.knockback
        else
          error('invalid knockback type ' .. tostring(col.tags.knockbacktype))
        end
        --self.delta_pos = self.delta_pos + knockback:norm() * col.tags.knockback * (1 - self.resistance.knockback[1]) - self.resistance.knockback[2]
        self.knockback_delta =
          knockback:norm() * col.tags.knockback-- * (1 - self.resistance.knockback[1]) - self.resistance.knockback[2]
      end
        --self.pos = self.pos + Vector:new{10, 10}
    end

    if self.take_damage_sound then
      self.take_damage_sound:replay()
    end

    local final_damage = damage

    final_damage = math.ceil(final_damage)

    self.health = self.health - final_damage
    self:start_state'invuln'
  end
end

function Mob:heal(ammount)
  ammount = ammount or self.hearts * HEART_VALUE
  self.health = math.min(self.health + ammount, self.hearts * HEART_VALUE)
end

function Mob:is_dead()
  return self.health <= 0
end

function Mob:start_state(state)
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

Mob.changeState = Mob.start_state

function Mob:isInvuln()
  return self.state == 'invuln'
end

function Mob:recieve_input()
  self.input_last_frame = {}
  for k, v in pairs(self.input) do
    self.input_last_frame[k] = v
  end

  for _, v in ipairs{'up', 'down', 'left', 'right'} do
    self.input[v] = love.keyboard.isDown(v) and 1 or 0
  end
  self.input.use_left = love.keyboard.isDown('z') and 1 or 0
  self.input.use_right = love.keyboard.isDown('x') and 1 or 0
  self.input.use_left_reserve = love.keyboard.isDown('a') and 1 or 0
  self.input.use_right_reserve = love.keyboard.isDown('s') and 1 or 0
  self.input.left_shoulder = love.keyboard.isDown('lshift') and 1 or 0
  self.input.right_shoulder = love.keyboard.isDown('lctrl') and 1 or 0

  self.input_hold_time = self.input_hold_time or {}
  for k, v in pairs(self.input) do
    --if v == 1 then
      --self.input_hold_time[k] = (self.input_hold_time[k] or 0) + 1
    --else
      --self.input_hold_time[k] = false
    --end
    self.input_hold_time[k] = v == 1 and ((self.input_hold_time[k] or 0) + 1) or 0
  end
--  prinspect(self.input_hold_time)
end

function Mob:do_death()
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

function Mob:overlaps(other)
  if self.collision and other.collision then
    local hb0 = self.collision.hitbox
    local topleft0 = self.pos + hb0.corner
    local bottomright0 = topleft0 + hb0.dim

    local hb1 = other.collision.hitbox
    local topleft1 = other.pos + hb1.corner
    local bottomright1 = topleft1 + hb1.dim

    local minkowski = {
      topleft = topleft0 - bottomright1,
      dim = hb0.dim + hb1.dim,
    }

    minkowski.bottomright = minkowski.topleft + minkowski.dim

    if
      minkowski.topleft.x < 0 and
      minkowski.topleft.y < 0 and
      minkowski.bottomright.x > 0 and
      minkowski.bottomright.y > 0 then
        return true -- return penetration vector instead?
    else
      return false
    end
  else
    error'mobs do not both have collision data'
  end
end

return Mob
