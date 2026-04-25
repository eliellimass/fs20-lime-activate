AIImplement = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementStart")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementActive")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementEnd")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementStartLine")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementEndLine")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementStartTurn")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementTurnProgress")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementEndTurn")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementBlock")
		SpecializationUtil.registerEvent(vehicleType, "onAIImplementContinue")
	end
}

function AIImplement.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCanAIImplementContinueWork", AIImplement.getCanAIImplementContinueWork)
	SpecializationUtil.registerFunction(vehicleType, "getCanImplementBeUsedForAI", AIImplement.getCanImplementBeUsedForAI)
	SpecializationUtil.registerFunction(vehicleType, "getAIMinTurningRadius", AIImplement.getAIMinTurningRadius)
	SpecializationUtil.registerFunction(vehicleType, "getAIMarkers", AIImplement.getAIMarkers)
	SpecializationUtil.registerFunction(vehicleType, "setAIMarkersInverted", AIImplement.setAIMarkersInverted)
	SpecializationUtil.registerFunction(vehicleType, "getAIInvertMarkersOnTurn", AIImplement.getAIInvertMarkersOnTurn)
	SpecializationUtil.registerFunction(vehicleType, "getAISizeMarkers", AIImplement.getAISizeMarkers)
	SpecializationUtil.registerFunction(vehicleType, "getAILookAheadSize", AIImplement.getAILookAheadSize)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasNoFullCoverageArea", AIImplement.getAIHasNoFullCoverageArea)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementCollisionTriggers", AIImplement.getAIImplementCollisionTriggers)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsLowering", AIImplement.getAINeedsLowering)
	SpecializationUtil.registerFunction(vehicleType, "getAILowerIfAnyIsLowered", AIImplement.getAILowerIfAnyIsLowered)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsRootAlignment", AIImplement.getAINeedsRootAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getAIAllowTurnBackward", AIImplement.getAIAllowTurnBackward)
	SpecializationUtil.registerFunction(vehicleType, "getAIBlockTurnBackward", AIImplement.getAIBlockTurnBackward)
	SpecializationUtil.registerFunction(vehicleType, "getAIToolReverserDirectionNode", AIImplement.getAIToolReverserDirectionNode)
	SpecializationUtil.registerFunction(vehicleType, "getAITurnRadiusLimitation", AIImplement.getAITurnRadiusLimitation)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitProhibitions", AIImplement.setAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "addAIFruitProhibitions", AIImplement.addAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "clearAIFruitProhibitions", AIImplement.clearAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitProhibitions", AIImplement.getAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitExtraRequirements", AIImplement.setAIFruitExtraRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitExtraRequirements", AIImplement.getAIFruitExtraRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitRequirements", AIImplement.setAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAIFruitRequirement", AIImplement.addAIFruitRequirement)
	SpecializationUtil.registerFunction(vehicleType, "clearAIFruitRequirements", AIImplement.clearAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitRequirements", AIImplement.getAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAITerrainDetailRequiredRange", AIImplement.addAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "clearAITerrainDetailRequiredRange", AIImplement.clearAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "getAITerrainDetailRequiredRange", AIImplement.getAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "addAITerrainDetailProhibitedRange", AIImplement.addAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "clearAITerrainDetailProhibitedRange", AIImplement.clearAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getAITerrainDetailProhibitedRange", AIImplement.getAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getFieldCropsQuery", AIImplement.getFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "updateFieldCropsQuery", AIImplement.updateFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "createFieldCropsQuery", AIImplement.createFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIImplementInLine", AIImplement.getIsAIImplementInLine)
	SpecializationUtil.registerFunction(vehicleType, "aiImplementStartLine", AIImplement.aiImplementStartLine)
	SpecializationUtil.registerFunction(vehicleType, "aiImplementEndLine", AIImplement.aiImplementEndLine)
end

function AIImplement.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AIImplement.addVehicleToAIImplementList)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIImplement.getAllowTireTracks)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", AIImplement.getDoConsumePtoPower)
end

function AIImplement.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIImplement)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIImplement)
end

function AIImplement:onLoad(savegame)
	local spec = self.spec_aiImplement
	local baseName = "vehicle.ai"

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".areaMarkers#leftIndex", baseName .. ".areaMarkers#leftNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".areaMarkers#rightIndex", baseName .. ".areaMarkers#rightNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".areaMarkers#backIndex", baseName .. ".areaMarkers#backNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".sizeMarkers#leftIndex", baseName .. ".sizeMarkers#leftNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".sizeMarkers#rightIndex", baseName .. ".sizeMarkers#rightNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".sizeMarkers#backIndex", baseName .. ".sizeMarkers#backNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".trafficCollisionTrigger#index", baseName .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".trafficCollisionTrigger#node", baseName .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".collisionTrigger#index", baseName .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.aiLookAheadSize#value", baseName .. ".lookAheadSize#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".toolReverserDirectionNode#index", baseName .. ".toolReverserDirectionNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".turningRadiusLimiation", baseName .. ".turningRadiusLimitation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. ".forceTurnNoBackward#value", baseName .. ".allowTurnBackward#value (inverted)")

	spec.minTurningRadius = getXMLFloat(self.xmlFile, baseName .. ".minTurningRadius#value")
	spec.leftMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".areaMarkers#leftNode"), self.i3dMappings)
	spec.rightMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".areaMarkers#rightNode"), self.i3dMappings)
	spec.backMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".areaMarkers#backNode"), self.i3dMappings)
	spec.aiMarkersInverted = false
	spec.sizeLeftMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".sizeMarkers#leftNode"), self.i3dMappings)
	spec.sizeRightMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".sizeMarkers#rightNode"), self.i3dMappings)
	spec.sizeBackMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".sizeMarkers#backNode"), self.i3dMappings)
	spec.collisionTrigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".collisionTrigger#node"), self.i3dMappings)

	if spec.collisionTrigger ~= nil then
		local rigidBodyType = getRigidBodyType(spec.collisionTrigger)

		if rigidBodyType ~= "Kinematic" then
			g_logManager:xmlWarning(self.configFileName, "'aiCollisionTrigger' is not a kinematic body type")
		end

		self:doCollisionMaskCheck(MathUtil.bitsToMask(20, 13), nil, spec.collisionTrigger, "aiCollisionTrigger")
	end

	spec.needsLowering = Utils.getNoNil(getXMLBool(self.xmlFile, baseName .. ".needsLowering#value"), true)
	spec.lowerIfAnyIsLowerd = Utils.getNoNil(getXMLBool(self.xmlFile, baseName .. ".needsLowering#lowerIfAnyIsLowerd"), false)
	spec.needsRootAlignment = Utils.getNoNil(getXMLBool(self.xmlFile, baseName .. ".needsRootAlignment#value"), true)
	spec.needsRootAlignmentThreshold = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, baseName .. ".needsRootAlignment#threshold"), 90))
	spec.allowTurnBackward = Utils.getNoNil(getXMLBool(self.xmlFile, baseName .. ".allowTurnBackward#value"), true)
	spec.blockTurnBackward = Utils.getNoNil(getXMLBool(self.xmlFile, baseName .. ".blockTurnBackward#value"), false)
	spec.toolReverserDirectionNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".toolReverserDirectionNode#node"), self.i3dMappings)
	spec.turningRadiusLimitation = {
		rotationJoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. ".turningRadiusLimitation#rotationJointNode"), self.i3dMappings)
	}

	if spec.turningRadiusLimitation.rotationJoint ~= nil then
		spec.turningRadiusLimitation.wheelIndices = {
			StringUtil.getVectorFromString(getXMLString(self.xmlFile, baseName .. ".turningRadiusLimitation#wheelIndices"))
		}
	end

	spec.turningRadiusLimitation.radius = getXMLFloat(self.xmlFile, baseName .. ".turningRadiusLimitation#radius")
	spec.lookAheadSize = Utils.getNoNil(getXMLFloat(self.xmlFile, baseName .. ".lookAheadSize#value"), 2)
	spec.useAttributesOfAttachedImplement = Utils.getNoNil(getXMLBool(self.xmlFile, baseName .. ".useAttributesOfAttachedImplement#value"), false)
	spec.hasNoFullCoverageArea = Utils.getNoNil(getXMLString(self.xmlFile, baseName .. ".hasNoFullCoverageArea#value"), false)
	spec.hasNoFullCoverageAreaOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, baseName .. ".hasNoFullCoverageArea#offset"), 0)
	spec.terrainDetailRequiredValueRanges = {}
	spec.terrainDetailProhibitedValueRanges = {}
	spec.requiredFruitTypes = {}
	spec.prohibitedFruitTypes = {}
	spec.isLineStarted = false
end

function AIImplement:onPostLoad(savegame)
	if self.getWheels ~= nil then
		local spec = self.spec_aiImplement

		if spec.turningRadiusLimitation.wheelIndices ~= nil then
			spec.turningRadiusLimitation.wheels = {}
			local wheels = self:getWheels()

			for _, index in ipairs(spec.turningRadiusLimitation.wheelIndices) do
				table.insert(spec.turningRadiusLimitation.wheels, wheels[index])
			end
		end
	end
end

function AIImplement:getCanAIImplementContinueWork()
	return true
end

function AIImplement:getCanImplementBeUsedForAI()
	local leftMarker, rightMarker, backMarker, _ = self:getAIMarkers()

	if leftMarker == nil or rightMarker == nil or backMarker == nil then
		return false
	end

	return true
end

function AIImplement:addVehicleToAIImplementList(superFunc, list)
	if self:getCanImplementBeUsedForAI() then
		table.insert(list, {
			object = self
		})
	end

	superFunc(self, list)
end

function AIImplement:getAllowTireTracks(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIImplement:getDoConsumePtoPower(superFunc)
	local rootVehicle = self:getRootVehicle()

	if rootVehicle.getAIIsTurning ~= nil and rootVehicle:getAIIsTurning() then
		return false
	end

	return superFunc(self)
end

function AIImplement:getAIMinTurningRadius()
	return self.spec_aiImplement.minTurningRadius
end

function AIImplement:getAIMarkers()
	local spec = self.spec_aiImplement

	if spec.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, implement in ipairs(self:getAttachedImplements()) do
			if implement.object.getAIMarkers ~= nil then
				return implement.object:getAIMarkers()
			end
		end
	end

	if spec.aiMarkersInverted then
		return spec.rightMarker, spec.leftMarker, spec.backMarker, true
	else
		return spec.leftMarker, spec.rightMarker, spec.backMarker, false
	end
end

function AIImplement:setAIMarkersInverted(state)
	local spec = self.spec_aiImplement
	spec.aiMarkersInverted = not spec.aiMarkersInverted
end

function AIImplement:getAIInvertMarkersOnTurn(turnLeft)
	return false
end

function AIImplement:getAISizeMarkers()
	local spec = self.spec_aiImplement

	return spec.sizeLeftMarker, spec.sizeRightMarker, spec.sizeBackMarker
end

function AIImplement:getAILookAheadSize()
	return self.spec_aiImplement.lookAheadSize
end

function AIImplement:getAIHasNoFullCoverageArea()
	return self.spec_aiImplement.hasNoFullCoverageArea, self.spec_aiImplement.hasNoFullCoverageAreaOffset
end

function AIImplement:getAIImplementCollisionTriggers(collisionTriggers)
	local spec = self.spec_aiImplement

	if spec.collisionTrigger ~= nil then
		collisionTriggers[self] = spec.collisionTrigger
	end
end

function AIImplement:getAINeedsLowering()
	return self.spec_aiImplement.needsLowering
end

function AIImplement:getAILowerIfAnyIsLowered()
	return self.spec_aiImplement.lowerIfAnyIsLowerd
end

function AIImplement:getAINeedsRootAlignment()
	return self.spec_aiImplement.needsRootAlignment, self.spec_aiImplement.needsRootAlignmentThreshold
end

function AIImplement:getAIAllowTurnBackward()
	return self.spec_aiImplement.allowTurnBackward
end

function AIImplement:getAIBlockTurnBackward()
	return self.spec_aiImplement.blockTurnBackward
end

function AIImplement:getAIToolReverserDirectionNode()
	return self.spec_aiImplement.toolReverserDirectionNode
end

function AIImplement:getAITurnRadiusLimitation()
	local spec = self.spec_aiImplement

	return spec.turningRadiusLimitation.radius, spec.turningRadiusLimitation.rotationJoint, spec.turningRadiusLimitation.wheels
end

function AIImplement:setAIFruitExtraRequirements(useDensityHeightMap, useWindrowFruitType)
	local spec = self.spec_aiImplement
	spec.useDensityHeightMap = useDensityHeightMap or spec.useDensityHeightMap or false
	spec.useWindrowFruitType = useWindrowFruitType or spec.useWindrowFruitType or false

	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitExtraRequirements()
	local spec = self.spec_aiImplement

	return spec.useDensityHeightMap, spec.useWindrowFruitType
end

function AIImplement:setAIFruitRequirements(fruitType, minGrowthState, maxGrowthState)
	self:clearAIFruitRequirements()
	self:addAIFruitRequirement(fruitType, minGrowthState, maxGrowthState)
	self:updateFieldCropsQuery()
end

function AIImplement:addAIFruitRequirement(fruitType, minGrowthState, maxGrowthState)
	local spec = self.spec_aiImplement

	table.insert(spec.requiredFruitTypes, {
		fruitType = fruitType or 0,
		minGrowthState = minGrowthState or 0,
		maxGrowthState = maxGrowthState or 0
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAIFruitRequirements()
	local spec = self.spec_aiImplement

	if #spec.requiredFruitTypes > 0 then
		spec.requiredFruitTypes = {}
	end

	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitRequirements()
	return self.spec_aiImplement.requiredFruitTypes
end

function AIImplement:setAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
	self:clearAIFruitProhibitions()
	self:addAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
	self:updateFieldCropsQuery()
end

function AIImplement:addAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
	local spec = self.spec_aiImplement

	table.insert(spec.prohibitedFruitTypes, {
		fruitType = fruitType or 0,
		minGrowthState = minGrowthState or 0,
		maxGrowthState = maxGrowthState or 0
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAIFruitProhibitions()
	local spec = self.spec_aiImplement

	if #spec.prohibitedFruitTypes > 0 then
		spec.prohibitedFruitTypes = {}
	end

	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitProhibitions()
	return self.spec_aiImplement.prohibitedFruitTypes
end

function AIImplement:addAITerrainDetailRequiredRange(detailType1, detailType2, minState, maxState)
	table.insert(self.spec_aiImplement.terrainDetailRequiredValueRanges, {
		detailType1,
		detailType2,
		minState,
		maxState
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAITerrainDetailRequiredRange()
	self.spec_aiImplement.terrainDetailRequiredValueRanges = {}

	self:updateFieldCropsQuery()
end

function AIImplement:getAITerrainDetailRequiredRange()
	local spec = self.spec_aiImplement

	if spec.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, implement in ipairs(self:getAttachedImplements()) do
			if implement.object.getAITerrainDetailRequiredRange ~= nil then
				return implement.object:getAITerrainDetailRequiredRange()
			end
		end
	end

	return spec.terrainDetailRequiredValueRanges
end

function AIImplement:addAITerrainDetailProhibitedRange(detailType1, detailType2, minState, maxState)
	table.insert(self.spec_aiImplement.terrainDetailProhibitedValueRanges, {
		detailType1,
		detailType2,
		minState,
		maxState
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAITerrainDetailProhibitedRange()
	self.spec_aiImplement.terrainDetailProhibitedValueRanges = {}

	self:updateFieldCropsQuery()
end

function AIImplement:getAITerrainDetailProhibitedRange()
	local spec = self.spec_aiImplement

	if spec.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, implement in ipairs(self:getAttachedImplements()) do
			if implement.object.getAITerrainDetailProhibitedRange ~= nil then
				return implement.object:getAITerrainDetailProhibitedRange()
			end
		end
	end

	return spec.terrainDetailProhibitedValueRanges
end

function AIImplement:getFieldCropsQuery()
	if self.spec_aiImplement.fieldCropyQuery == nil then
		self:createFieldCropsQuery()
	end

	return self.spec_aiImplement.fieldCropyQuery
end

function AIImplement:updateFieldCropsQuery()
	if self.spec_aiImplement.fieldCropyQuery ~= nil then
		self:createFieldCropsQuery()
	end
end

function AIImplement:createFieldCropsQuery()
	local spec = self.spec_aiImplement
	local query = FieldCropsQuery:new(g_currentMission.terrainDetailId)
	local _, useWindrowFruitType = self:getAIFruitExtraRequirements()
	local fruitRequirements = self:getAIFruitRequirements()

	for i = 1, #fruitRequirements do
		local fruitRequirement = fruitRequirements[i]

		if fruitRequirement.fruitType ~= FruitType.UNKNOWN then
			local ids = g_currentMission.fruits[fruitRequirement.fruitType]

			if ids ~= nil and ids.id ~= 0 then
				if useWindrowFruitType then
					return 0, 1
				end

				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitRequirement.fruitType)

				query:addRequiredCropType(ids.id, fruitRequirement.minGrowthState + 1, fruitRequirement.maxGrowthState + 1, desc.startStateChannel, desc.numStateChannels, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			end
		end
	end

	local fruitProhibitions = self:getAIFruitProhibitions()

	for i = 1, #fruitProhibitions do
		local fruitProhibition = fruitProhibitions[i]

		if fruitProhibition.fruitType ~= FruitType.UNKNOWN then
			local ids = g_currentMission.fruits[fruitProhibition.fruitType]

			if ids ~= nil and ids.id ~= 0 then
				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitProhibition.fruitType)

				query:addProhibitedCropType(ids.id, fruitProhibition.minGrowthState + 1, fruitProhibition.maxGrowthState + 1, desc.startStateChannel, desc.numStateChannels, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			end
		end
	end

	local terrainDetailRequiredValueRanges = self:getAITerrainDetailRequiredRange()

	for i = 1, #terrainDetailRequiredValueRanges do
		local valueRange = terrainDetailRequiredValueRanges[i]

		query:addRequiredGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])
	end

	local terrainDetailProhibitValueRanges = self:getAITerrainDetailProhibitedRange()

	for i = 1, #terrainDetailProhibitValueRanges do
		local valueRange = terrainDetailProhibitValueRanges[i]

		query:addProhibitedGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])
	end

	spec.fieldCropyQuery = query
end

function AIImplement:getIsAIImplementInLine()
	return self.spec_aiImplement.isLineStarted
end

function AIImplement:aiImplementStartLine()
	self.spec_aiImplement.isLineStarted = true

	SpecializationUtil.raiseEvent(self, "onAIImplementStartLine")
	self:getRootVehicle().actionController:onAIEvent(self, "onAIImplementStartLine")
end

function AIImplement:aiImplementEndLine()
	self.spec_aiImplement.isLineStarted = false

	SpecializationUtil.raiseEvent(self, "onAIImplementEndLine")
	self:getRootVehicle().actionController:onAIEvent(self, "onAIImplementEndLine")
end
