local Input = simpleClass'Input'

Input.controller_inputs = {
  'up', 'down', 'left', 'right',
  'action_a', 'action_b', 'action_x', 'action_y',
  'shoulder_left', 'shoulder_right', 'start', 'select',
}

Input.game_inputs = {
  'pause', 'restart',
}

Input.debug_inputs = {
  'test1', 'test2',
}

function Input:new(inputs)
  local obj = {
    hold_time = {},
    inputs = inputs or Input.controller_inputs,
  }

  for _, name in ipairs(inputs) do
    obj.hold_time[name] = 0
  end

  setmetatable(obj, Input)

  return obj
  --return setmetatable(Input.inherit({}, Input.template, Input))
end

function Input:update()
  local hold_time = self.hold_time
  for _, name in ipairs(self.inputs) do
    if Input:isDown(name)
      hold_time[name] = hold_time[name] + 1
    else
      hold_time[name] = 0
    end
  end
end

return Input
