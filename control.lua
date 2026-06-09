local control = {}

local function load(cmd)
	if (cmd == 'turn_OFF') then
		gpio.wakeup(14, gpio.INTR_LOW)
		gpio.write(14, 0)
		load_disabled = true
	end
	if (cmd == 'turn_ON' and low_voltage_disconnect_state == 1) then
		gpio.wakeup(14, gpio.INTR_HIGH)
		gpio.write(14, 1)
		load_disabled = false
	end
	return not (load_disabled or low_voltage_disconnect_state ~= 1)
end

local function gpio_device(pin, state_var)
	return function(cmd)
		if cmd == 'turn_OFF' then
			gpio.wakeup(pin, gpio.INTR_LOW)
			gpio.write(pin, 0)
			_G[state_var] = false
		end

		if cmd == 'turn_ON' and low_voltage_disconnect_state == 1 then
			gpio.wakeup(pin, gpio.INTR_HIGH)
			gpio.write(pin, 1)
			_G[state_var] = true
		end

		if cmd == 'status' then
			return _G[state_var] and low_voltage_disconnect_state == 1
		end
	end
end

local items = {
	ftp = 'TCP_21_ftp.lua',
	telnet = 'TCP_23_telnet.lua',
	web = 'TCP_80_web.lua',
	mpptracker = function(cmd)
		if (cmd == 'status') then
			local running = mppttimer:state()
			return running
		end
		if (cmd == 'turn_OFF') then
			mppttimer:stop()
		end
		if (cmd == 'turn_ON') then
			mppttimer:start()
		end
		return false
	end,
	load = load,
	valve_1 = gpio_device(26, "valve_1_state"),
	valve_2 = gpio_device(27, "valve_2_state"),
	valve_3 = gpio_device(12, "valve_3_state")
}

control.display_names = {
	valve_1 = "Irrigation Sector 1",
	valve_2 = "Irrigation Sector 2",
	valve_3 = "Irrigation Sector 3 or USB load output",
	load = "Load power output",
	web = "Web server",
	telnet = "Telnet server",
	mpptracker = "Solar Maximum Power Point Charger",
	ftp = "FTP server"
}

control.item_order = {
	'valve_1',
	'valve_2',
	'valve_3',
	'load',
	'mpptracker',
	'web',
	'telnet',
	'ftp'
}

function control.command(cmd, what)
	local item = items[what]
	if (item == nil) then
		return false
	end
	if (type(item) == 'string') then
		if (cmd == 'status') then
			return tcp_servers[item]
		end
		if (cmd == 'turn_OFF') then
			server_deactivate(item)
		end
		if (cmd == 'turn_ON') then
			server_activate(item)
		end
		return tcp_servers[item]
	end
	return item(cmd)
end

return control
