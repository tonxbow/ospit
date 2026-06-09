-- --- CLEANUP SECTION ---
if poll_timer then 
    poll_timer:unregister() 
    print("Previous timer killed.")
end
uart.on(2, "data") -- Reset listener

-- --- GLOBALS & CONFIG ---
local current_node = 1
local MAX_NODES = 4


for i = 1, MAX_NODES do
    _G["soiltemp" .. i] = -127
    _G["soilhumidity" .. i] = -127
end
-- --- CRC CALCULATION ---
function calculate_crc(data)
    local crc = 0xFFFF
    for i = 1, #data do
        local byte = string.byte(data, i)
        crc = bit.bxor(crc, byte)
        for j = 1, 8 do
            if bit.band(crc, 1) == 1 then
                crc = bit.bxor(bit.rshift(crc, 1), 0xA001)
            else
                crc = bit.rshift(crc, 1)
            end
        end
    end
    return string.char(bit.band(crc, 0xFF), bit.rshift(crc, 8))
end

-- --- LISTENER ---
local rx_buffer = ""
uart.on(2, "data", 0, function(data)
    rx_buffer = rx_buffer .. data
    
    -- Standard Modbus RTU response for 2 registers is 7-9 bytes depending on implementation
    if #rx_buffer >= 9 then
        local mbnode_id = string.byte(rx_buffer, 1)
        local func_code = string.byte(rx_buffer, 2)

        if func_code == 0x03 then
            local h_raw = string.byte(rx_buffer, 4) * 256 + string.byte(rx_buffer, 5)
            local t_raw = string.byte(rx_buffer, 6) * 256 + string.byte(rx_buffer, 7)
            
            -- Signed Integer Conversion
            if t_raw > 32767 then t_raw = t_raw - 65536 end
            
            -- Set Global Variables dynamically
            _G["soiltemp" .. mbnode_id] = t_raw / 10
            _G["soilhumidity" .. mbnode_id] = h_raw / 10
            
            print(string.format("[NODE %d] Temp: %.1f°C | Hum: %.1f%%", 
                mbnode_id, _G["soiltemp"..mbnode_id], _G["soilhumidity"..mbnode_id]))
        end
        rx_buffer = "" -- Clear buffer after processing
    end
end)

-- --- THE POLLER (Round Robin) ---
mbpoll_timer = tmr.create()
mbpoll_timer:alarm(2000, tmr.ALARM_AUTO, function()
    rx_buffer = "" -- Flush buffer before every new request to start fresh
    -- Request 2 registers starting at address 0x0000
    local msg = string.char(current_node, 0x03, 0, 0, 0, 2)
    local full_request = msg .. calculate_crc(msg)
    
    uart.write(2, full_request)
    
    -- Increment node for next cycle
    current_node = current_node + 1
    if current_node > MAX_NODES then
        current_node = 1
    end
    
end)

print("Multi-sensor system started. Polling IDs 1-4 every 2 seconds...")
