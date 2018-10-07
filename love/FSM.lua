local FSM = Class'FSM'

function FSM:new(func)
  local obj = {}
  setmetatable(obj, FSM)
  obj.co = coroutine.create(func)
  obj:action'begin'
  return obj
end

function FSM:get()
  return self.state
end

function FSM:action(action, arg)
  local ok
  ok, self.state = coroutine.resume(self.co, action, arg)
  assert(ok, self.state)
end

function FSM:update()
  return self:action()
end

return FSM
