local modem, eeprom = component.proxy(component.list("modem")()),
    component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local ac, ma, DOWN, UP, SOUTH, EAST, WEST = { "", "", "", "", "" }, "", 0, 1, 3, 4, 5
local activeColors = { [0] = "", [1] = "", [3] = "", [4] = "", [5] = "" }
local fs = {}
local stat = {}
modem.broadcast(6002, add)
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

modem.open(2)
modem.open(1)
while true do
    local e, _, from, port, _, m = computer.pullSignal()


    if e == "modem_message" then
        if port == 2 then
            message = unserialize(m)

            if message.addr == add then
                if message.wert == "start" then
                else
                table.insert(fs, message.wert)
                end
            elseif message.addr == "all" then
                if message.wert == "start" then
                    modem.broadcast(6002, serialize(fs))
                    start = 1

                    modem.broadcast(2, serialize({ addr = "fs", wert = "start" }))
                end
            end

       else
    message = unserialize(m)
    stat[message.name] = message.wert
   
    for i, fs_entry in ipairs(fs) do
        if type(fs_entry) == "table" then
            for fahrweg_name, stell_all in pairs(fs_entry) do
                if type(stell_all) == "table" then
                    local all_match = true
                    for signal_name, required_value in pairs(stell_all) do
                        if stat[signal_name] ~= required_value then
                            all_match = false
                            break
                        end
                    end
                    if all_match then
                        modem.broadcast(6002, fahrweg_name)
                        modem.broadcast(6002, "TREFFER: " .. fahrweg_name)
                    end
                else
                    modem.broadcast(6002, "FEHLER: stell_all ist kein Table für " .. tostring(fahrweg_name))
                end
            end
        else
            modem.broadcast(6002, "FEHLER: fs_entry " .. i .. " ist kein Table  "..fs_entry)
        end
    end
end
    end
end
