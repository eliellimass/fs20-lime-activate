source("dataS/scripts/vehicles/specializations/events/WoodHarvesterCutTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterOnCutTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterOnDelimbTreeEvent.lua")

WoodHarvester = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onCutTree")
	end
}

function WoodHarvester.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "woodHarvesterSplitShapeCallback", WoodHarvester.woodHarvesterSplitShapeCallback)
	SpecializationUtil.registerFunction(vehicleType, "setLastTreeDiameter", WoodHarvester.setLastTreeDiameter)
	SpecializationUtil.registerFunction(vehicleType, "cutTree", WoodHarvester.cutTree)
	SpecializationUtil.registerFunction(vehicleType, "onDelimbTree", WoodHarvester.onDelimbTree)
end

function WoodHarvester.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", WoodHarvester.getCanBeSelected)
end

function WoodHarvester.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onCutTree", WoodHarvester)
end

function WoodHarvester:onLoad(savegame)
	local spec = self.spec_woodHarvester

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.woodHarvester.delimbSound", "vehicle.woodHarvester.sounds.delimb")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.woodHarvester.cutSound", "vehicle.woodHarvester.sounds.cut")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.woodHarvester.treeSizeMeasure#index", "vehicle.woodHarvester.treeSizeMeasure#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.woodHarvester.forwardingWheels.wheel(0)", "vehicle.woodHarvester.forwardingNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.woodHarvester.cutParticleSystems", "vehicle.woodHarvester.cutEffects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.woodHarvester.delimbParticleSystems", "vehicle.woodHarvester.delimbEffects")

	spec.curSplitShape = nil
	spec.attachedSplitShape = nil
	spec.hasAttachedSplitShape = false
	spec.isAttachedSplitShapeMoving = false
	spec.attachedSplitShapeX = 0
	spec.attachedSplitShapeY = 0
	spec.attachedSplitShapeZ = 0
	spec.attachedSplitShapeTargetY = 0
	spec.attachedSplitShapeLastCutY = 0
	spec.attachedSplitShapeStartY = 0
	spec.cutTimer = -1
	spec.cutNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.woodHarvester.cutNode#node"), self.i3dMappings)
	spec.cutMaxRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutNode#maxRadius"), 1)
	spec.cutSizeY = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutNode#sizeY"), 1)
	spec.cutSizeZ = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutNode#sizeZ"), 1)
	spec.cutAttachNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.woodHarvester.cutNode#attachNode"), self.i3dMappings)
	spec.cutAttachReferenceNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.woodHarvester.cutNode#attachReferenceNode"), self.i3dMappings)
	spec.cutAttachMoveSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutNode#attachMoveSpeed"), 3) * 0.001
	local cutReleasedComponentJointIndex = getXMLInt(self.xmlFile, "vehicle.woodHarvester.cutNode#releasedComponentJointIndex")

	if cutReleasedComponentJointIndex ~= nil then
		spec.cutReleasedComponentJoint = self.componentJoints[cutReleasedComponentJointIndex]
		spec.cutReleasedComponentJointRotLimitX = 0
		spec.cutReleasedComponentJointRotLimitXSpeed = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutNode#releasedComponentJointRotLimitXSpeed"), 100) * 0.001)
	end

	local cutReleasedComponentJoint2Index = getXMLInt(self.xmlFile, "vehicle.woodHarvester.cutNode#releasedComponentJoint2Index")

	if cutReleasedComponentJoint2Index ~= nil then
		spec.cutReleasedComponentJoint2 = self.componentJoints[cutReleasedComponentJoint2Index]
		spec.cutReleasedComponentJoint2RotLimitX = 0
		spec.cutReleasedComponentJoint2RotLimitXSpeed = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutNode#releasedComponentJointRotLimitXSpeed"), 100) * 0.001)
	end

	if spec.cutAttachReferenceNode ~= nil and spec.cutAttachNode ~= nil then
		spec.cutAttachHelperNode = createTransformGroup("helper")

		link(spec.cutAttachReferenceNode, spec.cutAttachHelperNode)
		setTranslation(spec.cutAttachHelperNode, 0, 0, 0)
		setRotation(spec.cutAttachHelperNode, 0, 0, 0)
	end

	spec.delimbNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.woodHarvester.delimbNode#node"), self.i3dMappings)
	spec.delimbSizeX = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.delimbNode#sizeX"), 0.1)
	spec.delimbSizeY = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.delimbNode#sizeY"), 1)
	spec.delimbSizeZ = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.delimbNode#sizeZ"), 1)
	spec.delimbOnCut = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.woodHarvester.delimbNode#delimbOnCut"), false)
	spec.cutLengthMin = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutLengths#min"), 1)
	spec.cutLengthMax = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutLengths#max"), 5)
	spec.cutLengthStep = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutLengths#step"), 0.5)

	if self.isClient then
		spec.cutEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.woodHarvester.cutEffects", self.components, self, self.i3dMappings)
		spec.delimbEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.woodHarvester.delimbEffects", self.components, self, self.i3dMappings)
		spec.forwardingNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.woodHarvester.forwardingNodes", self.components, self, self.i3dMappings)
		spec.samples = {
			cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodHarvester.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			delimb = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodHarvester.sounds", "delimb", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isCutSamplePlaying = false
		spec.isDelimbSamplePlaying = false
	end

	spec.cutAnimation = {
		name = getXMLString(self.xmlFile, "vehicle.woodHarvester.cutAnimation#name"),
		speedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutAnimation#speedScale"), 1),
		cutTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.cutAnimation#cutTime"), 1)
	}
	spec.grabAnimation = {
		name = getXMLString(self.xmlFile, "vehicle.woodHarvester.grabAnimation#name"),
		speedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.grabAnimation#speedScale"), 1)
	}

	if spec.grabAnimation.name ~= nil then
		local speedScale = -spec.grabAnimation.speedScale
		local stopTime = 0

		if spec.grabAnimation.speedScale < 0 then
			stopTime = 1
		end

		self:playAnimation(spec.grabAnimation.name, speedScale, nil, true)
		self:setAnimationStopTime(spec.grabAnimation.name, stopTime)
		AnimatedVehicle.updateAnimationByName(self, spec.grabAnimation.name, 99999999)
	end

	spec.treeSizeMeasure = {
		node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.woodHarvester.treeSizeMeasure#node"), self.i3dMappings),
		rotMaxRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.woodHarvester.treeSizeMeasure#rotMaxRadius"), 1)
	}
	spec.warnInvalidTree = false
	spec.warnInvalidTreeRadius = false
	spec.warnTreeNotOwned = false
	spec.currentCutLength = spec.cutLengthMin
	spec.lastDiameter = 0

	if self.loadDashboardsFromXML ~= nil then
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.woodHarvester.dashboards", {
			valueTypeToLoad = "cutLength",
			valueObject = spec,
			valueFunc = function (spec)
				return spec.currentCutLength * 100
			end
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.woodHarvester.dashboards", {
			valueTypeToLoad = "curCutLength",
			valueObject = spec,
			valueFunc = function (spec)
				return math.abs(spec.currentCutLength - (spec.attachedSplitShapeTargetY - spec.attachedSplitShapeY)) * 100
			end
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.woodHarvester.dashboards", {
			valueTypeToLoad = "diameter",
			valueObject = spec,
			valueFunc = function (spec)
				return spec.lastDiameter * 1000
			end
		})
	end
end

function WoodHarvester:onPostLoad(savegame)
	local spec = self.spec_woodHarvester

	if savegame ~= nil and not savegame.resetVehicles then
		spec.currentCutLength = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. ".woodHarvester#currentCutLength"), spec.cutLengthMin)
	end
end

function WoodHarvester:onDelete()
	local spec = self.spec_woodHarvester

	if spec.attachedSplitShapeJointIndex ~= nil then
		removeJoint(spec.attachedSplitShapeJointIndex)

		spec.attachedSplitShapeJointIndex = nil
	end

	if spec.cutAttachHelperNode ~= nil then
		delete(spec.cutAttachHelperNode)
	end

	if self.isClient then
		g_effectManager:deleteEffects(spec.cutEffects)
		g_effectManager:deleteEffects(spec.delimbEffects)
		g_soundManager:deleteSamples(spec.samples)
		g_animationManager:deleteAnimations(spec.forwardingNodes)
	end
end

function WoodHarvester:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_woodHarvester

	setXMLFloat(xmlFile, key .. "#currentCutLength", spec.currentCutLength)
end

function WoodHarvester:onReadStream(streamId, connection)
	local spec = self.spec_woodHarvester
	spec.hasAttachedSplitShape = streamReadBool(streamId)
	spec.isAttachedSplitShapeMoving = streamReadBool(streamId)
end

function WoodHarvester:onWriteStream(streamId, connection)
	local spec = self.spec_woodHarvester

	streamWriteBool(streamId, spec.hasAttachedSplitShape)
	streamWriteBool(streamId, spec.isAttachedSplitShapeMoving)
end

function WoodHarvester:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_woodHarvester

	if self.isServer then
		local lostShape = false

		if spec.attachedSplitShape ~= nil then
			if not entityExists(spec.attachedSplitShape) then
				spec.attachedSplitShape = nil
				spec.attachedSplitShapeJointIndex = nil
				spec.isAttachedSplitShapeMoving = false
				spec.cutTimer = -1
				lostShape = true
			end
		elseif spec.curSplitShape ~= nil and not entityExists(spec.curSplitShape) then
			spec.curSplitShape = nil
			lostShape = true
		end

		if lostShape then
			SpecializationUtil.raiseEvent(self, "onCutTree", 0)

			if g_server ~= nil then
				g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent:new(self, 0), nil, , self)
			end
		end
	end

	if self.isServer and (spec.attachedSplitShape ~= nil or spec.curSplitShape ~= nil) then
		if spec.cutTimer > 0 then
			if spec.cutAnimation.name ~= nil then
				if spec.cutAnimation.cutTime < self:getAnimationTime(spec.cutAnimation.name) then
					spec.cutTimer = 0
				end
			else
				spec.cutTimer = math.max(spec.cutTimer - dt, 0)
			end
		end

		local readyToCut = spec.cutTimer == 0

		if readyToCut then
			spec.cutTimer = -1
			local x, y, z = getWorldTranslation(spec.cutNode)
			local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
			local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)
			local newTreeCut = false
			local currentSplitShape = nil

			if spec.attachedSplitShapeJointIndex ~= nil then
				removeJoint(spec.attachedSplitShapeJointIndex)

				spec.attachedSplitShapeJointIndex = nil
				currentSplitShape = spec.attachedSplitShape
				spec.attachedSplitShape = nil
			else
				currentSplitShape = spec.curSplitShape
				spec.curSplitShape = nil
				newTreeCut = true
			end

			local splitTypeName = ""
			local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(currentSplitShape))

			if splitType ~= nil then
				splitTypeName = splitType.name
			end

			if spec.delimbOnCut then
				local xD, yD, zD = getWorldTranslation(spec.delimbNode)
				local nxD, nyD, nzD = localDirectionToWorld(spec.delimbNode, 1, 0, 0)
				local yxD, yyD, yzD = localDirectionToWorld(spec.delimbNode, 0, 1, 0)
				local vx = x - xD
				local vy = y - yD
				local vz = z - zD
				local sizeX = MathUtil.vector3Length(vx, vy, vz)

				removeSplitShapeAttachments(currentSplitShape, xD + vx * 0.5, yD + vy * 0.5, zD + vz * 0.5, nxD, nyD, nzD, yxD, yyD, yzD, sizeX * 0.7 + spec.delimbSizeX, spec.delimbSizeY, spec.delimbSizeZ)
			end

			spec.attachedSplitShape = nil
			spec.curSplitShape = nil
			spec.prevSplitShape = currentSplitShape

			g_currentMission:removeKnownSplitShape(currentSplitShape)
			splitShape(currentSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ, "woodHarvesterSplitShapeCallback", self)

			if spec.attachedSplitShape == nil then
				SpecializationUtil.raiseEvent(self, "onCutTree", 0)

				if g_server ~= nil then
					g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent:new(self, 0), nil, , self)
				end
			elseif spec.delimbOnCut then
				local xD, yD, zD = getWorldTranslation(spec.delimbNode)
				local nxD, nyD, nzD = localDirectionToWorld(spec.delimbNode, 1, 0, 0)
				local yxD, yyD, yzD = localDirectionToWorld(spec.delimbNode, 0, 1, 0)
				local vx = x - xD
				local vy = y - yD
				local vz = z - zD
				local sizeX = MathUtil.vector3Length(vx, vy, vz)

				removeSplitShapeAttachments(spec.attachedSplitShape, xD + vx * 3, yD + vy * 3, zD + vz * 3, nxD, nyD, nzD, yxD, yyD, yzD, sizeX * 3 + spec.delimbSizeX, spec.delimbSizeY, spec.delimbSizeZ)
			end

			if newTreeCut then
				local stats = g_currentMission:farmStats(self:getActiveFarm())

				stats:updateStats("cutTreeCount", 1)

				if splitTypeName ~= "" then
					stats:updateTreeTypesCut(splitTypeName)
				end
			end
		end

		if spec.attachedSplitShape ~= nil and spec.isAttachedSplitShapeMoving then
			if spec.delimbNode ~= nil then
				local x, y, z = getWorldTranslation(spec.delimbNode)
				local nx, ny, nz = localDirectionToWorld(spec.delimbNode, 1, 0, 0)
				local yx, yy, yz = localDirectionToWorld(spec.delimbNode, 0, 1, 0)

				removeSplitShapeAttachments(spec.attachedSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.delimbSizeX, spec.delimbSizeY, spec.delimbSizeZ)
			end

			if spec.cutNode ~= nil and spec.attachedSplitShapeJointIndex ~= nil then
				local x, y, z = getWorldTranslation(spec.cutAttachReferenceNode)
				local nx, ny, nz = localDirectionToWorld(spec.cutAttachReferenceNode, 0, 1, 0)
				local _, lengthRem = getSplitShapePlaneExtents(spec.attachedSplitShape, x, y, z, nx, ny, nz)

				if lengthRem == nil or lengthRem <= 0.1 then
					removeJoint(spec.attachedSplitShapeJointIndex)

					spec.attachedSplitShapeJointIndex = nil
					spec.attachedSplitShape = nil

					self:onDelimbTree(false)

					if g_server ~= nil then
						g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent:new(self, false), nil, , self)
					end

					SpecializationUtil.raiseEvent(self, "onCutTree", 0)

					if g_server ~= nil then
						g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent:new(self, 0), nil, , self)
					end
				else
					spec.attachedSplitShapeY = spec.attachedSplitShapeY + spec.cutAttachMoveSpeed * dt

					if spec.attachedSplitShapeTargetY <= spec.attachedSplitShapeY then
						spec.attachedSplitShapeY = spec.attachedSplitShapeTargetY

						self:onDelimbTree(false)

						if g_server ~= nil then
							g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent:new(self, false), nil, , self)
						end
					end

					if spec.attachedSplitShapeJointIndex ~= nil then
						x, y, z = localToWorld(spec.cutNode, 0.3, 0, 0)
						nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
						local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)
						local shape, minY, maxY, minZ, maxZ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ)

						if shape == spec.attachedSplitShape then
							local treeCenterX, treeCenterY, treeCenterZ = localToWorld(spec.cutNode, 0, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
							spec.attachedSplitShapeX, _, spec.attachedSplitShapeZ = worldToLocal(spec.attachedSplitShape, treeCenterX, treeCenterY, treeCenterZ)

							self:setLastTreeDiameter((maxY - minY + maxZ - minZ) * 0.5)
						end

						x, y, z = localToWorld(spec.attachedSplitShape, spec.attachedSplitShapeX, spec.attachedSplitShapeY, spec.attachedSplitShapeZ)

						setJointPosition(spec.attachedSplitShapeJointIndex, 1, x, y, z)
					end
				end
			end
		end
	end

	if self.isClient then
		if spec.cutAnimation.name ~= nil then
			if self:getIsAnimationPlaying(spec.cutAnimation.name) and self:getAnimationTime(spec.cutAnimation.name) < spec.cutAnimation.cutTime then
				if not spec.isCutSamplePlaying then
					g_soundManager:playSample(spec.samples.cut)

					spec.isCutSamplePlaying = true
				end

				g_effectManager:setFillType(spec.cutEffects, FillType.WOODCHIPS)
				g_effectManager:startEffects(spec.cutEffects)
			else
				if spec.isCutSamplePlaying then
					g_soundManager:stopSample(spec.samples.cut)

					spec.isCutSamplePlaying = false
				end

				g_effectManager:stopEffects(spec.cutEffects)
			end
		end

		if spec.isAttachedSplitShapeMoving then
			if not spec.isDelimbSamplePlaying then
				g_soundManager:playSample(spec.samples.delimb)

				spec.isDelimbSamplePlaying = true
			end

			g_effectManager:setFillType(spec.delimbEffects, FillType.WOODCHIPS)
			g_effectManager:startEffects(spec.delimbEffects)
			g_animationManager:startAnimations(spec.forwardingNodes)
		else
			if spec.isDelimbSamplePlaying then
				g_soundManager:stopSample(spec.samples.delimb)

				spec.isDelimbSamplePlaying = false
			end

			g_effectManager:stopEffects(spec.delimbEffects)
			g_animationManager:stopAnimations(spec.forwardingNodes)
		end
	end
end

function WoodHarvester:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_woodHarvester
	spec.warnInvalidTree = false
	spec.warnInvalidTreeRadius = false
	spec.warnTreeNotOwned = false

	if self:getIsTurnedOn() and spec.attachedSplitShape == nil and spec.cutNode ~= nil then
		local x, y, z = getWorldTranslation(spec.cutNode)
		local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
		local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)

		if spec.curSplitShape == nil and (spec.cutReleasedComponentJoint == nil or spec.cutReleasedComponentJointRotLimitX == 0) then
			local shape, minY, maxY, minZ, maxZ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ)

			if shape ~= 0 then
				local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(shape))

				if splitType == nil or not splitType.allowsWoodHarvester then
					spec.warnInvalidTree = true
				elseif g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
					local treeDx, treeDy, treeDz = localDirectionToWorld(shape, 0, 1, 0)
					local cosTreeAngle = MathUtil.dotProduct(nx, ny, nz, treeDx, treeDy, treeDz)

					if cosTreeAngle >= 0.35 then
						local radius = math.max(maxY - minY, maxZ - minZ) * 0.5 * cosTreeAngle

						if spec.cutMaxRadius < radius then
							spec.warnInvalidTreeRadius = true
						else
							self:setLastTreeDiameter(math.max(maxY - minY, maxZ - minZ))

							spec.curSplitShape = shape
						end
					end
				else
					spec.warnTreeNotOwned = true
				end
			end
		end

		if spec.curSplitShape ~= nil then
			local minY, maxY, minZ, maxZ = testSplitShape(spec.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ)

			if minY == nil then
				spec.curSplitShape = nil
			else
				local cutTooLow = false
				_, y, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, minY, minZ)
				cutTooLow = cutTooLow or y < 0.01
				_, y, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, minY, maxZ)
				cutTooLow = cutTooLow or y < 0.01
				_, y, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, maxY, minZ)
				cutTooLow = cutTooLow or y < 0.01
				_, y, _ = localToLocal(spec.cutNode, spec.curSplitShape, 0, maxY, maxZ)
				cutTooLow = cutTooLow or y < 0.01

				if cutTooLow then
					spec.curSplitShape = nil
				end
			end
		end

		if spec.curSplitShape == nil and spec.cutTimer > -1 then
			SpecializationUtil.raiseEvent(self, "onCutTree", 0)

			if g_server ~= nil then
				g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent:new(self, 0), nil, , self)
			end
		end
	end

	if self.isServer and spec.attachedSplitShape == nil then
		if spec.cutReleasedComponentJoint ~= nil and spec.cutReleasedComponentJointRotLimitX ~= 0 then
			spec.cutReleasedComponentJointRotLimitX = math.max(0, spec.cutReleasedComponentJointRotLimitX - spec.cutReleasedComponentJointRotLimitXSpeed * dt)

			setJointRotationLimit(spec.cutReleasedComponentJoint.jointIndex, 0, true, 0, spec.cutReleasedComponentJointRotLimitX)
		end

		if spec.cutReleasedComponentJoint2 ~= nil and spec.cutReleasedComponentJoint2RotLimitX ~= 0 then
			spec.cutReleasedComponentJoint2RotLimitX = math.max(spec.cutReleasedComponentJoint2RotLimitX - spec.cutReleasedComponentJoint2RotLimitXSpeed * dt, 0)

			setJointRotationLimit(spec.cutReleasedComponentJoint2.jointIndex, 0, true, -spec.cutReleasedComponentJoint2RotLimitX, spec.cutReleasedComponentJoint2RotLimitX)
		end
	end

	if self.isServer and self.playDelayedGrabAnimationTime ~= nil and self.playDelayedGrabAnimationTime < g_currentMission.time then
		self.playDelayedGrabAnimationTime = nil

		if self:getAnimationTime(spec.grabAnimation.name) > 0 and spec.grabAnimation.name ~= nil and spec.attachedSplitShape == nil then
			if spec.grabAnimation.speedScale > 0 then
				self:setAnimationStopTime(spec.grabAnimation.name, 0)
			else
				self:setAnimationStopTime(spec.grabAnimation.name, 1)
			end

			self:playAnimation(spec.grabAnimation.name, -spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), false)
		end
	end

	if self.isClient then
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]

		if actionEvent ~= nil then
			local showAction = false

			if spec.hasAttachedSplitShape then
				if not spec.isAttachedSplitShapeMoving and self:getAnimationTime(spec.cutAnimation.name) == 1 then
					showAction = true
				end
			elseif spec.curSplitShape ~= nil then
				showAction = true
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
		end

		actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, not spec.isAttachedSplitShapeMoving)

			if not spec.isAttachedSplitShapeMoving then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText("action_woodHarvesterChangeCutLength"), string.format("%.1f", spec.currentCutLength)))
			end
		end
	end
end

function WoodHarvester:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_woodHarvester

	if isActiveForInputIgnoreSelection and isSelected and self:getIsTurnedOn() and spec.cutNode ~= nil then
		if spec.warnInvalidTreeRadius then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_treeTooThick"), 1000)
		elseif spec.warnInvalidTree then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_treeTypeNotSupported"), 1000)
		elseif spec.warnTreeNotOwned then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 1000)
		end
	end
end

function WoodHarvester:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_woodHarvester

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, WoodHarvester.actionEventCutTree, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_woodHarvesterCut"))

			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, WoodHarvester.actionEventSetCutlength, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
		end
	end
end

function WoodHarvester:onDeactivate()
	local spec = self.spec_woodHarvester
	spec.curSplitShape = nil

	self:setLastTreeDiameter(0)
end

function WoodHarvester:onTurnedOn()
	local spec = self.spec_woodHarvester
	self.playDelayedGrabAnimationTime = nil

	if spec.grabAnimation.name ~= nil then
		if spec.grabAnimation.speedScale > 0 then
			self:setAnimationStopTime(spec.grabAnimation.name, 1)
		else
			self:setAnimationStopTime(spec.grabAnimation.name, 0)
		end

		self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
	end

	self:setLastTreeDiameter(0)
end

function WoodHarvester:onTurnedOff()
	local spec = self.spec_woodHarvester
	spec.curSplitShape = nil

	self:setLastTreeDiameter(0)

	spec.attachedSplitShape = nil
	spec.hasAttachedSplitShape = false
	spec.isAttachedSplitShapeMoving = false

	if spec.attachedSplitShapeJointIndex ~= nil then
		removeJoint(spec.attachedSplitShapeJointIndex)

		spec.attachedSplitShapeJointIndex = nil
	end

	self.playDelayedGrabAnimationTime = g_currentMission.time + 500

	if spec.grabAnimation.name ~= nil and spec.attachedSplitShape == nil then
		if spec.grabAnimation.speedScale > 0 then
			self:setAnimationStopTime(spec.grabAnimation.name, 1)
		else
			self:setAnimationStopTime(spec.grabAnimation.name, 0)
		end

		self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
	end

	if self.isClient then
		g_effectManager:stopEffects(spec.delimbEffects)
		g_effectManager:stopEffects(spec.cutEffects)
		g_soundManager:stopSamples(spec.samples)

		spec.isCutSamplePlaying = false
		spec.isDelimbSamplePlaying = false
	end
end

function WoodHarvester:cutTree(length, noEventSend)
	local spec = self.spec_woodHarvester

	WoodHarvesterCutTreeEvent.sendEvent(self, length, noEventSend)

	if self.isServer then
		if length == 0 then
			if spec.attachedSplitShape ~= nil or spec.curSplitShape ~= nil then
				spec.cutTimer = 100

				if spec.cutAnimation.name ~= nil then
					self:setAnimationTime(spec.cutAnimation.name, 0, true)
					self:playAnimation(spec.cutAnimation.name, spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.name))
				end
			end
		elseif length > 0 and spec.attachedSplitShape ~= nil then
			spec.attachedSplitShapeTargetY = spec.attachedSplitShapeLastCutY + length

			self:onDelimbTree(true)

			if g_server ~= nil then
				g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent:new(self, true), nil, , self)
			end
		end
	end
end

function WoodHarvester:onCutTree(radius)
	local spec = self.spec_woodHarvester

	if radius > 0 then
		if self.isClient then
			if spec.grabAnimation.name ~= nil then
				local targetAnimTime = math.min(1, radius / spec.treeSizeMeasure.rotMaxRadius)

				if spec.grabAnimation.speedScale < 0 then
					targetAnimTime = 1 - targetAnimTime
				end

				self:setAnimationStopTime(spec.grabAnimation.name, targetAnimTime)

				if self:getAnimationTime(spec.grabAnimation.name) < targetAnimTime then
					self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
				else
					self:playAnimation(spec.grabAnimation.name, -spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
				end
			end

			self:setLastTreeDiameter(2 * radius)
		end

		spec.hasAttachedSplitShape = true
	else
		if spec.grabAnimation.name ~= nil then
			if spec.grabAnimation.speedScale > 0 then
				self:setAnimationStopTime(spec.grabAnimation.name, 1)
			else
				self:setAnimationStopTime(spec.grabAnimation.name, 0)
			end

			self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
		end

		spec.hasAttachedSplitShape = false
		spec.cutTimer = -1
	end
end

function WoodHarvester:onDelimbTree(state)
	local spec = self.spec_woodHarvester

	if state then
		spec.isAttachedSplitShapeMoving = true
	else
		spec.isAttachedSplitShapeMoving = false

		self:cutTree(0)
	end
end

function WoodHarvester:woodHarvesterSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	local spec = self.spec_woodHarvester

	g_currentMission:addKnownSplitShape(shape)

	if spec.attachedSplitShape == nil and isAbove and not isBelow and spec.cutAttachNode ~= nil and spec.cutAttachReferenceNode ~= nil then
		spec.attachedSplitShape = shape
		local treeCenterX, treeCenterY, treeCenterZ = localToWorld(spec.cutNode, 0, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
		local x, y, z = localToWorld(spec.cutAttachReferenceNode, 0, 0, (maxZ - minZ) * 0.5)
		local dx, dy, dz = localDirectionToWorld(shape, 0, 0, 1)
		local upx, upy, upz = localDirectionToWorld(spec.cutAttachReferenceNode, 0, 1, 0)
		local sideX, sideY, sizeZ = MathUtil.crossProduct(upx, upy, upz, dx, dy, dz)
		dx, dy, dz = MathUtil.crossProduct(sideX, sideY, sizeZ, upx, upy, upz)

		I3DUtil.setWorldDirection(spec.cutAttachHelperNode, dx, dy, dz, upx, upy, upz, 2)

		local constr = JointConstructor:new()

		constr:setActors(spec.cutAttachNode, shape)
		constr:setJointTransforms(spec.cutAttachHelperNode, shape)
		constr:setJointWorldPositions(x, y, z, treeCenterX, treeCenterY, treeCenterZ)
		constr:setRotationLimit(0, 0, 0)
		constr:setRotationLimit(1, 0, 0)
		constr:setRotationLimit(2, 0, 0)
		constr:setEnableCollision(false)

		spec.attachedSplitShapeJointIndex = constr:finalize()

		if spec.cutReleasedComponentJoint ~= nil then
			spec.cutReleasedComponentJointRotLimitX = math.pi * 0.9

			if spec.cutReleasedComponentJoint.jointIndex ~= 0 then
				setJointRotationLimit(spec.cutReleasedComponentJoint.jointIndex, 0, true, 0, spec.cutReleasedComponentJointRotLimitX)
			end
		end

		if spec.cutReleasedComponentJoint2 ~= nil then
			spec.cutReleasedComponentJoint2RotLimitX = math.pi * 0.9

			if spec.cutReleasedComponentJoint2.jointIndex ~= 0 then
				setJointRotationLimit(spec.cutReleasedComponentJoint2.jointIndex, 0, true, -spec.cutReleasedComponentJoint2RotLimitX, spec.cutReleasedComponentJoint2RotLimitX)
			end
		end

		spec.attachedSplitShapeX, spec.attachedSplitShapeY, spec.attachedSplitShapeZ = worldToLocal(shape, treeCenterX, treeCenterY, treeCenterZ)
		spec.attachedSplitShapeLastCutY = spec.attachedSplitShapeY
		spec.attachedSplitShapeStartY = spec.attachedSplitShapeY
		spec.attachedSplitShapeTargetY = spec.attachedSplitShapeY
		local radius = (maxY - minY + maxZ - minZ) / 4

		SpecializationUtil.raiseEvent(self, "onCutTree", radius)

		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent:new(self, radius), nil, , self)
		end
	end
end

function WoodHarvester:setLastTreeDiameter(diameter)
	local spec = self.spec_woodHarvester
	spec.lastDiameter = diameter
end

function WoodHarvester:getCanBeSelected(superFunc)
	return true
end

function WoodHarvester:actionEventCutTree(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_woodHarvester

	if spec.hasAttachedSplitShape then
		if not spec.isAttachedSplitShapeMoving and self:getAnimationTime(spec.cutAnimation.name) == 1 then
			self:cutTree(spec.currentCutLength)
		end
	elseif spec.curSplitShape ~= nil then
		self:cutTree(0)
	end
end

function WoodHarvester:actionEventSetCutlength(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_woodHarvester

	if not spec.isAttachedSplitShapeMoving then
		spec.currentCutLength = spec.currentCutLength + spec.cutLengthStep

		if spec.currentCutLength > spec.cutLengthMax + 0.0001 then
			spec.currentCutLength = spec.cutLengthMin
		end
	end
end
