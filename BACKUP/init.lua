 dofile"SSD1306.lua"
--dofile"SSD1327-waveshare-128x128.lua"

function run_file(file)
    print("Starting",file)
    dofile(file)
    print_free()
end

function run_prefix(prefix)
    local files={}
    for key,value in pairs(file.list()) do
        if (key:match(prefix.."%d%d.*%.lua")) then
	    table.insert(files,key) 
        end
    end
    table.sort(files)
    for i,value in ipairs(files) do
        run_file(value)
    end
end

function start()
    run_prefix("S")
    run_file("is.lua")
end

function kill()
    run_prefix("K")
end

function print_free()
	print(node.heap().." Bytes free, "..(collectgarbage("count")*1024).." in use")
end

print_free()
boottimer = tmr.create()
print("Booting in 5 seconds, enter stop() to cancel")
boottimer:register(5000, tmr.ALARM_SINGLE, start)
boottimer:start()

function stop()
	boottimer:stop()
end
