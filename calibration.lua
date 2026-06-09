Vref = 1100 --mV

files = file.list()

if file.exists("VrefCal") then

    print("Vref already calibrated. Great!")
    file.open("VrefCal", "r")
    Vref = file.readline()
    print("VrefValue is set to:", Vref, "mV" )
    file.close()

else

    print("VrefCal not found. Vref of ESP chip *not* calibrated. Using default Vref value of 1100 mV")
    print("It is recommended to calibrate Vref using vrcal.lua and a laboratory power supply.")

end
