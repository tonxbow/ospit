-- Lines beginning with (--) are comments.
-- BEGIN
------  Irrigation system
-- Enable irrigation?
i_nbld=false -- boolean

-- Humidity level when valve/pump 1 closes/stops
i_lvl1=80

-- Humidity level when valve/pump 2 closes/stops
i_lvl2=80

-- Humidity level when valve/pump 3 closes/stops
i_lvl3=80

-- Is a tank gauge sensor connected?
i_tanksens=false -- boolean

-- Max opening time of valves (in minutes)
i_vlv_opn=5

-- Hour of day when irrigation starts
i_hr=3

------ Battery and Solar Module
-- Rated capacity of battery in Amperehours (Ah)
ah_batt=18

-- Power rating of the solar module in Watt.
pv_watt=50

-- Average power consumption of the system in Ampere (A)
av_pwr=1
------ WIFI
-- WiFi mode
-- One of: 1 = STATION, 2 = SOFTAP, 3 = STATIONAP, 4 = NULLMODE
wlanmode=2 -- option 1;2;3;4

---- Station
-- Wifi station AP SSID (the existing WiFi-AP that the device should connect to as a WiFi client)
sta_ssid="Example"

-- WPA key to connect to the existing AP as WiFi client
sta_pwd="12345678" --password

-- Station hostname (leave blank for default)
sta_hostname=""

---- Accesspoint
-- Accesspoint SSID
ap_ssid="OpenMPPT"

-- Accesspoint WPA key (can not be blank)
ap_pwd="12345678" -- password

-- Accesspoint WiFi channel
ap_ch="11"

-- Accesspoint IP
ap_ip="192.168.10.10"

-- Accesspoint Netmask
ap_nmask="255.255.255.0"

-- Internet gateway IP
ap_gw="192.168.10.1"

-- DNS server IP
ap_dns="8.8.8.8"

-- Accesspoint hostname (leave blank for default)
ap_hostname=""

------ System
-- Password for services
-- Note: Passwords are send unencrypted
webkey="pass123" -- password

-- Autoreboot timer in minutes
-- Set to 0 to disable.
nextreboot=7200

-- The logic of the local timezone setting in the SDK is reversed.
-- To get UTC+2 you actually need to set UTC-2.
timezone="CEST-1"

-- Latitude of Geolocation
lat=52.4997

-- Longitude
long=13.3755

-- Node-ID
nodeid="ospit"

-- Verbosity level: 0 (critical errors only)
-- up to 4 (very verbose)
verbose=1 -- option 1;2;3;4

---- MQTT-Telemetry configuration
-- Enable MQTT?
mqtt_enabled=true -- boolean
-- MQTT broker to connect to
mqttbrkr1_host="isems.mqtthub.net"
-- Port to connect to
mqttbrkr1_port=1883
-- The telemetry channel to send our data to. 
mqttbrkr1_channel="isems/testdrive/foobar/"
-- Close connection after sending data?
-- Recommended if setting up 2 brokers
mqttbrkr1_close=true -- boolean
-- Use only last (newest) csv data line
-- If set to false, the last 5 csv data lines are send
-- not used if we send json data
mqttbrkr1_short=false -- boolean
-- Send JSON data instead of CSV data
mqttbrkr1_json=true -- boolean

-- Second MQTT broker to connect to (leave blank to disable it)
mqttbrkr2_host=""
-- Port to connect to
mqttbrkr2_port=1883
-- Telemetry channel to send metrics to.
mqttbrkr2_channel=""
-- Close connection after sending data
-- Recommended if setting up two brokers
mqttbrkr2_close=true -- boolean
-- Use only last (newest) csv data line
-- not used if we send json data
mqttbrkr2_short=false -- boolean
-- Send JSON data instead of CSV data
mqttbrkr2_json=true -- boolean
