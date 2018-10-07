return function(filename, dir)
  if type(filename) ~= 'string' then
    error('filename is not a string', 2)
  end

  local info = love.filesystem.getInfo(dir)
  if not (info and info.type == 'directory') then
    return false, 'directory "' .. dir .. '" does not exist'
  end

  local fullpath = dir .. filename

  local info = love.filesystem.getInfo(fullpath)
  if not info then
    return false, 'file "' .. fullpath .. '" does not exist'
  else
    if info.type ~= 'file' then
      return false, 'file "' .. fullpath .. '" is a ' .. tostring(info.type) .. ', not a file'
    end
  end

  return love.filesystem.read(fullpath)
end
