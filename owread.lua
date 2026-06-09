dofile"owids.lua"



-- Configuration: Mapping Global IDs to Global Variable Names
local sensor_config = {
    [airtemp_id  or ""] = "airtemp",
    [batttemp_id or ""] = "battery_temperature",
    [pcbtemp_id  or ""] = "heatsink_temperature"
}

local function read_thermal_monitors(pin)
    ow.setup(pin)
    
    -- 1. Broadcast Convert T to all sensors
    ow.reset(pin)
    ow.skip(pin)
    ow.write(pin, 0x44)

    -- 2. Non-blocking wait for conversion
    tmr.create():alarm(750, tmr.ALARM_SINGLE, function()
        -- Reset globals to -127 at start of scan to clear stale data
        airtemp  = -127
        battery_temperature= -127
        heatsink_temperature  = -127

        ow.reset_search(pin)
        local addr = ow.search(pin)
        
        -- Loop handles 0, 1, or many sensors without crashing
        while addr ~= nil do
            local crc = ow.crc8(string.sub(addr, 1, 7))
            if crc == addr:byte(8) then
                local id_hex = string.format("%02x%02x%02x%02x%02x%02x%02x%02x", addr:byte(1,8))
                local var_name = sensor_config[id_hex]

                if var_name then
                    ow.reset(pin)
                    ow.select(pin, addr)
                    ow.write(pin, 0xBE)

                    local data = ""
                    for i = 1, 9 do
                        data = data .. string.char(ow.read(pin))
                    end

                    if ow.crc8(string.sub(data, 1, 8)) == data:byte(9) then
                        local t = (data:byte(1) + data:byte(2) * 256)
                        if t > 32767 then t = t - 65536 end
                        local celsius = t * 0.0625
                        
                        -- Update the global variable for other programs
                        _G[var_name] = celsius
                    end
                end
            end
            addr = ow.search(pin)
        end
        
        ow.reset_search(pin)
        
        local airtemp2 = airtemp * 10 
        airtemp2 = math.floor(airtemp2)
        airtemp = airtemp2 / 10
        

        -- Debug output to console
        printv(2,string.format("Temps: Air=%.2f, Batt=%.2f, PCB=%.2f", airtemp, battery_temperature, heatsink_temperature))
        
    end)
end

-- Example Call
read_thermal_monitors(2)
