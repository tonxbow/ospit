-- Telemetry implementation for MQTT

function mqtt_publish(broker)
    local data
    if (broker.short) then
        data=csvs[#csvs]
    else
        data=csvlog
    end
    
    if not (broker.json) then
     telemetry_channel_node = (broker.channel) .. nodeid
     mqtt_topic = telemetry_channel_node .. "/csvlog"
     printv(2,"Prepared csv log mqtt data.")
    end

    
    -- Dynamically add soil sensor data to MQTT data packet if they are connected
local function add_to_telemetry(target_table, key, val)
    if val ~= -127 then
        target_table[key] = val
    end
end

if (broker.json) then 
    data = {
        timeToShutdown = nextreboot,
        openCircuitVoltage = V_oc,
        airTemperature = airtemp, 
        heatsink_temperature = heatsink_temperature,
        tankGauge = tankgauge,
        mppVoltage = V_in,
        batteryVoltage = V_out,
        batteryChargeEstimate = charge_state_int,
        batteryHealthEstimate = health_estimate,
        batteryTemperature = battery_temperature,
        freeRAM = freeRAM
    }

    add_to_telemetry(data, "SoilHumiditySection1", shumidity1)
    add_to_telemetry(data, "SoilTemperatureSection1", stemp1)
    
    add_to_telemetry(data, "SoilHumiditySection2", shumidity2)
    add_to_telemetry(data, "SoilTemperatureSection2", stemp2)
    
    add_to_telemetry(data, "SoilHumiditySection3", shumidity3)
    add_to_telemetry(data, "SoilTemperatureSection3", stemp3)
    
    add_to_telemetry(data, "SoilHumiditySection4", shumidity4)
    add_to_telemetry(data, "SoilTemperatureSection4", stemp4)
end
         
    printv(2,"Creating JSON payload.")
    sjson.encode(data)
    ok, json = pcall(sjson.encode, data)
    if ok then
        
        data = json
        --print("JSON payload:", data)
    else
        printv(1,"MQTT ERROR: Encoding to JSON failed!")
        return
    end
    
    telemetry_channel_node = (broker.channel) .. nodeid
    mqtt_topic = telemetry_channel_node .. "/data.json"
    --[[ Modification for home assistant ]]--
    --[[mqtt_topic = (broker.channel) .. "sensor/" .. nodeid .. "/config" ]]--
    
    
printv(2,"mqtt_topic: ", mqtt_topic)
printv(2,"########## MQTT broker host:", broker.host)
printv(2,"Sending this MQTT Data set:", data)

    broker.m:publish(mqtt_topic, data, 1, 0, function(client)
        printv(2,"########## Success: MQTT message sent.")
        if (broker.close) then
            broker.m=nil
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
    
    
    m = mqtt.Client("isems-" .. nodeid, 120)
    broker.m=m
    m:on("connect", function(client) printv(2,"########## Connected to MQTT broker") end)
    m:on("offline", function(client) printv(2,"########## MQTT broker " .. broker.host .. " offline") ; broker.m=nil end)

    -- on publish message receive event
    m:on("message", function(client, topic, message) 
    printv(2,"######## Topic", topic .. ":" ) 
    if message ~= nil then
    printv(2,"######## The MQTT server has received this message:", message)
    end
end)

   m:connect(broker.host, broker.port, 0,
        function(client)
            -- subscribe topic with qos = 0
            -- client:subscribe(mqtt_topic, 0, function(client) print("subscribe success") end)
	    mqtt_publish(broker)
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
	for _,k in ipairs{'host','port','close','short','json','channel' } do
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
