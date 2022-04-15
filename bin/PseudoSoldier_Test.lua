local component = require("component")
local term = require("term")
local computer = require("computer")
local modem = component.modem
gpsChannel = 2
gpsRequestChannel = 20
--trgChannel = 1
SoldierChannel = 2413

modem.open(gpsChannel)
--modem.open(trgChannel)
modem.open(SoldierChannel)
modem.setStrength(math.huge)
gpsSats={}
cmdTRGPos={}

drone_inv = "inv_s"
ResponseChannel = 2403
isFree = true
function replyInv(add)
	print("replying to add: ",add)
	modem.send(add,ResponseChannel,"stats",isFree,false)--Queens send "true"
end

function length(a)
  local c = 0
  for k,_ in pairs(a) do c=c+1 end
  return c
end

function add2GPSTable(r_addr,x,y,z,dist)
  if length(gpsSats) < 7 then gpsSats[r_addr] = {x=x,y=y,z=z,d=dist} end 
end

acts = {
	[drone_inv] = function(r_add) replyInv(r_add) end,
	["commit"] = function() isFree = false end,
	["uncommit"] = function() isFree = true end,
	["gps"] = function(r_addr,x,y,z,dist,_) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z) cmdTRGPos={c={x,y,z},d=dist} end,
	
	["formup"] = function(_,x,y,z,_,trgC) print(gpsMoveToTarget({x=x,y=y,z=z},trgC)) end,
	
	["HUSH"] = function()  sleep(1) computer.shutdown() end
}


local floor, sqrt, abs = math.floor, math.sqrt, math.abs

local function round(v, m) return {x = floor((v.x+(m*0.5))/m)*m, y = floor((v.y+(m*0.5))/m)*m, z = floor((v.z+(m*0.5))/m)*m} end
local function cross(v, b) return {x = v.y*b.z-v.z*b.y, y = v.z*b.x-v.x*b.z, z = v.x*b.y-v.y*b.x} end
local function len(v) return sqrt(v.x^2+v.y^2+v.z^2) end
local function dot(v, b) return v.x*b.x+v.y*b.y+v.z*b.z end
local function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
local function sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
local function mul(v, m) return {x=v.x*m, y=v.y*m, z=v.z*m} end
local function norm(v) return mul(v, 1/len(v)) end
local function trunc(v) local t = math.modf(v) return t end
local function vec_trunc(A)
	if A then
		return {x=trunc(A.x),y=trunc(A.y),z=trunc(A.z)}
	end
	return nil
end

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
			--print("rnd1: ",rnd1.x,rnd1.y,rnd1.z)
			--print("rnd2: ",rnd2.x,rnd2.y,rnd2.z)
			return rnd1, rnd2
		else
			--print("rnd1: ",rnd1.x,rnd1.y,rnd1.z)
			return rnd1
		end
	end
	--print("result: ",result.x,result.y,result.z)
	return result
end

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

local function getGPSlocation()
	modem.open(gpsChannel)
	local fixes = {}
	local pos1, pos2 = nil, nil
	local deadline = computer.uptime()+2
	for addr,fix in pairs(gpsSats) do
		if fix.d == 0 then 
			pos1, pos2 = {x=fix.x, y=fix.y, z=fix.z}, nil
		else 
			table.insert(fixes, fix)
		end
	end
	if #fixes >= 3 then
		if fixes[1].z then
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


local refreshGPSInterval = 0
function refreshGPSTable()
	if refreshGPSInterval >= 60 then gpsSats={} refreshGPSInterval = 0 end
	refreshGPSInterval = refreshGPSInterval + 1
end
 
function getTRGPos()
	return cmdTRGPos
end

function printGPSSats() -- temp
	print("gpsSats:")
	for addr,c in pairs(gpsSats) do
		print(addr,":: {",c.x,c.y,c.z,c.d,"}")
	end
end
function printTRGPos() -- temp
	if trgPos then
		print("trgPos: {",trgPos[1],trgPos[2],trgPos[3],"}")
	else
		print("trgPos:")
	end
end

function printGPSTRG() -- temp
	term.clear()
	printGPSSats()
	printTRGPos()
end

actsWhileMoving = {
	[drone_inv] = function(r_add) replyInv(r_add) end,
	["commit"] = function() d.setLightColor(0x0077FF) isFree = false end,
	["uncommit"] = function() isFree = true end,
	["gps"] = function(r_addr,x,y,z,dist,_) add2GPSTable(r_addr,x,y,z,dist) end,
	["trg"] = function(_,x,y,z,dist) cmdTRGPos={c={x=x,y=y,z=z},d=dist} end,
	["HUSH"] = function() d.setLightColor(0xFF0000) sleep(1) computer.shutdown() end
}

function gpsMoveToTarget(offset,trgChannel)
	checkArg(1,e_name,"string","nil")
	local ctrlTRGPos = nil
	modem.open(trgChannel)
	repeat
		term.clear()
		print("phase1")
		printGPSTRG()
		if length(gpsSats)>=3 then
			ctrlTRGPos = getGPSlocation()
		end
	
		if ctrlTRGPos then ctrlTRGPos = vec_trunc(ctrlTRGPos) 
		--[[else d.setLightColor(0xFF0000) d.setStatusText("No GPS") end]]
		else print("No GPS") end
	
		_,_,r_add,_,dist,msg,x,y,z,_ = computer.pullSignal(0.5)
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add,x,y,z,dist)
		end
	until msg == "stop" or ctrlTRGPos
	
	local mv = {0,0,0},msg,r_add,dist,x,y,z
	
	repeat
		_,_,r_add,_,dist,msg,x,y,z,_ = computer.pullSignal(0.5)
		if actsWhileMoving[msg] then
			actsWhileMoving[msg](r_add,x,y,z,dist)
		end
		
		term.clear()
		print("phase2")
		printGPSTRG()
		local trgPos = getTRGPos()
		if trgPos.d and trgPos.d < 50 then
			trgPos.c = vec_trunc(trgPos.c)
			print("trgPos: ",trgPos.c.x,trgPos.c.y,trgPos.c.z)
			--trgPos.c = add(trgPos.c, offset)
			--print("trgPosWOffset: ",trgPos.c.x,trgPos.c.y,trgPos.c.z)
			print("Offset: ",offset.x,offset.y,offset.z)
			mv = sub(trgPos.c,ctrlTRGPos)
			--d.move(mv.x,mv.y,mv.z)
			print("mv: ",mv.x,mv.y,mv.z)
			
			ctrlTRGPos = trgPos.c
		else
			--[[d.setLightColor(0xFF0000)
			d.setStatusText("Out Of\nRange")
			d.move(-mv.x,-mv.y,-mv.z)]]
			print("Out Of Range")
		end
		refreshGPSTable()
	until msg == "stop"
	modem.close(trgChannel)
	return "S1"
end


--gpsMoveToTarget({x=10,y=23,z=35})
while true do
	_,_,r_addr,_,dist,msg,x,y,z,trgCh = computer.pullSignal(0.5)
	--_,_,r_addr,_,dist,msg,trgCh,x,y,z = computer.pullSignal()
	if acts[msg] then
		acts[msg](r_addr,x,y,z,dist,trgCh)
	end
end

--[[
while true do
	_,_,r_addr,_,dist,msg,trgCh,x,y,z = computer.pullSignal(0.5)

	if acts[msg] then
		acts[msg](r_addr,x,y,z,dist,trgCh)
	end
	
	--printGPSTRG()
	local current_pos
	if length(gpsSats)>=3 then
		current_pos = getGPSlocation()
	end
	
	term.clear()
	if current_pos then 
		print("current_pos: ",current_pos.x,current_pos.y,current_pos.z)
	else 
		print("current_pos:") 
	end
	
	refreshGPSTable()
end
]]
