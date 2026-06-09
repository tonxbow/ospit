local cmds_wget={}

local function putcontents(filename,data)
	local fd = file.open(filename, "w")
	if fd == nil then return nil end
	if (fd:write(data) == nil) then return nil end
	fd:close()
	return true
end

function cmds_wget.wget(ctx,url,filename,md5,async)
	local ret=0
	local count=0
	local hash
	local fd

	if (filename == nil) then
		filename=url:gsub(".*/", "")
	end
	if (filename == 'ota:') then
		otaupgrade.commence()
	else
		fd=shell.open(ctx,"wget.tmp", "w")
		if (fd == nil) then
			return -1
		end
	end
	if (md5 ~= nil) then
		hash=crypto.new_hash("MD5")
	end
	ctx.stdout:write("Getting '"..url.."' to '"..filename.."' ")
	connection = http.createConnection(url, http.GET, { async=async } )
	connection:on("complete", function(status, connected)
		if (filename ~= 'ota:') then
			fd:close()
		end
		ctx.stdout:write("\nRequest completed with status code "..status..','..count.." packets\n")
		if (status == 200) then
			if (hash) then
				digest=hash:finalize()
				hex=''
				for i=1,digest:len() do
					hex=hex..string.format('%02x',string.byte(digest,i))
				end
				if (hex ~= md5) then
					ctx.stderr:write("MD5 failed "..hex.." vs " .. md5 .. "\n")
					ret=-1
					return ret
				end
			end
			if (filename == 'ota:') then
				otaupgrade.complete()
				ctx.stdout:write("Update complete, please reboot\n")
			else
				file.remove(filename)
				if (file.rename("wget.tmp",filename) == nil) then
					ctx.stderr:print("failed to rename file")
					ret=-1
				end
			end
		end
	end)
	connection:on("data", function(status, data)
		ctx.stdout:write(".")
		if (tmr.wdclr) then
			tmr.wdclr()
		end
		if (hash) then
			hash:update(data)
		end
		count=count+1
		if (filename == 'ota:') then
			otaupgrade.write(data)
		else
			if (fd:write(data) == nil) then
				ctx.stderr:print("failed to write wget.tmp")
				ret=-1
				connection:close()
			end
		end
		if ((count % 100) == 0 and async) then
			t=tmr.create()
			t:alarm(10, tmr.ALARM_SINGLE, function() connection:ack() end)
			return http.DELAYACK
		end
	end)
	connection:request()
	if (async) then
		ctx.stdout:write("Resuming in Background\n")
	end
	return ret
end

return cmds_wget
