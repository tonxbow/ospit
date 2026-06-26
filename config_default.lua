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

-- Battery profile for automatic voltage and temperature defaults
battery_profile="AGM" -- option AGM;GEL;Flooded;LiFePO4;Custom

-- Base charge end voltage in mV (used when battery_profile=Custom)
batt_charge_voltage_mv=14100

-- Temperature compensation in mV per degree C from 25C (used when battery_profile=Custom)
batt_temp_coeff_mv_per_c=30

-- Charge end voltage cap in mV when battery temp is above limit (used when battery_profile=Custom)
batt_hot_charge_voltage_mv=13100

-- Battery temperature limit in C for hot charge cap
batt_charge_limit_temp_c=42

-- Battery overheat warning threshold in C
batt_temp_high_warn_c=40

-- Battery low temperature warning threshold in C
batt_temp_low_warn_c=-10

-- Low voltage disconnect threshold for main load output in V
low_voltage_disconnect=11.9

-- Low voltage reconnect threshold for main load output in V
low_voltage_reconnect=12.3

-- Enable deep sleep when low voltage disconnect triggers
low_voltage_sleep_enabled=true -- boolean

-- Deep sleep duration in microseconds for low voltage disconnect
low_voltage_sleep_us=300000000

-- USB output voltage disconnect threshold in V
usb_voltage_disconnect=12.8

-- USB output voltage reconnect threshold in V
usb_voltage_reconnect=13.4

-- Heatsink temperature derating start threshold in C
heatsink_derate_start_c=60

-- Heatsink temperature restore threshold in C
heatsink_derate_restore_c=58

-- Charge voltage derating step in mV when heatsink is hot
heatsink_derate_step_mv=100

------ Environmental sensors
-- Enable BME280 environmental sensor?
bme280_enabled=false -- boolean

-- I2C address for BME280 in decimal (0x76 = 118, 0x77 = 119)
bme280_address=118

-- Enable BH1750 light sensor?
bh1750_enabled=false -- boolean

-- I2C address for BH1750 in decimal (0x23 = 35, 0x5C = 92)
bh1750_address=35

-- Shared I2C SDA pin for environmental sensors
env_i2c_sda=21

-- Shared I2C SCL pin for environmental sensors
env_i2c_scl=22

-- Polling interval for environmental sensors in milliseconds
env_sensor_interval_ms=30000
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
-- MQTT username (leave blank for anonymous access)
mqttbrkr1_user=""
-- MQTT password (leave blank for anonymous access)
mqttbrkr1_password="" -- password
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
-- MQTT username (leave blank for anonymous access)
mqttbrkr2_user=""
-- MQTT password (leave blank for anonymous access)
mqttbrkr2_password="" -- password
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
