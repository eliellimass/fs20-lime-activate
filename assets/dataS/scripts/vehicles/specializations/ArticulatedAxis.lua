ArticulatedAxis = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Drivable, specializations)
	end,
	registerEventListeners = function (vehicleType)
		SpecializationUtil.registerEventListener(vehicleType, "onLoad", ArticulatedAxis)
		SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ArticulatedAxis)
		SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ArticulatedAxis)
	end,
	onLoad = function (self, savegame)
		local xmlFile = self.xmlFile
		local spec = self.spec_articulatedAxis

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.articulatedAxis.rotatingPart(0)#index", "vehicle.articulatedAxis.rotatingPart(0)#node")

		local index = getXMLInt(xmlFile, "vehicle.articulatedAxis#componentJointIndex")

		if index ~= nil then
			if index == 0 then
				g_logManager:xmlWarning(self.configFileName, "Invalid component joint index '0' for articulatedAxis. Indices start with 1!")
			else
				local componentJoint = self.componentJoints[index]
				local rotSpeed = getXMLFloat(xmlFile, "vehicle.articulatedAxis#rotSpeed")
				local rotMax = getXMLFloat(xmlFile, "vehicle.articulatedAxis#rotMax")
				local rotMin = getXMLFloat(xmlFile, "vehicle.articulatedAxis#rotMin")

				if componentJoint ~= nil and rotSpeed ~= nil and rotMax ~= nil and rotMin ~= nil then
					spec.rotSpeed = math.rad(rotSpeed)
					spec.rotMax = math.rad(rotMax)
					spec.rotMin = math.rad(rotMin)
					spec.componentJoint = componentJoint
					spec.anchorActor = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.articulatedAxis#anchorActor"), 0)
					spec.rotationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.articulatedAxis#rotNode"), self.i3dMappings)

					if spec.rotationNode == nil then
						spec.rotationNode = spec.componentJoint.jointNode
					end

					spec.curRot = 0
					local i = 0
					spec.rotatingParts = {}

					while true do
						local key = string.format("vehicle.articulatedAxis.rotatingPart(%d)", i)

						if not hasXMLProperty(xmlFile, key) then
							break
						end

						local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

						if node ~= nil then
							local rotatingPart = {
								node = node,
								defRot = {
									getRotation(node)
								},
								posRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#posRot"), 3),
								negRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#negRot"), 3),
								negRotFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#negRotFactor"), 1),
								posRotFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#posRotFactor"), 1),
								invertSteeringAngle = Utils.getNoNil(getXMLBool(xmlFile, key .. "#invertSteeringAngle"), false)
							}

							table.insert(spec.rotatingParts, rotatingPart)
						else
							g_logManager:xmlWarning(self.configFileName, "Failed to load rotation part '%s'", key)
						end

						i = i + 1
					end

					local maxRotTime = rotMax / rotSpeed
					local minRotTime = rotMin / rotSpeed

					if maxRotTime < minRotTime then
						local temp = minRotTime
						minRotTime = maxRotTime
						maxRotTime = temp
					end

					if self.maxRotTime < maxRotTime then
						self.maxRotTime = maxRotTime
					end

					if minRotTime < self.minRotTime then
						self.minRotTime = minRotTime
					end

					self.maxRotation = rotMax
					self.wheelSteeringDuration = MathUtil.sign(rotSpeed) * rotMax / rotSpeed
					local aiReverserNodeString = getXMLString(xmlFile, "vehicle.articulatedAxis#aiRevereserNode")

					if aiReverserNodeString ~= nil then
						spec.aiRevereserNode = I3DUtil.indexToObject(self.components, aiReverserNodeString, self.i3dMappings)
					end

					local maxTurningRadius = 0
					local specWheels = self.spec_wheels

					for i = 1, 2 do
						local rootNode = self.components[componentJoint.componentIndices[i]].node

						for _, wheel in ipairs(specWheels.wheels) do
							if self:getParentComponent(wheel.repr) == rootNode then
								local wx, _, wz = localToLocal(wheel.driveNode, rootNode, 0, 0, 0)
								local dx1 = 1

								if wx < 0 then
									dx1 = -1
								end

								local dz1 = math.tan(math.max(wheel.rotMin, wheel.rotMax))

								if wz > 0 then
									dz1 = -dz1
								end

								local x2 = 0
								local z2 = 0
								local dx2 = 1

								if wx < 0 then
									dx2 = -1
								end

								local dz2 = math.tan(math.max(rotMin, rotMax))

								if wz < 0 then
									dz2 = -dz2
								end

								local l1 = MathUtil.vector2Length(dx1, dz1)
								dz1 = dz1 / l1
								dx1 = dx1 / l1
								local l2 = MathUtil.vector2Length(dx2, dz2)
								dz2 = dz2 / l2
								dx2 = dx2 / l2
								local intersect, _, f2 = MathUtil.getLineLineIntersection2D(wx, wz, dx1, dz1, x2, z2, dx2, dz2)

								if intersect then
									local radius = math.abs(f2)
									maxTurningRadius = math.max(maxTurningRadius, radius)
								end
							end
						end
					end

					if maxTurningRadius ~= 0 then
						self.maxTurningRadius = maxTurningRadius
					end
				end
			end
		end

		spec.interpolatedRotatedTime = 0
	end,
	onPostLoad = function (self)
		local spec = self.spec_articulatedAxis

		if spec.componentJoint ~= nil and self.updateArticulatedAxisRotation ~= nil then
			self:updateArticulatedAxisRotation(0, 99999)
		end
	end,
	onUpdate = function (self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		local spec = self.spec_articulatedAxis

		if spec.componentJoint ~= nil then
			if spec.interpolatedRotatedTime < self.rotatedTime then
				spec.interpolatedRotatedTime = math.min(self.rotatedTime, spec.interpolatedRotatedTime + math.abs(spec.rotSpeed) * dt / 500)
			elseif self.rotatedTime < spec.interpolatedRotatedTime then
				spec.interpolatedRotatedTime = math.max(self.rotatedTime, spec.interpolatedRotatedTime - math.abs(spec.rotSpeed) * dt / 500)
			end

			local steeringAngle = MathUtil.clamp(self.rotatedTime * spec.rotSpeed, spec.rotMin, spec.rotMax)

			if self.updateArticulatedAxisRotation ~= nil then
				steeringAngle = self:updateArticulatedAxisRotation(steeringAngle, dt)
			end

			if math.abs(steeringAngle - spec.curRot) > 1e-06 then
				if self.isServer then
					setRotation(spec.rotationNode, 0, steeringAngle, 0)
					self:setComponentJointFrame(spec.componentJoint, spec.anchorActor)

					spec.curRot = steeringAngle
				end

				if self.isClient then
					local percent = 0

					if steeringAngle > 0 then
						percent = steeringAngle / spec.rotMax
					elseif steeringAngle < 0 then
						percent = steeringAngle / spec.rotMin
					end

					for _, rotPart in pairs(spec.rotatingParts) do
						local rx, ry, rz = nil

						if steeringAngle > 0 and not rotPart.invertSteeringAngle or steeringAngle < 0 and rotPart.invertSteeringAngle then
							rx, ry, rz = MathUtil.vector3ArrayLerp(rotPart.defRot, rotPart.posRot, math.min(1, percent * rotPart.posRotFactor))
						else
							rx, ry, rz = MathUtil.vector3ArrayLerp(rotPart.defRot, rotPart.negRot, math.min(1, percent * rotPart.negRotFactor))
						end

						setRotation(rotPart.node, rx, ry, rz)

						if self.setMovingToolDirty ~= nil then
							self:setMovingToolDirty(rotPart.node)
						end
					end
				end
			end
		end
	end
}
