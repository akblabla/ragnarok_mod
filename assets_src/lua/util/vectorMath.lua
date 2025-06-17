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
	return area
end
function VectorMath.dotProduct(A,B)
	local result = A.x*B.x+A.y*B.y
	return result
end

function VectorMath.rotate90(A)
	return {x = -A.y, y = A.x}
end

function VectorMath.vectorLength(A)
	local result = math.sqrt(VectorMath.dotProduct(A,A))
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
	local scala = VectorMath.dotProduct(A,B)/VectorMath.dotProduct(B,B)
	local result = {x=B.x*scala, y=B.y*scala}
	return result
end

function VectorMath.projectionLength(A,B)
	local result = VectorMath.dotProduct(A,B)/VectorMath.length(B)
	return result
end

return VectorMath
