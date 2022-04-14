local event = require 'event'
local component = require 'component'
local modem = component.modem

local swarm_utilities = require("swarm_utilities")

local flight_formation = {}

flight_formation.pool_Q={}
flight_formation.pool_S={}

function flight_formation.clearPool_Q(p)
	flight_formation.pool_Q={}
end
function flight_formation.clearPool_S(p)
	flight_formation.pool_S={}
end


msg_reaction = {
	["stats"] = function(l_add,r_add,port,dist,status,isQ,...) add2Pool(r_add,status,isQ) end
}
 
function msg_handler(evt,l_add,r_add,port,dist,msg,status,isQ,...)
	if msg_reaction[msg] then
		msg_reaction[msg](l_add,r_add,port,dist,status,isQ,...)
	end
end
 

function openFlighFormComms()
		event.ignore("modem_message",msg_handler)
		event.listen("modem_message",msg_handler)
		print("event listener created!!!")
end
function flight_formation.closeFlighFormComms() --**********************--
		event.ignore("modem_message",msg_handler)
		print("event listener destroyed!!!")
end
 
function flight_formation.populatePool(port,is_Queen) --**********************--
	openFlighFormComms()
	if is_Queen then
		modem.broadcast(port,"inv_q")
	else
		modem.broadcast(port,"inv_s")
	end
end
 
function add2Pool(addr,is_free,is_Q)
	if is_Q then
		flight_formation.pool_Q[addr] = is_free
	else
		flight_formation.pool_S[addr] = is_free
	end
end
 
function flight_formation.refreshPool(port,is_Queen) --**********************--
	--print("refreshing..")
	openFlighFormComms()
	if is_Queen then
		flight_formation.pool_Q={}
		modem.broadcast(port,"inv_q")
	else
		flight_formation.pool_S={}
		modem.broadcast(port,"inv_s")
	end
end
 
 
function populateFFT(ff,f,port,is_Queen)
	if is_Queen then
		for addr,is_free in pairs(flight_formation.pool_Q) do
			if not next(f) then return end
			if is_free then
				if not ff[addr] then
						ff[addr] = table.remove(f)
						flight_formation.pool_Q[addr] = false
						modem.send(addr,port,"commit")
				end
			end
		end
	else
		for addr,is_free in pairs(flight_formation.pool_S) do
			if not next(f) then return end
			if is_free then
				if not ff[addr] then
						ff[addr] = table.remove(f)
						flight_formation.pool_S[addr] = false
						modem.send(addr,port,"commit")
				end
			end
		end
	end
end
 
function pruneFFT(ff,f,is_Queen)
	local drone_pool = {}
	if is_Queen then drone_pool = flight_formation.pool_Q
	else drone_pool = flight_formation.pool_S
	end
	for addr,c in pairs(ff) do
		if drone_pool[addr]==nil then
			table.insert(f,1,c)
			ff[addr] = nil
		end
	end
end
 
function refreshFF(ff,f,port,is_Queen)
	print("refreshing FF..")
	flight_formation.refreshPool(port,is_Queen)
	os.sleep(2)
	pruneFFT(ff,f,is_Queen)
	for addr,c in pairs(ff) do
		modem.send(addr,port,"commit")
		if is_Queen then
			if not (flight_formation.pool_Q[addr] == nil) then flight_formation.pool_Q[addr] = false end
		else
			if not (flight_formation.pool_S[addr] == nil) then flight_formation.pool_S[addr] = false end
		end
	end
end

function flight_formation.refreshFFT(ffbook,fbook,port,is_Queen) --**********************--
	print("refreshing FFT..")
	for i = 1,#ffbook do
		refreshFF(ffbook[i],fbook[i],port,is_Queen)
	end
end



function flight_formation.formFF(ff,f,port,is_Queen) --**********************--
	populateFFT(ff,f,port,is_Queen)
end

function flight_formation.formUP(e_name,ff,f,port,is_Queen) --**********************--
	if is_Queen then
		for addr,pos in pairs(ff) do
			--modem.send(addr,port,"formup",e_name,pos[1],pos[2],pos[3])
			local comp_pos = {}
			comp_pos = pos
			if pos[1]>0 then comp_pos[1]=pos[1]-1 end --compensate positive coordinate component position
			if pos[2]>0 then comp_pos[2]=pos[2]-1 end
			if pos[3]>0 then comp_pos[3]=pos[3]-1 end
			modem.send(addr,port,"formup",e_name,comp_pos[1],comp_pos[2],comp_pos[3])
		end
	else
		for addr,pos in pairs(ff) do
			modem.send(addr,port,"formup")
		end
	end
end
function flight_formation.updateOffset(ff,f,e_pos,port) --**********************-- --generally reserved for soldiers
	for addr,pos in pairs(ff) do
		local trgPos = swarm_utilities.add_vec(e_pos,pos)
		modem.send(addr,port,"trg",trgPos[1],trgPos[2],trgPos[3])
	end
end
 
function flight_formation.breakFormation(ff,f,port,is_Queen) --**********************--
	for addr,pos in pairs(ff) do
		table.insert(f,1,pos)
		ff[addr]=nil
		if is_Queen then
			if not flight_formation.pool_Q[addr] == nil then
				flight_formation.pool_Q[addr]=true
			end
		else
			if not flight_formation.pool_S[addr] == nil then
				flight_formation.pool_S[addr]=true
			end
		end
		modem.send(addr,port,"uncommit")

	end
	os.sleep(1)
	flight_formation.refreshPool(port,is_Queen)
end
 
function flight_formation.printDronePool(is_Queen) --**********************--
	print("Drone Pool:")
	print("Address:				isFree:")
	if is_Queen then
		for k,v in pairs(flight_formation.pool_Q) do
			print(k.." ::	"..tostring(v))
		end
	else
		for k,v in pairs(flight_formation.pool_S) do
			print(k.." ::	"..tostring(v))
		end
	end
end
function flight_formation.printFFAssignment(ffb) --**********************--
	print("Flight Formation Assignment:")
	for i = 1,#ffb do
		print("Formation["..i.."]:")
		print("Address:				X:	Y:	Z:")
		for k,v in pairs(ffb[i]) do
			print(k.." ::	"..tostring(v[1]).."	"..tostring(v[2]).."	"..tostring(v[3]))
		end
	end
end

return flight_formation
