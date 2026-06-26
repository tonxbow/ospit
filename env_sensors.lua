local env_sensors = {}

local I2C_ID = i2c.HW0
local BME280_CHIP_ID = 0x60
local BH1750_POWER_ON = 0x01
local BH1750_RESET = 0x07
local BH1750_CONT_H_RES_MODE = 0x10

local function get_number(name, default)
    local value = _G[name]
    if value == nil then
        return default
    end
    local numeric = tonumber(value)
    if numeric == nil then
        return default
    end
    return numeric
end

local function clear_bme280_values()
    bme280_temperature = -127
    bme280_humidity = -127
    bme280_pressure = -127
end

local function clear_bh1750_values()
    bh1750_lux = -127
end

clear_bme280_values()
clear_bh1750_values()

local function setup_bus()
    local sda = get_number('env_i2c_sda', 21)
    local scl = get_number('env_i2c_scl', 22)
    return pcall(i2c.setup, I2C_ID, sda, scl, i2c.FAST)
end

local function write_bytes(addr, ...)
    local payload = { ... }
    local ok = pcall(function()
        i2c.start(I2C_ID)
        if not i2c.address(I2C_ID, addr, i2c.TRANSMITTER) then
            error('i2c_nack')
        end
        for _, byte in ipairs(payload) do
            i2c.write(I2C_ID, string.char(byte))
        end
        i2c.stop(I2C_ID)
    end)
    return ok
end

local function read_bytes(addr, reg, len)
    local ok, data = pcall(function()
        i2c.start(I2C_ID)
        if not i2c.address(I2C_ID, addr, i2c.TRANSMITTER) then
            error('i2c_nack_tx')
        end
        i2c.write(I2C_ID, string.char(reg))
        i2c.stop(I2C_ID)
        i2c.start(I2C_ID)
        if not i2c.address(I2C_ID, addr, i2c.RECEIVER) then
            error('i2c_nack_rx')
        end
        local value = i2c.read(I2C_ID, len)
        i2c.stop(I2C_ID)
        return value
    end)
    if not ok then
        return nil
    end
    return data
end

local function u8(data, index)
    return string.byte(data, index + 1)
end

local function s8(value)
    if value > 127 then
        return value - 256
    end
    return value
end

local function u16le(data, index)
    return u8(data, index) + (u8(data, index + 1) * 256)
end

local function s16le(data, index)
    local value = u16le(data, index)
    if value > 32767 then
        return value - 65536
    end
    return value
end

local function s12(value)
    if value > 2047 then
        return value - 4096
    end
    return value
end

local function round2(value)
    return math.floor((value * 100) + 0.5) / 100
end

local bme280_cal = nil
local bh1750_ready = false

local function load_bme280_calibration(addr)
    local part1 = read_bytes(addr, 0x88, 26)
    local part2 = read_bytes(addr, 0xE1, 7)
    if part1 == nil or part2 == nil then
        return nil
    end

    local dig_H4 = s12(bit.lshift(u8(part2, 3), 4) + bit.band(u8(part2, 4), 0x0F))
    local dig_H5 = s12(bit.lshift(u8(part2, 5), 4) + bit.rshift(u8(part2, 4), 4))

    return {
        dig_T1 = u16le(part1, 0),
        dig_T2 = s16le(part1, 2),
        dig_T3 = s16le(part1, 4),
        dig_P1 = u16le(part1, 6),
        dig_P2 = s16le(part1, 8),
        dig_P3 = s16le(part1, 10),
        dig_P4 = s16le(part1, 12),
        dig_P5 = s16le(part1, 14),
        dig_P6 = s16le(part1, 16),
        dig_P7 = s16le(part1, 18),
        dig_P8 = s16le(part1, 20),
        dig_P9 = s16le(part1, 22),
        dig_H1 = u8(part1, 25),
        dig_H2 = s16le(part2, 0),
        dig_H3 = u8(part2, 2),
        dig_H4 = dig_H4,
        dig_H5 = dig_H5,
        dig_H6 = s8(u8(part2, 6))
    }
end

local function init_bme280()
    local addr = get_number('bme280_address', 118)
    local chip = read_bytes(addr, 0xD0, 1)
    if chip == nil or u8(chip, 0) ~= BME280_CHIP_ID then
        return false
    end
    if not write_bytes(addr, 0xF2, 0x01) then
        return false
    end
    if not write_bytes(addr, 0xF4, 0x27) then
        return false
    end
    if not write_bytes(addr, 0xF5, 0xA0) then
        return false
    end
    bme280_cal = load_bme280_calibration(addr)
    return bme280_cal ~= nil
end

local function read_bme280()
    if not bme280_enabled then
        clear_bme280_values()
        return true
    end

    local addr = get_number('bme280_address', 118)
    if bme280_cal == nil and not init_bme280() then
        clear_bme280_values()
        printv(1, 'BME280 init failed at address', addr)
        return false
    end

    local raw = read_bytes(addr, 0xF7, 8)
    if raw == nil then
        clear_bme280_values()
        printv(1, 'BME280 read failed at address', addr)
        return false
    end

    local adc_P = bit.lshift(u8(raw, 0), 12) + bit.lshift(u8(raw, 1), 4) + bit.rshift(u8(raw, 2), 4)
    local adc_T = bit.lshift(u8(raw, 3), 12) + bit.lshift(u8(raw, 4), 4) + bit.rshift(u8(raw, 5), 4)
    local adc_H = bit.lshift(u8(raw, 6), 8) + u8(raw, 7)

    local cal = bme280_cal
    local var1 = (adc_T / 16384.0 - cal.dig_T1 / 1024.0) * cal.dig_T2
    local var2 = ((adc_T / 131072.0 - cal.dig_T1 / 8192.0) * (adc_T / 131072.0 - cal.dig_T1 / 8192.0)) * cal.dig_T3
    local t_fine = var1 + var2
    local temperature = t_fine / 5120.0

    var1 = (t_fine / 2.0) - 64000.0
    var2 = var1 * var1 * cal.dig_P6 / 32768.0
    var2 = var2 + var1 * cal.dig_P5 * 2.0
    var2 = (var2 / 4.0) + (cal.dig_P4 * 65536.0)
    var1 = (cal.dig_P3 * var1 * var1 / 524288.0 + cal.dig_P2 * var1) / 524288.0
    var1 = (1.0 + var1 / 32768.0) * cal.dig_P1

    local pressure = -127
    if var1 ~= 0 then
        pressure = 1048576.0 - adc_P
        pressure = (pressure - (var2 / 4096.0)) * 6250.0 / var1
        var1 = cal.dig_P9 * pressure * pressure / 2147483648.0
        var2 = pressure * cal.dig_P8 / 32768.0
        pressure = pressure + (var1 + var2 + cal.dig_P7) / 16.0
        pressure = pressure / 100.0
    end

    local humidity = t_fine - 76800.0
    humidity = (adc_H - (cal.dig_H4 * 64.0 + cal.dig_H5 / 16384.0 * humidity)) * (cal.dig_H2 / 65536.0 * (1.0 + cal.dig_H6 / 67108864.0 * humidity * (1.0 + cal.dig_H3 / 67108864.0 * humidity)))
    humidity = humidity * (1.0 - cal.dig_H1 * humidity / 524288.0)
    if humidity > 100 then humidity = 100 end
    if humidity < 0 then humidity = 0 end

    bme280_temperature = round2(temperature)
    bme280_pressure = round2(pressure)
    bme280_humidity = round2(humidity)
    return true
end

local function init_bh1750()
    local addr = get_number('bh1750_address', 35)
    if not write_bytes(addr, BH1750_POWER_ON) then
        return false
    end
    write_bytes(addr, BH1750_RESET)
    if not write_bytes(addr, BH1750_CONT_H_RES_MODE) then
        return false
    end
    bh1750_ready = true
    return true
end

local function read_bh1750()
    if not bh1750_enabled then
        clear_bh1750_values()
        return true
    end

    local addr = get_number('bh1750_address', 35)
    if not bh1750_ready and not init_bh1750() then
        clear_bh1750_values()
        printv(1, 'BH1750 init failed at address', addr)
        return false
    end

    local ok, data = pcall(function()
        i2c.start(I2C_ID)
        if not i2c.address(I2C_ID, addr, i2c.RECEIVER) then
            error('i2c_nack_rx')
        end
        local value = i2c.read(I2C_ID, 2)
        i2c.stop(I2C_ID)
        return value
    end)
    if not ok or data == nil or #data < 2 then
        clear_bh1750_values()
        printv(1, 'BH1750 read failed at address', addr)
        bh1750_ready = false
        return false
    end

    local raw = bit.lshift(string.byte(data, 1), 8) + string.byte(data, 2)
    bh1750_lux = round2(raw / 1.2)
    return true
end

function env_sensors.read()
    if not bme280_enabled and not bh1750_enabled then
        clear_bme280_values()
        clear_bh1750_values()
        return true
    end

    if not setup_bus() then
        clear_bme280_values()
        clear_bh1750_values()
        printv(1, 'Environmental sensor I2C setup failed')
        return false
    end

    local ok_bme = read_bme280()
    local ok_bh = read_bh1750()
    return ok_bme or ok_bh
end

return env_sensors