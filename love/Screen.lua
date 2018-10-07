local Screen = {}
Screen.__index = Screen

function Screen:getMousePosition()
  local pos = Vector:new{self.x, self.y}
  local rawMouse = Vector:new{love.mouse.getPosition()}
  return (rawMouse - pos) / self.scale
end

function Screen:window_size(w, h)
  self.center.x = math.floor(w / 2)
  self.center.y = math.floor(h / 2)
  self.scale = math.floor(math.min(w / self.minw, h / self.minh))
  self.scale = math.max(self.scale, 1)
  self.x = self.center.x - math.floor(self.width / 2) * self.scale
  self.y = self.center.y - math.floor(self.height / 2) * self.scale
end

function Screen:update_window()
  local w, h, f = love.window.getMode()
  f.minwidth = self.minw
  f.minheight = self.minh
  love.window.setMode(w, h, f)
end

function Screen:renderTo(func)
  self.canvas:renderTo(func)
end

function Screen:draw(x, y)
  love.graphics.draw(self.canvas, self.x + (x or 0), self.y + (y or 0), 0, self.scale, self.scale)
end

function Screen:new(w, h, border)
  local screen = {
    x = 0,
    y = 0,
    scale = 3,
    width = w,
    height = h,
  }

  screen.canvas = love.graphics.newCanvas(screen.width, screen.height)

  if border then
    screen.minw = math.floor(screen.width / border + 2) * border
    screen.minh = math.floor(screen.height / border + 2) * border
  else
    screen.minw = screen.width
    screen.minh = screen.height
  end

  screen.center = Vector:new{
    math.floor(love.graphics.getWidth() / 2),
    math.floor(love.graphics.getHeight() / 2),
  }

  setmetatable(screen, Screen)

  return screen
end

return Screen
