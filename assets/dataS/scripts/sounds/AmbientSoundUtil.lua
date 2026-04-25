AmbientSoundUtil = {
	onCreateSoundNode = function (_, id)
		g_ambientSoundManager:addSound3d(id)
	end,
	onCreatePolygonChain = function (_, id)
		g_ambientSoundManager:addPolygonChain(id)
	end
}
