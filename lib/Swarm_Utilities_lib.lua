local utilities = {}

function math.trunc(v)
    local t = math.modf(v)
	return t
end
function utilities.vec_trunc(A)
	if A then
		return {math.trunc(A[1]),math.trunc(A[2]),math.trunc(A[3])}
	end
	return nil
end
function utilities.add_vec(A,B)
	if A and B then
		return {A[1]+B[1],A[2]+B[2],A[3]+B[3]}
	end
	return nil
end
return utilities
