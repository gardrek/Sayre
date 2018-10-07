local Base32 = {}

local map = '0123456789abcdefghjkmnpqrstvwxyz'

-- Convert acceptable characters into canonical form and remove any other characters
-- If the resulting string's length is less than minlength (if it is given) then the string is padded to that lenght with zeroes
function Base32:normalize(str, minlength)
  str = str:lower():gsub("[il]",'1'):gsub("o",'0'):gsub("[^" .. map .. "]", '')
  if minlength and minlength > #str then
    str = str .. string.rep('0', minlength - #str)
  end
  return str
end

function Base32:strip_zero_tail(str)
  if type(str) == 'string' then
    if str ~= '' then
      str = str:gsub("0+$", '')
      if str == '' then str = '0' end
    end
  elseif type(str) == 'table' then
    local data = {}
    for i = 1, #str do
      data[i] = str[i]
    end
    for i = #data, #data - 8, -1 do
      if data[i] == 0 then
        data[i] = nil
      else
        break
      end
    end
    str = data
  else
    error''
  end
  return str
end

-- Turn an array of 5-bit values into a base32 string
function Base32:arrayToBase32(array)
  local encodedArray = {}
  for i, v in ipairs(array) do
    v = bit.band(v, 0x1f) + 1
    encodedArray[i] = map:sub(v, v)
  end
  return table.concat(encodedArray)
end

-- Turn a Base32 string into an array of 5-bit values
function Base32:base32ToArray(str)
  local array = {}
  for i = 1, #str do
    array[i] = map:find(str:sub(i, i), 1, true) - 1
  end
  return array
end

-- Turns an array of 8-bit values into and array of 5-bit values
function Base32:eightBitToFiveBit(array)
  local encodedArray = {}
  local buf = {}
  for i = 1, #array, 5 do
    for j = 0, 4 do
      buf[j] = array[i + j] or 0
    end
    table.insert(encodedArray, bit.rshift(bit.band(buf[0], 0xF8), 3))
    table.insert(encodedArray, bit.bor(bit.lshift(bit.band(buf[0], 0x07), 2), bit.rshift(bit.band(buf[1], 0xC0), 6)))
    table.insert(encodedArray, bit.rshift(bit.band(buf[1], 0x3E), 1))
    table.insert(encodedArray, bit.bor(bit.lshift(bit.band(buf[1], 0x01), 4), bit.rshift(bit.band(buf[2], 0xF0), 4)))
    table.insert(encodedArray, bit.bor(bit.lshift(bit.band(buf[2], 0x0F), 1), bit.rshift(buf[3], 7)))
    table.insert(encodedArray, bit.rshift(bit.band(buf[3], 0x7C), 2))
    table.insert(encodedArray, bit.bor(bit.lshift(bit.band(buf[3], 0x03), 3), bit.rshift(bit.band(buf[4], 0xE0), 5)))
    table.insert(encodedArray, bit.band(buf[4], 0x1F))
  end
  return encodedArray
end

function Base32:fiveBitToEightBit(array)
  local encodedArray = {}
  local buf = {}
  for i = 1, #array, 8 do
    for j = 0, 7 do
      buf[j] = array[i + j] or 0
    end
    table.insert(encodedArray, bit.band(bit.bor(bit.lshift(buf[0], 3), bit.rshift(buf[1], 2)), 0xFF))
    table.insert(encodedArray, bit.band(bit.bor(bit.lshift(buf[1], 6), bit.lshift(buf[2], 1), bit.rshift(buf[3], 4)), 0xFF))
    table.insert(encodedArray, bit.band(bit.bor(bit.lshift(buf[3], 4), bit.rshift(buf[4], 1)), 0xFF))
    table.insert(encodedArray, bit.band(bit.bor(bit.lshift(buf[4], 7), bit.lshift(buf[5], 2), bit.rshift(buf[6], 3)), 0xFF))
    table.insert(encodedArray, bit.band(bit.bor(bit.lshift(buf[6], 5), buf[7]), 0xFF))
  end
  return encodedArray
end

function Base32:encode(data)
  if type(data) == 'string' then
    data = {data:byte(1, #data)}
  elseif type(data) ~= 'table' then
    error'bad argument'
  end

  return
    self:arrayToBase32(
      self:eightBitToFiveBit(data)
    )
end

function Base32:decode(str)
  return self:fiveBitToEightBit(
    self:base32ToArray(
      self:normalize(str)
    )
  )
end

return Base32
