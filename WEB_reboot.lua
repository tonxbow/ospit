return function (info)
        if (not authenticated()) then
               return
        end
		send_response("<html><head><meta http-equiv=\"refresh\" content=\"10; URL=/index.html\"></head><body><h3>Rebooting in 1 second. Will be back in less than 10 seconds. </h3></body></html>")
		reboottimer = tmr.create()
		reboottimer:register(1000, tmr.ALARM_SINGLE, function()
			node.restart()
		end)
                reboottimer:start()
		return
end
