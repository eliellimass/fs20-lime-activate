HTMLUtil = {
	encodeEntities = {
		["\\xe7"] = "&ccedil;",
		["\\xab"] = "&laquo;",
		["\\xc7"] = "&Ccedil;",
		["\\xd9"] = "&Ugrave;",
		["\\xd6"] = "&Ouml;",
		["\\x9c"] = "&oelig;",
		["\\xc9"] = "&Eacute;",
		["\\xe8"] = "&egrave;",
		["\\xef"] = "&iuml;",
		["\\x8c"] = "&OElig;",
		["\\xc8"] = "&Egrave;",
		["\\xfb"] = "&ucirc;",
		["\\xee"] = "&icirc;",
		["\\xdb"] = "&Ucirc;",
		["\\xa9"] = "&copy;",
		["\\xf4"] = "&ocirc;",
		["\\xcf"] = "&Iuml;",
		["\\xbb"] = "&raquo;",
		["\\xe6"] = "&aelig;",
		["\\xe4"] = "&auml;",
		["\\xce"] = "&Icirc;",
		["\\xc6"] = "&AElig;",
		["\\xf9"] = "&ugrave;",
		["\\xe2"] = "&acirc;",
		[">"] = "&gt;",
		["\\xd4"] = "&Ocirc;",
		["\\xae"] = "&reg;",
		["<"] = "&lt;",
		["\\xc2"] = "&Acirc;",
		["\\xe0"] = "&agrave;",
		["\\xff"] = "&yuml;",
		["\\xc0"] = "&Agrave;",
		["\\xfc"] = "&uuml;",
		["\\xeb"] = "&euml;",
		["\\xea"] = "&ecirc;",
		["\\xcb"] = "&Euml;",
		["\\xf6"] = "&ouml;",
		["\\x9f"] = "&Yuml;",
		["\\xca"] = "&Ecirc;",
		["\\xe9"] = "&eacute;"
	},
	decodeEntities = {
		Ocirc = "\\xd4",
		auml = "\\xe4",
		ugrave = "\\xf9",
		acirc = "\\xe2",
		Ccedil = "\\xc7",
		ccedil = "\\xe7",
		Iuml = "\\xcf",
		Euml = "\\xcb",
		Eacute = "\\xc9",
		Egrave = "\\xc8",
		Icirc = "\\xce",
		ecirc = "\\xea",
		Ugrave = "\\xd9",
		raquo = "\\xbb",
		ouml = "\\xf6",
		laquo = "\\xab",
		egrave = "\\xe8",
		Ucirc = "\\xdb",
		aelig = "\\xe6",
		yuml = "\\xff",
		OElig = "\\x8c",
		eacute = "\\xe9",
		Agrave = "\\xc0",
		agrave = "\\xe0",
		oelig = "\\x9c",
		AElig = "\\xc6",
		iuml = "\\xef",
		reg = "\\xae",
		icirc = "\\xee",
		ocirc = "\\xf4",
		ucirc = "\\xfb",
		copy = "\\xa9",
		amp = "&",
		euml = "\\xeb",
		Acirc = "\\xc2",
		uuml = "\\xfc",
		Ecirc = "\\xca",
		Ouml = "\\xd6",
		Yuml = "\\x9f"
	},
	encodeToHTML = function (str, inCData)
		local encodedString = str

		if inCData then
			encodedString = string.gsub(encodedString, "]]>", "]]]]><![CDATA[>")
		else
			encodedString = string.gsub(encodedString, "&", "&amp;")
			encodedString = string.gsub(encodedString, "\"", "&quot;")
			encodedString = string.gsub(encodedString, "]", "&#93;")
			encodedString = string.gsub(encodedString, "<", "&lt;")
			encodedString = string.gsub(encodedString, ">", "&gt;")
			encodedString = string.gsub(encodedString, "\n", "&#10;")
			encodedString = string.gsub(encodedString, "\r", "&#13;")
		end

		return encodedString
	end
}

function HTMLUtil.decodeFromHTML(str)
	local function ReplaceEntity(entity)
		return HTMLUtil.decodeEntities[string.sub(entity, 2, -2)] or entity
	end

	return string.gsub(str, "&%a+;", ReplaceEntity)
end
