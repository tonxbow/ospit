config={}

function config.parse(filename,cb,param)
	local f=file.open(filename)
	if (f == nil) then
		print("Failed to open",filename)
		return false
	end
	while(true) do
		line=f:readline()
		if (line == nil) then
			break
		end
		line=line:sub(1,-2)
		local data={line=line,param=param}
		if (not line:match('^%s*-')) then
			k,v,c=line:match('^%s*([^ ]+)%s*=%s*([^ ]+)%s*(--.*)')
			if (k ~= nil and v~= nil) then
				data.key=k
				data.rawvalue=v
				data.comment=c
				c=c:sub(3):match("^%s*(.-)%s*$")
				if ((v:sub(1,1) == "'" or v:sub(1,1) == '"') and v:sub(-1,-1) == v:sub(1,1)) then
					v=v:sub(2,-2)
					if (c == '') then
						c='string'
					end
				end
				data.type=c
				data.value=v
			end
		end
		if (cb(data) == false) then
			print("cb failed")
			return false
		end
		if (tmr.wdclr) then
			tmr.wdclr()
		end
	end
	f:close()
	print("Success")
	return true
end

function config.update_cp(from,tmp,to,changes)
	local f=file.open(tmp,'w')
	if (f == nil) then
		print("failed to open",tmp)
		return false
	end
	local ret=config.parse(from,function(data)
		local s=data.param
		if (data.key) then
			if (s[data.key]) then
				data.value=s[data.key]
			end
			data.rawvalue=(data.type == 'string' or data.type == 'password') and '"'..data.value..'"' or data.value
			data.line=data.key..'='..tostring(data.rawvalue)..(data.comment ~= '' and ' '..data.comment or '')
		end
		return f:write(data.line .. '\n')
	end,changes)
	f:close()
	if (ret) then
		file.remove(to)
		ret=file.rename(tmp,to)
	end
	return(ret)
end

function config.move_to_old()
	file.remove('config_old.lua')
	return file.rename('config.lua','config_old.lua')
end

function config.update_template(template,changes)
	local ret=config.move_to_old()
	if (ret) then
		ret=config.update_cp(template,'config.tmp','config.lua',changes)
	end
	return ret
end

function config.update(changes)
	return config.update_template('config_old.lua',changes)
end

function config.save()
	return config.update_template('config_default.lua',_G)
end

-- Initializing GPIO 0 for configuration reset trigger feature. Pulling IO0 to 3V3 before rebooting will reset the config to config_default. 
--gpio.set_drive(0, gpio.DRIVE_0)
gpio.config( { gpio={0}, dir=gpio.IN, pull=gpio.PULL_DOWN })
gpio.set_drive(0, gpio.DRIVE_0)

dofile "board.lua"
dofile "calibration.lua"


if (not file.exists('config.lua')) then
	print("Initializing config.lua from config_default.lua")
	config.update_cp('config_default.lua','config.tmp','config.lua',{})
end

print("WE ARE HERE!!!")
print("WE ARE HERE!!!")
print("WE ARE HERE!!!")
print("WE ARE HERE!!!")
print("WE ARE HERE!!!")
print(gpio.read(0))

if gpio.read(0) == 1 then 
	print("Resetting config.lua to config_default.lua as per user request! IO0 is pulled to HIGH")
	print("Backup of (possibly broken) config.lua to config_broken.lua")
	file.remove('config_broken.lua')
	file.rename('config.lua','config_broken.lua')
	config.update_cp('config_default.lua','config.tmp','config.lua',{})
end

dofile "config.lua"
if (enable_osprint ~= nil) then
	node.osprint(enable_osprint)
end
if (timezone ~= nil) then
	time.settimezone(timezone)
end
