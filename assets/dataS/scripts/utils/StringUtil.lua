StringUtil = {}

function StringUtil.getVectorFromString(input)
	if input == nil then
		return nil
	end

	local vals = StringUtil.splitString(" ", StringUtil.trim(input))
	local num = table.getn(vals)

	for i = 1, num do
		vals[i] = tonumber(vals[i])
	end

	return unpack(vals, 1, num)
end

function StringUtil.getVectorNFromString(input, num)
	if input == nil then
		return nil
	end

	local strings = StringUtil.splitString(" ", StringUtil.trim(input))

	if num == nil then
		num = table.getn(strings)

		if num == 0 then
			return nil
		end
	end

	if table.getn(strings) ~= num then
		print("Error: Invalid " .. num .. "-vector '" .. input .. "'")

		return nil
	end

	local results = {}

	for i = 1, num do
		table.insert(results, tonumber(strings[i]))
	end

	return results
end

function StringUtil.getRadiansFromString(input, num)
	if input == nil then
		return nil
	end

	local strings = StringUtil.splitString(" ", input)

	if table.getn(strings) ~= num then
		print("Error: Invalid " .. num .. "-vector '" .. input .. "'")

		return nil
	end

	local results = {}

	for i = 1, num do
		local degrees = tonumber(strings[i])

		if degrees ~= nil then
			table.insert(results, math.rad(degrees))
		else
			print("Error: Invalid " .. num .. "-vector '" .. input .. "'")
		end
	end

	return results
end

function StringUtil.parseList(str, separator, lambda)
	if not str then
		return nil
	end

	if str == "" then
		return {}
	end

	list = StringUtil.splitString(separator, str)
	newlist = {}

	for i, v in pairs(list) do
		newlist[i] = lambda(v)
	end

	return newlist
end

function StringUtil.splitString(splitPattern, text)
	local results = {}

	if text ~= nil then
		local start = 1
		local splitStart, splitEnd = string.find(text, splitPattern, start, true)

		while splitStart ~= nil do
			table.insert(results, string.sub(text, start, splitStart - 1))

			start = splitEnd + 1
			splitStart, splitEnd = string.find(text, splitPattern, start, true)
		end

		table.insert(results, string.sub(text, start))
	end

	return results
end

function StringUtil.startsWith(str, find)
	return str:sub(1, find:len()) == find
end

function StringUtil.endsWith(str, find)
	return str:sub(str:len() - find:len() + 1) == find
end

function StringUtil.trim(str)
	local n = str:find("%S")

	return n and str:match(".*%S", n) or ""
end

function StringUtil.getFilenameFromPath(path)
	path = path:gsub("\\", "/")
	local elems = StringUtil.splitString("/", path)

	return elems[#elems]
end
