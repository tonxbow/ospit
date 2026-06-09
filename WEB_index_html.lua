-- HTML output
local pagestring = "<html>mp2.lua not started yet</html>"

if not heatsink_temperature then heatsink_temperature = 0.0 end

if V_out ~= nil then 
    -- Start building the page header
    pagestring = "<html><h3><a href=\"config\">System Config</a> | <a href=\"control\">Control Panel</a> | <a href=\"time\">Time</a> | <a href=\"help.html\">Manual</a> |<a href=\"reboot\">Reboot</a></h3><h1>OSPIT</h1><h2>Status Page of "..nodeid.."</h2><b>Date</b> "..string.format("%04d-%02d-%02d", localTime["year"], localTime["mon"], localTime["day"]).."<br><b>Time</b> "..string.format("%02d:%02d:%02d", localTime["hour"], localTime["min"], localTime["sec"]).."<br><b>Uptime in seconds</b> "..node_uptime.."<h2>Battery status</h2><b>Health status</b> "..charge_status.." <br><b>Charge state </b>"..charge_state_int.."%<br><b>Battery voltage </b>"..V_out.." Volt<br><b>Battery temperature</b> "..battery_temperature.."&deg;C<h2>Environment status</h2><b>Air temperature</b> "..airtemp.."&deg;C<br>"

    -- Helper function to append sensor data only if valid
    local function append_sensor(label, val, unit)
        if val ~= -127 then
            pagestring = pagestring .. "<b>" .. label .. "</b> " .. val .. unit .. "<br>"
        end
    end

    -- Process sensors 1 through 4
    append_sensor("Soil humidity | Sector 1", shumidity1, "%")
    append_sensor("Soil temperature | Sector 1", stemp1, "&deg;C")
    append_sensor("Soil humidity | Sector 2", shumidity2, "%")
    append_sensor("Soil temperature | Sector 2", stemp2, "&deg;C")
    append_sensor("Soil humidity | Sector 3", shumidity3, "%")
    append_sensor("Soil temperature | Sector 3", stemp3, "&deg;C")
    append_sensor("Soil humidity | Sector 4", shumidity4, "%")
    append_sensor("Soil temperature | Sector 4", stemp4, "&deg;C")

    -- Append the footer/system stats
    pagestring = pagestring .. "<h2>Manual irrigation control</h2> <iframe src=\"./icontrol\" style=\"height:320px;width:300px;\" title=\"Irrigation valve control\"></iframe><h2>Water supply status</h2><b>Tank fill gauge</b> "..tankgauge.."%<h2>Solar power status</h2><b>Solar panel open circuit voltage</b> "..V_oc.." Volt<br><b>MPP-Tracking voltage</b> "..V_in.." Volt</html>"
end 
        
return function(conn)
    printv(3,"Pagestring",pagestring)
    send_response(pagestring)
end
