-- WiFi mode
-- One of: 1 = STATION, 2 = SOFTAP, 3 = STATIONAP, 4 = NULLMODE

print("WiFi Mode: ", wlanmode)

local function config_sta()
	wifi.sta.on("connected", function() print("sta connected") end)
	wifi.sta.on("got_ip", function(event, info)  print("sta got ip "..info.ip) localstaip = info.ip end)
	wifi.sta.config({ssid=sta_ssid, pwd=sta_pwd, auto=true}, true)
	if (sta_hostname ~= nil and sta_hostname ~= '') then
		wifi.sta.sethostname(sta_hostname)
	end
end

local function config_ap()
	wifi.ap.on("start")
	wifi.ap.on("sta_connected", function(event, info) print("Station connected:  "..info.mac ) end)
	wifi.ap.config({ssid=ap_ssid, pwd=ap_pwd, channel=ap_ch})
	wifi.ap.setip({ip=ap_ip, netmask=ap_nmask, gateway=ap_gw, dns=ap_dns})
	if (ap_hostname ~= nil and ap_hostname ~= '') then
		wifi.ap.sethostname(ap_hostname)
	end
end
if wlanmode == 1 then
	wifi.mode(wifi.STATION, true)
end
if wlanmode == 2 then
	wifi.mode(wifi.SOFTAP, true)
end
if wlanmode == 3 then
	wifi.mode(wifi.STATIONAP, true)
end
wifi.start()
if wlanmode == 1 or wlanmode == 3 then
	config_sta()
end
if wlanmode == 2 or wlanmode == 3 then
	config_ap()
end
if wlanmode == 4 then
	--config_ap(nil)
    print("Wifi is disabled")
end

uplinktimer = tmr.create()
uplinktimer:register(10000, tmr.ALARM_SINGLE, function() print("Starting NTP service") time.initntp() end)
uplinktimer:start()

