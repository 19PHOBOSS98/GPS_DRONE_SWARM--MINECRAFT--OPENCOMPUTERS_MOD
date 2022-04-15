local component = require 'component'
local radar = component.radar

local TRG = {}


function TRG.getPlayerCoord(e_name) --**********************--
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(radar.getPlayers()) do 
		if v.name == e_name then
			return {c={x=v.x,y=v.y,z=v.z},d=v.distance}
		end 
	end
	return nil
end


function TRG.getEntityCoord(e_name) ---**********************--
	checkArg(1,e_name,'string','nil') 
	for k,v in ipairs(radar.getEntities()) do 
		if v.name == e_name then
			return {c={x=v.x,y=v.y,z=v.z},d=v.distance}
		end 
	end
	return nil
end

return TRG
