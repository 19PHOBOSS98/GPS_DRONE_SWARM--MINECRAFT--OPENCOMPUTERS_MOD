local component = require("component")
local event = require("event")
local serialization= require("serialization")
local computer= require("computer")
local thread= require("thread")
local term= require("term")
local modem = component.modem
--local Tn = component.navigation
--local Tr = component.radar
local QueensChannel = 2412
local QueensResponseChannel = 2402
local PawnsChannel = 2413
local PawnsResponseChannel = 2403

local drone_is_queen = true

--custom libraries
local s_utils = require("swarm_utilities")
local q_firmware = require("queen_firmware")
local flightform = require("flight_formation")
local radar_targeting = require("radar_targeting")
local GPS = require("GPS")
local GPS_TRG = require("GPS_TRG")
local p_firmware = require("pawn_firmware")

modem.open(QueensResponseChannel)
modem.open(PawnsResponseChannel)

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
--satff={}
--compensatedSatForm = {{0,25,-2},{0,25,3},{2,22,0},{-3,22,0}}
--form1 = {{0,35,-3},{0,30,3},{3,20,0},{-3,25,0}}
--form1 = {{0,35,-5},{0,30,2},{5,20,0},{-2,25,0}}
--form2 = {{-2,10,2},{2,15,2},{0,2,0}}
--form3 = {{-2,20,-2},{2,25,-2}}
--form2 = {{-10,10,10},{10,12,10},{0,5,0}}
--form3 = {{-10,14,-10},{10,16,-10}}
form2 = {{3,0,0},{0,3,0},{0,0,3},{3,0,3},{-3,0,-3}}
form3 = {{-3,0,0},{0,-3,0},{0,0,-3},{3,3,3},{-3,-3,-3}}

--*************--
--[[
The radar has an inaccuracy where it recognises two blocks as zeroes in each axis.
Drones positioned in coordinates with positive axis components around a target player are actually a block extra away from the origin
the given formation array is thus compensated in the formUP function from the flight_formation library
]]
--*************--

fbook={actualSatForm,form2,form3}
dynamic_fbook = fbook


print("Bingus30")
function printSwarmStats()
	term.clear()
	print("QUEENS:")
	flightform.printDronePool(drone_is_queen)
	flightform.printFFAssignment(ffbook)
end


local gpsChannel = 2
--local trgChannel = 3


--trgPortBook = {}--{[trgport]="target"} multiple to fixed single relationship
trgPortBook = {[3]="Bingus",[4]="Floppa",[5]="FloppaMi",[7]="FloppaNi"}

Pawnffbook = {}
Pawnffbook[1] = {}
Pawnform1 = {{3,2,-2},{-3,2,-2},{0,2,3}}
--Pawnform1 = {{0,2,0}}
Pawnfbook = {Pawnform1}
Pawndynamic_fbook = Pawnfbook


function printSwarmStatsPawn()
	term.clear()
	print("PAWNS:")
	flightform.printDronePool(false)
	flightform.printFFAssignment(Pawnffbook)
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
		flightform.QformUP("ph0",ffbook[1],QueensChannel)
		printSwarmStats()
	    os.sleep(0.5)
	elseif(cmd == "Q") then
		flightform.refreshFFT(ffbook,dynamic_fbook,QueensChannel,drone_is_queen)
		flightform.formFF(ffbook[2],dynamic_fbook[2],QueensChannel,drone_is_queen)
		flightform.formFF(ffbook[3],dynamic_fbook[3],QueensChannel,drone_is_queen)
		flightform.QformUP("ph0",ffbook[2],QueensChannel)
		flightform.QformUP("ph0",ffbook[3],QueensChannel)
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
	elseif(cmd == "PRINTQ") then --printGroup
		printSwarmStats()
	    os.sleep(0.5)
	elseif(cmd == "S") then
    	modem.broadcast(QueensChannel,"stop")
		event.ignore("modem_message",msg_handler)
    	os.sleep(0.5)
	elseif(cmd == "HUSH") then
		modem.broadcast(QueensChannel,"HUSH")
    	os.sleep(0.5)
		
		
		
	elseif(cmd == "GPS") then
		for addr,c in pairs(ffbook[1]) do
			print(addr,c)
			modem.send(addr,QueensChannel,"setgpspos",_,c[1],c[2],c[3])
		end
		modem.broadcast(QueensChannel,"startgps")
    	os.sleep(0.5)
	elseif(cmd == "TRG") then
		GPS_TRG.updateGPSTRGsPRINT(trgPortBook,gpsChannel)
    	os.sleep(0.5)
		
	elseif(cmd == "K") then
		GPS_TRG.killGPSTRGThread(gpsChannel)
    	os.sleep(0.5)





	elseif(cmd == "A") then -- form triangle on Floppa with PAWNS
		flightform.refreshFFT(Pawnffbook,Pawndynamic_fbook,PawnsChannel,false)
		flightform.formFF(Pawnffbook[1],Pawndynamic_fbook[1],PawnsChannel,false)
		flightform.PformUP(4,Pawnffbook[1],PawnsChannel)
		printSwarmStatsPawn()
		os.sleep(0.5)
		
	elseif(cmd == "GP") then -- recall PAWNS
		modem.broadcast(PawnsChannel,"stop")
		GPS_TRG.GPSRecall(trgPortBook,gpsChannel,PawnsChannel)
		os.sleep(0.5)	
		
	elseif(cmd == "FP") then
		p_firmware.broadcastFirmWare(PawnsChannel)
    	os.sleep(0.5)
	elseif(cmd == "EP") then 
		for i = 1,#Pawnffbook do
			flightform.breakFormation(Pawnffbook[i],Pawndynamic_fbook[i],PawnsChannel,false)
		end
		printSwarmStatsPawn()
		os.sleep(0.5)
	elseif(cmd == "RP") then	--refreshFormation
		flightform.refreshFFT(Pawnffbook,Pawndynamic_fbook,PawnsChannel,false)
		printSwarmStatsPawn()
		os.sleep(0.5)	
	elseif(cmd == "PRINTP") then
		printSwarmStatsPawn()
		os.sleep(0.5)
	elseif(cmd == "SP") then
    		modem.broadcast(PawnsChannel,"stop")
	    	os.sleep(0.5)
	elseif(cmd == "HUSHP") then
		modem.broadcast(PawnsChannel,"HUSH")
	    	os.sleep(0.5)		
		
		


		
	elseif(cmd == "EXIT") then
		flightform.closeFlighFormComms()
		GPS_TRG.killGPSTRGThread(gpsChannel)
		os.exit()
	else
    	modem.broadcast(QueensChannel,cmd)
	end
end
