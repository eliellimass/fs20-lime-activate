Lighting = {}
local Lighting_mt = Class(Lighting)

function Lighting:new(environment, customMt)
	local self = setmetatable({}, customMt or Lighting_mt)
	self.environment = environment
	self.updateInterval = 10000
	self.lastDayTime = 0
	self.globalCloudCoverage = 0

	return self
end

function Lighting.fileInterpolator(first, second, alpha)
	return first.file, second.file, alpha
end

function Lighting:load(xmlFile, baseKey)
	local lightScatteringRotLoadFunc = getLoadNamedInterpolatorCurve({
		"primary",
		"secondary"
	})

	local function lightScatteringRotToRadLoadFunc(xmlFile, key)
		local values = lightScatteringRotLoadFunc(xmlFile, key)
		values[1] = math.rad(values[1])
		values[2] = math.rad(values[2])

		return values
	end

	self.lightScatteringRotCurve = AnimCurve:new(linearInterpolator2)

	self.lightScatteringRotCurve:loadCurveFromXML(xmlFile, baseKey .. ".lightScatteringRotation", lightScatteringRotToRadLoadFunc)

	self.asymmetryFactorCurve = AnimCurve:new(linearInterpolator1)

	self.asymmetryFactorCurve:loadCurveFromXML(xmlFile, baseKey .. ".asymmetryFactor", loadInterpolator1Curve)

	self.sunBrightnessScaleCurve = AnimCurve:new(linearInterpolator1)

	self.sunBrightnessScaleCurve:loadCurveFromXML(xmlFile, baseKey .. ".sunBrightnessScale", loadInterpolator1Curve)

	if #self.sunBrightnessScaleCurve.keyframes == 0 then
		self.sunBrightnessScaleCurve:addKeyframe({
			1,
			time = 0
		})
	end

	self.sunSizeScaleCurve = AnimCurve:new(linearInterpolator1)

	self.sunSizeScaleCurve:loadCurveFromXML(xmlFile, baseKey .. ".sunSizeScale", loadInterpolator1Curve)

	if #self.sunSizeScaleCurve.keyframes == 0 then
		self.sunSizeScaleCurve:addKeyframe({
			15000,
			time = 0
		})
	end

	self.moonBrightnessScaleCurve = AnimCurve:new(linearInterpolator1)

	self.moonBrightnessScaleCurve:loadCurveFromXML(xmlFile, baseKey .. ".moonBrightnessScale", loadInterpolator1Curve)

	if #self.moonBrightnessScaleCurve.keyframes == 0 then
		self.moonBrightnessScaleCurve:addKeyframe({
			1,
			time = 0
		})
	end

	self.moonSizeScaleCurve = AnimCurve:new(linearInterpolator1)

	self.moonSizeScaleCurve:loadCurveFromXML(xmlFile, baseKey .. ".moonSizeScale", loadInterpolator1Curve)

	if #self.moonSizeScaleCurve.keyframes == 0 then
		self.moonSizeScaleCurve:addKeyframe({
			42,
			time = 0
		})
	end

	self.sunIsPrimaryCurve = AnimCurve:new(linearInterpolator1)

	self.sunIsPrimaryCurve:loadCurveFromXML(xmlFile, baseKey .. ".sunIsPrimary", loadInterpolator1Curve)

	if #self.sunIsPrimaryCurve.keyframes == 0 then
		self.sunIsPrimaryCurve:addKeyframe({
			1,
			time = 0
		})
	end

	self.primaryExtraterrestrialColor = AnimCurve:new(linearInterpolator3)

	self.primaryExtraterrestrialColor:loadCurveFromXML(xmlFile, baseKey .. ".primaryExtraterrestrialColor", loadInterpolator3Curve)

	self.primaryDynamicLightingScale = AnimCurve:new(linearInterpolator1)

	self.primaryDynamicLightingScale:loadCurveFromXML(xmlFile, baseKey .. ".primaryDynamicLightingScale", loadInterpolator1Curve)

	if #self.primaryDynamicLightingScale.keyframes == 0 then
		self.primaryDynamicLightingScale:addKeyframe({
			1,
			time = 0
		})
	end

	self.secondaryExtraterrestrialColor = AnimCurve:new(linearInterpolator3)

	self.secondaryExtraterrestrialColor:loadCurveFromXML(xmlFile, baseKey .. ".secondaryExtraterrestrialColor", loadInterpolator3Curve)

	self.autoExposureCurve = AnimCurve:new(linearInterpolator3)

	self.autoExposureCurve:loadCurveFromXML(xmlFile, baseKey .. ".autoExposure", getLoadNamedInterpolatorCurve({
		"keyLuminance",
		"minExposure",
		"maxExposure"
	}))

	if GS_IS_MOBILE_VERSION then
		self.fixedExposureCurve = AnimCurve:new(linearInterpolator1)

		self.fixedExposureCurve:loadCurveFromXML(xmlFile, baseKey .. ".fixedExposure", getLoadNamedInterpolatorCurve({
			"exposure"
		}))
	end

	if g_currentMission.xmlFile ~= nil then
		self.colorGradingFileCurve = AnimCurve:new(Lighting.fileInterpolator)
		local j = 0

		while true do
			local key = string.format("%s.colorGradings.colorGrading(%d)", baseKey, j)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local colorGradingXmlFile = getXMLString(xmlFile, key .. "#filename")
			local time = getXMLString(xmlFile, key .. "#time")

			if time ~= nil and colorGradingXmlFile ~= nil then
				self.colorGradingFileCurve:addKeyframe({
					time = Utils.evaluateFormula(time),
					file = Utils.getFilename(colorGradingXmlFile, g_currentMission.baseDirectory)
				})
			end

			j = j + 1
		end

		if #self.colorGradingFileCurve.keyframes == 0 then
			local filename = Utils.getFilename(getXMLString(g_currentMission.xmlFile, "map.colorGrading#filename") or "", g_currentMission.baseDirectory)

			self.colorGradingFileCurve:addKeyframe({
				time = 0,
				file = filename
			})
		end

		self.envMapBasePath = getXMLString(xmlFile, baseKey .. ".envMap#basePath")

		if self.envMapBasePath ~= nil then
			self.envMapBasePath = Utils.getFilename(self.envMapBasePath, g_currentMission.baseDirectory)
		end

		self.envMapTimes = {}
		local i = 0

		while true do
			local key = string.format("%s.envMap.timeProbe(%d)", baseKey, i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local time = getXMLFloat(xmlFile, key .. "#timeHours")

			if time ~= nil then
				table.insert(self.envMapTimes, time)
			end

			i = i + 1
		end

		self.envMapRenderingMode = false
	end

	self.lastDayTime = 0
	self.globalCloudCoverage = 0

	return true
end

function Lighting:setEnvironment(environment)
	self.environment = environment
end

function Lighting:reset()
	resetAutoExposure()
end

function Lighting.getEnvMapBaseFilename(dayTimeHours)
	local hours, minutes = math.modf(dayTimeHours)
	local minutes, seconds = math.modf(minutes * 60)
	seconds = math.floor(seconds * 60)

	return string.format("%d_%d_%d", hours, minutes, seconds)
end

function Lighting:update(dt, force)
	if force or self.updateInterval < math.abs(self.environment.dayTime - self.lastDayTime) then
		local dayMinutes = self.environment.dayTime / 60000

		if self.envMapBasePath ~= nil and #self.envMapTimes > 0 then
			local envMap0, envMap1 = nil
			local blendWeight = 0

			if #self.envMapTimes > 1 then
				local dayHours = dayMinutes / 60
				local secondIndex = 1

				for i, time in ipairs(self.envMapTimes) do
					if dayHours < time then
						secondIndex = i

						break
					end
				end

				local firstIndex = secondIndex - 1

				if firstIndex <= 0 then
					firstIndex = #self.envMapTimes
					blendWeight = (dayHours - (self.envMapTimes[firstIndex] - 24)) / (self.envMapTimes[secondIndex] - (self.envMapTimes[firstIndex] - 24))
				else
					blendWeight = (dayHours - self.envMapTimes[firstIndex]) / (self.envMapTimes[secondIndex] - self.envMapTimes[firstIndex])
				end

				envMap0 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[firstIndex]) .. ".png"
				envMap1 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[secondIndex]) .. ".png"
			else
				envMap0 = self.envMapBasePath .. "/" .. Lighting.getEnvMapBaseFilename(self.envMapTimes[1]) .. ".png"
				envMap1 = envMap0
			end

			setEnvMap(envMap0, envMap1, blendWeight, force or self.envMapRenderingMode)
		end

		local primaryScatteringRotation, secondaryScatteringRotation = self.lightScatteringRotCurve:get(dayMinutes)
		local pLscX, pLscY, pLscZ = mathEulerRotateVector(self.environment.sunHeightAngle, 0, primaryScatteringRotation, 0, 0, 1)

		setLightScatteringDirection(self.environment.sunLightId, pLscX, pLscY, pLscZ)

		local sLscX, sLscY, sLscZ = mathEulerRotateVector(self.environment.sunHeightAngle, 0, secondaryScatteringRotation, 0, 0, 1)
		local sdr, sdg, sdb = self.secondaryExtraterrestrialColor:get(dayMinutes)

		setAtmosphereSecondaryLightSource(sLscX, sLscY, sLscZ, sdr, sdg, sdb)

		local asymmetryFactor = self.asymmetryFactorCurve:get(dayMinutes)

		setAtmosphereCornettAsymetryFactor(asymmetryFactor)

		local sunSizeScale = self.sunSizeScaleCurve:get(dayMinutes)

		setSunSizeScale(sunSizeScale)

		local moonSizeScale = self.moonSizeScaleCurve:get(dayMinutes)

		setMoonSizeScale(moonSizeScale)

		local sunIsPrimary = self.sunIsPrimaryCurve:get(dayMinutes) > 0.5

		setSunIsPrimary(sunIsPrimary)

		local moonBrightnessScale = self.moonBrightnessScaleCurve:get(dayMinutes)
		local sunBrightnessScale = self.sunBrightnessScaleCurve:get(dayMinutes)

		if self.envMapRenderingMode then
			if sunIsPrimary then
				sunBrightnessScale = sunBrightnessScale * 0.001
			else
				moonBrightnessScale = moonBrightnessScale * 0.001
			end
		end

		setSunBrightnessScale(sunBrightnessScale)
		setMoonBrightnessScale(moonBrightnessScale)

		local dr, dg, db = self.primaryExtraterrestrialColor:get(dayMinutes)
		local dynamicLightingScale = self.primaryDynamicLightingScale:get(dayMinutes)
		local lightDamping = -0.1 * self.globalCloudCoverage + 1
		dynamicLightingScale = dynamicLightingScale * lightDamping

		setLightColor(self.environment.sunLightId, dr * dynamicLightingScale, dg * dynamicLightingScale, db * dynamicLightingScale)
		setLightScatteringColor(self.environment.sunLightId, dr, dg, db)

		local gradingFile1, gradingFile2, gradingAlpha = self.colorGradingFileCurve:get(dayMinutes)

		setColorGradingSettings(gradingFile1, gradingFile2, gradingAlpha)
		self:updateExposureSettings()

		self.lastDayTime = self.environment.dayTime
	end
end

function Lighting:updateExposureSettings()
	local dayMinutes = self.environment.dayTime / 60000
	local minExposure, maxExposure, keyValue = nil

	if GS_IS_MOBILE_VERSION then
		if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
			minExposure = self.fixedExposureCurve:get(dayMinutes)
			maxExposure = minExposure
			keyValue = 0.18
		else
			keyValue = self.fixedKeyValue
			minExposure = self.fixedMinExposure
			maxExposure = self.fixedMaxExposure
		end
	elseif self.fixedKeyValue == nil then
		keyValue, minExposure, maxExposure = self.autoExposureCurve:get(dayMinutes)
	elseif self.fixedMinExposure == nil then
		_, minExposure, maxExposure = self.autoExposureCurve:get(dayMinutes)
		keyValue = self.fixedKeyValue
	else
		keyValue = self.fixedKeyValue
		minExposure = self.fixedMinExposure
		maxExposure = self.fixedMaxExposure
	end

	setExposureRange(keyValue, minExposure, maxExposure)
end

function Lighting:setFixedExposureSettings(keyValue, minExposure, maxExposure)
	if maxExposure == nil then
		maxExposure = minExposure
	end

	self.fixedKeyValue = keyValue
	self.fixedMinExposure = minExposure
	self.fixedMaxExposure = maxExposure
end

function Lighting:setCloudCoverage(globalCoverage)
	self.globalCloudCoverage = globalCoverage
end
