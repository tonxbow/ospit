local cmds_config={}
local subcmds_config={}

function cmds_config.config(ctx,subcmd,...)
  return shell.cmd2(ctx,{subcmds_config},subcmd,...)
end

function subcmds_config.list(ctx)
  config.parse('config.lua',function(data)
    if (data.key) then
       local key=data.key
       if (tostring(data.value) == tostring(_G[key])) then
         ctx.stdout:print(key,data.value)
       else
         ctx.stdout:print('***',key,data.value,_G[key])
       end
    end
  end,nil)
end

function subcmds_config.save(ctx)
  if (config.save()) then
     return 0
  end
  ctx.stderr:print('failed')
end

return cmds_config
