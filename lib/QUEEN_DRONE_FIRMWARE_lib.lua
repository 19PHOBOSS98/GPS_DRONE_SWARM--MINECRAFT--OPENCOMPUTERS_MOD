local component = require 'component'
local modem = component.modem

local QUEEN = {}


local FIRMWARE = {
[[
r= component.proxy(component.list('radar')())
n= component.proxy(component.list('navigation')())
d= component.proxy(component.list('drone')())
m= component.proxy(component.list('modem')())
Channel = 2412
ResponseChannel = 2402
m.open(Channel)
drone_inv = "inv_q"
isDroneQueen = true
isFree = true
broadcastGPS = false
gpsChannel = 2
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
function sub_vec(A,B) return {A[1]-B[1],A[2]-B[2],A[3]-B[3]} end
function math.trunc(v)
    local t = math.modf(v)
	return t
end
function vec_trunc(A)
	if A then
		return {math.trunc(A[1]),math.trunc(A[2]),math.trunc(A[3])}
	end
	return nil
end
]]
,
[[
function getPlayerCoord(e_name) 
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(r.getPlayers()) do 
		if v.name == e_name then
			return {v.x,v.y,v.z},v.distance
		end 
	end
	return nil
end
]]
,
[[
function move(x,y,z) 
	checkArg(1,x,'number','nil')
	checkArg(1,y,'number','nil')
	checkArg(1,z,'number','nil')
	if x and y and z then
			d.setLightColor(0x00FFAF)
			d.move(x,y,z)
	end
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

function QgpsBroadcast(c)
	if broadcastGPS and c[1] then
		--m.broadcast(gpsChannel,"gps",-c[1],-(c[2]+1),-c[3])
		m.broadcast(gpsChannel,"gps",c[1],c[2],c[3])
		d.setLightColor(0x00FFCC)
	end
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
	["formup"] = function(_,tag,x,y,z) d.setStatusText(navMoveToPlayerWOffset(tag,x,y,z)) end,
	["startgps"] = function() broadcastGPS = true end,
	["stopgps"] = function() broadcastGPS = false end,
	["HUSH"] = function() computer.shutdown() end
}
]]
,
[[
actsWhileMoving = {
	[drone_inv] = function(r_add) replyInv(r_add) end,
	["commit"] = function() d.setLightColor(0x0077FF) isFree = false end,
	["uncommit"] = function() isFree = true end,
	["startgps"] = function() broadcastGPS = true end,
	["stopgps"] = function() broadcastGPS = false end,
	["HUSH"] = function() d.setLightColor(0xFF0000) sleep(1) computer.shutdown() end
}
]]
,
[[
function navMoveToPlayer(e_name)
	checkArg(1,e_name,"string","nil")
	local trgPos = {n.getPosition()},msg,r_add
 
	if not trgPos[1] then d.setLightColor(0xFF0000) return "Out Of\nRange" end
 
	trgPos = vec_trunc(trgPos)
	local mv = {0,0,0}
	local mapRange = n.getRange()
 
	repeat
		local v = getPlayerCoord(e_name)
		if not v then 
			d.setLightColor(0xFF0000)
			d.setStatusText("Out Of\nRange")
		else
			v = vec_trunc(v)
			local npos = {n.getPosition()}
			if npos[1] then
				npos = vec_trunc(npos)
				local Qpn = {npos[1] + v[1], npos[2] + v[2] + 2, npos[3] + v[3]}
				mv = sub_vec(Qpn,trgPos)
				if math.abs(Qpn[1]) < mapRange-5 and math.abs(Qpn[3]) < mapRange-5 then
					d.move(mv[1],mv[2],mv[3])
					trgPos = Qpn
				end
			else
				d.setLightColor(0xFF0000)
				d.setStatusText("Out Of\nRange")
				d.move(-mv[1],-mv[2],-mv[3])
			end
		end
		_,_,r_add,_,_,msg = computer.pullSignal(0.5)
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add)
		end
	until msg == "stop"
	return d.name()
end
]]
,
[[
function navSwarmPlayer(e_name)
	checkArg(1,e_name,"string","nil")
	local trgPos = {n.getPosition()},msg,r_add
 
	if not trgPos[1] then d.setLightColor(0xFF0000) return "Out Of\nRange" end
 
	trgPos = vec_trunc(trgPos)
	local mv = {0,0,0}
	local mapRange = n.getRange()
 
	repeat
		local v = getPlayerCoord(e_name)
		if not v then 
			d.setLightColor(0xFF0000)
			d.setStatusText("Out Of\nRange")
		else
			v = vec_trunc(v)
			local npos = {n.getPosition()}
			if npos[1] then
				npos = vec_trunc(npos)
				local Qpn = {npos[1] + v[1] +math.random(-3,3), npos[2] + v[2] +math.random(-3,3), npos[3] + v[3]+math.random(-3,3)}
				mv = sub_vec(Qpn,trgPos)
				if math.abs(Qpn[1]) < mapRange-5 and math.abs(Qpn[3]) < mapRange-5 then
					d.move(mv[1],mv[2],mv[3])
					trgPos = Qpn
				end
			else
				d.setLightColor(0xFF0000)
				d.setStatusText("Out Of\nRange")
				d.move(-mv[1],-mv[2],-mv[3])
			end
		end
		_,_,r_add,_,_,msg = computer.pullSignal(0.5)
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add)
		end
	until msg == "stop"
	return d.name()
end
]]
,
[[
gpsSatPos={}
function navMoveToPlayerWOffset(e_name,xo,yo,zo)
	checkArg(1,e_name,"string","nil")
	local trgPos = {n.getPosition()}
	if not trgPos[1] then d.setLightColor(0xFF0000) return "Out Of\nRange" end
	trgPos = vec_trunc(trgPos)
	local mv = {0,0,0},msg,r_add
	local mapRange = n.getRange()
	repeat
		local v = getPlayerCoord(e_name)
		if not v then 
			d.setLightColor(0xFF0000)
			d.setStatusText("Out Of\nRange")
		else
			v = vec_trunc(v)
			--QgpsBroadcast(v)

			--gpsSatPos = {-v[1],-(v[2]+1),-v[3]} --offset origin to tablet position (above player's head)
			gpsSatPos = {-v[1],-v[2],-v[3]}

			local npos = {n.getPosition()}
			if npos[1] then
				npos = vec_trunc(npos)
				local Qpn = {npos[1] + v[1] + xo, npos[2] + v[2] + yo, npos[3] + v[3] + zo}
				mv = sub_vec(Qpn,trgPos)
				if math.abs(Qpn[1]) < mapRange-5 and math.abs(Qpn[3]) < mapRange-5 then
					d.move(mv[1],mv[2],mv[3])
					trgPos = Qpn
				end
			else
				d.setLightColor(0xFF0000)
				d.setStatusText("Out Of\nRange")
				d.move(-mv[1],-mv[2],-mv[3])
			end
		end
		_,_,r_add,_,_,msg = computer.pullSignal(0.5)
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add)
		end
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
	_,_,r_add,_,_,cmd,tag,x,y,z = computer.pullSignal(0.5)
	if d.name():match("^Q%d+$") then
		if acts[cmd] then
			acts[cmd](r_add,tag,x,y,z)
		end
		QgpsBroadcast(gpsSatPos)
	end
	--d.setLightColor(0xFFAF00)
	--d.setLightColor(0x77FF77)
end
]]
}

function QUEEN.broadcastFirmWare(port)
	for _,part in ipairs(FIRMWARE) do
		modem.broadcast(port,part)
	end
end

return QUEEN
