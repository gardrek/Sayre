function moblist:insert(mob)
  for i = #self, 1, -1 do
    if self[i] == mob then
      error'tried to insert mob twice'
    end
  end
  mob.moblist = self
  return table.insert(self, mob)
end

function moblist:remove(which)
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

function moblist:remove_all()
  for i = #self, 1, -1 do
    self[i] = nil
  end
end

function moblist:handle_collision()
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
  self:remove_dead()
end

function moblist:remove_dead()
  for i, v in ipairs(self) do
    if v:is_dead() then
      local mobs = v:do_death()
      moblist:remove(i)
      for _, mob in ipairs(mobs) do
        moblist:insert(mob)
      end
    end
  end
end

