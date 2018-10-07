return function(name)
  local class = {}

  class.class = name

  class.__index = function(table, key)
    local value = rawget(table, key)
    if value == nil then
      value = rawget(class, key)
    end
    --if value == nil then
      --value = rawget(class, key)
    --end
    if value == nil then
      error(
        'Attempt to access non-existant member ' .. key ..
        ' of class ' .. (rawget(class, 'class') or 'unknown class'),
        2
      )
    end
    return value
  end

  function class:has(member)
    local value = rawget(self, member)
    if value == nil then
      value = rawget(class, member)
    end
    return value
  end

  function class:new(template)
    return class.inherit(class.template or {}, template)
  end

  function class:dup()
    return class.inherit({}, self)
  end

  function class:inherit(template)
    for k, v in pairs(template) do
      if type(v) == 'table' then
        if type(v.dup) == 'function' then
          self[k] = v:dup()
        else
          print(k, v, v.dup, v.class)
          error'no dup function found during recursive dup'
        end
      else
        self[k] = v
      end
    end

    setmetatable(self, class)

    if class.init then
      self:init(template)
    end

    return self
  end

  return class
end
