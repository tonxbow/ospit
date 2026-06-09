-- ds18b20 connected to GPIO_2
 
local pin = 2
local addr = nil 
ow.setup(pin)
local count = 0
repeat
  count = count + 1
  addr = ow.reset_search(pin)
  addr = ow.search(pin)
until (addr ~= nil) or (count > 4)
if addr == nil then
  printv(1,"18b20: No more addresses.")
else
  printv(1,addr:byte(1,8))
  local crc = ow.crc8(string.sub(addr,1,7))
  if crc == addr:byte(8) then
    if (addr:byte(1) == 0x10) or (addr:byte(1) == 0x28) then
      printv(1,"Device is a DS18S20 family device.")
          ow.reset(pin)
          ow.select(pin, addr)
          ow.write(pin, 0x44, 1)
          local present = ow.reset(pin)
          ow.select(pin, addr)
          ow.write(pin,0xBE,1)
          printv(1,"18b20: P="..present)
          local data = nil
          local data = string.char(ow.read(pin))
	  local increment 		
          for increment = 1, 8 do
            data = data .. string.char(ow.read(pin))
          end

          printv(1,"18b20:",data:byte(1,9))
          crc = ow.crc8(string.sub(data,1,8))
          printv(1,"18b20: CRC="..crc)
          
          if crc == data:byte(9) then
             local tbits = (data:byte(1) + data:byte(2) * 256) * 625
             ow_temp1 = tbits / 10000
            if ow_temp1 > 200 then ow_temp1 = ow_temp1 - 4095 
          end
             printv(2,"Temp_i2c = " ..ow_temp1 .. " Celsius\n")
         end    
    else
      printv(4,"18b20: Device family is not recognized.\n")
          end
  else
    printv(4,"18b20: CRC is not valid!\n")
    
  end

end

