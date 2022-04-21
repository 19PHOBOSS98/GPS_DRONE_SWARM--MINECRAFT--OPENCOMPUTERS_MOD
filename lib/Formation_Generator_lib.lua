local TWPI = math.pi*2

function rotatePointOnXAxis(radians,point)
	local s = math.sin(radians);
	local c = math.cos(radians);
	
	local ynew = point.y * c - point.z * s;
	local znew = point.y * s + point.z * c;
	return {x=point.x,y=ynew,z=znew}
end

function rotatePointOnYAxis(radians,point)
	local s = math.sin(radians);
	local c = math.cos(radians);
	
	local xnew = point.x * c - point.z * s;
	local znew = point.x * s + point.z * c;
	return {x=xnew,y=point.y,z=znew}
end

function rotatePointOnZAxis(radians,point)
	local s = math.sin(radians);
	local c = math.cos(radians);
	
	local xnew = point.x * c - point.y * s;
	local ynew = point.x * s + point.y * c;
	return {x=xnew,y=ynew,z=point.z}
end

rotate = {
    ["X"] = function(i,basePoint) return rotatePointOnXAxis(i,basePoint) end,
    ["Y"] = function(i,basePoint) return rotatePointOnYAxis(i,basePoint) end,
    ["Z"] = function(i,basePoint) return rotatePointOnZAxis(i,basePoint) end
}

local FORMATION_GENERATOR = {}

function FORMATION_GENERATOR.circleFormation(axis,droneCount,basePoint) --***************************--
    --print("\nA Circle with ",droneCount,"drone(s):")
    local rot_div = TWPI/droneCount
    local formationTable = {}
    for i = 0,TWPI-rot_div, rot_div do
        local c = rotate[axis](i,basePoint)
        table.insert(formationTable,c)
    end
    return formationTable
end
--[[
circ = circleFormation("Y",4,{x=0,y=0,z=5})
for k,v in pairs(circ) do
    print(v.x,v.y,v.z)
end
]]


planeAxis = {
    ["X"] = function(l,w,pos) return {x=pos.x,y=pos.y+w,z=pos.z+l} end,
    ["Y"] = function(l,w,pos) return {x=pos.x+w,y=pos.y,z=pos.z+l} end,
    ["Z"] = function(l,w,pos) return {x=pos.x+w,y=pos.y+l,z=pos.z} end
}

function FORMATION_GENERATOR.SquareFormation(droneCount,basePoint) --***************************--
    --print("\nA Circle with ",droneCount,"drone(s):")
    local rot_div = TWPI/droneCount
    local formationTable = {}
    for i = 0,TWPI-rot_div, rot_div do
        local c = rotate[axis](i,basePoint)
        table.insert(formationTable,c)
    end
    return formationTable
end

function FORMATION_GENERATOR.squareFormation(plane_axis,width,length,basePoint)
    local formationTable = {}
    for l=0,length-1 do
        for w=0,width-1 do
            local derivedPos = planeAxis[plane_axis](l,w,basePoint)
            table.insert(formationTable,derivedPos)
        end
    end
    return formationTable
end
--[[
print("5X3:")
s = squareFormation("Y",5,3,{x=0,y=0,z=0})
for k,v in pairs(s) do
    print(v.x,v.y,v.z)
end
]]
function FORMATION_GENERATOR.hollowSquareFormation(plane_axis,width,length,basePoint)
    local formationTable = {}
    for l=0,length-1 do
        for w=0,width-1 do
            if not (w > 0 and w < width-1 and l > 0 and l<length-1) then
                local derivativePos = planeAxis[plane_axis](l,w,basePoint)
                table.insert(formationTable,derivativePos)
            end
        end
    end
    return formationTable
end

--[[
print("hollowSquare:")
print("5X2:")
hs = hollowSquareFormation("Y",5,2,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

XXXXX
XXXXX

print("5X3:")
hs = hollowSquareFormation("Y",5,3,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

XXXXX
XOOOX
XXXXX


print("5X5:")
hs = hollowSquareFormation("Y",5,5,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

XXXXX
XOOOX
XOOOX
XOOOX
XXXXX

print("2X2:")
hs = hollowSquareFormation("Y",2,2,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

XX
XX

print("3X2:")
hs = hollowSquareFormation("Y",3,2,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

XXX
XXX


]]


return FORMATION_GENERATOR
