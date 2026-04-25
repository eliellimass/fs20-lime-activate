SettingsAdvancedFrame = {}
local SettingsAdvancedFrame_mt = Class(SettingsAdvancedFrame, TabbedMenuFrameElement)
SettingsAdvancedFrame.CONTROLS = {
	ELEMENT_FOLIAGE_DRAW_DISTANCE = "foliageDrawDistanceElement",
	ELEMENT_TEXTURE_RESOLUTION = "textureResolutionElement",
	ELEMENT_OBJECT_DRAW_DISTANCE = "objectDrawDistanceElement",
	ELEMENT_SHADER_QUALITY = "shaderQualityElement",
	ELEMENT_MAX_TIRE_TRACKS = "maxTireTracksElement",
	ELEMENT_SHADOW_QUALITY = "shadowQualityElement",
	ELEMENT_MAX_MIRRORS = "maxMirrorsElement",
	ELEMENT_SHADOW_MAP_FILTERING = "shadowMapFilteringElement",
	ELEMENT_PERFORMANCE_CLASS = "performanceClassElement",
	MAIN_CONTAINER = "settingsContainer",
	ELEMENT_LIGHTS_PROFILE = "lightsProfileElement",
	ELEMENT_TERRAIN_LOD_DISTANCE = "terrainLODDistanceElement",
	ELEMENT_LOD_DISTANCE = "lodDistanceElement",
	ELEMENT_REAL_BEACON_LIGHTS = "realBeaconLightsElement",
	ELEMENT_VOLUME_MESH_TESSELLATION = "volumeMeshTessellationElement",
	ELEMENT_MSAA = "msaaElement",
	ELEMENT_TERRAIN_QUALITY = "terrainQualityElement",
	ELEMENT_MAX_LIGHTS = "maxLightsElement",
	ELEMENT_TEXTURE_FILTERING = "textureFilteringElement"
}

function SettingsAdvancedFrame:new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement:new(target, custom_mt or SettingsAdvancedFrame_mt)

	self:registerControls(SettingsAdvancedFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.hasCustomMenuButtons = true

	return self
end

function SettingsAdvancedFrame:copyAttributes(src)
	SettingsAdvancedFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsAdvancedFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsAdvancedFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}
end

function SettingsAdvancedFrame:onApplySettings()
	local needsRestart = self.settingsModel:needsRestartToApplyChanges()

	self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)

	if needsRestart then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		restartApplication("")
	else
		self:setMenuButtonInfoDirty()
	end
end

function SettingsAdvancedFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	return buttons
end

function SettingsAdvancedFrame:updateValues()
	self:updatePerformanceClass()
	self.performanceClassElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
	self.msaaElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.MSAA))
	self.textureFilteringElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.TEXTURE_FILTERING))
	self.textureResolutionElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.TEXTURE_RESOLUTION))
	self.shadowQualityElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.SHADOW_QUALITY))
	self.shaderQualityElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.SHADER_QUALITY))
	self.shadowMapFilteringElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING))
	self.maxLightsElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.MAX_LIGHTS))
	self.terrainQualityElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.TERRAIN_QUALITY))
	self.objectDrawDistanceElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE))
	self.foliageDrawDistanceElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE))
	self.lodDistanceElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.LOD_DISTANCE))
	self.terrainLODDistanceElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE))
	self.volumeMeshTessellationElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION))
	self.maxTireTracksElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.MAX_TIRE_TRACKS))
	self.lightsProfileElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.LIGHTS_PROFILE))
	self.realBeaconLightsElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS))
	self.maxMirrorsElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.MAX_MIRRORS))
	self:setMenuButtonInfoDirty()
end

function SettingsAdvancedFrame:onFrameOpen()
	self:updateValues()
end

function SettingsAdvancedFrame:getMainElementSize()
	return self.settingsContainer.size
end

function SettingsAdvancedFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function SettingsAdvancedFrame:updatePerformanceClass()
	local texts, _, _ = self.settingsModel:getPerformanceClassTexts()

	self.performanceClassElement:setTexts(texts)
end

function SettingsAdvancedFrame:onCreatePerformanceClass(element)
	local texts, _, _ = self.settingsModel:getPerformanceClassTexts()

	element:setTexts(texts)
end

function SettingsAdvancedFrame:onCreateMSAA(element)
	element:setTexts(self.settingsModel:getMSAATexts())
end

function SettingsAdvancedFrame:onCreateShadowQuality(element)
	element:setTexts(self.settingsModel:getShadowQualityTexts())
end

function SettingsAdvancedFrame:onCreateShaderQuality(element)
	element:setTexts(self.settingsModel:getShaderQualityTexts())
end

function SettingsAdvancedFrame:onCreateTextureFiltering(element)
	element:setTexts(self.settingsModel:getTextureFilteringTexts())
end

function SettingsAdvancedFrame:onCreateTextureResolution(element)
	element:setTexts(self.settingsModel:getTextureResolutionTexts())
end

function SettingsAdvancedFrame:onCreateShadowMapFiltering(element)
	element:setTexts(self.settingsModel:getShadowMapFilteringTexts())
end

function SettingsAdvancedFrame:onCreateLightsProfile(element)
	element:setTexts(self.settingsModel:getLightsProfileTexts())
end

function SettingsAdvancedFrame:onCreateTerrainQuality(element)
	element:setTexts(self.settingsModel:getTerraingQualityTexts())
end

function SettingsAdvancedFrame:onCreateShadowMaxLights(element)
	element:setTexts(self.settingsModel:getShadowMapLightsTexts())
end

function SettingsAdvancedFrame:onCreateObjectDrawDistance(element)
	element:setTexts(self.settingsModel:getObjectDrawDistanceTexts())
end

function SettingsAdvancedFrame:onCreateFoliageDrawDistance(element)
	element:setTexts(self.settingsModel:getFoliageDrawDistanceTexts())
end

function SettingsAdvancedFrame:onCreateLODDistance(element)
	element:setTexts(self.settingsModel:getLODDistanceTexts())
end

function SettingsAdvancedFrame:onCreateTerrainLODDistance(element)
	element:setTexts(self.settingsModel:getTerrainLODDistanceTexts())
end

function SettingsAdvancedFrame:onCreateVolumeMeshTessellation(element)
	element:setTexts(self.settingsModel:getVolumeMeshTessalationTexts())
end

function SettingsAdvancedFrame:onCreateMaxTireTracks(element)
	element:setTexts(self.settingsModel:getMaxTireTracksTexts())
end

function SettingsAdvancedFrame:onCreateMaxMirrors(element)
	element:setTexts(self.settingsModel:getMaxMirrorsTexts())
end

function SettingsAdvancedFrame:onClickPerformanceClass(state)
	self.settingsModel:applyPerformanceClass(state)
	self:updateValues()
end

function SettingsAdvancedFrame:onClickMSAA(state)
	self.settingsModel:setValue(SettingsModel.SETTING.MSAA, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickTextureFiltering(state)
	self.settingsModel:setValue(SettingsModel.SETTING.TEXTURE_FILTERING, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickTextureResolution(state)
	self.settingsModel:setValue(SettingsModel.SETTING.TEXTURE_RESOLUTION, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickShadowQuality(state)
	self.settingsModel:setValue(SettingsModel.SETTING.SHADOW_QUALITY, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickShaderQuality(state)
	self.settingsModel:setValue(SettingsModel.SETTING.SHADER_QUALITY, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickShadowMapFiltering(state)
	self.settingsModel:setValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickShadowMaxLights(state)
	self.settingsModel:setValue(SettingsModel.SETTING.MAX_LIGHTS, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickTerrainQuality(state)
	self.settingsModel:setValue(SettingsModel.SETTING.TERRAIN_QUALITY, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickObjectDrawDistance(state)
	self.settingsModel:setValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickFoliageDrawDistance(state)
	self.settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickLODDistance(state)
	self.settingsModel:setValue(SettingsModel.SETTING.LOD_DISTANCE, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickTerrainLODDistance(state)
	self.settingsModel:setValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickVolumeMeshTessellation(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickMaxTireTracks(state)
	self.settingsModel:setValue(SettingsModel.SETTING.MAX_TIRE_TRACKS, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickLightsProfile(state)
	self.settingsModel:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickRealBeaconLights(state)
	self.settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickMaxMirrors(state)
	self.settingsModel:setValue(SettingsModel.SETTING.MAX_MIRRORS, state)
	self.settingsModel:applyCustomSettings()
	self:updateValues()
end

SettingsAdvancedFrame.L10N_SYMBOL = {
	BUTTON_APPLY = "button_apply"
}
