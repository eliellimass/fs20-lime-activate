g_guiElementCount = 0
g_guiElements = {}
allGuis = {}
allOverlays = {}
local oldDoExit = doExit

function doExit()
	for _, gui in ipairs(allGuis) do
		log("delete gui", gui.name, gui, gui.target, ClassUtil.getClassNameByObject(gui), ClassUtil.getClassNameByObject(gui.target))
		gui:delete()
		gui.target:delete()
	end

	g_inputDisplayManager:delete()

	for overlay, trace in pairs(allOverlays) do
		log(overlay, overlay.filename)
		log(trace)
	end

	log("----> do exit", g_guiElementCount)
	oldDoExit()
end

local oldDraw = draw

function draw(...)
	renderText(0.5, 0.5, getCorrectTextSize(0.1), tostring(g_guiElementCount))
	oldDraw(...)
end

local oldOverlayNew = Overlay.new

function Overlay.new(...)
	local self = oldOverlayNew(...)
	allOverlays[self] = debug.traceback()

	return self
end

local oldOverlayDelete = Overlay.delete

function Overlay:delete()
	allOverlays[self] = nil

	oldOverlayDelete(self)
end

local oldLoadGui = Gui.loadGui

function Gui.loadGui(...)
	local gui = oldLoadGui(...)

	log("load gui", gui.name)
	table.insert(allGuis, gui)

	return gui
end

local oldGuiElementNew = GuiElement.new

function GuiElement.new(...)
	local self = oldGuiElementNew(...)
	g_guiElementCount = g_guiElementCount + 1
	g_guiElements[self] = debug.traceback()

	return self
end

local oldGuiElementDelete = GuiElement.delete

function GuiElement:delete(...)
	g_guiElements[self] = nil
	g_guiElementCount = g_guiElementCount - 1

	oldGuiElementDelete(self, ...)
end
