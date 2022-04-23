local s_utils = require 'swarm_utilities'

local FORMATION_GENERATOR = {}

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



function FORMATION_GENERATOR.rotateFormation(axis,radians,formationTable) --***************************--
    local newFormationTable = {}
    for k,position in pairs(formationTable) do
        local newPos = rotate[axis](radians,{x=position.x,y=position.y,z=position.z})
        table.insert(newFormationTable,{newPos.x,newPos.y,newPos.z})
    end
    return newFormationTable
end

--[[
print("\nTriangle:")
t = TriangleFormation("Y:spanX",2,4,2,1,{x=0,y=0,z=0})
for k,v in pairs(t) do
    print(v.x,v.y,v.z)
end



print("\nRotated Triangle:")
new_t = rotateFormation("Y",math.pi/2,t)

for k,v in pairs(new_t) do
    print(v.x,v.y,v.z)
end

print("\nHollow Square:")
hsqr = hollowSquareFormation("Y",5,3,{x=0,y=0,z=0})
for k,v in pairs(hsqr) do
    print(v.x,v.y,v.z)
end

XXXXX
XOOOX
XXXXX

print("\nRotated Hollow Square:")
new_t = rotateFormation("Z",math.pi/2,hsqr)
for k,v in pairs(new_t) do
    print(v.x,v.y,v.z)
end
]]

function FORMATION_GENERATOR.circleFormation(axis,droneCount,basePoint) --***************************--
    --print("\nA Circle with ",droneCount,"drone(s):")
    local rot_div = TWPI/droneCount
    local formationTable = {}
    for i = 0,TWPI-rot_div, rot_div do
        local c = rotate[axis](i,basePoint)
        table.insert(formationTable,{c.x,c.y,c.z})
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
--[[
function FORMATION_GENERATOR.SquareFormation(droneCount,basePoint) --***************************--
    --print("\nA Circle with ",droneCount,"drone(s):")
    local rot_div = TWPI/droneCount
    local formationTable = {}
    for i = 0,TWPI-rot_div, rot_div do
        local c = rotate[axis](i,basePoint)
        table.insert(formationTable,{c.x,c.y,c.z})
    end
    return formationTable
end
]]
function FORMATION_GENERATOR.squareFormation(plane_axis,width,length,basePoint) --***************************--
    local formationTable = {}
    for l=0,length-1 do
        for w=0,width-1 do
            local derivedPos = planeAxis[plane_axis](l,w,basePoint)
            table.insert(formationTable,{derivedPos.x,derivedPos.y,derivedPos.z})
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
function FORMATION_GENERATOR.hollowSquareFormation(plane_axis,width,length,scale,basePoint) --****************************--
    local formationTable = {}
    for l=0,length-1 do
        for w=0,width-1 do
            if not (w > 0 and w < width-1 and l > 0 and l<length-1) then
                local derivedPos = planeAxis[plane_axis](l,w,basePoint)
                derivedPos = s_utils.mul(derivedPos,scale)
                table.insert(formationTable,{derivedPos.x,derivedPos.y,derivedPos.z})
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

P == {x=0,y=0,z=0}

XXXXX
PXXXX

print("5X3:")
hsqr = hollowSquareFormation("Y",5,3,{x=-2,y=0,z=-1})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

P == {x=-2,y=0,z=-1}

XXXXX
XOOOX
PXXXX


print("5X5:")
hs = hollowSquareFormation("Y",5,5,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

P == {x=0,y=0,z=0}

XXXXX
XOOOX
XOOOX
XOOOX
PXXXX

print("2X2:")
hs = hollowSquareFormation("Y",2,2,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

P == {x=0,y=0,z=0}

XX
PX

print("3X2:")
hs = hollowSquareFormation("Y",3,2,{x=0,y=0,z=0})
for k,v in pairs(hs) do
    print(v.x,v.y,v.z)
end

P == {x=0,y=0,z=0}
XXX
PXX


]]

--[[
X	X       X       X       X
    X                       X
        X               X
            X       X
                X
]]
triangleDirection = {
    ["Y:spanZ"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x,y=basePoint.y+height_rise,z=basePoint.z+b_run},
                        {x=basePoint.x,y=basePoint.y+height_rise,z=basePoint.z-b_run} 
            end,
    ["-Y:spanZ"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x,y=basePoint.y-height_rise,z=basePoint.z+b_run},
                        {x=basePoint.x,y=basePoint.y-height_rise,z=basePoint.z-b_run} 
            end,
    ["Y:spanX"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x+b_run,y=basePoint.y+height_rise,z=basePoint.z},
                        {x=basePoint.x-b_run,y=basePoint.y+height_rise,z=basePoint.z} 
            end,
    ["-Y:spanX"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x+b_run,y=basePoint.y-height_rise,z=basePoint.z},
                        {x=basePoint.x-b_run,y=basePoint.y-height_rise,z=basePoint.z} 
            end,
    ["X:spanZ"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x+height_rise,y=basePoint.y,z=basePoint.z+b_run},
                        {x=basePoint.x+height_rise,y=basePoint.y,z=basePoint.z-b_run} 
            end,
    ["-X:spanZ"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x-height_rise,y=basePoint.y,z=basePoint.z+b_run},
                        {x=basePoint.x-height_rise,y=basePoint.y,z=basePoint.z-b_run}
            end,
    ["X:spanY"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x+height_rise,y=basePoint.y+b_run,z=basePoint.z},
                        {x=basePoint.x+height_rise,y=basePoint.y-b_run,z=basePoint.z} 
            end,
    ["-X:spanY"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x-height_rise,y=basePoint.y+b_run,z=basePoint.z},
                        {x=basePoint.x-height_rise,y=basePoint.y-b_run,z=basePoint.z}
            end,
    ["Z:spanX"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x+b_run,y=basePoint.y,z=basePoint.z+height_rise},
                        {x=basePoint.x-b_run,y=basePoint.y,z=basePoint.z+height_rise} 
            end,
    ["-Z:spanX"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x+b_run,y=basePoint.y,z=basePoint.z-height_rise},
                        {x=basePoint.x-b_run,y=basePoint.y,z=basePoint.z-height_rise}
            end,
    ["Z:spanY"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x,y=basePoint.y+b_run,z=basePoint.z+height_rise},
                        {x=basePoint.x,y=basePoint.y-b_run,z=basePoint.z+height_rise}
            end,
    ["-Z:spanY"] = function(height_rise,b_run,basePoint) 
                return {x=basePoint.x,y=basePoint.y+b_run,z=basePoint.z-height_rise},
                        {x=basePoint.x,y=basePoint.y-b_run,z=basePoint.z-height_rise}
            end,  
}


function FORMATION_GENERATOR.TriangleFormation(plane_axis,height,base,scale,basePoint) --***************************--
    local formationTable = {}
    local slope = height/(base*0.5)
    table.insert(formationTable,{basePoint.x,basePoint.y,basePoint.z})
    local run = 0
    
    for rise = 1,height do
        run = rise/slope
        local pos,neg = triangleDirection[plane_axis](rise,run,basePoint)
        table.insert(formationTable,{pos.x,pos.y,pos.z})
        table.insert(formationTable,{neg.x,neg.y,neg.z})
    end
    for b = run,1,-1 do 
        local pos,neg = triangleDirection[plane_axis](height,b,basePoint)
	
        if not s_utils.isEqual(pos,neg) then
		pos = s_utils.mul(pos,scale)
		table.insert(formationTable,{neg.x,neg.y,neg.z})
        end
	pos = s_utils.mul(pos,scale)
	table.insert(formationTable,{pos.x,pos.y,pos.z})
    end
    return formationTable
end
--[[
print("\nTriangle:")
t = TriangleFormation("Y:spanX",2,4,2,1,{x=0,y=0,z=0})
for k,v in pairs(t) do
    print(v.x,v.y,v.z)
end

OUTPUT:
Triangle:
0	0	0
1.0	1	0
-1.0	1	0
0.0	2	0

]]
return FORMATION_GENERATOR
