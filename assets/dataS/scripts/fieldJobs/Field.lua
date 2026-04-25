Field = {}
local Field_mt = Class(Field)

function Field:new(customMt)
	local self = {}

	setmetatable(self, customMt or Field_mt)

	self.fieldId = 0
	self.posX = 0
	self.posZ = 0
	self.rootNode = nil
	self.name = nil
	self.mapHotspot = nil
	self.fieldMissionAllowed = true
	self.fieldGrassMission = false
	self.fieldAngle = 0
	self.fieldDimensions = nil
	self.fieldArea = 1
	self.getFieldStatusPartitions = {}
	self.setFieldStatusPartitions = {}
	self.maxFieldStatusPartitions = {}
	self.isAIActive = true
	self.fruitType = nil
	self.lastCheckedTime = nil
	self.currentMission = nil

	return self
end

function Field:load(id)
	self.rootNode = id
	self.name = Utils.getNoNil(getUserAttribute(id, "name"), "")
	self.fieldMissionAllowed = Utils.getNoNil(getUserAttribute(id, "fieldMissionAllowed"), true)
	self.fieldGrassMission = Utils.getNoNil(getUserAttribute(id, "fieldGrassMission"), false)
	local fieldDimensions = I3DUtil.indexToObject(id, getUserAttribute(id, "fieldDimensionIndex"))

	if fieldDimensions == nil then
		print("Warning: No fieldDimensionIndex defined for Field '" .. getName(id) .. "'!")

		return false
	end

	local angleRad = math.rad(Utils.getNoNil(tonumber(getUserAttribute(id, "fieldAngle")), 0))
	self.fieldAngle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.terrainDetailAngleMaxValue)
	self.fieldDimensions = fieldDimensions

	FieldUtil.updateFieldPartitions(self, self.getFieldStatusPartitions, 900)
	FieldUtil.updateFieldPartitions(self, self.setFieldStatusPartitions, 400)
	FieldUtil.updateFieldPartitions(self, self.maxFieldStatusPartitions, 10000000)

	self.posX, self.posZ = FieldUtil.getCenterOfField(self)
	self.nameIndicator = I3DUtil.indexToObject(id, getUserAttribute(id, "nameIndicatorIndex"))

	if self.nameIndicator ~= nil then
		local x, _, z = getWorldTranslation(self.nameIndicator)
		self.posZ = z
		self.posX = x
	end

	self.farmland = nil

	return true
end

function Field:delete()
	if self.mapHotspot == nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end
end

function Field:getCenterOfFieldWorldPosition()
	return self.posX, self.posZ
end

function Field:setFarmland(farmland)
	self.farmland = farmland
end

function Field:updateOwnership()
	self:setFieldOwned(g_farmlandManager:getFarmlandOwner(self.farmland.id))
end

function Field:setFieldId(fieldId)
	self.fieldId = fieldId
end

function Field:addMapHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end

	local _, textSize = getNormalizedScreenValues(0, 9)
	local _, textOffsetY = getNormalizedScreenValues(0, 7)
	local mapHotspot = MapHotspot:new("field", MapHotspot.CATEGORY_FIELD_DEFINITION)

	if GS_IS_MOBILE_VERSION then
		mapHotspot:setIcon(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_FIELD_BUY, nil, , {
			0.2705,
			0.6514,
			0.0802,
			1
		})

		local width, height = getNormalizedScreenValues(35, 35)

		mapHotspot:setSize(width, height)
		mapHotspot:setText("")
	else
		mapHotspot:setText(tostring(self.fieldId))
		mapHotspot:setTextOffset(0, self.mapHotspot.textSize)
		mapHotspot:setSize(0, 0)
	end

	mapHotspot:setWorldPosition(self.posX, self.posZ)
	mapHotspot:setAssociatedData(self.fieldId)

	self.mapHotspot = mapHotspot

	g_currentMission:addMapHotspot(mapHotspot)
end

function Field:setFieldOwned(farmId)
	self:updateHotspotColor(farmId)

	self.isAIActive = farmId == FarmlandManager.NO_OWNER_FARM_ID
end

function Field:updateHotspotColor(farmId)
	local mapHotspot = self.mapHotspot

	if mapHotspot ~= nil then
		if farmId ~= FarmlandManager.NO_OWNER_FARM_ID then
			local farm = g_farmManager:getFarmById(farmId)

			if farm ~= nil then
				local color = Utils.getNoNil(farm:getColor(), {
					1,
					1,
					1,
					1
				})

				if GS_IS_MOBILE_VERSION then
					color = {
						1,
						1,
						1,
						1
					}

					mapHotspot:setIcon(nil)
					mapHotspot:setText(tostring(self.fieldId))
					mapHotspot:setTextOffset(0, self.mapHotspot.textSize)
					mapHotspot:setSize(0, 0)
					mapHotspot:setTextColorSelected({
						0.2705,
						0.6514,
						0.0802,
						1
					})
				end

				mapHotspot:setTextBold(true)
				mapHotspot:setTextColor(color)
			end
		else
			mapHotspot:setTextBold(false)
			mapHotspot:setTextColor({
				1,
				1,
				1,
				1
			})
		end
	end
end

function Field:activate()
	self:setFieldOwned(FarmlandManager.NO_OWNER_FARM_ID)
end

function Field:deactivate()
	self:setFieldOwned(g_farmlandManager:getFarmlandOwner(self.farmland.id))
	g_missionManager:cancelMissionOnField(self)
end

function Field:getIsAIActive()
	return self.isAIActive
end
