local Item = simpleClass'Item'

--function Item.__index(table, key)
  --local value = rawget(table, key)
  --if not value then
    --value = rawget(Item, key)
  --end
  --if not value then
    --value = rawget(Item, key)
  --end
  --if not value then
    ----error(
      ----'Attempt to access non-existant member ' .. key ..
      ----' of class ' .. (rawget(Item, 'class') or 'UnkownClass'),
      ----2
    ----)
    --return nil
  --end
  --return value
--end

local function pickup(self, owner)
  if not self:is_dead() and self.state ~= 'invuln' then
    local sound = self.collision.tags.pickup_sound
    if sound then
      sound:replay()
    end
    self.health = 0
    if self.item.use_on_pickup then
      self.item:use(owner)
    else
      owner:add_item(self.item, self.count)
    end
  end
end

local invuln_anim_state = {
  timer = 12,
  finish = function(self)
    self:start_state'walk'
  end,
}

local function make_use_mob(template, self, owner, hand)
  local mob = Mob:new(template)
  mob.team = owner.team
  mob.name = mob.name or self.name
  mob.palette = mob.palette or self.palette
  mob.pos = owner.pos + hold_offset[hand][owner.dir] + dir2vec[owner.dir] * HALFTILEVEC
  mob.dir = owner.dir
  mob.owner = owner
  mob.collision.parent = mob
  return mob
end

local function base_use(self, owner, hand)
  owner:start_state'attack'
  return make_use_mob(self.use_mob_template, self, owner, hand)
end

local function drawUnderneath(self)
  if self.dir == 1 then
    self.draworder = self.owner.draworder - 1
  else
    self.draworder = self.pos.y * 512 + self.pos.x
  end
end

Item.mob_templates = {
  
}

Item.base = {
  sword = {
    name = 'sword',
    equippable = true,
    tile = TILE.SWORD,
    palette = PALETTE.BROWN,
    dir = 3,
    use_mob_template = {
      sprite = TILE.SWORD,
      speed = 4,
      collision = {
        tags = {
          damage = HEART_VALUE,
          leave_screen = true,
          knockback = 16,
          knockbacktype = 'self_dir',
        },
        rotating_hitbox = {16, 10},
        hitbox = 16,
        onhit = function(self, other)
          if other.mob.team ~= self.mob.team then
            if other.tags.body then
              other.mob:take_damage(self)
            elseif other.tags.pickup then
              other.tags.pickup(other.mob, self.mob.owner)
            end
          end
        end,
      },
      anim = {
        timer = 0,
        start = true,
        states = {
          walk = {
            timer = 12,
            tick = function(self)
              --local n = math.sin(1 / (12 - self.anim.timer) + 0.5)
              --local n = math.sin(self.anim.timer / 12 - 0.5)
              local n = math.sin(self.anim.timer / 12 - 1) * .35
              --print(n)
              self.delta_pos = dir2vec[self.dir] * self.speed * n
            end,
            finish = function(self)
              self.health = 0
            end,
          },
        },
      },
      setDrawOrder = drawUnderneath,
    },
    use = function(self, owner, hand)
      Sound.sword_swing:replay()
      local mob = base_use(self, owner, hand)
      mob.pos = owner.pos + hold_offset[hand][owner.dir] + dir2vec[owner.dir] * TILEVEC
      return mob
    end,
  },

  knife = {
    name = 'knife',
    equippable = true,
    has_count = true,
    tile = TILE.KNIFE,
    palette = PALETTE.GREEN,
    dir = 1,
    use_mob_template = {
      sprite = TILE.KNIFE,
      speed = 3,
      collision = {
        tags = {
          damage = 2 * HEART_VALUE,
          leave_screen = true,
          knockback = 4,
          knockbacktype = 'self_dir',
        },
        onhit = function(self, other)
          if other.mob.team ~= self.mob.team and other.tags.body and not self.mob:is_dead() then
            other.mob:take_damage(self)
            self.mob.health = 0
            self.mob.owner.projectile_cooldown = 0
            -- IDEA: maybe per-item cooldown?
          end
        end,
        hitbox = 16,
      },
      anim = {
        timer = 0,
        start = true,
        states = {
          walk = {
            timer = 75,
            tick = function(self)
              self.anim.tile_offset = 2 - math.floor(self.anim.timer / 8) % 3
              self.delta_pos = dir2vec[self.dir] * self.speed
              --[===[ TODO: make projectiles fly with input instead of animation timer?
              for i = 0, 3 do
                self.input[dir_name[i]] = 0
              end
              print(self.dir)
              self.input[dir_name[self.dir]] = 1
              --]===]
            end,
            finish = function(self)
              self.health = 0
            end,
          },
        },
      },
      setDrawOrder = drawUnderneath,
    },
    use = function(self, owner, hand)
      if owner.projectile_cooldown <= 0 and owner.inventory.ammo[self.name] > 0 then
        Sound.knife_throw:replay()
        owner.projectile_cooldown = 30
        owner.inventory.ammo[self.name] = owner.inventory.ammo[self.name] - 1
        return base_use(self, owner, hand)
      end
    end,
    pickup_mob_template = {
      count = 1,
      anim = {
        timer = 0,
        states = {
          invuln = {
            timer = invuln_anim_state.timer,
            tick = function(self)
              self.anim.tile_offset = 2 - math.floor(self.anim.timer / 8) % 3
            end,
            finish = invuln_anim_state.finish,
          },
          walk = {
            timer = 50400,
            tick = function(self)
              self.anim.tile_offset = 2 - math.floor(self.anim.timer / 8) % 3
            end,
            finish = function(self)
              self:start_state'walk'
            end,
          },
        },
      },
    },
  },

  wand = {
    name = 'wand',
    equippable = true,
    tile = TILE.WAND,
    palette = PALETTE.BLUE,
    dir = 3,
    melee_mob_template = {
      name = 'wand',
      sprite = TILE.WAND,
      speed = 4,
      collision = {
        tags = {
          damage = HEART_VALUE,
          leave_screen = true,
          knockback = 8,
          knockbacktype = 'self_dir',
        },
        rotating_hitbox = {16, 10},
        hitbox = 16,
        onhit = function(self, other)
          if other.mob.team ~= self.mob.team then
            if other.tags.body then
              other.mob:take_damage(self)
            elseif other.tags.pickup then
              other.tags.pickup(other.mob, self.mob.owner)
            end
          end
        end,
      },
      anim = {
        timer = 0,
        start = true,
        states = {
          walk = {
            timer = 12,
            tick = function(self)
              --local n = math.sin(1 / (12 - self.anim.timer) + 0.5)
              --local n = math.sin(self.anim.timer / 12 - 0.5)
              local n = math.sin(self.anim.timer / 12 - 1) * .35
              --print(n)
              self.delta_pos = dir2vec[self.dir] * self.speed * n
            end,
            finish = function(self)
              self.health = 0
            end,
          },
        },
      },
      setDrawOrder = drawUnderneath,
    },
    projectile_mob_template = {
      name = 'wand_blast',
      sprite = TILE.WAND_BLAST,
      palette = PALETTE.RED,
      speed = 2,
      hearts = 3,
      --[==[update = function(self)
        Mob.update(self)
        self.delta_pos = dir2vec[self.dir] * self.speed
        --print'oy'
        --self.input[dir_name[self.dir]] = 1
      end,]==]
      ---[=====[
      ai = {
        timer = 0,
        tick = function(self)
          self.delta_pos = dir2vec[self.dir] * self.speed
          --mob.ai.timer = mob.ai.timer + 1
          --if mob.ai.timer >= 32 then
            --mob.ai.timer = 0
            --for i = 0, 3 do
              --mob.input[dir_name[i]] = 0
            --end
            --mob.input[dir_name[mob.dir]] = 1
          --end
        end,
      },
      --]=====]
      collision = {
        tags = {
          damage = 2 * HEART_VALUE,
          leave_screen = true,
          --knockback = 4,
          --knockbacktype = 'self_dir',
        },
        onhit = function(self, other)
          if other.mob.team ~= self.mob.team and other.tags.body and not self.mob:is_dead() then
            if not other.mob:isInvuln() then
              self.mob:take_damage(HEART_VALUE)
            end
            other.mob:take_damage(self)
            if self.mob:is_dead() then
              self.mob.owner.projectile_cooldown = 0
            end
            self.mob:changeState'walk'
          end
        end,
        hitbox = 16,
      },
      anim = {
        timer = 0,
        start = true,
        states = {
          walk = {
            timer = 90,
            tick = function(self)
              self.anim.tile_offset = 2 - math.floor(self.anim.timer / 5) % 3
              --self.anim.tile_offset = 3 - math.floor(self.anim.timer / 4) % 4 -- sword blast
              self.anim.palette_offset = math.floor(self.anim.timer / 2) % 2 == 0 and -3 or 0
              --self.delta_pos = dir2vec[self.dir] * self.speed
            end,
            finish = function(self)
              self.health = 0
            end,
          },
        },
      },
    },
    use = function(self, owner, hand)
      Sound.sword_swing:replay()
      local melee = make_use_mob(self.melee_mob_template, self, owner, hand)
      melee.pos = owner.pos + hold_offset[hand][owner.dir] + dir2vec[owner.dir] * TILEVEC
      local mobs = {melee}
      if owner.projectile_cooldown <= 0 then--and owner.inventory.ammo[self.name] > 0 then
        --Sound.knife_throw:replay()
        owner.projectile_cooldown = 45
        --owner.inventory.ammo[self.name] = owner.inventory.ammo[self.name] - 1
        local projectile = make_use_mob(self.projectile_mob_template, self, owner, hand)
        projectile.pos = melee.pos:dup()
        table.insert(mobs, projectile)
      end
      owner:start_state'attack'
      return mobs
    end,
  },



  bottle = {
    name = 'bottle',
    equippable = true,
    has_count = true,
    tile = TILE.BOTTLE_SMALL + 1,
    palette = PALETTE.GREY,
    dir = 3,
    use_mob_template = {
      sprite = TILE.BOTTLE_SMALL,
      speed = 4,
      collision = {
        tags = {
          damage = math.floor(HEART_VALUE / 4),
          leave_screen = true,
        },
        rotating_hitbox = {16, 10},
        hitbox = 16,
        onhit = function(self, other)
          if other.mob.team ~= self.mob.team then
            if other.tags.body then
              other.mob:take_damage(self)
            elseif other.tags.pickup then
              other.tags.pickup(other.mob, self.mob.owner)
            end
          end
        end,
      },
      anim = {
        timer = 0,
        start = true,
        states = {
          walk = {
            timer = 12,
            tick = function(self)
              --local n = math.sin(1 / (12 - self.anim.timer) + 0.5)
              --local n = math.sin(self.anim.timer / 12 - 0.5)
              local n = math.sin(self.anim.timer / 12 - 1) * .35
              --print(n)
              self.delta_pos = dir2vec[self.dir] * self.speed * n
            end,
            finish = function(self)
              self.health = 0
            end,
          },
        },
      },
      setDrawOrder = drawUnderneath,
    },
    use = function(self, owner, hand)
      Sound.sword_swing:replay()
      local mob = base_use(self, owner, hand)
      mob.pos = owner.pos + hold_offset[hand][owner.dir] + dir2vec[owner.dir] * TILEVEC
      return mob
    end,
  },


  --consumables
  heart = {
    name = 'heart',
    use_on_pickup = true,
    pickup_sound = Sound.heart,
    tile = TILE.HEART_FULL,
    palette = PALETTE.RED,
    dir = 0,
    use = function(self, owner, hand)
      owner:heal(16)
    end,
  },

  health_up = {
    name = 'health_up',
    use_on_pickup = true,
    pickup_sound = Sound.heart,
    tile = TILE.HEALTH_UP,
    palette = PALETTE.RED,
    dir = 0,
    use = function(self, owner, hand)
      owner.hearts = owner.hearts + 1
      owner:heal()
    end,
  },

  butterfly = {
    name = 'butterfly',
    use_on_pickup = true,
    --pickup_sound = Sound.heart,
    tile = TILE.BUTTERFLY,
    palette = PALETTE.RED,
    dir = 0,
    use = function(self, owner, hand)
      owner:heal()
    end,
    pickup_mob_template = {
      count = 1,
      anim = {
        timer = 0,
        states = {
          invuln = {
            timer = invuln_anim_state.timer,
            tick = function(self)
              self.anim.tile_offset = 1 - math.floor(self.anim.timer / 8) % 2
            end,
            finish = invuln_anim_state.finish,
          },
          walk = {
            timer = 50400,
            tick = function(self)
              self.anim.tile_offset = 1 - math.floor(self.anim.timer / 8) % 2
            end,
            finish = function(self)
              self:start_state'walk'
            end,
          },
        },
      },

      speed = 1,
      rotation_type = 'none',
      ai = {
        timer = 32,
        tick = function(mob)
          mob.ai.timer = mob.ai.timer + 1
          if mob.ai.timer >= 32 then
            mob.ai.timer = 0
            for i = 0, 3 do
              mob.input[dir_name[i]] = 0
            end
            --local turn = (mob.dir + 2 + math.random(1, 3)) % 4
            --mob.input[dir_name[turn]] = 1
            mob.input[dir_name[math.random(0, 3)]] = 1
          end
        end,
      },
    },
  },
}

function Item:dup()
  return Item:new(self)
end

function Item:new(t)
  return setmetatable(recursive_copy(t), Item)
end

function Item:from_base(basename)
  return Item:new(Item.base[basename])
end

function Item:make_pickup(pos, count)
  local mob = Mob:new{
    name = self.name,
    team = 'item',
    pos = pos:dup(),
    sprite = self.tile,
    palette = self.palette,
    rotation_type = 'rotate',
    dir = self.dir,
    health = 1,
    state = 'invuln',
    anim = {
      timer = 0,
      start = true,
      states = {
        invuln = invuln_anim_state,
      },
    },
    collision = {
      tags = {
        pickup = pickup,
        pickup_sound = self.pickup_sound or Sound.pickup,
      },
      hitbox = 12,
      --onhit = function(self, other)
      --end,
    },
    item = self,
  }

  if self.pickup_mob_template then
    mob = mob:inherit(self.pickup_mob_template)
  end

  if count then
    error('too many arguments to make_pickup', 2)
    --mob:inherit{count = count}
  end

  --[[
  if self.has_count then
    count = count or self.count
    if type(count) == 'number' then
      mob.count = count
    else
      error'count must be a number'
    end
  end
  --]]

  mob:changeState'invuln'

  return mob
end

function Item:pickup_from_base(base, ...)
  return Item:from_base(base):make_pickup(...)
end

function Item:draw_icon(sprites, x, y)
  sprites:drawSpriteRecolor(self.palette or 10, self.tile, x, y, self.dir)
end

function Item:same_class(other)
  -- TODO: imlement item classes
  return self.name == other.name
end

return Item
