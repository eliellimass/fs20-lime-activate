VideoElement = {}
local VideoElement_mt = Class(VideoElement, GuiElement)

function VideoElement:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = VideoElement_mt
	end

	local self = GuiElement:new(target, custom_mt)
	self.videoFilename = nil
	self.allowStop = true
	self.isLooping = false
	self.volume = 1

	return self
end

function VideoElement:loadFromXML(xmlFile, key)
	VideoElement:superClass().loadFromXML(self, xmlFile, key)

	self.videoFilename = Utils.getNoNil(getXMLString(xmlFile, key .. "#videoFilename"), self.videoFilename)
	self.volume = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#volume"), self.volume)
	self.allowStop = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowStop"), self.allowStop)
	self.isLooping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLooping"), self.isLooping)

	self:addCallback(xmlFile, key .. "#onEndVideo", "onEndVideoCallback")
	self:changeVideo(self.videoFilename)
end

function VideoElement:loadProfile(profile, applyProfile)
	VideoElement:superClass().loadProfile(self, profile, applyProfile)

	self.videoFilename = profile:getValue("videoFilename", self.videoFilename)
	self.volume = profile:getNumber("volume", self.volume)
	self.allowStop = profile:getBool("allowStop", self.allowStop)
	self.isLooping = profile:getBool("isLooping", self.isLooping)
end

function VideoElement:copyAttributes(src)
	VideoElement:superClass().copyAttributes(self, src)
	self:changeVideo(src.videoFilename)

	self.volume = src.volume
	self.allowStop = src.allowStop
	self.isLooping = src.isLooping
	self.onEndVideoCallback = src.onEndVideoCallback
end

function VideoElement:delete()
	self:disposeVideo()
	VideoElement:superClass().delete(self)
end

function VideoElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if VideoElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		local ret = eventUsed

		if not eventUsed and self.allowStop then
			ret = true

			if isDown and self.overlay ~= nil then
				self:disposeVideo()
				self:onEndVideo()
			end

			return ret
		end
	end

	return eventUsed
end

function VideoElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if self:getIsActive() then
		if VideoElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
			eventUsed = true
		end

		local ret = eventUsed
		ret = true

		if isDown and self.overlay ~= nil then
			self:disposeVideo()
			self:onEndVideo()
		end

		return ret
	end

	return eventUsed
end

function VideoElement:update(dt)
	VideoElement:superClass().update(self, dt)

	if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
		updateVideoOverlay(self.overlay)
	elseif self.overlay ~= nil then
		self:disposeVideo()
		self:onEndVideo()
	end
end

function VideoElement:draw()
	if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
		renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2])
	end

	VideoElement:superClass().draw(self)
end

function VideoElement:onEndVideo()
	if self.onEndVideoCallback ~= nil then
		if self.target ~= nil then
			self.onEndVideoCallback(self.target)
		else
			self.onEndVideoCallback()
		end
	end
end

function VideoElement:disposeVideo()
	if self.overlay ~= nil then
		self:stopVideo()
		delete(self.overlay)

		self.overlay = nil
	end
end

function VideoElement:getIsActive()
	return self:getIsVisible()
end

function VideoElement:playVideo()
	if self.overlay ~= nil then
		playVideoOverlay(self.overlay)
	end
end

function VideoElement:stopVideo()
	if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
		stopVideoOverlay(self.overlay)
	end
end

function VideoElement:changeVideo(newVideoFilename)
	self:disposeVideo()

	self.videoFilename = newVideoFilename

	if self.videoFilename ~= nil then
		local videoFilename = string.gsub(self.videoFilename, "$l10nSuffix", g_gui.languageSuffix)
		self.overlay = createVideoOverlay(videoFilename, self.isLooping, self.volume)
	end
end
