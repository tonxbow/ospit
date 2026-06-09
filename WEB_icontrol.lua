local display_names = {
    valve_1 = "Irrigation Sector 1",
    valve_2 = "Irrigation Sector 2",
    valve_3 = "Irrigation Sector 3 or USB load output"
}


local function gpio_device(pin, state_var)
    return function(cmd)
        if cmd == 'turn_OFF' then
            gpio.wakeup(pin, gpio.INTR_LOW)
            gpio.write(pin, 0)
            _G[state_var] = false
        end
        if cmd == 'turn_ON' and low_voltage_disconnect_state == 1 then
            gpio.wakeup(pin, gpio.INTR_HIGH)
            gpio.write(pin, 1)
            _G[state_var] = true
        end
        if cmd == 'status' then
            return (_G[state_var] == true) and (low_voltage_disconnect_state == 1)
        end
    end
end

local valve_1 = gpio_device(26, "valve_1_state")
local valve_2 = gpio_device(27, "valve_2_state")
local valve_3 = gpio_device(12, "valve_3_state")

local items = {
    valve_1 = valve_1,
    valve_2 = valve_2,
    valve_3 = valve_3
}

local item_order = { 'valve_1', 'valve_2', 'valve_3'}

local function startstopstatus(cmd, what)
    local item = items[what]
    if (item == nil) then return false end
    
    if (cmd == 'status') then
        if (type(item) == 'function') then return item('status') end
        if (type(item) == 'string') then return tcp_servers[item] end
    end

    if (type(item) == 'function') then
        return item(cmd)
    end
    
    if (type(item) == 'string') then
        if (cmd == 'turn_OFF') then server_deactivate(item) end
        if (cmd == 'turn_ON') then server_activate(item) end
    end
    return false
end

-- MAIN REQUEST HANDLER

return function (info)
    if (not authenticated()) then return end
        
    local p = info.headers.path

    -- Routing logic
    if (p:match('^/icontrol/turn_ON/')) then
        startstopstatus('turn_ON', p:sub(19)) 
    elseif (p:match('^/icontrol/turn_OFF/')) then
        startstopstatus('turn_OFF', p:sub(20))
    end

    -- Send Preamble and Styles
    send_buffered(info.http_preamble)
    send_buffered("<style> .item-row { margin-bottom: 20px; padding: 10px; border-bottom: 1px solid #ccc; } .status-ON { color: red; font-weight: bold; } .status-OFF { color: green; } </style>")

    for _, k in ipairs(item_order) do
        local status = 'OFF'
        local command = 'turn_ON'
        local status_class = 'status-OFF'
        
        if (startstopstatus('status', k)) then
            status = 'ON'
            command = 'turn_OFF'
            status_class = 'status-ON'
        end
        
        -- Use the display_names table, or fall back to the key if not found
        local label = display_names[k] or k
        
        -- HTML output with names and styles
        send_buffered([[
            <div class='item-row'>
                <strong>]] .. label .. [[:</strong> 
                <span class=']] .. status_class .. [['>]] .. status .. [[</span>
                <form method='post' action='/icontrol/]] .. command .. [[/]] .. k .. [['>
                    <input type='submit' value=']] .. command:gsub("_", " ") .. [['/>
                </form>
            </div>
        ]])
    end
end
