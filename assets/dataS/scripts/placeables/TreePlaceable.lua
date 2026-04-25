TreePlaceable = {}
local TreePlaceable_mt = Class(TreePlaceable, Placeable)

InitStaticObjectClass(TreePlaceable, "TreePlaceable", ObjectIds.OBJECT_TREE_PLACEABLE)

function TreePlaceable:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = TreePlaceable_mt
	end

	local self = Placeable:new(isServer, isClient, mt)
	self.useMultiRootNode = true

	registerObjectClassName(self, "TreePlaceable")

	return self
end

function TreePlaceable:delete()
	unregisterObjectClassName(self)
	TreePlaceable:superClass().delete(self)
end

function TreePlaceable:readStream(streamId, connection)
	TreePlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local serverSplitShapeFileId = streamReadInt32(streamId)

		if self.splitShapeFileId ~= nil and self.splitShapeFileId >= 0 and serverSplitShapeFileId >= 0 then
			setSplitShapesFileIdMapping(self.splitShapeFileId, serverSplitShapeFileId)
		end
	end
end

function TreePlaceable:writeStream(streamId, connection)
	TreePlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteInt32(streamId, Utils.getNoNil(self.splitShapeFileId, -1))
	end
end

function TreePlaceable:createNode(i3dFilename)
	setSplitShapesLoadingFileId(-1)
	setSplitShapesNextFileId(true)
	g_i3DManager:fillSharedI3DFileCache(i3dFilename, nil)
	setSplitShapesLoadingFileId(Utils.getNoNil(self.splitShapeFileId, -1))

	self.splitShapeFileId = setSplitShapesNextFileId()

	if not TreePlaceable:superClass().createNode(self, i3dFilename) then
		return false
	end

	if getNumOfChildren(self.nodeId) > 0 then
		local child = getChildAt(self.nodeId, 0)

		if getNumOfChildren(child) > 0 then
			local child = getChildAt(child, 0)

			if getNumOfChildren(child) > 0 then
				self.attachments = getChildAt(child, 0)
			end
		end
	end

	if self.attachments ~= nil then
		setVisibility(self.attachments, false)
	end

	return true
end

function TreePlaceable:finalizePlacement()
	local numChildren = getNumOfChildren(self.nodeId)

	for i = 0, numChildren - 1 do
		local child = getChildAt(self.nodeId, i)

		if getIsSplitShapeSplit(child) then
			setWorldRotation(child, getRotation(child))
			setWorldTranslation(child, getTranslation(child))
		end
	end

	TreePlaceable:superClass().finalizePlacement(self)

	if self.attachments ~= nil then
		setVisibility(self.attachments, true)
	end
end

function TreePlaceable:getNeedsSaving()
	if getNumOfChildren(self.nodeId) == 0 or self.splitShapeFileId ~= nil and not getFileIdHasSplitShapes(self.splitShapeFileId) then
		self:delete()

		return false
	end

	return TreePlaceable:superClass().getNeedsSaving(self)
end

function TreePlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	self.splitShapeFileId = getXMLInt(xmlFile, key .. "#splitShapeFileId")

	if not TreePlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	return true
end

function TreePlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	TreePlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	if self.splitShapeFileId ~= nil then
		setXMLInt(xmlFile, key .. "#splitShapeFileId", self.splitShapeFileId)
	end
end
