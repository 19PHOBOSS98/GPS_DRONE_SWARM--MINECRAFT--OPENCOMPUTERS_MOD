local swarm_utilities = {}

local floor, sqrt, abs = math.floor, math.sqrt, math.abs

function swarm_utilities.round(v, m) return {x = floor((v.x+(m*0.5))/m)*m, y = floor((v.y+(m*0.5))/m)*m, z = floor((v.z+(m*0.5))/m)*m} end
function swarm_utilities.cross(v, b) return {x = v.y*b.z-v.z*b.y, y = v.z*b.x-v.x*b.z, z = v.x*b.y-v.y*b.x} end
function swarm_utilities.len(v) return sqrt(v.x^2+v.y^2+v.z^2) end
function swarm_utilities.dot(v, b) return v.x*b.x+v.y*b.y+v.z*b.z end
function swarm_utilities.add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
function swarm_utilities.sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
function swarm_utilities.mul(v, m) return {x=v.x*m, y=v.y*m, z=v.z*m} end
function swarm_utilities.norm(v) return swarm_utilities.mul(v, 1/swarm_utilities.len(v)) end
function swarm_utilities.trunc(v) local t = math.modf(v) return t end
function swarm_utilities.vec_trunc(A)
	if A then
		return {x=swarm_utilities.trunc(A.x),y=swarm_utilities.trunc(A.y),z=swarm_utilities.trunc(A.z)}
	end
	return nil
end
function swarm_utilities.arr_length(a)
	local c = 0
	for k,_ in pairs(a) do c=c+1 end
	return c
	end
return swarm_utilities
