if not displ_cntr then displ_cntr = 1 end

if not pump_on then pump_on = false end

if displ_cntr == 1 then 

disp:clearBuffer()

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

--disp:drawStr(56, 55, "Status:0x")
--disp:drawStr(110, 55, statuscode)
-- disp:drawStr(62, 55, "@elektra_42")

end 

if displ_cntr == 2 then 

disp:clearBuffer()

disp:drawStr(0, 0, "Humidity1 ")
disp:drawStr(84, 0, shumidity1)
disp:drawStr(122, 0, "%")
disp:drawStr(0, 10, "SoilTmp1 ")
disp:drawStr(84, 10, stemp1)
disp:drawStr(122, 10, "C")
disp:drawStr(0, 20, "Humidity2")
disp:drawStr(84, 20, shumidity2)
disp:drawStr(122, 20, "%")           
disp:drawStr(0, 30, "SoilTmp2:")
disp:drawStr(84, 30, stemp2)
disp:drawStr(122, 30, "C")
disp:drawStr(0, 40, "AirTmp: ")
disp:drawStr(84, 40, airtemp)
disp:drawStr(122, 40, "C")

--disp:drawStr(56, 55, "Status:0x")
--disp:drawStr(110, 55, statuscode)
--disp:drawStr(62, 55, "@elektra_42")

displ_cntr = 1

end 

if low_voltage_disconnect_state == 1 and pump_is_load == true then
disp:drawStr(0, 50, "Load: on")
else
disp:drawStr(0, 50, "Load: off")
end

if low_voltage_disconnect_state == 1 and pump_is_load == false then

if pump_on == true then disp:drawStr(0, 50, "Pump: on") end
else
disp:drawStr(0, 50, "Pump: off")
end

if displ_cntr == 1 then  displ_cntr = 2 end 

disp:sendBuffer()
