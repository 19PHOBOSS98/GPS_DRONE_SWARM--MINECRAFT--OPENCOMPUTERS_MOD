local m=component.proxy(component.list("modem")())
local d=component.proxy(component.list("drone")())
d.setLightColor(0x4287F5)               -- the first character 's' of the method should have been in lower case
d.setStatusText(d.name())                -- same here... my bad
m.open(2413)
m.setWakeMessage("RISE")
local function respond(...)
  local args=table.pack(...)
  pcall(function() m.broadcast(3000, table.unpack(args)) end)--needed to broadcast to a different channel to avoid drones yelling at each other about recursive error messages
end
local function receive()
  while true do
    local evt,_,_,_,_,cmd=computer.pullSignal()
    if evt=="modem_message" then return load(cmd) end
  end
end
while true do
  local result,reason=pcall(function()
    local result,reason=receive()
    if not result then return respond(reason) end
    respond(result())
  end)
  if not result then respond(reason) end
end
