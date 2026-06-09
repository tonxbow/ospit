if not loadurl or loadurl == "" then printv(1,"Variable \"loadurl\" not set.\n Example: loadurl = \"http://elektrad.info\"") return end

watchfailcount = 0

loadresettimer = tmr.create()

loadresettimer:register(10000, tmr.ALARM_SINGLE, function()
        if V_out > 12.0 and load_disabled == false then 
        gpio.wakeup(14, gpio.INTR_HIGH)
        gpio.write(14, 1)
        low_voltage_disconnect_state = 1
        printv(1,"Message from loadresettimer: Enabled power output.")
        end
    end)


loadwatchtimer = tmr.create()

loadwatchtimer:register(60000, tmr.ALARM_AUTO, function()
                   printv(2,"Loadwatch process started\nWatching http(s) loadurl: ", loadurl)   
                   connection = http.createConnection(loadurl )
                   connection:on("complete", function(status)
                   printv(2,"Load watchdog connecting to =", loadurl, "\n Completed with status code =", status)
                   if status ~= 200 then watchfailcount = watchfailcount + 1 end
                   if status == 200 then watchfailcount = 0 end
                   printv(2,"Watchfailcounter =", watchfailcount)
                   if watchfailcount >= 15 and load_disabled == false then printv(1, "Testing http(s) connect failed ", watchfailcount, "times!\nWill reset load now!")
                                gpio.wakeup(14, gpio.INTR_LOW)
                                gpio.write(14, 0)
                                low_voltage_disconnect_state = 0
                                printv(1,"Disabled power output. Load reset timer started.\nWill re-enable power output in 10 seconds")
                                watchfailcount = 0 
                                loadresettimer:start()
                                end
                   connection:close()         
                    end)
                connection:request()
    end)

loadwatchtimer:start()
