SplineUtil = {
	getValidSplineTime = function (t)
		return t % 1
	end
}

function SplineUtil.getSplineTimeAtWorldPos(spline, t, posX, posZ, checkDistance, maxSteps)
	local splineLength = getSplineLength(spline)
	local currentCheckDistance = checkDistance / splineLength
	local stepCounter = 0

	while true do
		local t1 = SplineUtil.getValidSplineTime(t + currentCheckDistance)
		local t2 = SplineUtil.getValidSplineTime(t - currentCheckDistance)
		local fX, _, fZ = getSplinePosition(spline, t1)
		local bX, _, bZ = getSplinePosition(spline, t2)
		local fDistance = MathUtil.vector2LengthSq(posX - fX, posZ - fZ)
		local bDistance = MathUtil.vector2LengthSq(posX - bX, posZ - bZ)
		currentCheckDistance = currentCheckDistance * 0.5
		local currentDistance = fDistance

		if fDistance < bDistance then
			t = SplineUtil.getValidSplineTime(t + currentCheckDistance)
		else
			currentDistance = bDistance
			t = SplineUtil.getValidSplineTime(t - currentCheckDistance)
		end

		if maxSteps < stepCounter then
			break
		end

		stepCounter = stepCounter + 1
	end

	return t, stepCounter
end
