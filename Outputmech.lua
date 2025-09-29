local rs, modem, eeprom = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()), component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local ac, ma, DOWN, UP, SOUTH, EAST, WEST = {"", "", "", "", ""}, "", 0, 1, 3, 4, 5
local activeColors = {[0] = "", [1] = "", [3] = "",  [4] = "",  [5] = ""  }
local start = 0
local colorBits = { "white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown","green", "red", "black" }
local colorNames = {}
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

modem.open(1)
modem.open(2)
modem.open(11)

while true do
    local e, _, from, port, _, msg = computer.pullSignal()
    if e == "modem_message" then
        if port == 1 or port == 11 then
            local data = unserialize(msg)
            for i, color in ipairs(colorBits) do
                if color == data.name then
                    if data.wert == "+" then
                       rs.setBundledOutput(UP, i,0) 
                    else
                       rs.setBundledOutput(UP, i,255) 
                    end
                    
                end
                
            end
        elseif port == 2 then
            message = unserialize(msg)

            if message.addr == add then
                if message.wert == "start" then
                    
                    start = 1
                 
                    modem.broadcast(2, serialize({ addr = "fs", wert = "start" }))

                
                else
                    table.insert(colorNames, message.wert)
                    
                end
            end
        end
        
    end
end