local Input = Class'Input'

Input.devices = {
  'keyboard', --'mouse', 
}

for i, v in ipairs(Input.devices) do
  Input.devices[v] = true
end

Input.inputs = {
  controller = {
    'up', 'down', 'left', 'right',
    'action_a', 'action_b', 'action_x', 'action_y',
    'shoulder_left', 'shoulder_right', 'start', 'select',
  },
  vm = {
    'pause', 'restart',
  },
  editor ={
    -- ...
  },
  debug = {
    'test1', 'test2',
  },
}

local classNew = Input.new

local genericDup = recursive_copy
--[[function(self)
  local obj = {}
  for k, v in pairs(self) do
    if type(v) == 'table' then  
      print(k)
      error''
    else
      obj[k] = v
    end
  end
  return obj
end]]

for _, v in pairs(Input.inputs) do
  v.dup = genericDup
end

function Input:new(input_set)
  local obj = {
    hold_time = {
      dup = genericDup,
    },
    value = {
      dup = genericDup,
    },
    binding = {
      dup = genericDup,
    },
  }

  if input_set then
    if type(input_set) == 'string' then
      local set = Input.inputs[input_set]
      if not set then
        error('unknown input set ' .. input_set, 2)
      end
      obj.inputs = set
    elseif type(input_set) == 'table' then
      obj.inputs = input_set
    else
      error('incorrect argument: must be a string or a table', 2)
    end
  else
    obj.inputs = Input.inputs.controller
  end

  for _, name in ipairs(obj.inputs) do
    obj.hold_time[name] = 0
  end

  --setmetatable(obj, Input)

  return classNew(Input, obj)
  --return setmetatable(Input.inherit({}, Input.template, Input))
end

function Input:update()
  local hold_time = self.hold_time
  local value = self.value
  for _, name in ipairs(self.inputs) do
    if self:isDown(name) then
      hold_time[name] = math.max(1, hold_time[name] + 1)
      value[name] = 1
    else
      hold_time[name] = math.min(0, hold_time[name] - 1)
      value[name] = 0
    end
  end
end

-- TODO: change bindings to be a list instead of only one key

function Input:isDown(name)
  local device, binding = unpack(self.binding[name])
  if device == 'keyboard' then
    return love.keyboard.isDown(binding)
  else
    error('incorrect binding')
  end
end

function Input:setBinding(name, device, binding)
  if Input.devices[device] then
    self.binding[name] = {device, binding}
  else
    error('invalid device ' .. tostring(device), 2)
  end
end

function Input:setPlayer1Binding_TEST()
  local bindings = {
    'up', 'down', 'left', 'right',
    'x', 'z', 's', 'a',
    'lshift', 'space', 'return', 'tab',
  }
  for i, name in ipairs(self.inputs) do
    self:setBinding(name, 'keyboard', bindings[i])
  end
end

return Input
