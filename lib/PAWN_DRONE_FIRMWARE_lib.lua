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
m.open(gpsChannel)

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
local floor, sqrt, abs = math.floor, math.sqrt, math.abs

local function round(v, m) return {x = floor((v.x+(m*0.5))/m)*m, y = floor((v.y+(m*0.5))/m)*m, z = floor((v.z+(m*0.5))/m)*m} end
local function cross(v, b) return {x = v.y*b.z-v.z*b.y, y = v.z*b.x-v.x*b.z, z = v.x*b.y-v.y*b.x} end
local function len(v) return sqrt(v.x^2+v.y^2+v.z^2) end
local function dot(v, b) return v.x*b.x+v.y*b.y+v.z*b.z end
local function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
local function sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
local function mul(v, m) return {x=v.x*m, y=v.y*m, z=v.z*m} end
local function norm(v) return mul(v, 1/len(v)) end
	
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

	["gps"] = function(r_addr,x,y,z,dist,_) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z) cmdTRGPos={c={x,y,z},d=dist} end,
	["formup"] = function(_,x,y,z,_,trgC) d.setStatusText(gpsMoveToTarget({x=x,y=y,z=z},trgC)) end,	
	
	["HUSH"] = function() computer.shutdown() end
}
]]
,
[[
actsWhileMoving = {
	[drone_inv] = function(r_add) replyInv(r_add) end,
	["commit"] = function() d.setLightColor(0x0077FF) isFree = false end,
	["uncommit"] = function() isFree = true end,
	["gps"] = function(r_addr,x,y,z,dist,_) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z,dist) cmdTRGPos={c={x=x,y=y,z=z},d=dist} end,
	["HUSH"] = function() d.setLightColor(0xFF0000) sleep(1) computer.shutdown() end
}
]]
,
[[
local function trilaterate(A, B, C)
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
local function narrow(p1, p2, fix)
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
local function getGPSlocation()
	modem.open(gpsChannel)
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
		return nil
	elseif pos1 then
		local c = round(pos1,1)
		return {x=c.x,y=c.y,z=c.z}
	else 
		return nil
	end
end
]]
,
[[
local refreshGPSInterval = 0
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
	checkArg(1,e_name,"string","nil")
	d.setLightColor(0xFFFFFF)
	local ctrlTRGPos = nil
	modem.open(trgChannel)
	repeat
		if arr_length(gpsSats)>=3 then
			ctrlTRGPos = getGPSlocation()
		end
	
		if ctrlTRGPos then ctrlTRGPos = vec_trunc(ctrlTRGPos) 
		else d.setLightColor(0xFF0000) d.setStatusText("No GPS") end
	
		_,_,r_add,_,dist,msg,x,y,z,_ = computer.pullSignal(0.5)
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add,x,y,z,dist)
		end
	until msg == "stop" or ctrlTRGPos
	
	local mv = {0,0,0},msg,r_add,dist,x,y,z
	if ctrlTRGPos then
		repeat
			_,_,r_add,_,dist,msg,x,y,z,_ = computer.pullSignal(0.5)
			if actsWhileMoving[msg] then
				actsWhileMoving[msg](r_add,x,y,z,dist)
			end

			local trgPos = getTRGPos()
			if trgPos.d and trgPos.d < 50 then
				trgPos.c = vec_trunc(trgPos.c)
				local trgPosOffset = add(trgPos.c, offset)
				mv = sub(trgPosOffset,ctrlTRGPos)
				d.move(mv.x,mv.y,mv.z)
				ctrlTRGPos = trgPosOffset
			else
				d.setLightColor(0xFF0000)
				d.setStatusText("Out Of\nRange")
				d.move(-mv.x,-mv.y,-mv.z)
			end
			refreshGPSTable()
		until msg == "stop"
	end
	modem.close(trgChannel)
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
