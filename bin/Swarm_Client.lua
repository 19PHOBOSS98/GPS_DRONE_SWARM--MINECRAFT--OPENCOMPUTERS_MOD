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
form1 = {{0,0,0},{2,2,0},{0,4,4},{-8,8,0},{0,10,-10},{12,12,0},{0,14,14},{-16,16,0}}
--form2 = {{-2,10,2},{2,15,2},{0,2,0}}
--form3 = {{-2,20,-2},{2,25,-2}}
form2 = {{-10,10,10},{10,12,10},{0,5,0}}
form3 = {{-10,14,-10},{10,16,-10}}
fbook={form1,form2,form3}
dynamic_fbook = fbook


print("Bingus28")


local gpsChannel = 2
local trgChannel = 3


function gpsBroadcast(gps_port)
	while true do
		modem.broadcast(gps_port,"gps",0,0,0)
		--print("broadcasting..")
		os.sleep(3)
	end
end

local gpsThread
local sat_mode = false
function toggleGPSBroadCast(channel) --**********************--
	sat_mode = not sat_mode
	print("sat_mode: "..tostring(sat_mode))
	if sat_mode then
		print("creating GPS Thread..")
		gpsThread = thread.create(function(port) gpsBroadcast(port) end,channel)
	else
		gpsThread:kill()
	end
end

function getPlayerCoord(e_name) 
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(Tr.getPlayers()) do 
		if v.name == e_name then
			return {v.x,v.y,v.z},v.distance
		end 
	end
	return {0,0,0},0
end

function trgBroadcast(e_name)
	while true do
		local player_co = getPlayerCoord(e_name)
		player_co = s_utils.vec_trunc(player_co)
		modem.broadcast(trgChannel,"trg",player_co[1],player_co[2],player_co[3])
		--print("broadcasting target..")
		os.sleep(3)
	end
end

local trgThread
local send_trg = false
function toggleTargetBroadCast(target) --**********************--
	send_trg = not send_trg
	print("send_trg: "..tostring(send_trg))
	if send_trg then
		print("creating TRG Thread..")
		flightform.formFF(S_ffbook[1],S_dynamic_fbook[1],SoldiersChannel,false)
		flightform.formUP("ph0",S_ffbook[1],S_dynamic_fbook[1],SoldiersChannel,false)
		trgThread = thread.create(function(t) trgBroadcast(t) end,target)
	else
		trgThread:kill()
	end
end

function trgWOffset(e_name)
	while true do
		local player_co = getPlayerCoord(e_name)
		player_co = s_utils.vec_trunc(player_co)
		flightform.updateOffset(S_ffbook[1],S_dynamic_fbook[1],player_co,trgChannel)
		--print("target with offset..")
		os.sleep(3)
	end
end
local trgWoThread
local send_trgWo = false
function toggleTargetWithOffset(target) --**********************--
	send_trgWo = not send_trgWo
	print("send_trgWo: "..tostring(send_trgWo))
	if send_trgWo then
		print("creating TRG Thread..")
		flightform.formFF(S_ffbook[1],S_dynamic_fbook[1],SoldiersChannel,false)
		flightform.formUP("ph0",S_ffbook[1],S_dynamic_fbook[1],SoldiersChannel,false)
		trgWoThread = thread.create(function(t) trgWOffset(t) end,target)
	else
		trgWoThread:kill()
	end
end

function printSwarmStats()
	term.clear()
	flightform.printDronePool(drone_is_queen)
	flightform.printFFAssignment(ffbook)
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
		toggleGPSBroadCast(gpsChannel)
    	os.sleep(0.5)
	elseif(cmd == "TRG") then
		toggleTargetBroadCast("ph0")
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
		if gpsThread then
			gpsThread:kill()
		end
		if trgThread then
			trgThread:kill()
		end
		os.exit()
	else
    	modem.broadcast(QueensChannel,cmd)
	end
end
