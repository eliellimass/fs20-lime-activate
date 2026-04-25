Chainsaw = {}
local Chainsaw_mt = Class(Chainsaw, HandTool)

InitStaticObjectClass(Chainsaw, "Chainsaw", ObjectIds.OBJECT_CHAINSAW)

Chainsaw.CAMERA_TRANSITION_STATES = {
	CUT = 1,
	IN = 0,
	OUT = 2,
	NONE = -1
}
Chainsaw.SOUND_STATES = {
	CUT = 5,
	START = 1,
	IDLE = 3,
	QUICKTAP = 6,
	STOP = 2,
	ACTIVE = 4
}

function Chainsaw:new(isServer, isClient, customMt)
	local self = HandTool:new(isServer, isClient, customMt or Chainsaw_mt)

	return self
end

function Chainsaw:load(xmlFilename, player)
	if not Chainsaw:superClass().load(self, xmlFilename, player) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.rotateInput = 0
	self.activatePressed = false
	self.eventIdRotateHandtool = ""
	self.rotationZ = 0
	self.rotationSpeedZ = 0.003
	self.cutSizeY = 1.1
	self.cutSizeZ = 1
	self.isCutting = false
	self.waitingForResetAfterCut = false
	self.cutNode = getChildAt(self.rootNode, 0)
	self.graphicsNode = getChildAt(self.cutNode, 0)
	self.chainNode = getChildAt(self.graphicsNode, 0)
	self.psNode = getChildAt(self.graphicsNode, 1)
	self.cutPositionNode = getChildAt(self.graphicsNode, 5)
	self.pricePerSecond = Utils.getNoNil(getXMLFloat(xmlFile, "handTool.chainsaw.pricePerMinute"), 50) / 1000
	self.quicktapThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "handTool.chainsaw#quicktapThreshold"), 0) * 1000

	if self.isClient then
		self.particleSystems = {}
		local i = 0

		while true do
			local keyPS = string.format("handTool.chainsaw.particleSystems.emitterShape(%d)", i)

			if not hasXMLProperty(xmlFile, keyPS) then
				break
			end

			local emitterShape = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, keyPS .. "#node"))
			local particleType = getXMLString(xmlFile, keyPS .. "#particleType")

			if emitterShape ~= nil then
				local fillType = FillType.WOODCHIPS
				local particleSystem = g_particleSystemManager:getParticleSystem(fillType, particleType)

				if particleSystem ~= nil then
					table.insert(self.particleSystems, ParticleUtil.copyParticleSystem(xmlFile, keyPS, particleSystem, emitterShape))
				end
			end

			i = i + 1
		end

		if #self.particleSystems == 0 then
			self.particleSystems = nil
		end

		self.equipmentUVs = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.chainsaw.equipment#uvs"), "0 0"), 2)
		self.chains = g_animationManager:loadAnimations(xmlFile, "handTool.chainsaw.chain", self.rootNode, self, nil)
		self.samples = {
			start = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "start", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			idle = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "idle", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, ),
			cutStart = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "cutStart", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			cutStop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "cutStop", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			cutLoop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "cutLoop", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, ),
			activeStart = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "activeStart", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			activeStop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "activeStop", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			activeLoop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "activeLoop", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, )
		}

		player:loadHandToolStopSample(xmlFile, "handTool.chainsaw.sounds", "stop")

		self.samplesQuicktap = {}
		local j = 0

		while true do
			local sampleQuicktap = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds.quickTapSounds", string.format("quickTap(%d)", j), self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, )

			if sampleQuicktap == nil then
				break
			end

			table.insert(self.samplesQuicktap, sampleQuicktap)

			j = j + 1
		end

		self.samplesQuicktapCount = j
		self.samplesTree = {
			cut = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.treeSounds", "cut", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, )
		}
		self.samplesBranch = {}
		local k = 0

		while true do
			local sampleBranch = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.branchSounds", string.format("branch(%d)", k), self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, )

			if sampleBranch == nil then
				break
			end

			table.insert(self.samplesBranch, sampleBranch)

			k = k + 1
		end

		self.samplesBranchCount = k
		self.samplesBranchActiveTimer = 0
		self.samplesTreeLinkNode = createTransformGroup("cutSoundLinkNode")

		link(self.cutNode, self.samplesTreeLinkNode)

		if self.samplesTree.cut ~= nil and self.samplesTree.cut.soundNode ~= nil then
			link(self.samplesTreeLinkNode, self.samplesTree.cut.soundNode)
		end

		self.soundFSM = FSMUtil.create()

		self.soundFSM:addState(Chainsaw.SOUND_STATES.START, ChainsawSoundStateStart:new(Chainsaw.SOUND_STATES.START, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.STOP, ChainsawSoundStateStop:new(Chainsaw.SOUND_STATES.STOP, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.IDLE, ChainsawSoundStateIdle:new(Chainsaw.SOUND_STATES.IDLE, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.ACTIVE, ChainsawSoundStateActive:new(Chainsaw.SOUND_STATES.ACTIVE, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.CUT, ChainsawSoundStateCut:new(Chainsaw.SOUND_STATES.CUT, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.QUICKTAP, ChainsawSoundStateQuicktap:new(Chainsaw.SOUND_STATES.QUICKTAP, self, self.soundFSM))

		local filename = getXMLString(xmlFile, "handTool.chainsaw.ringSelector#file")

		if filename ~= nil then
			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				self.ringSelectorFilename = filename
				self.ringSelector = getChildAt(i3dNode, 0)
				self.ringSelectorScaleOffset = Utils.getNoNil(getXMLFloat(xmlFile, "handTool.chainsaw.ringSelector#scaleOffset"), 0.3)

				setVisibility(self.ringSelector, false)
				link(player.chainsawSplitShapeFocus, self.ringSelector)
				delete(i3dNode)
			end
		end
	end

	if self.player ~= g_currentMission.player then
		self.handNodePositionInCutting = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.handNode.thirdPersonCutting#position"), "0 0 0"), 3)
		self.handNodeRotationInCutting = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.handNode.thirdPersonCutting#rotation"), "0 0 0"), 3)
		self.referenceNodeInCutting = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, "handTool.handNode.thirdPersonCutting#referenceNode"))
	end

	self.lastWorkTime = 0
	self.maxWorkTime = 300
	self.moveSpeedY = 0.0001
	self.speedFactor = 0
	self.defaultCutDuration = 8
	self.maxTrunkWidthSq = 1
	self.outDuration = 0.15
	self.inDuration = 0.15
	self.cutTimer = 0
	self.outTimer = self.outDuration
	self.transitionAlpha = 0
	self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.NONE
	self.minRotationZ = math.rad(90)
	self.maxRotationZ = math.rad(-90)
	self.maxModelTranslation = 0
	self.cutFocusDistance = -1
	self.startCameraDirectionY = {
		0,
		1,
		0
	}
	self.startCameraDirectionZ = {
		0,
		0,
		1
	}
	self.endCameraDirectionY = {
		0,
		1,
		0
	}
	self.endCameraDirectionZ = {
		0,
		0,
		1
	}
	self.startChainsawPosition = {
		0,
		0,
		0
	}
	self.endChainsawPosition = {
		0,
		0,
		0
	}
	self.showNotOwnedWarning = false
	self.isCutting = false
	self.isHorizontalCut = false

	delete(xmlFile)

	return true
end

function Chainsaw:delete()
	if self.isClient then
		ParticleUtil.deleteParticleSystems(self.particleSystems)

		if self.ringSelector ~= nil then
			delete(self.ringSelector)
		end

		g_soundManager:deleteSamples(self.samplesTree)
		g_soundManager:deleteSamples(self.samplesBranch)
		g_soundManager:deleteSamples(self.samples)
		g_soundManager:deleteSamples(self.samplesQuicktap)

		if self.ringSelectorFilename ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.ringSelectorFilename, self.baseDirectory, false)
		end

		g_animationManager:deleteAnimations(self.chains)
	end

	Chainsaw:superClass().delete(self)
end

function Chainsaw:cutRaycastCallback(hitObjectId, x, y, z, distance)
	setWorldTranslation(self.player.chainsawCameraFocus, x, y, z)

	self.cutFocusDistance = distance
end

function Chainsaw:updateCutRaycast()
	self.cutFocusDistance = -1

	setTranslation(self.player.chainsawCameraFocus, 0, 0, 0)

	local cameraPosition = {
		getWorldTranslation(self.player.cameraNode)
	}
	local worldDirection = {
		unProject(0.52, 0.4, 1)
	}
	local treeCollisionMask = 16789504
	worldDirection[1], worldDirection[2], worldDirection[3] = MathUtil.vector3Normalize(worldDirection[1], worldDirection[2], worldDirection[3])

	raycastClosest(cameraPosition[1], cameraPosition[2], cameraPosition[3], worldDirection[1], worldDirection[2], worldDirection[3], "cutRaycastCallback", self.player.cutDetectionDistance, self, treeCollisionMask)
end

function Chainsaw:testTooLow(shape, minY, maxY, minZ, maxZ)
	local cutTooLow = false
	local _, y1, _ = localToLocal(self.player.chainsawSplitShapeFocus, shape, 0, minY, minZ)
	local _, y3, _ = localToLocal(self.player.chainsawSplitShapeFocus, shape, 0, maxY, minZ)
	local _, y4, _ = localToLocal(self.player.chainsawSplitShapeFocus, shape, 0, maxY, maxZ)
	cutTooLow = y1 < 0.01 or y1 < 0.01 or y3 < 0.03 or y4 < 0.01

	if not cutTooLow then
		local x1, y1, z1 = localToWorld(self.player.chainsawSplitShapeFocus, 0, minY, minZ)
		local x2, y2, z2 = localToWorld(self.player.chainsawSplitShapeFocus, 0, minY, maxZ)
		local x3, y3, z3 = localToWorld(self.player.chainsawSplitShapeFocus, 0, maxY, minZ)
		local x4, y4, z4 = localToWorld(self.player.chainsawSplitShapeFocus, 0, maxY, maxZ)
		local h1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, y1, z1)
		local h2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, y2, z2)
		local h3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, y3, z3)
		local h4 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x4, y4, z4)
		cutTooLow = h1 < 0.01 or h2 < 0.01 or h3 < 0.03 or h4 < 0.01
	end

	if cutTooLow then
		return true
	end

	return false
end

function Chainsaw:getLookAt(cameraNode, targetX, targetY, targetZ)
	local xx = 0
	local xy = 0
	local xz = 0
	local yx = 0
	local yy = 0
	local yz = 0
	local zx = 0
	local zy = 0
	local zz = 0
	local nodePosition = {
		getWorldTranslation(cameraNode)
	}
	local nodeUpDirection = {
		localDirectionToWorld(getParent(cameraNode), 0, -1, 0)
	}
	zx = nodePosition[1] - targetX
	zy = nodePosition[2] - targetY
	zz = nodePosition[3] - targetZ
	zx, zy, zz = MathUtil.vector3Normalize(zx, zy, zz)
	xx, xy, xz = MathUtil.crossProduct(zx, zy, zz, nodeUpDirection[1], nodeUpDirection[2], nodeUpDirection[3])
	xx, xy, xz = MathUtil.vector3Normalize(xx, xy, xz)
	yx, yy, yz = MathUtil.crossProduct(zx, zy, zz, xx, xy, xz)
	yx, yy, yz = MathUtil.vector3Normalize(yx, yy, yz)

	return yx, yy, yz, zx, zy, zz
end

function Chainsaw:getCutStartEnd()
	local selectorPosition = {
		getWorldTranslation(self.ringSelector)
	}
	local selectorScale = {
		getScale(self.ringSelector)
	}
	local cutDirection = {
		localDirectionToWorld(self.ringSelector, 0, 1, 0)
	}
	local cutStartposition = {
		selectorPosition[1] - 0.5 * selectorScale[1] * cutDirection[1],
		selectorPosition[2] - 0.5 * selectorScale[2] * cutDirection[2],
		selectorPosition[3] - 0.5 * selectorScale[3] * cutDirection[3]
	}
	local cutEndposition = {
		selectorPosition[1] + 0.5 * selectorScale[1] * cutDirection[1],
		selectorPosition[2] + 0.5 * selectorScale[2] * cutDirection[2],
		selectorPosition[3] + 0.5 * selectorScale[3] * cutDirection[3]
	}

	return cutStartposition[1], cutStartposition[2], cutStartposition[3], cutEndposition[1], cutEndposition[2], cutEndposition[3]
end

function Chainsaw:calculateCutDuration()
	local startX, startY, startZ, endX, endY, endZ = self:getCutStartEnd()
	local trunkWidthSq = MathUtil.vector3LengthSq(endX - startX, endY - startY, endZ - startZ)
	trunkWidthSq = MathUtil.clamp(trunkWidthSq, 0, self.maxTrunkWidthSq)
	local cutDuration = trunkWidthSq * self.defaultCutDuration / self.maxTrunkWidthSq

	return cutDuration
end

function Chainsaw:updateCuttingTimers(dt, isCutting)
	local dtInSec = dt * 0.001
	self.transitionAlpha = 0

	if isCutting then
		local cutDuration = self:calculateCutDuration()

		if self.cutTimer == 0 then
			self.outTimer = 0
			self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.IN
		elseif self.cutTimer == self.inDuration then
			self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.CUT
		end

		if self.cutTimer >= 0 and self.cutTimer < self.inDuration then
			self.cutTimer = math.min(self.cutTimer + dtInSec, self.inDuration)
			self.transitionAlpha = MathUtil.clamp(self.cutTimer, 0, self.inDuration) / self.inDuration
		elseif self.inDuration <= self.cutTimer and self.cutTimer < cutDuration then
			local restCutDuration = math.max(cutDuration - self.inDuration, 0)
			self.cutTimer = math.min(self.cutTimer + dtInSec, cutDuration)
			self.transitionAlpha = MathUtil.clamp(self.cutTimer - self.inDuration, 0, restCutDuration) / restCutDuration
		else
			self.transitionAlpha = 1
		end
	else
		cutDuration = self.defaultCutDuration

		if self.outTimer == 0 then
			self.cutTimer = 0
			self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.OUT
		end

		if self.outTimer >= 0 and self.outTimer < self.outDuration then
			self.outTimer = math.min(self.outTimer + dtInSec, self.outDuration)
			self.transitionAlpha = MathUtil.clamp(self.outTimer, 0, self.outDuration) / self.outDuration
		end
	end
end

function Chainsaw:resetTransitionState()
	if self.cameraTransitionState ~= Chainsaw.CAMERA_TRANSITION_STATES.NONE then
		self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.NONE
	end
end

function Chainsaw:updateCuttingCamera(isCutting)
	if isCutting then
		if self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.IN then
			setRotation(self.player.cuttingCameraNode, 0, 0, 0)

			local yx, yy, yz = localDirectionToWorld(self.player.cuttingCameraNode, 0, 1, 0)
			local zx, zy, zz = localDirectionToWorld(self.player.cuttingCameraNode, 0, 0, 1)
			local startX, startY, startZ, _, _, _ = self:getCutStartEnd()
			self.startCameraDirectionY = {
				yx,
				yy,
				yz
			}
			self.startCameraDirectionZ = {
				zx,
				zy,
				zz
			}
			self.endCameraDirectionY[1], self.endCameraDirectionY[2], self.endCameraDirectionY[3], self.endCameraDirectionZ[1], self.endCameraDirectionZ[2], self.endCameraDirectionZ[3] = self:getLookAt(self.player.cuttingCameraNode, startX, startY, startZ)
		elseif self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.CUT then
			local startX, startY, startZ, endX, endY, endZ = self:getCutStartEnd()
			self.startCameraDirectionY[1], self.startCameraDirectionY[2], self.startCameraDirectionY[3], self.startCameraDirectionZ[1], self.startCameraDirectionZ[2], self.startCameraDirectionZ[3] = self:getLookAt(self.player.cuttingCameraNode, startX, startY, startZ)
			self.endCameraDirectionY[1], self.endCameraDirectionY[2], self.endCameraDirectionY[3], self.endCameraDirectionZ[1], self.endCameraDirectionZ[2], self.endCameraDirectionZ[3] = self:getLookAt(self.player.cuttingCameraNode, endX, endY, endZ)
		end
	elseif self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.OUT then
		local yx, yy, yz = localDirectionToWorld(self.player.cuttingCameraNode, 0, 1, 0)
		local zx, zy, zz = localDirectionToWorld(self.player.cuttingCameraNode, 0, 0, 1)
		self.startCameraDirectionY = {
			yx,
			yy,
			yz
		}
		self.startCameraDirectionZ = {
			zx,
			zy,
			zz
		}

		setRotation(self.player.cuttingCameraNode, 0, 0, 0)

		yx, yy, yz = localDirectionToWorld(self.player.cuttingCameraNode, 0, 1, 0)
		zx, zy, zz = localDirectionToWorld(self.player.cuttingCameraNode, 0, 0, 1)
		self.endCameraDirectionY = {
			yx,
			yy,
			yz
		}
		self.endCameraDirectionZ = {
			zx,
			zy,
			zz
		}
	end

	local currentCamera = getCamera()

	if isCutting or self.outTimer < self.outDuration then
		if currentCamera ~= self.player.cuttingCameraNode then
			setCamera(self.player.cuttingCameraNode)
		end

		local smoothDirY = {
			MathUtil.lerp(self.startCameraDirectionY[1], self.endCameraDirectionY[1], self.transitionAlpha),
			MathUtil.lerp(self.startCameraDirectionY[2], self.endCameraDirectionY[2], self.transitionAlpha),
			MathUtil.lerp(self.startCameraDirectionY[3], self.endCameraDirectionY[3], self.transitionAlpha)
		}
		local smoothDirZ = {
			MathUtil.lerp(self.startCameraDirectionZ[1], self.endCameraDirectionZ[1], self.transitionAlpha),
			MathUtil.lerp(self.startCameraDirectionZ[2], self.endCameraDirectionZ[2], self.transitionAlpha),
			MathUtil.lerp(self.startCameraDirectionZ[3], self.endCameraDirectionZ[3], self.transitionAlpha)
		}
		smoothDirY = {
			worldDirectionToLocal(getParent(self.player.cuttingCameraNode), smoothDirY[1], smoothDirY[2], smoothDirY[3])
		}
		smoothDirZ = {
			worldDirectionToLocal(getParent(self.player.cuttingCameraNode), smoothDirZ[1], smoothDirZ[2], smoothDirZ[3])
		}
		local d, e, f = getWorldTranslation(self.player.chainsawSplitShapeFocus)

		setDirection(self.player.cuttingCameraNode, smoothDirZ[1], smoothDirZ[2], smoothDirZ[3], smoothDirY[1], smoothDirY[2], smoothDirY[3])
	elseif currentCamera ~= self.player.cameraNode then
		setRotation(self.player.cuttingCameraNode, 0, 0, 0)
		setCamera(self.player.cameraNode)
	end
end

function Chainsaw:updateChainsawModel(isCutting)
	local currentPos = {
		getWorldTranslation(self.graphicsNode)
	}

	if isCutting then
		local startPos = {}
		local endPos = {}
		startPos[1], startPos[2], startPos[3], endPos[1], endPos[2], endPos[3] = self:getCutStartEnd()

		if self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.IN then
			self.startChainsawPosition = currentPos
			self.endChainsawPosition = startPos
		elseif self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.CUT then
			self.startChainsawPosition = startPos
			self.endChainsawPosition = endPos
		end
	elseif self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.OUT then
		self.startChainsawPosition = currentPos

		setTranslation(self.graphicsNode, 0, 0, 0)

		self.endChainsawPosition = {
			getWorldTranslation(self.graphicsNode)
		}
	end

	if isCutting or self.outTimer < self.outDuration then
		local smoothPosition = {
			MathUtil.lerp(self.startChainsawPosition[1], self.endChainsawPosition[1], self.transitionAlpha),
			MathUtil.lerp(self.startChainsawPosition[2], self.endChainsawPosition[2], self.transitionAlpha),
			MathUtil.lerp(self.startChainsawPosition[3], self.endChainsawPosition[3], self.transitionAlpha)
		}
		local offset = {
			localToLocal(self.cutPositionNode, self.graphicsNode, 0, 0, 0)
		}
		local cutDirection = {
			localDirectionToWorld(self.ringSelector, 0, 0, offset[3])
		}
		local destination = {
			smoothPosition[1] - cutDirection[1],
			smoothPosition[2] - cutDirection[2],
			smoothPosition[3] - cutDirection[3]
		}
		local modelTranslation = {
			worldToLocal(getParent(self.graphicsNode), destination[1], destination[2], destination[3])
		}
		local distance = MathUtil.vector3Length(modelTranslation[1], modelTranslation[2], modelTranslation[3])

		if self.maxModelTranslation < distance then
			modelTranslation = {
				MathUtil.vector3Normalize(modelTranslation[1], modelTranslation[2], modelTranslation[3])
			}
			modelTranslation = {
				modelTranslation[1] * self.maxModelTranslation,
				modelTranslation[2] * self.maxModelTranslation,
				modelTranslation[3] * self.maxModelTranslation
			}
			local screen = {
				project(destination[1], destination[2], destination[3])
			}

			setTranslation(self.graphicsNode, modelTranslation[1], modelTranslation[2], modelTranslation[3])

			local graph = {
				getWorldTranslation(self.graphicsNode)
			}
			local screen2 = {
				project(graph[1], graph[2], graph[3])
			}
			local world2 = {
				unProject(screen[1], screen[2], screen2[3])
			}

			setWorldTranslation(self.graphicsNode, world2[1], world2[2], world2[3])
		else
			setTranslation(self.graphicsNode, modelTranslation[1], modelTranslation[2], modelTranslation[3])
		end
	else
		setTranslation(self.graphicsNode, 0, 0, 0)
	end
end

function Chainsaw:getCutShapeInformation()
	local x, y, z = getWorldTranslation(self.player.chainsawSplitShapeFocus)
	local nx, ny, nz = localDirectionToWorld(self.player.chainsawSplitShapeFocus, 1, 0, 0)
	local yx, yy, yz = localDirectionToWorld(self.player.chainsawSplitShapeFocus, 0, 1, 0)

	return x, y, z, nx, ny, nz, yx, yy, yz
end

function Chainsaw:update(dt, allowInput)
	Chainsaw:superClass().update(self, dt, allowInput)

	if self.isServer then
		local price = self.pricePerSecond * dt / 1000

		g_farmManager:getFarmById(self.player.farmId).stats:updateStats("expenses", price)
		g_currentMission:addMoney(-price, self.player.farmId, MoneyType.VEHICLE_RUNNING_COSTS)
	end

	if self.isClient then
		if not self.isCutting then
			self:updateCutRaycast()
		end

		if self.showNotOwnedWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 2000)

			self.showNotOwnedWarning = false
		end
	end

	self.shouldDelimb = false
	local lockPlayerInput = false

	if allowInput then
		local isCutting = false
		local hasBeenCut = false

		setRotation(self.graphicsNode, math.rad(math.random(-1, 1)) * 0.1, math.rad(math.random(-1, 1)) * 0.1, math.rad(-180))

		if self.curSplitShape == nil then
			lockPlayerInput = self.rotateInput ~= 0

			if self.rotateInput ~= 0 then
				self.rotationZ = MathUtil.clamp(self.rotationZ + self.rotationSpeedZ * self.rotateInput * dt, self.maxRotationZ, self.minRotationZ)

				setRotation(self.rootNode, self.handNodeRotation[1], self.handNodeRotation[2], self.handNodeRotation[3] - self.rotationZ)
				setRotation(self.player.chainsawCameraFocus, 0, 0, -self.rotationZ)
			end
		end

		local shape = 0

		if not self.waitingForResetAfterCut and (self.curSplitShape ~= nil or self.cutTimer == 0) then
			local minY, maxY, minZ, maxZ = nil

			if self.curSplitShape == nil or not entityExists(self.curSplitShape) then
				self.curSplitShape = nil
				local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()
				shape, minY, maxY, minZ, maxZ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ)

				if shape ~= nil and shape ~= 0 then
					if self:isCuttingAllowed(x, y, z) then
						self.showNotOwnedWarning = false
						local cutTooLow = self:testTooLow(shape, minY, maxY, minZ, maxZ)
						local outsideRange = self.cutFocusDistance < 0 or self.player.cutDetectionDistance <= self.cutFocusDistance

						if cutTooLow or outsideRange then
							self.player.walkingIsLocked = false
							self.curSplitShape = nil
							maxZ = nil
							minZ = nil
							maxY = nil
							minY = nil
							shape = 0
						end
					else
						self.showNotOwnedWarning = true
					end
				end

				self.curSplitShapeMinY = minY
				self.curSplitShapeMaxY = maxY
				self.curSplitShapeMinZ = minZ
				self.curSplitShapeMaxZ = maxZ
			else
				shape = self.curSplitShape
			end

			self:updateRingSelector(shape)
		end

		if self.activatePressed then
			self.speedFactor = math.min(self.speedFactor + dt / self.maxWorkTime, 1)

			if not self.waitingForResetAfterCut then
				local inRange = self.player.minCutDistance <= self.cutFocusDistance and self.cutFocusDistance < self.player.maxCutDistance
				self.shouldDelimb = inRange

				if (self.curSplitShape ~= nil or self.cutTimer == 0) and inRange then
					if self.curSplitShape ~= nil and entityExists(self.curSplitShape) then
						lockPlayerInput = true
						local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()
						local minY, maxY, minZ, maxZ = testSplitShape(self.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ)

						if minY == nil then
							self.player.walkingIsLocked = false
							self.curSplitShape = nil
						else
							local cutTooLow = self:testTooLow(self.curSplitShape, minY, maxY, minZ, maxZ)

							if cutTooLow then
								self.player.walkingIsLocked = false
								self.curSplitShape = nil
							end
						end

						self.curSplitShapeMinY = minY
						self.curSplitShapeMaxY = maxY
						self.curSplitShapeMinZ = minZ
						self.curSplitShapeMaxZ = maxZ
					elseif shape ~= 0 then
						self.player.walkingIsLocked = true
						self.curSplitShape = shape
					end

					if self.curSplitShape ~= nil then
						local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()

						if self:isCuttingAllowed(x, y, z) then
							isCutting = true
						end

						if self.cutTimer > 0 then
							self.lastWorkTime = math.min(self.lastWorkTime, self.maxWorkTime * 0.7)
						end

						local cutDuration = self:calculateCutDuration()

						if cutDuration <= self.cutTimer then
							if g_currentMission:getIsServer() then
								ChainsawUtil.cutSplitShape(self.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ, self.player.farmId)
							else
								g_client:getServerConnection():sendEvent(ChainsawCutEvent:new(self.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ, self.player.farmId))
							end

							hasBeenCut = true
							self.waitingForResetAfterCut = true
							self.player.walkingIsLocked = false
							self.curSplitShape = nil
							self.curSplitShapeMinY = nil

							self:updateRingSelector(0)
						end
					end
				end
			end
		else
			self.speedFactor = math.max(self.speedFactor - dt / self.maxWorkTime, 0)
			self.waitingForResetAfterCut = false
			self.player.walkingIsLocked = false
			self.curSplitShape = nil
			self.curSplitShapeMinY = nil
			self.lastWorkTime = math.max(self.lastWorkTime - dt, 0)
			self.workUpPlayed = false
		end

		self.player:lockInput(lockPlayerInput)
		self:updateCuttingTimers(dt, isCutting)
		self:updateCuttingCamera(isCutting)
		self:updateChainsawModel(isCutting)
		self:updateDelimb()
		self:setCutting(isCutting, self.rotationZ > 0.7, hasBeenCut)
	end

	self.soundFSM:update(dt)
	self:updateParticles()

	self.rotateInput = 0
	self.activatePressed = false
end

function Chainsaw:isCuttingAllowed(x, y, z)
	return g_currentMission.accessHandler:canFarmAccessLand(self.player.farmId, x, z)
end

function Chainsaw:updateDelimb()
	if self.shouldDelimb then
		local x, y, z = getWorldTranslation(self.player.chainsawSplitShapeFocus)
		local nx, ny, nz = localDirectionToWorld(self.player.chainsawSplitShapeFocus, 1, 0, 0)
		local yx, yy, yz = localDirectionToWorld(self.player.chainsawSplitShapeFocus, 0, 1, 0)

		if g_currentMission:getIsServer() then
			findAndRemoveSplitShapeAttachments(x, y, z, nx, ny, nz, yx, yy, yz, 0.7, self.cutSizeY, self.cutSizeZ)
		else
			g_client:getServerConnection():sendEvent(ChainsawDelimbEvent:new(self.player, x, y, z, nx, ny, nz, yx, yy, yz, false))
		end
	end
end

function Chainsaw:updateParticles()
	if self.particleSystems ~= nil then
		local active = false

		if self.isCutting and (g_currentMission.time < self.samplesBranchActiveTimer or self.curSplitShapeMinY ~= nil and self.curSplitShapeMaxY ~= nil and self.inDuration < self.cutTimer) then
			active = true
		end

		if self.isCutting and self.player.isOwner then
			active = true
		end

		for _, ps in pairs(self.particleSystems) do
			ParticleUtil.setEmittingState(ps, active)
		end
	end
end

function Chainsaw:updateRingSelector(shape)
	if self.ringSelector ~= nil then
		local hasShape = shape ~= nil and shape ~= 0

		if g_woodCuttingMarkerEnabled and hasShape then
			local inDetectionRange = false
			local inCutRange = false

			if self.cutFocusDistance ~= nil and self.cutFocusDistance >= 0 and self.cutFocusDistance < self.player.cutDetectionDistance then
				inDetectionRange = true
				inCutRange = self.player.minCutDistance <= self.cutFocusDistance and self.cutFocusDistance < self.player.maxCutDistance
			end

			if not getVisibility(self.ringSelector) and inDetectionRange then
				local x, y, z = getWorldTranslation(self.ringSelector)

				if self:isCuttingAllowed(x, y, z) then
					setVisibility(self.ringSelector, true)
				else
					setVisibility(self.ringSelector, false)
				end
			elseif getVisibility(self.ringSelector) and not inDetectionRange then
				setVisibility(self.ringSelector, false)
			end

			if getVisibility(self.ringSelector) then
				if inCutRange then
					setShaderParameter(self.ringSelector, "colorScale", 0.395, 0.925, 0.115, 1, false)
				else
					setShaderParameter(self.ringSelector, "colorScale", 0.098, 0.45, 0.96, 1, false)
				end

				if self.curSplitShapeMinY ~= nil then
					local scale = math.max(self.curSplitShapeMaxY - self.curSplitShapeMinY + self.ringSelectorScaleOffset, self.curSplitShapeMaxZ - self.curSplitShapeMinZ + self.ringSelectorScaleOffset)

					setScale(self.ringSelector, 1, scale, scale)

					local a, b, c = localToWorld(self.player.chainsawSplitShapeFocus, 0, (self.curSplitShapeMinY + self.curSplitShapeMaxY) * 0.5, (self.curSplitShapeMinZ + self.curSplitShapeMaxZ) * 0.5)
					local x, y, z = worldToLocal(getParent(self.ringSelector), a, b, c)

					setTranslation(self.ringSelector, x, y, z)
				else
					setScale(self.ringSelector, 1, 1, 1)
				end
			end
		elseif getVisibility(self.ringSelector) then
			setVisibility(self.ringSelector, false)
		end
	end
end

function Chainsaw:setCutting(isCutting, isHorizontalCut, hasBeenCut, noEventSend)
	ChainsawStateEvent.sendEvent(self.player, isCutting, isHorizontalCut, hasBeenCut, noEventSend)

	if not self.player.isOwner then
		self.player:setCuttingAnim(isCutting, isHorizontalCut)

		if self.isCutting ~= isCutting then
			if isCutting then
				setTranslation(self.handNode, unpack(self.handNodePositionInCutting))
				setRotation(self.handNode, unpack(self.handNodeRotationInCutting))

				if self.referenceNodeInCutting ~= nil then
					local x, y, z = getWorldTranslation(self.referenceNodeInCutting)
					x, y, z = worldToLocal(getParent(self.handNode), x, y, z)
					local a, b, c = getTranslation(self.handNode)

					setTranslation(self.handNode, a - x, b - y, c - z)
				end
			else
				setTranslation(self.handNode, unpack(self.handNodePosition))
				setRotation(self.handNode, unpack(self.handNodeRotation))

				if self.referenceNode ~= nil then
					local x, y, z = getWorldTranslation(self.referenceNode)
					x, y, z = worldToLocal(getParent(self.handNode), x, y, z)
					local a, b, c = getTranslation(self.handNode)

					setTranslation(self.handNode, a - x, b - y, c - z)
				end
			end
		end
	end

	self.isCutting = isCutting
	self.isHorizontalCut = isHorizontalCut
	self.hasBeenCut = hasBeenCut
end

function Chainsaw:getChainSpeedFactor()
	return self.speedFactor
end

function Chainsaw:onActivate(allowInput)
	Chainsaw:superClass().onActivate(self)

	self.rotationZ = 0

	setRotation(self.rootNode, self.handNodeRotation[1], self.handNodeRotation[2], self.handNodeRotation[3])
	setRotation(self.player.chainsawCameraFocus, 0, 0, self.rotationZ)

	self.startTime = g_currentMission.time

	if not self.player.isOwner then
		self.player.visualInformation:setProtectiveUV(self.equipmentUVs)
		self.player:setWoodWorkVisibility(true)
	end

	if self.isClient then
		g_animationManager:startAnimations(self.chains)
	end

	self.cutTimer = 0

	setTranslation(self.graphicsNode, 0, 0, 0)
	self.soundFSM:changeState(Chainsaw.SOUND_STATES.START)
end

function Chainsaw:onDeactivate(allowInput)
	Chainsaw:superClass().onDeactivate(self)

	self.speedFactor = 0
	self.curSplitShape = nil

	self.player:lockInput(false)

	self.player.walkingIsLocked = false

	self.player:setWoodWorkVisibility(false)

	if self.isClient then
		g_animationManager:stopAnimations(self.chains)

		self.cutTimer = 0

		setTranslation(self.graphicsNode, 0, 0, 0)

		if self.particleSystems ~= nil then
			for _, ps in pairs(self.particleSystems) do
				ParticleUtil.resetNumOfEmittedParticles(ps)
				ParticleUtil.setEmittingState(ps, false)
			end
		end

		if getVisibility(self.ringSelector) then
			setVisibility(self.ringSelector, false)
		end
	end

	self.soundFSM:changeState(Chainsaw.SOUND_STATES.STOP)
end

function Chainsaw:registerActionEvents()
	Chainsaw:superClass().registerActionEvents(self, allowInput)
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)

	local eventId = ""
	_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_ROTATE_HANDTOOL, self, self.onInputRotate, false, false, true, true)

	g_inputBinding:setActionEventText(eventId, g_i18n:getText("action_rotate"))

	self.eventIdRotateHandtool = eventId

	g_inputBinding:endActionEventsModification()
end

function Chainsaw:onInputRotate(_, inputValue)
	self.rotateInput = self.rotateInput + inputValue
end

function Chainsaw:isBeingUsed()
	return self.isCutting
end
