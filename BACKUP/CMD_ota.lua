local cmds_ota={}
local subcmds_ota={}

function cmds_ota.ota(ctx,subcmd,...)
  return shell.cmd2(ctx,{subcmds_ota},subcmd,...)
end

function subcmds_ota.info(ctx)
  boot_part, next_part, info = otaupgrade.info()
  ctx.stdout:write("Booted: "..boot_part.."\n")
  if (next_part) then
    ctx.stdout:write("  Next: "..next_part.."\n")
  end
  for p,t in pairs(info) do
    ctx.stdout:write("@ "..p..":".."\n")
    for k,v in pairs(t) do
      ctx.stdout:write("    "..k..": "..v.."\n")
    end
  end
  if (info[boot_part]) then
    ctx.stdout:write("Running version: "..info[boot_part].version.."\n")
  end
  return 0
end

function subcmds_ota.accept(ctx)
  otaupgrade.accept()
end

function subcmds_ota.rollback(ctx)
  otaupgrade.rollback()
end

function subcmds_ota.update(ctx,url,md5)
  cmds_wget.wget(ctx,url,'ota:',md5,tmr.wdclr == nil)
end

return cmds_ota
