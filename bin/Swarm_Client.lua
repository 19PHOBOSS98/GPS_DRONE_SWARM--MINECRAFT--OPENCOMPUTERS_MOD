local component = require("component")
local event = require("event")
local serialization= require("serialization")
local computer= require("computer")
local thread= require("thread")
local term= require("term")
local modem = component.modem
--local Tn = component.navigation
local Tr = component.radar
local QueensChannel = 2412
local QueensResponseChannel = 2402
local SoldiersChannel = 2413
local SoldiersResponseChannel = 2403

local drone_is_queen = true

--custom libraries
local s_utils = require("swarm_utilities")
local q_firmware = require("queen_firmware")
local flightform = require("flight_formation")

modem.open(QueensResponseChannel)

modem.open(SoldiersResponseChannel)
modem.broadcast(SoldiersChannel,"Sr= component.proxy(component.list('radar')())")
modem.broadcast(SoldiersChannel,"Sn= component.proxy(component.list('navigation')())")
modem.broadcast(SoldiersChannel,"Sd= component.proxy(component.list('drone')())")
modem.broadcast(SoldiersChannel,"function sleep(timeout) checkArg(1, timeout, 'number', 'nil') local deadline = computer.uptime() + (timeout or 0) repeat computer.pullSignal(deadline - computer.uptime()) until computer.uptime() >= deadline end")


flightformation={}
ffbook={flightformation}
ffbook[2]={}
ffbook[3]={}
--form1 = {{13,2,-2},{-13,2,-2},{0,2,13}} --bad y gps value
--form1 = {{3,8,-2},{-3,14,-2},{0,20,3}} -- bad xz gps values
--form1 = {{10,8,-10},{-10,14,0},{5,20,10}}
--form1 = {{0,0,0},{5,5,0},{0,10,10},{-15,15,0},{0,20,-20}}
--form1 = {{0,0,0},{2,2,0},{0,4,4},{-8,8,0},{0,10,-10},{12,12,0},{0,14,14},{-16,16,0}}--golden ratio Spiral
actualSatForm = {{0,25,-3},{0,25,3},{3,22,0},{-3,22,0}}-- ComputerCraft Heresy --(Tetrahedron) -- it's actually good for xz coordinates
satff={}
compensatedSatForm = {{0,25,-2},{0,25,3},{2,22,0},{-3,22,0}}
--form1 = {{0,35,-3},{0,30,3},{3,20,0},{-3,25,0}}
--form1 = {{0,35,-5},{0,30,2},{5,20,0},{-2,25,0}}
--form2 = {{-2,10,2},{2,15,2},{0,2,0}}
--form3 = {{-2,20,-2},{2,25,-2}}
--form2 = {{-10,10,10},{10,12,10},{0,5,0}}
--form3 = {{-10,14,-10},{10,16,-10}}
form2 = {{3,0,0},{0,3,0},{0,0,3},{3,0,3},{-3,0,-3}}
form3 = {{-3,0,0},{0,-3,0},{0,0,-3},{3,3,3},{-3,-3,-3}}
fbook={compensatedSatForm,form2,form3}
dynamic_fbook = fbook


print("Bingus28")
function printSwarmStats()
	term.clear()
	flightform.printDronePool(drone_is_queen)
	flightform.printFFAssignment(ffbook)
end

local gpsChannel = 2
local trgChannel = 3


function getPlayerCoord(e_name) 
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(Tr.getPlayers()) do 
		if v.name == e_name then
			return {c={x=v.x,y=v.y,z=v.z},d=v.distance}
		end 
	end
	return nil
end


function getEntityCoord(e_name) 
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(Tr.getEntities()) do 
		if v.name == e_name then
			return {c={x=v.x,y=v.y,z=v.z},d=v.distance}
		end 
	end
	return nil
end
--**********************--
gpsChannel = 2

function length(a)
  local c = 0
  for k,_ in pairs(a) do c=c+1 end
  return c
end

function add2GPSTable(r_addr,x,y,z,dist)
  if length(gpsSats) < 7 then gpsSats[r_addr] = {x=x,y=y,z=z,d=dist} end 
end

acts = {
["gps"] = function(r_addr,x,y,z,dist) add2GPSTable(r_addr,x,y,z,dist) end,
["trg"] = function(_,x,y,z) cmdTRGPos={c={x,y,z},d=dist} end
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
			print("rnd1: ",rnd1.x,rnd1.y,rnd1.z)
			print("rnd2: ",rnd2.x,rnd2.y,rnd2.z)
			return rnd1, rnd2
		else
			print("rnd1: ",rnd1.x,rnd1.y,rnd1.z)
			return rnd1
		end
	end
	print("result: ",result.x,result.y,result.z)
	return result
end

local function narrow(p1, p2, fix)
	local d1 = abs(len(sub(p1, fix))-fix.d)
	local d2 = abs(len(sub(p2, fix))-fix.d)
	if abs(d1-d2) < 0.01 then 
		return p1, p2
	elseif d1 < d2 then
		print("p1: ",p1.x,p1.y,p1.z)
		return p1,nil
	else 
		print("p2: ",p2.x,p2.y,p2.z)
		return p2,nil
	end
end

local function locate(gpsT)
	local fixes = {}
	local pos1, pos2 = nil, nil
	local deadline = computer.uptime()+2
	for addr,fix in pairs(gpsT) do
		if fix.d == 0 then 
			pos1, pos2 = {x=fix.x, y=fix.y, z=fix.z}, nil
		else 
			table.insert(fixes, fix)
			print(addr,fix.x,fix.y,fix.z)
		end
	end
	if #fixes >= 4 then
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
		--local c = round(pos1,1)
		local c = pos1
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


function getGPSPos(gpsT)
	local gpsPos = locate(gpsT)--{x,y,z}
	--if gpsPos then return vec_trunc(gpsPos) end
	if gpsPos then return gpsPos end
	--if gpsPos then return round(gpsPos,1) end
	return nil
end
--**********************--

--function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end

--trgPortBook = {}--{[trgport]="target"} multiple to fixed single relationship
trgPortBook = {[3]="Bingus",[4]="Floppa",[5]="FloppaMi",[7]="FloppaNi"}


function pawnsFormUP(ff,cmdport,trgPort,trgName)
	for addr,pos in pairs(ff) do
		modem.send(addr,cmdport,"formup")
	end
	trgPortBook[trgPort] = trgName
end

function msgThreadHandler(e)

end

function bcGPSTRGPos(tpBook,gpsC)
	modem.open(gpsC)
	modem.setStrength(math.huge)
	local gpsTable = {}
	event.listen("modem_message",function(_,_,r_addr,_,dist,msg,xg,yg,zg,...)
		if msg == "gps" then gpsTable[r_addr] = {x=xg,y=yg,z=zg,d=dist} end
	end)
	while true do
		term.clear()
		local gpsPos = getGPSPos(gpsTable)
		if gpsPos then
			gpsPos = vec_trunc(gpsPos)
			print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			for tport,tname in pairs(tpBook) do
				--print("tport: ",tport,"tname: ",tname)
				--local radPos = getPlayerCoord(tname)
				local radPos = getEntityCoord(tname)
				print("tport: ",tport,"tname: ",tname,"radPos: ",radPos.c.x,radPos.c.y,radPos.c.z)
				radPos.c = vec_trunc(radPos.c)
				if radPos.d then
					local trgPos = add(radPos.c,gpsPos)
					--print("tport: ",tport,"tname: ",tname,"trgPos: ",trgPos.x,trgPos.y,trgPos.z)
					modem.broadcast(tport,"trg",trgPos.x,trgPos.y,trgPos.z)
				end
			end
		end
		os.sleep(0.5)
	end
	
end

local gpstrgThread = nil
gpsChannel = 2 
function updateGPSTRGs(tpBook)--only call this sparingly, don't want to stall other flight formations
	if gpstrgThread then gpstrgThread:kill() end
	gpstrgThread = thread.create(function(tpb,gpsC) print("threading") bcGPSTRGPos(tpb,gpsC) end,tpBook,gpsChannel)
end
function killGPSTRGThread()
	if gpstrgThread then gpstrgThread:kill() end
end



while true do
	local cmd=io.read()
	if not cmd then return end
	if(cmd == "F") then
		q_firmware.broadcastFirmWare(QueensChannel)
    	os.sleep(0.5)
	elseif(cmd == "G") then
		modem.broadcast(QueensChannel,"stop")
    	modem.broadcast(QueensChannel,"go","ph0")
    	os.sleep(0.5)
	elseif(cmd == "B") then
		modem.broadcast(QueensChannel,"stop")
   		modem.broadcast(QueensChannel,"bzz","ph0")
    	os.sleep(0.5)
	elseif(cmd == "M") then
		modem.broadcast(QueensChannel,"stop")
   		modem.broadcast(QueensChannel,"move","",0,3,0)
    	os.sleep(0.5)


	elseif(cmd == "P") then	--refreshFormation
		flightform.populatePool(QueensChannel,drone_is_queen)
		os.sleep(0.5)
		printSwarmStats()
	    os.sleep(0.5)

	elseif(cmd == "T") then
		flightform.refreshFFT(ffbook,dynamic_fbook,QueensChannel,drone_is_queen)
		flightform.formFF(ffbook[1],dynamic_fbook[1],QueensChannel,drone_is_queen)
		flightform.formUP("ph0",ffbook[1],dynamic_fbook[1],QueensChannel,drone_is_queen)
		printSwarmStats()
	    os.sleep(0.5)
	elseif(cmd == "Q") then
		flightform.refreshFFT(ffbook,dynamic_fbook,QueensChannel,drone_is_queen)
		flightform.formFF(ffbook[2],dynamic_fbook[2],QueensChannel,drone_is_queen)
		flightform.formFF(ffbook[3],dynamic_fbook[3],QueensChannel,drone_is_queen)
		flightform.formUP("ph0",ffbook[2],dynamic_fbook[2],QueensChannel,drone_is_queen)
		flightform.formUP("ph0",ffbook[3],dynamic_fbook[3],QueensChannel,drone_is_queen)
		printSwarmStats()
	    os.sleep(0.5)
	elseif(cmd == "E") then
		for i = 1,#ffbook do
			flightform.breakFormation(ffbook[i],dynamic_fbook[i],QueensChannel,drone_is_queen)
		end
		printSwarmStats()
	    os.sleep(0.5)
	elseif(cmd == "R") then	--refreshFormation
		flightform.refreshFFT(ffbook,dynamic_fbook,QueensChannel,drone_is_queen)
		printSwarmStats()
	    os.sleep(0.5)		
	elseif(cmd == "PRINT") then --printGroup
		printSwarmStats()
	    os.sleep(0.5)

	elseif(cmd == "GPS") then
		for addr,c in pairs(ffbook[1]) do
			print(addr,c)
			local c_actl = c
			if c[1]>0 then c_actl[1]=c[1]+1 end
			if c[3]<0 then c_actl[3]=c[3]-1 end
			modem.send(addr,QueensChannel,"setgpspos",_,c_actl[1],c_actl[2],c_actl[3])
		end
		modem.broadcast(QueensChannel,"startgps")
    	os.sleep(0.5)
	elseif(cmd == "TRG") then
		updateGPSTRGs(trgPortBook)
    	os.sleep(0.5)
		
	elseif(cmd == "K") then
		killGPSTRGThread()
    	os.sleep(0.5)
		
	elseif(cmd == "S") then
    	modem.broadcast(QueensChannel,"stop")
		event.ignore("modem_message",msg_handler)
    	os.sleep(0.5)
	elseif(cmd == "HUSH") then
		modem.broadcast(QueensChannel,"HUSH")
    	os.sleep(0.5)

	elseif(cmd == "EXIT") then
		flightform.closeFlighFormComms()
		killGPSTRGThread()
		os.exit()
	else
    	modem.broadcast(QueensChannel,cmd)
	end
end
