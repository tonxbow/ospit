--GPIO35, BoardTempSens channel 7 
-- List of ADC1 channels
-- 0: GPIO36, 1: GPIO37, 2: GPIO38, 3: GPIO39, 4: GPIO32, 5: GPIO33, 6: GPIO34, 7: GPIO35

heatsinktempadc = ADCmeasure(7, 2)

if heatsinktempadc >= 4000 then 
    
    printv(1,"Heatsink temperature sensor not detected. Is the polarity of the sensor reversed?")
    heatsink_temperature = 0.0
    heatsink_tempsens_missing = 1
    adc.setup(adc.ADC1, 7, adc.ATTEN_11db)
    heatsink_temperature_previous = nil
end
    
if heatsinktempadc < 4000 then

heatsink_tempsens_missing = 0
    
adc.setup(adc.ADC1, 7, adc.ATTEN_6db)
-- print("Temperature sensor connected")

-- Vref11dB = Vref * 0.0034
local Vref6dB = Vref * 0.002

heatsinktempadc = ADCmeasure(7, 100)

-- Measured with 2 x 1N4148 diodes forward voltage in series at 39k Ohm

heatsink_sensor_voltage = ((heatsinktempadc / 4095) * Vref6dB) / 1.06

heatsink_temperature = -50 + ((1.273 - heatsink_sensor_voltage) / 0.0048)

printv(0,"Heatsink sensor voltage: ", heatsink_sensor_voltage, "V")
printv(0,"Heatsink temperature: ", heatsink_temperature, "degrees celsius")


adc.setup(adc.ADC1, 7, adc.ATTEN_11db)

end

