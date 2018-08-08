local Mob = require 'Mob'
local Vector = require 'Vector'
local Sound = require 'Sound'
local Drop = require 'Drop'

local Enemy = {}

local mob_anim_states = {
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
    timer = 12,
    finish = function(self)
      self:start_state'walk'
    end,
  },
}

local function make_puff(pos)
  local mob = Mob:new{
    sprite = TILE.PUFF,
    palette = PALETTE.YELLOW,
    pos = pos,
    anim = {
      timer = 0,
      start = true,
      states = {
        invuln = {
          timer = 12,
          tick = function(self)
            self.anim.tile_offset = 2 - math.floor(self.anim.timer / 4) % 3
          end,
          finish = function(self)
            self.health = 0
          end,
        },
      },
    },
  }
  mob:changeState'invuln'
  return mob
end

Enemy.make_puff = make_puff

Enemy.training_dummy = Mob:new{
  name = 'dummy',
  team = 'dummy',
  pos = Vector:new{4 * TILESIZE, 4 * TILESIZE},
  sprite = TILE.ENEMY_BLOB,
  rotation_type = 'add',
  dir = 1,
  hearts = 128,
  resistance = {
    knockback = {1, 0},
  },
  anim = {
    timer = 0,
    state = 'walk',
    states = mob_anim_states,
  },
  collision = {
    tags = {
      body = true,
      --damage = HEART_VALUE * 0.5,
      knockback = 12,
      --knockbacktype = 'opposite_dir',
      knockbacktype = 'parent_dir',
    },
    hitbox = 10,
    onhit = function(self, other)
      if self.mob.team ~= other.mob.team and not self.mob:is_dead() then
        if other.tags.body then
          other.mob:take_damage(self)
        end
      end
    end,
  },
  take_damage_sound = Sound.enemy_hit,
  --[[drops = {
    Drop.normal,
  },]]
}

Enemy.template = {}

local e = Mob:new{
  name = 'enemy',
  team = 'enemy',
  pos = Vector:new{12 * TILESIZE, 8 * TILESIZE},
  sprite = TILE.ENEMY_BLOB_SMALL,
  invuln_palette = 14,
  palette = PALETTE.BLUE,
  rotation_type = 'add',
  dir = 1,
  hearts = 1,
  input = {
    left = 0,
    right = 0,
    up = 0,
    down = 0,
  },
  ai = {
    timer = 0,
    tick = function(mob)
      mob.ai.timer = mob.ai.timer + 1
      if mob.ai.timer >= 32 then
        mob.ai.timer = 0
        for i = 0, 3 do
          mob.input[dir_name[i]] = 0
        end
        local turn = (mob.dir + 2 + math.random(1, 3)) % 4
        mob.input[dir_name[turn]] = 1
      end
    end,
  },
  speed = 0.5,
  anim = {
    timer = 0,
    state = 'walk',
    states = mob_anim_states,
  },
  collision = {
    tags = {
      body = true,
      damage = HEART_VALUE * 0.25,
      knockback = 12,
      --knockbacktype = 'opposite_dir',
      knockbacktype = 'parent_dir',
    },
    hitbox = 10,
    onhit = function(self, other)
      if self.mob.team ~= other.mob.team and not self.mob:is_dead() then
        if other.tags.body then
          other.mob:take_damage(self)
        end
      end
    end,
  },
  take_damage_sound = Sound.enemy_hit,
  drops = {
    Drop.normal,
  },
  on_death = function(self)
    return {make_puff(self.pos)}
  end,
}

table.insert(Enemy.template, e)

---- Enemy #2

local e = Enemy.template[1]:dup()

e.sprite = TILE.ENEMY_BLOB
e.collision.tags.damage = HEART_VALUE * 0.5
e.drops = nil

e.on_death = function(self)
  -- TODO: check for overkill, split if not overkill, roll for item if overkill, little blobs give no items
  -- check direction of atack, and split accordingly
  -- basically, we need to know more about what killed us
  local off = Vector:new{4, 0}
  local mob = Enemy.template[1]:dup()
  mob.ai.timer = 100
  mob:inherit{
    pos = self.pos + off,
    palette = self.palette,
  }
  mob:changeState'invuln'
  local mob2 = mob:dup()
  mob2:inherit{pos = self.pos - off}
  return {mob, mob2}
end

table.insert(Enemy.template, e)

---- Enemy #3

local e = Enemy.template[1]:dup()
--prinspect(e)
--e.collision.tags.damage = e.collision.tags.damage * 2
e.hearts = 2
e.health = e.hearts * HEART_VALUE
e.speed = e.speed * 2
e.sprite = TILE.ENEMY_DEMON_BLOB
e.palette = PALETTE.RED
e.invuln_palette = 15
e.drops[1] = Drop.money
table.insert(Enemy.template, e)

---- Enemy #4

local e = Enemy.template[1]:dup()
e.hearts = 2
e.health = e.hearts * HEART_VALUE
e.sprite = TILE.ENEMY_SHOOTING_BLOB
e.palette = PALETTE.CYAN
e.drops[1] = Drop.normal

do
  local projectile = {
    sprite = TILE.SHOOTING_SEED,
    palette = PALETTE.YELLOW,
    rotation_type = 'none',
    speed = 2,
    collision = {
      tags = {
        damage = 0.5 * HEART_VALUE,
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
            --self.anim.tile_offset = 2 - math.floor(self.anim.timer / 8) % 3
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
  }

  local function base_use(self, owner, offset)
    local mob = Mob:new(self.use_mob_template)
    mob.team = owner.team
    mob.name = self.name
    mob.pos = owner.pos + offset * HALFTILEVEC
    mob.dir = owner.dir
    mob.owner = owner
    mob.collision.parent = mob
    owner:start_state'attack'
    return mob
  end

  local function proj_use(self, owner, offset)
    if owner.projectile_cooldown <= 0 then -- and ammo
      --Sound.knife_throw:replay()
      owner.projectile_cooldown = 30
      -- subtract ammo
      return base_use(self, owner, offset)
    end
  end

  e.attack = function(self)
    local mob = proj_use({name = 'seed', use_mob_template = projectile, }, self, Vector:new{0, 0})
    if mob then
      self.moblist:insert(mob)
    end
  end

  e.projectile_cooldown = 0
end

e.ai = {
  timer = 0,
  tick = function(mob)
    mob.ai.timer = mob.ai.timer + 1
    if mob.ai.timer >= 32 then
      mob.ai.timer = 0
      if mob.state == 'attack' then
        mob:changeState'walk'
      elseif mob.state == 'walk' then
        for i = 0, 3 do
          mob.input[dir_name[i]] = 0
        end
        if math.random(1, 4) == 1 then
          mob:attack()
        else
          local turn = (mob.dir + 2 + math.random(1, 3)) % 4
          mob.input[dir_name[turn]] = 1
        end
      elseif mob.state == 'invuln' then
      else
        error(mob.state)
      end
    end
  end,
}

table.insert(Enemy.template, e)

Enemy.template[1].collision.tags.knockback = 8
--Enemy.template[1].collision.tags.knockback = nil
--Enemy.template[1].collision.tags.knockbacktype = nil


return Enemy
