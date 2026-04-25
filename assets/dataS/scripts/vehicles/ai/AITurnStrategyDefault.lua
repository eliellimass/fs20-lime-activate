AITurnStrategyDefault = {}
local AITurnStrategyDefault_mt = Class(AITurnStrategyDefault, AITurnStrategy)

function AITurnStrategyDefault:new(customMt)
	if customMt == nil then
		customMt = AITurnStrategyDefault_mt
	end

	local self = AITurnStrategy:new(customMt)
	self.strategyName = "AITurnStrategyDefault"

	return self
end

function AITurnStrategyDefault:delete()
end

function AITurnStrategyDefault:startTurn(driveStrategyStraight)
	if not AITurnStrategyDefault:superClass().startTurn(self, driveStrategyStraight) then
		return false
	end

	local turnData = driveStrategyStraight.turnData
	local sideOffset = nil

	if self.turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = turnData.radius
	else
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = -turnData.radius
	end

	local c2X, c2Y, c2Z = nil
	local a = 2 * math.abs(sideOffset)
	local b = math.sqrt(2 * turnData.radius * 2 * turnData.radius - a * a)

	if sideOffset >= 0 then
		c2Z = b + turnData.zOffsetTurn
		c2Y = 0
		c2X = turnData.radius + a
	else
		c2Z = b + turnData.zOffsetTurn
		c2Y = 0
		c2X = -turnData.radius - a
	end

	local alpha = math.acos(a / (2 * turnData.radius))
	local c4X, c4Y, c4Z = nil

	if sideOffset >= 0 then
		c4Z = turnData.zOffsetTurn
		c4Y = 0
		c4X = turnData.radius + a
	else
		c4Z = turnData.zOffsetTurn
		c4Y = 0
		c4X = -turnData.radius - a
	end

	local c3X, c3Y, c3Z = nil
	c3Z = c4Z + (c2Z - c4Z) / 2
	c3Y = 0
	local b = math.sqrt(2 * turnData.radius * 2 * turnData.radius - b / 2 * b / 2)

	if sideOffset >= 0 then
		c3X = c2X - b
	else
		c3X = c2X + b
	end

	local beta = math.acos(b / (2 * turnData.radius))
	local rvX, rvY, rvZ = getWorldRotation(self.vehicle:getAIVehicleDirectionNode(), 0, 0, 0)

	self:addNoFullCoverageSegment(self.turnSegments)

	if turnData.zOffsetTurn > 0 then
		local segment = {
			isCurve = false,
			moveForward = true,
			slowDown = true,
			startPoint = self:getVehicleToWorld(0, 0, 0, true),
			endPoint = self:getVehicleToWorld(0, 0, turnData.zOffsetTurn, true)
		}

		table.insert(self.turnSegments, segment)
	end

	local segment = {
		isCurve = true,
		moveForward = true,
		slowDown = true,
		usePredictionToSkipToNextSegment = false,
		radius = turnData.radius,
		o = createTransformGroup("segment1")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c1X, c1Y, c1Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180)
		segment.endAngle = alpha
	else
		segment.startAngle = math.rad(0)
		segment.endAngle = math.rad(180) - alpha
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = false,
		slowDown = true,
		usePredictionToSkipToNextSegment = false,
		radius = turnData.radius,
		o = createTransformGroup("segment2")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c2X, c2Y, c2Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180) + alpha
		segment.endAngle = math.rad(180) + beta
	else
		segment.startAngle = -alpha
		segment.endAngle = -beta
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		slowDown = true,
		radius = turnData.radius,
		o = createTransformGroup("segment3")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c3X, c3Y, c3Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = beta
		segment.endAngle = -beta
	else
		segment.startAngle = math.pi - beta
		segment.endAngle = math.pi + beta
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		slowDown = true,
		radius = turnData.radius,
		o = createTransformGroup("segment4")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c4X, c4Y, c4Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.pi - beta
		segment.endAngle = math.pi
	else
		segment.startAngle = beta
		segment.endAngle = 0
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = false
	}
	local zTarget = math.min(c4Z - 0.05, turnData.zOffset)
	segment.moveForward = zTarget < c4Z
	segment.slowDown = true
	local x = 2 * sideOffset
	segment.startPoint = self:getVehicleToWorld(x, 0, c4Z, true)
	segment.endPoint = self:getVehicleToWorld(x, 0, zTarget, true)

	table.insert(self.turnSegments, segment)
	self:startTurnFinalization()

	return true
end

function AITurnStrategyDefault:updateTurningSizeBox(box, turnLeft, turnData, lookAheadDistance)
	local sideOffset = nil

	if turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = turnData.radius
	else
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = -turnData.radius
	end

	local a = 2 * math.abs(sideOffset)
	local b = math.sqrt(2 * turnData.radius * 2 * turnData.radius - a * a)
	local c2X, c2Y, c2Z = nil

	if sideOffset >= 0 then
		c2Z = b + turnData.zOffsetTurn
		c2Y = 0
		c2X = turnData.radius + a
	else
		c2Z = b + turnData.zOffsetTurn
		c2Y = 0
		c2X = -turnData.radius - a
	end

	local alpha = math.acos(a / (2 * turnData.radius))
	local c4Z = nil

	if sideOffset >= 0 then
		c4Z = turnData.zOffsetTurn
	else
		c4Z = turnData.zOffsetTurn
	end

	local b = math.sqrt(2 * turnData.radius * 2 * turnData.radius - b / 2 * b / 2)
	local beta = math.acos(b / (2 * turnData.radius))
	local maxX, minX = nil

	if sideOffset >= 0 then
		maxX = c1X + math.cos(alpha) * turnData.radius + turnData.toolOverhang.front.zt
		minX = math.min(-turnData.toolOverhang.front.xt, -turnData.toolOverhang.back.xt)

		if not turnData.allToolsAtFront then
			minX = math.min(minX, c1X - turnData.toolOverhang.back.xb)
		end
	else
		minX = c1X - math.cos(alpha) * turnData.radius - turnData.toolOverhang.front.zt
		maxX = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)

		if not turnData.allToolsAtFront then
			maxX = math.max(maxX, c1X + turnData.toolOverhang.back.xb)
		end
	end

	local maxZ = nil
	maxZ = math.max(c1Z + math.max(turnData.toolOverhang.front.zb, turnData.toolOverhang.back.zb), c2Z - math.sin(beta) * turnData.radius + turnData.toolOverhang.back.zt)
	box.center[3] = maxZ / 2 + lookAheadDistance / 2
	box.center[2] = 0
	box.center[1] = maxX - (maxX - minX) / 2
	box.size[3] = maxZ / 2 + lookAheadDistance / 2
	box.size[2] = 5
	box.size[1] = (maxX - minX) / 2

	self:adjustHeightOfTurningSizeBox(box)
end
