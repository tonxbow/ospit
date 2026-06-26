-- Telemetry implementation for MQTT

local control = require('control')

local function mqtt_control_topic()
    return "ospit/subs/" .. nodeid
end

local function mqtt_normalize_command(cmd)
    if (cmd == nil) then
        return nil
    end
    local normalized = string.lower(tostring(cmd))
    if (normalized == 'turn_on' or normalized == 'turn on' or normalized == 'on') then
        return 'turn_ON'
    end
    if (normalized == 'turn_off' or normalized == 'turn off' or normalized == 'off') then
        return 'turn_OFF'
    end
    if (normalized == 'status') then
        return 'status'
    end
    return nil
end

local function mqtt_parse_control_message(message)
    if (message == nil or message == '') then
        return nil, nil
    end

    local ok, decoded = pcall(sjson.decode, message)
    if (ok and type(decoded) == 'table') then
        return mqtt_normalize_command(decoded.command or decoded.cmd or decoded.action),
               decoded.item or decoded.output or decoded.target
    end

    local cmd, item = message:match("^%s*([^%s/]+)/([%w_]+)%s*$")
    if (cmd ~= nil and item ~= nil) then
        return mqtt_normalize_command(cmd), item
    end

    cmd, item = message:match("^%s*(%S+)%s+([%w_]+)%s*$")
    if (cmd ~= nil and item ~= nil) then
        return mqtt_normalize_command(cmd), item
    end

    return nil, nil
end

local function mqtt_handle_control_message(topic, message)
    if (topic ~= mqtt_control_topic()) then
        return
    end

    local cmd, item = mqtt_parse_control_message(message)
    if (cmd == nil or item == nil) then
        printv(1, "MQTT control ignored: invalid payload", message)
        return
    end

    local result = control.command(cmd, item)
    if (result == false and cmd ~= 'turn_OFF') then
        printv(1, "MQTT control failed:", cmd, item)
        return
    end

    printv(2, "MQTT control executed:", cmd, item, result)
end

local function mqtt_subscribe_controls(broker, on_ready)
    local topic = mqtt_control_topic()
    broker.subscribe_topic = topic
    broker.m:subscribe(topic, 1, function(client)
        broker.subscribed = true
        printv(2, "Subscribed to MQTT control topic:", topic)
        on_ready(client)
    end)
end

function mqtt_publish(broker)
   
    local function safe_get(name, def)
        if _G[name] ~= nil then return _G[name] end
        return def
    end

    local ts = safe_get('timestamp', 0)
    -- try to get a readable datetime if rtctime available
    local datetime = nil
    if (type(ts) == 'number' and ts > 0 and os and os.date) then
        pcall(function() datetime = os.date("!%Y-%m-%dT%H:%M:%SZ", ts) end)
    end

    local device_tbl = {
        id = nodeid,
        device = nodeid,
        serial = nodeid,
        uptime = (node and node.uptime) and math.floor(node.uptime()/1000000) or 0,
        ts = ts,
        datetime = datetime
    }


    local others = { heap = (node and node.heap) and node.heap() or safe_get('freeRAM', safe_get('freeRAM', 0)) }

    -- Sensors: soil sensors separated
    local sensors = {}
    local function add_sensor(prefix, val)
        if val ~= nil and val ~= -127 then sensors[prefix] = val end
    end

    add_sensor('airTemperature', safe_get('airtemp', nil))
    add_sensor('soilHumidity1', safe_get('shumidity1', nil))
    add_sensor('soilTemperature1', safe_get('stemp1', nil))
    add_sensor('soilHumidity2', safe_get('shumidity2', nil))
    add_sensor('soilTemperature2', safe_get('stemp2', nil))
    add_sensor('soilHumidity3', safe_get('shumidity3', nil))
    add_sensor('soilTemperature3', safe_get('stemp3', nil))
    add_sensor('soilHumidity4', safe_get('shumidity4', nil))
    add_sensor('soilTemperature4', safe_get('stemp4', nil))
    add_sensor('soilTemperature4', safe_get('stemp4', nil))
    add_sensor('soilTemperature4', safe_get('stemp4', nil))
    add_sensor('airTemperature',safe_get('airtemp', nil))
    add_sensor('batteryTemperature',safe_get('battery_temperature', nil))
    add_sensor('tankGauge',safe_get('tankgauge', nil))
    add_sensor('bme280Temperature', safe_get('bme280_temperature', nil))
    add_sensor('bme280Humidity', safe_get('bme280_humidity', nil))
    add_sensor('bme280Pressure', safe_get('bme280_pressure', nil))
    add_sensor('bh1750Lux', safe_get('bh1750_lux', nil))

    -- Voltage/power sensors (include Vsolar, battery_temperature, airtemp)
    local voltage = {
        batteryVoltage = safe_get('V_out', nil),
        mppVoltage = safe_get('V_in', nil),
        Vsolar = safe_get('V_oc', nil)
    }

    -- Compose final payload (removed sys and pumps)
    -- Determine load/output statuses
    local load_on = false
    -- load_on true when not disabled and no low-voltage trip
    load_on = not (safe_get('load_disabled', false) or (safe_get('low_voltage_disconnect_state', low_voltage_disconnect_state) ~= 1))

    local outputs = {
        load = load_on,
        valve_1 = safe_get('valve_1_state', safe_get('valve_1_enabled', false)),
        valve_2 = safe_get('valve_2_state', safe_get('valve_2_enabled', false)),
        valve_3 = safe_get('valve_3_state', safe_get('valve_3_enabled', false))
    }

    local payload = {
        id = device_tbl.id,
        uptime = device_tbl.uptime,
        ts = device_tbl.ts,
        datetime = device_tbl.datetime,
        outputs = outputs,
        sensors = sensors,
        voltage = voltage,
        mcu = others
    }

    printv(2, "Creating structured JSON payload for MQTT")
    local ok, json = pcall(sjson.encode, payload)
    if not ok then
        printv(1, "MQTT ERROR: Encoding structured payload failed")
        return
    end

    local telemetry_channel_node = (broker.channel or "") .. nodeid
    local mqtt_topic = telemetry_channel_node .. "/data"

    printv(2, "mqtt_topic:", mqtt_topic)
    printv(3, "payload:", json)

    broker.m:publish(mqtt_topic, json, 1, 0, function(client)
        printv(2, "Success: Structured MQTT payload sent to " .. mqtt_topic)
        if (broker.close and broker.subscribe_topic == nil) then
            broker.m = nil
        end
    end)
end

function mqtt_connect(broker)
    --[[
    MQTT telemetry

    Encode telemetry data as JSON and publish message to
    MQTT broker at topic configured within "config.lua".
    ]]

    local m
    printv(2,"Submitting telemetry data to MQTT broker.")
    
    printv(2,"########## MQTT broker host:", broker.host)
    
    
    if (broker.user ~= nil and broker.user ~= '') then
        m = mqtt.Client("isems-" .. nodeid, 120, broker.user, broker.password)
    else
        m = mqtt.Client("isems-" .. nodeid, 120)
    end
    broker.m=m
    m:on("connect", function(client) printv(2,"########## Connected to MQTT broker") end)
    m:on("offline", function(client) printv(2,"########## MQTT broker " .. broker.host .. " offline") ; broker.m=nil ; broker.subscribed=nil end)

    -- on publish message receive event
    m:on("message", function(client, topic, message) 
        printv(2,"######## Topic", topic .. ":" ) 
        if message ~= nil then
            printv(2,"######## The MQTT server has received this message:", message)
        end
        mqtt_handle_control_message(topic, message)
    end)

   m:connect(broker.host, broker.port, 0,
        function(client)
            mqtt_subscribe_controls(broker, function()
	        mqtt_publish(broker)
            end)
        end,
        function(client, reason)
            printv(1,"########### MQTT connect failed. Reason: " .. reason)
        end
    )
end

local function get_config()
    mqttbrkrs={}
    for i=1,2 do
	local broker={}
	for _,k in ipairs{'host','port','close','short','json','channel','user','password' } do
	    broker[k]=_G['mqttbrkr'..i..'_'..k]
	end
	if (broker.host ~= nil and broker.host ~= '') then
	    table.insert(mqttbrkrs,broker)
	end
    end
end

if mqtt_enabled then
    if (mqttbrkrs == nil) then
        get_config()
    end
    for i,broker in ipairs(mqttbrkrs) do
        if (broker.m) then
            mqtt_publish(broker)
        else
            mqtt_connect(broker)
        end
    end
end
