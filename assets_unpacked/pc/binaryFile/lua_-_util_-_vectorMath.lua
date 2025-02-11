local VectorMath = {}

VectorMath.__index = VectorMath

function VectorMath.getTilesInRectangle(pos1,pos2)
	local x1 = math.min(pos1.x,pos2.x)
	local x2 = math.max(pos1.x,pos2.x)
	local y1 = math.min(pos1.y,pos2.y)
	local y2 = math.max(pos1.y,pos2.y)

	local result = {}
	for x = x1, x2 do
		for y = y1, y2 do
			table.insert(result, {x=x, y=y})
		end
	end
	return result
end

function VectorMath.crossProduct(A,B)
	return A.x*B.y-B.x*A.y
end

function VectorMath.triangleArea(A, B, C)
	local AB = {x=B.x-A.x, y=B.y-A.y}
	local AC = {x=C.x-A.x, y=C.y-A.y}
	local area = math.abs(VectorMath.crossProduct(AB,AC)/2)
	--print("\t\t\t\t\ttriangleArea: "..tostring(area))
	return area
end
function VectorMath.dotProduct(A,B)
	--print("\t\t\tdotProduct")
	--print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	--print("\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	local result = A.x*B.x+A.y*B.y
	--print("\t\t\tresult: "..tostring(result))
	return result
end

function VectorMath.rotate90(A)
	return {x = -A.y, y = A.x}
end

function VectorMath.vectorLength(A)
	--print("\t\t\tvectorLength")
	--print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	local result = math.sqrt(VectorMath.dotProduct(A,A))
	--print("\t\t\tresult: "..tostring(result))
	return result
end

function VectorMath.dist(A,B)
	local AB = VectorMath.diff(A,B)
	local result = VectorMath.vectorLength(AB)
	return result
end

function VectorMath.add(A,B)
	return {x=A.x+B.x,y=A.y+B.y}
end
function VectorMath.diff(A,B)
	return {x=A.x-B.x,y=A.y-B.y}
end
function VectorMath.scale(A,b)
	return {x=A.x*b,y=A.y*b}
end
function VectorMath.projection(A,B)
	--print("\t\t\tvectorProjection")
	--print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	--print("\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	local scala = VectorMath.dotProduct(A,B)/VectorMath.dotProduct(B,B)
	--print("\t\t\tscala: "..tostring(scala))
	local result = {x=B.x*scala, y=B.y*scala}
	--print("\t\t\tresult: "..tostring(result.x)..", "..tostring(result.y))
	return result
end

function VectorMath.projectionLength(A,B)
	-- print("\t\t\tvectorProjectionLength")
	-- print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	-- print("\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	local result = VectorMath.dotProduct(A,B)/VectorMath.length(B)
	-- print("\t\t\tresult: "..tostring(result))
	return result
end

return VectorMath
