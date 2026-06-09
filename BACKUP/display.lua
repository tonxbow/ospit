if not displ_cntr then displ_cntr = 1 end

if not pump_on then pump_on = false end

if displ_cntr == 3 then displ_cntr = 1 end 

disp:clearBuffer()


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

end 


if displ_cntr == 2 then 

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


end 




displ_cntr = displ_cntr + 1  

disp:sendBuffer()
