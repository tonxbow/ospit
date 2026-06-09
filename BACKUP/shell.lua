cmds_shell={}

function cmds_shell.exit(ctx)
	ctx:exit()
end

function cmds_shell.rehash(ctx)
	shell.rehash()
	return 0
end

shell={}

local function get_module(name)
	if (shell.module == nil) then
		shell.module={}
		setmetatable(shell.module, { __mode = "v" })
	end
	local mod=shell.module[name]
	if (not mod) then
		-- print("loading",name)
		mod=require(name)
		package.loaded[name]=nil
		shell.module[name]=mod
	else
		-- print(name,"already loaded")
	end
	return mod
end

local function proxy(name,cmd,...)
	local mod=get_module(name)
	return mod[cmd](...)
end

function shell.rehash()
	local cmds={}
	for key,value in pairs(file.list()) do
	    if (key:match("CMD_.*%.lua")) then
		-- print(key)
		local name=key:sub(1,-5)
		local mod=get_module(name)
		for key2,value2 in pairs(mod) do
		    -- print(key,":",key2)
		    cmds[key2]=function(...) return proxy(name,key2,...) end
		end
	    end
	end
	shell.cmds=cmds
end

function shell.cmd_tables()
	local list={}
	-- table.insert(shell.cmds)
	for key,item in pairs(_G) do
                if (key:sub(0,5) == 'cmds_') then
			-- print("global",key)
			table.insert(list,item)
		end
	end
	if (shell.cmds) then
		table.insert(list,shell.cmds)
	end
	return list
end

function shell.help(ctx,tables)
	local list={}
	ctx.stdout:print("Following commands exist:")
	for key,item in pairs(tables) do
		-- print("key",key)
		for key,item in pairs(item) do
			-- print("key",key,type(item))
			if (type(item) == "function") then
				table.insert(list,key)
			end
		end
	end
	table.sort(list)
	for k,v in pairs(list) do ctx.stdout:print(v) end
	return 0
end

function shell.cmd_exec(ctx,tables,cmd,args)
	if (cmd == 'help' or cmd == '' or cmd == nil) then
		return shell.help(ctx,tables)
	end
	for key,item in pairs(tables) do
		local f=item[cmd]
		if (f) then
			local status,ret=xpcall(function() return f(ctx,unpack(args)) end ,function(x) return x.."\n"..debug.traceback() end)
			-- print("xpcall","status",status,"ret",ret)
			if (status) then
				return ret
			end
			ctx.stderr:print(ret)
			return -2
		end
	end
	ctx.stderr:print("Command '"..cmd.."' not found, use 'help' for help")
	return -22
end

function shell.pack(...)
	return { n = select("#", ...), ... }
end

function shell.cmd2(ctx,tables,cmd,...)
	return shell.cmd_exec(ctx,tables,cmd,shell.pack(...))
end

function shell.cmd_line(ctx,c)
	if (c:match('[A-Za-z_][0-9A-Za-z_]*=.*')) then
		pcall(loadstring(c))
		return 0
	end
	local args=shell.words(c)
	local cmd=table.remove(args,1)
	if (cmd == nil or cmd == "") then return end
	local ret=shell.cmd_exec(ctx,shell.cmd_tables(),cmd,args) 
	if (ret == nil) then ret=0 end
	return ret
end

function shell.response(ret)
	if (ret < 0) then
		return("ERR "..ret)
	elseif (ret > 0) then
		return("OK "..ret)
	else
		return("OK")
	end
end

function shell.cmd(ctx,c)
	ret=shell.cmd_line(ctx,c)
	if (ret == nil) then
		return
	end
	ctx.stderr:print(shell.response(ret))
	end

function shell.cmd_str(c)
	str_ctx={}
	str_ctx.stdin=iostr:new()
	str_ctx.stdout=iostr:new()
	str_ctx.stderr=iostr:new()
	ret=shell.cmd_line(str_ctx,c)
	return ret,str_ctx.stdout.data,str_ctx.stderr.data
end

function shell.filter(ctx,from,to,tomode,filterfunc,post)
	local fd1=shell.open(ctx,from,"r")
	if (fd1 == nil) then return -1 end
	local fd2=shell.open(ctx,to,tomode)
	local ret=0
	if (fd2) then
		while true do
			str=fd1:readline()
			if (str == nil) then
				break
			end
			str=filterfunc(str)
			if (str) then
				if (shell.write(ctx,to,fd2,str) == nil) then
					ret=-1
					break
				end
			end
		end
		if (post) then
			if (shell.write(ctx,to,fd2,post) == nil) then
				ret=-1
			end
		end
		fd2:close()
	end
	fd1:close()
	return ret
end

function shell.on(ctx,data)
	if (data == "\r" or data == "\n") then
		ctx.stderr:write("\r\n")
		shell.cmd(ctx,ctx.cmdline)
		ctx.cmdline=""
		shell.prompt(ctx)
	elseif (data == "\b") then
		local len=ctx.cmdline:len()
		if (len > 0) then
			ctx.cmdline=ctx.cmdline:sub(0,len-1)
			ctx.stderr:write("\b \b")
		end
	else
		ctx.cmdline=ctx.cmdline..data
		ctx.stderr:write(data)
	end
end

function shell.open(ctx,name,mode)
	local fd=file.open(name,mode)
	if (fd == nil) then
		ctx.stderr:print("Failed to open '"..name.."'")
	end
	return fd
end

function shell.prompt(ctx)
	ctx.stderr:write("# ")
end

function shell.rename(ctx,old,new)
	file.remove(new)
	if (file.rename(old,new)) then
		return 0
	end
        ctx.stderr.print("Failed to rename '"+old+"' to '"+new+"'")
	return -1
end

function shell.run()
	uart_ctx={}
	uart_ctx.stdin=io:new{write=function(self,str) uart.write(0, str) end}
	uart_ctx.cmdline=""
	uart.on(0,"data", 0, function(data) uart_ctx.stdin:on(data) end, 0)
	uart_ctx.stdin.on=function(self,data) shell.on(uart_ctx,data) end
	uart_ctx.stdout=uart_ctx.stdin;
	uart_ctx.stderr=uart_ctx.stdin;
	uart_ctx.exit=function(self) uart_ctx={}; uart.on("data") end
	shell.prompt(uart_ctx)
end

function shell.words(str)
	local args={}
	for arg in str:gmatch("%S+") do table.insert(args, arg) end
	return args
end

function shell.write(ctx,file,fd,data)
	local ret=fd:write(data)
	if (ret == nil) then
		ctx.stderr:print("Failed to write to '"+file+"'")
	end
	return ret
end


io={}

function io:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function io.print(self,...)
	local n = select("#",...)
	for i = 1,n do
		local v = tostring(select(i,...))
		self:write(v)
		if i~=n then self:write("\t") end
	end
	self:write("\n")
end

iostr=io:new()

function iostr.write(self, str)
	self.data=(self.data or "")..str
end

shell.rehash()

return shell
