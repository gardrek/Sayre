local Item = require 'Item'

local This = {}
This.class = 'Inventory'

function This.__index(table, key)
  local value = rawget(table, key)
  if not value then
    value = rawget(This, key)
  end
  if not value then
    value = rawget(This, key)
  end
  if not value then
    error(
      'Attempt to access non-existant member ' .. key ..
      ' of class ' .. (rawget(This, 'class') or 'UnkownClass'),
      2
    )
  end
  return value
end

This.template = {
  equipment = {
    left_hand = false,
    right_hand = false,
  },
  items = {},
  ammo = {},
}

function This:dup()
  return This:new(self)
end

function This:new(template)
  template = template or {}
  local instance = {}

  for k, v in pairs(self.template) do
    instance[k] = v
  end

  for k, v in pairs(template) do
    if This[k] then
      error('attempt to overwrite built-in ' .. k .. ' on class' .. This.class, 2)
    end
    if type(v) == 'table' then
      if k == 'equipment' or k == 'items' or k == 'ammo' then
        instance[k] = {}
        for slot, item in pairs(v) do
          instance[k][slot] = item
        end
      elseif type(v.dup) == 'function' then
        instance[k] = v:dup()
      else
        error''
      end
    else
      instance[k] = v
    end
  end

  setmetatable(instance, This)
  return instance
end

function This:add_item(item, count)
  if item.has_count then
    if self.ammo[item.name] and count then
      self.ammo[item.name] = self.ammo[item.name] + count
    else
      self.ammo[item.name] = count or 0
    end
  --else
    --self.items[item.name] = item
  end
  self.items[item.name] = item
  --self[#self] = item
end

function This:equip(slot, item)
  -- TODO: make sure the item is in our inventory
  self.equipment[slot] = item
end

function This:unequip(item)
  if type(item) == 'string' then
    self.equipment[item] = false
  else
    for k, v in pairs(self.equipment) do
      if v == item then
        self.equipment[k] =false
      end
    end
  end
end

return This

