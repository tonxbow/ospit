disp:clearBuffer()

disp:drawStr(0, 0, "Battery: ")
disp:drawStr(84, 0, V_out)
disp:drawStr(122, 0, "V")
disp:drawStr(0, 10, "Charge: ")
disp:drawStr(84, 10, charge_state_int)
disp:drawStr(122, 10, "%")
disp:drawStr(0, 20, "V_oC:")
disp:drawStr(84, 20, V_oc)
disp:drawStr(122, 20, "V")           
disp:drawStr(0, 30, "V_in:")
disp:drawStr(84, 30, V_in)
disp:drawStr(122, 30, "V")
disp:drawStr(0, 40, "Temperature: ")
disp:drawStr(84, 40, battery_temperature)
disp:drawStr(122, 40, "C")

if low_voltage_disconnect_state == 1 then
disp:drawStr(0, 50, "Load:          on")
else
disp:drawStr(0, 50, "Load:         off")
end

-- WiFi mode 
-- One of: 1 = STATION, 2 = SOFTAP, 3 = STATIONAP, 4 = NULLMODE

if localstaip == nil then localstaip = "not connected" end 

disp:drawStr(0, 62, "WiFimode:")
if wlanmode == 1 then 
disp:drawStr(66, 62, "Station")
disp:drawStr(0, 75, "SSID:")
disp:drawStr(34, 75, sta_ssid)
disp:drawStr(0, 85, "IP:")
disp:drawStr(38, 85, localstaip)

elseif 

wlanmode == 2 then 
disp:drawStr(66, 62, "SoftAP")
disp:drawStr(0, 75, "SSID:")
disp:drawStr(34, 75, ap_ssid)
disp:drawStr(0, 85, "IP:")
disp:drawStr(38, 85, ap_ip)

elseif 

wlanmode == 3 then 
disp:drawStr(66, 62, "Station+AP")
disp:drawStr(0, 75, "SSID:")
disp:drawStr(34, 75, sta_ssid)
disp:drawStr(0, 85, "IP:")
disp:drawStr(38, 85, localstaip)
disp:drawStr(0, 96, "SSID:")
disp:drawStr(38, 96, ap_ssid)
disp:drawStr(0, 106, "IP:")
disp:drawStr(38, 106, ap_ip)

elseif 

wlanmode == 4 then 
disp:drawStr(66, 62, "off")

end 

disp:drawStr(0, 118, string.format("%04d-%02d-%02d %02d:%02d:%02d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"]))


--disp:drawStr(122, 60, "V")


--disp:drawStr(0, 110, "V_mppt:")
--disp:drawStr(84, 110, V_in)
--disp:drawStr(122, 110, "V")


--disp:drawStr(56, 55, "Status:0x")
--disp:drawStr(110, 55, statuscode)
--disp:drawStr(62, 119, "@elektra_42")

disp:sendBuffer()
