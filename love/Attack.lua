local Attack = {}
Attack.__index = Attack

Attack.damage_types = {
  'slash',
  'blunt',
  'fire',
  'blast',
}

Attack.isDamageType = {}

for _, name in ipairs(Attack.damage_types) do
  Attack.isDamageType[name] = true
end

Attack.effect_types = {
  'knockback',
  'stun',
}

Attack.isEffectType = {}

for _, name in ipairs(Attack.effect_types) do
  Attack.isEffectType[name] = true
end

function Attack:new(t, n)
  local obj = t
  if type(t) == 'string' then
    obj = {
      damage = {},
      effect = {},
    }
    if type(n) ~= 'number' then
      error('damage/effect must be a number (is ' .. tostring(n) .. ', a ' .. type(n), 2)
    end
    if Attack.isDamageType[t] then
      obj.damage[t] = n
    elseif Attack.isEffectType[t] then
      obj.effect[t] = n
    else
      error('invalid damage type ' .. t, 2)
    end
  end
  if type(obj)  ~= 'table' then
    error('invalid arguments', 2)
  end
  return Attack.dup(obj)
end

function Attack:dup()
  local dmg = {}
  local damage = {}
  dmg.damage = damage
  for type, v in pairs(self.damage) do
    damage[type] = v
  end
  return setmetatable(dmg, Attack)
end

local function calculate_damage(damage, multiplier, resistance)
  return math.floor(math.max(0, damage * (multiplier) - resistance))
end

function Attack:calculate_damage(type, multiplier, resistance)
  multiplier = multiplier or 1
  resistance = resistance or 0
  local damage = calculate_damage(self.damage[type], multiplier, resistance)
  return damage
end

function Attack:calculate_effect(type, multiplier, resistance)
  multiplier = multiplier or 1
  resistance = resistance or 0
  local effect = calculate_damage(self.effect[type], multiplier, resistance)
  return effect
end

return Attack
