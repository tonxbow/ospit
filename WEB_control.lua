local control = require('control')


-- MAIN REQUEST HANDLER

return function (info)
    if (not authenticated()) then return end
        
    local p = info.headers.path

    -- Routing logic
    if (p:match('^/control/turn_ON/')) then
        control.command('turn_ON', p:sub(18)) 
    elseif (p:match('^/control/turn_OFF/')) then
        control.command('turn_OFF', p:sub(19))
    end

    -- Send Preamble and Styles
    send_buffered(info.http_preamble)
    send_buffered("<style> .item-row { margin-bottom: 20px; padding: 10px; border-bottom: 1px solid #ccc; } .status-ON { color: red; font-weight: bold; } .status-OFF { color: green; } </style><html><h3><a href=\"/index\">Status page</a> | <a href=\"/config\">System Config</a> | <a href=\"/time\">Time</a> | <a href=\"/help.html\">Manual</a> |<a href=\"/reboot\">Reboot</a></h3><h1>Control Panel</h1>")

    for _, k in ipairs(control.item_order) do
        local status = 'OFF'
        local command = 'turn_ON'
        local status_class = 'status-OFF'
        
        if (control.command('status', k)) then
            status = 'ON'
            command = 'turn_OFF'
            status_class = 'status-ON'
        end
        
        -- Use the display_names table, or fall back to the key if not found
        local label = control.display_names[k] or k
        
        
        
        -- HTML output with names and styles
        send_buffered([[
            <div class='item-row'>
                <strong>]] .. label .. [[:</strong> 
                <span class=']] .. status_class .. [['>]] .. status .. [[</span>
                <form method='post' action='/control/]] .. command .. [[/]] .. k .. [['>
                    <input type='submit' value=']] .. command:gsub("_", " ") .. [['/>
                </form>
            </div>
        ]])
    end
end
