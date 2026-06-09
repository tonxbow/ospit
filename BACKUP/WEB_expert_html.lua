-- HTML output

local pagestring = "<html>mp2.lua not started yet</html>"

if not heatsink_temperature then heatsink_temperature = 0.0 end

if V_out ~= nil then pagestring= "<html><a href=\"control\">Control</a>  <a href=\"reboot\">Reboot</a>  <a href=\"config\">Configuration</a>  <a href=\"router\">Routing</a>  <a href=\"help.html\">Help</a>  <a href=\"csv.log\">CSV-Log</a>  <a href=\"random\">Nonce</a><br><br><h1>Independent Solar Energy Mesh</h1><br><h2>Status of "..nodeid.."</h2><br>Local time: "..string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"], localTime["dst"]).."<br>Summary: "..charge_status..". "..system_status.."<br>Humidity sensor 1: "..humidity1.."%<br>Humidity sensor 2: "..humidity2.."%<br>Tank fill gauge: "..tankgauge.."%<br>Charge state: "..charge_state_int.."%<br>Next scheduled reboot by watchdog in: "..nextreboot.." minutes<br>Battery voltage: "..V_out.." Volt<br>Temperature corrected charge end voltage: "..V_out_max_temp.." Volt<br>Battery temperature: "..battery_temperature.."&deg;C<br>Battery health estimate: "..health_estimate.."%<br>Power save level: "..powersave.."<br>Solar panel open circuit voltage: "..V_oc.." Volt<br>MPP-Tracking voltage: "..V_in.." Volt<br>Low voltage disconnect voltage: "..low_voltage_disconnect.." Volt<br>Rated battery capacity (when new): "..ah_batt.." Ah<br>Rated solar module power: "..pv_watt.." Watt<br>Unix-Timestamp: "..timestamp.." (local time)<br>Solar controller type and firmware: "..hardware_version.." "..firmware_type.."<br>Latitude: "..lat.."<br>Longitude: "..long.."<br>Status code: 0x"..statuscode.."<br>Free RAM in Bytes: "..freeRAM.."<br>Uptime in seconds: "..node_uptime.."<br>Heatsink temperature: "..heatsink_temperature.."&deg;C</html>"


end 
        
return function(conn)
    printv(3,"Pagestring",pagestring)
    send_response(pagestring)
end
