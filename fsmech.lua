local modem, eeprom =  component.proxy(component.list("modem")()),
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
                    
                
            elseif message.addr =="all" then
                if message.wert == "start" then
                    --modem.broadcast(6001, serialize(fs))
                    start = 1
                    
                    modem.broadcast(2, serialize({ addr = "fs", wert = "start" }))
                end
            end
        else
            --{1 = {F1={...}},2={F2={...}},...}
            --{F1={...}}
                stat[message.name] = message.wert
            for i, fs1 in ipairs(fs) do
                for key1,stellall in pairs(fs1) do
                    for key,stell in pairs(stellall) do
                        if stat[key] == stell then
                        modem.broadcast(6001, key1)
                        end
                    end
                    
                end
             end
            
        end
    end

end
