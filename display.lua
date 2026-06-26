if not displ_cntr then displ_cntr = 1 end

if not pump_on then pump_on = false end

-- Clear buffer and draw current page
disp:clearBuffer()

-- Page 1: Power and battery
if displ_cntr == 1 then 
    disp:drawStr(0, 0, "Vbatt ")
    disp:drawStr(84, 0, V_out)
    disp:drawStr(122, 0, "V")
    disp:drawStr(0, 10, "Charge ")
    disp:drawStr(84, 10, charge_state_int)
    disp:drawStr(122, 10, "%")
    disp:drawStr(0, 20, "Vsolar")
    disp:drawStr(84, 20, V_oc)
    disp:drawStr(122, 20, "V")           
    disp:drawStr(0, 30, "Vmpp")
    disp:drawStr(84, 30, V_in)
    disp:drawStr(122, 30, "V")
    disp:drawStr(0, 40, "BattTmp ")
    disp:drawStr(84, 40, battery_temperature)
    disp:drawStr(122, 40, "C")

    if low_voltage_disconnect_state == 1 and pump_is_load == true then
        disp:drawStr(0, 50, "Load is on")
    end 

    if low_voltage_disconnect_state == 0 and pump_is_load == true then
        disp:drawStr(0, 50, "Load is off")
    end

    if pump_is_load == false and pump_on == true then 
        disp:drawStr(0, 50, "Pump/Valve4 is on")
    end

    if  pump_is_load == false and pump_on == false then
        disp:drawStr(0, 50, "Pump/Valve4 is off")
    end

-- Page 2: Soil sensors and environment
elseif displ_cntr == 2 then 
    disp:drawStr(0, 0, "SlHumdty1 ")
    disp:drawStr(90, 0, shumidity1)
    disp:drawStr(122, 0, "%")
    disp:drawStr(0, 10, "SlHumdty2 ")
    disp:drawStr(90, 10, shumidity2)
    disp:drawStr(122, 10, "%")
    disp:drawStr(0, 20, "SlHumdty3")
    disp:drawStr(90, 20, shumidity3)
    disp:drawStr(122, 20, "%")           
    disp:drawStr(0, 30, "SlHumdty4")
    disp:drawStr(90, 30, shumidity4)
    disp:drawStr(122, 30, "%")
    disp:drawStr(0, 40, "AirTmp ")
    disp:drawStr(90, 40, airtemp)
    disp:drawStr(122, 40, "C")
    disp:drawStr(0, 50, "TankGauge ")
    disp:drawStr(90, 50, tankgauge)
    disp:drawStr(122, 50, "%")

-- Page 3: Connectivity and MQTT status
elseif displ_cntr == 3 then
    local ip = nil
    local rssi = nil
    local wifi_ok = false

    if wifi and wifi.sta then
        -- getip may return ip,netmask,gateway or nil
        local ok, a, b, c = pcall(function() return wifi.sta.getip() end)
        if ok and a then
            ip = a
            wifi_ok = true
        end
        -- fallback: some modules set a global 'localstaip' on got_ip event
        if (not ip) and _G['localstaip'] then
            ip = _G['localstaip']
            wifi_ok = true
        end
        -- rssi may not be available until connected
        local ok2, rr = pcall(function() return wifi.sta.getrssi() end)
        if ok2 and rr then rssi = rr end
    else
        -- fallback to global localstaip even if wifi table missing
        if _G['localstaip'] then
            ip = _G['localstaip']
            wifi_ok = true
        end
    end

    local mqtt_status = "off"
    if mqttbrkrs ~= nil and type(mqttbrkrs) == 'table' and #mqttbrkrs > 0 then
        local b = mqttbrkrs[1]
        if b and b.m then
            mqtt_status = (b.subscribed and "on (sub)" or "on")
        end
    end

    -- Debug print to console when IP missing (helps diagnose)
    if not ip then printv(2, "Display: no IP found; wifi.sta available=", (wifi and wifi.sta) and 1 or 0, " localstaip=", _G['localstaip']) end

    disp:drawStr(0, 0, "IP:")
    disp:drawStr(40, 0, ip or "no-ip")
    disp:drawStr(0, 10, "WIFI:")
    disp:drawStr(40, 10, wifi_ok and "connected" or "disconnected")
    if rssi ~= nil then disp:drawStr(120, 10, tostring(rssi)) end
    disp:drawStr(0, 20, "MQTT:")
    disp:drawStr(40, 20, mqtt_status)
    disp:drawStr(0, 30, "Heap:")
    disp:drawStr(40, 30, tostring((node and node.heap) and node.heap() or 0))
end

-- Advance page counter
displ_cntr = displ_cntr + 1
if displ_cntr > 3 then displ_cntr = 1 end

disp:sendBuffer()
