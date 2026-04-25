Utils = {
	getNoNil = function (value, setTo)
		if value == nil then
			return setTo
		end

		return value
	end,
	getNoNilRad = function (valueDeg, defaultRad)
		if valueDeg == nil then
			return defaultRad
		end

		return math.rad(valueDeg)
	end,
	limitTextToWidth = function (text, textSize, width, trimFront, trimReplaceText)
		local replaceTextWidth = getTextWidth(textSize, trimReplaceText)
		local indexOfFirstCharacter = 1
		local indexOfLastCharacter = utf8Strlen(text)

		if width >= 0 then
			local totalWidth = getTextWidth(textSize, text)

			if width < totalWidth then
				if trimFront then
					indexOfFirstCharacter = getTextLineLength(textSize, text, totalWidth - width + replaceTextWidth)
					text = trimReplaceText .. utf8Substr(text, indexOfFirstCharacter)
				else
					indexOfLastCharacter = getTextLineLength(textSize, text, width - replaceTextWidth)
					text = utf8Substr(text, 0, indexOfLastCharacter) .. trimReplaceText
				end
			end
		end

		return text, indexOfFirstCharacter, indexOfLastCharacter
	end,
	getMovedLimitedValue = function (curVal, maxVal, minVal, speed, dt, inverted)
		local limitF = math.min
		local limitF2 = math.max

		if inverted then
			minVal = maxVal
			maxVal = minVal
		end

		if maxVal < minVal then
			limitF = math.max
			limitF2 = math.min
		end

		return limitF2(limitF(curVal + (maxVal - minVal) / speed * dt, maxVal), minVal)
	end
}

function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
	local ret = {}

	for i = 1, numValues do
		ret[i] = Utils.getMovedLimitedValue(currentValues[i], maxValues[i], minValues[i], speed, dt, inverted)
	end

	return ret
end

function Utils.setMovedLimitedValues(values, maxValues, minValues, numValues, speed, dt, inverted)
	local changed = false

	for i = 1, numValues do
		local newValue = Utils.getMovedLimitedValue(values[i], maxValues[i], minValues[i], speed, dt, inverted)

		if newValue ~= values[i] then
			changed = true
			values[i] = newValue
		end
	end

	return changed
end

function Utils.removeModDirectory(filename)
	local isMod = false
	local isDlc = false
	local dlcsDirectoryIndex = 0

	if filename == nil then
		printCallstack()
	end

	local filenameLower = filename:lower()

	if g_modsDirectory then
		local modsDirLen = g_modsDirectory:len()
		local modsDirLower = g_modsDirectory:lower()

		if filenameLower:sub(1, modsDirLen) == modsDirLower then
			filename = filename:sub(modsDirLen + 1)
			isMod = true
		end
	end

	if not isMod then
		for i = 1, table.getn(g_dlcsDirectories) do
			local dlcsDir = g_dlcsDirectories[i].path:lower()
			local dlcsDirLen = dlcsDir:len()

			if filenameLower:sub(1, dlcsDirLen) == dlcsDir then
				filename = filename:sub(dlcsDirLen + 1)
				dlcsDirectoryIndex = i
				isDlc = true

				break
			end
		end
	end

	return filename, isMod, isDlc, dlcsDirectoryIndex
end

function Utils.getModNameAndBaseDirectory(filename)
	local modName = nil
	local baseDirectory = ""
	local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(filename)

	if isMod or isDlc then
		local f, l = modFilename:find("/")

		if f ~= nil and l ~= nil and f > 1 then
			modName = modFilename:sub(1, f - 1)

			if isDlc then
				baseDirectory = g_dlcsDirectories[dlcsDirectoryIndex].path .. modName .. "/"

				if g_dlcModNameHasPrefix[modName] then
					modName = g_uniqueDlcNamePrefix .. modName
				end
			else
				baseDirectory = g_modsDirectory .. modName .. "/"
			end
		end
	end

	return modName, baseDirectory
end

function Utils.getVersatileRotation(repr, componentNode, dt, posX, posY, posZ, currentAngle, minAngle, maxAngle)
	local vx, vy, vz = getVelocityAtLocalPos(componentNode, posX, posY, posZ)
	local x, _, z = worldDirectionToLocal(getParent(repr), vx, vy, vz)
	local length = MathUtil.vector2Length(x, z)
	local steeringAngle = currentAngle

	if length > 0.15 then
		z = z / length
		steeringAngle = math.acos(z)

		if x < 0 then
			steeringAngle = -steeringAngle
		end
	end

	if minAngle ~= nil and minAngle ~= 0 and maxAngle ~= nil and maxAngle ~= 0 then
		if maxAngle < steeringAngle then
			steeringAngle = maxAngle
		elseif steeringAngle < minAngle then
			steeringAngle = minAngle
		end
	end

	steeringAngle = MathUtil.normalizeRotationForShortestPath(steeringAngle, currentAngle)

	if currentAngle < steeringAngle then
		steeringAngle = math.min(currentAngle + 0.003 * dt, steeringAngle)
	else
		steeringAngle = math.max(currentAngle - 0.003 * dt, steeringAngle)
	end

	return steeringAngle
end

function Utils.getYRotationBetweenNodes(node1, node2)
	local x, _, z = worldDirectionToLocal(node1, localDirectionToWorld(node2, 0, 0, 1))
	local dot = z
	dot = dot / MathUtil.vector2Length(x, z)
	local angle = math.acos(dot)

	if x < 0 then
		angle = -angle
	end

	return angle
end

function Utils.getPerformanceClassIndex(profileClass)
	profileClass = profileClass:lower()
	local currentProfileIndex = GS_PROFILE_LOW

	if profileClass == "medium" then
		currentProfileIndex = GS_PROFILE_MEDIUM
	elseif profileClass == "high" then
		currentProfileIndex = GS_PROFILE_HIGH
	elseif profileClass == "very high" then
		currentProfileIndex = GS_PROFILE_VERY_HIGH
	end

	return currentProfileIndex
end

function Utils.getPerformanceClassFromIndex(profileClassIndex)
	local currentProfileClass = "Low"

	if profileClassIndex == GS_PROFILE_MEDIUM then
		currentProfileClass = "Medium"
	elseif profileClassIndex == GS_PROFILE_HIGH then
		currentProfileClass = "High"
	elseif profileClassIndex == GS_PROFILE_VERY_HIGH then
		currentProfileClass = "Very High"
	end

	return currentProfileClass
end

function Utils.getPerformanceClassId()
	return Utils.getPerformanceClassIndex(getPerformanceClass())
end

function Utils.getStateFromValues(values, steps, value)
	local state = table.getn(values)

	for i = 1, table.getn(values) do
		if value <= values[i] + steps * 0.5 then
			state = i

			break
		end
	end

	return state
end

function Utils.getValueIndex(targetValue, values)
	local index = 1
	local threshold = 0.0001

	for k, val in pairs(values) do
		if targetValue < val - threshold then
			break
		end

		index = k
	end

	return index
end

function Utils.getNumTimeScales()
	if g_addTestCommands and not g_isPresentationVersion then
		return #g_timeScaleSettings + 1
	else
		return #g_timeScaleSettings
	end
end

function Utils.getTimeScaleString(timeScaleIndex)
	if timeScaleIndex == 1 then
		return g_i18n:getText("ui_realTime")
	elseif g_languageShort == "cs" then
		if timeScaleIndex > #g_timeScaleSettings then
			return string.format("%d倍 (dev only)", Utils.getTimeScaleFromIndex(timeScaleIndex))
		else
			return string.format("%d倍", Utils.getTimeScaleFromIndex(timeScaleIndex))
		end
	elseif timeScaleIndex > #g_timeScaleSettings then
		return string.format("%dx (dev only)", Utils.getTimeScaleFromIndex(timeScaleIndex))
	else
		return string.format("%dx", Utils.getTimeScaleFromIndex(timeScaleIndex))
	end
end

function Utils.getTimeScaleIndex(timeScale)
	if g_addTestCommands and not g_isPresentationVersion and g_timeScaleDevSetting <= timeScale then
		return #g_timeScaleSettings + 1
	end

	if GS_IS_MOBILE_VERSION and timeScale == 60 then
		timeScale = 30
	end

	for i = #g_timeScaleSettings, 1, -1 do
		if g_timeScaleSettings[i] <= timeScale then
			return i
		end
	end

	return 1
end

function Utils.getTimeScaleFromIndex(timeScaleIndex)
	if g_addTestCommands and not g_isPresentationVersion and timeScaleIndex > #g_timeScaleSettings then
		return g_timeScaleDevSetting
	end

	if g_timeScaleSettings[timeScaleIndex] ~= nil then
		return g_timeScaleSettings[timeScaleIndex]
	end

	return 1
end

function Utils.getMasterVolumeIndex(masterVolume)
	local eps = 0.01
	local masterVolumeIndex = 1

	if masterVolume >= 0.1 - eps then
		masterVolumeIndex = 2
	end

	if masterVolume >= 0.2 - eps then
		masterVolumeIndex = 3
	end

	if masterVolume >= 0.3 - eps then
		masterVolumeIndex = 4
	end

	if masterVolume >= 0.4 - eps then
		masterVolumeIndex = 5
	end

	if masterVolume >= 0.5 - eps then
		masterVolumeIndex = 6
	end

	if masterVolume >= 0.6 - eps then
		masterVolumeIndex = 7
	end

	if masterVolume >= 0.7 - eps then
		masterVolumeIndex = 8
	end

	if masterVolume >= 0.8 - eps then
		masterVolumeIndex = 9
	end

	if masterVolume >= 0.9 - eps then
		masterVolumeIndex = 10
	end

	if masterVolume >= 1 - eps then
		masterVolumeIndex = 11
	end

	return masterVolumeIndex
end

function Utils.getMasterVolumeFromIndex(masterVolumeIndex)
	local masterVolume = 1

	if masterVolumeIndex == 1 then
		masterVolume = 0
	end

	if masterVolumeIndex == 2 then
		masterVolume = 0.1
	end

	if masterVolumeIndex == 3 then
		masterVolume = 0.2
	end

	if masterVolumeIndex == 4 then
		masterVolume = 0.3
	end

	if masterVolumeIndex == 5 then
		masterVolume = 0.4
	end

	if masterVolumeIndex == 6 then
		masterVolume = 0.5
	end

	if masterVolumeIndex == 7 then
		masterVolume = 0.6
	end

	if masterVolumeIndex == 8 then
		masterVolume = 0.7
	end

	if masterVolumeIndex == 9 then
		masterVolume = 0.8
	end

	if masterVolumeIndex == 10 then
		masterVolume = 0.9
	end

	return masterVolume
end

function Utils.getUIScaleIndex(uiScale)
	local eps = 0.01
	local uiScaleIndex = 1

	if uiScale >= 0.6 - eps then
		uiScaleIndex = 2
	end

	if uiScale >= 0.7 - eps then
		uiScaleIndex = 3
	end

	if uiScale >= 0.8 - eps then
		uiScaleIndex = 4
	end

	if uiScale >= 0.9 - eps then
		uiScaleIndex = 5
	end

	if uiScale >= 1 - eps then
		uiScaleIndex = 6
	end

	if uiScale >= 1.1 - eps then
		uiScaleIndex = 7
	end

	if uiScale >= 1.2 - eps then
		uiScaleIndex = 8
	end

	if uiScale >= 1.3 - eps then
		uiScaleIndex = 9
	end

	if uiScale >= 1.4 - eps then
		uiScaleIndex = 10
	end

	if uiScale >= 1.5 - eps then
		uiScaleIndex = 11
	end

	return uiScaleIndex
end

function Utils.getUIScaleFromIndex(uiScaleIndex)
	local uiScale = 1

	if uiScaleIndex == 1 then
		uiScale = 0.5
	end

	if uiScaleIndex == 2 then
		uiScale = 0.6
	end

	if uiScaleIndex == 3 then
		uiScale = 0.7
	end

	if uiScaleIndex == 4 then
		uiScale = 0.8
	end

	if uiScaleIndex == 5 then
		uiScale = 0.9
	end

	if uiScaleIndex == 6 then
		uiScale = 1
	end

	if uiScaleIndex == 7 then
		uiScale = 1.1
	end

	if uiScaleIndex == 8 then
		uiScale = 1.2
	end

	if uiScaleIndex == 9 then
		uiScale = 1.3
	end

	if uiScaleIndex == 10 then
		uiScale = 1.4
	end

	if uiScaleIndex == 11 then
		uiScale = 1.5
	end

	return uiScale
end

function Utils.getFilename(filename, baseDir)
	if filename == nil then
		printCallstack()

		return nil
	end

	if filename:sub(1, 1) == "$" then
		return filename:sub(2), false
	elseif baseDir == nil or baseDir == "" then
		return filename, false
	elseif filename == "" then
		return filename, true
	end

	return baseDir .. filename, true
end

function Utils.getMaxJointForceLimit(forceLimit1, forceLimit2)
	if forceLimit1 < 0 or forceLimit2 < 0 then
		return -1
	end

	return math.max(forceLimit1, forceLimit2)
end

function Utils.appendedFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function (...)
			oldFunc(...)
			newFunc(...)
		end
	else
		return newFunc
	end
end

function Utils.prependedFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function (...)
			newFunc(...)
			oldFunc(...)
		end
	else
		return newFunc
	end
end

function Utils.overwrittenFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function (self, ...)
			return newFunc(self, oldFunc, ...)
		end
	else
		return function (self, ...)
			return newFunc(self, nil, ...)
		end
	end
end

function Utils.shuffle(t)
	local n = table.getn(t)

	while n > 2 do
		local k = math.random(n)
		t[k] = t[n]
		t[n] = t[k]
		n = n - 1
	end

	return t
end

function Utils.get2DArray(str)
	if str ~= nil then
		local parts = StringUtil.splitString(" ", str)
		local x, y = unpack(parts)

		if x ~= nil and y ~= nil then
			return {
				Utils.evaluateFormula(x),
				Utils.evaluateFormula(y)
			}
		end
	end

	return nil
end

function Utils.getFilenameInfo(filename, excludePath)
	local cleanFilename = filename
	local pos, _, extension = string.find(filename, "([^.]*)$")

	if pos == 1 then
		extension = nil
	else
		cleanFilename = string.sub(filename, 1, pos - 2)

		if excludePath ~= nil and excludePath then
			local lastSlash = cleanFilename:find("/[^/]*$")
			cleanFilename = string.sub(cleanFilename, lastSlash + 1)
		end
	end

	return cleanFilename, extension
end

function Utils.stringToBoolean(value)
	local ret = value ~= nil and value:lower() == "true"

	return ret
end

function Utils.formatTime(timeMinutes)
	local timeHoursF = timeMinutes / 60 + 0.0001
	local timeHours = math.floor(timeHoursF)
	local timeMinutes = math.floor((timeHoursF - timeHours) * 60)

	return string.format("%02d:%02d", timeHours, timeMinutes)
end

function Utils.renderMultiColumnText(x, y, textSize, texts, spacingX, aligns)
	for i, text in ipairs(texts) do
		local align = aligns ~= nil and aligns[i] or RenderText.ALIGN_LEFT

		setTextAlignment(align)

		local w = getTextWidth(textSize, text)

		if align == RenderText.ALIGN_RIGHT then
			renderText(x + w, y, textSize, text)
		elseif align == RenderText.ALIGN_CENTER then
			renderText(x + w * 0.5, y, textSize, text)
		else
			renderText(x, y, textSize, text)
		end

		x = x + w + spacingX
	end

	setTextAlignment(RenderText.ALIGN_LEFT)
end

function Utils.getCoinToss()
	return math.random() >= 0.5
end

function Utils.getNormallyDistributedRandomVariables(mean, sigmaSq)
	local u, v = nil
	local q = -1

	while q >= 1 or q <= 0 do
		u = -1 + 2 * math.random()
		v = -1 + 2 * math.random()
		q = u^2 + v^2
	end

	local p = math.sqrt(-2 * math.log(q) / math.log(math.exp(1)) / q)
	local x1 = u * p
	local x2 = v * p
	local sigma = math.sqrt(sigmaSq)

	return mean + sigma * x1, mean + sigma * x2
end

function Utils.getIntersectionOfLinearMovementAndTerrain(node, speed)
	local cx, cy, cz = nil
	local x0, y0, z0 = getWorldTranslation(node)
	local dx, dy, dz = localDirectionToWorld(node, 0, -1, 0)
	local vx = dx * speed
	local vy = dy * speed
	local vz = dz * speed
	local stepT = 1 / speed
	local maxT = 50 / speed

	for t = 2 * stepT, maxT, stepT do
		local x = x0 + vx * t
		local z = z0 + vz * t
		local y = y0 + vy * t - 4.905 * t * t
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

		if y <= h then
			cx = x
			cy = h
			cz = z

			break
		end

		if VehicleDebug.state == VehicleDebug.DEBUG then
			drawDebugPoint(x, y, z, 0, 0, 1, 1)
		end
	end

	return cx, cy, cz
end

function Utils.clearBit(bitMask, bit)
	local bitFlag = 2^bit

	return bitAND(bitMask, bitNOT(bitFlag))
end

function Utils.setBit(bitMask, bit)
	local bitFlag = 2^bit

	return bitOR(bitMask, bitFlag)
end

function Utils.isBitSet(bitMask, bit)
	local bitFlag = 2^bit

	return bitAND(bitMask, bitFlag) ~= 0
end

function Utils.evaluateFormula(str)
	if str == nil then
		printCallstack()
	end

	if str:find("[_%a]") == nil then
		local f = loadstring("g_asd_tempMathValue = " .. str)

		if f ~= nil then
			f()

			str = g_asd_tempMathValue
			g_asd_tempMathValue = nil
		end
	end

	return tonumber(str)
end

function Utils.randomFloat(lowerValue, upperValue)
	return lowerValue + math.random() * (upperValue - lowerValue)
end

function Utils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, color)
	local sx, sy, sz = project(x, y, z)
	color = color or {
		0.5,
		1,
		0.5,
		1
	}

	if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		setTextColor(0, 0, 0, 0.75)
		renderText(sx, sy - 0.0015 + textOffset, textSize, text)
		setTextColor(unpack(color))
		renderText(sx, sy + textOffset, textSize, text)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end
