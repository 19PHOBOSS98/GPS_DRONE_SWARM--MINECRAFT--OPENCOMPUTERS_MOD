local component = require 'component'
local modem = component.modem

local PAWN = {}


local FIRMWARE = {
[[
d= component.proxy(component.list('drone')())
m= component.proxy(component.list('modem')())
Channel = 2413
ResponseChannel = 2403
gpsChannel = 2

m.open(Channel)


drone_inv = "inv_s"
isDroneQueen = false
isFree = true

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
floor, sqrt, abs = math.floor, math.sqrt, math.abs

function round(v, m) return {x = floor((v.x+(m*0.5))/m)*m, y = floor((v.y+(m*0.5))/m)*m, z = floor((v.z+(m*0.5))/m)*m} end
function cross(v, b) return {x = v.y*b.z-v.z*b.y, y = v.z*b.x-v.x*b.z, z = v.x*b.y-v.y*b.x} end
function len(v) return sqrt(v.x^2+v.y^2+v.z^2) end
function dot(v, b) return v.x*b.x+v.y*b.y+v.z*b.z end
function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
function sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
function mul(v, m) return {x=v.x*m, y=v.y*m, z=v.z*m} end
function norm(v) return mul(v, 1/len(v)) end
	
function arr_length(a)
  local c = 0
  for k,_ in pairs(a) do c=c+1 end
  return c
end
function trunc(v) local t = math.modf(v) return t end
function vec_trunc(A)
	if A then
		return {x=trunc(A.x),y=trunc(A.y),z=trunc(A.z)}
	end
	return nil
end
]]
,

[[
function add2GPSTable(r_addr,x,y,z,dist)
  if arr_length(gpsSats) < 7 then gpsSats[r_addr] = {x=x,y=y,z=z,d=dist} end 
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
acts = {
	[drone_inv] = function(r_add) d.setLightColor(0x00FFBB) replyInv(r_add) end,
	["commit"] = function() d.setLightColor(0x5E00FF) isFree = false end,
	["uncommit"] = function() isFree = true end,

	["gps"] = function(r_addr,x,y,z,dist) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z,dist) cmdTRGPos={c={x,y,z},d=dist} end,
	["formup"] = function(_,x,y,z,_,trgC) d.setStatusText(gpsMoveToTarget({x=x,y=y,z=z},trgC)) end,	
	["orbit"] = function(_,x,y,z,_,trgC) d.setStatusText(gpsOrbitTRG({x=x,y=y,z=z},trgC)) end,
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
	--["trg"] = function(_,x,y,z,dist) cmdTRGPos={c={x=x,y=y,z=z},d=dist} d.setStatusText("trg2:"..tostring(cmdTRGPos.c.x))  end,
	["HUSH"] = function() d.setLightColor(0xFF0000) sleep(1) computer.shutdown() end
}
]]
,
[[
function trilaterate(A, B, C)
	local a2b = {x=B.x-A.x, y=B.y-A.y, z=B.z-A.z}
	local a2c = {x=C.x-A.x, y=C.y-A.y, z=C.z-A.z}
	if abs(dot(norm(a2b), norm(a2c))) > 0.999 then return nil end
	local d, ex = len(a2b), norm(a2b)
	local i = dot(ex, a2c)
	local exMi = mul(ex, i)
	local ey = norm(sub(a2c, mul(ex, i)))
	local j, ez = dot(ey, a2c), cross(ex, ey)
	local r1, r2, r3 = A.d, B.d, C.d
	local x = (r1^2 - r2^2 + d^2) / (2*d)
	local y = (r1^2 - r3^2 - x^2 + (x-i)^2 + j^2) / (2*j)
	local result = add(A, add(mul(ex, x), mul(ey, y)))
	local zSquared = r1^2 - x^2 - y^2
	if zSquared > 0 then
		local z = sqrt( zSquared )
		local result1 = add(result, mul(ez, z))
		local result2 = sub(result, mul(ez, z))
		local rnd1, rnd2 = result1,result2
		if rnd1.x ~= rnd2.x or rnd1.y ~= rnd2.y or rnd1.z ~= rnd2.z then
			return rnd1, rnd2
		else
			return rnd1
		end
	end
	return result
end
]]
,
[[
function narrow(p1, p2, fix)
	local d1 = abs(len(sub(p1, fix))-fix.d)
	local d2 = abs(len(sub(p2, fix))-fix.d)
	if abs(d1-d2) < 0.01 then 
		return p1, p2
	elseif d1 < d2 then 
		return p1,nil
	else 
		return p2,nil
	end
end
]]
,
[[
function getGPSlocation()
	local fixes = {}
	local pos1, pos2 = nil, nil
	for addr,fix in pairs(gpsSats) do
		if fix.d == 0 then 
			pos1, pos2 = {x=fix.x, y=fix.y, z=fix.z}, nil
		else 
			table.insert(fixes, fix)
		end
	end
	if #fixes >= 3 then
		if not pos1 then
			pos1, pos2 = trilaterate(fixes[1], fixes[2], fixes[3])
		end
		if pos1 and pos2 then
			for f=4,#fixes do
				pos1, pos2 = narrow(pos1, pos2, fixes[f])
				if pos1 and not pos2 then break end
			end
		end
	end        

	if pos1 and pos2 then
		d.setStatusText("ps12")
		return nil
	elseif pos1 then
		local c = round(pos1,1)
		return {x=c.x,y=c.y,z=c.z}
	else 
		d.setStatusText("else")
		return nil
	end
end
]]
,
[[
refreshGPSInterval = 0
function refreshGPSTable()
	if refreshGPSInterval >= 17 then gpsSats={} refreshGPSInterval = 0 end
	refreshGPSInterval = refreshGPSInterval + 1
end

function getTRGPos()
	return cmdTRGPos
end
]]
,
[[
function gpsMoveToTarget(offset,trgChannel)
	d.setLightColor(0xFFFFFF)
	gpsSats={}
	m.open(gpsChannel)
	local ctrlTRGPos = nil
	repeat
		if arr_length(gpsSats)>=3 then
			ctrlTRGPos = getGPSlocation()
		end
	
		if ctrlTRGPos then ctrlTRGPos = vec_trunc(ctrlTRGPos) 
		else d.setLightColor(0xFF0000) d.setStatusText("No GPS:") end
	
		_,_,r_addr,_,dist,msg,x,y,z,trgCh = computer.pullSignal(0.5)
		
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_addr,x,y,z,dist)
		end
		refreshGPSTable()
	until msg == "stop" or ctrlTRGPos

	if ctrlTRGPos then
		m.close(gpsChannel)
		d.setLightColor(0xFFFFFF)
		m.open(trgChannel)
		local mv = {x=0,y=0,z=0},msg,r_add,dist,x,y,z
		local trgUpdate = {}
			repeat
				_,_,r_addr,_,dist,msg,x,y,z,trgCh = computer.pullSignal(0.5)
	
				if msg == "trg" then
					trgUpdate = {c={x=x,y=y,z=z},d=dist}
				end
				local trgPos = trgUpdate

				if trgPos.d and trgPos.d < 50 then
					trgPos.c = vec_trunc(trgPos.c)
					local trgPosOffset = add(trgPos.c, offset)
					mv = sub(trgPosOffset,ctrlTRGPos)
					d.move(mv.x,mv.y,mv.z)
					ctrlTRGPos = trgPosOffset
					d.setLightColor(0x00FF00)
					d.setStatusText(d.name())
				else
					d.setLightColor(0xFF0000)
					d.setStatusText("Out Of\nRange")
					d.move(-mv.x,-mv.y,-mv.z)
				end
				if actsWhileMoving[msg] then
					actsWhileMoving[msg](r_addr,x,y,z,dist)
				end
			until msg == "stop"
	end
	m.close(trgChannel)
	return d.name()
end
]]
,
[[
function rotatePoint(rad,point)
	local s = math.sin(rad);
	local c = math.cos(rad);

	// rotate point
	float xnew = point.x * c - point.y * s;
	float ynew = point.x * s + point.y * c;

	return point
end
]]
,
[[
function gpsOrbitTRG(offset,trgChannel)
	d.setLightColor(0xFFFFFF)
	gpsSats={}
	m.open(gpsChannel)
	local ctrlTRGPos = nil
	repeat
		if arr_length(gpsSats)>=3 then
			ctrlTRGPos = getGPSlocation()
		end
	
		if ctrlTRGPos then ctrlTRGPos = vec_trunc(ctrlTRGPos) 
		else d.setLightColor(0xFF0000) d.setStatusText("No GPS:") end
	
		_,_,r_addr,_,dist,msg,x,y,z,trgCh = computer.pullSignal(0.5)
		
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_addr,x,y,z,dist)
		end
		refreshGPSTable()
	until msg == "stop" or ctrlTRGPos

	if ctrlTRGPos then
		m.close(gpsChannel)
		d.setLightColor(0xFFFFFF)
		m.open(trgChannel)
		local mv = {x=0,y=0,z=0},msg,r_add,dist,x,y,z
		local trgUpdate = {}
		local currentAngle = 0 -- in radians
		local rotationInterval = 0.785 -- PI/4
			repeat
				_,_,r_addr,_,dist,msg,x,y,z,trgCh = computer.pullSignal(0.5)
	
				if msg == "trg" then
					trgUpdate = {c={x=x,y=y,z=z},d=dist}
				end
				local trgPos = trgUpdate

				if trgPos.d and trgPos.d < 50 then
					trgPos.c = vec_trunc(trgPos.c)

					if currentAngle >= 6.3832 then currentAngle = 0 end
					local rotatedOffset = rotatePoint(currentAngle,offset)
					currentAngle = currentAngle + rotationInterval
	
					local trgPosOffset = add(trgPos.c, rotatedOffset)
	
					mv = sub(trgPosOffset,ctrlTRGPos)
					d.move(mv.x,mv.y,mv.z)
					ctrlTRGPos = trgPosOffset
					d.setLightColor(0x00FF00)
					d.setStatusText(d.name())
				else
					d.setLightColor(0xFF0000)
					d.setStatusText("Out Of\nRange")
					d.move(-mv.x,-mv.y,-mv.z)
				end
				if actsWhileMoving[msg] then
					actsWhileMoving[msg](r_addr,x,y,z,dist)
				end
			until msg == "stop"
	end
	m.close(trgChannel)
	return d.name()
end
]]
,
[[
d.setAcceleration(100)
d.setLightColor(0x007B62)
while true do
	_,_,r_addr,_,dist,msg,x,y,z,trgCh = computer.pullSignal(0.5)
	if d.name():match("^S%d+$") then
		if acts[msg] then
			acts[msg](r_addr,x,y,z,dist,trgCh)
		end
	end
	--d.setLightColor(0xFFAF00)
	--d.setLightColor(0x77FF77)
end
]]
}

PAWN.master = "" --control tablet modem address, set before broadcasting firmware

function PAWN.broadcastFirmWare(port)
	modem.broadcast(port,
	[[
		master = ]]..PAWN.master..[[
	]]
	)
	for _,part in ipairs(FIRMWARE) do
		modem.broadcast(port,part)
	end
end

return PAWN
