local redstone, modem, eeprom = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()),component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local PORT = 1234
local zustaendigkeit = {}
local colorBits = { "white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown", "green", "red", "black" }
local colorValues = { 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000, 0x4000, 0x8000 }  -- colors API values
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
    for i, MY_ID in ipairs(zustaendigkeit) do
        if tonumber(id) == tonumber(MY_ID) then
            local colorValue = colorValues[i]  -- Get the actual color API value
            local level = (lage == "-") and 15 or 0
            redstone.setBundledOutput(REDSTONE_SIDE, colorValue, level)
            modem.broadcast(9999, "Set redstone for ID " .. id .. " color " .. colorBits[i] .. " to " .. level)
            return
        end
    end
    modem.broadcast(9999, "ID " .. id .. " not found in zustaendigkeit")
end

modem.broadcast(PORT, serialize({event = "zustaendigkeit_request", id = add}))

while #zustaendigkeit == 0 do
  local eventType, _, from, port, _, message = computer.pullSignal()
  
  if eventType ~= "modem_message" then goto continue end
  if port ~= PORT then goto continue end
  modem.broadcast(9999,#zustaendigkeit.."   ID    "..message)
  local data = unserialize(message)
  if not data then goto continue end
   if data.id ~= add then goto continue end
    if data.event == "zustaendigkeit_response" and data.id == add then
    zustaendigkeit = unserialize(data.zustaendigkeit)
     modem.broadcast(PORT, serialize({event = "ack", id = add, zustaendigkeit = data.zustaendigkeit}))
  end
  
  ::continue::
end

for i , MY_ID in ipairs(zustaendigkeit) do
  modem.broadcast(9999,"request_lage    "..MY_ID)
  modem.broadcast(PORT, serialize({event = "request_lage", id = MY_ID}))
end

while true do
  local eventType, _, from, port, _, message = computer.pullSignal()
  
  if eventType ~= "modem_message" then goto continue end
  if port ~= PORT then goto continue end
  
  local data = unserialize(message)
  if not data then goto continue end
  
  local dataId = tonumber(data.id) or data.id
  
  local isResponsible = false
  for i, MY_ID in ipairs(zustaendigkeit) do
    if dataId == MY_ID then
      isResponsible = true
      break
    end
  end
  
  if not isResponsible then goto continue end
  
  if data.event == "umstellauftrag" or data.event == "lage_response" then
    modem.broadcast(9999, "umstellauftrag " .. tostring(dataId))
    setRedstone(data.lage, dataId)
    modem.broadcast(PORT, serialize({event = "ack", id = dataId, lage = data.lage}))
  end
  
  ::continue::
end