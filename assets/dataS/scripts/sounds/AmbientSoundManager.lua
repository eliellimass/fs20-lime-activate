AmbientSoundManager = {
	DEBUG = false,
	BITMASK_INDOOR = 1,
	BITMASK_DAY = 2,
	BITMASK_HAIL = 4,
	BITMASK_RAIN = 8,
	BITMASK_INSIDE_BUILDING = 16
}
local AmbientSoundManager_mt = Class(AmbientSoundManager, AbstractManager)

function AmbientSoundManager:new(customMt)
	local self = AbstractManager:new(customMt or AmbientSoundManager_mt)

	return self
end

function AmbientSoundManager:initDataStructures()
	self.ambient3DSounds = {}
	self.nodeToSoundNode = {}
	self.nodeToPolyChain = {}
	self.polyChains = {}
	self.rootNode = nil
	self.lastGrid = nil
	self.ambientXmlFilename = nil
	self.ambient3DFilename = nil
	self.initialized = false
	self.numOfAmbient3DSounds = 0
	self.blocksPerRowColumn = 8
end

function AmbientSoundManager:loadMapData(xmlFile, missionInfo)
	AmbientSoundManager:superClass().loadMapData(self)

	local xmlFilename = Utils.getFilename(getXMLString(xmlFile, "map.sounds#filename"), g_currentMission.baseDirectory)

	if xmlFile == nil or xmlFilename == nil then
		return false
	end

	local soundXmlFile = loadXMLFile("ambientSoundsXML", xmlFilename)

	if soundXmlFile == nil or soundXmlFile == 0 then
		g_logManager:xmlWarning(xmlFilename, "Warning: AmbientSounds could not load xmlFile!")

		return false
	end

	self.initialized = true
	self.mapSoundGrid = MapDataGrid:new(g_currentMission.mapWidth, self.blocksPerRowColumn)

	for i = 1, self.blocksPerRowColumn do
		for j = 1, self.blocksPerRowColumn do
			self.mapSoundGrid:setValue(i, j, {})
		end
	end

	self.ambientXmlFilename = xmlFilename
	local filename = getXMLString(soundXmlFile, "sound.ambient3d#filename")

	if filename ~= nil then
		local ambient3DFilename = Utils.getFilename(filename, g_currentMission.baseDirectory)
		self.ambient3DFilename = ambient3DFilename
	end

	self:loadAmbientSounds()

	self.indoorVolumeFactor = getXMLFloat(soundXmlFile, "sound.ambient3d#indoorVolumeFactor") or 1
	self.indoorLowpassGainFactor = getXMLFloat(soundXmlFile, "sound.ambient3d#indoorLowpassGainFactor") or 1

	if g_addCheatCommands then
		addConsoleCommand("gsReloadAmbientSounds", "Reload ambient sound system", "consoleCommandReloadAmbientSound", self)
		addConsoleCommand("gsToggleAmbientSoundsDebug", "Toggles ambient sound system debugging", "consoleCommandToggleAmbientSoundsDebug", self)
	end

	delete(soundXmlFile)

	return true
end

function AmbientSoundManager:unloadMapData()
	if self.initialized then
		removeConsoleCommand("gsReloadAmbientSounds")
		removeConsoleCommand("gsToggleAmbientSoundsDebug")
		self:deleteAmbientSounds()
		self.mapSoundGrid:delete()
	end

	AmbientSoundManager:superClass().unloadMapData(self)
end

function AmbientSoundManager:loadAmbientSounds()
	self.isAmbientSoundEnabled = true
	self.currentState = false

	if g_soundPlayer ~= nil then
		loadAmbientSound(g_soundPlayer.soundPlayerId, self.ambientXmlFilename, AudioGroup.ENVIRONMENT)
	end

	if self.ambient3DFilename ~= nil then
		local i3dNode = loadI3DFile(self.ambient3DFilename, false, true, false)

		if i3dNode ~= 0 and i3dNode ~= nil then
			self.rootNode = createTransformGroup("sound3DRootNode")

			link(getRootNode(), self.rootNode)

			for i = getNumOfChildren(i3dNode), 1, -1 do
				local child = getChildAt(i3dNode, i - 1)

				link(self.rootNode, child)
			end

			delete(i3dNode)
		end
	end
end

function AmbientSoundManager:deleteAmbientSounds()
	for _, soundNode in ipairs(self.ambient3DSounds) do
		soundNode:delete()
	end

	self.ambient3DSounds = {}

	if g_soundPlayer ~= nil then
		unloadAmbientSound(g_soundPlayer.soundPlayerId)
	end

	if self.rootNode ~= nil then
		delete(self.rootNode)
	end

	self:initDataStructures()
end

function AmbientSoundManager:getState()
	local worldStateFlags = 0
	local playerActive = g_currentMission.player ~= nil and g_currentMission.player.isControlled
	local isIndoor = false

	if g_soundManager:getIsIndoor() and not playerActive then
		isIndoor = true
		worldStateFlags = bitOR(worldStateFlags, AmbientSoundManager.BITMASK_INDOOR)
	end

	local isInsideBuilding = false

	if g_soundManager:getIsInsideBuilding() then
		isInsideBuilding = true
		worldStateFlags = bitOR(worldStateFlags, AmbientSoundManager.BITMASK_INSIDE_BUILDING)
	end

	local environment = g_currentMission.environment
	local dayTime = environment.dayTime
	local nightEndTime = 60000 * environment.nightEndMinutes
	local nightStartTime = 60000 * environment.nightStartMinutes
	local isDay = nightEndTime < dayTime and dayTime < nightStartTime

	if isDay then
		worldStateFlags = bitOR(worldStateFlags, AmbientSoundManager.BITMASK_DAY)
	end

	local isRain = false

	if environment.weather:getIsRaining() then
		worldStateFlags = bitOR(worldStateFlags, AmbientSoundManager.BITMASK_RAIN)
		isRain = true
	end

	local isHail = false
	local isSun = not isRain and not isHail

	return worldStateFlags, isIndoor, isInsideBuilding, isDay, isRain, isHail, isSun, dayTime
end

function AmbientSoundManager:update(dt)
	if not self.initialized then
		return
	end

	local currentState = self.isAmbientSoundEnabled and not g_gui:getIsGuiVisible()

	if currentState ~= self.currentState then
		self.currentState = currentState

		if g_soundPlayer ~= nil then
			setEnableAmbientSound(g_soundPlayer.soundPlayerId, currentState)
		end
	end

	if not currentState then
		return
	end

	local worldStateFlags, isIndoor, isInsideBuilding, isDay, isRain, isHail, isSun, dayTime, extra = self:getState()

	if g_soundPlayer ~= nil then
		updateAmbientSound(g_soundPlayer.soundPlayerId, dt, worldStateFlags)
	end

	local camera = getCamera()
	local x, _, z = getWorldTranslation(camera)
	local currentGrid, rowIndex, columnIndex = self.mapSoundGrid:getValueAtWorldPos(x, z)

	if currentGrid ~= self.lastGrid and self.lastGrid ~= nil then
		for _, soundNode in pairs(self.lastGrid) do
			if currentGrid[soundNode] == nil then
				soundNode:reset()
			end
		end
	end

	if currentGrid ~= nil then
		for _, soundNode in pairs(currentGrid) do
			soundNode:update(dt, isDay, isSun, isRain, isHail, isIndoor, isInsideBuilding, dayTime, extra)
		end
	end

	for _, item in ipairs(self.polyChains) do
		local cx, cy, cz = item.polyChain:getClosestPoint(getWorldTranslation(getCamera()))

		if cx ~= nil and cy ~= nil and cz ~= nil then
			for i = #item.soundNodes, 1, -1 do
				local soundNode = self.nodeToSoundNode[item.soundNodes[i]]

				if soundNode ~= nil then
					soundNode:setWorldPosition(cx, cy, cz)
				else
					g_logManager:xmlWarning("Removing node %s from polychain updater. Not a soundnode!", getName(item.soundNodes[i]))
					table.remove(self.nodeToSoundNode, i)
				end
			end
		end
	end

	self.lastGrid = currentGrid

	if AmbientSoundManager.DEBUG then
		for _, item in ipairs(self.polyChains) do
			item.polyChain:drawDebug(1, 0, 0)

			local x, y, z = item.polyChain:getClosestPoint(getWorldTranslation(getCamera()))

			DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, 0, 0, 1, 0, 1, 0, "p")
		end

		local data = {}

		table.insert(data, {
			name = "isDay",
			value = isDay
		})
		table.insert(data, {
			name = "isHail",
			value = isHail
		})
		table.insert(data, {
			name = "isRain",
			value = isRain
		})
		table.insert(data, {
			name = "isSun",
			value = isSun
		})
		table.insert(data, {
			name = "isIndoor",
			value = isIndoor
		})
		table.insert(data, {
			name = "isInsideBuilding",
			value = isInsideBuilding
		})
		table.insert(data, {
			name = "Section Row",
			value = rowIndex
		})
		table.insert(data, {
			name = "Section Column",
			value = columnIndex
		})
		DebugUtil.renderTable(0.1, 0.98, 0.012, data)

		local activeSounds = {}
		local i = 0

		for _, soundNode in pairs(currentGrid) do
			DebugUtil.drawDebugNode(soundNode.parent, string.format("%s - Radius: %d", getName(soundNode.parent), soundNode.outerRange), false)

			local distance = calcDistanceFrom(getCamera(), soundNode.parent)

			table.insert(activeSounds, {
				name = "distance",
				value = distance
			})
			table.insert(activeSounds, {
				name = "outerRange",
				value = soundNode.outerRange
			})
			table.insert(activeSounds, {
				value = "",
				name = ""
			})
			table.insert(activeSounds, {
				name = "inRange",
				value = distance < soundNode.outerRange
			})
			table.insert(activeSounds, {
				name = "ID/OD Volume Factor",
				value = isIndoor and self.indoorVolumeFactor or 1
			})
			table.insert(activeSounds, {
				value = "",
				name = ""
			})
			table.insert(activeSounds, {
				name = "group",
				value = getName(soundNode.parent)
			})
			table.insert(activeSounds, {
				name = "NextIn",
				value = string.format("%d", math.max(0, soundNode.nextPlayTime - g_time))
			})
			table.insert(activeSounds, {
				value = "",
				name = ""
			})

			for _, node in ipairs(soundNode.nodes) do
				table.insert(activeSounds, {
					name = getName(node.node),
					value = string.format("%s - Volume: %.2f", tostring(isSamplePlaying(node.sample)), node.volume)
				})
			end

			table.insert(activeSounds, {
				value = "",
				name = ""
			})
			table.insert(activeSounds, {
				name = "playByDay",
				value = soundNode.playByDay
			})
			table.insert(activeSounds, {
				name = "playByNight",
				value = soundNode.playByNight
			})
			table.insert(activeSounds, {
				name = "playDuringSun",
				value = soundNode.playDuringSun
			})
			table.insert(activeSounds, {
				name = "playDuringRain",
				value = soundNode.playDuringRain
			})
			table.insert(activeSounds, {
				name = "playDuringHail",
				value = soundNode.playDuringHail
			})
			table.insert(activeSounds, {
				name = "playExterior",
				value = soundNode.playExterior
			})
			table.insert(activeSounds, {
				name = "playInterior",
				value = soundNode.playInterior
			})
			table.insert(activeSounds, {
				name = "playInsideBuilding",
				value = soundNode.playInsideBuilding
			})
			table.insert(activeSounds, {
				name = "playHour",
				value = soundNode.playHour
			})
			table.insert(activeSounds, {
				name = "playHourStart",
				value = soundNode.playHourStart / 60 / 60 / 1000
			})
			table.insert(activeSounds, {
				name = "playHourEnd",
				value = soundNode.playHourEnd / 60 / 60 / 1000
			})
			table.insert(activeSounds, {
				name = "playHourInverted",
				value = soundNode.playHourInverted
			})
			table.insert(activeSounds, {
				value = "",
				name = ""
			})
			table.insert(activeSounds, {
				value = "-------------------",
				name = "----------------",
				newColumn = i % 3 == 0
			})

			i = i + 1
		end

		DebugUtil.renderTable(0.25, 0.98, 0.011, activeSounds, 0.15)
	end
end

function AmbientSoundManager:enableAmbientSound(isEnabled)
	self.isAmbientSoundEnabled = isEnabled
end

function AmbientSoundManager:addSound3d(node)
	if not self.initialized then
		return
	end

	if node == nil then
		return
	end

	if not getHasClassId(node, ClassIds.AUDIO_SOURCE) then
		print("Warning: " .. tostring(getName(node)) .. " is not an AUDIO_SOURCE!")

		return
	end

	local soundNode = SoundNode:new(node, AudioGroup.ENVIRONMENT)

	if soundNode ~= nil then
		self:addSoundNodeToGrid(soundNode)
		table.insert(self.ambient3DSounds, soundNode)

		self.numOfAmbient3DSounds = #self.ambient3DSounds
		self.nodeToSoundNode[soundNode.parent] = soundNode

		for _, node in ipairs(soundNode.nodes) do
			self.nodeToSoundNode[node.node] = soundNode
		end

		if self.nodeToPolyChain[node] ~= nil then
			self:updatePolyChainGrid(self.nodeToPolyChain[node], soundNode)
		end
	end
end

function AmbientSoundManager:addPolygonChain(node)
	if not self.initialized then
		return
	end

	if getNumOfChildren(node) < 2 then
		return
	end

	local chain = getChildAt(node, 0)
	local nodes = getChildAt(node, 1)
	local polyChain = PolygonChain:new()
	local soundNodes = {}

	for i = 0, getNumOfChildren(chain) - 1 do
		local controlNode = getChildAt(chain, i)

		polyChain:addControlNode(controlNode)
	end

	for i = 0, getNumOfChildren(nodes) - 1 do
		local soundNode = getChildAt(nodes, i)
		self.nodeToPolyChain[soundNode] = polyChain

		table.insert(soundNodes, soundNode)
	end

	table.insert(self.polyChains, {
		polyChain = polyChain,
		soundNodes = soundNodes
	})
end

function AmbientSoundManager:addSoundNodeToGrid(soundNode)
	local x, _, z = soundNode:getWorldPosition()
	local value, rowIndex, colIndex = self.mapSoundGrid:getValueAtWorldPos(x, z)

	if value == nil then
		value = {}

		self.mapSoundGrid:setValue(rowIndex, colIndex, value)
	end

	value[soundNode] = soundNode

	for rowIndex = 1, self.blocksPerRowColumn do
		for colIndex = 1, self.blocksPerRowColumn do
			local minX, maxX, minZ, maxZ = self.mapSoundGrid:getBoundaries(rowIndex, colIndex)

			if self:intersectsWithGrid(minX, maxX, minZ, maxZ, x, z, soundNode.outerRange) then
				self:addSoundToGrid(soundNode, rowIndex, colIndex)
			end
		end
	end
end

function AmbientSoundManager:addSoundToGrid(soundNode, rowIndex, colIndex)
	local value = self.mapSoundGrid:getValue(rowIndex, colIndex)

	if value == nil then
		value = {}

		self.mapSoundGrid:setValue(rowIndex, colIndex, value)
	end

	value[soundNode] = soundNode
end

function AmbientSoundManager:intersectsWithGrid(minX, maxX, minZ, maxZ, x, z, range)
	return MathUtil.vector2Length(minX - x, minZ - z) < range or MathUtil.vector2Length(minX - x, minZ - z) < range or MathUtil.vector2Length(minX - x, maxZ - z) < range or MathUtil.vector2Length(maxX - x, maxZ - z) < range or MathUtil.getHasCircleLineIntersection(x, z, range, minX, minZ, maxX, minZ) or MathUtil.getHasCircleLineIntersection(x, z, range, minX, minZ, minX, maxZ) or MathUtil.getHasCircleLineIntersection(x, z, range, minX, maxZ, maxX, maxZ) or MathUtil.getHasCircleLineIntersection(x, z, range, maxX, minZ, maxX, maxZ)
end

function AmbientSoundManager:updatePolyChainGrid(polyChain, soundNode)
	local startX, startY, startZ = nil

	for _, node in ipairs(polyChain.controlNodes) do
		local endX, endY, endZ = getWorldTranslation(node)

		if startX ~= nil then
			local dirX, dirY, dirZ = MathUtil.vector3Normalize(endX - startX, endY - endY, endZ - startZ)
			local nX, _, nZ = MathUtil.vector3Normalize(MathUtil.crossProduct(dirX, dirY, dirZ, 0, 1, 0))
			local range = soundNode.outerRange
			local startX1 = startX + nX * range
			local startZ1 = startZ + nZ * range
			local endX1 = endX + nX * range
			local endZ1 = endZ + nZ * range
			local startX2 = startX - nX * range
			local startZ2 = startZ - nZ * range
			local endX2 = endX - nX * range
			local endZ2 = endZ - nZ * range

			for rowIndex = 1, 8 do
				for colIndex = 1, 8 do
					local minX, maxX, minZ, maxZ = self.mapSoundGrid:getBoundaries(rowIndex, colIndex)

					if MathUtil.getHaveLineSegementsIntersection2D(minX, minZ, maxX, minZ, startX1, startZ1, endX1, endZ1) or MathUtil.getHaveLineSegementsIntersection2D(minX, minZ, maxX, minZ, startX2, startZ2, endX2, endZ2) or MathUtil.getHaveLineSegementsIntersection2D(minX, minZ, minX, maxZ, startX1, startZ1, endX1, endZ1) or MathUtil.getHaveLineSegementsIntersection2D(minX, minZ, minX, maxZ, startX2, startZ2, endX2, endZ2) or MathUtil.getHaveLineSegementsIntersection2D(minX, maxZ, maxX, maxZ, startX1, startZ1, endX1, endZ1) or MathUtil.getHaveLineSegementsIntersection2D(minX, maxZ, maxX, maxZ, startX2, startZ2, endX2, endZ2) or MathUtil.getHaveLineSegementsIntersection2D(maxX, minZ, maxX, maxZ, startX1, startZ1, endX1, endZ1) or MathUtil.getHaveLineSegementsIntersection2D(maxX, minZ, maxX, maxZ, startX2, startZ2, endX2, endZ2) or self:intersectsWithGrid(minX, maxX, minZ, maxZ, endX, endZ, range) then
						self:addSoundToGrid(soundNode, rowIndex, colIndex)
					end
				end
			end
		end

		startZ = endZ
		startY = endY
		startX = endX
	end
end

function AmbientSoundManager:consoleCommandReloadAmbientSound()
	local ambientXmlFilename = self.ambientXmlFilename
	local ambient3DFilename = self.ambient3DFilename

	self:deleteAmbientSounds()

	self.initialized = true
	self.mapSoundGrid = MapDataGrid:new(g_currentMission.mapWidth, self.blocksPerRowColumn)

	for i = 1, self.blocksPerRowColumn do
		for j = 1, self.blocksPerRowColumn do
			self.mapSoundGrid:setValue(i, j, {})
		end
	end

	self.ambientXmlFilename = ambientXmlFilename
	self.ambient3DFilename = ambient3DFilename

	self:loadAmbientSounds()
end

function AmbientSoundManager:consoleCommandToggleAmbientSoundsDebug()
	AmbientSoundManager.DEBUG = not AmbientSoundManager.DEBUG

	return "AmbientSoundDebug " .. tostring(AmbientSoundManager.DEBUG)
end

g_ambientSoundManager = AmbientSoundManager:new()
