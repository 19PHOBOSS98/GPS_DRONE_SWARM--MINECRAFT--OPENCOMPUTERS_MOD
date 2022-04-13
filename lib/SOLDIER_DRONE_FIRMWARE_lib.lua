local component = require 'component'
local modem = component.modem

local SOLDIER = {}


local FIRMWARE = {
[[
r= component.proxy(component.list('radar')())
n= component.proxy(component.list('navigation')())
d= component.proxy(component.list('drone')())
m= component.proxy(component.list('modem')())
Channel = 2413
ResponseChannel = 2403
gpsChannel = 2
trgChannel = 3
m.open(Channel)
m.open(gpsChannel)
m.open(trgChannel)
drone_inv = "inv_s"
isDroneQueen = true
isFree = true
gpsChannel = 2

gpsSats={}
cmdTRGPos={}
]]
,
[[
function sleep(timeout) 
	checkArg(1, timeout, 'number', 'nil')
	local deadline = computer.uptime() + (timeout or 0)
	repeat
		computer.pullSignal(deadline - computer.uptime())
	until computer.uptime() >= deadline
end
]]
,
[[
function trunc(v) local t = math.modf(v) return t end
function vec_trunc(A)
	if A then
		return {x=trunc(A.x),y=trunc(A.y),z=trunc(A.z)}
	end
	return nil
end
local function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
local function sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
]]
,

[[
function getPlayerCoord(e_name) 
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(r.getPlayers()) do 
		if v.name == e_name then
			return {c={v.x,v.y,v.z},d=v.distance}
		end 
	end
	return nil
end
]]
,
[[
function replyInv(add)
	m.send(add,ResponseChannel,"stats",isFree,isDroneQueen)--Queens send "true"
end
]]
,
[[
function length(a)
	local c = 0
	for k,_ in pairs(a) do c=c+1 end
	return c
end
 
function add2GPSTable(r_addr,x,y,z,dist)
	if r_addr == master then gpsSats[r_addr] = {c={x=x,y=y,z=z},d=dist} end 
	if length(gpsSats) < 7 then gpsSats[r_addr]= {c={x=x,y=y,z=z},d=dist} end 
end
]]
,
[[
acts = {
	["go"] = function(_,tag) d.setLightColor(0x00FF00) d.setStatusText(navMoveToPlayer(tag)) end,
    ["bzz"] = function(_,tag) d.setLightColor(0x0000FF) d.setStatusText(navSwarmPlayer(tag)) end,
	["move"] = function(_,_,x,y,z) move(x,y,z) end,
	[drone_inv] = function(r_add) d.setLightColor(0xFF00BB) replyInv(r_add) end,
	["commit"] = function() d.setLightColor(0x0077FF) isFree = false end,
	["uncommit"] = function() isFree = true end,

	["formup"] = function() d.setStatusText(gpsMoveToTarget()) end,
	["gps"] = function(r_addr,x,y,z,dist) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z,dist) cmdTRGPos={c={x=x,y=y,z=z},d=dist} end,

	["HUSH"] = function() computer.shutdown() end
}
]]
,
[[
actsWhileMoving = {
	[drone_inv] = function(r_add) replyInv(r_add) end,
	["commit"] = function() d.setLightColor(0x0077FF) isFree = false end,
	["uncommit"] = function() isFree = true end,

	["gps"] = function(r_addr,x,y,z,dist) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z,dist) cmdTRGPos={c={x=x,y=y,z=z},d=dist} end,

	["HUSH"] = function() d.setLightColor(0xFF0000) sleep(1) computer.shutdown() end
}
]]
,
[[
local refreshGPSInterval = 0
function refreshGPSTable()
	if refreshGPSInterval >= 17 then gpsSats={} refreshGPSInterval = 0 end
	refreshGPSInterval = refreshGPSInterval + 1
end

function getGPSlocation()
	local gpsPos = locate()
	if gpsPos then return gpsPos end
	return nil
end

function getTRGPos()
	return cmdTRGPos
end
]]
,
[[
function gpsMoveToTarget(offset)
	checkArg(1,e_name,"string","nil")
	local ctrlTRGPos = getGPSlocation()
	if not ctrlTRGPos.d then d.setLightColor(0xFF0000) return "Out Of\nRange" end
	ctrlTRGPos = vec_trunc(ctrlTRGPos.c)
	local mv = {0,0,0},msg,r_add,dist,x,y,z
	repeat
		local trgPos = getTRGPos()
		if trgPos.d and trgPos.d < 50 then
			trgPos.c = vec_trunc(trgPos.c)
			mv = sub_vec(trgPos.c,ctrlTRGPos.c)

			d.move(mv.x,mv.y,mv.z)
			ctrlTRGPos = trgPos.c

		else
			d.setLightColor(0xFF0000)
			d.setStatusText("Out Of\nRange")
			d.move(-mv.x,-mv.y,-mv.z)
		end
		_,_,r_add,_,dist,msg,x,y,z = select(6,computer.pullSignal(0.5))
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add,x,y,z,dist)
		end
		refreshGPSTable()
	until msg == "stop"
	return d.name()
end
]]
,
[[
d.setAcceleration(100)
local cmd,tag,x,y,z
d.setLightColor(0xFFAF00)
while true do
	_,_,r_add,_,dist,cmd,tag,x,y,z = computer.pullSignal(0.5)
	if d.name():match("^Q%d+$") then
		if acts[cmd] then
			acts[cmd](r_add,tag,x,y,z,dist)
		end
	end
	--d.setLightColor(0xFFAF00)
	--d.setLightColor(0x77FF77)
end
]]
}

SOLDIER.master = "" --control tablet modem address, set before broadcasting firmware

function SOLDIER.broadcastFirmWare(port)
	modem.broadcast(port,
	[[
		master = ]]..SOLDIER.master..[[
	]]
	)
	for _,part in ipairs(FIRMWARE) do
		modem.broadcast(port,part)
	end
end

return SOLDIER
