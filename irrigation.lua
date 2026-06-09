-- Persistence variables (initialized once)

if IRR_active_vlv == nil then IRR_active_vlv = 0 end 
if IRR_last_t == nil then IRR_last_t, tusec = time.get() end
if IRR_pin_state == nil then IRR_pin_state = 0 end 
if irrigation_done == nil then irrigation_done = false end 


localTime = time.getlocal()

if irrigation_done == true and localTime["hour"] == i_hr + 1 then irrigation_done = false end 

--[[-- Tank gauge 170 Ohm (full) to 0 Ohm (empty), series resistor 820 Ohm

adc.setup(adc.ADC1, 0, adc.ATTEN_11db)
tankgaugeadc = ADCmeasure(4, 2)

if tankgaugeadc > 4000 then printv(1, "Water tank gauge sensor not connected!") 
tankgauge = -1
else
adc.setup(adc.ADC1, 0, adc.ATTEN_0db)
tankgaugeadc = ADCmeasure(0, 40)
tankgauge = tankgaugeadc / 8.85
tankgauge = math.floor(tankgauge)
tankgauge = tankgauge / 2
adc.setup(adc.ADC1, 0, adc.ATTEN_11db)
end

--if tankgauge ~= nil and tankgauge > 100 then tankgauge = 100 end

printv(2, "Water tank level at", tankgauge, "percent")
printv(3, "Water tank sensor ADC value:", tankgaugeadc) ]]--

local tankgaugeadc = ADCmeasure(4, 2)

if tankgaugeadc > 4000 then tankgauge = 0 end
if tankgaugeadc < 3000 then tankgauge = 1 end

local valves = {26, 27, 12, 14}
local humidities = {shumidity1, shumidity2, shumidity3, shumidity4}
local targets = {i_lvl1, i_lvl2, i_lvl3, i_lvl4}

-- Convert minutes to seconds
local max_sec = i_vlv_opn * 60
local now, tusec = time.get()

-- Calculate elapsed time
local idiff = (now >= IRR_last_t) and (now - IRR_last_t) or 0
IRR_last_t = now -- Update for the next loop iteration

-- 1. TRIGGER: Start the sequence
if localTime["hour"] == i_hr and IRR_active_vlv == 0 and i_nbld == true and irrigation_done == false then
    IRR_active_vlv = 1
    IRR_elapsed_total = 0
    printv(1, "Irrigation Sequence Started")
end

-- 2. EXECUTION & SKIP LOGIC
if IRR_active_vlv > 0 and IRR_active_vlv <= #valves then
    local i = IRR_active_vlv
    
    -- CHECK: If humidity is -127, skip this valve without touching GPIO
    if humidities[i] == -127 then
        printv(1, "Sensor " .. i .. " disconnected (-127). Skipping.")
        IRR_active_vlv = IRR_active_vlv + 1
        IRR_elapsed_total = 0
        IRR_pin_state = 0
        return -- Exit this execution loop so we don't hit the GPIO logic below
    end

    IRR_elapsed_total = (IRR_elapsed_total or 0) + idiff
    
    -- Safety Check
    if (tankgauge <= 0 and i_tanksens == true) or low_voltage_disconnect_state == 0 then
        gpio.write(valves[i], 0)
        if pump_is_load == false then gpio.write(14, 0) end 
        IRR_pin_state, IRR_active_vlv = 0, 0
        printv(1, "Irrigation Emergency Stop")

    -- Watering Logic
    elseif humidities[i] < targets[i] and IRR_elapsed_total < max_sec and humidities[i] >= 0 then
        if IRR_pin_state == 0 then
            gpio.write(valves[i], 1)
            if pump_is_load == false then gpio.write(14, 1) end
            IRR_pin_state = 1
            printv(1, "Valve " .. i .. " ON")
        end
    
    -- Transition Logic (End of cycle for current valve)
    else
        gpio.write(valves[i], 0)
        if pump_is_load == false then gpio.write(14, 0) end
        IRR_pin_state = 0
        printv(1, "Valve " .. i .. " OFF. Advancing.")
        IRR_active_vlv = IRR_active_vlv + 1
        IRR_elapsed_total = 0
    end

-- 3. RESET (Clean exit only for active sequence)
elseif IRR_active_vlv > #valves or (localTime["hour"] ~= i_hr and IRR_active_vlv ~= 0) then
    irrigation_done = true
    if pump_is_load == false then gpio.write(14, 0) end
    -- Only write 0 to pins that were actually part of the active sequence
    -- To prevent killing the USB charger, we check humidity[i] here too
    for i, pin in ipairs(valves) do 
        if humidities[i] ~= -127 then
            gpio.write(pin, 0) 
        end
    end
    IRR_pin_state, IRR_active_vlv = 0, 0
end
