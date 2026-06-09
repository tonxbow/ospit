-- modb-set-nodeid.lua

-- If the modbus reading program modbr.lua is running, we need to stop it't timer
if mbpoll_timer then 
    mbpoll_timer:unregister() 
    printv(2,"Previous timer of modbr.lua killed. Restart the OSPIT after you have finished preparing the sensor(s)")
end

if MB_OLD_ID == nil then print("\n\nMB_OLD_ID missing!\n") end 
if MB_NEW_ID == nil then print("MB_NEW_ID missing!\n") end
if MB_OLD_ID == nil or  MB_NEW_ID == nil or MB_OLD_ID == MB_NEW_ID then print("USAGE:\n\n Set old and new global node-id variables for the RTU-Modbus\n before running this script.\n\nExample:\n\nMB_OLD_ID=1\n\nMB_NEW_ID=2\n\ndofile\"modb-set-nodeid.lua\"\n\n\nMAKE SURE TO ONLY HAVE ONE MODBUS SENSOR CONNECTED\nTO THE MODBUS WHILE DOING THIS,\nOR BE PREPARED FOR TROUBLESHOOTING!") do return end end

if MB_OLD_ID == 0 or  MB_NEW_ID == 0 then print("Do not try to write to the broadcast Modbus node address \n or try to set the broadcast Modbus address to a node!") do return end end


local TARGET_REG = 0x07D0

if mbpoll_timer then mbpoll_timer:stop() end

-- --- CRC FUNCTION ---
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



function set_slave_id(new_id)
    local addr_hi = bit.rshift(TARGET_REG, 8)
    local addr_lo = bit.band(TARGET_REG, 0xFF)
    local val_hi  = 0x00
    local val_lo  = new_id

    -- Function Code 06: Write Single Register
    local msg = string.char(MB_OLD_ID, 0x06, addr_hi, addr_lo, val_hi, val_lo)
    local packet = msg .. calculate_crc(msg)
    
    print(string.format("Changing ID to %d... TX: %s", new_id, encoder.toHex(packet)))
    print("------------------------------------------")
    print(string.format("Command sent: %d -> %d", MB_OLD_ID, new_id))
    print("Wait 2 seconds, then update your poller script.")
    print("------------------------------------------")
    
    -- Cleanup globals so you don't accidentally run it twice
    MB_OLD_ID = nil
    MB_NEW_ID = nil
    uart.write(2, packet)
end

set_slave_id(MB_NEW_ID)

print("Modbus poll timer unregistered. After finishing changing sensor node IDs, reboot.")
