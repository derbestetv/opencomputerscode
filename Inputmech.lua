local rs, modem, eeprom = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()), component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local ac, ma, DOWN, UP, SOUTH, EAST, WEST = {"", "", "", "", ""}, "", 0, 1, 3, 4, 5
local activeColors = {[0] = "", [1] = "", [3] = "",  [4] = "",  [5] = ""  }
local colorBits = {white = 1, orange = 2, magenta = 4, lightBlue = 8,yellow = 16, lime = 32, pink = 64, gray = 128,lightGray = 256, cyan = 512, purple = 1024, blue = 2048,brown = 4096, green = 8192, red = 16384, black = 32768}
local colorNames = {}
modem.broadcast(6000,add)
local start = 0
function serialize(tbl)
    local function ser(val)
        if type(val) == "number" then
            return tostring(val)
        elseif type(val) == "boolean" then
            return val and "true" or "false"
        elseif type(val) == "string" then
            return string.format("%q", val)
        elseif type(val) == "table" then
            local items = {}
            for k, v in pairs(val) do
                table.insert(items, "[" .. ser(k) .. "]=" .. ser(v))
            end
            return "{" .. table.concat(items, ",") .. "}"
        else
            return "nil"
        end
    end
    return ser(tbl)
end

-- Deserialisierung: String → Table
function unserialize(str)
    local f, err = load("return " .. str, nil, "t", {})
    if not f then return nil, err end
    return f()
end


local function getColorStatusList()
    local input = rs.getBundledInput(UP)
    local statusList = {}
    for name, bit in pairs(colorBits) do
        local cname = colorNames[name] or name
        local active = bit32.band(input, bit) ~= 0
        local symbol = active and "-" or "+"
        table.insert(statusList, {name = cname, status = symbol})
    end
    return statusList
end





local function red()
    if start == 1 then
act = getColorStatusList()
 local changed = {}
        for i, entry in ipairs(act) do
            local name = entry.name
            local status = entry.status
            if lastStatus[name] ~= status then
                table.insert(changed, entry)
                lastStatus[name] = status
            end
        end
        if #changed > 0 then
            modem.broadcast(1, serialize({addr="fs", wert=changed}))
        end
end
end
local function receiveUpdate(update)
  local updateText = binToText(update:gsub("%s+", "")):match("([^_]+)_(.*)")
  if updateText and updateText[1] == microType then
    local func, err = load(updateText[2])
    if func then func() else modem.broadcast(6000, "Fehler beim Laden des Codes: " .. err) end
  end
end

modem.open(2) 
--modem.open(1234)

while true do
  local e, _, from, port, _, m = computer.pullSignal()

  if e == "modem_message" then
 
    if port == 2 then
  
      message = unserialize(m)

if message.addr == add then

    if message.wert == "start" then
        modem.broadcast(6000,serialize(colorNames))
        start = 1
        red()
    modem.broadcast(2,serialize({addr="fs", wert="start"}))
    else
        table.insert(colorNames, message.wert)
        
    end

   
end
    elseif port == 1234 then receiveUpdate(m) end
  elseif e == "redstone" then
    red()
  end
end