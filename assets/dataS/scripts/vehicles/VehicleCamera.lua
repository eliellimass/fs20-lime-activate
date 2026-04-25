VehicleCamera = {}
local VehicleCamera_mt = Class(VehicleCamera)
VehicleCamera.doCameraSmoothing = false

function VehicleCamera:new(vehicle, customMt)
	local instance = {}

	if customMt ~= nil then
		setmetatable(instance, customMt)
	else
		setmetatable(instance, VehicleCamera_mt)
	end

	instance.vehicle = vehicle
	instance.isActivated = false
	instance.limitRotXDelta = 0
	instance.raycastDistance = 0
	instance.normalX = 0
	instance.normalY = 0
	instance.normalZ = 0
	instance.raycastNodes = {}
	instance.disableCollisionTime = -1
	instance.lookAtPosition = {
		0,
		0,
		0
	}
	instance.lookAtLastTargetPosition = {
		0,
		0,
		0
	}
	instance.position = {
		0,
		0,
		0
	}
	instance.lastTargetPosition = {
		0,
		0,
		0
	}
	instance.upVector = {
		0,
		0,
		0
	}
	instance.lastUpVector = {
		0,
		0,
		0
	}
	instance.lastInputValues = {
		upDown = 0,
		leftRight = 0
	}
	instance.isCollisionEnabled = not g_modIsLoaded.FS19_disableVehicleCameraCollision

	return instance
end

function VehicleCamera:loadFromXML(xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.vehicle.configFileName, key .. "#index", "#node")

	local camIndexStr = getXMLString(xmlFile, key .. "#node")
	self.cameraNode = I3DUtil.indexToObject(self.vehicle.components, camIndexStr, self.vehicle.i3dMappings)

	if self.cameraNode == nil or not getHasClassId(self.cameraNode, ClassIds.CAMERA) then
		g_logManager:xmlWarning(self.vehicle.configFileName, "Invalid camera node for camera '%s'. Must be a camera type!", key)

		return false
	end

	self.fovY = calculateFovY(self.cameraNode)

	setFovY(self.cameraNode, self.fovY)

	self.isRotatable = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rotatable"), false)
	self.limit = Utils.getNoNil(getXMLBool(xmlFile, key .. "#limit"), false)

	if self.limit then
		self.rotMinX = getXMLFloat(xmlFile, key .. "#rotMinX")
		self.rotMaxX = getXMLFloat(xmlFile, key .. "#rotMaxX")
		self.transMin = getXMLFloat(xmlFile, key .. "#transMin")
		self.transMax = getXMLFloat(xmlFile, key .. "#transMax")

		if self.transMax ~= nil then
			self.transMax = math.max(self.transMin, self.transMax * g_platformSettingsManager:getSetting("maxCameraZoomFactor", 1))
		end

		if self.rotMinX == nil or self.rotMaxX == nil or self.transMin == nil or self.transMax == nil then
			g_logManager:xmlWarning(self.vehicle.configFileName, "Missing 'rotMinX', 'rotMaxX', 'transMin' or 'transMax' for camera '%s'", key)

			return false
		end
	end

	self.isInside = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isInside"), false)

	if self.isInside then
		self.defaultLowPassGain = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#defaultLowPassGain"), 0.5)
		self.defaultVolume = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#defaultVolume"), 0.9)
	else
		self.defaultLowPassGain = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#defaultLowPassGain"), 1)
		self.defaultVolume = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#defaultVolume"), 1)
	end

	self.allowHeadTracking = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowHeadTracking"), self.isInside)
	local shadowBoxIndexStr = getXMLString(xmlFile, key .. "#shadowFocusBox")
	self.shadowFocusBoxNode = I3DUtil.indexToObject(self.vehicle.components, shadowBoxIndexStr, self.vehicle.i3dMappings)

	if self.shadowFocusBoxNode ~= nil and not getHasClassId(self.shadowFocusBoxNode, ClassIds.SHAPE) then
		g_logManager:xmlWarning(self.vehicle.configFileName, "Invalid camera shadow focus box '%s'. Must be a shape and cpu mesh", getName(shadowFocusBoxNode))

		self.shadowFocusBoxNode = nil
	end

	if self.isInside and self.shadowFocusBoxNode == nil then
		g_logManager:xmlDevWarning(self.vehicle.configFileName, "Missing shadow focus box for indoor camera '%s'", key)
	end

	self.useOutdoorSounds = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useOutdoorSounds"), not self.isInside)

	if self.isRotatable then
		self.rotateNode = I3DUtil.indexToObject(self.vehicle.components, getXMLString(xmlFile, key .. "#rotateNode"), self.vehicle.i3dMappings)
		self.hasExtraRotationNode = self.rotateNode ~= nil
	end

	local rotation = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#rotation"), 3)

	if rotation ~= nil then
		local rotationNode = self.cameraNode

		if self.rotateNode ~= nil then
			rotationNode = self.rotateNode
		end

		setRotation(rotationNode, unpack(rotation))
	end

	local translation = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#translation"), 3)

	if translation ~= nil then
		setTranslation(self.cameraNode, unpack(translation))
	end

	self.allowTranslation = self.rotateNode ~= nil and self.rotateNode ~= self.cameraNode
	self.useMirror = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useMirror"), false)
	self.useWorldXZRotation = getXMLBool(xmlFile, key .. "#useWorldXZRotation")
	self.resetCameraOnVehicleSwitch = getXMLBool(xmlFile, key .. "#resetCameraOnVehicleSwitch")

	if not g_platformSettingsManager:getSetting("useWorldCameraInside", true) and self.isInside or not g_platformSettingsManager:getSetting("useWorldCameraOutside", true) and not self.isInside then
		self.useWorldXZRotation = false
	end

	self.positionSmoothingParameter = 0
	self.lookAtSmoothingParameter = 0
	local useDefaultPositionSmoothing = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useDefaultPositionSmoothing"), true)

	if useDefaultPositionSmoothing then
		if self.isInside then
			self.positionSmoothingParameter = 0.128
			self.lookAtSmoothingParameter = 0.176
		else
			self.positionSmoothingParameter = 0.016
			self.lookAtSmoothingParameter = 0.022
		end
	end

	self.positionSmoothingParameter = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#positionSmoothingParameter"), self.positionSmoothingParameter)
	self.lookAtSmoothingParameter = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#lookAtSmoothingParameter"), self.lookAtSmoothingParameter)
	local useHeadTracking = g_gameSettings:getValue("isHeadTrackingEnabled") and isHeadTrackingAvailable() and self.allowHeadTracking

	if useHeadTracking then
		self.positionSmoothingParameter = 0
		self.lookAtSmoothingParameter = 0
	end

	self.cameraPositionNode = self.cameraNode

	if self.positionSmoothingParameter > 0 then
		self.cameraPositionNode = createTransformGroup("cameraPositionNode")
		local camIndex = getChildIndex(self.cameraNode)

		link(getParent(self.cameraNode), self.cameraPositionNode, camIndex)

		local x, y, z = getTranslation(self.cameraNode)
		local rx, ry, rz = getRotation(self.cameraNode)

		setTranslation(self.cameraPositionNode, x, y, z)
		setRotation(self.cameraPositionNode, rx, ry, rz)
		unlink(self.cameraNode)
	end

	self.rotYSteeringRotSpeed = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#rotYSteeringRotSpeed"), 0))

	if self.rotateNode == nil or self.rotateNode == self.cameraNode then
		self.rotateNode = self.cameraPositionNode
	end

	if useHeadTracking then
		local dx, _, dz = localDirectionToLocal(self.cameraPositionNode, getParent(self.cameraPositionNode), 0, 0, 1)
		local tx, ty, tz = localToLocal(self.cameraPositionNode, getParent(self.cameraPositionNode), 0, 0, 0)
		self.headTrackingNode = createTransformGroup("headTrackingNode")

		link(getParent(self.cameraPositionNode), self.headTrackingNode)
		setTranslation(self.headTrackingNode, tx, ty, tz)

		if math.abs(dx) + math.abs(dz) > 0.0001 then
			setDirection(self.headTrackingNode, dx, 0, dz, 0, 1, 0)
		else
			setRotation(self.headTrackingNode, 0, 0, 0)
		end
	end

	self.origRotX, self.origRotY, self.origRotZ = getRotation(self.rotateNode)
	self.rotX = self.origRotX
	self.rotY = self.origRotY
	self.rotZ = self.origRotZ
	self.origTransX, self.origTransY, self.origTransZ = getTranslation(self.cameraPositionNode)
	self.transX = self.origTransX
	self.transY = self.origTransY
	self.transZ = self.origTransZ
	local transLength = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ) + 1e-05
	self.zoom = transLength
	self.zoomTarget = transLength
	self.zoomLimitedTarget = -1
	local trans1OverLength = 1 / transLength
	self.transDirX = trans1OverLength * self.origTransX
	self.transDirY = trans1OverLength * self.origTransY
	self.transDirZ = trans1OverLength * self.origTransZ

	if self.allowTranslation and transLength <= 0.01 then
		g_logManager:xmlWarning(self.vehicle.configFileName, "Invalid camera translation for camera '%s'. Distance needs to be bigger than 0.01", key)
	end

	table.insert(self.raycastNodes, self.rotateNode)

	local i = 0

	while true do
		local raycastKey = key .. string.format(".raycastNode(%d)", i)

		if not hasXMLProperty(xmlFile, raycastKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.vehicle.configFileName, raycastKey .. "#index", raycastKey .. "#node")

		local node = I3DUtil.indexToObject(self.vehicle.components, getXMLString(xmlFile, raycastKey .. "#node"), self.vehicle.i3dMappings)

		if node ~= nil then
			table.insert(self.raycastNodes, node)
		end

		i = i + 1
	end

	local sx, sy, sz = getScale(self.cameraNode)

	if sx ~= 1 or sy ~= 1 or sz ~= 1 then
		g_logManager:xmlWarning(self.vehicle.configFileName, "Vehicle camera with scale found for camera '%s'. Resetting to scale 1", key)
		setScale(self.cameraNode, 1, 1, 1)
	end

	self.headTrackingPositionOffset = {
		0,
		0,
		0
	}
	self.headTrackingRotationOffset = {
		0,
		0,
		0
	}
	self.changeObjects = {}

	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, self.changeObjects, self.vehicle.components, self.vehicle)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.vehicle, self.vehicle.setMovingToolDirty)

	return true
end

function VehicleCamera:delete()
	if self.cameraNode ~= nil and self.positionSmoothingParameter > 0 then
		delete(self.cameraNode)

		self.cameraNode = nil
	end

	setShadowFocusBox(0)
end

function VehicleCamera:zoomSmoothly(offset)
	local zoomTarget = self.zoomTarget

	if self.transMin ~= nil and self.transMax ~= nil and self.transMin ~= self.transMax then
		zoomTarget = math.min(self.transMax, math.max(self.transMin, self.zoomTarget + offset))
	end

	self.zoomTarget = zoomTarget
end

function VehicleCamera:raycastCallback(transformId, x, y, z, distance, nx, ny, nz)
	self.raycastDistance = distance
	self.normalX = nx
	self.normalY = ny
	self.normalZ = nz
	self.raycastTransformId = transformId
end

function VehicleCamera:update(dt)
	local target = self.zoomTarget

	if self.zoomLimitedTarget >= 0 then
		target = math.min(self.zoomLimitedTarget, self.zoomTarget)
	end

	self.zoom = target + math.pow(0.99579, dt) * (self.zoom - target)

	if self.lastInputValues.upDown ~= 0 then
		local value = self.lastInputValues.upDown * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		self.lastInputValues.upDown = 0

		if g_gameSettings:getValue("invertYLook") then
			value = -value or value
		end

		if self.isRotatable and self.isActivated and not g_gui:getIsGuiVisible() then
			if self.limitRotXDelta > 0.001 then
				self.rotX = math.min(self.rotX - value, self.rotX)
			elseif self.limitRotXDelta < -0.001 then
				self.rotX = math.max(self.rotX - value, self.rotX)
			else
				self.rotX = self.rotX - value
			end

			if self.limit then
				self.rotX = math.min(self.rotMaxX, math.max(self.rotMinX, self.rotX))
			end
		end
	end

	if self.lastInputValues.leftRight ~= 0 then
		local value = self.lastInputValues.leftRight * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		self.lastInputValues.leftRight = 0

		if self.isRotatable and self.isActivated and not g_gui:getIsGuiVisible() then
			self.rotY = self.rotY - value
		end
	end

	if g_gameSettings:getValue("isHeadTrackingEnabled") and isHeadTrackingAvailable() and self.allowHeadTracking and self.headTrackingNode ~= nil then
		local tx, ty, tz = getHeadTrackingTranslation()
		local pitch, yaw, roll = getHeadTrackingRotation()

		if pitch ~= nil then
			local camParent = getParent(self.cameraNode)
			local ctx, cty, ctz, crx, cry, crz = nil

			if camParent ~= 0 then
				ctx, cty, ctz = localToLocal(self.headTrackingNode, camParent, tx, ty, tz)
				crx, cry, crz = localRotationToLocal(self.headTrackingNode, camParent, pitch, yaw, roll)
			else
				ctx, cty, ctz = localToWorld(self.headTrackingNode, tx, ty, tz)
				crx, cry, crz = localRotationToWorld(self.headTrackingNode, pitch, yaw, roll)
			end

			setRotation(self.cameraNode, crx, cry, crz)
			setTranslation(self.cameraNode, ctx, cty, ctz)
		end
	else
		self:updateRotateNodeRotation()

		if self.limit then
			if self.isRotatable and (self.useWorldXZRotation == nil and g_gameSettings:getValue("useWorldCamera") or self.useWorldXZRotation) then
				local numIterations = 4

				for i = 1, numIterations do
					local transX = self.transDirX * self.zoom
					local transY = self.transDirY * self.zoom
					local transZ = self.transDirZ * self.zoom
					local x, y, z = localToWorld(getParent(self.cameraPositionNode), transX, transY, transZ)
					local terrainHeight = DensityMapHeightUtil.getHeightAtWorldPos(x, 0, z)
					local minHeight = terrainHeight + 0.9

					if y < minHeight then
						local h = math.sin(self.rotX) * self.zoom
						local h2 = h - (minHeight - y)
						self.rotX = math.asin(MathUtil.clamp(h2 / self.zoom, -1, 1))

						self:updateRotateNodeRotation()
					else
						break
					end
				end
			end

			if self.allowTranslation then
				self.limitRotXDelta = 0
				local hasCollision, collisionDistance, nx, ny, nz, normalDotDir = self:getCollisionDistance()

				if hasCollision then
					local distOffset = 0.1

					if normalDotDir ~= nil then
						local absNormalDotDir = math.abs(normalDotDir)
						distOffset = MathUtil.lerp(1.2, 0.1, absNormalDotDir * absNormalDotDir * (3 - 2 * absNormalDotDir))
					end

					collisionDistance = math.max(collisionDistance - distOffset, 0.01)
					self.disableCollisionTime = g_currentMission.time + 400
					self.zoomLimitedTarget = collisionDistance

					if collisionDistance < self.zoom then
						self.zoom = collisionDistance
					end

					if self.isRotatable and nx ~= nil and collisionDistance < self.transMin then
						local _, lny, _ = worldDirectionToLocal(self.rotateNode, nx, ny, nz)

						if lny > 0.5 then
							self.limitRotXDelta = 1
						elseif lny < -0.5 then
							self.limitRotXDelta = -1
						end
					end
				elseif self.disableCollisionTime <= g_currentMission.time then
					self.zoomLimitedTarget = -1
				end
			end
		end

		self.transZ = self.transDirZ * self.zoom
		self.transY = self.transDirY * self.zoom
		self.transX = self.transDirX * self.zoom

		setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)

		if self.positionSmoothingParameter > 0 then
			local interpDt = g_physicsDt

			if self.vehicle.spec_rideable ~= nil then
				interpDt = self.vehicle.spec_rideable.interpolationDt
			end

			if g_server == nil then
				interpDt = dt
			end

			if interpDt > 0 then
				local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
				local lookAtPos = self.lookAtPosition
				local lookAtLastPos = self.lookAtLastTargetPosition
				lookAtPos[1], lookAtPos[2], lookAtPos[3] = self:getSmoothed(self.lookAtSmoothingParameter, lookAtPos[1], lookAtPos[2], lookAtPos[3], xlook, ylook, zlook, lookAtLastPos[1], lookAtLastPos[2], lookAtLastPos[3], interpDt)
				lookAtLastPos[3] = zlook
				lookAtLastPos[2] = ylook
				lookAtLastPos[1] = xlook
				local x, y, z = getWorldTranslation(self.cameraPositionNode)
				local pos = self.position
				local lastPos = self.lastTargetPosition
				pos[1], pos[2], pos[3] = self:getSmoothed(self.positionSmoothingParameter, pos[1], pos[2], pos[3], x, y, z, lastPos[1], lastPos[2], lastPos[3], interpDt)
				lastPos[3] = z
				lastPos[2] = y
				lastPos[1] = x
				local upx, upy, upz = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
				local up = self.upVector
				local lastUp = self.lastUpVector
				up[1], up[2], up[3] = self:getSmoothed(self.positionSmoothingParameter, up[1], up[2], up[3], upx, upy, upz, lastUp[1], lastUp[2], lastUp[3], interpDt)
				lastUp[3] = upz
				lastUp[2] = upy
				lastUp[1] = upx

				self:setSeparateCameraPose()
			end
		end
	end
end

function VehicleCamera:getSmoothed(alpha, curX, curY, curZ, targetX, targetY, targetZ, lastTargetX, lastTargetY, lastTargetZ, dt)
	local dtLooped = math.max(math.floor(dt - 6), 0)
	local dtDirect = dt - dtLooped
	local invDt = 1 / dt
	local velX = (targetX - lastTargetX) * invDt
	local velY = (targetY - lastTargetY) * invDt
	local velZ = (targetZ - lastTargetZ) * invDt
	local velScale = math.pow(1 - alpha, 1 + dtDirect) + (1 + dtDirect) * alpha - 1
	local posScale = math.pow(1 - alpha, dtDirect)
	local newX = (velScale * velX + alpha * (posScale * (curX - lastTargetX) + lastTargetX)) / alpha
	local newY = (velScale * velY + alpha * (posScale * (curY - lastTargetY) + lastTargetY)) / alpha
	local newZ = (velScale * velZ + alpha * (posScale * (curZ - lastTargetZ) + lastTargetZ)) / alpha

	for i = 1, dtLooped do
		newX = newX + (lastTargetX + velX * (i + dtDirect) - newX) * alpha
		newY = newY + (lastTargetY + velY * (i + dtDirect) - newY) * alpha
		newZ = newZ + (lastTargetZ + velZ * (i + dtDirect) - newZ) * alpha
	end

	return newX, newY, newZ
end

function VehicleCamera:onActivate()
	if self.cameraNode == nil then
		return
	end

	self.isActivated = true

	if self.resetCameraOnVehicleSwitch == nil and g_gameSettings:getValue("resetCamera") or self.resetCameraOnVehicleSwitch then
		self:resetCamera()
	end

	setCamera(self.cameraNode)

	if self.shadowFocusBoxNode then
		setShadowFocusBox(self.shadowFocusBoxNode)
	end

	if self.positionSmoothingParameter > 0 then
		local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
		self.lookAtPosition[1] = xlook
		self.lookAtPosition[2] = ylook
		self.lookAtPosition[3] = zlook
		self.lookAtLastTargetPosition[1] = xlook
		self.lookAtLastTargetPosition[2] = ylook
		self.lookAtLastTargetPosition[3] = zlook
		local x, y, z = getWorldTranslation(self.cameraPositionNode)
		self.position[1] = x
		self.position[2] = y
		self.position[3] = z
		self.lastTargetPosition[1] = x
		self.lastTargetPosition[2] = y
		self.lastTargetPosition[3] = z
		local upx, upy, upz = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
		self.upVector[1] = upx
		self.upVector[2] = upy
		self.upVector[3] = upz
		self.lastUpVector[1] = upx
		self.lastUpVector[2] = upy
		self.lastUpVector[3] = upz
		local rx, ry, rz = getWorldRotation(self.rotateNode)

		setRotation(self.cameraNode, rx, ry, rz)
		setTranslation(self.cameraNode, x, y, z)
	end

	self.lastInputValues = {
		upDown = 0,
		leftRight = 0
	}
	local _, actionEventId1 = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, VehicleCamera.actionEventLookUpDown, false, false, true, true, nil)
	local _, actionEventId2 = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, VehicleCamera.actionEventLookLeftRight, false, false, true, true, nil)

	g_inputBinding:setActionEventTextVisibility(actionEventId1, false)
	g_inputBinding:setActionEventTextVisibility(actionEventId2, false)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, true, self.vehicle, self.vehicle.setMovingToolDirty)

	self.touchListenerPinch = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_PINCH, VehicleCamera.touchEventZoomInOut, self)
	self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, VehicleCamera.touchEventLookUpDown, self)
	self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, VehicleCamera.touchEventLookLeftRight, self)
end

function VehicleCamera:onDeactivate()
	self.isActivated = false

	setShadowFocusBox(0)
	g_inputBinding:removeActionEventsByTarget(self)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.vehicle, self.vehicle.setMovingToolDirty)
	g_touchHandler:removeGestureListener(self.touchListenerPinch)
	g_touchHandler:removeGestureListener(self.touchListenerY)
	g_touchHandler:removeGestureListener(self.touchListenerX)
end

function VehicleCamera:actionEventLookUpDown(actionName, inputValue, callbackState, isAnalog, isMouse)
	if isMouse then
		inputValue = inputValue * 0.001 * 16.666
	else
		inputValue = inputValue * 0.001 * g_currentDt
	end

	self.lastInputValues.upDown = self.lastInputValues.upDown + inputValue
end

function VehicleCamera:touchEventLookUpDown(value)
	if self.isActivated then
		local factor = g_screenHeight / g_screenWidth * -150

		VehicleCamera.actionEventLookUpDown(self, nil, value * factor, nil, , false)
	end
end

function VehicleCamera:touchEventZoomInOut(value)
	if self.isActivated then
		self:zoomSmoothly(value * 15)
	end
end

function VehicleCamera:touchEventLookLeftRight(value)
	if self.isActivated then
		local factor = g_screenWidth / g_screenHeight * 150

		VehicleCamera.actionEventLookLeftRight(self, nil, value * factor, nil, , false)
	end
end

function VehicleCamera:actionEventLookLeftRight(actionName, inputValue, callbackState, isAnalog, isMouse)
	if isMouse then
		inputValue = inputValue * 0.001 * 16.666
	else
		inputValue = inputValue * 0.001 * g_currentDt
	end

	self.lastInputValues.leftRight = self.lastInputValues.leftRight + inputValue
end

function VehicleCamera:resetCamera()
	self.rotX = self.origRotX
	self.rotY = self.origRotY
	self.rotZ = self.origRotZ
	self.transX = self.origTransX
	self.transY = self.origTransY
	self.transZ = self.origTransZ
	local transLength = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ)
	self.zoom = transLength
	self.zoomTarget = transLength
	self.zoomLimitedTarget = -1

	self:updateRotateNodeRotation()
	setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)

	if self.positionSmoothingParameter > 0 then
		local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
		self.lookAtPosition[1] = xlook
		self.lookAtPosition[2] = ylook
		self.lookAtPosition[3] = zlook
		local x, y, z = getWorldTranslation(self.cameraPositionNode)
		self.position[1] = x
		self.position[2] = y
		self.position[3] = z

		self:setSeparateCameraPose()
	end
end

function VehicleCamera:updateRotateNodeRotation()
	local rotY = self.rotY

	if self.rotYSteeringRotSpeed ~= nil and self.rotYSteeringRotSpeed ~= 0 and self.vehicle.spec_articulatedAxis ~= nil and self.vehicle.spec_articulatedAxis.interpolatedRotatedTime ~= nil then
		rotY = rotY + self.vehicle.spec_articulatedAxis.interpolatedRotatedTime * self.rotYSteeringRotSpeed
	end

	if self.useWorldXZRotation == nil and g_gameSettings:getValue("useWorldCamera") or self.useWorldXZRotation then
		local upx = 0
		local upy = 1
		local upz = 0
		local dx, _, dz = localDirectionToWorld(getParent(self.rotateNode), 0, 0, 1)
		local invLen = 1 / math.sqrt(dx * dx + dz * dz)
		dx = dx * invLen
		dz = dz * invLen
		local newDx = math.cos(self.rotX) * (math.cos(rotY) * dx + math.sin(rotY) * dz)
		local newDy = -math.sin(self.rotX)
		local newDz = math.cos(self.rotX) * (-math.sin(rotY) * dx + math.cos(rotY) * dz)
		newDx, newDy, newDz = worldDirectionToLocal(getParent(self.rotateNode), newDx, newDy, newDz)
		upx, upy, upz = worldDirectionToLocal(getParent(self.rotateNode), upx, upy, upz)

		if math.abs(MathUtil.dotProduct(newDx, newDy, newDz, upx, upy, upz)) > 0.99 * MathUtil.vector3Length(newDx, newDy, newDz) * MathUtil.vector3Length(upx, upy, upz) then
			setRotation(self.rotateNode, self.rotX, rotY, self.rotZ)
		else
			setDirection(self.rotateNode, newDx, newDy, newDz, upx, upy, upz)
		end
	else
		setRotation(self.rotateNode, self.rotX, rotY, self.rotZ)
	end
end

function VehicleCamera:setSeparateCameraPose()
	if self.rotateNode ~= self.cameraPositionNode then
		local dx = self.position[1] - self.lookAtPosition[1]
		local dy = self.position[2] - self.lookAtPosition[2]
		local dz = self.position[3] - self.lookAtPosition[3]
		local upx, upy, upz = unpack(self.upVector)

		if upx == 0 and upy == 0 and upz == 0 then
			upy = 1
		end

		if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
			upx = 0.1
		end

		setDirection(self.cameraNode, dx, dy, dz, upx, upy, upz)
	else
		local dx, dy, dz = localDirectionToWorld(self.rotateNode, 0, 0, 1)
		local upx, upy, upz = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)

		setDirection(self.cameraNode, dx, dy, dz, upx, upy, upz)
	end

	setTranslation(self.cameraNode, self.position[1], self.position[2], self.position[3])
end

function VehicleCamera:getTiltDirectionOffset()
	if not self.isInside and g_gameSettings:getValue(GameSettings.SETTING.CAMERA_TILTING) and getHasTouchpad() then
		local dx, dy, dz = getGravityDirection()
		local tiltOffset = MathUtil.getHorizontalRotationFromDeviceGravity(dx, dy, dz)

		return tiltOffset
	end

	return 0
end

function VehicleCamera:getCollisionDistance()
	if not self.isCollisionEnabled then
		return false, nil, , , , 
	end

	local raycastMask = 4576
	local targetCamX, targetCamY, targetCamZ = localToWorld(self.rotateNode, self.transDirX * self.zoomTarget, self.transDirY * self.zoomTarget, self.transDirZ * self.zoomTarget)
	local hasCollision = false
	local collisionDistance = -1
	local normalX, normalY, normalZ, normalDotDir = nil

	for _, raycastNode in ipairs(self.raycastNodes) do
		hasCollision = false
		local nodeX, nodeY, nodeZ = getWorldTranslation(raycastNode)
		local dirX = targetCamX - nodeX
		local dirY = targetCamY - nodeY
		local dirZ = targetCamZ - nodeZ
		local dirLength = MathUtil.vector3Length(dirX, dirY, dirZ)
		dirX = dirX / dirLength
		dirY = dirY / dirLength
		dirZ = dirZ / dirLength
		local startX = nodeX
		local startY = nodeY
		local startZ = nodeZ
		local currentDistance = 0
		local minDistance = self.transMin

		while true do
			if dirLength - currentDistance <= 0 then
				break
			end

			self.raycastDistance = 0

			raycastClosest(startX, startY, startZ, dirX, dirY, dirZ, "raycastCallback", dirLength - currentDistance, self, raycastMask, true)

			if self.raycastDistance ~= 0 then
				currentDistance = currentDistance + self.raycastDistance + 0.001
				local ndotd = MathUtil.dotProduct(self.normalX, self.normalY, self.normalZ, dirX, dirY, dirZ)
				local isAttachedVehicle = false
				local ignoreObject = false
				local object = g_currentMission:getNodeObject(self.raycastTransformId)

				if object ~= nil then
					local vehicles = self.vehicle:getChildVehicles()

					for i = 1, #vehicles do
						local vehicle = vehicles[i]

						if object ~= vehicle then
							local attached1 = object.getIsAttachedTo ~= nil and object:getIsAttachedTo(vehicle)
							local attached2 = vehicle.getIsAttachedTo ~= nil and vehicle:getIsAttachedTo(object)
							isAttachedVehicle = attached1 or attached2
							local mountObject = object.dynamicMountObject or object.tensionMountObject

							if mountObject ~= nil and (mountObject == vehicle or mountObject:getRootVehicle() == vehicle) then
								isAttachedVehicle = true
							end
						end

						if isAttachedVehicle then
							break
						end
					end
				end

				if getHasClassId(self.raycastTransformId, ClassIds.SHAPE) and getSplitType(self.raycastTransformId) ~= 0 then
					ignoreObject = true
				end

				if getIsTrigger(self.raycastTransformId) then
					ignoreObject = true
				end

				if isAttachedVehicle or object == self.vehicle or ignoreObject then
					if ndotd > 0 then
						minDistance = math.max(minDistance, currentDistance)
					end
				else
					hasCollision = true

					if raycastNode == self.rotateNode then
						normalZ = self.normalZ
						normalY = self.normalY
						normalX = self.normalX
						collisionDistance = math.max(self.transMin, currentDistance)
						normalDotDir = ndotd
					end

					break
				end

				startX = nodeX + dirX * currentDistance
				startY = nodeY + dirY * currentDistance
				startZ = nodeZ + dirZ * currentDistance
			else
				break
			end
		end

		if not hasCollision then
			break
		end
	end

	return hasCollision, collisionDistance, normalX, normalY, normalZ, normalDotDir
end
