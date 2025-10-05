local modem, eeprom = component.proxy(component.list("modem")()),
    component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local ac, ma, DOWN, UP, SOUTH, EAST, WEST = { "", "", "", "", "" }, "", 0, 1, 3, 4, 5
local activeColors = { [0] = "", [1] = "", [3] = "", [4] = "", [5] = "" }
local fs = {}
local stat = {}
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

modem.open(2)
modem.open(1)
while true do
    local e, _, from, port, _, m = computer.pullSignal()


    if e == "modem_message" then
        if port == 2 then
            message = unserialize(m)

            if message.addr == add then
                table.insert(fs, message.wert)
            elseif message.addr == "all" then
                if message.wert == "start" then
                    modem.broadcast(6001, serialize(fs))
                    start = 1

                    modem.broadcast(2, serialize({ addr = "fs", wert = "start" }))
                end
            end

        else
            --{1 = {F1={...}},2={F2={...}},...}
            --{F1={...}}
            message = unserialize(m)
            stat[message.name] = message.wert
            for i, fs_entry in ipairs(fs) do
                -- fs_entry ist: {F1 = {W11 = "-", W10 = "+", ...}}
                for fahrweg_name, stell_all in pairs(fs_entry) do
                    -- fahrweg_name ist: "F1"
                    -- stell_all ist: {W11 = "-", W10 = "+", ...}

                    if type(stell_all) == "table" then
                        local all_match = true
                        for signal_name, required_value in pairs(stell_all) do
                            if stat[signal_name] ~= required_value then
                                all_match = false
                                break
                            end
                        end
                        if all_match then
                            modem.broadcast(6001, fahrweg_name)
                            modem.broadcast(6000, "TREFFER: " .. fahrweg_name)
                        end
                    end
                end
            end
        end
    end
end
