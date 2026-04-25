ExtendedBaleLoader = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(BaleLoader, specializations)
	end
}

function ExtendedBaleLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoint", ExtendedBaleLoader.createBaleToBaleJoint)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentFoldingAnimation", ExtendedBaleLoader.getCurrentFoldingAnimation)
end

function ExtendedBaleLoader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doStateChange", ExtendedBaleLoader.doStateChange)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "playAnimation", ExtendedBaleLoader.playAnimation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAnimationPlaying", ExtendedBaleLoader.getIsAnimationPlaying)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAnimationTime", ExtendedBaleLoader.getAnimationTime)
end

function ExtendedBaleLoader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedBaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedBaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedBaleLoader)
end

function ExtendedBaleLoader:onLoad(savegame)
	local spec = self.spec_baleLoader
	spec.baleJoints = {}
	spec.foldingAnimations = {}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.baleLoader.foldingAnimations.foldingAnimation(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseKey) then
			break
		end

		local entry = {
			name = getXMLString(self.xmlFile, baseKey .. "#name"),
			minFillLevel = getXMLFloat(self.xmlFile, baseKey .. "#minFillLevel") or -math.huge,
			maxFillLevel = getXMLFloat(self.xmlFile, baseKey .. "#maxFillLevel") or math.huge,
			minBalePlace = getXMLFloat(self.xmlFile, baseKey .. "#minBalePlace") or -math.huge,
			maxBalePlace = getXMLFloat(self.xmlFile, baseKey .. "#maxBalePlace") or math.huge
		}

		if entry.name ~= nil then
			table.insert(spec.foldingAnimations, entry)
		end

		i = i + 1
	end

	spec.useCustomTransportToWorkAnimation = #spec.foldingAnimations > 0
	spec.joinBalesTogetherDuringUnload = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.baleLoader#joinBalesTogetherDuringUnload"), true)

	if savegame ~= nil and not savegame.resetVehicles then
		spec.lastFoldingAnimation = getXMLString(savegame.xmlFile, savegame.key .. ".pdlc_andersonPack.extendedBaleLoader#lastFoldingAnimation")
		spec.loadingIsFinished = false
	end
end

function ExtendedBaleLoader:onPostLoad(savegame)
	local spec = self.spec_baleLoader
	spec.loadingIsFinished = true
end

function ExtendedBaleLoader:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_baleLoader

	if spec.lastFoldingAnimation ~= nil then
		setXMLString(xmlFile, key .. "#lastFoldingAnimation", spec.lastFoldingAnimation)
	end
end

function ExtendedBaleLoader:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if self.isServer and not self:getIsAnimationPlaying("releaseFrontplattform") and #spec.baleJoints > 0 then
		for _, jointIndex in ipairs(spec.baleJoints) do
			removeJoint(jointIndex)
		end

		spec.baleJoints = {}
	end
end

function ExtendedBaleLoader:doStateChange(superFunc, id, nearestBaleServerId)
	local spec = self.spec_baleLoader

	if not spec.joinBalesTogetherDuringUnload or not self.isServer then
		superFunc(self, id, nearestBaleServerId)

		return
	end

	local baleLines = {}

	if id == BaleLoader.CHANGE_DROP_BALES then
		for _, balePlace in pairs(spec.balePlaces) do
			if balePlace.bales ~= nil then
				local i = 1

				for _, baleServerId in pairs(balePlace.bales) do
					local bale = NetworkUtil.getObject(baleServerId)

					if bale ~= nil then
						if baleLines[i] == nil then
							table.insert(baleLines, {
								bale
							})
						else
							table.insert(baleLines[i], bale)
						end
					end

					i = i + 1
				end
			end
		end
	end

	superFunc(self, id, nearestBaleServerId)

	if id == BaleLoader.CHANGE_DROP_BALES and #baleLines > 1 then
		local lineRotLimit = math.rad(2)
		local sideRotLimit = math.rad(1)

		for li, line in ipairs(baleLines) do
			local isRoundbale = line[1].baleDiameter ~= nil

			if isRoundbale then
				for i = 1, #line - 1 do
					self:createBaleToBaleJoint(line[i], line[i + 1], 0, 0.1, line[i].baleWidth + 0.025, lineRotLimit, 0, 0, i)
				end

				if li == 1 then
					local line2 = baleLines[li + 1]

					if line2 ~= nil then
						self:createBaleToBaleJoint(line[1], line2[1], line[1].baleDiameter + 0.05, 0.1, 0, sideRotLimit, sideRotLimit, sideRotLimit, 1)

						if #line == #line2 then
							self:createBaleToBaleJoint(line[#line], line2[#line2], line[#line].baleDiameter + 0.05, 0.1, 0, sideRotLimit, sideRotLimit, sideRotLimit, #line2)
						end
					end
				end
			elseif #baleLines > 1 then
				for i = 1, #line - 1 do
					local topBale = baleLines[li + 1][i]

					if topBale ~= nil then
						self:createBaleToBaleJoint(line[i], topBale, 0, line[1].baleHeight + 0.05, 0, lineRotLimit, 0, 0, i)
					end
				end

				for i = 1, #line - 1 do
					self:createBaleToBaleJoint(line[i], line[i + 1], line[i].baleWidth + 0.2, 0.05, 0, 0, 0, lineRotLimit * 5, i)
				end

				break
			end
		end
	end
end

function ExtendedBaleLoader:createBaleToBaleJoint(bale1, bale2, x, y, z, rx, ry, rz, balePlaceIndex)
	local spec = self.spec_baleLoader
	local balePlaceRot = spec.balePlaces[balePlaceIndex].node
	local constr = JointConstructor:new()

	constr:setActors(bale1.nodeId, bale2.nodeId)

	local jointTransform1 = createTransformGroup("jointTransform1")

	link(bale1.nodeId, jointTransform1)
	setRotation(jointTransform1, localRotationToLocal(balePlaceRot, bale1.nodeId, 0, 0, 0))

	local jointTransform2 = createTransformGroup("jointTransform2")

	link(bale2.nodeId, jointTransform2)
	setRotation(jointTransform2, localRotationToLocal(balePlaceRot, bale2.nodeId, 0, 0, 0))
	constr:setJointTransforms(jointTransform1, jointTransform2)
	constr:setEnableCollision(true)
	constr:setRotationLimit(0, -rx, rx)
	constr:setRotationLimit(1, -ry, ry)
	constr:setRotationLimit(2, -rz, rz)
	constr:setTranslationLimit(0, true, -x, x)
	constr:setTranslationLimit(1, true, -y, y)
	constr:setTranslationLimit(2, true, -z, z)

	local jointIndex = constr:finalize()

	table.insert(spec.baleJoints, jointIndex)
end

function ExtendedBaleLoader:playAnimation(superFunc, name, speed, animTime, noEventSend)
	local spec = self.spec_baleLoader

	if spec.useCustomTransportToWorkAnimation and name == "baleGrabberTransportToWork" then
		name = self:getCurrentFoldingAnimation()
	end

	return superFunc(self, name, speed, animTime, noEventSend)
end

function ExtendedBaleLoader:getIsAnimationPlaying(superFunc, name)
	local spec = self.spec_baleLoader

	if spec.useCustomTransportToWorkAnimation and name == "baleGrabberTransportToWork" then
		name = self:getCurrentFoldingAnimation()
	end

	return superFunc(self, name)
end

function ExtendedBaleLoader:getAnimationTime(superFunc, name)
	local spec = self.spec_baleLoader

	if spec.useCustomTransportToWorkAnimation and name == "baleGrabberTransportToWork" then
		name = self:getCurrentFoldingAnimation()
	end

	return superFunc(self, name)
end

function ExtendedBaleLoader:getCurrentFoldingAnimation()
	local spec = self.spec_baleLoader

	if not spec.loadingIsFinished then
		return spec.lastFoldingAnimation
	end

	local name = spec.foldingAnimations[1].name
	local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
	local balePlace = #spec.startBalePlace.bales

	for _, foldingAnimation in ipairs(spec.foldingAnimations) do
		if foldingAnimation.minFillLevel <= fillLevel and fillLevel <= foldingAnimation.maxFillLevel and foldingAnimation.minBalePlace <= balePlace and balePlace <= foldingAnimation.maxBalePlace then
			name = foldingAnimation.name

			break
		end
	end

	if name ~= spec.lastFoldingAnimation then
		if spec.lastFoldingAnimation ~= nil then
			local animTime = self:getAnimationTime(spec.lastFoldingAnimation)

			self:setAnimationTime(name, animTime, false)
		end

		spec.lastFoldingAnimation = name
	end

	return name
end
