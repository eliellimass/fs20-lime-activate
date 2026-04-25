SplineVehicle = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function SplineVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getFrontToBackDistance", SplineVehicle.getFrontToBackDistance)
	SpecializationUtil.registerFunction(vehicleType, "getSplineTimeFromDistance", SplineVehicle.getSplineTimeFromDistance)
	SpecializationUtil.registerFunction(vehicleType, "getSplinePositionAndTimeFromDistance", SplineVehicle.getSplinePositionAndTimeFromDistance)
	SpecializationUtil.registerFunction(vehicleType, "alignToSplineTime", SplineVehicle.alignToSplineTime)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSplinePosition", SplineVehicle.getCurrentSplinePosition)
end

function SplineVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getLastSpeed", SplineVehicle.getLastSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTrainSystem", SplineVehicle.setTrainSystem)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentSurfaceSound", SplineVehicle.getCurrentSurfaceSound)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreSurfaceSoundsActive", SplineVehicle.getAreSurfaceSoundsActive)
end

function SplineVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SplineVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SplineVehicle)
end

function SplineVehicle:onLoad(savegame)
	local spec = self.spec_splineVehicle
	spec.frontNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.splineVehicle.dollies#frontNode"), self.i3dMappings)
	spec.backNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.splineVehicle.dollies#backNode"), self.i3dMappings)
	spec.frontToBackDistance = calcDistanceFrom(spec.frontNode, spec.backNode)
	spec.dolly1Node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.splineVehicle.dollies#dolly1Node"), self.i3dMappings)
	spec.dolly2Node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.splineVehicle.dollies#dolly2Node"), self.i3dMappings)
	spec.dollyToDollyDistance = calcDistanceFrom(spec.dolly1Node, spec.dolly2Node)
	spec.rootNodeToBackDistance = calcDistanceFrom(spec.backNode, self.rootNode)
	spec.rootNodeToFrontDistance = calcDistanceFrom(spec.frontNode, self.rootNode)
	spec.alignDollys = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.splineVehicle.dollies#alignDollys"), true)
	spec.splinePosition = 0
	spec.lastSplinePosition = 0
	spec.currentSplinePosition = 0
	spec.lastSplinePositionDelta = 0
	spec.lastSplinePositionSpeed = 0
	spec.splinePositionSpeedReal = 0
	spec.splinePositionSpeed = 0
	spec.splinePositionAcceleration = 0
	spec.splineSpeed = 0
	spec.firstUpdate = true
end

function SplineVehicle:setTrainSystem(superFunc, trainSystem)
	superFunc(self, trainSystem)

	local spec = self.spec_splineVehicle
	spec.splineLength = trainSystem:getSplineLength()
	spec.frontToBackSplineTime = spec.frontToBackDistance / spec.splineLength
	spec.dollyToDollySplineTime = spec.dollyToDollyDistance / spec.splineLength
	spec.rootNodeToBackSplineTime = spec.rootNodeToBackDistance / spec.splineLength
	spec.rootNodeToFrontSplineTime = spec.rootNodeToFrontDistance / spec.splineLength
end

function SplineVehicle:getCurrentSplinePosition()
	return self.spec_splineVehicle.splinePosition
end

function SplineVehicle:getFrontToBackDistance()
	return self.spec_splineVehicle.frontToBackDistance
end

function SplineVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_splineVehicle

	if spec.trainSystem ~= nil then
		local interpDt = g_physicsDt

		if g_server == nil then
			interpDt = g_physicsDtUnclamped
		end

		spec.lastSplinePositionSpeed = spec.splinePositionSpeedReal
		spec.splinePositionSpeedReal = 0.9 * spec.splinePositionSpeedReal + 0.1 * spec.lastSplinePositionDelta * spec.trainSystem.splineLength * 1000 / interpDt
		spec.splinePositionSpeed = spec.splinePositionSpeed * 0.95 + spec.splinePositionSpeedReal * 0.05
		spec.splinePositionAcceleration = (spec.splinePositionSpeedReal - spec.lastSplinePositionSpeed) * 1000 / interpDt
	end
end

function SplineVehicle:getSplineTimeFromDistance(t, distance, stepSize)
	if self.trainSystem == nil then
		return
	end

	local positiveTimeOffset = stepSize >= 0
	local x, y, z, t2 = getSplinePositionWithDistance(self.trainSystem.spline, t, distance, positiveTimeOffset, 0.01)

	return SplineUtil.getValidSplineTime(t2)
end

function SplineVehicle:getSplinePositionAndTimeFromDistance(t, distance, stepSize)
	if self.trainSystem == nil then
		return
	end

	local positiveTimeOffset = stepSize >= 0
	local x, y, z, t2 = getSplinePositionWithDistance(self.trainSystem.spline, t, distance, positiveTimeOffset, 0.01)

	return x, y, z, SplineUtil.getValidSplineTime(t2)
end

function SplineVehicle:alignToSplineTime(spline, yOffset, tFront)
	if self.trainSystem == nil then
		return
	end

	local spec = self.spec_splineVehicle
	local maxDiff = math.max(self.trainSystem.trainLengthSplineTime, 0.25)
	local delta = tFront - spec.splinePosition

	if maxDiff < math.abs(delta) then
		if delta > 0 then
			delta = delta - 1
		else
			delta = delta + 1
		end
	end

	self.movingDirection = 1

	if delta < 0 then
		self.movingDirection = -1
	end

	local p1x, p1y, p1z, t = self:getSplinePositionAndTimeFromDistance(tFront, spec.rootNodeToFrontDistance, -1.2 * spec.rootNodeToFrontSplineTime)
	local wp1x, wp1y, wp1z = localToWorld(getParent(spline), p1x, p1y, p1z)
	local p2x, p2y, p2z, t2 = self:getSplinePositionAndTimeFromDistance(t, spec.dollyToDollyDistance, -1.2 * spec.dollyToDollySplineTime)
	local wp2x, wp2y, wp2z = localToWorld(getParent(spline), p2x, p2y, p2z)

	setDirection(self.rootNode, wp1x - wp2x, wp1y - wp2y, wp1z - wp2z, 0, 1, 0)

	local qx, qy, qz, qw = getWorldQuaternion(self.rootNode)

	self:setWorldPositionQuaternion(wp1x, wp1y + yOffset, wp1z, qx, qy, qz, qw, 1, true)

	if spec.alignDollys then
		local d1x, d1y, d1z = getSplineDirection(spline, t)
		local d2x, d2y, d2z = getSplineDirection(spline, t2)
		d1x, d1y, d1z = localDirectionToLocal(spline, getParent(spec.dolly1Node), d1x, d1y, d1z)
		d2x, d2y, d2z = localDirectionToLocal(spline, getParent(spec.dolly2Node), d2x, d2y, d2z)

		setDirection(spec.dolly1Node, d1x, d1y, d1z, 0, 1, 0)
		setDirection(spec.dolly2Node, d2x, d2y, d2z, 0, 1, 0)
	end

	spec.lastSplinePositionDelta = delta
	spec.splinePosition = tFront

	if spec.firstUpdate then
		spec.lastSplinePositionDelta = 0
		spec.firstUpdate = false
	end

	local tBack = self:getSplineTimeFromDistance(tFront, spec.frontToBackDistance, -1.2 * spec.frontToBackSplineTime)

	return tBack
end

function SplineVehicle:getLastSpeed(superFunc, useAttacherVehicleSpeed)
	return math.abs(self.spec_splineVehicle.splinePositionSpeedReal * 3.6)
end

function SplineVehicle:getCurrentSurfaceSound()
	return self.spec_wheels.surfaceNameToSound.railroad
end

function SplineVehicle:getAreSurfaceSoundsActive(superFunc)
	local rootVehicle = self:getRootVehicle()

	if rootVehicle ~= nil then
		return rootVehicle:getAreSurfaceSoundsActive()
	end

	return true
end
