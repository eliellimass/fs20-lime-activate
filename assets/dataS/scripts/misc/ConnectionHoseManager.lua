ConnectionHoseType = nil
ConnectionHoseManager = {
	DEFAULT_HOSES_FILENAME = "data/shared/connectionHoses/connectionHoses.xml"
}
local ConnectionHoseManager_mt = Class(ConnectionHoseManager, AbstractManager)

function ConnectionHoseManager:new(customMt)
	local self = AbstractManager:new(customMt or ConnectionHoseManager_mt)

	self:initDataStructures()

	return self
end

function ConnectionHoseManager:initDataStructures()
	self.typeByName = {}
	ConnectionHoseType = self.typeByName
	self.basicHoses = {}
	self.sockets = {}
end

function ConnectionHoseManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	ConnectionHoseManager:superClass().loadMapData(self)
	self:loadConnectionHosesFromXML(ConnectionHoseManager.DEFAULT_HOSES_FILENAME)
end

function ConnectionHoseManager:unloadMapData()
	for _, entry in ipairs(self.basicHoses) do
		delete(entry.node)
	end

	for _, hoseType in pairs(self.typeByName) do
		for _, adapter in pairs(hoseType.adapters) do
			delete(adapter.node)
		end

		for _, hose in pairs(hoseType.hoses) do
			delete(hose.materialNode)
		end
	end

	for _, entry in pairs(self.sockets) do
		delete(entry.node)
	end

	ConnectionHoseManager:superClass().unloadMapData(self)
end

function ConnectionHoseManager:loadConnectionHosesFromXML(xmlFilename)
	local xmlFile = loadXMLFile("TempHoses", xmlFilename)

	if xmlFile ~= nil then
		local i = 0

		while true do
			local hoseKey = string.format("connectionHoses.basicHoses.basicHose(%d)", i)

			if not hasXMLProperty(xmlFile, hoseKey) then
				break
			end

			local filename = getXMLString(xmlFile, hoseKey .. "#filename")

			if filename ~= nil then
				local hoseFileRoot = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

				if hoseFileRoot ~= nil and hoseFileRoot ~= 0 then
					local node = I3DUtil.indexToObject(hoseFileRoot, getXMLString(xmlFile, hoseKey .. "#node"))

					if node ~= nil then
						unlink(node)

						local entry = {
							node = node,
							startStraightening = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#startStraightening"), 2),
							endStraightening = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#endStraightening"), 2),
							minCenterPointAngle = Utils.getNoNilRad(getXMLFloat(xmlFile, hoseKey .. "#minCenterPointAngle"), math.rad(90))
						}
						local length = getXMLFloat(xmlFile, hoseKey .. "#length")

						if length == nil then
							print(string.format("Warning: Missing length attribute in '%s'", hoseKey))
						end

						local realLength = getXMLFloat(xmlFile, hoseKey .. "#realLength")

						if realLength == nil then
							print(string.format("Warning: Missing realLength attribute in '%s'", hoseKey))
						end

						local diameter = getXMLFloat(xmlFile, hoseKey .. "#diameter")

						if diameter == nil then
							print(string.format("Warning: Missing diameter attribute in '%s'", hoseKey))
						end

						if length ~= nil and realLength ~= nil and diameter ~= nil then
							entry.length = length
							entry.realLength = realLength
							entry.diameter = diameter

							table.insert(self.basicHoses, entry)
						end
					end

					delete(hoseFileRoot)
				end
			end

			i = i + 1
		end

		i = 0

		while true do
			local key = string.format("connectionHoses.connectionHoseTypes.connectionHoseType(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local name = getXMLString(xmlFile, key .. "#name")

			if name ~= nil then
				local hoseType = {
					name = name,
					adapters = {}
				}
				local j = 0

				while true do
					local adapterKey = string.format("%s.adapter(%d)", key, j)

					if not hasXMLProperty(xmlFile, adapterKey) then
						break
					end

					local adapterName = Utils.getNoNil(getXMLString(xmlFile, adapterKey .. "#name"), "DEFAULT")
					local filename = getXMLString(xmlFile, adapterKey .. "#filename")

					if filename ~= nil then
						local adapterFileRoot = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

						if adapterFileRoot ~= nil and adapterFileRoot ~= 0 then
							local node = I3DUtil.indexToObject(adapterFileRoot, getXMLString(xmlFile, adapterKey .. "#node"))
							local hoseReferenceNode = getChildAt(node, 0)

							unlink(node)

							if hoseReferenceNode ~= 0 then
								local entry = {
									node = node,
									hoseReferenceNode = hoseReferenceNode
								}
								hoseType.adapters[adapterName] = entry
							else
								print(string.format("Warning: Missing hose reference node as child from adapter '%s' in connection type '%s'", adapterName, name))
							end

							delete(adapterFileRoot)
						end
					end

					j = j + 1
				end

				hoseType.hoses = {}
				j = 0

				while true do
					local hoseKey = string.format("%s.material(%d)", key, j)

					if not hasXMLProperty(xmlFile, hoseKey) then
						break
					end

					local hoseName = Utils.getNoNil(getXMLString(xmlFile, hoseKey .. "#name"), "DEFAULT")
					local filename = getXMLString(xmlFile, hoseKey .. "#filename")

					if filename ~= nil then
						local adapterFileRoot = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

						if adapterFileRoot ~= nil and adapterFileRoot ~= 0 then
							local materialNode = I3DUtil.indexToObject(adapterFileRoot, getXMLString(xmlFile, hoseKey .. "#materialNode"))

							unlink(materialNode)

							if materialNode ~= nil then
								local entry = {
									materialNode = materialNode,
									defaultColor = StringUtil.getVectorNFromString(getXMLString(xmlFile, hoseKey .. "#defaultColor"), 4),
									uvOffset = StringUtil.getVectorNFromString(getXMLString(xmlFile, hoseKey .. "#uvOffset"), 2),
									uvScale = StringUtil.getVectorNFromString(getXMLString(xmlFile, hoseKey .. "#uvScale"), 2)
								}
								hoseType.hoses[hoseName] = entry
							end

							delete(adapterFileRoot)
						end
					end

					j = j + 1
				end

				self:addConnectionHoseType(name, hoseType)
			end

			i = i + 1
		end

		i = 0

		while true do
			local socketKey = string.format("connectionHoses.sockets.socket(%d)", i)

			if not hasXMLProperty(xmlFile, socketKey) then
				break
			end

			local name = getXMLString(xmlFile, socketKey .. "#name")
			local filename = getXMLString(xmlFile, socketKey .. "#filename")

			if name ~= nil and filename ~= nil then
				local socketFileRoot = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

				if socketFileRoot ~= nil and socketFileRoot ~= 0 then
					local node = I3DUtil.indexToObject(socketFileRoot, getXMLString(xmlFile, socketKey .. "#node"))

					if node ~= nil then
						unlink(node)

						local entry = {
							node = node,
							referenceNode = getXMLString(xmlFile, socketKey .. "#referenceNode"),
							cabs = {}
						}
						local j = 0

						while true do
							local cabKey = string.format(socketKey .. ".cab(%d)", j)

							if not hasXMLProperty(xmlFile, cabKey) then
								break
							end

							local cab = {
								node = getXMLString(xmlFile, cabKey .. "#node")
							}

							if cab.node ~= nil then
								cab.openedRotation = StringUtil.getRadiansFromString(getXMLString(xmlFile, cabKey .. "#openedRotation"), 3)
								cab.closedRotation = StringUtil.getRadiansFromString(getXMLString(xmlFile, cabKey .. "#closedRotation"), 3)
								cab.openedVisibility = Utils.getNoNil(getXMLBool(xmlFile, cabKey .. "#openedVisibility"), true)
								cab.closedVisibility = Utils.getNoNil(getXMLBool(xmlFile, cabKey .. "#closedVisibility"), true)

								table.insert(entry.cabs, cab)
							end

							j = j + 1
						end

						self.sockets[name:lower()] = entry
					end

					delete(socketFileRoot)
				end
			end

			i = i + 1
		end

		delete(xmlFile)
	end
end

function ConnectionHoseManager:addConnectionHoseType(name, desc)
	name = name:upper()

	if self.typeByName[name] == nil then
		self.typeByName[name] = desc
	else
		print(string.format("Warning: connection hose type '%s' already exits!", name))
	end
end

function ConnectionHoseManager:getClonedAdapterNode(typeName, adapterName)
	typeName = typeName:upper()
	adapterName = adapterName:upper()

	if self.typeByName[typeName] ~= nil then
		local adapter = self.typeByName[typeName].adapters[adapterName]

		if adapter ~= nil then
			local adapterNodeClone = clone(adapter.node, true)
			local hoseReferenceNodeClone = getChildAt(adapterNodeClone, 0)

			return adapterNodeClone, hoseReferenceNodeClone
		end
	end
end

function ConnectionHoseManager:getClonedHoseNode(typeName, hoseName, length, diameter, color)
	typeName = typeName:upper()
	hoseName = hoseName:upper()

	if self.typeByName[typeName] ~= nil then
		local hose = self.typeByName[typeName].hoses[hoseName]

		if hose ~= nil then
			local hoseNodeClone, realLength, startStraightening, endStraightening, minCenterPointAngle, closestDiameter = self:getClonedBasicHose(length, diameter)

			if hoseNodeClone ~= nil then
				local material = getMaterial(hose.materialNode, 0)

				setMaterial(hoseNodeClone, material, 0)

				if color ~= nil or hose.defaultColor ~= nil then
					for i = 1, 8 do
						local parameter = string.format("colorMat%d", i - 1)

						if getHasShaderParameter(hoseNodeClone, parameter) then
							local r, g, b, _ = unpack(color or hose.defaultColor)
							local _, _, _, w = getShaderParameter(hoseNodeClone, parameter)

							setShaderParameter(hoseNodeClone, parameter, r, g, b, w, false)
						end
					end
				end

				local _, y, z, w = getShaderParameter(hoseNodeClone, "lengthAndDiameter")

				setShaderParameter(hoseNodeClone, "lengthAndDiameter", realLength, diameter / closestDiameter, z, w, false)

				local scaleFactorX = 1
				local scaleFactorY = 1

				if hose.uvScale ~= nil then
					scaleFactorY = hose.uvScale[2]
					scaleFactorX = hose.uvScale[1]
				end

				_, y, z, w = getShaderParameter(hoseNodeClone, "uvScale")

				setShaderParameter(hoseNodeClone, "uvScale", length / realLength * scaleFactorX, y * scaleFactorY, z, w, false)

				if hose.uvOffset ~= nil then
					_, _, z, w = getShaderParameter(hoseNodeClone, "offsetUV")

					setShaderParameter(hoseNodeClone, "offsetUV", hose.uvOffset[1], hose.uvOffset[2], z, w, false)
				end

				return hoseNodeClone, startStraightening, endStraightening, minCenterPointAngle
			end
		end
	end
end

function ConnectionHoseManager:getClonedBasicHose(length, diameter)
	local minDiameterDiff = math.huge
	local closestDiameter = math.huge

	for _, hose in pairs(self.basicHoses) do
		local diff = math.abs(hose.diameter - diameter)

		if diff < minDiameterDiff then
			minDiameterDiff = diff
			closestDiameter = hose.diameter
		end
	end

	local foundHoses = {}

	for _, hose in pairs(self.basicHoses) do
		local diff = math.abs(hose.diameter - closestDiameter)

		if diff <= 0.0001 then
			table.insert(foundHoses, hose)
		end
	end

	local minLengthDiff = math.huge
	local foundHose = nil

	for _, hose in pairs(foundHoses) do
		local diff = math.abs(hose.length - length)

		if diff < minLengthDiff then
			minLengthDiff = diff
			foundHose = hose
		end
	end

	if foundHose ~= nil then
		return clone(foundHose.node, true), foundHose.realLength, foundHose.startStraightening, foundHose.endStraightening, foundHose.minCenterPointAngle, closestDiameter
	end
end

function ConnectionHoseManager:linkSocketToNode(socketName, node)
	local socket = self.sockets[socketName:lower()]

	if socket ~= nil and node ~= nil then
		local linkedSocket = {
			node = clone(socket.node, true)
		}
		linkedSocket.referenceNode = I3DUtil.indexToObject(linkedSocket.node, socket.referenceNode)
		linkedSocket.cabs = {}

		for _, cab in ipairs(socket.cabs) do
			local clonedCab = {}

			for i, v in pairs(cab) do
				clonedCab[i] = v
			end

			clonedCab.node = I3DUtil.indexToObject(linkedSocket.node, clonedCab.node)

			table.insert(linkedSocket.cabs, clonedCab)
		end

		link(node, linkedSocket.node)
		self:closeSocket(linkedSocket)

		return linkedSocket
	end
end

function ConnectionHoseManager:getSocketTarget(socket, defaultTarget)
	if socket ~= nil and socket.referenceNode ~= nil then
		return socket.referenceNode
	end

	return defaultTarget
end

function ConnectionHoseManager:openSocket(socket)
	if socket ~= nil and #socket.cabs > 0 then
		for _, cab in ipairs(socket.cabs) do
			if cab.openedRotation ~= nil then
				setRotation(cab.node, unpack(cab.openedRotation))
			end

			setVisibility(cab.node, cab.openedVisibility)
		end
	end
end

function ConnectionHoseManager:closeSocket(socket)
	if socket ~= nil and #socket.cabs > 0 then
		for _, cab in ipairs(socket.cabs) do
			if cab.openedRotation ~= nil then
				setRotation(cab.node, unpack(cab.closedRotation))
			end

			setVisibility(cab.node, cab.closedVisibility)
		end
	end
end

g_connectionHoseManager = ConnectionHoseManager:new()
