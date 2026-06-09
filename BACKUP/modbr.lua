-- --- CLEANUP SECTION ---
if mbpoll_timer then 
    mbpoll_timer:stop() 
    printv(1,"Previous Modbus read timer killed.")
end
uart.on(2, "data") -- Reset listener

-- --- GLOBALS & CONFIG ---
local current_node = 1
local MAX_NODES = 4
local response_received = true -- State tracking

-- Initialize data with "Unknown" state
for i = 1, MAX_NODES do
    _G["stemp" .. i] = -127
    _G["shumidity" .. i] = -127
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

-- --- TIMEOUT WATCHDOG ---
-- This runs 1 second after a request. If no data came back, it wipes the globals.
local irrwatchdog = tmr.create()
local function handle_timeout()
    if not response_received then
        _G["stemp" .. current_node] = -127
        _G["shumidity" .. current_node] = -127
        printv(2, string.format("![TIMEOUT] Node %d is offline", current_node))
    end
end

-- --- LISTENER ---
local rx_buffer = ""
uart.on(2, "data", 0, function(data)
    rx_buffer = rx_buffer .. data
    
    -- Standard Modbus RTU response (approx 9 bytes)
    if #rx_buffer >= 9 then
        local mbnode_id = string.byte(rx_buffer, 1)
        local func_code = string.byte(rx_buffer, 2)

        if func_code == 0x03 and mbnode_id == current_node then
            response_received = true -- Mark as successful
            
            local h_raw = string.byte(rx_buffer, 4) * 256 + string.byte(rx_buffer, 5)
            local t_raw = string.byte(rx_buffer, 6) * 256 + string.byte(rx_buffer, 7)
            
            -- Signed Integer Conversion
            if t_raw > 32767 then t_raw = t_raw - 65536 end
            
            -- Set Global Variables
            _G["stemp" .. mbnode_id] = t_raw / 10
            _G["shumidity" .. mbnode_id] = h_raw / 10
            
            printv(2,string.format("[NODE %d] Temp: %.1f°C | Hum: %.1f%%", 
                mbnode_id, _G["stemp"..mbnode_id], _G["shumidity"..mbnode_id]))
        end
        rx_buffer = "" -- Clear buffer
    end
end)

-- --- THE POLLER (Round Robin) ---
mbpoll_timer = tmr.create()
mbpoll_timer:alarm(4000, tmr.ALARM_AUTO, function()
    -- 1. Advance to next node
    current_node = current_node + 1
    if current_node > MAX_NODES then current_node = 1 end
    
    -- 2. Reset tracking state
    rx_buffer = ""
    response_received = false
    
    -- 3. Send Request
    local msg = string.char(current_node, 0x03, 0, 0, 0, 2)
    local full_request = msg .. calculate_crc(msg)
    uart.write(2, full_request)
    
    -- 4. Start the watchdog timer (wait 1000ms for a reply)
    irrwatchdog:stop() -- Reset watchdog if it was running
    irrwatchdog:alarm(1000, tmr.ALARM_SINGLE, handle_timeout)
end)

printv(2,"System Active. Monitoring 4 nodes with timeout protection...")
