local function gen_page(data)
	local s=data.param
	if (data.key) then
		local c=data.type
		if (c == 'boolean') then c='option true;false' end
		if (c:sub(1,7) == 'option ') then
			send_buffered("<select name='"..k.."'>")
			for str in string.gmatch(c:sub(8), "([^;]+)") do
				send_buffered("<option value='"..str.."'"..(v == str and " selected='selected'" or "")..">"..str..'</option>')
			end
			send_buffered("</select></br>")
		else
			send_buffered("<input type='"..(c == 'password' and c or 'text').."' name='"..k.."' value='"..v.."' /><br/>")
		end
		s.sep='<hr/>'
	else
		if (s.output) then
			if (s.sep ~= '') then
				send_buffered(s.sep)
				s.sep=''
			end
			local text
			local prefix=''
			local postfix='<br/>'
			if (data.line:sub(1,6) == '------') then
				prefix='<h1>'
				text=data.line:sub(7)
				postfix='</h1>'
			elseif (data.line:sub(1,4) == '----') then
				prefix='<h2>'
				text=data.line:sub(5)
				postfix='</h2>'
			else
				text=data.line:sub(4)
			end
			send_buffered(prefix..text..postfix)
		end
		if (data.line == '-- BEGIN') then
			s.output=true
		end
	end
	return true
end

return function (info)
	if (not authenticated()) then
		return
	end
	send_buffered(info.http_preamble)
	if (info.headers.method == 'POST') then
		if (config.update(info.postdata)) then
			send_buffered("Your new configuration has been stored in flash. <br>You have to reboot the system in order to run with the new settings.<br><a href='/reboot'>Reboot now!</a><br><a href='/'>Back to main page</a>",nil)
			return
		else
			send_buffered('An error occured</br>')
		end
	end
	send_buffered("<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><title>FF-ESP32 irrigation configuration</title></head><body><form method='post' accept-charset=utf-8 >")
	state={output=false,sep=''}
	config.parse('iconfig.lua',gen_page,state)
	send_buffered("</hr><input type='submit' value='Submit'/>")
	send_buffered("</form></body></html>")
end
