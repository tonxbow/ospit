-- owdetect.lua
local pin = 2
ow.setup(pin)
ow.reset_search(pin)

print("Searching for DS18B20 sensors...")
local addr = ow.search(pin)
local count = 0

while addr do
  local crc = ow.crc8(string.sub(addr, 1, 7))
  if crc == addr:byte(8) then
    count = count + 1
    local hex = string.format("%02x%02x%02x%02x%02x%02x%02x%02x", addr:byte(1,8))
    print(string.format("Sensor %d ID: %s", count, hex))
  end
  addr = ow.search(pin)
end

if count == 0 then print("No sensors found. Check pull-up resistor on GPIO 2.") end
ow.reset_search(pin)
