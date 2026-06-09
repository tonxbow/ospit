return function(socket)
    local fifo = {}
    local rxbuffer = ''
    local ctl = false
    local auth = 0
    local username = ''
    local ctx = {}
    local txbytes = 0
    local sync_limit=20000

    local function sender(c,sync)
        if #fifo > 0 then
	    local str=table.remove(fifo, 1)
	    txbytes=txbytes+str:len()
            c:send(str)
	    if (tmr.wdclr) then
	       tmr.wdclr()
	    end
	else
	    txbytes=0
        end
    end

    local function strip_lf()
	if (rxbuffer:byte(1) == 0x0a) then
	    rxbuffer=rxbuffer:sub(2)
	 end
    end

    local function get_line()
	strip_lf()
	local pos=rxbuffer:find('\r')
	if (pos == nil) then
	    return nil
	end
        local ret=rxbuffer:sub(1,pos-1)
	rxbuffer=rxbuffer:sub(pos+1)
	strip_lf()
	return ret
    end

    local function s_output(str)
	if (str == nil or str == '') then
	    return
	end
        table.insert(fifo, str)
	if (txbytes == 0 or txbytes+str:len() < sync_limit) then
            sender(socket)
        end
    end

    local function write(self,str)
	s_output(str)
    end

    local function close()
	local t=tmr.create()
	t:alarm(50, tmr.ALARM_SINGLE, function() 
	    socket:close()
	    socket=nil
        end)
    end

    socket:on("receive", function(c, l)
	rxbuffer=rxbuffer .. l
	while (rxbuffer:byte(1) == 0xff and rxbuffer:len()>=3) do
	    local next=4
	    if (rxbuffer:byte(2) == 0xfa) then
		_,next=rxbuffer:find(string.char(0xff)..string.char(0xf0))
		if (next == nil) then
		    return
		end
		next=next+1
	    end
            if (ctl == false) then
	        ctl = true
                s_output(string.char(0xff)..string.char(0xfd)..string.char(0x22).. -- DO LINEMODE
	                 string.char(0xff)..string.char(0xfa)..string.char(0x22).. -- SUBNEGOTIATE BEGIN
			 string.char(1)..string.char(1).. -- LINEMODE EDIT
                         string.char(0xff)..string.char(0xf0)) -- SUBNEGOTIATE END
	    end
	    rxbuffer=rxbuffer:sub(next)
	end
	local line=get_line()
	if (line == nil) then
	    return
	end
	if (auth == 0) then
	    username=line
	    if (ctl) then
	        s_output(string.char(0xff)..string.char(0xfb)..string.char(0x01)) -- WILL ECHO
	    end
    	    s_output("Password: ")
	    auth=1
        elseif (auth == 1) then
	    s_output("\r\n")
	    if (ctl) then
	        s_output(string.char(0xff)..string.char(0xfc)..string.char(0x01)) -- WONT ECHO
	    end
	    if (require('auth').authenticate(username,line,true)) then
		if (username == 'lua') then auth=2 end
		if (username == 'root') then auth=3 end
	    else
                auth=0
	    end
	    if (auth < 2) then
		s_output("Login incorrect\n")
		close()
		return
	    end
	    if (auth == 2) then
		node.output(s_output, 0)
            	node.input('\n')
	    elseif (auth == 3) then
		require('shell')
                ctx.stdin=io:new{write=write}
                ctx.stdout=ctx.stdin
                ctx.stderr=ctx.stdin
                ctx.exit=close
                shell.prompt(ctx)
	    end
        elseif (auth == 2) then
            node.input(line..'\r')
        elseif (auth == 3) then
            shell.cmd(ctx, line)
            shell.prompt(ctx)
        end
    end)
    socket:on("disconnection", function(c)
        if (auth == 2) then
	    node.output(nil)
        end
    end)
    socket:on("sent", sender)

    s_output("Welcome to NodeMCU world.\n"..require('auth').challenge().."\nlogin: ")
end
