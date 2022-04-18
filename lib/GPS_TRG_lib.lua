local thread = require 'thread'
local term = require 'term'
local event = require 'event'
local component = require 'component'
local modem = component.modem

local radar_targeting = require 'radar_targeting'
local s_utils = require 'swarm_utilities'
local GPS = require 'GPS'
local flightform = require 'flight_formation'
local vec_trunc,add = s_utils.vec_trunc,s_utils.add

local GPS_TRG = {}

function GPS_TRG.bcGPSTRGPos(tpBook,gpsC,rotAnglInt)
	modem.open(gpsC)
	modem.setStrength(math.huge)
	local gpsTable = {}
	local refreshGPSInterval = 5
	local refreshGPSCounter = 0
	event.listen("modem_message",function(_,_,r_addr,_,dist,msg,xg,yg,zg,...)
		if msg == "gps" then
			GPS.add2GPSTable(r_addr,xg,yg,zg,dist,gpsTable)
		end
	end)
	while true do
		--term.clear()
		local gpsPos = GPS.getGPSPos(gpsTable)
		if gpsPos then
			--print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			gpsPos = vec_trunc(gpsPos)
			--print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			for tport,tname in pairs(tpBook) do
				--print("tport: ",tport,"tname: ",tname)
				--local radPos = radar_targeting.getPlayerCoord(tname)
				local radPos = radar_targeting.getEntityCoord(tname)
				--print("tport: ",tport,"tname: ",tname,"radPos: ",radPos.c.x,radPos.c.y,radPos.c.z)
				if radPos then
					radPos.c = vec_trunc(radPos.c)
					local trgPos = add(radPos.c,gpsPos)
					--print("tport: ",tport,"tname: ",tname,"trgPos: ",trgPos.x,trgPos.y,trgPos.z)
					modem.broadcast(tport,"trg",trgPos.x,trgPos.y,trgPos.z,"",rotAnglInt)
				end
			end
		else
			print("GPS Out Of Range")
		end
		refreshGPSCounter,gpsTable = GPS.refreshGPSTable(gpsTable,refreshGPSCounter,refreshGPSInterval)
		os.sleep(0.5)
	end
	
end

function GPS_TRG.bcGPSTRGPosPRINT(tpBook,gpsC,rotAnglInt)
	modem.open(gpsC)
	modem.setStrength(math.huge)
	local gpsTable = {}
	local refreshGPSInterval = 5
	local refreshGPSCounter = 0
	event.listen("modem_message",function(_,_,r_addr,_,dist,msg,xg,yg,zg,...)
		if msg == "gps" then
			GPS.add2GPSTable(r_addr,xg,yg,zg,dist,gpsTable)
		end
	end)
	while true do
		term.clear()
		local gpsPos = GPS.getGPSPos(gpsTable)
		if gpsPos then
			print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			gpsPos = vec_trunc(gpsPos)
			print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			for tport,tname in pairs(tpBook) do
				--print("tport: ",tport,"tname: ",tname)
				--local radPos = radar_targeting.getPlayerCoord(tname)
				local radPos = radar_targeting.getEntityCoord(tname)
				--print("tport: ",tport,"tname: ",tname,"radPos: ",radPos.c.x,radPos.c.y,radPos.c.z)
				if radPos then
					radPos.c = vec_trunc(radPos.c)
					local trgPos = add(radPos.c,gpsPos)
					print("tport: ",tport,"tname: ",tname,"trgPos: ",trgPos.x,trgPos.y,trgPos.z,",rotAnglInt",rotAnglInt)
					modem.broadcast(tport,"trg",trgPos.x,trgPos.y,trgPos.z,"",rotAnglInt)
				else
					print(tname," is out of radar Range")
				end
			end
		else
			print("GPS Out Of Range")
		end
		refreshGPSCounter,gpsTable = GPS.refreshGPSTable(gpsTable,refreshGPSCounter,refreshGPSInterval)
		os.sleep(0.5)
	end
	
end

function GPS_TRG.bcGPSRecall(tpBook,gpsC,PawnsC)
	modem.open(gpsC)
	modem.setStrength(math.huge)
	local gpsTable = {}
	local refreshGPSInterval = 5
	local refreshGPSCounter = 0
	event.listen("modem_message",function(_,_,r_addr,_,dist,msg,xg,yg,zg,...)
		if msg == "gps" then
			GPS.add2GPSTable(r_addr,xg,yg,zg,dist,gpsTable)
		end
	end)
	modem.broadcast(PawnsC,"formup",0,2,0,1)
	while true do
		term.clear()
		local gpsPos = GPS.getGPSPos(gpsTable)
		if gpsPos then
			gpsPos = vec_trunc(gpsPos)
			print("Recalling...")
			print("GPS Location: ",gpsPos.x,gpsPos.y,gpsPos.z)
			modem.broadcast(1,"trg",gpsPos.x,gpsPos.y,gpsPos.z)
		else
			print("GPS Out Of Range")
		end
		refreshGPSCounter,gpsTable = GPS.refreshGPSTable(gpsTable,refreshGPSCounter,refreshGPSInterval)
		os.sleep(0.5)
	end
	
end


function GPS_TRG.bcStaticGPSPos(tport,gpsC,rotAnglInt)
	modem.open(gpsC)
	modem.setStrength(math.huge)
	local gpsTable = {}
	local refreshGPSInterval = 5
	local refreshGPSCounter = 0
	event.listen("modem_message",function(_,_,r_addr,_,dist,msg,xg,yg,zg,...)
		if msg == "gps" then
			GPS.add2GPSTable(r_addr,xg,yg,zg,dist,gpsTable)
		end
	end)
	repeat
		term.clear()
		print("..Static Formation..")
		local gpsPos = GPS.getGPSPos(gpsTable)
		if gpsPos then
			gpsPos = vec_trunc(gpsPos)
			print("GPS Formation Center: ",gpsPos.x,gpsPos.y,gpsPos.z)
			print("Broadcasting to trgChannel: ",tport)
			print("rotAnglInt: ",rotAnglInt)
			modem.broadcast(tport,"trg",gpsPos.x,gpsPos.y,gpsPos.z,"",rotAnglInt)
		else
			print("GPS Out Of Range")
		end
		refreshGPSCounter,gpsTable = GPS.refreshGPSTable(gpsTable,refreshGPSCounter,refreshGPSInterval)
		os.sleep(0.5)
	until gpsPos
	os.sleep(3)
	modem.close(gpsC)
	print("PAWNS:")
	flightform.printDronePool(false)
	flightform.printFFAssignment(Pawnffbook)
	
end



GPS_TRG.gpstrgThread = nil

function GPS_TRG.updateGPSTRGs(tpBook,gpsC,rotAngInt) --**********************-- --only call this sparingly, don't want to stall other flight formations
	GPS_TRG.killGPSTRGThread(gpsC)
	GPS_TRG.gpstrgThread = thread.create(function(tpb,gpsC,rotAngInt) print("threading") GPS_TRG.bcGPSTRGPos(tpb,gpsC,rotAngInt) end,tpBook,gpsC,rotAngInt)
end

function GPS_TRG.updateGPSTRGsPRINT(tpBook,gpsC,rotAngInt) --**********************-- --only call this sparingly, don't want to stall other flight formations
	GPS_TRG.killGPSTRGThread(gpsC)
	GPS_TRG.gpstrgThread = thread.create(function(tpb,gpsC,rotAngInt) print("threading") GPS_TRG.bcGPSTRGPosPRINT(tpb,gpsC,rotAngInt) end,tpBook,gpsC,rotAngInt)
end

function GPS_TRG.GPSRecall(tpBook,gpsC,PawnsC) --**********************-- --only call this sparingly, don't want to stall other flight formations
	GPS_TRG.killGPSTRGThread(gpsC)
	GPS_TRG.gpstrgThread = thread.create(function(tpb,gpsC,PawnsC) print("threading") GPS_TRG.bcGPSRecall(tpb,gpsC,PawnsC) end,tpBook,gpsC,PawnsC)
end

function GPS_TRG.updateStaticGPS(tpBook,gpsC,rotAngInt) --**********************--
	GPS_TRG.killGPSTRGThread(gpsC)
	GPS_TRG.gpstrgThread = thread.create(function(tpb,gpsC,rotAngInt) print("threading") GPS_TRG.bcStaticGPSPos(tpb,gpsC,rotAngInt) end,tpBook,gpsC,rotAngInt)
end

function GPS_TRG.killGPSTRGThread(gpsC) --**********************--
	if GPS_TRG.gpstrgThread then GPS_TRG.gpstrgThread:kill() modem.close(gpsC) end
end


return GPS_TRG
