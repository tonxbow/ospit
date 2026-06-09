-- Calibration and board data

-- MPP range of FF-OpenMPPT-ESP32 v1.0
      Vmpp_max = 23.8 
      Vmpp_min = 14.45


-- MPP range of FF-OpenMPPT-ESP32 v1.1
--       Vmpp_max = 27.2
--       Vmpp_min = 13.25

-- MPP range of FF-OpenMPPT-ESP32 v1.2

--    Vmpp_max = 25.15
--    Vmpp_min = 12.86

-- The Vcc rail of the ESP32 is the Voltage 
-- reference for the temperature sensor
-- Measure this for your individual board

    pcbtemp_id  = "28089dde0b000031" -- This is the soldered PCB temperature monitor

    Vcc = 3.04
    
    hardware_version = "1.0"
    firmware_type = "ESP_2.0"

--  Is Schottky Diode D6 (Solar input) present on board? 
--  Choose "false" if D6 pads are bridged, else "true" if D6 is populated.
--  D6 burns some solar power and heats the board.
--  At 5 Ampere Solar input current, the D6 loss amounts to 2 Watt.

--  D6 makes the system safer but less efficient.
--  Power rating of the board is 120 Watt Solar input (U_mpp) *without* D6
--  Power rating *with* D6 populated is 100 Watt Solar input (U_mpp)
--  If D6 pads are bridged, the Solar+ connector carries power
--  from the battery. In theory, this can cause a small discharge
--  current at night.

--  Use this efficiency modification with caution.
--  Do not reverse polarity when connecting a solar module or 
--  short the solar module wires!


    D6_loaded=true
 
