-- global.lua
-- Creates a function for making globals, and errors if you try to access
-- an uninitialized global. This will catch a lot of typoes and adds
-- intentionality to global declarations/initializations.

function global(name, value)
  rawset(_G, name, value)
end

  function requireGlobal(name)
  global(name, require(name))
end

local mt = getmetatable(_G)

if not mt then
  mt = {}
  setmetatable(_G, mt)
end

mt.__newindex = function(self, key, value)
  if key == '_' then
    rawset(self, key, value)
  else
    error('Attempt to create a new global "' .. tostring(key) .. '" without using "global"', 2)
  end
end

mt.__index = function(self, key)
  if key == '_' then
    print('warning: value of special global "_" read')
    return rawget(self, key)
  else
    error('Attempt to access uninitialized variable "' .. tostring(key) .. '"', 2)
  end
end
