PlacementUtil = {
	TEST_HEIGHT = 50,
	TEST_STEP_SIZE = 1
}

function PlacementUtil.getPlace(places, sizeX, sizeZ, offsetX, offsetZ, usage, includeDynamics, includeStatics, doExactTest)
	for _, place in pairs(places) do
		if sizeX <= place.maxWidth and sizeZ <= place.maxLength then
			local placeUsage = usage[place]

			if placeUsage == nil then
				placeUsage = 0
			end

			local halfSizeX = sizeX * 0.5

			for width = placeUsage + halfSizeX, place.width - halfSizeX, PlacementUtil.TEST_STEP_SIZE do
				local x = place.startX + width * place.dirX
				local y = place.startY + width * place.dirY
				local z = place.startZ + width * place.dirZ
				local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
				y = math.max(terrainHeight + 0.5, y)
				PlacementUtil.tempHasCollision = false

				overlapBox(x, y, z, place.rotX, place.rotY, place.rotZ, sizeX * 0.5, PlacementUtil.TEST_HEIGHT * 0.5, sizeZ * 0.5, "PlacementUtil.collisionTestCallback", nil, 528895, includeDynamics, includeStatics, doExactTest)

				if not PlacementUtil.tempHasCollision then
					local vehicleX = x + offsetX * place.dirX - offsetZ * place.dirPerpX
					local vehicleY = y + offsetX * place.dirY - offsetZ * place.dirPerpY
					local vehicleZ = z + offsetX * place.dirZ - offsetZ * place.dirPerpZ
					local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
					y = math.max(terrainHeight + place.yOffset, y)

					return vehicleX, vehicleY, vehicleZ, place, width + halfSizeX, y - terrainHeight
				end
			end
		end
	end

	return nil
end

function PlacementUtil.markPlaceUsed(usage, place, width)
	usage[place] = width
end

function PlacementUtil.unmarkPlaceUsed(usage, place)
	usage[place] = nil
end

function PlacementUtil:collisionTestCallback(transformId)
	if g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil or g_currentMission:getNodeObject(transformId) ~= nil then
		PlacementUtil.tempHasCollision = true

		return false
	end

	return true
end

function PlacementUtil.createPlace(id)
	local place = {}
	place.startX, place.startY, place.startZ = getWorldTranslation(id)
	place.rotX, place.rotY, place.rotZ = getWorldRotation(id)
	place.dirX, place.dirY, place.dirZ = localDirectionToWorld(id, 1, 0, 0)
	place.dirPerpX, place.dirPerpY, place.dirPerpZ = localDirectionToWorld(id, 0, 0, 1)
	place.yOffset = Utils.getNoNil(getUserAttribute(id, "yOffset"), 1)
	place.maxWidth = Utils.getNoNil(getUserAttribute(id, "maxWidth"), math.huge)
	place.maxLength = Utils.getNoNil(getUserAttribute(id, "maxLength"), math.huge)

	if getNumOfChildren(id) > 0 then
		local x, _, _ = getTranslation(getChildAt(id, 0))
		place.width = math.abs(x)

		if x < 0 then
			place.dirX = -place.dirX
			place.dirY = -place.dirY
			place.dirZ = -place.dirZ
		end
	else
		place.width = 0.1
	end

	return place
end

function PlacementUtil.createRestrictedZone(id)
	local restrictedZone = {}
	restrictedZone.x, _, restrictedZone.z = getWorldTranslation(id)

	if getNumOfChildren(id) > 0 then
		local x, _, z = getTranslation(getChildAt(id, 0))
		restrictedZone.width = math.abs(x)
		restrictedZone.length = math.abs(z)

		if x < 0 then
			restrictedZone.x = restrictedZone.x + x
		end

		if z < 0 then
			restrictedZone.z = restrictedZone.z + z
		end
	else
		restrictedZone.width = 1
		restrictedZone.length = 1
	end

	return restrictedZone
end

function PlacementUtil.isInsideRestrictedZone(restrictedZones, placeable, x, y, z)
	for _, restrictedZone in pairs(restrictedZones) do
		local dx = restrictedZone.x + restrictedZone.width - x
		local dz = restrictedZone.z + restrictedZone.length - z

		if dx > 0 and dx < restrictedZone.width and dz > 0 and dz < restrictedZone.length then
			return true
		end
	end

	if y < g_currentMission.waterY - 0.5 then
		return true
	end

	return false
end

function PlacementUtil.isInsidePlacementPlaces(places, placeable, x, y, z)
	local distanceLimit = 10 + math.sqrt(placeable.placementTestSizeX * placeable.placementTestSizeX * 0.25 + placeable.placementTestSizeZ * placeable.placementTestSizeZ * 0.25)

	for _, place in pairs(places) do
		local dx = place.dirX
		local dz = place.dirZ
		local sx = place.startX
		local sz = place.startZ
		local width = place.width
		local t = (x - sx) * dx + (z - sz) * dz
		local distance = nil

		if t >= 0 and t <= width then
			distance = math.abs((sz - z) * dx - (sx - x) * dz)
		elseif t < 0 then
			distance = math.sqrt((sx - x) * (sx - x) + (sz - z) * (sz - z))
		else
			local ex = place.startX + width * dx
			local ez = place.startZ + width * dz
			distance = math.sqrt((ex - x) * (ex - x) + (ez - z) * (ez - z))
		end

		if distance < distanceLimit then
			return true
		end
	end

	return false
end

local callbackTarget = {
	hasOverlap = false
}

function callbackTarget:overlapCallback(transformId)
	self.hasOverlap = transformId ~= g_currentMission.terrainRootNode

	if self.hasOverlap then
		return false
	end
end

function PlacementUtil.hasObjectOverlap(placeable, x, y, z, rotY)
	local distX = placeable.placementTestSizeX * 0.5
	local distZ = placeable.placementTestSizeZ * 0.5
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
	local normX, _, normZ = MathUtil.crossProduct(0, 1, 0, dirX, 0, dirZ)
	x = x + dirX * placeable.placementTestSizeOffsetZ + normX * placeable.placementTestSizeOffsetX
	z = z + dirZ * placeable.placementTestSizeOffsetZ + normZ * placeable.placementTestSizeOffsetX

	overlapBox(x, y, z, 0, rotY, 0, distX, 15, distZ, "overlapCallback", callbackTarget, nil, true, true, true)

	local hasOverlap = false

	if callbackTarget.hasOverlap then
		hasOverlap = true
	else
		local startX, startZ, widthX, widthZ, heightX, heightZ = PlacementUtil.parallelogramFromTest(placeable, x, z, rotY)
		local density = DensityMapHeightUtil.getValueAtArea(startX, startZ, startX + widthX, startZ + widthZ, startX + heightX, startZ + heightZ)
		hasOverlap = density > 0
	end

	return hasOverlap
end

function PlacementUtil.hasOverlapWithPoint(placeable, x, y, z, rotY, pointX, pointZ)
	local startX, startZ, widthX, widthZ, heightX, heightZ = PlacementUtil.parallelogramFromTest(placeable, x, z, rotY)

	if VehicleDebug.state == VehicleDebug.DEBUG then
		DebugUtil.drawDebugParallelogram(startX, startZ, widthX, widthZ, heightX, heightZ, 0, 1, 0, 0, 0.5)
	end

	return MathUtil.isPointInParallelogram(pointX, pointZ, startX, startZ, widthX, widthZ, heightX, heightZ)
end

function PlacementUtil.parallelogramFromTest(placeable, x, z, rotY)
	local distX = placeable.placementTestSizeX * 0.5
	local distZ = placeable.placementTestSizeZ * 0.5
	local v1x = distX * math.cos(rotY)
	local v1z = distZ * math.sin(rotY)
	local v2x = distX * math.cos(rotY - 0.5 * math.pi)
	local v2z = distZ * math.sin(rotY - 0.5 * math.pi)
	local startX = x - v1x - v2x
	local startZ = z - v1z - v2z
	local widthX = v2x * 2
	local widthZ = v2z * 2
	local heightX = v1x * 2
	local heightZ = v1z * 2

	return startX, startZ, widthX, widthZ, heightX, heightZ
end

function PlacementUtil.loadPlaceableFromXML(xmlFilename, x, y, z, rx, ry, rz, moveMode, ownerFarmId)
	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	local placeableType = getXMLString(xmlFile, "placeable.placeableType")

	delete(xmlFile)

	local placeable = nil
	local hasNoSpace = false

	if placeableType ~= nil then
		placeable, hasNoSpace = PlacementUtil.loadPlaceable(placeableType, xmlFilename, x, y, z, rx, ry, rz, moveMode, ownerFarmId)
	end

	return placeable, hasNoSpace
end

function PlacementUtil.loadPlaceable(placeableType, xmlFilename, x, y, z, rx, ry, rz, moveMode, ownerFarmId)
	local classObject = g_placeableTypeManager:getClassObjectByTypeName(placeableType)

	if classObject == nil then
		local modName, _ = Utils.getModNameAndBaseDirectory(xmlFilename)

		if modName ~= nil then
			placeableType = modName .. "." .. placeableType
			classObject = g_placeableTypeManager:getClassObjectByTypeName(placeableType)
		end
	end

	local placeable = nil

	if classObject ~= nil then
		placeable = classObject:new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
	else
		print("Error: Invalid placeable type '" .. placeableType .. "'")
	end

	local hasNoSpace = false

	if placeable ~= nil then
		placeable:setOwnerFarmId(ownerFarmId, true)

		if placeable:load(xmlFilename, x, y, z, rx, ry, rz) then
			if not moveMode then
				assert(g_currentMission:getIsServer())

				if PlacementUtil.isInsidePlacementPlaces(g_currentMission.storeSpawnPlaces, placeable, x, y, z) or PlacementUtil.isInsidePlacementPlaces(g_currentMission.loadSpawnPlaces, placeable, x, y, z) or PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, placeable, x, y, z) or PlacementUtil.hasObjectOverlap(placeable, x, y, z, ry) then
					placeable:delete()

					placeable = nil
					hasNoSpace = true
				end
			end
		else
			print("Error: Failed to load placeable '" .. xmlFilename .. "'")
			placeable:delete()

			placeable = nil
		end
	end

	return placeable, hasNoSpace
end

function PlacementUtil.getPlaceableAreaByNodes(startNode, widthNode, heightNode)
	local worldStartX, worldStartY, worldStartZ = getWorldTranslation(startNode)
	local worldSide1X, worldSide1Y, worldSide1Z = getWorldTranslation(widthNode)
	local worldSide2X, worldSide2Y, worldSide2Z = getWorldTranslation(heightNode)
	local side1X = worldSide1X - worldStartX
	local side1Y = worldSide1Y - worldStartY
	local side1Z = worldSide1Z - worldStartZ
	local side2X = worldSide2X - worldStartX
	local side2Y = worldSide2Y - worldStartY
	local side2Z = worldSide2Z - worldStartZ

	return {
		worldStartX,
		worldStartY,
		worldStartZ,
		side1X,
		side1Y,
		side1Z,
		side2X,
		side2Y,
		side2Z
	}
end
