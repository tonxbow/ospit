--[[
* **********************************************************************
 * MPPT LUA source code for OSPIT
 * Copyright (C) 2026  by Corinna 'Elektra' Aichele
 *
 * This file is part of the Open-Hardware and Open-Software project 
 * FF-ESP32-OpenMPPT.
 * 
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this source file. If not, see http://www.gnu.org/licenses/. 
 ************************************************************************* ]]




-- IO14 GPIO = control Low-Voltage-Disconnect / external power output
-- IO32 Temp Sense,  Channel 4
-- IO34 V_in,  Channel 6
-- IO33 V_out,  Channel 5

-- ADC channel 0:GPIO36, 1:GPIO37, 2:GPIO38, 3:GPIO39, 4:GPIO32, 5:GPIO33, 6:GPIO34, 7: GPIO35

-- DAC channel 1 is attached to GPIO25 - DAC channel 2 is attached to GPIO26
-- Value: 8bit =  0 to 255

-- V_out_max and V_out_max_temp in mV
if not V_out_max then  V_out_max = 14100 end 
if not V_out_max_temp then V_out_max_temp = V_out_max end

-- V_oc = 0
-- Vcc = 3.07

-- ptc_series_resistance_R17 = 2200
low_voltage_disconnect = 11.9


if D6_loaded == nil then D6_loaded = true printv(4, "Schottky diode D6 info missing in board.lua\n Assuming it is present") end
if D6_loaded == true then D6loss = 300 else  D6loss = 0 printv(4, "D6 not present") end 

if heatsink_temperature > 60 then 
     
     if not V_out_max_config then V_out_max_config = V_out_max end
     V_out_max = V_out_max - 100
     printv(3,"Reducing V_out_max due to high heatsink temperature to: ", V_out_max , "mV")
 
     end

if heatsink_temperature < 58 and V_out_max_config ~= nil then
     V_out_max = V_out_max_config
     printv(3,"Restoring V_out_max due to heatsink temperature reaching acceptable level to: ", V_out_max , "mV")
     V_out_max_config = nil
     end
 


timestamp = time.get()

if Voutctrlcounter > 0  then V_outctrltimer:stop()  end

function ADCmeasure (adcchannel, number_of_runs, result) 
    local result = 0
    local value1 = 0
    local value2 = 0
    local c = 0

    while c ~= number_of_runs do
    --GPIO35
    value1 = adc.read(adc.ADC1, adcchannel)
    value2 = value2 + value1
    --print(value2, value1)
    c = c+1
    end
    
result = value2 / number_of_runs
result = math.floor(result)

-- print("ADC channel", adcchannel, " result value (12 bit):", result)
   
return result
end

function Vinmeasure (V_in_result)
    local value3 = 0
    local V_in_result = 0
    --GPIO34, V_in
    value3 = ADCmeasure(6, 15)
    Vincorrectionfactor = 1 + ((3200 - value3) * 0.000052)
    printv(4,"Vincorrectionfactor=", Vincorrectionfactor)
    -- 0.03571 ratio of Voltage divider 1k/27k
    V_in_result = ((value3 / 4095) * Vref) / 0.035714

    -- Correction factor, taking Schottky diode input loss into account
    V_in_result = (V_in_result * Vincorrectionfactor) + D6loss

    V_in_result = math.ceil(V_in_result) 
    V_in_result = V_in_result / 1000

    return V_in_result
end


function Voutmeasure (V_out_result)
    local value4 = 0
    local V_out_result = 0
    
    --GPIO33, V_out
    value4 = ADCmeasure(5, 15)
    printv(4,"ADC_Vout =", value4)
    Voutcorrectionfactor = 1 + ((3150 - value4) * 0.000037)
    printv(4,"Voutcorrectionfactor=", Voutcorrectionfactor)
    -- 0.0625 ratio of Voltage divider 1k/15k
    -- 0.1089 ratio of Voltage divider 3.3k/27k
    -- V_out_result = ((value4 / 4095) * Vref) / 0.086
    V_out_result = ((value4 / 4095) * Vref) / 0.0625
    V_out_result = (V_out_result * Voutcorrectionfactor)
    V_out_result = math.ceil(V_out_result)
    V_out_result = V_out_result / 1000
    
    return V_out_result
end

function Voutctrl(number_of_steps)
    
    if dac1value == nil then number_of_steps = 0  end 
    
    printv(3,"Voutctrl running.")
    
    --print("### Voutctrl active ###\n", "V_out_max_temp:", V_out_max_temp, "V_out:", V_out, "dac1value =", dac1value, "\nnumber_of_steps:", number_of_steps, "Voutctrlcounter =", Voutctrlcounter)
    
    printv(4,"# Voutctrl dac1value =", dac1value)
    
    while number_of_steps > 0 do 
           
            V_out = Voutmeasure() 
            --print("V_out:", V_out, "V_out_max_temp:", V_out_max_temp)    
            
             printv(4,"V_out: ", V_out, "V_out_max_temp: ", V_out_max_temp)
            
            if (V_out_max_temp + 0.03) < V_out then 
            dac1value = dac1value + 1
            --print("Increasing dac1value =", dac1value)
            --number_of_steps = number_of_steps - 2
            end
            
            if (V_out_max_temp - 0.03) > V_out and dac1value > 0 then 
            dac1value = dac1value - 1
            --print("Decreasing dac1value =", dac1value)
            --number_of_steps = number_of_steps - 1
            end
            
            if dac1value > 254 then dac1value = 254
            print("WARNING: V_out_ctrl maximum Vmpp reached.")
            number_of_steps = 0
            end
            
            number_of_steps = number_of_steps - 1
            
            dac.write(dac.CHANNEL_1, dac1value)
            end
            
            Voutctrlcounter = Voutctrlcounter - 1
            
            printv(4,"Voutctrlcounter = ", Voutctrlcounter)
            
    end



adc.setup(adc.ADC1, 4, adc.ATTEN_11db)

function get_statuscode()
    local x=2048
    local sum=0
    for i=0,11 do
        sum=sum+_G['Bit_'..i]*x
        x=x/2
    end
    return string.format('%03X',sum)
end

function update_log()
      
    local ffopenmppt_log = nodeid .. ";" .. packetrev .. ";" .. timestamp .. ";" .. firmware_type .. ";" .. nextreboot .. ";" .. powersave .. ";".. V_oc .. ";".. V_in .. ";".. V_out .. ";".. charge_state_int .. ";" .. health_estimate .. ";".. battery_temperature .. ";".. low_voltage_disconnect .. ";".. V_out_max_temp .. ";" .. ah_batt .. ";".. pv_watt .. ";".. lat .. ";" .. long .. ";" ..  statuscode

    
    if(csvs == nil) then
        csvs={}
    end
    if (#csvs > 4) then
        table.remove(csvs,1)
    end
    table.insert(csvs,ffopenmppt_log)
    csvlog=table.concat(csvs,"\n")
end

V_out_max_temp = V_out_max - ((battery_temperature - 25.00) * 30)

if battery_temperature > 42.00 then V_out_max_temp = 13100 end

battery_temperature = battery_temperature * 100
battery_temperature = math.floor(battery_temperature)
battery_temperature = battery_temperature / 100

V_out_max_temp = math.floor(V_out_max_temp)

V_out_max_temp = V_out_max_temp / 1000


V_in = Vinmeasure()

V_out = Voutmeasure()


if V_out_max_temp + 0.05 < V_out then Voutctrlcounter = 45000 end

if V_out_max_temp - 0.3 > V_out then Voutctrlcounter = 0 end

if V_in >= V_out and V_out_max_temp > V_out and Voutctrlcounter <= 0 then 

    dac1value= 254
    dac.write(dac.CHANNEL_1, dac1value)
    printv(3,"MPPT - Setting PWM to ", dac1value)



            count_dac = 1
            compare_dac = 0
            
        while count_dac < 20 do 
            printv(3,"MPPT - Measure V_in idle - run #", count_dac) 
            val1 = ADCmeasure(6, 50)
            if compare_dac == 0 then compare_dac = val1 end
            if count_dac >= 2 and val1 <= compare_dac then count_dac = 20 end 
            if count_dac >= 2 and val1 > compare_dac then 
            compare_dac = val1 end
            printv(3,"MPPT - Previous ADC measurement value:", compare_dac, "Latest ADC measurement value:", val1)
            count_dac =  count_dac + 1
        end


        V_oc = Vinmeasure()   
        v_mpp_estimate = V_oc / 1.24


        printv(2,"V_oc=", V_oc)
        printv(2,"V_mpp_estimate=", v_mpp_estimate)
        dac1value = (v_mpp_estimate - Vmpp_min) / ((Vmpp_max - Vmpp_min) / 285)
        dac1value = math.floor(dac1value)
        if dac1value < 0 then dac1value = 0 end
        if dac1value > 255 then dac1value = 255 end
        dac.write(dac.CHANNEL_1, dac1value)
        printv(2,"Setting PWM to ", dac1value)

end


if V_in < V_out then 
    V_oc = 0 
    dac1value = 29
    dac.write(dac.CHANNEL_1, dac1value)

end
    
if V_out < low_voltage_disconnect then
        print("Disabled power output")
        disp:clearBuffer()
        disp:drawStr(7, 0, V_out)
        disp:drawStr(48, 0, "V")
        --disp:drawStr(7, 0, "low batt")
        disp:sendBuffer()
        gpio.wakeup(14, gpio.INTR_LOW)
        gpio.write(14, 0)
        low_voltage_disconnect_state = 0
        node.dsleep(300000000)
end
    
if V_out > 12.3 and load_disabled == false and pump_is_load==true then 
       gpio.wakeup(14, gpio.INTR_HIGH)
       gpio.write(14, 1)
       low_voltage_disconnect_state = 1
       printv(2,"Enabled power output")
end

if not usb_voltage_disconnect_state then  usb_voltage_disconnect_state = 1 end 

if V_out < 12.8 and usb_load and usb_load == true and shumidity3 == -127 then 
        --gpio.wakeup(12, gpio.INTR_HIGH)
        printv(2,"Disabled USB power output")
        gpio.write(12, 0)
        usb_voltage_disconnect_state = 1
end
    
if V_out > 13.4 and usb_load and usb_load == true and shumidity3 == -127 and usb_voltage_disconnect_state == 1 then 
       --gpio.wakeup(12, gpio.INTR_HIGH)
       usb_voltage_disconnect_state = 0
       printv(2,"Enabled USB power output")
       gpio.write(12, 1)
end

V_out = Voutmeasure()

val1 = ADCmeasure(6, 200)
printv(2,"V_in measure run 1", val1)
 
val1 = ADCmeasure(6, 30)
printv(2,"V_in measure run 2", val1)

V_in = Vinmeasure()

if V_oc < V_out + 0.2 and Voutctrlcounter <= 0  then 
    
    V_in = 0
    V_oc = 0 

end


-- #################################################################################################
-- Below: Common parts from previous program isems.lua that reads data from AVR 8bit via serial port
-- #################################################################################################



printv(2,"lat",lat)
printv(2,"nodeid",nodeid)

packetrev = "1"
counter_serial_loop = 0
powersave = 0
csvlog = nodeid .. ";1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0"
quickstart_threshold = 14


Bit_0  = 0
Bit_1  = 0
Bit_2  = 0
Bit_3  = 0
Bit_4  = 0
Bit_5  = 0
Bit_6  = 0
Bit_7  = 0
Bit_8  = 0
Bit_9  = 0
Bit_10 = 0
Bit_11 = 0

V_out = Voutmeasure()



printv(2,"##################################################################################")
printv(2,"V_in (mpp):", V_in, "V_out:", V_out, "V_out_max_temp:", V_out_max_temp)
printv(2,"V_oc=", V_oc, "PTC resistance=", ptc_resistance, "Battery_temperature =", battery_temperature)

        charge_status = ""
        
        if (V_in >= V_out and V_out ~= 0 and V_oc >= V_in) then charge_status = "Charging" Bit_0 = 1 end
        
        if (V_in < V_out) then charge_status = "Discharging" Bit_1 = 1 end

        if (V_out == 0.0 and V_in == 0.0) then charge_status = "No information" end

        if (V_oc == 0.0 and V_in < V_out) then V_in = 0.0 end

        if (V_oc == 0.0 and V_in > V_out) then V_oc = V_in end

        if (V_out_max_temp == 0.0) then V_out_max_temp = 14.2 end 

-- State of charge estimate
        
        charge_increment = 0.05
        
        if not V_out_old then V_out_old = V_out end
        
-- To estimate charge state when discharging is relatively simple, due to low and relatively constant load.
       
  
        if V_in < V_out and V_out > 12.60 then charge_state = (95 + ((V_out - 12.6) * 20)) end 

        if V_in < V_out and V_out < 12.60 then charge_state = (10 + ((V_out - 11.6) * 85)) end
        


-- Estimate SoC while charging without measuring current --  tricky!

        -- Detect and handle charge end
        -- At charge end, the battery can no longer take the full energy offered by the solar module. Once we are at 100% charge, the MPPT voltage almost reaches V_oc 

        if V_out >= (V_out_max_temp - 0.2) and V_oc >= V_in then charge_state = (((V_out - 12.0) / ((V_out_max_temp - 12.0) /100)) * (V_in / (V_oc - 0.5) )) printv(3,"CHG_CON_EST_1") end
         
         if V_out > V_out_max_temp then charge_state = 100 printv(3,"CHG_CON_EST_1-1") end 
                
         
        -- Detect and handle very low charge current
        -- At very low charge current, the V_oc versus V_mpp ratio is smaller than the MPP controller calculates.

        if V_out < (V_out_max_temp - 0.05) and V_in > V_out and 1.18 > (V_oc / V_in) and V_out > 12.6 then charge_state = (85 + ((V_out - 12.6) * 25)) printv(3,"CHG_CON_EST_2") charge_increment = 0.02 end
        
        if V_out < (V_out_max_temp - 0.05) and V_in > V_out and 1.18 > (V_oc / V_in) and V_out <= 12.6 then charge_state = (10 + ((V_out - 11.6) * 75)) printv(3,"CHG_CON_EST_2_1") charge_increment = 0.02 end
        
        if V_out < (V_out_max_temp - 0.05) and V_in > V_out and V_in <= 15 and V_out <= 12.6 then charge_state = (10 + ((V_out - 11.6) * 85))  printv(3,"CHG_CON_EST_2_2") charge_increment = 0.02 end
        
        if V_out < (V_out_max_temp - 0.05) and V_in > V_out and V_in <= 15 and V_out > 12.6 then charge_state = (85 + ((V_out - 12.6) * 25)) printv(3,"CHG_CON_EST_2_3") charge_increment = 0.02 end
        
        -- Detect if solar panel charge current is less than consumer current. 

        if V_out < (V_out_max_temp - 0.05) and V_in > V_out and V_in >= 15  and 1.18 < (V_oc / V_in)  and V_out <= 13.2 then 
        charge_state = (((V_out - 11.6) / ((V_out_max_temp - 11.6) /100)) * (V_in / (V_oc - 0.5) )) printv(3,"CHG_CON_EST_2_3") 
        charge_increment = 0.02 end
        
        -- Detect and handle considerable charge current
        -- At considerable charge current, the V_oc versus V_mpp ratio matches the ratio the MPP controller calculates. Unless the current doesn't go down close to zero, we haven't reached charge limit.

        if V_out < (V_out_max_temp - 0.2) and 1.18 <= (V_oc / V_in) and V_in > 15 and V_out > 13.2 and V_out_old < V_out then 
        charge_state = (((V_out - 12.0) / ((V_out_max_temp - 12.0) / 100)) * (V_in / V_oc ))
        charge_increment = 0.25 printv(3,"CHG_CON_EST_3")  end

        
if not charge_state then charge_state = 50 end 
       
if not charge_state_float then charge_state_float = charge_state end

-- Sanity check of battery level gauge: Move slowly

if charge_state > charge_state_float then charge_state_float = charge_state_float + charge_increment end

if charge_state < charge_state_float and V_out > 0 and V_out < 12.9 and V_out_old > V_out then charge_state_float = charge_state_float - charge_increment  end

if charge_state_float < 0 then charge_state_float = 0 end 

charge_state_int = math.ceil(charge_state_float)

printv(2, "SoC now, SoC avg: ", charge_state, charge_state_float, "\n V_out_old, V_out now", V_out_old, V_out)

V_out_old = V_out


-- if V_out >= (V_out_max_temp - 0.05) and V_in >= (V_oc * 0.95) and V_in > 16.00 then charge_status = "Fully charged" Bit_2 = 1 end

if charge_state_int > 100 then charge_state_int = 100 end

if charge_state_int == 100 then charge_status = "Fully charged" Bit_2 = 1 Bit_0 = 0 end 

       
-- Battery health estimate calculation
                    
-- Log discharge rate over 6 hours at night. Save battery gauge at 22 hours local time, then check charge state again 6 hours later.

-- Check if we are at 2 hours before midnight.
       
localTime = time.getlocal()
printv(2,'localtime',string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"], localTime["dst"]))

printv(2,"health_test_in_progress:", health_test_in_progress, "timestamp:", timestamp)


if health_test_in_progress == false and localTime["hour"] == 22 and timestamp > 1569859000 then 
        printv(1,"Starting 6 hour discharge check")
        health_test_in_progress = true
        battery_gauge_start = charge_state_float - 0.5
end

if health_test_in_progress == true and localTime["hour"] == 4 then
        printv(1,"Finishing 6 hour discharge check")
        health_test_in_progress = false
        battery_gauge_stop = charge_state_float                      
        if battery_gauge_start > 100 then battery_gauge_start = 100 end

        if battery_gauge_start > 0 and battery_gauge_stop > 0 and av_pwr > 0 then health_estimate = (((6 * av_pwr) / (((battery_gauge_start - battery_gauge_stop) / 100) * ah_batt)) * 100) end

        printv(1,"battery_gauge_start:", battery_gauge_start, "battery_gauge_stop:", battery_gauge_stop, "av_pwr:", av_pwr, "ah_batt:", ah_batt)
                                     
        printv(1,"Battery health estimate: ", health_estimate)

        health_estimate = math.ceil(health_estimate)

        if health_estimate > 100 then health_estimate = 100 end

end

       
-- System health report
       

critical_storage_charge_ratio = 5.0


storage_charge_ratio =  (ah_batt * (health_estimate / 100)) / (pv_watt / 15)

system_status = " "

if (storage_charge_ratio > critical_storage_charge_ratio and charge_state_int > 50) then system_status = "Healthy. " Bit_3 = 1 end

if (storage_charge_ratio > critical_storage_charge_ratio and charge_state_int <= 50) then system_status = "Warning: Battery level low. Increased battery wear. "  Bit_4 = 1 end

if (storage_charge_ratio <= critical_storage_charge_ratio) then system_status = system_status .. "Warning: Energy storage capacity too small. Check battery size and/or wear. "  Bit_5 = 1 end

if tempsens_missing == 1 then system_status = system_status .. "Warning: Temperature sensor not connected. " Bit_6 = 1 end

if V_out == 0.0 then system_status = "Error: No communication with solar controller." Bit_7 = 1 V_out_max_temp = 0 end

battery_temperature = tonumber(battery_temperature) 

if battery_temperature >= 40.0 then system_status = system_status .. "Battery overheating. " Bit_8 = 1 end

if battery_temperature <= -10.0 then system_status = system_status .. "Low battery temperature. " Bit_9 = 1 end
          
                    
if 0.2 > V_out - low_voltage_disconnect or tonumber(nextreboot) < 15 then Bit_10 = 1 end


statuscode=get_statuscode()
-- print("statuscode =", statuscode)

freeRAM = node.heap()

-- CSV payload

update_log()

node_uptime = math.floor((node.uptime() / 1000000))



if Voutctrlcounter > 0  then V_outctrltimer:start()  end

if disp ~= nil then dofile"display.lua" end

 Bit_0  = nil
 Bit_1  = nil
 Bit_2  = nil
 Bit_3  = nil
 Bit_4  = nil
 Bit_5  = nil
 Bit_6  = nil 
 Bit_7  = nil  
 Bit_8  = nil
 Bit_9  = nil
 Bit_10 = nil  
 Bit_11 = nil 
 
-- dofile"irrigation.lua"
