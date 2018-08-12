local Moblist = simpleClass'Moblist'

function Moblist:new(t)
  local moblist = {}
  setmetatable(moblist, Moblist)
  for i, v in ipairs(t) do
    moblist:insert(v)
  end
  return moblist
end

function Moblist:insert(mob)
  if type(mob) ~= 'table' then
    error'invalid arguments'
  end
  if mob.class ~= 'Mob' then
    error'inserting multiple mobs not implemented'
    if #mob < 1 then
    end
  else
    for i = #self, 1, -1 do
      if self[i] == mob then
        error'tried to insert mob twice'
      end
    end
    mob.moblist = self
    return table.insert(self, mob)
  end
end

function Moblist:remove(which)
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

function Moblist:removeAll()
  for i = #self, 1, -1 do
    self[i] = nil
  end
end

function Moblist:handleCollision()
  error'not yet implemented'
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
  self:removeDead()
end

function Moblist:removeDead()
  for i, v in ipairs(self) do
    if v:isDead() then
      local mobs = v:doDeath()
      moblist:remove(i)
      for _, mob in ipairs(mobs) do
        moblist:insert(mob)
      end
    end
  end
end

return Moblist
