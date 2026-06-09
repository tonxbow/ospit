if webkey == nil then webkey = "empty" end

if encrypted_webkey == true then  randomstring,  webkeyhash = cryptokey (webkey) end

if encrypted_webkey == false or encrypted_webkey == nil then webkeyhash = webkey randomstring = "Encryption not enabled." end


return function(conn)

    local function send(ctx,...)
        local n=select("#",...)
        local t={...}
        for i=1,n do
            if (t[i] ~= nil and t[i] ~= '') then
                local s=tostring(t[i])
                local l=s:len()
                table.insert(ctx.response,s)
                if (ctx.txbytes == 0 or ctx.txbytes+l < ctx.sync_limit) then
                    tmr:wdclr()
                    ctx:send_next()
                end
            end
        end
    end
    
    local function send_next(ctx)
       if #ctx.response > 0 then
            local str=table.remove(ctx.response, 1)
            ctx.txbytes=ctx.txbytes+str:len()
            pcall(ctx.conn.send,ctx.conn,str)
            if (tmr:wdclr()) then
                tmr:wdclr()
            end
        else
            ctx.conn:close()
	    ctx.conn=nil
        end
    end
    
    local function urldecode(str)
        str = string.gsub (str, "+", " ")
        str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
        return str
    end
    
    
    function authenticated(ctx)
        if (not ctx) then
            ctx=webctx
        end
        local user,pass
        local a=ctx.headers['authorization']
        if (a) then
            user,pass=encoder.fromBase64(a:match('^Basic +(.*)')):match('^([^:]*):(.*)')
        end
        local auth=require('auth')
        if (auth.authenticate(user,pass,true)) then
            return true
        end
        ctx:send('HTTP/1.0 401 Unauthorized\r\nWWW-Authenticate: Basic realm="'..auth.challenge()..'"\r\nContent-Type: text/html\r\n\r\nAccess denied')
        return false
    end
    
    
    function send_buffered(...)
        webctx:send(...)
    end
    
    function send_response(response)
        send_buffered(webctx.http_preamble,response)
    end
    
    local function receiver(ctx, sck, data)
        ctx.payload=ctx.payload..data
        if (ctx.headers == nil) then
            local pos=ctx.payload:find('\r\n\r\n')
            -- print('looking for headers')
            if (not pos) then
                return
            end
            -- print('header found',pos)
            local header=ctx.payload:sub(1,pos)
            for str in string.gmatch(header, "([^\r\n]+)") do
                if (ctx.headers) then
                    local k,v=str:match("([^: ]*)%s*:%s*(.*)")
                    ctx.headers[k:lower()]=v
                else
                    local m,pa,pr=str:match("([^ ]*)%s+([^ ]*)%s+([^ ]*)")
                    ctx.headers={method=m,path=pa,protocol=pr}
                end
            end
            ctx.content=ctx.payload:sub(pos+4)
            -- print("len",payload:len())
        end
        local cl=ctx.headers['content-length']
        if (cl and ctx.content:len() < tonumber(cl)) then
            -- print('not enough data',cl,payload:len())
           return
        end
        if (ctx.headers.method == 'POST') then
            ctx.postdata={}
            for str in string.gmatch(ctx.content, "([^&]+)") do
                local k,v=str:match("([^=]*)=(.*)")
                ctx.postdata[urldecode(k)]=urldecode(v)
            end
        end
        local p=ctx.headers['path']
        printv(2,"PATH",p)
        local f='WEB_'..p:gsub('^/([^/]*).*$','%1'):gsub('%.','_')
        if (not file.exists(f..'.lua')) then
            f='WEB_index_html'
        end
        webctx=ctx
        require(f)(ctx)
        package.loaded[f]=nil
	webctx=nil
    end
    local ctx={
        conn=conn,
	payload='',
	response={},
	txbytes=0,
    	http_preamble = 'HTTP/1.0 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\n\r\n',
	sync_limit=0,
	send=send,
	send_next=send_next,
	authenticated=authenticated
    }
    conn:on('sent',function(sck) send_next(ctx) end) 
    conn:on("receive", function(sock,data) receiver(ctx,sock,data) end)
end
