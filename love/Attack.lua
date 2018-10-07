local Attack = {}
Attack.__index = Attack

Attack.damage_types = {
  'slash',
  'blunt',
  'fire',
  'blast',
  'pierce',
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

Attack.isType = {}

for _, name in ipairs(Attack.damage_types) do
  Attack.isType[name] = true
end

for _, name in ipairs(Attack.effect_types) do
  Attack.isType[name] = true
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
  local damage = {}
  for type, v in pairs(self.damage) do
    damage[type] = v
  end
  local effect = {}
  for type, v in pairs(self.effect) do
    effect[type] = v
  end
  return setmetatable({
    damage = damage,
    effect = effect,
  }, Attack)
end

local function calculate_final(damage, multiplier, reduction)
  return math.floor(math.max(0, damage * multiplier - reduction))
  --return math.floor(math.max(0, math.max(1, damage * multiplier) - reduction))
  --return math.floor(math.max(0, math.ceil(damage * multiplier) - reduction))
end

function Attack:calculate_damage(type, multiplier, reduction)
  multiplier = multiplier or 1
  reduction = reduction or 0
  local damage = calculate_final(self.damage[type], multiplier, reduction)
  return damage
end

function Attack:calculate_effect(type, multiplier, reduction)
  multiplier = multiplier or 1
  reduction = reduction or 0
  local effect = calculate_final(self.effect[type], multiplier, reduction)
  return effect
end

return Attack
