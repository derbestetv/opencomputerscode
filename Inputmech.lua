local rs, modem, eeprom = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()),
    component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local ac, ma, DOWN, UP, SOUTH, EAST, WEST = { "", "", "", "", "" }, "", 0, 1, 3, 4, 5
local activeColors = { [0] = "", [1] = "", [3] = "", [4] = "", [5] = "" }
local colorBits = { "white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown","green", "red", "black" }
local colorNames = {}
modem.broadcast(6000, add)
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
    local input = rs.getBundledInput()[UP]
    modem.broadcast(6000, "input  "..serialize(colorBits))
    local statusList = {}
    for i, color in ipairs(colorBits) do
        if input[i] > 0 then
            local active = true
        else
            local active = false
        end
        local cname = ""
        for i, color1 in ipairs(colorNames) do
            if color1["color"] == color then
             cname = color1["name"] 
            break
            end
        end
        
        local symbol = active and "-" or "+"
        modem.broadcast(6000,"status  ".. serialize({ name = cname, status = symbol }))
        table.insert(statusList, { name = cname, status = symbol })
    end
    return statusList
end



local function red1()

        act = getColorStatusList()
        local changed = {}
        for i, entry in ipairs(act) do
            local name = entry.name
            local status = entry.status
            if lastStatus[name] ~= status then
                modem.broadcast(1, serialize({ addr = "fs", wert = { name = status } }))
                lastStatus[name] = status
            end
        end
  
end


local function red(start1)
    if start1 == 1 then
        act = getColorStatusList()
        local changed = {}
        for i, entry in ipairs(act) do
            local name = entry.name
            local status = entry.status
            if lastStatus[name] ~= status then
                modem.broadcast(1, serialize({ addr = "fs", wert = { name = status } }))
                lastStatus[name] = status
            end
        end
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
                    
                    start = 1
                    red1()
                    modem.broadcast(2, serialize({ addr = "fs", wert = "start" }))
                else
                    table.insert(colorNames, message.wert)
                end
            end
        end
    elseif e == "redstone" then
        red(start)
    end
end
