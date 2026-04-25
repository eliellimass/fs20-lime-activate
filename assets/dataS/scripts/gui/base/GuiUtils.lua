GuiUtils = {
	getNormalizedValues = function (data, refSize, defaultValue)
		if data ~= nil then
			local parts = data
			local isString = type(data) == "string"

			if isString then
				parts = StringUtil.splitString(" ", data)
			end

			local values = {}

			for k, part in pairs(parts) do
				local value = part

				if isString then
					local isPixelValue = false
					local isDisplayPixelValue = false

					if string.find(value, "px") ~= nil then
						isPixelValue = true
						value = string.gsub(value, "px", "")
					elseif string.find(value, "dp") ~= nil then
						isDisplayPixelValue = true
						value = string.gsub(value, "dp", "")
					end

					value = Utils.evaluateFormula(value)

					if isDisplayPixelValue then
						local s = (k + 1) % 2

						if s == 0 then
							value = value / g_screenWidth
						else
							value = value / g_screenHeight
						end
					elseif isPixelValue then
						value = value / refSize[(k + 1) % 2 + 1]
					end
				else
					value = value / refSize[(k + 1) % 2 + 1]
				end

				table.insert(values, value)
			end

			return values
		end

		return defaultValue
	end,
	getNormalizedTextSize = function (str, refSize, defaultValue)
		if str ~= nil then
			local isPixelValue = false
			local isDisplayPixelValue = false

			if string.find(str, "px") ~= nil then
				isPixelValue = true
				str = string.gsub(str, "px", "")
			elseif string.find(value, "dp") ~= nil then
				isDisplayPixelValue = true
				str = string.gsub(str, "dp", "")
			end

			local value = tonumber(str)

			if value == nil then
				printCallstack()
			end

			if isPixelValue then
				return value / (refSize or g_screenHeight)
			elseif isDisplayPixelValue then
				return value / g_screenHeight
			end
		end

		return defaultValue
	end,
	get2DArray = function (str, defaultValue)
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

		return defaultValue
	end,
	get4DArray = function (str, defaultValue)
		local w, x, y, z = StringUtil.getVectorFromString(str)

		if w ~= nil and x ~= nil and y ~= nil and z ~= nil then
			return {
				w,
				x,
				y,
				z
			}
		end

		return defaultValue
	end,
	getColorArray = function (colorStr, defaultValue)
		local r, g, b, a = StringUtil.getVectorFromString(colorStr)

		if r ~= nil and g ~= nil and b ~= nil and a ~= nil then
			return {
				r,
				g,
				b,
				a
			}
		end

		return defaultValue
	end
}

function GuiUtils.getUVs(str, ref, defaultValue)
	if str ~= nil then
		local uvs = GuiUtils.getNormalizedValues(str, ref or {
			1024,
			1024
		})

		return {
			uvs[1],
			1 - uvs[2] - uvs[4],
			uvs[1],
			1 - uvs[2],
			uvs[1] + uvs[3],
			1 - uvs[2] - uvs[4],
			uvs[1] + uvs[3],
			1 - uvs[2]
		}
	end

	return defaultValue
end

function GuiUtils.checkOverlayOverlap(posX, posY, overlayX, overlayY, overlaySizeX, overlaySizeY, hotspot)
	if hotspot ~= nil and #hotspot == 4 then
		return posX >= overlayX + hotspot[1] and posX <= overlayX + overlaySizeX + hotspot[3] and posY >= overlayY + hotspot[2] and posY <= overlayY + overlaySizeY + hotspot[4]
	else
		return overlayX <= posX and posX <= overlayX + overlaySizeX and overlayY <= posY and posY <= overlayY + overlaySizeY
	end
end
