master = "812d603b-18c2-45dc-a2ed-05184019526f"
local component = require("component")
local term = require("term")
local computer = require("computer")
local modem = component.modem
gpsChannel = 2
trgChannel = 3
SoldierChannel = 2412
modem.open(gpsChannel)
modem.open(trgChannel)
modem.open(SoldierChannel)
gpsSats={}
cmdTRGPos={}



function length(a)
  local c = 0
  for k,_ in pairs(a) do c=c+1 end
  return c
end

function add2GPSTable(r_addr,x,y,z,dist)
  if r_addr == master then gpsSats[r_addr] = {x=x,y=y,z=z,d=dist} end 
  if length(gpsSats) < 7 then gpsSats[r_addr]={x=x,y=y,z=z,d=dist} end 
end

tasks = {
["gps"] = function(r_addr,x,y,z,dist) add2GPSTable(r_addr,x,y,z,dist) end,
["trg"] = function(_,x,y,z) cmdTRGPos={vec={x,y,z},d=dist} end
}

local floor, sqrt, abs = math.floor, math.sqrt, math.abs

local function round(v, m)
  return {x = floor((v.x+(m*0.5))/m)*m, y = floor((v.y+(m*0.5))/m)*m, z = floor((v.z+(m*0.5))/m)*m}
end
local function cross(v, b)
  return {x = v.y*b.z-v.z*b.y, y = v.z*b.x-v.x*b.z, z = v.x*b.y-v.y*b.x}
end
local function len(v) return sqrt(v.x^2+v.y^2+v.z^2) end
local function dot(v, b) return v.x*b.x+v.y*b.y+v.z*b.z end
local function add(v, b) return {x=v.x+b.x, y=v.y+b.y, z=v.z+b.z} end
local function sub(v, b) return {x=v.x-b.x, y=v.y-b.y, z=v.z-b.z} end
local function mul(v, m) return {x=v.x*m, y=v.y*m, z=v.z*m} end
local function norm(v) return mul(v, 1/len(v)) end

function math.trunc(v)
    local t = math.modf(v)
	return t
end
local function vec_trunc(A)
	if A then
		return {math.trunc(A[1]),math.trunc(A[2]),math.trunc(A[3])}
	end
	return nil
end

local function trilaterate(A, B, C)
  local a2b = {x=B.x-A.x, y=B.y-A.y, z=B.z-A.z}
  local a2c = {x=C.x-A.x, y=C.y-A.y, z=C.z-A.z}
  if abs(dot(norm(a2b), norm(a2c))) > 0.999 then
    return nil
  end
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
    --local rnd1, rnd2 = round(result1, 0.01), round(result2, 0.01)
	--local rnd1, rnd2 = round(result1, 1), round(result2, 1)
	local rnd1, rnd2 = result1,result2
  if rnd1.x ~= rnd2.x or rnd1.y ~= rnd2.y or rnd1.z ~= rnd2.z then
    print("rnd1: ",rnd1.x,rnd1.y,rnd1.z)
    print("rnd2: ",rnd2.x,rnd2.y,rnd2.z)
    return rnd1, rnd2
    else
    return rnd1
    end
  end
  print("result: ",result.x,result.y,result.z)
  --return round(result, 0.01)
	--return round(result, 1)
	return result
end

local function narrow(p1, p2, fix)
  local d1 = abs(len(sub(p1, fix))-fix.d)
  local d2 = abs(len(sub(p2, fix))-fix.d)
  if abs(d1-d2) < 0.01 then
    return p1, p2
  elseif d1 < d2 then
    --return round(p1, 0.01),nil
	--return round(p1, 1),nil
	return p1,nil
  else
    --return round(p2, 0.01),nil
	--return round(p2, 1),nil
	return p2,nil
  end
end

local function locate()
  modem.open(gpsChannel)
  local fixes = {}
  local pos1, pos2 = nil, nil
  local deadline = computer.uptime()+2
  for addr,fix in pairs(gpsSats) do
    --print(addr,":: {",fix.x,fix.y,fix.z,fix.d,"}")
        if fix.d == 0 then
          pos1, pos2 = {fix.x, fix.y, fix.z}, nil
        else
          table.insert(fixes, fix)
    end
  end

  --for k,fix in ipairs(fixes) do print(k,":: {",fix.x,fix.y,fix.z,fix.d,"}")end

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

  if pos1 and pos2 then return nil
  --elseif pos1 then return {pos1.x, pos1.y, pos1.z}	
	elseif pos1 then 
		local c = round(pos1,1) 
		return {c.x,c.y,c.z}
  else return nil end
end


local refreshGPSInterval = 0
function refreshGPSTable()
	if refreshGPSInterval >= 60 then gpsSats={} refreshGPSInterval = 0 end
	refreshGPSInterval = refreshGPSInterval + 1
end

function getGPSlocation()
	local gpsPos = locate()
	--if gpsPos then return vec_trunc(gpsPos) end
	if gpsPos then return gpsPos end
	return nil
end
 
function getTRGPos()
	return cmdTRGPos
end


local last_cmd=""
while true do

    _,_,r_addr,_,dist,msg,x,y,z = computer.pullSignal(0.5)
    term.clear()
    if tasks[msg] then
      tasks[msg](r_addr,x,y,z,dist)
    elseif msg then
      last_cmd = msg
    end
    print("gpsSats:")
    for addr,c in pairs(gpsSats) do
      print(addr,":: {",c.x,c.y,c.z,c.d,"}")
    end

    if trgPos then
      print("trgPos: {",trgPos[1],trgPos[2],trgPos[3],"}")
    else
      print("trgPos:")
    end
    
    print("cmd: ",last_cmd)
    local current_pos
    if length(gpsSats)>=3 then
      --current_pos = locate()
		current_pos = getGPSlocation()
    end
    if current_pos then print("current_pos: ",current_pos[1],current_pos[2],current_pos[3])
    else print("current_pos:") end

	refreshGPSTable()
end
