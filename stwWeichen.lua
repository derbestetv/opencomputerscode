local redstone, modem, eeprom = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()),component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local PORT = 1234
local zustaendigkeit = {}
local colorBits = { "white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown", "green", "red", "black" }
local REDSTONE_SIDE = 5

modem.open(PORT)



local function serialize(tbl)
  local function ser(val)
    if type(val) == "number" then return tostring(val)
    elseif type(val) == "boolean" then return val and "true" or "false"
    elseif type(val) == "string" then 
      return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    elseif type(val) == "table" then
      local items = {}
      for k, v in pairs(val) do
        items[#items + 1] = "[" .. ser(k) .. "]=" .. ser(v)
      end
      return "{" .. table.concat(items, ",") .. "}"
    else return "nil" end
  end
  return ser(tbl)
end

local function unserialize(str)
  local f = load("return " .. str)
  if not f then return nil end
  return f()
end

local function setRedstone(lage, id)
    for i , MY_ID in ipairs(zustaendigkeit) do
        if id ~= MY_ID then return end
        if lage == "-" then
            redstone.setBundledOutput(REDSTONE_SIDE, i, 255)
            
            return
        end
        redstone.setBundledOutput(REDSTONE_SIDE, i, 0)
    end
end

modem.broadcast(PORT, serialize({event = "zustaendigkeit_request", id = add}))

while #zustaendigkeit == 0 do
  local eventType, _, from, port, _, message = computer.pullSignal()
  
  if eventType ~= "modem_message" then goto continue end
  if port ~= PORT then goto continue end
  
  local data = unserialize(message)
  if not data then goto continue end
   if data.id ~= add then goto continue end
    if data.event == "zustaendigkeit_response" and data.id == add then
    zustaendigkeit = data.zustaendigkeit
     modem.broadcast(PORT, serialize({event = "ack", id = add, zustaendigkeit = data.zustaendigkeit}))
  end
  
  ::continue::
end
 for i , MY_ID in ipairs(zustaendigkeit) do
modem.broadcast(PORT, serialize({event = "request_lage", id = MY_ID}))
 end

while true do
  local eventType, _, from, port, _, message = computer.pullSignal()
  
  if eventType ~= "modem_message" then goto continue end
  if port ~= PORT then goto continue end
  
  local data = unserialize(message)
  if not data then goto continue end
  for i , MY_ID in ipairs({zustaendigkeit}) do
  if data.id ~= MY_ID then goto continue end
  end

  if data.event == "umstellauftrag" or data.event == "lage_response" then
    setRedstone(data.lage, data.id)
    modem.broadcast(PORT, serialize({event = "ack", id = data.id, lage = data.lage}))
 
  end
  
  ::continue::
end