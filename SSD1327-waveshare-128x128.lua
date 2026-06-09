-- For Waveshare SSD1327 no-name display, using SPI port at 128x128 resolution

-- Available compiled-in fonts: 
-- font_6x10_tf
-- font_unifont_t_symbols

-- miso = 19 -- MISO GPIO 19 UEXT Header
-- TX_2 = 17 -- TX_2 GPIO 17 UEXT Header 
-- RX_2 = 16 -- RX_2 GPIO 16 UEXT Header

sclk = 18 -- SCLK GPIO 18 UEXT Header
mosi = 23 -- MOSI GPIO 23 UEXT Header
cs   = 5 -- SSEL GPIO 5 UEXT Header
dc   = 16 -- RX_2 GPIO 16 UEXT Header
res  = 17 -- TX_2 GPIO 17 UEXT Header

bus = spi.master(spi.HSPI, {sclk=sclk, mosi=mosi})
disp = u8g2.ssd1327_midas_128x128(bus, cs, dc, res)

disp:setFont(u8g2.font_6x10_tf)
disp:setFontRefHeightExtendedText()
disp:setDrawColor(1)
disp:setFontPosTop()
disp:setFontDirection(0)

disp:clearBuffer()

disp:drawStr(0, 0, "FF-ESP32-OpenMPPT")
disp:drawStr(0, 14, "Init is waiting now")
disp:drawStr(0, 24, "for 5 seconds.")
disp:drawStr(0, 34, "To interrupt booting")
disp:drawStr(0, 44, "type \"stop()\" in")
disp:drawStr(0, 54, "serial terminal.")

disp:sendBuffer()
