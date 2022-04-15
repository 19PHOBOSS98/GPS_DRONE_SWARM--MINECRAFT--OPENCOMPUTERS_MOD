local s_utils = require 'swarm_utilities'
local GPS ={}


local floor, sqrt, abs = math.floor, math.sqrt, math.abs
--local round,cross,len,dot,add,sub,mul,norm,trunc,vec_trunc,arr_length = s_utils.round,s_utils.cross,s_utils.len,s_utils.dot,s_utils.add,s_utils.sub,s_utils.mul,s_utils.norm,s_utils.trunc,s_utils.vec_trunc,s_utils.arr_length
local arr_length = s_utils.arr_length
local trunc,vec_trunc = s_utils.trunc,s_utils.vec_trunc
--local round,cross,len,dot,add,sub,mul,norm = s_utils.round,s_utils.cross,s_utils.len,s_utils.dot,s_utils.add,s_utils.sub,s_utils.mul,s_utils.norm
--local round = s_utils.round
local cross = s_utils.cross
local len = s_utils.len
local dot = s_utils.dot
local add = s_utils.add
local sub = s_utils.sub
--local function round(v, m) return {x = floor((v.x+(m*0.5))/m)*m, y = floor((v.y+(m*0.5))/m)*m, z = floor((v.z+(m*0.5))/m)*m} end
--local function cross(v, b) return {x = v.y*b.z-v.z*b.y, y = v.z*b.x-v.x*b.z, z = v.x*b.y-v.y*b.x} end
--local function len(v) return sqrt(v.x^2+v.y^2+v.z^2) end
--local function dot(v, b) return v.x*b.x+v.y*b.y+v.z*b.z end
--local function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
--local function sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
local function mul(v, m) return {x=v.x*m, y=v.y*m, z=v.z*m} end
local function norm(v) return mul(v, 1/len(v)) end
--[[
local function trunc(v) local t = math.modf(v) return t end
local function vec_trunc(A)
	if A then
		return {x=trunc(A.x),y=trunc(A.y),z=trunc(A.z)}
	end
	return nil
end

local function arr_length(a)
	--print("arr_local")
	local c = 0
	for k,_ in pairs(a) do c=c+1 end
	return c
end]]


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
		--print("p1: ",p1.x,p1.y,p1.z)
		return p1,nil
	else 
		--print("p2: ",p2.x,p2.y,p2.z)
		return p2,nil
	end
end

function GPS.getGPSPos(gpsT) --**********************--
	local fixes = {}
	local pos1, pos2 = nil, nil
	for addr,fix in pairs(gpsT) do
		if fix.d == 0 then 
			pos1, pos2 = {x=fix.x, y=fix.y, z=fix.z}, nil
		else 
			table.insert(fixes, fix)
			print(addr,fix.x,fix.y,fix.z,fix.d)
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
		local c = pos1
		return {x=c.x,y=c.y,z=c.z}
	else 
		return nil
	end
end



function GPS.refreshGPSTable(gpsT,refreshCounter,refreshInterval) --************--
	--print("refreshCounter: ",refreshCounter,"refreshInterval: ",refreshInterval)
	if refreshCounter >= refreshInterval then return 0,{} end
	return refreshCounter + 1,gpsT
end


function GPS.add2GPSTable(r_addr,x,y,z,dist,gpsT) --************--
	--print("add2GPSTable")
	if arr_length(gpsT) < 7 then gpsT[r_addr] = {x=x,y=y,z=z,d=dist} end 
end

return GPS
