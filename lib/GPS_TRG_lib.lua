local thread = require 'thread'
local term = require 'term'
local event = require 'event'
local component = require 'component'
local modem = component.modem

local radar_targeting = require 'radar_targeting'
local s_utils = require 'swarm_utilities'
local GPS = require 'GPS'

local vec_trunc,add = s_utils.vec_trunc,s_utils.add

local GPS_TRG = {}

function GPS_TRG.bcGPSTRGPos(tpBook,gpsC)
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
			--print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			gpsPos = vec_trunc(gpsPos)
			print("gpsPos: ",gpsPos.x,gpsPos.y,gpsPos.z)
			for tport,tname in pairs(tpBook) do
				--print("tport: ",tport,"tname: ",tname)
				--local radPos = radar_targeting.getPlayerCoord(tname)
				local radPos = radar_targeting.getEntityCoord(tname)
				--print("tport: ",tport,"tname: ",tname,"radPos: ",radPos.c.x,radPos.c.y,radPos.c.z)
				radPos.c = vec_trunc(radPos.c)
				if radPos.d then
					local trgPos = add(radPos.c,gpsPos)
					print("tport: ",tport,"tname: ",tname,"trgPos: ",trgPos.x,trgPos.y,trgPos.z)
					modem.broadcast(tport,"trg",trgPos.x,trgPos.y,trgPos.z)
				end
			end
		end
		refreshGPSCounter,gpsTable = GPS.refreshGPSTable(gpsTable,refreshGPSCounter,refreshGPSInterval)
		os.sleep(0.5)
	end
	
end

GPS_TRG.gpstrgThread = nil

function GPS_TRG.updateGPSTRGs(tpBook,gpsC) --**********************-- --only call this sparingly, don't want to stall other flight formations
	GPS_TRG.killGPSTRGThread(gpsC)
	GPS_TRG.gpstrgThread = thread.create(function(tpb,gpsC) print("threading") GPS_TRG.bcGPSTRGPos(tpb,gpsC) end,tpBook,gpsC)
end
function GPS_TRG.killGPSTRGThread(gpsC) --**********************--
	if GPS_TRG.gpstrgThread then GPS_TRG.gpstrgThread:kill() modem.close(gpsC) end
end

return GPS_TRG