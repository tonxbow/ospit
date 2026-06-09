if (tcp_servers == nil) then
    tcp_servers={}
end
if (tcp_modules == nil) then
    tcp_modules={}
    setmetatable(tcp_modules, { __mode = "v" })
end

function server_connect(c,name)
    local mod=tcp_modules[name]
    if (not mod) then
	-- print("loading",name)
        mod=require(name)
	tcp_modules[name]=mod
	package.loaded[name]=nil
    else
	-- print(name,"already loaded")
    end
    mod(c)
end

function server_activate(name)
    local port=name:match("TCP_(%d*).*%.lua")
    if (port) then
	print("Activating",name)
	local s=net.createServer(net.TCP)
	tcp_servers[name]=s
	s:listen(port,function(c) server_connect(c,name:sub(1,-5)) end, true)
    end
end

function server_deactivate(name)
    local s=tcp_servers[name]
    pcall(s.close,s)
    tcp_servers[name]=nil
end

for key,value in pairs(file.list()) do
    server_activate(key)
end
