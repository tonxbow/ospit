local cmds_pkg={}
local subcmds_pkg={}

function cmds_pkg.pkg(ctx,...)
	return shell.cmd2(ctx,{subcmds_pkg},...)
end

local function set_installed(ctx,pcols)
	local oldversion=0
	local post
	if (pcols[2]) then
		post=table.concat(pcols," ") .. "\n"
	end
	
	shell.filter(ctx,"installed.txt","installed.tmp","w",function(line)
		local cols=shell.words(line)
		if (cols[1] == pcols[1]) then
			oldversion=cols[2]
			return nil
		else
			return line
		end
	end,post)
			
	shell.rename(ctx,"installed.tmp","installed.txt")
	return oldversion
end

local function concat_path(p1,p2)
	while (p2:sub(1, 3) == '../') do
		local index=p1:sub(1,-2):match('^.*()/')
		p1=p1:sub(1,index)
		p2=p2:sub(4)
	end
	return p1..p2
end

function subcmds_pkg.install(ctx,name)
	local fd = file.open("packages.txt")
	local done=0
	if (fd) then
		while true do
			local str=fd:readline()
			if (str == nil) then
				break
			end
			local cols=shell.words(str)
			if (cols[1] == name) then
				local dest="install.tmp"
				local async=false
				if (name == 'NodeMCU.bin') then
					dest='ota:'
					async=tmr.wdclr == nil
				end
				shell.cmd_exec(ctx,shell.cmd_tables(),'wget',{cols[4],dest,cols[3],async})
				if (dest ~= 'ota:') then
					shell.rename(ctx,dest,name)
				end
				set_installed(ctx,cols)
				if (name:match("S%d%d.*%.lua")) then
					run_file(name)
				end
				done=done+1
			end
                end
		fd:close()
	end
	if (done == 0) then
		ctx.stderr:print("package not found")
		return -1
	end
	return 0
end

function subcmds_pkg.uninstall(ctx,name)
	local status=set_installed(ctx,{name})
	if (status == nil or status == 0) then
		ctx.stderr:print("Package "..name.." not found")
		return -1
	end
	file.remove(name)
end

function subcmds_pkg.up(ctx)
	local ret=subcmds_pkg.update(ctx)
	if (ret == 0) then
		ret=subcmds_pkg.upgrade(ctx)
	end
	return ret
end

function subcmds_pkg.update(ctx)
	local fd=shell.open(ctx,"feeds.txt","r")
	if (fd == nil) then return -1 end
	local ret=0
	file.remove("packages.tmp2")
	while (ret == 0) do
		local str=fd:readline()
		if (str == nil) then break end
		local cols=shell.words(str)
		local baseurl=cols[1]
		ret=shell.cmd_exec(ctx,shell.cmd_tables(),'wget',{baseurl .. "packages.txt","packages.tmp1"})
		if (ret ~= 0) then break end
		ret=shell.filter(ctx,"packages.tmp1","packages.tmp2","a",
			function(line)
				local cols=shell.words(line)
				cols[4] = concat_path(baseurl,cols[4])
				return table.concat(cols," ").."\n"
			end)
		file.remove("packages.tmp1")
	end
	fd:close()
	if (ret ~= 0) then return ret end
	shell.rename(ctx,"packages.tmp2","packages.txt")
	return 0
end

function subcmds_pkg.upgrade(ctx)
	local fd=shell.open(ctx,"installed.txt","r")
	if (fd == nil) then return -1 end
	local ret=0
	local installed={}
	while (ret == 0) do
		local str=fd:readline()
		if (str == nil) then break end
		local cols=shell.words(str)
		installed[cols[1]]=cols[2]
	end
	fd:close()
	local fd=shell.open(ctx,"packages.txt","r")
	if (fd == nil) then return -1 end
	while (ret == 0) do
		local str=fd:readline()
		if (str == nil) then break end
		local cols=shell.words(str)
		local pkg=cols[1]
		local oldv=installed[pkg]
		local newv=cols[2]
		if (oldv and tonumber(oldv) < tonumber(newv)) then
			ctx.stdout:print("Updating " .. pkg .. ' from ' .. oldv .. ' to ' .. newv)
			subcmds_pkg.install(ctx,pkg)
		end
	end
	fd:close()
end

return cmds_pkg
