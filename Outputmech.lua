local rs, modem, eeprom = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()), component.proxy(component.list("eeprom")())
local add, microType = eeprom.getLabel(), eeprom.getLabel():match("([^%s]+)")
local ac, ma, DOWN, UP, SOUTH, EAST, WEST = {"", "", "", "", ""}, "", 0, 1, 3, 4, 5
local activeColors = {[0] = "", [1] = "", [3] = "",  [4] = "",  [5] = ""  }

local colorBits = {white = 1, orange = 2, magenta = 4, lightBlue = 8, yellow = 16, lime = 32, pink = 64, gray = 128, lightGray = 256, cyan = 512, purple = 1024, blue = 2048, brown = 4096, green = 8192, red = 16384, black = 32768}
local colorNames = {}

function unserialize(str)
    local tbl = {}
    for part in str:gmatch("([^;]+)") do
        local k, v = part:match("([^:]+):(.+)")
        if k and v then
            if v:match("^%d+$") then
                tbl[k] = tonumber(v)
            elseif v == "1" then
                tbl[k] = true
            elseif v == "0" then
                tbl[k] = false
            elseif v:match("^'(.*)'$") then
                tbl[k] = v:match("^'(.*)'$")
            else
                tbl[k] = v
            end
        end
    end
    return tbl
end

modem.open(1)
modem.open(2)
modem.open(11)

while true do
    local e, _, from, port, _, msg = computer.pullSignal()
    if e == "modem_message" then
        if port == 1 or port == 11 then
            local data = unserialize(msg)
            if type(data.wert) == "table" and data.addr == adr then
                for _, entry in ipairs(data.wert) do
                    -- Suche das Bit zur Farbe (über Mapping oder Standard)
                    local bit = nil
                    for cname, cbit in pairs(colorBits) do
                        if entry.name == colorNames[cname] or entry.name == cname then
                            bit = cbit
                            break
                        end
                    end
                    if bit then
                        if entry.status == "-" then
                            rs.setBundledOutput(1, bit32.bor(rs.getBundledOutput(1), bit))
                        else
                            rs.setBundledOutput(1, bit32.band(rs.getBundledOutput(1), bit32.bnot(bit)))
                        end
                    end
                end
            end
        elseif port == 2 then
            -- Farbnamen-Mapping empfangen wie im Input
            local data = unserialize(msg)
            if data and data.wert then
                colorNames = unserialize(data.wert)
            end
        end
    end
end