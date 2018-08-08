local Vector = require 'Vector'
local Mob = require 'Mob'
local Item = require 'Item'

local Drop = {}
Drop.__index = Drop
Drop.class = 'Drop'

local function new(t)
  if t.items then
    local total = 0
    for i, v in ipairs(t.items) do
      local c = {}
      c.item = v[1]
      c.number = v[2]
      t.items[i] = c
      total = total + c.number
    end
    t.total = total
  end
  return setmetatable(t, Drop)
end

function Drop:roll()
  if self.items then
    -- NOTE: math.random() is in range [0, 1), so it will always be less than 1
    -- this means we don't have to have an edge case for rate = 1
    if math.random() < (self.rate or 1) then
      local total = self.total
      local index = math.random(1, total)
      local acc = 0
      for _, v in ipairs(self.items) do
        acc = acc + v.number
        if index <= acc then
          if v.item then
            return v.item:dup()
          else
            return
          end
        end
      end
    end
  else
    local max = self.max or #self
    local n = math.random(1, max)
    local mob = self[n]
    if mob then
      return mob:dup()
    end
  end
end

function Drop:dup()
  return self
end

local heart = Item:from_base'heart'
local knife = Item:from_base'knife'

local fiver = Item:from_base'knife'

Mob.inherit(fiver.pickup_mob_template, {
  count = 5,
  sprite = TILE.KNIFE_MULT,
})

local tenpiece = Item:from_base'knife'

Mob.inherit(tenpiece.pickup_mob_template, {
  count = 10,
  sprite = TILE.KNIFE_MULT + 8,
})

local health_up = Item:from_base'health_up'

local butterfly = Item:from_base'butterfly'

Drop.normal = new{
  rate = 0.3125,
  items = {
    {heart, 4},
    {knife, 5},
    {butterfly, 1},
  },
}

Drop.money = new{
  rate = 0.59375,
  items = {
    {heart, 2},
    {knife, 5},
    {fiver, 2},
    {butterfly, 1},
  }
}

Drop.super_money = new{
  items = {
    {knife, 2},
    {fiver, 7},
    {tenpiece, 1},
  }
}

Drop.ultra_money = new{
  items = {
    {butterfly, 1},
    {fiver, 6},
    {tenpiece, 3},
  }
}

Drop.boss = new{
  health_up,
}

Drop.test = new{
  heart,
  knife,
  fiver,
  tenpiece,
  butterfly,
  health_up,
}

return Drop
