function string.dump()
	return ""
end

function loadfile()
end

function load()
	return nil, "invalid function"
end

function string.posixFormat(fmt, ...)
	local args = {
		...
	}
	local order = {}
	fmt = fmt:gsub("([%%]?)%%(%d+)%$", function (first, i)
		if first == "%" then
			return "%%" .. i .. "$"
		end

		table.insert(order, args[tonumber(i)])

		return "%"
	end)

	if #order == 0 then
		return string.format(fmt, ...)
	end

	return string.format(fmt, unpack(order))
end

if math.mod == nil then
	math.mod = math.fmod
end

if getProfileUiResolutionScaling == nil then
	function getProfileUiResolutionScaling()
		return 1
	end
end

if InAppPurchase.ERROR_PENDING_PAYMENT == nil then
	InAppPurchase.ERROR_PENDING_PAYMENT = 5
end

if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PC then
	GS_PLATFORM_TYPE = GS_PLATFORM_TYPE_ANDROID
end

GS_IS_CONSOLE_VERSION = GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE
GS_IS_MOBILE_VERSION = GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_IOS or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH
GS_PROFILE_LOW = 1
GS_PROFILE_MEDIUM = 2
GS_PROFILE_HIGH = 3
GS_PROFILE_VERY_HIGH = 4
g_gameVersion = 1
g_gameVersionNotification = "1.1.13.0"
g_gameVersionDisplay = "1.1.13.0"
g_gameVersionDisplayExtra = ""
g_isPresentationVersion = false
g_isPresentationVersionLogoEnabled = false
g_isPresentationVersionShopEnabled = false
g_isPresentationVersionDlcEnabled = false
g_isPresentationVersionAllMapsEnabled = false
g_isPresentationVersionSpecialStore = false
g_isPresentationVersionSpecialStorePath = "dataS/storeItems_presentationVersion.xml"
g_isPresentationVersionAIDeactivated = false
g_isPresentationVersionHideMenuButtons = false
g_isPresentationVersionUseReloadButton = false
g_isPresentationVersionSaveGameOnQuit = false
g_showWatermark = false
g_isDevelopmentConsoleScriptModTesting = false
g_leagueBuild = false
g_isPresentationVersionPlaytimeCountdown = nil
g_minModDescVersion = 40
g_maxModDescVersion = 43
GS_PERFORMANCE_CLASS_PRESETS = {
	{
		maxNumMirrors = 0,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_LOW
	},
	{
		maxNumMirrors = 0,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_MEDIUM
	},
	{
		maxNumMirrors = 3,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_HIGH
	},
	{
		maxNumMirrors = 4,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_VERY_HIGH
	}
}
GS_INPUT_HELP_MODE_AUTO = 1
GS_INPUT_HELP_MODE_KEYBOARD = 2
GS_INPUT_HELP_MODE_GAMEPAD = 3
GS_INPUT_HELP_MODE_TOUCH = 4
GS_PRIO_VERY_HIGH = 1
GS_PRIO_HIGH = 2
GS_PRIO_NORMAL = 3
GS_PRIO_LOW = 4
GS_PRIO_VERY_LOW = 5
GS_MONEY_EURO = 1
GS_MONEY_DOLLAR = 2
GS_MONEY_POUND = 3
g_registeredConsoleCommands = {}
local oldAddConsoleCommand = addConsoleCommand

function addConsoleCommand(name, ...)
	if g_registeredConsoleCommands[name] == nil then
		oldAddConsoleCommand(name, ...)

		g_registeredConsoleCommands[name] = true
	else
		print(string.format("Error: Failed to register console command '%s! Command was already registered!", name))
	end
end

local oldRemoveConsoleCommand = removeConsoleCommand

function removeConsoleCommand(name, ...)
	oldRemoveConsoleCommand(name, ...)

	g_registeredConsoleCommands[name] = nil
end

g_registeredTriggers = {}
local oldAddTrigger = addTrigger

function addTrigger(objectId, ...)
	oldAddTrigger(objectId, ...)

	g_registeredTriggers[objectId] = objectId
end

local oldRemoveTrigger = removeTrigger

function removeTrigger(objectId, ...)
	oldRemoveTrigger(objectId, ...)

	g_registeredTriggers[objectId] = nil
end

function getIsTrigger(objectId)
	return g_registeredTriggers[objectId] ~= nil
end

source("dataS/scripts/shared/input.lua")
source("dataS/scripts/shared/scenegraph.lua")
source("dataS/scripts/shared/class.lua")
source("dataS/scripts/shared/graph.lua")
source("dataS/scripts/misc/AbstractManager.lua")
source("dataS/scripts/misc/LogManager.lua")
source("dataS/scripts/drawing.lua")
source("dataS/scripts/collections/DataGrid.lua")
source("dataS/scripts/collections/MapDataGrid.lua")
source("dataS/scripts/collections/PolygonChain.lua")
source("dataS/scripts/collections/ValueBuffer.lua")
source("dataS/scripts/collections/SimpleState.lua")
source("dataS/scripts/collections/SimpleStateMachine.lua")
source("dataS/scripts/debug/DebugUtil.lua")
source("dataS/scripts/debug/DebugManager.lua")
source("dataS/scripts/debug/elements/DebugCube.lua")
source("dataS/scripts/debug/elements/DebugGizmo.lua")
source("dataS/scripts/debug/elements/DebugText.lua")
source("dataS/scripts/debug/elements/DebugInfoTable.lua")
source("dataS/scripts/utils/FSMUtil.lua")
source("dataS/scripts/utils/ClassUtil.lua")
source("dataS/scripts/utils/Utils.lua")
source("dataS/scripts/utils/XMLUtil.lua")
source("dataS/scripts/utils/ParticleUtil.lua")
source("dataS/scripts/utils/ChainsawUtil.lua")
source("dataS/scripts/utils/DynamicMountUtil.lua")
source("dataS/scripts/utils/FSDensityMapUtil.lua")
source("dataS/scripts/utils/HTMLUtil.lua")
source("dataS/scripts/utils/IKUtil.lua")
source("dataS/scripts/utils/ListUtil.lua")
source("dataS/scripts/utils/MathUtil.lua")
source("dataS/scripts/utils/MapPerformanceTestUtil.lua")
source("dataS/scripts/utils/ObjectChangeUtil.lua")
source("dataS/scripts/utils/PlacementUtil.lua")
source("dataS/scripts/utils/SplineUtil.lua")
source("dataS/scripts/utils/StringUtil.lua")
source("dataS/scripts/utils/PlatformPrivilegeUtil.lua")
source("dataS/scripts/utils/RaycastUtil.lua")
source("dataS/scripts/misc/AsyncManager.lua")
source("dataS/scripts/misc/DeferredLoadingManager.lua")
source("dataS/scripts/GameState.lua")
source("dataS/scripts/GameStateManager.lua")
source("dataS/scripts/Shader.lua")
source("dataS/scripts/GameSettings.lua")
source("dataS/scripts/MessageCenter.lua")
source("dataS/scripts/Files.lua")
source("dataS/scripts/io.lua")
source("dataS/scripts/MoneyType.lua")
source("dataS/scripts/network/NetworkUtil.lua")
source("dataS/scripts/network/EventIds.lua")
source("dataS/scripts/network/ObjectIds.lua")
source("dataS/scripts/network/Object.lua")
source("dataS/scripts/network/NetworkNode.lua")
source("dataS/scripts/network/Client.lua")
source("dataS/scripts/network/Server.lua")
source("dataS/scripts/network/Connection.lua")
source("dataS/scripts/network/Event.lua")
source("dataS/scripts/network/MessageIds.lua")
source("dataS/scripts/network/ConnectionManager.lua")
source("dataS/scripts/network/MasterServerConnection.lua")
source("dataS/scripts/interpolation/InterpolationTime.lua")
source("dataS/scripts/interpolation/InterpolatorAngle.lua")
source("dataS/scripts/interpolation/InterpolatorPosition.lua")
source("dataS/scripts/interpolation/InterpolatorQuaternion.lua")
source("dataS/scripts/interpolation/InterpolatorValue.lua")
source("dataS/scripts/I18N.lua")
source("dataS/scripts/gui/base/Overlay.lua")
source("dataS/scripts/gui/base/ButtonOverlay.lua")
source("dataS/scripts/gui/base/RoundStatusBar.lua")
source("dataS/scripts/gui/base/StatusBar.lua")
source("dataS/scripts/input/InputBinding.lua")
source("dataS/scripts/input/InputHelper.lua")
source("dataS/scripts/input/InputDisplayManager.lua")
source("dataS/scripts/input/TouchHandler.lua")
source("dataS/scripts/gui/base/InGameIcon.lua")
source("dataS/scripts/missions/SavegameController.lua")
source("dataS/scripts/missions/StartMissionInfo.lua")
source("dataS/scripts/gui/base/Gui.lua")
Gui.initGuiLibrary("dataS/scripts/gui")

Gui.initGuiLibrary = nil

source("dataS/scripts/gui/hud/HUD.lua")
source("dataS/scripts/gui/hud/MobileHUD.lua")
source("dataS/scripts/missions/MissionCollaborators.lua")
source("dataS/scripts/BaseMission.lua")
source("dataS/scripts/FSBaseMission.lua")
source("dataS/scripts/missions/mission00.lua")
source("dataS/scripts/tutorials/Tutorial.lua")
source("dataS/scripts/gui/base/SettingsModel.lua")
source("dataS/scripts/RestartManager.lua")
source("dataS/scripts/ai/HelperManager.lua")
source("dataS/scripts/ai/NPCManager.lua")
source("dataS/scripts/animals/AnimalManager.lua")
source("dataS/scripts/animals/AnimalFoodManager.lua")
source("dataS/scripts/animals/AnimalNameManager.lua")
source("dataS/scripts/densityMaps/DensityMapHeightUtil.lua")
source("dataS/scripts/densityMaps/DensityMapHeightManager.lua")
source("dataS/scripts/densityMaps/FSDensityMapModifier.lua")
source("dataS/scripts/densityMaps/DensityMapHeightModifier.lua")
source("dataS/scripts/fieldJobs/FieldUtil.lua")
source("dataS/scripts/fieldJobs/Field.lua")
source("dataS/scripts/fieldJobs/FieldManager.lua")
source("dataS/scripts/fieldJobs/MissionManager.lua")
source("dataS/scripts/fieldJobs/AbstractMission.lua")
source("dataS/scripts/fieldJobs/AbstractFieldMission.lua")
source("dataS/scripts/fieldJobs/BaleMission.lua")
source("dataS/scripts/fieldJobs/PlowMission.lua")
source("dataS/scripts/fieldJobs/CultivateMission.lua")
source("dataS/scripts/fieldJobs/SowMission.lua")
source("dataS/scripts/fieldJobs/HarvestMission.lua")
source("dataS/scripts/fieldJobs/WeedMission.lua")
source("dataS/scripts/fieldJobs/SprayMission.lua")
source("dataS/scripts/fieldJobs/FertilizeMission.lua")
source("dataS/scripts/fieldJobs/TransportMission.lua")
source("dataS/scripts/fieldJobs/events/MissionStartEvent.lua")
source("dataS/scripts/fieldJobs/events/MissionStartedEvent.lua")
source("dataS/scripts/fieldJobs/events/MissionCancelEvent.lua")
source("dataS/scripts/fieldJobs/events/MissionDismissEvent.lua")
source("dataS/scripts/fieldJobs/events/MissionFinishedEvent.lua")
source("dataS/scripts/i3d/I3DUtil.lua")
source("dataS/scripts/i3d/I3DManager.lua")
source("dataS/scripts/i3d/FoliageXmlUtil.lua")
source("dataS/scripts/misc/AutoSaveManager.lua")
source("dataS/scripts/misc/BaleTypeManager.lua")
source("dataS/scripts/misc/BrandColorManager.lua")
source("dataS/scripts/misc/ConnectionHoseManager.lua")
source("dataS/scripts/misc/DepthOfFieldManager.lua")
source("dataS/scripts/misc/FillTypeManager.lua")
source("dataS/scripts/misc/FruitTypeManager.lua")
source("dataS/scripts/misc/GameplayHintManager.lua")
source("dataS/scripts/misc/GamingStationManager.lua")
source("dataS/scripts/misc/HelpLineManager.lua")
source("dataS/scripts/misc/MapManager.lua")
source("dataS/scripts/misc/ModManager.lua")
source("dataS/scripts/misc/PlaceableTypeManager.lua")
source("dataS/scripts/misc/PlatformSettingsManager.lua")
source("dataS/scripts/misc/PreorderBonusManager.lua")
source("dataS/scripts/misc/SleepManager.lua")
source("dataS/scripts/misc/SplitTypeManager.lua")
source("dataS/scripts/misc/SprayTypeManager.lua")
source("dataS/scripts/misc/TreePlantManager.lua")
source("dataS/scripts/misc/TensionBeltManager.lua")
source("dataS/scripts/misc/ToolTypeManager.lua")
source("dataS/scripts/misc/GroundTypeManager.lua")
source("dataS/scripts/misc/LifetimeStats.lua")
source("dataS/scripts/materials/MaterialUtil.lua")
source("dataS/scripts/materials/CutterEffectManager.lua")
source("dataS/scripts/materials/MaterialManager.lua")
source("dataS/scripts/materials/ParticleSystemManager.lua")
source("dataS/scripts/modHub/ModCategoryInfo.lua")
source("dataS/scripts/modHub/ModInfo.lua")
source("dataS/scripts/pedestrian/PedestrianSystem.lua")
source("dataS/scripts/terrainDeformation/TerrainDeformation.lua")
source("dataS/scripts/terrainDeformation/TerrainDeformationQueue.lua")
source("dataS/scripts/terrainDeformation/LandscapingSculptEvent.lua")
source("dataS/scripts/terrainDeformation/Landscaping.lua")
source("dataS/scripts/terrainDeformation/FoliagePainter.lua")
source("dataS/scripts/shop/BrandManager.lua")
source("dataS/scripts/shop/StoreItemUtil.lua")
source("dataS/scripts/shop/StoreManager.lua")
source("dataS/scripts/shop/ShopDisplayItem.lua")
source("dataS/scripts/iap/InAppPurchaseController.lua")
source("dataS/scripts/iap/IAProduct.lua")
source("dataS/scripts/sounds/AudioGroup.lua")
source("dataS/scripts/sounds/AmbientSoundManager.lua")
source("dataS/scripts/sounds/AmbientSoundUtil.lua")
source("dataS/scripts/sounds/SoundPlayer.lua")
source("dataS/scripts/sounds/SoundManager.lua")
source("dataS/scripts/sounds/SoundNode.lua")
source("dataS/scripts/sounds/RandomSound.lua")
source("dataS/scripts/sounds/DailySound.lua")
source("dataS/scripts/sounds/SoundMixer.lua")
source("dataS/scripts/gui/base/GuiSoundPlayer.lua")
source("dataS/scripts/traffic/TrafficSystem.lua")
source("dataS/scripts/gui/base/GuiTopDownCamera.lua")
source("dataS/scripts/gui/PlacementScreenController.lua")
source("dataS/scripts/gui/LandscapingScreenController.lua")
source("dataS/scripts/gui/ControlsController.lua")
source("dataS/scripts/gui/ShopController.lua")
source("dataS/scripts/gui/ModHubController.lua")
source("dataS/scripts/gui/base/MapOverlayGenerator.lua")
source("dataS/scripts/gui/base/FocusManager.lua")
source("dataS/scripts/gui/base/TabbedMenu.lua")
source("dataS/scripts/gui/base/TabbedMenuWithDetails.lua")
source("dataS/scripts/gui/elements/TabbedMenuFrameElement.lua")
source("dataS/scripts/gui/SettingsGeneralFrame.lua")
source("dataS/scripts/gui/SettingsDisplayFrame.lua")
source("dataS/scripts/gui/SettingsAdvancedFrame.lua")
source("dataS/scripts/gui/SettingsConsoleFrame.lua")
source("dataS/scripts/gui/SettingsDeviceFrame.lua")
source("dataS/scripts/gui/SettingsControlsFrame.lua")
source("dataS/scripts/gui/InGameMenuAnimalsFrame.lua")

if GS_IS_MOBILE_VERSION then
	source("dataS/scripts/gui/InGameMenuAnimalsFrameMobile.lua")
end

source("dataS/scripts/gui/InGameMenuContractsFrame.lua")
source("dataS/scripts/gui/InGameMenuFinancesFrame.lua")
source("dataS/scripts/gui/InGameMenuGeneralSettingsFrame.lua")
source("dataS/scripts/gui/InGameMenuGameSettingsFrame.lua")
source("dataS/scripts/gui/InGameMenuMobileSettingsFrame.lua")
source("dataS/scripts/gui/InGameMenuHelpFrame.lua")
source("dataS/scripts/gui/InGameMenuMainFrame.lua")
source("dataS/scripts/gui/InGameMenuMapFrame.lua")
source("dataS/scripts/gui/InGameMenuMultiplayerFarmsFrame.lua")
source("dataS/scripts/gui/InGameMenuMultiplayerUsersFrame.lua")
source("dataS/scripts/gui/InGameMenuPricesFrame.lua")
source("dataS/scripts/gui/InGameMenuStatisticsFrame.lua")
source("dataS/scripts/gui/InGameMenuTutorialFrame.lua")
source("dataS/scripts/gui/InGameMenuVehiclesFrame.lua")
source("dataS/scripts/gui/InGameMenuTutorialFrame.lua")
source("dataS/scripts/gui/ShopCategoriesFrame.lua")
source("dataS/scripts/gui/ShopItemsFrame.lua")
source("dataS/scripts/gui/ShopLandscapingFrame.lua")
source("dataS/scripts/gui/ModHubLoadingFrame.lua")
source("dataS/scripts/gui/ModHubCategoriesFrame.lua")
source("dataS/scripts/gui/ModHubItemsFrame.lua")
source("dataS/scripts/gui/ModHubDetailsFrame.lua")
source("dataS/scripts/gui/AchievementsScreen.lua")
source("dataS/scripts/gui/AnimalScreen.lua")
source("dataS/scripts/gui/CareerScreen.lua")
source("dataS/scripts/gui/CharacterCreationScreen.lua")
source("dataS/scripts/gui/ConnectToMasterServerScreen.lua")
source("dataS/scripts/gui/CreateGameScreen.lua")
source("dataS/scripts/gui/DifficultyScreen.lua")
source("dataS/scripts/gui/GamepadSigninScreen.lua")
source("dataS/scripts/gui/ChinaSigninScreen.lua")
source("dataS/scripts/gui/InGameMenu.lua")
source("dataS/scripts/gui/ShopMenu.lua")
source("dataS/scripts/gui/JoinGameScreen.lua")
source("dataS/scripts/gui/MainScreen.lua")
source("dataS/scripts/gui/MapSelectionScreen.lua")
source("dataS/scripts/gui/ModSelectionScreen.lua")
source("dataS/scripts/gui/MPLoadingScreen.lua")
source("dataS/scripts/gui/MultiplayerScreen.lua")
source("dataS/scripts/gui/PlacementScreen.lua")
source("dataS/scripts/gui/LandscapingScreen.lua")
source("dataS/scripts/gui/SelectMasterServerScreen.lua")
source("dataS/scripts/gui/ServerDetailScreen.lua")
source("dataS/scripts/gui/SettingsScreen.lua")
source("dataS/scripts/gui/ShopConfigScreen.lua")
source("dataS/scripts/gui/StartupScreen.lua")
source("dataS/scripts/gui/TutorialScreen.lua")
source("dataS/scripts/gui/CreditsScreen.lua")
source("dataS/scripts/gui/dialogs/MessageDialog.lua")
source("dataS/scripts/gui/dialogs/YesNoDialog.lua")
source("dataS/scripts/gui/dialogs/InfoDialog.lua")
source("dataS/scripts/gui/dialogs/SleepDialog.lua")
source("dataS/scripts/gui/dialogs/ConnectionFailedDialog.lua")
source("dataS/scripts/gui/dialogs/TextInputDialog.lua")
source("dataS/scripts/gui/dialogs/ColorPickerDialog.lua")
source("dataS/scripts/gui/dialogs/SavegameConflictDialog.lua")
source("dataS/scripts/gui/dialogs/ChatDialog.lua")
source("dataS/scripts/gui/dialogs/DenyAcceptDialog.lua")
source("dataS/scripts/gui/dialogs/SiloDialog.lua")
source("dataS/scripts/gui/dialogs/AnimalDialog.lua")
source("dataS/scripts/gui/dialogs/TransferMoneyDialog.lua")
source("dataS/scripts/gui/dialogs/DirectSellDialog.lua")
source("dataS/scripts/gui/dialogs/SellItemDialog.lua")
source("dataS/scripts/gui/dialogs/EditFarmDialog.lua")
source("dataS/scripts/gui/dialogs/UnBanDialog.lua")
source("dataS/scripts/gui/dialogs/ServerSettingsDialog.lua")
source("dataS/scripts/gui/dialogs/VoteDialog.lua")
source("dataS/scripts/gui/dialogs/GameRateDialog.lua")
source("dataS/scripts/gui/dialogs/ChinaAgeRatingDialog.lua")
source("dataS/scripts/gui/dialogs/ControlsIntroductionDialog.lua")
source("dataS/scripts/events/CheatMoneyEvent.lua")
source("dataS/scripts/events/ClientStartMissionEvent.lua")
source("dataS/scripts/events/GetAdminAnswerEvent.lua")
source("dataS/scripts/events/GetAdminEvent.lua")
source("dataS/scripts/events/KickBanEvent.lua")
source("dataS/scripts/events/KickBanNotificationEvent.lua")
source("dataS/scripts/events/MissionDynamicInfoEvent.lua")
source("dataS/scripts/events/SaveEvent.lua")
source("dataS/scripts/events/ResetVehicleEvent.lua")
source("dataS/scripts/events/ChangeVehicleConfigEvent.lua")
source("dataS/scripts/events/UnbanEvent.lua")
source("dataS/scripts/gui/ModHubScreen.lua")
source("dataS/scripts/MissionInfo.lua")
source("dataS/scripts/FSMissionInfo.lua")
source("dataS/scripts/FSCareerMissionInfo.lua")
source("dataS/scripts/FSTutorialMissionInfo.lua")
source("dataS/scripts/environment/Environment.lua")
source("dataS/scripts/environment/Lighting.lua")
source("dataS/scripts/environment/EnvironmentTimeEvent.lua")
source("dataS/scripts/environment/weather/Weather.lua")
source("dataS/scripts/environment/weather/CloudUpdater.lua")
source("dataS/scripts/environment/weather/TemperatureUpdater.lua")
source("dataS/scripts/environment/weather/WeatherFrontUpdater.lua")
source("dataS/scripts/environment/weather/WeatherObject.lua")
source("dataS/scripts/environment/weather/WeatherObjectRain.lua")
source("dataS/scripts/environment/weather/WeatherInstance.lua")
source("dataS/scripts/environment/weather/WeatherTypeManager.lua")
source("dataS/scripts/environment/weather/WindObject.lua")
source("dataS/scripts/environment/weather/WindUpdater.lua")
source("dataS/scripts/environment/weather/WeatherAddObjectEvent.lua")
source("dataS/scripts/environment/weather/WindObjectChangedEvent.lua")
source("dataS/scripts/environment/weather/FogUpdater.lua")
source("dataS/scripts/environment/weather/FogStateEvent.lua")
source("dataS/scripts/environment/weather/SkyBoxUpdater.lua")
source("dataS/scripts/AnimCurve.lua")
source("dataS/scripts/CameraPath.lua")
source("dataS/scripts/CameraFlightManager.lua")
source("dataS/scripts/events.lua")
source("dataS/scripts/AchievementManager.lua")
source("dataS/scripts/events/TreePlantEvent.lua")
source("dataS/scripts/events/TreeGrowEvent.lua")
source("dataS/scripts/events/MoneyChangeEvent.lua")
source("dataS/scripts/events/RequestMoneyChangeEvent.lua")
source("dataS/scripts/player/PlayerStateBase.lua")
source("dataS/scripts/player/PlayerStateAnimalFeed.lua")
source("dataS/scripts/player/PlayerStateAnimalPet.lua")
source("dataS/scripts/player/PlayerStateAnimalInteract.lua")
source("dataS/scripts/player/PlayerStateAnimalRide.lua")
source("dataS/scripts/player/PlayerStateCrouch.lua")
source("dataS/scripts/player/PlayerStateFall.lua")
source("dataS/scripts/player/PlayerStateIdle.lua")
source("dataS/scripts/player/PlayerStateJump.lua")
source("dataS/scripts/player/PlayerStateRun.lua")
source("dataS/scripts/player/PlayerStateSwim.lua")
source("dataS/scripts/player/PlayerStateWalk.lua")
source("dataS/scripts/player/PlayerStatePickup.lua")
source("dataS/scripts/player/PlayerStateDrop.lua")
source("dataS/scripts/player/PlayerStateThrow.lua")
source("dataS/scripts/player/PlayerStateUseLight.lua")
source("dataS/scripts/player/PlayerStateCycleHandtool.lua")
source("dataS/scripts/player/PlayerStateActivateObject.lua")
source("dataS/scripts/player/PlayerStateMachine.lua")
source("dataS/scripts/player/PlayerModelManager.lua")
source("dataS/scripts/player/PlayerStyle.lua")
source("dataS/scripts/player/Player.lua")
source("dataS/scripts/player/PlayerTeleportEvent.lua")
source("dataS/scripts/player/PlayerSetHandToolEvent.lua")
source("dataS/scripts/player/PlayerSetFarmEvent.lua")
source("dataS/scripts/player/PlayerSwitchedFarmEvent.lua")
source("dataS/scripts/player/PlayerPickUpObjectEvent.lua")
source("dataS/scripts/player/PlayerThrowObjectEvent.lua")
source("dataS/scripts/player/PlayerToggleLightEvent.lua")

if not GS_IS_CONSOLE_VERSION then
	source("dataS/scripts/events/ChatEvent.lua")
end

source("dataS/scripts/events/ShutdownEvent.lua")
source("dataS/scripts/events/SleepRequestEvent.lua")
source("dataS/scripts/events/SleepResponseEvent.lua")
source("dataS/scripts/events/StartSleepStateEvent.lua")
source("dataS/scripts/events/StopSleepStateEvent.lua")
source("dataS/scripts/objects/AnimatedObject.lua")
source("dataS/scripts/objects/AnimatedMapObject.lua")
source("dataS/scripts/objects/DigitalDisplay.lua")
source("dataS/scripts/objects/Windmill.lua")
source("dataS/scripts/objects/Nightlight.lua")
source("dataS/scripts/objects/Nightlight2.lua")
source("dataS/scripts/objects/NightlightFlicker.lua")
source("dataS/scripts/objects/NightIllumination.lua")
source("dataS/scripts/objects/Placeholders.lua")
source("dataS/scripts/objects/ChurchClock.lua")
source("dataS/scripts/objects/TimedVisibility.lua")
source("dataS/scripts/objects/TrashBag.lua")
source("dataS/scripts/objects/PhysicsObject.lua")
source("dataS/scripts/objects/MountableObject.lua")
source("dataS/scripts/objects/Bale.lua")
source("dataS/scripts/objects/Watermill.lua")
source("dataS/scripts/objects/AdBanner.lua")
source("dataS/scripts/objects/ObjectSpawner.lua")
source("dataS/scripts/objects/Basketball.lua")
source("dataS/scripts/objects/DogBall.lua")
source("dataS/scripts/objects/VendingMachine.lua")
source("dataS/scripts/objects/Can.lua")
source("dataS/scripts/objects/HelpIcons.lua")
source("dataS/scripts/objects/NightGlower.lua")
source("dataS/scripts/objects/FollowerSound.lua")
source("dataS/scripts/objects/Butterfly.lua")
source("dataS/scripts/objects/SunAdmirer.lua")
source("dataS/scripts/objects/VehicleSellingPoint.lua")
source("dataS/scripts/objects/Colorizer.lua")
source("dataS/scripts/objects/VehicleShopBase.lua")
source("dataS/scripts/objects/SimParticleSystem.lua")
source("dataS/scripts/objects/Rotator.lua")
source("dataS/scripts/objects/OilPump.lua")

if GS_IS_MOBILE_VERSION then
	source("dataS/scripts/objects/TourIconsMobile.lua")
else
	source("dataS/scripts/objects/TourIcons.lua")
end

source("dataS/scripts/objects/WaterLog.lua")
source("dataS/scripts/objects/Storage.lua")
source("dataS/scripts/objects/Ship.lua")
source("dataS/scripts/objects/StorageSystem.lua")
source("dataS/scripts/users/User.lua")
source("dataS/scripts/users/UserEvent.lua")
source("dataS/scripts/users/UserDataEvent.lua")
source("dataS/scripts/users/UserManager.lua")
source("dataS/scripts/vehicles/ConfigurationUtil.lua")
source("dataS/scripts/vehicles/ConfigurationManager.lua")
source("dataS/scripts/vehicles/SpecializationManager.lua")
source("dataS/scripts/vehicles/SpecializationUtil.lua")
source("dataS/scripts/vehicles/VehicleTypeManager.lua")
source("dataS/scripts/vehicles/WorkAreaTypeManager.lua")
source("dataS/scripts/vehicles/ai/AIVehicleUtil.lua")
source("dataS/scripts/vehicles/WheelsUtil.lua")
source("dataS/scripts/vehicles/VehicleActionController.lua")
source("dataS/scripts/vehicles/VehicleMotor.lua")
source("dataS/scripts/vehicles/VehicleCamera.lua")
source("dataS/scripts/vehicles/VehicleCharacter.lua")
source("dataS/scripts/vehicles/VehicleEnterRequestEvent.lua")
source("dataS/scripts/vehicles/VehicleEnterResponseEvent.lua")
source("dataS/scripts/vehicles/VehicleLeaveEvent.lua")
source("dataS/scripts/vehicles/VehicleAttachEvent.lua")
source("dataS/scripts/vehicles/VehicleDetachEvent.lua")
source("dataS/scripts/vehicles/VehicleBundleAttachEvent.lua")
source("dataS/scripts/vehicles/VehicleLowerImplementEvent.lua")
source("dataS/scripts/vehicles/TireTrackSystem.lua")
source("dataS/scripts/effects/FoliageBendingSystem.lua")
source("dataS/scripts/triggers/BasketTrigger.lua")
source("dataS/scripts/triggers/FillTrigger.lua")
source("dataS/scripts/triggers/BarrierTrigger.lua")
source("dataS/scripts/triggers/HotspotTrigger.lua")
source("dataS/scripts/triggers/InsideBuildingTrigger.lua")
source("dataS/scripts/triggers/ShopTrigger.lua")
source("dataS/scripts/triggers/SlideDoorTrigger.lua")
source("dataS/scripts/triggers/PalletSellTrigger.lua")
source("dataS/scripts/triggers/ElkTrigger.lua")
source("dataS/scripts/triggers/LoanTrigger.lua")
source("dataS/scripts/triggers/POITrigger.lua")
source("dataS/scripts/triggers/RainDropFactorTrigger.lua")
source("dataS/scripts/triggers/WeighStation.lua")
source("dataS/scripts/triggers/FillPlane.lua")
source("dataS/scripts/triggers/UnloadTrigger.lua")
source("dataS/scripts/triggers/BaleUnloadTrigger.lua")
source("dataS/scripts/triggers/LoadTrigger.lua")
source("dataS/scripts/triggers/LoadTriggerSetIsLoadingEvent.lua")
source("dataS/scripts/objects/UnloadingStation.lua")
source("dataS/scripts/objects/LoadingStation.lua")
source("dataS/scripts/objects/SellingStation.lua")
source("dataS/scripts/objects/SimpleBgaSellingStation.lua")
source("dataS/scripts/objects/BuyingStation.lua")
source("dataS/scripts/objects/BgaSellStation.lua")
source("dataS/scripts/triggers/UnloadFeedingTrough.lua")
source("dataS/scripts/objects/FillLevelListener.lua")
source("dataS/scripts/triggers/TransportMissionTrigger.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleBase.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleAnimals.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleFood.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleFoodSpillage.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleLiquidManure.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleManure.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModulePallets.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleStraw.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleWater.lua")
source("dataS/scripts/animals/AnimalHusbandryModules/HusbandryModuleMilk.lua")
source("dataS/scripts/objects/BunkerSilo.lua")
source("dataS/scripts/objects/BunkerSiloCloseEvent.lua")
source("dataS/scripts/objects/BunkerSiloOpenEvent.lua")
source("dataS/scripts/objects/Bga.lua")
source("dataS/scripts/economy/GreatDemandSpecs.lua")
source("dataS/scripts/economy/EconomyManager.lua")
source("dataS/scripts/economy/FarmlandManager.lua")
source("dataS/scripts/economy/FarmlandStateEvent.lua")
source("dataS/scripts/economy/FarmlandInitialStateEvent.lua")
source("dataS/scripts/economy/Farmland.lua")
source("dataS/scripts/objects/MissionPhysicsObject.lua")
source("dataS/scripts/animals/Animal.lua")
source("dataS/scripts/animals/RideableAnimal.lua")
source("dataS/scripts/animals/Horse.lua")
source("dataS/scripts/animals/WildlifeSpawner.lua")
source("dataS/scripts/animals/LightWildLifeAnimal.lua")
source("dataS/scripts/animals/LightWildlife.lua")
source("dataS/scripts/animals/CrowsWildlifeStates.lua")
source("dataS/scripts/animals/CrowsWildlifeSoundStates.lua")
source("dataS/scripts/animals/CrowsWildlife.lua")
source("dataS/scripts/animals/Dog.lua")
source("dataS/scripts/animals/shop/AnimalController.lua")
source("dataS/scripts/animals/shop/AbstractAnimalStrategy.lua")
source("dataS/scripts/animals/shop/AnimalItem.lua")
source("dataS/scripts/animals/shop/DealerFarmStrategie.lua")
source("dataS/scripts/animals/shop/DealerStrategie.lua")
source("dataS/scripts/animals/shop/DealerTrailerStrategie.lua")
source("dataS/scripts/animals/shop/TrailerFarmStrategie.lua")
source("dataS/scripts/animals/shop/VisualTrailer.lua")
source("dataS/scripts/animals/events/AnimalRidingEvent.lua")
source("dataS/scripts/animals/events/AnimalAddEvent.lua")
source("dataS/scripts/animals/events/AnimalRemoveEvent.lua")
source("dataS/scripts/animals/events/AnimalCleanEvent.lua")
source("dataS/scripts/animals/events/AnimalNameEvent.lua")
source("dataS/scripts/animals/events/AnimalDealerEvent.lua")
source("dataS/scripts/animals/events/FarmTrailerEvent.lua")
source("dataS/scripts/animals/events/DogFeedEvent.lua")
source("dataS/scripts/animals/events/DogFetchItemEvent.lua")
source("dataS/scripts/animals/events/DogFollowEvent.lua")
source("dataS/scripts/animals/events/DogPetEvent.lua")
source("dataS/scripts/animals/AnimalLoadingTrigger.lua")
source("dataS/scripts/farms/Farm.lua")
source("dataS/scripts/farms/FarmManager.lua")
source("dataS/scripts/farms/AccessHandler.lua")
source("dataS/scripts/farms/BanStorage.lua")
source("dataS/scripts/farms/FarmStats.lua")
source("dataS/scripts/farms/FinanceStats.lua")
source("dataS/scripts/farms/events/ObjectFarmChangeEvent.lua")
source("dataS/scripts/farms/events/FarmCreateUpdateEvent.lua")
source("dataS/scripts/farms/events/FarmDestroyEvent.lua")
source("dataS/scripts/farms/events/FarmsInitialStateEvent.lua")
source("dataS/scripts/farms/events/TransferMoneyEvent.lua")
source("dataS/scripts/farms/events/ContractingStateEvent.lua")
source("dataS/scripts/farms/events/RemovePlayerFromFarmEvent.lua")
source("dataS/scripts/farms/events/GetBansEvent.lua")
source("dataS/scripts/animation/AnimationCache.lua")
source("dataS/scripts/animation/AnimationManager.lua")
source("dataS/scripts/animation/Animation.lua")
source("dataS/scripts/animation/RotationAnimation.lua")
source("dataS/scripts/animation/ScrollingAnimation.lua")
source("dataS/scripts/animation/ShakeAnimation.lua")
source("dataS/scripts/SeasonsModDefaultOnCreate.lua")
source("dataS/scripts/effects/EffectManager.lua")
source("dataS/scripts/effects/Effect.lua")
source("dataS/scripts/effects/ShaderPlaneEffect.lua")
source("dataS/scripts/effects/LevelerEffect.lua")
source("dataS/scripts/effects/PipeEffect.lua")
source("dataS/scripts/effects/SlurrySideToSideEffect.lua")
source("dataS/scripts/effects/CutterEffect.lua")
source("dataS/scripts/effects/MorphPositionEffect.lua")
source("dataS/scripts/effects/ConveyorBeltEffect.lua")
source("dataS/scripts/effects/ParticleEffect.lua")
source("dataS/scripts/effects/TipEffect.lua")
source("dataS/scripts/effects/WindrowerEffect.lua")
source("dataS/scripts/shop/BuyObjectEvent.lua")
source("dataS/scripts/shop/BuyPlaceableEvent.lua")
source("dataS/scripts/shop/SellVehicleEvent.lua")
source("dataS/scripts/shop/BuyVehicleEvent.lua")
source("dataS/scripts/shop/BuyHandToolEvent.lua")
source("dataS/scripts/shop/SellHandToolEvent.lua")
source("dataS/scripts/shop/SellPlaceableEvent.lua")
source("dataS/scripts/handTools/HandTool.lua")
source("dataS/scripts/handTools/ChainsawSoundStates.lua")
source("dataS/scripts/handTools/Chainsaw.lua")
source("dataS/scripts/handTools/ChainsawStateEvent.lua")
source("dataS/scripts/handTools/ChainsawCutEvent.lua")
source("dataS/scripts/handTools/ChainsawDelimbEvent.lua")
source("dataS/scripts/handTools/HighPressureWasherLance.lua")
source("dataS/scripts/trainSystem/RailroadCrossing.lua")
source("dataS/scripts/trainSystem/RailroadCaller.lua")

g_uniqueDlcNamePrefix = "pdlc_"
g_forceDefaultPCButtons = true
g_language = 0
g_languageShort = "en"
g_languageSuffix = "_en"
g_showSafeFrame = false
g_flightAndNoHUDKeysEnabled = false
g_woodCuttingMarkerEnabled = true
g_isDevelopmentVersion = false
g_isServerStreamingVersion = false
g_addTestCommands = false
g_addCheatCommands = false
g_showDevelopmentWarnings = false
g_appIsSuspended = false
g_hasWindowFocus = true
g_networkDebug = false
g_networkDebugPrints = false
g_gameRevision = "000"
g_buildName = ""
g_buildTypeParam = ""
g_platformPrefix = ""

if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
	g_platformPrefix = "ps_"
elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
	g_platformPrefix = "xbox_"
elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH then
	g_platformPrefix = "switch_"
end

g_showDeeplinkingFailedMessage = false
g_isSignedIn = false
g_settingsLanguageGUI = 0
g_availableLanguageNamesTable = {}
g_availableLanguagesTable = {}
g_fovYDefault = math.rad(60)
g_fovYMin = math.rad(45)
g_fovYMax = math.rad(90)
g_uiDebugEnabled = false
g_playerColors = {
	{
		name = "color_white",
		value = {
			1,
			1,
			1,
			1
		}
	},
	{
		name = "color_lightGrey",
		value = {
			0.7,
			0.7,
			0.75,
			1
		}
	},
	{
		name = "color_darkGrey",
		value = {
			0.12,
			0.12,
			0.14,
			1
		}
	},
	{
		name = "color_black",
		value = {
			0.03,
			0.03,
			0.03,
			1
		}
	},
	{
		name = "color_iceblue",
		value = {
			0.287,
			0.533,
			0.904,
			1
		}
	},
	{
		name = "color_blue",
		value = {
			0.11,
			0.24,
			0.45,
			1
		}
	},
	{
		name = "color_darkBlue",
		value = {
			0.0395,
			0.083,
			0.235,
			1
		}
	},
	{
		name = "color_lakeBlue",
		value = {
			0.0232,
			0.0382,
			0.0844,
			1
		}
	},
	{
		name = "color_brightGreen",
		value = {
			0.296,
			0.439,
			0.107,
			1
		}
	},
	{
		name = "color_green",
		value = {
			0.11,
			0.31,
			0.09,
			1
		}
	},
	{
		name = "color_darkGreen",
		value = {
			0.038,
			0.0865,
			0.0215,
			1
		}
	},
	{
		name = "color_forestGreen",
		value = {
			0.017,
			0.0275,
			0.0131,
			1
		}
	},
	{
		name = "color_pink",
		value = {
			0.855,
			0.255,
			0.404,
			1
		}
	},
	{
		name = "color_brightRed",
		value = {
			0.5,
			0.1,
			0.1,
			1
		}
	},
	{
		name = "color_red",
		value = {
			0.25,
			0.05,
			0.05,
			1
		}
	},
	{
		name = "color_purple",
		value = {
			0.104,
			0.0356,
			0.117,
			1
		}
	},
	{
		name = "color_yellow",
		value = {
			0.839,
			0.597,
			0.235,
			1
		}
	},
	{
		name = "color_darkYellow",
		value = {
			0.468,
			0.314,
			0.104,
			1
		}
	},
	{
		name = "color_lightBrown",
		value = {
			0.21,
			0.123,
			0.063,
			1
		}
	},
	{
		name = "color_brown",
		value = {
			0.07,
			0.041,
			0.021,
			1
		}
	}
}
g_vehicleColors = {
	{
		brandColor = "SHARED_WHITE2",
		name = "WHITE"
	},
	{
		g = 0.8388,
		name = "BEIGE",
		b = 0.7304,
		r = 0.8228
	},
	{
		g = 0.5906,
		name = "SILVER",
		b = 0.6105,
		r = 0.5271
	},
	{
		g = 0.3372,
		name = "METAL",
		b = 0.3613,
		r = 0.2705
	},
	{
		g = 0.159,
		name = "GREY",
		b = 0.1683,
		r = 0.1022
	},
	{
		brandColor = "AGCO_GREY2",
		name = "AGCO"
	},
	{
		brandColor = "SHARED_BLACK1",
		name = "ONYX"
	},
	{
		g = 0.01,
		name = "JET",
		b = 0.01,
		r = 0.01
	},
	{
		brandColor = "JOHNDEERE_YELLOW1",
		name = "JOHN DEERE"
	},
	{
		brandColor = "JCB_YELLOW1",
		name = "JCB"
	},
	{
		brandColor = "CHALLENGER_YELLOW1",
		name = "CHALLENGER"
	},
	{
		brandColor = "STARA_ORANGE",
		name = "STARA"
	},
	{
		brandColor = "FENDT_RED1",
		name = "FENDT"
	},
	{
		brandColor = "CASEIH_RED1",
		name = "CASE IH"
	},
	{
		brandColor = "MASSEYFERGUSON_RED",
		name = "MASSEY FERGUSON"
	},
	{
		brandColor = "HARDI_RED",
		name = "HARDI"
	},
	{
		brandColor = "RABE_BLUE1",
		name = "RABE"
	},
	{
		brandColor = "LEMKEN_BLUE1",
		name = "LEMKEN"
	},
	{
		brandColor = "NEWHOLLAND_BLUE1",
		name = "NEW HOLLAND"
	},
	{
		brandColor = "GOLDHOFER_BLUE",
		name = "GOLDHOFER"
	},
	{
		brandColor = "DEUTZ_GREEN4",
		name = "DEUTZ FAHR"
	},
	{
		brandColor = "JOHNDEERE_GREEN1",
		name = "JOHN DEERE"
	},
	{
		brandColor = "FENDT_NEWGREEN1",
		name = "FENDT NATURE GREEN"
	},
	{
		brandColor = "FENDT_OLDGREEN1",
		name = "FENDT CLASSIC"
	},
	{
		brandColor = "LIZARD_ECRU1",
		name = "GARLIC"
	},
	{
		g = 0.068,
		name = "DIRT",
		b = 0.03,
		r = 0.168
	},
	{
		g = 0.009,
		name = "CRIMSON",
		b = 0.006,
		r = 0.105
	},
	{
		brandColor = "LIZARD_PINK1",
		name = "PINK"
	},
	{
		brandColor = "LIZARD_PURPLE1",
		name = "PURPLE"
	},
	{
		brandColor = "NEWHOLLAND_BLUE2",
		name = "AZUL"
	},
	{
		g = 0.003,
		name = "NAVY",
		b = 0.031,
		r = 0.004
	},
	{
		brandColor = "LIZARD_OLIVE1",
		name = "OLIVE"
	}
}

if GS_IS_MOBILE_VERSION then
	g_timeScaleSettings = {
		1,
		2,
		5,
		10,
		30,
		45
	}
else
	g_timeScaleSettings = {
		1,
		5,
		15,
		30,
		60,
		120
	}
end

g_timeScaleDevSetting = 2000

if GS_IS_CONSOLE_VERSION then
	addReplacedCustomShader("alphaBlendedDecalShader.xml", "data/shaders/alphaBlendedDecalShader.xml")
	addReplacedCustomShader("alphaTestDisableShader.xml", "data/shaders/alphaTestDisableShader.xml")
	addReplacedCustomShader("beaconGlassShader.xml", "data/shaders/beaconGlassShader.xml")
	addReplacedCustomShader("buildingShader.xml", "data/shaders/buildingShader.xml")
	addReplacedCustomShader("buildingShaderUS.xml", "data/shaders/buildingShaderUS.xml")
	addReplacedCustomShader("bunkerSiloSilageShader.xml", "data/shaders/bunkerSiloSilageShader.xml")
	addReplacedCustomShader("carColorShader.xml", "data/shaders/carColorShader.xml")
	addReplacedCustomShader("characterShader.xml", "data/shaders/characterShader.xml")
	addReplacedCustomShader("cultivatorSoilShader.xml", "data/shaders/cultivatorSoilShader.xml")
	addReplacedCustomShader("cuttersShader.xml", "data/shaders/cuttersShader.xml")
	addReplacedCustomShader("emissiveAdditiveShader.xml", "data/shaders/emissiveAdditiveShader.xml")
	addReplacedCustomShader("emissiveFalloffShader.xml", "data/shaders/emissiveFalloffShader.xml")
	addReplacedCustomShader("emissiveLightsShader.xml", "data/shaders/emissiveLightsShader.xml")
	addReplacedCustomShader("envIntensityShader.xml", "data/shaders/envIntensityShader.xml")
	addReplacedCustomShader("exhaustShader.xml", "data/shaders/exhaustShader.xml")
	addReplacedCustomShader("fillIconShader.xml", "data/shaders/fillIconShader.xml")
	addReplacedCustomShader("fillPlaneShader.xml", "data/shaders/fillPlaneShader.xml")
	addReplacedCustomShader("flagShader.xml", "data/shaders/flagShader.xml")
	addReplacedCustomShader("fruitGrowthFoliageShader.xml", "data/shaders/fruitGrowthFoliageShader.xml")
	addReplacedCustomShader("fxCircleShader.xml", "data/shaders/fxCircleShader.xml")
	addReplacedCustomShader("grainSmokeShader.xml", "data/shaders/grainSmokeShader.xml")
	addReplacedCustomShader("grainUnloadingShader.xml", "data/shaders/grainUnloadingShader.xml")
	addReplacedCustomShader("grimmeMeshScrollShader.xml", "data/shaders/grimmeMeshScrollShader.xml")
	addReplacedCustomShader("groundHeightShader.xml", "data/shaders/groundHeightShader.xml")
	addReplacedCustomShader("groundHeightStaticShader.xml", "data/shaders/groundHeightStaticShader.xml")
	addReplacedCustomShader("groundShader.xml", "data/shaders/groundShader.xml")
	addReplacedCustomShader("lightBeamShader.xml", "data/shaders/lightBeamShader.xml")
	addReplacedCustomShader("localCatmullRomRopeShader.xml", "data/shaders/localCatmullRomRopeShader.xml")
	addReplacedCustomShader("meshRotateShader.xml", "data/shaders/meshRotateShader.xml")
	addReplacedCustomShader("meshScrollShader.xml", "data/shaders/meshScrollShader.xml")
	addReplacedCustomShader("morphTargetShader.xml", "data/shaders/morphTargetShader.xml")
	addReplacedCustomShader("numberShader.xml", "data/shaders/numberShader.xml")
	addReplacedCustomShader("oceanShader.xml", "data/shaders/oceanShader.xml")
	addReplacedCustomShader("oceanShaderMasked.xml", "data/shaders/oceanShaderMasked.xml")
	addReplacedCustomShader("particleSystemShader.xml", "data/shaders/particleSystemShader.xml")
	addReplacedCustomShader("pipeUnloadingShader.xml", "data/shaders/pipeUnloadingShader.xml")
	addReplacedCustomShader("psColorShader.xml", "data/shaders/psColorShader.xml")
	addReplacedCustomShader("psSubUVShader.xml", "data/shaders/psSubUVShader.xml")
	addReplacedCustomShader("rainShader.xml", "data/shaders/rainShader.xml")
	addReplacedCustomShader("roadShader.xml", "data/shaders/roadShader.xml")
	addReplacedCustomShader("scrollUVShader.xml", "data/shaders/scrollUVShader.xml")
	addReplacedCustomShader("shadowDisableShader.xml", "data/shaders/shadowDisableShader.xml")
	addReplacedCustomShader("silageBaleShader.xml", "data/shaders/silageBaleShader.xml")
	addReplacedCustomShader("simpleOceanShader.xml", "data/shaders/simpleOceanShader.xml")
	addReplacedCustomShader("skyShader.xml", "data/shaders/skyShader.xml")
	addReplacedCustomShader("slurryMeasurementShader.xml", "data/shaders/slurryMeasurementShader.xml")
	addReplacedCustomShader("slurryShader.xml", "data/shaders/slurryShader.xml")
	addReplacedCustomShader("solidFoliageShader.xml", "data/shaders/solidFoliageShader.xml")
	addReplacedCustomShader("streamShader.xml", "data/shaders/streamShader.xml")
	addReplacedCustomShader("tensionBeltShader.xml", "data/shaders/tensionBeltShader.xml")
	addReplacedCustomShader("terrainShader.xml", "data/shaders/terrainShader.xml")
	addReplacedCustomShader("tileAndMirrorShader.xml", "data/shaders/tileAndMirrorShader.xml")
	addReplacedCustomShader("tintAlphaShader.xml", "data/shaders/tintAlphaShader.xml")
	addReplacedCustomShader("tireTrackShader.xml", "data/shaders/tireTrackShader.xml")
	addReplacedCustomShader("treeBillboardShader.xml", "data/shaders/treeBillboardShader.xml")
	addReplacedCustomShader("treeBillboardSSShader.xml", "data/shaders/treeBillboardSSShader.xml")
	addReplacedCustomShader("treeBranchShader.xml", "data/shaders/treeBranchShader.xml")
	addReplacedCustomShader("treeMarkerShader.xml", "data/shaders/treeMarkerShader.xml")
	addReplacedCustomShader("treeTrunkShader.xml", "data/shaders/treeTrunkShader.xml")
	addReplacedCustomShader("triPlanarShader.xml", "data/shaders/triPlanarShader.xml")
	addReplacedCustomShader("underwaterFogShader.xml", "data/shaders/underwaterFogShader.xml")
	addReplacedCustomShader("uvOffsetShader.xml", "data/shaders/uvOffsetShader.xml")
	addReplacedCustomShader("uvRotateShader.xml", "data/shaders/uvRotateShader.xml")
	addReplacedCustomShader("uvScrollShader.xml", "data/shaders/uvScrollShader.xml")
	addReplacedCustomShader("vehicleShader.xml", "data/shaders/vehicleShader.xml")
	addReplacedCustomShader("vertexPaintShader.xml", "data/shaders/vertexPaintShader.xml")
	addReplacedCustomShader("windowShader.xml", "data/shaders/windowShader.xml")
	addReplacedCustomShader("windrowFoliageShader.xml", "data/shaders/windrowFoliageShader.xml")
	addReplacedCustomShader("windrowUnloadingShader.xml", "data/shaders/windrowUnloadingShader.xml")
	addReplacedCustomShader("windShader.xml", "data/shaders/windShader.xml")
end

g_densityMapRevision = 3
g_terrainLodTextureRevision = 2
g_splitShapesRevision = 1
g_tipCollisionRevision = 1
g_placementCollisionRevision = 1
g_menuMusic = nil
g_menuMusicIsPlayingStarted = false
g_maxNumRealVehicleLights = 1
g_clientInterpDelay = 100
g_clientInterpDelayMin = 60
g_clientInterpDelayMax = 150
g_clientInterpDelayBufferOffset = 30
g_clientInterpDelayBufferScale = 0.5
g_clientInterpDelayBufferMin = 45
g_clientInterpDelayBufferMax = 60
g_clientInterpDelayAdjustDown = 0.002
g_clientInterpDelayAdjustUp = 0.08
g_time = 0
g_currentDt = 16.666666666666668
g_updateLoopIndex = 0
g_physicsTimeLooped = 0
g_physicsDt = 16.666666666666668
g_physicsDtUnclamped = 16.666666666666668
g_physicsDtNonInterpolated = 16.666666666666668
g_physicsDtLastValidNonInterpolated = 16.666666666666668
g_packetPhysicsNetworkTime = 0
g_networkTime = netGetTime()
g_prevNetworkTime = g_networkTime - 16
g_physicsNetworkTime = g_networkTime
g_analogStickHTolerance = 0.45
g_analogStickVTolerance = 0.45
g_referenceScreenWidth = 1920
g_referenceScreenHeight = 1080
g_modEventListeners = {}
g_dlcsDirectories = {}

function loadDlcsDirectories()
	g_dlcsDirectories = {}
	local numDlcPaths = getNumDlcPaths()

	for i = 0, numDlcPaths - 1 do
		local path = getDlcPath(i)

		if path ~= nil then
			table.insert(g_dlcsDirectories, {
				isLoaded = true,
				path = path
			})

			if path == getAppBasePath() .. "pdlc/" then
				table.insert(g_dlcsDirectories, {
					isLoaded = false,
					path = "pdlc/"
				})
			end
		end
	end
end

function checkForNewDlcs()
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		local hasNewPaths = false
		local newDlcPaths = {}
		local numDlcPaths = getNumDlcPaths()

		for i = 0, numDlcPaths - 1 do
			local path = getDlcPath(i)

			if path ~= nil then
				newDlcPaths[path] = true

				if g_lastCheckDlcPaths[path] == nil then
					hasNewPaths = true
				end
			end
		end

		g_lastCheckDlcPaths = newDlcPaths

		return hasNewPaths
	else
		return true
	end
end

g_forceNeedsDlcsAndModsReload = false
g_lastCheckDlcPaths = {}

checkForNewDlcs()
loadDlcsDirectories()

g_maxUploadRate = 30.72
g_maxUploadRatePerClient = 393.216
g_drawGuiHelper = false
g_guiHelperSteps = 0.1
g_lastMousePosX = 0
g_lastMousePosY = 0
g_modIsLoaded = {}
g_modNameToDirectory = {}
g_isReloadingDlcs = false
g_dlcModNameHasPrefix = {}
modOnCreate = {}
g_screenWidth = 800
g_screenHeight = 600
g_screenAspectRatio = g_screenWidth / g_screenHeight
g_presentedScreenAspectRatio = g_screenAspectRatio
g_darkControllerOverlay = nil
g_aspectScaleX = 1
g_aspectScaleX = 1
g_gameServerXML = nil
g_gameStatsXMLPath = nil
g_serverMaxCapacity = 16

if GS_IS_CONSOLE_VERSION then
	g_serverMaxCapacity = 6
end

g_serverMinCapacity = 2
g_dedicatedServerInfo = nil
g_dedicatedServerMinFrameLimit = 5
g_dedicatedServerMaxFrameLimit = 60
g_hasLicenseError = false
g_nextModRecommendationTime = 0
g_maxNumLoadingBarSteps = 35
g_curNumLoadingBarStep = 0

function updateLoadingBarProgress(isLast)
	g_curNumLoadingBarStep = g_curNumLoadingBarStep + 1
	local ratio = g_curNumLoadingBarStep / g_maxNumLoadingBarSteps

	if isLast and ratio < 1 or ratio > 1 then
		print("Invalid g_maxNumLoadingBarSteps. Last step number is " .. g_curNumLoadingBarStep)
	end

	updateLoadingBar(ratio)
end

function init(args)
	g_messageCenter = MessageCenter:new()

	updateLoadingBarProgress()

	g_soundMixer = SoundMixer:new()

	updateLoadingBarProgress()

	g_autoSaveManager = AutoSaveManager:new()

	g_gamingStationManager:load()
	updateLoadingBarProgress()

	g_preorderBonusManager = PreorderBonusManager:new()

	updateLoadingBarProgress()

	g_lifetimeStats = LifetimeStats:new()

	g_lifetimeStats:load()

	local startParams = getStartParameters(args)
	local isServerStart = startParams.server ~= nil
	local autoStartSavegameId = startParams.autoStartSavegameId
	local devStartServer = startParams.devStartServer
	local devStartClient = startParams.devStartClient
	local devUniqueUserId = g_isDevelopmentVersion and startParams.uniqueUserId or nil
	local leagueStartServer = startParams.startFSLServer
	local leagueStartClient = startParams.startFSLClient

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		g_screenWidth = 1920
		g_screenHeight = 1080
	else
		g_screenWidth, g_screenHeight = getScreenModeInfo(getScreenMode())
	end

	local function getUITexture(screenHeight, prefix, postfix)
		local resolution = 2160
		local uiPostfix = "_1080p"

		if screenHeight < 720 then
			resolution = 720
			uiPostfix = "_720p"
		elseif screenHeight <= 1080 then
			resolution = 1080
			uiPostfix = ""
		end

		resolution = g_platformSettingsManager:getSetting("forcedUIResolution", resolution)
		local path = string.format("dataS2/menu/hud/%selements%s_%dp.png", prefix, postfix, resolution)

		return path, uiPostfix
	end

	local uiPostfix = GS_IS_MOBILE_VERSION and "_mobile" or ""
	g_baseUIFilename, g_baseUIPostfix = getUITexture(g_screenHeight, "ui_", "")
	g_baseHUDFilename, _ = getUITexture(g_screenHeight, "hud_", uiPostfix)
	g_hudClass = GS_IS_MOBILE_VERSION and MobileHUD or HUD

	if g_isDevelopmentVersion then
		print(string.format(" Loading UI-textures: '%s' '%s'", g_baseUIFilename, g_baseHUDFilename))
	end

	g_screenAspectRatio = g_screenWidth / g_screenHeight
	g_presentedScreenAspectRatio = getScreenAspectRatio()

	updateAspectRatio(g_presentedScreenAspectRatio)

	g_colorBgUVs = GuiUtils.getUVs({
		10,
		1010,
		4,
		4
	})
	g_colorBg = {
		0.0284,
		0.0284,
		0.0284,
		1
	}
	local safeFrameOffset = g_platformSettingsManager:getSetting("safeFrameOffset", 25)
	g_safeFrameOffsetX, g_safeFrameOffsetY = getNormalizedScreenValues(safeFrameOffset, safeFrameOffset)

	updateLoadingBarProgress()

	local xmlFile = loadXMLFile("SettingsFile", "dataS/settings.xml")

	loadLanguageSettings(xmlFile)

	local availableLanguagesString = "Available Languages:"

	for i, lang in ipairs(g_availableLanguagesTable) do
		availableLanguagesString = availableLanguagesString .. " " .. getLanguageCode(lang)
	end

	local developmentLevel = Utils.getNoNil(getXMLString(xmlFile, "settings#developmentLevel"), "release"):lower()
	g_buildName = Utils.getNoNil(getXMLString(xmlFile, "settings#buildName"), g_buildName)
	g_buildTypeParam = Utils.getNoNil(getXMLString(xmlFile, "settings#buildTypeParam"), g_buildTypeParam)
	g_gameRevision = Utils.getNoNil(getXMLString(xmlFile, "settings#revision"), g_gameRevision)
	g_gameRevision = g_gameRevision .. getGameRevisionExtraText()

	delete(xmlFile)

	g_isDevelopmentVersion = false

	if developmentLevel == "internal" then
		print("INTERNAL VERSION")

		g_addTestCommands = true
	elseif developmentLevel == "development" then
		print("DEVELOPMENT VERSION")

		g_isDevelopmentVersion = true
		g_addTestCommands = true

		enableDevelopmentControls()
	end

	if g_isDevelopmentVersion then
		g_networkDebug = true
	end

	if g_addTestCommands or startParams.cheats ~= nil then
		g_addCheatCommands = true
	end

	if g_addTestCommands or startParams.devWarnings ~= nil then
		g_showDevelopmentWarnings = true
	end

	local caption = "Farming Simulator 20"

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		caption = caption .. " (PlayStation 4)"
	elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		caption = caption .. " (XboxOne)"
	end

	if g_isDevelopmentVersion then
		caption = caption .. " - DevelopmentVersion"
	elseif g_addTestCommands then
		caption = caption .. " - InternalVersion"
	end

	setCaption(caption)

	g_gameSettings = GameSettings:new(nil, g_messageCenter)

	loadUserSettings(g_gameSettings)
	addNotificationFilter(GS_PRODUCT_ID, g_gameVersionNotification)
	updateLoadingBarProgress()

	local nameExtra = ""

	if g_buildTypeParam ~= "" then
		nameExtra = nameExtra .. " " .. g_buildTypeParam
	end

	if GS_IS_STEAM_VERSION then
		nameExtra = nameExtra .. " (Steam)"
	end

	if isServerStart then
		nameExtra = nameExtra .. " (Server)"
	end

	print("Farming Simulator 20" .. nameExtra)
	print("  Version: " .. g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " " .. g_buildName)
	print("  " .. availableLanguagesString)
	print("  Language: " .. g_languageShort)
	print("  Time: " .. getDate("%Y-%m-%d %H:%M:%S"))

	if g_addTestCommands then
		print("  Testing Commands: Enabled")
	elseif g_addCheatCommands then
		print("  Cheats: Enabled")
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PC then
		local screenshotsDir = getUserProfileAppPath() .. "screenshots/"
		g_screenshotsDirectory = screenshotsDir

		createFolder(screenshotsDir)
	end

	updateLoadingBarProgress()

	g_i18n = I18N:new()

	g_i18n:load()
	updateLoadingBarProgress()
	setMaxNumOfReflectionPlanes(math.max(g_gameSettings:getValue("maxNumMirrors") + 1, 3))

	local profileId = Utils.getPerformanceClassId()

	if GS_PROFILE_HIGH <= profileId then
		g_maxNumRealVehicleLights = 10
	else
		g_maxNumRealVehicleLights = 1
	end

	math.randomseed(getTime())
	math.random()
	math.random()
	math.random()
	updateLoadingBarProgress()
	g_splitTypeManager:load()
	addSplitShapesShaderParameterOverwrite("windScale", 0, nil, , )
	g_mapManager:addMapItem("MapUSM", "dataS/scripts/missions/mission00.lua", "Mission00", "data/maps/mapUSM.xml", "data/maps/mapUSM_vehicles.xml", "data/maps/mapUSM_items.xml", "", "", "data/maps/mapUSM/mapUSM_preview.png", "", nil, true, false)
	updateLoadingBarProgress()
	g_playerModelManager:load("dataS2/character/humans/player/playerModels.xml")
	updateLoadingBarProgress()
	registerHandTool("chainsaw", Chainsaw)
	registerHandTool("highPressureWasherLance", HighPressureWasherLance)

	g_animCache = AnimationCache:new()

	g_animCache:load(AnimationCache.CHARACTER, "dataS2/character/humans/characterAnimation.i3d")

	if not GS_IS_MOBILE_VERSION then
		g_animCache:load(AnimationCache.PEDESTRIAN, "dataS2/character/humans/pedestrians/pedestrianAnimation.i3d")
	end

	g_achievementManager = AchievementManager:new(nil, g_messageCenter)

	g_achievementManager:load()
	updateLoadingBarProgress()

	local modsDir = getModInstallPath()
	local modDownloadDir = getModDownloadPath()

	updateLoadingBarProgress()

	if not GS_IS_CONSOLE_VERSION then
		local modsDir2 = nil

		if Utils.getNoNil(getXMLBool(g_savegameXML, "gameSettings.modsDirectoryOverride#active"), false) then
			modsDir2 = getXMLString(g_savegameXML, "gameSettings.modsDirectoryOverride#directory")

			if modsDir2 ~= nil and modsDir2 ~= "" then
				modsDir = modsDir2
				modsDir = modsDir:gsub("\\", "/")

				if modsDir:sub(1, 2) == "//" then
					modsDir = "\\\\" .. modsDir:sub(3)
				end

				if modsDir:sub(modsDir:len(), modsDir:len()) ~= "/" then
					modsDir = modsDir .. "/"
				end
			end
		end
	end

	updateLoadingBarProgress()

	if modsDir then
		createFolder(modsDir)
	end

	if modDownloadDir then
		createFolder(modDownloadDir)
	end

	g_modsDirectory = modsDir

	initModDownloadManager(g_modsDirectory, modDownloadDir, g_minModDescVersion, g_maxModDescVersion, g_isDevelopmentVersion)
	startUpdatePendingMods()
	updateLoadingBarProgress()
	loadDlcs()
	updateLoadingBarProgress()

	local startedRepeat = startFrameRepeatMode()

	while isModUpdateRunning() do
		usleep(16000)
	end

	if startedRepeat then
		endFrameRepeatMode()
	end

	if not GS_IS_MOBILE_VERSION then
		loadMods()
	end

	if not GS_IS_CONSOLE_VERSION then
		copyFile(getAppBasePath() .. "VERSION", getUserProfileAppPath() .. "VERSION", true)
	end

	updateLoadingBarProgress()

	g_inputBinding = InputBinding:new(g_logManager, g_modManager, g_messageCenter, GS_IS_CONSOLE_VERSION)

	g_inputBinding:load()

	g_inputDisplayManager = InputDisplayManager:new(g_messageCenter, g_inputBinding, g_modManager, GS_IS_CONSOLE_VERSION)

	g_inputDisplayManager:load()

	g_touchHandler = TouchHandler:new()

	updateLoadingBarProgress()
	simulatePhysics(false)

	if isServerStart then
		local path = getUserProfileAppPath() .. "dedicated_server/dedicatedServerConfig.xml"

		loadServerSettings(path)
	end

	g_gameStatsXMLPath = getUserProfileAppPath() .. "dedicated_server/gameStats.xml"

	updateLoadingBarProgress()

	g_connectionManager = ConnectionManager:new()
	g_masterServerConnection = MasterServerConnection:new()
	local guiSoundPlayer = GuiSoundPlayer:new(g_soundManager)
	g_gui = Gui:new(g_messageCenter, g_languageSuffix, g_inputBinding, guiSoundPlayer)

	g_gui:loadProfiles("dataS/gui/guiProfiles.xml")

	local startMissionInfo = StartMissionInfo:new()
	g_mainScreen = MainScreen:new(nil, , startMissionInfo)
	g_creditsScreen = CreditsScreen:new(nil, , startMissionInfo)

	updateLoadingBarProgress()

	local settingsModel = SettingsModel.new(g_gameSettings, g_savegameXML, g_i18n, g_soundMixer, GS_IS_CONSOLE_VERSION)
	g_settingsScreen = SettingsScreen:new(nil, , g_messageCenter, g_i18n, g_inputBinding, settingsModel, GS_IS_CONSOLE_VERSION)
	local savegameController = SavegameController:new()
	g_careerScreen = CareerScreen:new(nil, , savegameController, startMissionInfo)
	g_characterSelectionScreen = CharacterCreationScreen:new(nil, , startMissionInfo)
	g_difficultyScreen = DifficultyScreen:new(nil, , startMissionInfo)

	updateLoadingBarProgress()

	local inAppPurchaseController = InAppPurchaseController:new(g_messageCenter, g_i18n, g_gameSettings)
	local inGameMenuTutorialFrame = InGameMenuTutorialFrame:new()
	local shopController = ShopController:new(g_messageCenter, g_i18n, g_storeManager, g_brandManager, g_fillTypeManager, inAppPurchaseController)
	local inGameMenuMapFrame = InGameMenuMapFrame:new(nil, g_messageCenter, g_i18n, g_inputBinding, g_inputDisplayManager, g_fruitTypeManager, g_fillTypeManager, g_storeManager, shopController, g_farmlandManager, g_farmManager)
	local inGameMenuPricesFrame = InGameMenuPricesFrame:new(nil, g_i18n, g_fillTypeManager)
	local inGameMenuVehiclesFrame = InGameMenuVehiclesFrame:new(nil, g_messageCenter, g_i18n, g_storeManager, g_brandManager, shopController)
	local inGameMenuFinancesFrame = InGameMenuFinancesFrame:new(nil, g_messageCenter, g_i18n, g_inputBinding)
	local animalFrameClass = GS_IS_MOBILE_VERSION and InGameMenuAnimalsFrameMobile or InGameMenuAnimalsFrame
	local inGameMenuAnimalsFrame = animalFrameClass:new(nil, g_messageCenter, g_i18n, g_animalManager, g_animalFoodManager, g_fillTypeManager)
	local inGameMenuContractsFrame = InGameMenuContractsFrame:new(nil, g_messageCenter, g_i18n, g_missionManager)
	local inGameMenuStatisticsFrame = InGameMenuStatisticsFrame:new()
	local inGameMenuMultiplayerFarmsFrame = InGameMenuMultiplayerFarmsFrame:new(nil, g_messageCenter, g_i18n, g_farmManager)
	local inGameMenuMultiplayerUsersFrame = InGameMenuMultiplayerUsersFrame:new(nil, g_messageCenter, g_i18n, g_farmManager)
	local inGameMenuHelpFrame = InGameMenuHelpFrame:new(nil, g_i18n, g_helpLineManager)
	local inGameMenuGeneralSettingsFrame = InGameMenuGeneralSettingsFrame:new(nil, settingsModel)
	local inGameMenuGameSettingsFrame = InGameMenuGameSettingsFrame:new(nil, g_i18n)
	local inGameMenuMobileSettingsFrame = InGameMenuMobileSettingsFrame:new(nil, settingsModel, g_messageCenter)
	local inGameMenuMainFrame = InGameMenuMainFrame:new(nil, g_i18n)
	local shopCategoriesFrame = ShopCategoriesFrame:new(nil, shopController)
	local shopItemsFrame = ShopItemsFrame:new(nil, shopController, g_i18n, g_brandManager, GS_IS_CONSOLE_VERSION)
	local shopLandscapingFrame = ShopLandscapingFrame:new(nil)
	g_shopConfigScreen = ShopConfigScreen:new(shopController, g_messageCenter, g_i18n, g_i3DManager, g_brandManager, g_configurationManager, g_vehicleTypeManager, g_inputBinding, g_inputDisplayManager)
	local guiTopDownCamera = GuiTopDownCamera:new(nil, g_messageCenter, g_i18n, g_inputBinding)
	local placementController = PlacementScreenController:new(g_i18n, g_inputBinding, g_placeableTypeManager, guiTopDownCamera)
	local placementScreen = PlacementScreen:new(nil, , g_messageCenter, g_inputBinding, placementController)
	local inGameMenu = InGameMenu:new(nil, , g_messageCenter, g_i18n, g_inputBinding, savegameController, g_fruitTypeManager, g_fillTypeManager, GS_IS_CONSOLE_VERSION)
	local shopMenu = ShopMenu:new(nil, , g_messageCenter, g_i18n, g_inputBinding, g_fruitTypeManager, g_fillTypeManager, g_storeManager, shopController, g_shopConfigScreen, placementScreen, GS_IS_CONSOLE_VERSION, inAppPurchaseController)
	local landscapingController = LandscapingScreenController:new(g_messageCenter, g_i18n, g_inputBinding, guiTopDownCamera, g_i3DManager, g_farmlandManager, g_groundTypeManager)
	local landscapingScreen = LandscapingScreen:new(nil, , g_messageCenter, g_i18n, g_inputBinding, landscapingController)

	updateLoadingBarProgress()

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		g_gamepadSigninScreen = GamepadSigninScreen:new(inGameMenu, shopMenu, g_achievementManager, settingsModel)
	end

	if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
		g_chinaSigninScreen = ChinaSigninScreen:new(inGameMenu, shopMenu, g_achievementManager, settingsModel)
	end

	if not g_isPresentationVersion then
		g_tutorialScreen = TutorialScreen:new()
	end

	local banStorage = BanStorage:new()
	local animalController = AnimalController:new(g_i18n)
	g_animalScreen = AnimalScreen:new(nil, , animalController, g_i18n, g_messageCenter)
	local missionCollaborators = MissionCollaborators:new()
	missionCollaborators.messageCenter = g_messageCenter
	missionCollaborators.savegameController = savegameController
	missionCollaborators.achievementManager = g_achievementManager
	missionCollaborators.inputManager = g_inputBinding
	missionCollaborators.inputDisplayManager = g_inputDisplayManager
	missionCollaborators.modManager = g_modManager
	missionCollaborators.fillTypeManager = g_fillTypeManager
	missionCollaborators.fruitTypeManager = g_fruitTypeManager
	missionCollaborators.inGameMenu = inGameMenu
	missionCollaborators.shopMenu = shopMenu
	missionCollaborators.landscapingScreen = landscapingScreen
	missionCollaborators.guiSoundPlayer = guiSoundPlayer
	missionCollaborators.guiTopDownCamera = guiTopDownCamera
	missionCollaborators.placementController = placementController
	missionCollaborators.landscapingController = landscapingController
	missionCollaborators.shopController = shopController
	missionCollaborators.animalController = animalController
	missionCollaborators.banStorage = banStorage
	g_mpLoadingScreen = MPLoadingScreen:new(nil, , missionCollaborators, savegameController, OnLoadingScreen)
	g_mapSelectionScreen = MapSelectionScreen:new(nil, , startMissionInfo)
	g_modSelectionScreen = ModSelectionScreen:new(nil, , startMissionInfo, g_i18n, GS_IS_CONSOLE_VERSION)
	g_achievementsScreen = AchievementsScreen:new(nil, , g_achievementManager)

	updateLoadingBarProgress()

	if not GS_IS_MOBILE_VERSION or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH or g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA" then
		g_startupScreen = StartupScreen:new()
	end

	g_createGameScreen = CreateGameScreen:new()
	g_multiplayerScreen = MultiplayerScreen:new(nil, , startMissionInfo)
	g_joinGameScreen = JoinGameScreen:new(nil, , startMissionInfo, g_messageCenter, g_inputBinding)
	g_connectToMasterServerScreen = ConnectToMasterServerScreen:new(nil, , startMissionInfo)

	updateLoadingBarProgress()

	g_selectMasterServerScreen = SelectMasterServerScreen:new(nil, , startMissionInfo)
	g_serverDetailScreen = ServerDetailScreen:new()
	g_messageDialog = MessageDialog:new()
	g_yesNoDialog = YesNoDialog:new()
	local sleepDialog = SleepDialog:new()
	g_textInputDialog = TextInputDialog:new(nil, , g_inputBinding)
	g_passwordDialog = TextInputDialog:new(nil, , g_inputBinding)
	g_infoDialog = InfoDialog:new()
	g_connectionFailedDialog = ConnectionFailedDialog:new()
	g_colorPickerDialog = ColorPickerDialog:new()
	g_chatDialog = ChatDialog:new()
	g_denyAcceptDialog = DenyAcceptDialog:new()
	g_siloDialog = SiloDialog:new()
	g_animalDialog = AnimalDialog:new()
	g_savegameConflictDialog = SavegameConflictDialog:new(nil, , g_i18n, savegameController)
	g_gameRateDialog = GameRateDialog:new()
	local transferMoneyDialog = TransferMoneyDialog:new()
	g_directSellDialog = DirectSellDialog:new(nil, , g_shopConfigScreen, g_messageCenter)
	g_sellItemDialog = SellItemDialog:new()
	local editFarmDialog = EditFarmDialog:new(nil, , g_i18n, g_farmManager)
	local unBanDialog = UnBanDialog:new(nil, , g_i18n, banStorage)
	local serverSettingsDialog = ServerSettingsDialog:new(nil, , g_i18n, settingsModel)

	if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
		g_chinaAgeRatingDialog = ChinaAgeRatingDialog:new()
		g_controlsIntroductionDialog = ControlsIntroductionDialog:new()
	end

	local voteDialog = nil

	if not GS_IS_MOBILE_VERSION then
		voteDialog = VoteDialog:new(nil, )
	end

	updateLoadingBarProgress()

	g_modHubController = ModHubController:new(g_messageCenter, g_i18n, g_gameSettings)

	if not GS_IS_MOBILE_VERSION then
		g_modHubScreen = ModHubScreen:new(nil, , g_messageCenter, g_i18n, g_inputBinding, g_modHubController, GS_IS_CONSOLE_VERSION)
	end

	g_gui:loadGui("dataS/gui/SettingsGeneralFrame.xml", "SettingsGeneralFrame", SettingsGeneralFrame:new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsAdvancedFrame.xml", "SettingsAdvancedFrame", SettingsAdvancedFrame:new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsDisplayFrame.xml", "SettingsDisplayFrame", SettingsDisplayFrame:new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsControlsFrame.xml", "SettingsControlsFrame", SettingsControlsFrame:new(nil, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsConsoleFrame.xml", "SettingsConsoleFrame", SettingsConsoleFrame:new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsDeviceFrame.xml", "SettingsDeviceFrame", SettingsDeviceFrame:new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/MainScreen.xml", "MainScreen", g_mainScreen)

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/CreditsScreen.xml", "CreditsScreen", g_creditsScreen)
	else
		g_gui:loadGui("dataS/gui/CreditsScreen.xml", "CreditsScreen", g_creditsScreen)
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		g_gui:loadGui("dataS/gui/GamepadSigninScreen.xml", "GamepadSigninScreen", g_gamepadSigninScreen)
	end

	if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
		g_gui:loadGui("dataS/gui/ChinaSigninScreen.xml", "ChinaSigninScreen", g_chinaSigninScreen)
	end

	g_gui:loadGui("dataS/gui/SettingsScreen.xml", "SettingsScreen", g_settingsScreen)

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/CareerScreen.xml", "CareerScreen", g_careerScreen)
	else
		g_gui:loadGui("dataS/gui/CareerScreen.xml", "CareerScreen", g_careerScreen)
	end

	g_gui:loadGui("dataS/gui/CharacterCreationScreen.xml", "CharacterCreationScreen", g_characterSelectionScreen)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/DifficultyScreen.xml", "DifficultyScreen", g_difficultyScreen)

	if not g_isPresentationVersion then
		g_gui:loadGui("dataS/gui/TutorialScreen.xml", "TutorialScreen", g_tutorialScreen)
	end

	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/ShopConfigScreen.xml", "ShopConfigScreen", g_shopConfigScreen)
	g_gui:loadGui("dataS/gui/PlacementScreen.xml", "PlacementScreen", placementScreen)
	g_gui:loadGui("dataS/gui/LandscapingScreen.xml", "LandscapingScreen", landscapingScreen)
	g_gui:loadGui("dataS/gui/MapSelectionScreen.xml", "MapSelectionScreen", g_mapSelectionScreen)
	g_gui:loadGui("dataS/gui/ModSelectionScreen.xml", "ModSelectionScreen", g_modSelectionScreen)
	updateLoadingBarProgress()

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/AchievementsScreen.xml", "AchievementsScreen", g_achievementsScreen)
		g_gui:loadGui("dataS/gui_mobile/AnimalScreen.xml", "AnimalScreen", g_animalScreen)
	else
		g_gui:loadGui("dataS/gui/AchievementsScreen.xml", "AchievementsScreen", g_achievementsScreen)
		g_gui:loadGui("dataS/gui/AnimalScreen.xml", "AnimalScreen", g_animalScreen)
	end

	if g_startupScreen ~= nil then
		g_gui:loadGui("dataS/gui/StartupScreen.xml", "StartupScreen", g_startupScreen)
	end

	g_gui:loadGui("dataS/gui/MPLoadingScreen.xml", "MPLoadingScreen", g_mpLoadingScreen)
	g_gui:loadGui("dataS/gui/CreateGameScreen.xml", "CreateGameScreen", g_createGameScreen)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/MultiplayerScreen.xml", "MultiplayerScreen", g_multiplayerScreen)
	g_gui:loadGui("dataS/gui/JoinGameScreen.xml", "JoinGameScreen", g_joinGameScreen)
	g_gui:loadGui("dataS/gui/ConnectToMasterServerScreen.xml", "ConnectToMasterServerScreen", g_connectToMasterServerScreen)
	g_gui:loadGui("dataS/gui/SelectMasterServerScreen.xml", "SelectMasterServerScreen", g_selectMasterServerScreen)
	g_gui:loadGui("dataS/gui/ServerDetailScreen.xml", "ServerDetailScreen", g_serverDetailScreen)

	local modHubLoadingFrame = ModHubLoadingFrame:new(nil)
	local modHubCategoriesFrame = ModHubCategoriesFrame:new(nil, g_modHubController, g_i18n, GS_IS_CONSOLE_VERSION)
	local modHubItemsFrame = ModHubItemsFrame:new(nil, g_modHubController, g_i18n, GS_IS_CONSOLE_VERSION)
	local modHubDetailsFrame = ModHubDetailsFrame:new(nil, g_modHubController, g_i18n, GS_IS_CONSOLE_VERSION, GS_IS_STEAM_VERSION)

	g_gui:loadGui("dataS/gui/ModHubLoadingFrame.xml", "ModHubLoadingFrame", modHubLoadingFrame, true)
	g_gui:loadGui("dataS/gui/ModHubCategoriesFrame.xml", "ModHubCategoriesFrame", modHubCategoriesFrame, true)
	g_gui:loadGui("dataS/gui/ModHubItemsFrame.xml", "ModHubItemsFrame", modHubItemsFrame, true)
	g_gui:loadGui("dataS/gui/ModHubDetailsFrame.xml", "ModHubDetailsFrame", modHubDetailsFrame, true)

	if not GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui/ModHubScreen.xml", "ModHubScreen", g_modHubScreen)
	end

	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/InGameMenuTutorialFrame.xml", "TutorialFrame", inGameMenuTutorialFrame, true)

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuMapFrame.xml", "MapFrame", inGameMenuMapFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuPricesFrame.xml", "PricesFrame", inGameMenuPricesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuVehiclesFrame.xml", "VehiclesFrame", inGameMenuVehiclesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuFinancesFrame.xml", "FinancesFrame", inGameMenuFinancesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuStatisticsFrame.xml", "StatisticsFrame", inGameMenuStatisticsFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuAnimalsFrame.xml", "AnimalsFrame", inGameMenuAnimalsFrame, true)
	else
		g_gui:loadGui("dataS/gui/InGameMenuMapFrame.xml", "MapFrame", inGameMenuMapFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuPricesFrame.xml", "PricesFrame", inGameMenuPricesFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuVehiclesFrame.xml", "VehiclesFrame", inGameMenuVehiclesFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuFinancesFrame.xml", "FinancesFrame", inGameMenuFinancesFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuStatisticsFrame.xml", "StatisticsFrame", inGameMenuStatisticsFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuAnimalsFrame.xml", "AnimalsFrame", inGameMenuAnimalsFrame, true)
	end

	g_gui:loadGui("dataS/gui/InGameMenuContractsFrame.xml", "ContractsFrame", inGameMenuContractsFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuMultiplayerFarmsFrame.xml", "MultiplayerFarmsFrame", inGameMenuMultiplayerFarmsFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuMultiplayerUsersFrame.xml", "StatisticsFrame", inGameMenuMultiplayerUsersFrame, true)

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuHelpFrame.xml", "HelpFrame", inGameMenuHelpFrame, true)
	else
		g_gui:loadGui("dataS/gui/InGameMenuHelpFrame.xml", "HelpFrame", inGameMenuHelpFrame, true)
	end

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuMainFrame.xml", "MainFrame", inGameMenuMainFrame, true)
	end

	g_gui:loadGui("dataS/gui/InGameMenuGeneralSettingsFrame.xml", "GeneralSettingsFrame", inGameMenuGeneralSettingsFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuGameSettingsFrame.xml", "GameSettingsFrame", inGameMenuGameSettingsFrame, true)

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuMobileSettingsFrame.xml", "InGameMenuMobileSettingsFrame", inGameMenuMobileSettingsFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenu.xml", "InGameMenu", inGameMenu)
	else
		g_gui:loadGui("dataS/gui/InGameMenu.xml", "InGameMenu", inGameMenu)
	end

	g_gui:loadGui("dataS/gui/ShopLandscapingFrame.xml", "ShopLandscapingFrame", shopLandscapingFrame, true)

	if GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui_mobile/ShopCategoriesFrame.xml", "ShopCategoriesFrame", shopCategoriesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/ShopItemsFrame.xml", "ShopItemsFrame", shopItemsFrame, true)
		g_gui:loadGui("dataS/gui_mobile/ShopMenu.xml", "ShopMenu", shopMenu)
	else
		g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", "ShopCategoriesFrame", shopCategoriesFrame, true)
		g_gui:loadGui("dataS/gui/ShopItemsFrame.xml", "ShopItemsFrame", shopItemsFrame, true)
		g_gui:loadGui("dataS/gui/ShopMenu.xml", "ShopMenu", shopMenu)
	end

	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/dialogs/MessageDialog.xml", "MessageDialog", g_messageDialog)
	g_gui:loadGui("dataS/gui/dialogs/YesNoDialog.xml", "YesNoDialog", g_yesNoDialog)
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "InfoDialog", g_infoDialog)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "ConnectionFailedDialog", g_connectionFailedDialog)
	g_gui:loadGui("dataS/gui/dialogs/TextInputDialog.xml", "TextInputDialog", g_textInputDialog)
	g_gui:loadGui("dataS/gui/dialogs/PasswordDialog.xml", "PasswordDialog", g_passwordDialog)
	g_gui:loadGui("dataS/gui/dialogs/ColorPickerDialog.xml", "ColorPickerDialog", g_colorPickerDialog)
	g_gui:loadGui("dataS/gui/dialogs/ChatDialog.xml", "ChatDialog", g_chatDialog)
	g_gui:loadGui("dataS/gui/dialogs/DenyAcceptDialog.xml", "DenyAcceptDialog", g_denyAcceptDialog)
	g_gui:loadGui("dataS/gui/dialogs/UnBanDialog.xml", "UnBanDialog", unBanDialog)
	g_gui:loadGui("dataS/gui/dialogs/SleepDialog.xml", "SleepDialog", sleepDialog)
	g_gui:loadGui("dataS/gui/dialogs/ServerSettingsDialog.xml", "ServerSettingsDialog", serverSettingsDialog)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/dialogs/SiloDialog.xml", "SiloDialog", g_siloDialog)
	g_gui:loadGui("dataS/gui/dialogs/AnimalDialog.xml", "AnimalDialog", g_animalDialog)
	g_gui:loadGui("dataS/gui/dialogs/GameRateDialog.xml", "GameRateDialog", g_gameRateDialog)
	g_gui:loadGui("dataS/gui/dialogs/DirectSellDialog.xml", "DirectSellDialog", g_directSellDialog)
	g_gui:loadGui("dataS/gui/dialogs/SellItemDialog.xml", "SellItemDialog", g_sellItemDialog)
	g_gui:loadGui("dataS/gui/dialogs/EditFarmDialog.xml", "EditFarmDialog", editFarmDialog)
	g_gui:loadGui("dataS/gui/dialogs/TransferMoneyDialog.xml", "TransferMoneyDialog", transferMoneyDialog)
	g_gui:loadGui("dataS/gui/dialogs/SavegameConflictDialog.xml", "SavegameConflictDialog", g_savegameConflictDialog)

	if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
		g_gui:loadGui("dataS/gui/dialogs/ChinaAgeRatingDialog.xml", "ChinaAgeRatingDialog", g_chinaAgeRatingDialog)
		g_gui:loadGui("dataS/gui/dialogs/ControlsIntroductionDialog.xml", "ControlsIntroductionDialog", g_controlsIntroductionDialog)
	end

	if not GS_IS_MOBILE_VERSION then
		g_gui:loadGui("dataS/gui/dialogs/VoteDialog.xml", "VoteDialog", voteDialog)
	end

	g_menuMusic = createStreamedSample("menuMusic", true)

	loadStreamedSample(g_menuMusic, "data/music/menu.ogg")
	setStreamedSampleGroup(g_menuMusic, AudioGroup.MENU_MUSIC)
	setStreamedSampleVolume(g_menuMusic, 1)

	local function func(target, audioGroupIndex, volume)
		if g_menuMusicIsPlayingStarted then
			if volume > 0 then
				resumeStreamedSample(g_menuMusic)
			else
				pauseStreamedSample(g_menuMusic)
			end
		end
	end

	g_soundMixer:addVolumeChangedListener(AudioGroup.MENU_MUSIC, func, nil)
	updateLoadingBarProgress()

	g_preShaderContentId = loadI3DFile("data/preShaderContent/preShaderContent.i3d", false, false)

	link(getRootNode(), g_preShaderContentId)

	g_preShaderContentVehicleId = loadI3DFile("data/preShaderContent/preShaderContentVehicle.i3d", false, false)
	g_preShaderContentCount = 0

	updateLoadingBarProgress(true)

	if g_startupScreen == nil then
		g_gui:showGui("MainScreen")
	else
		g_gui:showGui("StartupScreen")
	end

	g_inputBinding:setShowMouseCursor(true)

	g_defaultCamera = getCamera()

	if g_dedicatedServerInfo == nil then
		local soundPlayerLocal = getAppBasePath() .. "data/music"
		local soundPlayerTemplate = getAppBasePath() .. "profileTemplate/streamingInternetRadios.xml"
		local soundPlayerReadmeTemplate = getAppBasePath() .. "profileTemplate/ReadmeMusic.txt"
		local soundUserPlayerLocal = soundPlayerLocal
		local soundPlayerTarget = soundPlayerTemplate

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			soundUserPlayerLocal = getUserProfileAppPath() .. "music/"
			soundPlayerTarget = soundUserPlayerLocal .. "streamingInternetRadios.xml"
			local soundPlayerReadme = soundUserPlayerLocal .. "ReadmeMusic.txt"

			createFolder(soundUserPlayerLocal)
			copyFile(soundPlayerTemplate, soundPlayerTarget, false)
			copyFile(soundPlayerReadmeTemplate, soundPlayerReadme, false)
		end

		g_soundPlayer = SoundPlayer:new(getAppBasePath(), "https://www.farming-simulator.com/feed/fs2019-radio-station-feed.xml", soundPlayerTarget, soundPlayerLocal, soundUserPlayerLocal, g_languageShort, AudioGroup.RADIO)
	end

	RestartManager:init(args)

	if RestartManager.restarting then
		g_gui:showGui("MainScreen")
		RestartManager:handleRestart()
	end

	addConsoleCommand("gsDrawGuiHelper", "", "consoleCommandDrawGuiHelper")
	addConsoleCommand("gsCleanI3DCache", "", "consoleCommandCleanI3DCache")
	addConsoleCommand("gsSetHighQuality", "", "consoleCommandSetHighQuality")
	addConsoleCommand("gsShowSafeFrame", "", "consoleCommandShowSafeFrame")
	addConsoleCommand("gsEnableUIDebug", "", "consoleCommandToggleUiDebug")
	addConsoleCommand("gsRenderColorAndDepthScreenShot", "", "consoleCommandRenderColorAndDepthScreenShot")

	if g_addCheatCommands then
		addConsoleCommand("gsSetDebugRenderingMode", "", "consoleCommandSetDebugRenderingMode")
		addConsoleCommand("gsDrawRawInput", "", "consoleCommandDrawRawInput")
		addConsoleCommand("gsTestForceFeedback", "", "consoleCommandTestForceFeedback")
	end

	if g_addTestCommands then
		addConsoleCommand("gsChangeLanguage", "", "consoleCommandChangeLanguage")
		addConsoleCommand("gsReloadCurrentGui", "", "consoleCommandReloadCurrentGui")

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			addConsoleCommand("gsSuspendApp", "", "consoleCommandSuspendApp")
		end

		addConsoleCommand("gsFuzzInput", "", "consoleCommandFuzzInput")
	end

	if g_dedicatedServerInfo ~= nil then
		startServerGame()
	end

	if devStartServer ~= nil then
		startDevServer(devStartServer, devUniqueUserId)
	end

	if devStartClient ~= nil then
		startDevClient(devUniqueUserId)
	end

	if autoStartSavegameId ~= nil then
		autoStartLocalSavegame(autoStartSavegameId)
	end

	if leagueStartClient ~= nil and g_leagueBuild then
		startLeagueClient()
	end

	if leagueStartServer ~= nil and g_leagueBuild then
		startLeagueServer()
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PC then
		registerGlobalActionEvents(g_inputBinding)
	elseif GS_IS_CONSOLE_VERSION and g_isDevelopmentVersion then
		local eventAdded, eventId = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_FPS, InputBinding.NO_EVENT_TARGET, toggleShowFPS, false, true, false, true)

		if eventAdded then
			g_inputBinding:setActionEventTextVisibility(eventId, false)
		end

		eventAdded, eventId = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_STATS, InputBinding.NO_EVENT_TARGET, toggleStatsOverlay, false, true, false, true)

		if eventAdded then
			g_inputBinding:setActionEventTextVisibility(eventId, false)
		end
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PC then
		setFileLogPrefixTimestamp(true)
	end

	return true
end

function mouseEvent(posX, posY, isDown, isUp, button)
	Input.updateMouseButtonState(button, isDown)
	g_inputBinding:mouseEvent(posX, posY, isDown, isUp, button)

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:mouseEvent(posX, posY, isDown, isUp, button)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded then
		g_currentMission:mouseEvent(posX, posY, isDown, isUp, button)
	end

	g_lastMousePosX = posX
	g_lastMousePosY = posY

	if button <= Input.MOUSE_BUTTON_LEFT then
		touchEvent(posX, posY, isDown, isUp, TouchHandler.MOUSE_TOUCH_ID)
	end
end

function touchEvent(posX, posY, isDown, isUp, touchId)
	if g_touchHandler ~= nil then
		g_touchHandler:onTouchEvent(posX, posY, isDown, isUp, touchId)
	end

	if g_inputBinding ~= nil then
		g_inputBinding:keyEvent(posX, posY, isDown, isUp, touchId)
	end
end

function keyEvent(unicode, sym, modifier, isDown)
	Input.updateKeyState(sym, isDown)
	g_inputBinding:keyEvent(unicode, sym, modifier, isDown)

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:keyEvent(unicode, sym, modifier, isDown)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded then
		g_currentMission:keyEvent(unicode, sym, modifier, isDown)
	end
end

function update(dt)
	if g_preShaderContentCount <= 6 then
		if g_preShaderContentCount == 0 then
			setTranslation(getCamera(), 0, 0, 5)
		elseif g_preShaderContentCount == 1 then
			setTranslation(getCamera(), 0, 0, 30 * getViewDistanceCoeff() + 2)
		elseif g_preShaderContentCount == 2 then
			g_preShaderContentId2 = clone(g_preShaderContentId, false, false, false)

			delete(getChild(g_preShaderContentId2, "sun"))
			setTranslation(getCamera(), 0, 0, 5)
		elseif g_preShaderContentCount == 3 then
			setTranslation(getCamera(), 0, 5, 30 * getViewDistanceCoeff() + 2)
		elseif g_preShaderContentCount == 4 then
			link(getRootNode(), g_preShaderContentVehicleId)
			setTranslation(getCamera(), 0, 0, 5)
		elseif g_preShaderContentCount == 5 then
			setTranslation(getCamera(), 0, 0, 30 * getViewDistanceCoeff() + 2)
		else
			delete(g_preShaderContentVehicleId)

			g_preShaderContentVehicleId = nil

			delete(g_preShaderContentId2)

			g_preShaderContentId2 = nil

			delete(g_preShaderContentId)

			g_preShaderContentId = nil

			setTranslation(getCamera(), 0, 0, 0)
		end

		g_preShaderContentCount = g_preShaderContentCount + 1

		if g_preShaderContentCount <= 6 then
			return
		end
	end

	g_time = g_time + dt
	g_currentDt = dt
	g_physicsDt = getPhysicsDt()
	g_physicsDtUnclamped = getPhysicsDtUnclamped()
	g_physicsDtNonInterpolated = getPhysicsDtNonInterpolated()

	if g_physicsDtNonInterpolated > 0 then
		g_physicsDtLastValidNonInterpolated = g_physicsDtNonInterpolated
	end

	g_prevNetworkTime = g_networkTime
	g_networkTime = netGetTime()
	g_physicsNetworkTime = g_physicsNetworkTime + g_physicsDtUnclamped
	g_updateNetworkTime = netGetTime()
	g_physicsTimeLooped = (g_physicsTimeLooped + g_physicsDt * 10) % 65535
	g_updateLoopIndex = g_updateLoopIndex + 1

	if g_updateLoopIndex > 1073741824 then
		g_updateLoopIndex = 0
	end

	g_physicsDt = math.max(g_physicsDt, 0.001)
	g_physicsDtUnclamped = math.max(g_physicsDtUnclamped, 0.001)

	if g_isDevelopmentVersion then
		g_debugManager:update(dt)
	end

	g_lifetimeStats:update(dt)
	g_soundMixer:update(dt)
	g_deferredLoadingManager:update(dt)
	g_asyncManager:update(dt)
	g_messageCenter:update(dt)

	if g_nextModRecommendationTime < g_time and g_currentMission == nil and g_dedicatedServerInfo == nil then
		g_modHubController:updateRecommendationSystem()

		g_nextModRecommendationTime = g_time + 1800000
	end

	if not g_deferredLoadingManager:hasTasks() then
		g_inputBinding:update(dt)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		g_currentMission:preUpdate(dt)
	end

	if GS_IS_CONSOLE_VERSION and g_showDeeplinkingFailedMessage == true and g_gui.currentGuiName ~= "StartupScreen" and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		g_showDeeplinkingFailedMessage = false

		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
			if PlatformPrivilegeUtil.checkMultiplayer(onShowDeepLinkingErrorMsg, nil, , 30000) then
				onShowDeepLinkingErrorMsg()
			end
		else
			onShowDeepLinkingErrorMsg()
		end
	end

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:update(dt)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen" and g_gui.currentGuiName ~= "ChinaSigninScreen" then
		g_currentMission:update(dt)
	end

	if g_soundPlayer ~= nil then
		g_soundPlayer:update(dt)
	end

	if g_gui.currentGuiName == "MainScreen" then
		g_achievementManager:update(dt)
	end

	g_soundManager:update(dt)
	g_gamingStationManager:update(dt)
	Input.updateFrameEnd()
end

function draw()
	if g_isDevelopmentVersion then
		g_debugManager:draw()
	end

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:draw()
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen" and g_gui.currentGuiName ~= "ChinaSigninScreen" then
		g_currentMission:draw()
	end

	if g_showWatermark then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 0.5)
		renderText(0.5, 0.75, getCorrectTextSize(0.075), "INTERNAL USE ONLY")
		renderText(0.5, 0.73, getCorrectTextSize(0.03), "Copyright GIANTS Software GmbH")
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end

	if g_isDevelopmentConsoleScriptModTesting then
		renderText(0.2, 0.85, getCorrectTextSize(0.05), "CONSOLE SCRIPTS. DEVELOPMENT USE ONLY")
	end

	if g_showSafeFrame then
		if g_safeFrameOverlay == nil then
			g_safeFrameOverlay = createImageOverlay("dataS2/menu/safeFrame.png")
		end

		renderOverlay(g_safeFrameOverlay, 0, 0, 1, 1)
	end

	if g_drawGuiHelper then
		if g_guiHelperOverlay == nil then
			g_guiHelperOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
		end

		if g_guiHelperOverlay ~= 0 then
			setTextColor(1, 1, 1, 1)

			local width, height = getScreenModeInfo(getScreenMode())

			for i = g_guiHelperSteps, 1, g_guiHelperSteps do
				renderOverlay(g_guiHelperOverlay, i, 0, 1 / width, 1)
				renderOverlay(g_guiHelperOverlay, 0, i, 1, 1 / height)
			end

			for i = 0.05, 1, 0.05 do
				renderText(i, 0.97, getCorrectTextSize(0.02), tostring(i))
				renderText(0.01, i, getCorrectTextSize(0.02), tostring(i))
			end

			setTextAlignment(RenderText.ALIGN_RIGHT)
			setTextColor(0, 0, 0, 0.9)
			renderText(g_lastMousePosX - 0.015, g_lastMousePosY - 0.0125 - 0.002, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosY))
			setTextColor(1, 1, 1, 1)
			renderText(g_lastMousePosX - 0.015, g_lastMousePosY - 0.0125, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosY))
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextColor(0, 0, 0, 0.9)
			renderText(g_lastMousePosX, g_lastMousePosY + 0.015 - 0.002, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosX))
			setTextColor(1, 1, 1, 1)
			renderText(g_lastMousePosX, g_lastMousePosY + 0.015, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosX))
			setTextAlignment(RenderText.ALIGN_LEFT)

			local halfCrosshairWidth = 5 / width
			local halfCrosshairHeight = 5 / width

			renderOverlay(g_guiHelperOverlay, g_lastMousePosX - halfCrosshairWidth, g_lastMousePosY, 2 * halfCrosshairWidth, 1 / height)
			renderOverlay(g_guiHelperOverlay, g_lastMousePosX, g_lastMousePosY - halfCrosshairHeight, 1 / width, 2 * halfCrosshairHeight)
		end
	end

	if GS_IS_CONSOLE_VERSION and getNumOfGamepads() == 0 and g_gui.currentGuiName ~= "StartupScreen" and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
			requestGamepadSignin(Input.BUTTON_2, true, false)
		end

		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(0, 0, 0, 1)

		local xPos = 0.5
		local yPos = 0.6
		local blackOffset = 0.003
		local textSize = getCorrectTextSize(0.05)

		renderText(xPos - blackOffset, yPos + blackOffset * 1.7777777777777777, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos, yPos + blackOffset * 1.7777777777777777, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos + blackOffset, yPos + blackOffset * 1.7777777777777777, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos - blackOffset, yPos, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos + blackOffset, yPos, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos - blackOffset, yPos - blackOffset * 1.7777777777777777, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos, yPos - blackOffset * 1.7777777777777777, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		renderText(xPos + blackOffset, yPos - blackOffset * 1.7777777777777777, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		setTextColor(1, 1, 1, 1)
		renderText(xPos, yPos, textSize, g_i18n:getText("ui_pleaseReconnectController"))
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)

		if g_darkControllerOverlay == nil then
			g_darkControllerOverlay = createImageOverlay("dataS2/menu/blank.png")

			setOverlayColor(g_darkControllerOverlay, 1, 1, 1, 0.3)
		else
			renderOverlay(g_darkControllerOverlay, 0, 0, 1, 1)
		end
	end

	if g_showRawInput then
		setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 0.95)
		renderOverlay(GuiElement.debugOverlay, 0, 0, 1, 1)

		local numGamepads = getNumOfGamepads()
		local yCoord = 0.95

		for i = 0, numGamepads - 1 do
			local numButtons = 0

			for j = 0, Input.MAX_NUM_BUTTONS - 1 do
				if getHasGamepadButton(Input.BUTTON_1 + j, i) then
					numButtons = numButtons + 1
				end
			end

			local numAxes = 0

			for axis = 0, Input.MAX_NUM_AXES - 1 do
				if getHasGamepadAxis(axis, i) then
					numAxes = numAxes + 1
				end
			end

			local versionId = getGamepadVersionId(i)
			local versionText = ""

			if versionId < 65535 then
				versionText = string.format("Version: %04X ", versionId)
			end

			yCoord = yCoord - 0.025

			renderText(0.02, yCoord, 0.025, string.format("Index: %d Name: %s PID: %04X VID: %04X %s#Buttons: %d #Axes: %d", i, getGamepadName(i), getGamepadProductId(i), getGamepadVendorId(i), versionText, numButtons, numAxes))

			for axis = 0, Input.MAX_NUM_AXES - 1 do
				if getHasGamepadAxis(axis, i) then
					local physical = getGamepadAxisPhysicalName(axis, i)
					yCoord = yCoord - 0.016

					renderText(0.025, yCoord, 0.016, string.format("%s->%d: '%s' %1.2f", physical, axis, getGamepadAxisLabel(axis, i), getInputAxis(axis, i)))
				end
			end

			for button = 0, Input.MAX_NUM_BUTTONS - 1 do
				if getInputButton(button, i) > 0 then
					local physical = getGamepadButtonPhysicalName(button, i)
					yCoord = yCoord - 0.025

					renderText(0.025, yCoord, 0.025, string.format("%s->%d: '%s'", physical, button, getGamepadButtonLabel(button, i)))
				end
			end

			yCoord = yCoord - 0.016
		end
	end
end

function showSigninScreen()
	g_gamepadSigninScreen.forceShowSigninGui = true

	forceEndFrameRepeatMode()

	if g_currentMission ~= nil then
		if g_currentMission.isMissionStarted then
			g_currentMission:pauseGame()
			g_masterServerConnection:disconnectFromMasterServer()

			if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
				g_gui:showGui("ChinaSigninScreen")
			else
				g_gui:showGui("GamepadSigninScreen")
			end
		else
			OnInGameMenuMenu(true)
		end
	else
		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()

		if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
			g_gui:showGui("ChinaSigninScreen")
		else
			g_gui:showGui("GamepadSigninScreen")
		end
	end
end

function acceptedGameInvite(masterServerId, serverId, password, requestUserName)
	if g_currentMission ~= nil then
		OnInGameMenuMenu()
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE and (g_gui.currentGuiName == "GamepadSigninScreen" or not g_isSignedIn) then
		g_tempDeepLinkingInfo = {
			masterServerId = masterServerId,
			serverId = serverId,
			password = password,
			requestUserName = requestUserName
		}
	elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE and requestUserName ~= "" and g_gameSettings:getValue("nickname") ~= requestUserName then
		g_tempDeepLinkingInfo = {
			masterServerId = masterServerId,
			serverId = serverId,
			password = password,
			requestUserName = requestUserName
		}

		g_gui:showInfoDialog({
			text = string.format(g_i18n:getText("dialog_signinWithUserToAcceptInvite"), requestUserName),
			callback = onOkSigninAccept
		})
	elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		if PlatformPrivilegeUtil.checkMultiplayer(acceptedGameInvitePerformConnect, nil, {
			masterServerId,
			serverId,
			password
		}, 30000) then
			acceptedGameInvitePerformConnect({
				masterServerId,
				serverId,
				password
			})
		end
	else
		acceptedGameInvitePerformConnect({
			masterServerId,
			serverId,
			password
		})
	end
end

function acceptedGameInvitePerformConnect(args)
	local masterServerId, serverId, password = unpack(args)

	connectToServer(masterServerId, serverId, password)
end

function acceptedGameCreate()
	if g_currentMission ~= nil then
		OnInGameMenuMenu()
	end

	g_createGameScreen.usePendingInvites = true

	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")
end

function onOkSigninAccept()
	g_gamepadSigninScreen.forceShowSigninGui = true

	if g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
		g_gui:showGui("ChinaSigninScreen")
	else
		g_gui:showGui("GamepadSigninScreen")
	end
end

function onShowDeepLinkingErrorMsg()
	g_deepLinkingInfo = nil

	g_gui:showConnectionFailedDialog({
		text = g_i18n:getText("ui_failedToConnectToGame"),
		callback = g_connectionFailedDialog.onOkCallback,
		target = g_connectionFailedDialog,
		args = {
			"MainScreen"
		}
	})

	g_showDeeplinkingFailedMessage = false
end

function onDeepLinkingFailed()
	g_deepLinkingInfo = nil
	g_showDeeplinkingFailedMessage = true
end

function notifyWindowGainedFocus()
	g_hasWindowFocus = true
end

function notifyWindowLostFocus()
	g_hasWindowFocus = false
end

function notifyAppSuspended()
	g_appIsSuspended = true

	g_messageCenter:publish(MessageType.APP_SUSPENDED)
end

function notifyAppResumed()
	g_appIsSuspended = false

	g_messageCenter:publish(MessageType.APP_RESUMED)
end

function doExit()
	g_createGameScreen:removePortMapping()
	delete(g_savegameXML)
	g_lifetimeStats:save()

	if g_soundPlayer ~= nil then
		g_soundPlayer:delete()

		g_soundPlayer = nil
	end

	g_i3DManager:deleteSharedI3DFiles()
	print("Application quit")
	requestExit()
end

function registerObjectClassName(object, className)
	g_currentMission.objectsToClassName[object] = className
end

function unregisterObjectClassName(object)
	g_currentMission.objectsToClassName[object] = nil
end

function loadDlcs()
	storeHaveDlcsChanged()

	if g_isPresentationVersion and not g_isPresentationVersionDlcEnabled then
		return
	end

	local loadedDlcs = {}

	for i = 1, table.getn(g_dlcsDirectories) do
		local dir = g_dlcsDirectories[i]

		if dir.isLoaded then
			loadDlcsFromDirectory(dir.path, loadedDlcs)
		end
	end
end

function loadDlcsFromDirectory(dlcsDir, loadedDlcs)
	local appBasePath = getAppBasePath()

	if isAbsolutPath(dlcsDir) and (appBasePath:len() == 0 or not StringUtil.startsWith(dlcsDir, appBasePath)) then
		createFolder(dlcsDir)
	end

	local files = Files:new(dlcsDir)

	for _, v in pairs(files.files) do
		local addDLCPrefix = false
		local dlcFileHash, dlcName, xmlFilename = nil

		if v.isDirectory then
			if g_isDevelopmentVersion or GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_PC then
				dlcName = v.filename
				xmlFilename = "dlcDesc.xml"
				addDLCPrefix = true

				if GS_IS_CONSOLE_VERSION then
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, "")
				else
					dlcFileHash = getMD5("Dev_" .. v.filename)
				end
			end
		else
			local len = v.filename:len()

			if len > 4 then
				local ext = v.filename:sub(len - 3)

				if ext == ".dlc" then
					dlcName = v.filename:sub(1, len - 4)
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
					xmlFilename = "dlcDesc.xml"
					addDLCPrefix = true
				elseif ext == ".zip" or ext == ".gar" then
					dlcName = v.filename:sub(1, len - 4)
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
					xmlFilename = "modDesc.xml"
					addDLCPrefix = false
				end
			end
		end

		if dlcName ~= nil and xmlFilename ~= nil and g_dlcModNameHasPrefix[dlcName] == nil then
			local dlcDir = dlcsDir .. dlcName .. "/"
			local dlcFile = dlcDir .. xmlFilename
			g_dlcModNameHasPrefix[dlcName] = addDLCPrefix

			loadModDesc(dlcName, dlcDir, dlcFile, dlcFileHash, dlcsDir .. v.filename, v.isDirectory, addDLCPrefix)
		end
	end
end

function loadMods()
	haveModsChanged()

	local loadedMods = {}
	local modsDir = g_modsDirectory

	if g_isPresentationVersion then
		return
	end

	g_showIllegalActivityInfo = false
	local files = Files:new(modsDir)

	for _, v in pairs(files.files) do
		local modFileHash, modName = nil

		if v.isDirectory then
			modName = v.filename

			if g_isDevelopmentVersion then
				modFileHash = getMD5("DevMod_" .. v.filename)
			end
		else
			local len = v.filename:len()

			if len > 4 then
				local ext = v.filename:sub(len - 3)

				if ext == ".zip" or ext == ".gar" then
					modName = v.filename:sub(1, len - 4)
					modFileHash = getFileMD5(modsDir .. v.filename, modName)
				end
			end
		end

		if modName ~= nil then
			local modDir = modsDir .. modName .. "/"
			local modFile = modDir .. "modDesc.xml"

			if loadedMods[modFile] == nil then
				loadModDesc(modName, modDir, modFile, modFileHash, modsDir .. v.filename, v.isDirectory, false)

				loadedMods[modFile] = true
			end
		end
	end

	if g_showIllegalActivityInfo then
		print("Info: This game protects you from illegal activity")
	end

	g_showIllegalActivityInfo = nil
end

function loadModDesc(modName, modDir, modFile, modFileHash, absBaseFilename, isDirectory, addDLCPrefix)
	if not getIsValidModDir(modName) then
		print("Error: Invalid mod name '" .. modName .. "'! Characters allowed: (_, A-Z, a-z, 0-9). The first character must not be a digit")

		return
	end

	local origModName = modName

	if addDLCPrefix then
		modName = g_uniqueDlcNamePrefix .. modName
	end

	if g_modNameToDirectory[modName] ~= nil then
		return
	end

	g_modNameToDirectory[modName] = modDir
	local isDLCFile = false

	if StringUtil.endsWith(modFile, "dlcDesc.xml") then
		isDLCFile = true

		if not fileExists(modFile) then
			g_hasLicenseError = true

			print("Error: No license for dlc " .. modName .. ". Please reinstall.")

			return
		end
	end

	setModInstalled(absBaseFilename, addDLCPrefix)

	local xmlFile = loadXMLFile("ModFile", modFile)
	local version = getXMLString(xmlFile, "modDesc.version")
	local versionStr = ""

	if version ~= nil and version ~= "" then
		versionStr = " (Version: " .. version .. ")"
	end

	local hashStr = ""

	if modFileHash ~= nil then
		hashStr = " (Hash: " .. modFileHash .. ")"
	end

	if isDLCFile then
		print("Load dlc: " .. modName .. versionStr .. hashStr)
	else
		print("Load mod: " .. modName .. versionStr .. hashStr)
	end

	local modDescVersion = getXMLInt(xmlFile, "modDesc#descVersion")

	if modDescVersion == nil then
		print("Error: Missing descVersion attribute in mod " .. modName)
		delete(xmlFile)

		return
	end

	if modDescVersion < g_minModDescVersion or g_maxModDescVersion < modDescVersion then
		print("Error: Unsupported mod description version in mod " .. modName)
		delete(xmlFile)

		return
	end

	if _G[modName] ~= nil and not g_isReloadingDlcs then
		print("Error: Invalid mod name '" .. modName .. "'")
		delete(xmlFile)

		return
	end

	if isDLCFile then
		local requiredModName = getXMLString(xmlFile, "modDesc.multiplayer#requiredModName")

		if requiredModName ~= nil and requiredModName ~= origModName then
			print("Error: Do not rename dlcs. Name: '" .. origModName .. "'. Expect: '" .. requiredModName .. "'")
			delete(xmlFile)

			return
		end
	end

	local modEnv = {}

	if GS_IS_CONSOLE_VERSION then
		modEnv = Utils.getNoNil(_G[modName], modEnv)
	end

	_G[modName] = modEnv
	local modEnv_mt = {
		__index = _G
	}

	setmetatable(modEnv, modEnv_mt)

	if not isDLCFile then
		modEnv._G = modEnv
	end

	modEnv.g_i18n = g_i18n:addModI18N(modName)

	function modEnv.loadstring(str, chunkname)
		str = "setfenv(1," .. modName .. "); " .. str

		return loadstring(str, chunkname)
	end

	function modEnv.source(filename, env)
		if isAbsolutPath(filename) then
			if not g_isDevelopmentConsoleScriptModTesting and GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
				filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
			end

			source(filename, modName)
		else
			source(filename)
		end
	end

	function modEnv.InitEventClass(classObject, className)
		InitEventClass(classObject, modName .. "." .. className)
	end

	function modEnv.InitObjectClass(classObject, className)
		InitObjectClass(classObject, modName .. "." .. className)
	end

	function modEnv.registerObjectClassName(object, className)
		registerObjectClassName(object, modName .. "." .. className)
	end

	modEnv.g_placeableTypeManager = {
		addPlaceableType = function (self, typeName, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end

			g_placeableTypeManager:addPlaceableType(typeName, className, filename, customEnvironment)
		end,
		getClassObjectByTypeName = function (self, typeName)
			local classObj = g_placeableTypeManager:getClassObjectByTypeName(typeName)

			if classObj == nil then
				classObj = g_placeableTypeManager:getClassObjectByTypeName(modName .. "." .. typeName)
			end

			return classObj
		end
	}

	setmetatable(modEnv.g_placeableTypeManager, {
		__index = g_placeableTypeManager
	})

	modEnv.g_specializationManager = {
		addSpecialization = function (self, name, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				if not g_isDevelopmentConsoleScriptModTesting and GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
					filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
				end

				customEnvironment = modName
				name = modName .. "." .. name
				className = modName .. "." .. className
			end

			g_specializationManager:addSpecialization(name, className, filename, customEnvironment)
		end,
		getSpecializationByName = function (self, name)
			local spec = g_specializationManager:getSpecializationByName(name)

			if spec == nil then
				spec = g_specializationManager:getSpecializationByName(modName .. "." .. name)
			end

			return spec
		end
	}

	setmetatable(modEnv.g_specializationManager, {
		__index = g_specializationManager
	})

	modEnv.g_vehicleTypeManager = {
		addVehicleType = function (self, typeName, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				if GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
					filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
				end

				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end

			g_vehicleTypeManager:addVehicleType(typeName, className, filename, customEnvironment)
		end
	}

	setmetatable(modEnv.g_vehicleTypeManager, {
		__index = g_vehicleTypeManager
	})

	modEnv.g_effectManager = {
		registerEffectClass = function (self, className, effectClass)
			if not ClassUtil.getIsValidClassName(className) then
				print("Error: Invalid effect class name: " .. className)

				return
			end

			_G.g_effectManager:registerEffectClass(modName .. "." .. className, effectClass)
		end,
		getEffectClass = function (self, className)
			local effectClass = _G.g_effectManager:getEffectClass(className)

			if effectClass == nil then
				effectClass = _G.g_effectManager:getEffectClass(modName .. "." .. className)
			end

			return effectClass
		end
	}

	setmetatable(modEnv.g_effectManager, {
		__index = _G.g_effectManager
	})

	modEnv.InitStaticEventClass = ""
	modEnv.InitStaticObjectClass = ""
	modEnv.loadMod = ""
	modEnv.loadModDesc = ""
	modEnv.loadDlcs = ""
	modEnv.loadDlcsFromDirectory = ""
	modEnv.loadMods = ""
	modEnv.reloadDlcsAndMods = ""
	modEnv.verifyDlcs = ""
	modEnv.deleteFile = ""
	modEnv.deleteFolder = ""
	modEnv.isAbsolutPath = isAbsolutPath
	modEnv.g_isDevelopmentVersion = g_isDevelopmentVersion
	modEnv.GS_IS_CONSOLE_VERSION = GS_IS_CONSOLE_VERSION

	if not isDLCFile then
		modEnv.ClassUtil = {
			getClassModName = function (self, className)
				local classModName = _G.ClassUtil.getClassModName(className)

				if classModName == nil then
					classModName = _G.ClassUtil.getClassModName(modName .. "." .. className)
				end

				return classModName
			end
		}
	end

	if g_dedicatedServerInfo ~= nil then
		function modEnv.setFramerateLimiter()
		end

		modEnv.g_dedicatedServerMinFrameLimit = g_dedicatedServerMinFrameLimit
		modEnv.g_dedicatedServerMaxFrameLimit = g_dedicatedServerMaxFrameLimit
	end

	local onCreateUtil = {
		onCreateFunctions = {}
	}
	modEnv.g_onCreateUtil = onCreateUtil

	function onCreateUtil.addOnCreateFunction(name, func)
		onCreateUtil.onCreateFunctions[name] = func
	end

	function onCreateUtil.activateOnCreateFunctions()
		for name, func in pairs(onCreateUtil.onCreateFunctions) do
			modOnCreate[name] = function (self, id)
				func(id)
			end
		end
	end

	function onCreateUtil.deactivateOnCreateFunctions()
		for name, func in pairs(onCreateUtil.onCreateFunctions) do
			modOnCreate[name] = nil
		end
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.l10n.text(%d)", i)
		local name = getXMLString(xmlFile, baseName .. "#name")

		if name == nil then
			break
		end

		local text = getXMLString(xmlFile, baseName .. "." .. g_languageShort)

		if text == nil then
			text = getXMLString(xmlFile, baseName .. ".en")

			if text == nil then
				text = getXMLString(xmlFile, baseName .. ".de")
			end
		end

		if text == nil then
			print("Warning: No l10n text found for entry '" .. name .. "' in mod '" .. modName .. "'")
		elseif modEnv.g_i18n:hasModText(name) then
			print("Warning: Duplicate l10n entry '" .. name .. "' in mod '" .. modName .. "'. Ignoring this definition.")
		else
			modEnv.g_i18n:setText(name, text)
		end

		i = i + 1
	end

	local l10nFilenamePrefix = getXMLString(xmlFile, "modDesc.l10n#filenamePrefix")

	if l10nFilenamePrefix ~= nil then
		local l10nFilenamePrefixFull = Utils.getFilename(l10nFilenamePrefix, modDir)
		local l10nXmlFile, l10nFilename = nil
		local langs = {
			g_languageShort,
			"en",
			"de"
		}

		for _, lang in ipairs(langs) do
			l10nFilename = l10nFilenamePrefixFull .. "_" .. lang .. ".xml"

			if fileExists(l10nFilename) then
				l10nXmlFile = loadXMLFile("TempConfig", l10nFilename)

				break
			end
		end

		if l10nXmlFile ~= nil then
			local textI = 0

			while true do
				local key = string.format("l10n.texts.text(%d)", textI)

				if not hasXMLProperty(l10nXmlFile, key) then
					break
				end

				local name = getXMLString(l10nXmlFile, key .. "#name")
				local text = getXMLString(l10nXmlFile, key .. "#text")

				if name ~= nil and text ~= nil then
					if modEnv.g_i18n:hasModText(name) then
						print("Warning: Duplicate l10n entry '" .. name .. "' in '" .. l10nFilename .. "'. Ignoring this definition.")
					else
						modEnv.g_i18n:setText(name, text:gsub("\r\n", "\n"))
					end
				end

				textI = textI + 1
			end

			delete(l10nXmlFile)
		else
			print("Warning: No l10n file found for '" .. l10nFilenamePrefix .. "' in mod '" .. modName .. "'")
		end
	end

	local title = XMLUtil.getXMLI18NValue(xmlFile, "modDesc.title", getXMLString, nil, "", modName, true)
	local desc = XMLUtil.getXMLI18NValue(xmlFile, "modDesc.description", getXMLString, nil, "", modName, true)
	local iconFilename = XMLUtil.getXMLI18NValue(xmlFile, "modDesc.iconFilename", getXMLString, nil, "", modName, true)

	if title == "" then
		print("Error: Missing title in mod " .. modName)
		delete(xmlFile)

		return
	end

	if desc == "" then
		print("Error: Missing description in mod " .. modName)
		delete(xmlFile)

		return
	end

	local isMultiplayerSupported = Utils.getNoNil(getXMLBool(xmlFile, "modDesc.multiplayer#supported"), false)
	local isPreorderBonus = Utils.getNoNil(getXMLBool(xmlFile, "modDesc.isPreorderBonus#value"), false)

	if modFileHash == nil then
		if isMultiplayerSupported then
			print("Warning: Only zip mods are supported in multiplayer. You need to zip the mod " .. modName .. " to use it in multiplayer.")
		end

		isMultiplayerSupported = false
	end

	if isMultiplayerSupported and iconFilename == "" then
		print("Error: Missing icon filename in mod " .. modName)
		delete(xmlFile)

		return
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.maps.map(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		g_mapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile)

		i = i + 1
	end

	local version = XMLUtil.getXMLI18NValue(xmlFile, "modDesc.version", getXMLString, nil, "", modName, true)
	local author = XMLUtil.getXMLI18NValue(xmlFile, "modDesc.author", getXMLString, nil, "", modName, true)

	if isDLCFile then
		local dlcProductId = getXMLString(xmlFile, "modDesc.productId")

		if dlcProductId == nil or version == nil then
			print("Error: invalid product id or version in DLC " .. modName)
		else
			addNotificationFilter(dlcProductId, version)
		end
	end

	iconFilename = Utils.getFilename(iconFilename, modDir)

	g_modManager:addMod(title, desc, version, modDescVersion, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, modFileHash, absBaseFilename, isDirectory, isDLCFile, isPreorderBonus)
	delete(xmlFile)
end

function resetModOnCreateFunctions()
	modOnCreate = {}
end

function loadMod(modName, modDir, modFile, modTitle)
	if g_modIsLoaded[modName] then
		return
	end

	g_modIsLoaded[modName] = true
	g_modNameToDirectory[modName] = modDir
	local modEnv = _G[modName]

	if modEnv == nil then
		return
	end

	local xmlFile = loadXMLFile("ModFile", modFile)
	local isDLCFile = false

	if StringUtil.endsWith(modFile, "dlcDesc.xml") then
		isDLCFile = true
	else
		modTitle = ""
	end

	g_currentModDirectory = modDir
	g_currentModName = modName

	if not GS_IS_CONSOLE_VERSION or isDLCFile or g_isDevelopmentConsoleScriptModTesting then
		local i = 0

		while true do
			local baseName = string.format("modDesc.extraSourceFiles.sourceFile(%d)", i)
			local filename = getXMLString(xmlFile, baseName .. "#filename")

			if filename == nil then
				break
			end

			source(modDir .. filename, modName)

			i = i + 1
		end
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.brands.brand(%d)", i)
		local name = getXMLString(xmlFile, baseName .. "#name")

		if name == nil then
			break
		end

		local title = getXMLString(xmlFile, baseName .. "#title")
		local image = getXMLString(xmlFile, baseName .. "#image")

		g_brandManager:addBrand(name, title, image, modDir, true)

		i = i + 1
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.specializations.specialization(%d)", i)
		local specName = getXMLString(xmlFile, baseName .. "#name")

		if specName == nil then
			break
		end

		local className = getXMLString(xmlFile, baseName .. "#className")
		local filename = getXMLString(xmlFile, baseName .. "#filename")

		if className ~= nil and filename ~= nil then
			filename = modDir .. filename
			className = modName .. "." .. className
			specName = modName .. "." .. specName

			if not GS_IS_CONSOLE_VERSION or isDLCFile then
				g_specializationManager:addSpecialization(specName, className, filename, modName)
			else
				print("Error: Can't register specialization " .. specName .. " with scripts on consoles.")
			end
		end

		i = i + 1
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.vehicleTypes.type(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		g_vehicleTypeManager:loadVehicleTypeFromXML(xmlFile, baseName, isDLCFile, modDir, modName)

		i = i + 1
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.baleTypes.baleType(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		g_baleTypeManager:loadBaleTypeFromXML(xmlFile, baseName, nil, modDir, true)

		i = i + 1
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.jointTypes.jointType(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local name = getXMLString(xmlFile, baseName .. "#name")

		if name ~= nil then
			AttacherJoints.registerJointType(name)
		end

		i = i + 1
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.materialHolders.materialHolder(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local filename = getXMLString(xmlFile, baseName .. "#filename")

		if filename ~= nil then
			filename = Utils.getFilename(filename, g_currentModDirectory)

			g_materialManager:addModMaterialHolder(filename)
		end

		i = i + 1
	end

	i = 0

	while true do
		local baseName = string.format("modDesc.brandColors.color(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		g_brandColorManager:loadBrandColorFromXML(xmlFile, baseName)

		i = i + 1
	end

	local i = 0

	while true do
		local baseName = string.format("modDesc.storeItems.storeItem(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local storeItemXMLFilename = getXMLString(xmlFile, baseName .. "#xmlFilename")

		g_storeManager:addModStoreItem(storeItemXMLFilename, modDir, modName, not isDLCFile, false, modTitle)

		i = i + 1
	end

	delete(xmlFile)

	g_currentModDirectory = nil
	g_currentModName = nil
end

function reloadDlcsAndMods()
	if g_currentMission ~= nil then
		print("Dlc reloading is not supported during gameplay")

		return
	end

	for i = g_mapManager:getNumOfMaps(), 1, -1 do
		local map = g_mapManager:getMapDataByIndex(i)

		if map.isModMap then
			g_mapManager:removeMapItem(i)
		end
	end

	while g_modManager:getNumOfMods() > 0 do
		g_modManager:removeMod(g_modManager:getModByIndex(1))
	end

	g_modIsLoaded = {}
	g_modNameToDirectory = {}
	g_dlcModNameHasPrefix = {}
	g_isReloadingDlcs = true

	startUpdatePendingMods()
	loadDlcsDirectories()
	loadDlcs()

	if isModUpdateRunning() then
		local startedRepeat = startFrameRepeatMode()

		while isModUpdateRunning() do
			usleep(16000)
		end

		if startedRepeat then
			endFrameRepeatMode()
		end
	end

	loadMods()

	g_isReloadingDlcs = false
end

function verifyDlcs()
	local missingMods = {}

	for _, mod in ipairs(g_modManager:getMods()) do
		if not fileExists(mod.modFile) then
			table.insert(missingMods, mod)
		end
	end

	return table.getn(missingMods) == 0, missingMods
end

function getIsValidModDir(modDir)
	if modDir:len() == 0 then
		return false
	end

	if StringUtil.startsWith(modDir, g_uniqueDlcNamePrefix) then
		return false
	end

	if modDir:find("%d") == 1 then
		return false
	end

	if modDir:find("[^%w_]") ~= nil then
		return false
	end

	return true
end

function getModNameAndBaseDirectory(filename)
	return Utils.getModNameAndBaseDirectory(filename)
end

function addModEventListener(listener)
	table.insert(g_modEventListeners, listener)
end

function removeModEventListener(listener)
	for i, listenerI in ipairs(g_modEventListeners) do
		if listenerI == listener then
			table.remove(g_modEventListeners, i)

			break
		end
	end
end

function updateAspectRatio(aspect)
	local referenceAspect = g_referenceScreenWidth / g_referenceScreenHeight

	if aspect > referenceAspect then
		g_aspectScaleX = referenceAspect / aspect
		g_aspectScaleY = 1
	else
		g_aspectScaleX = 1
		g_aspectScaleY = aspect / referenceAspect
	end
end

function getNormalizedScreenValues(x, y)
	local values = GuiUtils.getNormalizedValues({
		x,
		y
	}, {
		g_referenceScreenWidth,
		g_referenceScreenHeight
	})
	local newX = values[1] * g_aspectScaleX
	local newY = values[2] * g_aspectScaleY

	return newX, newY
end

function getCorrectTextSize(size)
	return size * g_aspectScaleY
end

function getRandomPlayerColor()
	return math.random(2, table.getn(g_playerColors))
end

function consoleCommandDrawGuiHelper(steps)
	local steps = tonumber(steps)

	if steps ~= nil then
		g_guiHelperSteps = math.max(steps, 0.001)
		g_drawGuiHelper = true
	else
		g_guiHelperSteps = 0.1
		g_drawGuiHelper = false
	end

	if g_drawGuiHelper then
		return "DrawGuiHelper = true (step = " .. g_guiHelperSteps .. ")"
	else
		return "DrawGuiHelper = false"
	end
end

function consoleCommandShowSafeFrame()
	g_showSafeFrame = not g_showSafeFrame
end

function consoleCommandDrawRawInput()
	g_showRawInput = not g_showRawInput
end

function consoleCommandTestForceFeedback()
	if getHasGamepadAxisForceFeedback(0, 0) then
		co = coroutine.create(function ()
			for i = 1, 0, -0.2 do
				setGamepadAxisForceFeedback(0, 0, 0.8, i)
				print(string.format("TestForceFeedback %1.2f", i))
				usleep(500000)
				setGamepadAxisForceFeedback(0, 0, 0.8, -i)
				usleep(500000)
			end

			setGamepadAxisForceFeedback(0, 0, 0, 0)
		end)

		coroutine.resume(co)
	end
end

function consoleCommandCleanI3DCache()
	g_i3DManager:deleteSharedI3DFiles()

	return "I3D cache cleaned"
end

function consoleCommandSetHighQuality()
	setViewDistanceCoeff(5)
	setLODDistanceCoeff(5)
	setTerrainLODDistanceCoeff(500)
	setFoliageViewDistanceCoeff(2.5)

	return "High quality activated"
end

function getStartParameters(args)
	local argValues = StringUtil.splitString(" ", args)
	local valuePairs = {}
	local currentKey = "exe"

	for _, arg in pairs(argValues) do
		if StringUtil.startsWith(arg, "-") then
			currentKey = string.sub(arg, 2)
			valuePairs[currentKey] = ""
		else
			if valuePairs[currentKey] == nil then
				valuePairs[currentKey] = ""
			end

			if valuePairs[currentKey] ~= "" then
				valuePairs[currentKey] = valuePairs[currentKey] .. " "
			end

			valuePairs[currentKey] = valuePairs[currentKey] .. arg
		end
	end

	return valuePairs
end

function loadServerSettings(serverXMLPath)
	g_gameServerXML = loadXMLFile("gameServerXML", serverXMLPath)
	local xmlKey = "gameserver.settings"
	g_dedicatedServerInfo = {
		name = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".game_name"), "Farming Simulator Dedicated Game"),
		password = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".game_password"), ""),
		savegame = MathUtil.clamp(Utils.getNoNil(getXMLInt(g_gameServerXML, xmlKey .. ".savegame_index"), 1), 1, 30),
		maxPlayer = MathUtil.clamp(Utils.getNoNil(getXMLInt(g_gameServerXML, xmlKey .. ".max_player"), g_serverMaxCapacity), g_serverMinCapacity, g_serverMaxCapacity),
		ip = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".ip"), ""),
		port = Utils.getNoNil(getXMLInt(g_gameServerXML, xmlKey .. ".port"), 10823),
		useUpnp = Utils.getNoNil(getXMLBool(g_gameServerXML, xmlKey .. ".use_upnp"), true),
		difficulty = MathUtil.clamp(Utils.getNoNil(getXMLInt(g_gameServerXML, xmlKey .. ".difficulty"), 1), 1, 3),
		mapName = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".mapID"), "Map01"),
		mapFileName = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".mapFilename"), "default")
	}

	if StringUtil.endsWith(g_dedicatedServerInfo.mapFileName, ".dlc") and not StringUtil.startsWith(g_dedicatedServerInfo.mapFileName, "pdlc_") then
		g_dedicatedServerInfo.mapFileName = "pdlc_" .. g_dedicatedServerInfo.mapFileName
	end

	g_dedicatedServerInfo.masterServerName = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".matchmaking_server"), "Deutschland")
	g_dedicatedServerInfo.masterServerId = getXMLInt(g_gameServerXML, xmlKey .. ".matchmaking_server#id")

	if g_dedicatedServerInfo.masterServerId == nil then
		local serverIndex = getXMLInt(g_gameServerXML, xmlKey .. ".matchmaking_server#index") or 1

		if serverIndex == 2 then
			g_dedicatedServerInfo.masterServerId = 3
		elseif serverIndex == 3 then
			g_dedicatedServerInfo.masterServerId = 4
		else
			g_dedicatedServerInfo.masterServerId = 2
		end
	end

	g_dedicatedServerInfo.masterServerIndex = Utils.getNoNil(getXMLInt(g_gameServerXML, xmlKey .. ".matchmaking_server#index"), 1)
	g_dedicatedServerInfo.adminPassword = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".admin_password"), "gurkensalat")
	g_dedicatedServerInfo.pauseGameIfEmpty = Utils.getNoNil(getXMLBool(g_gameServerXML, xmlKey .. ".pause_game_if_empty"), true)
	g_dedicatedServerInfo.mpLanguageCode = Utils.getNoNil(getXMLString(g_gameServerXML, xmlKey .. ".language"), "en")
	g_dedicatedServerInfo.autoSaveInterval = MathUtil.clamp(getXMLInt(g_gameServerXML, xmlKey .. ".auto_save_interval") or 0, 0, 360)
	g_dedicatedServerInfo.gameStatsInterval = math.max(Utils.getNoNil(getXMLFloat(g_gameServerXML, xmlKey .. ".stats_interval"), 60), 10) * 1000
	local numL = getNumOfLanguages()

	for languageIndex = 0, numL - 1 do
		if getLanguageCode(languageIndex) == g_dedicatedServerInfo.mpLanguageCode then
			g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, languageIndex)

			break
		end
	end

	g_dedicatedServerInfo.mods = {}
	local i = 0

	while true do
		local baseName = string.format("gameserver.mods.mod(%d)", i)

		if not hasXMLProperty(g_gameServerXML, baseName) then
			break
		end

		local modFilename = getXMLString(g_gameServerXML, baseName .. "#filename")
		local modIsDlc = getXMLBool(g_gameServerXML, baseName .. "#isDlc")

		if modIsDlc and g_dlcModNameHasPrefix[modFilename] then
			modFilename = g_uniqueDlcNamePrefix .. modFilename
		end

		table.insert(g_dedicatedServerInfo.mods, modFilename)

		i = i + 1
	end
end

function startDevServer(savegameId, uniqueUserId)
	print("Start developer mp server (Savegame-Id: " .. tostring(savegameId) .. ")")
	g_mainScreen:onMultiplayerClick()
	g_multiplayerScreen:onClickCreateGame()

	g_careerScreen.selectedIndex = tonumber(savegameId)
	local savegameController = g_careerScreen.savegameController
	local savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)

	if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
		print("    Savegame not found! Please select savegame manually!")

		return
	end

	g_careerScreen.currentSavegame = savegame

	g_careerScreen:onClickOk()

	if g_gui.currentGuiName == "ModSelectionScreen" then
		g_modSelectionScreen:onClickOk()
	end

	g_autoDevMP = {
		masterServerId = 5,
		serverName = "InternalTest_" .. getUserName()
	}

	g_createGameScreen.serverNameElement:setText(g_autoDevMP.serverName)
	g_createGameScreen:onClickOk()
end

function startDevClient(uniqueUserId)
	print("Start developer mp client")
	g_mainScreen:onMultiplayerClick()

	g_autoDevMP = {
		masterServerId = 5,
		serverName = "InternalTest_" .. getUserName()
	}

	g_multiplayerScreen:onClickJoinGame()
	g_characterSelectionScreen:onClickOk()
end

function autoStartLocalSavegame(savegameId)
	print("Auto start local savegame (Id: " .. tostring(savegameId) .. ")")
	g_gui:setIsMultiplayer(false)
	g_gui:showGui("CareerScreen")

	g_careerScreen.selectedIndex = tonumber(savegameId)
	local savegameController = g_careerScreen.savegameController
	local savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)

	if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
		print("    Savegame not found! Please select savegame manually!")

		return
	end

	g_careerScreen.currentSavegame = savegame

	g_careerScreen:onClickOk()

	if g_gui.currentGuiName == "ModSelectionScreen" then
		g_modSelectionScreen:onClickOk()
	end
end

function startServerGame()
	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")

	g_careerScreen.selectedIndex = g_dedicatedServerInfo.savegame
	local savegameController = g_careerScreen.savegameController
	local savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)
	g_careerScreen.currentSavegame = savegame

	g_careerScreen:onClickOk()
	g_gameSettings:setValue("nickname", "Server")

	if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
		g_careerScreen.startMissionInfo.difficulty = g_dedicatedServerInfo.difficulty

		g_mapSelectionScreen:selectMapByNameAndFile(g_dedicatedServerInfo.mapName, g_dedicatedServerInfo.mapFileName)

		local success = g_characterSelectionScreen:onClickOk()

		if not success then
			g_characterSelectionScreen:onClickOk()
		end
	end

	if g_gui.currentGuiName == "ModSelectionScreen" then
		local addedMods = {}

		for _, modName in pairs(g_dedicatedServerInfo.mods) do
			local mod = g_modManager:getModByName(modName)

			if mod ~= nil and mod.isMultiplayerSupported and mod.fileHash ~= nil then
				addedMods[mod] = mod
			else
				print("Mod '" .. modName .. "' not found or not multiplayer ready")
			end
		end

		g_modSelectionScreen.addedMods = addedMods

		g_modSelectionScreen:onClickOk()
	end

	g_dedicatedServerInfo.selectedMap = g_mapManager:getMapById(savegame.mapId)

	g_createGameScreen.serverNameElement:setText(tostring(g_dedicatedServerInfo.name))
	g_createGameScreen.passwordElement:setText(tostring(g_dedicatedServerInfo.password))
	g_createGameScreen.portElement:setText(tostring(g_dedicatedServerInfo.port))
	g_createGameScreen.useUpnpElement:setIsChecked(g_dedicatedServerInfo.useUpnp)
	g_createGameScreen.bandwidthElement:setState(g_createGameScreen.dedicatedServerConnectionIndex)

	local capacityState = g_dedicatedServerInfo.maxPlayer - g_serverMinCapacity + 1

	g_createGameScreen.capacityElement:setState(capacityState)

	g_createGameScreen.missionDynamicInfo.serverAddress = g_dedicatedServerInfo.ip
	local hasError = g_createGameScreen:onClickOk()

	if hasError then
		g_createGameScreen:onClickOk()
	end
end

function connectToServer(masterServerId, serverId, password)
	if storeHaveDlcsChanged() or haveModsChanged() or g_forceNeedsDlcsAndModsReload then
		g_forceNeedsDlcsAndModsReload = false

		reloadDlcsAndMods()
	end

	if storeAreDlcsCorrupted() then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_dlcsCorruptRedownload"),
			callback = g_mainScreen.onDlcCorruptClick,
			target = g_mainScreen
		})
	else
		g_deepLinkingInfo = {
			masterServerId = masterServerId,
			serverId = serverId,
			password = password
		}

		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()
		g_multiplayerScreen:onClickJoinGame()
	end
end

function startLeagueClient()
	log("Starting FSL client")

	local success, name, password, region = loadLeagueInfo()

	if not success then
		return
	end

	g_mainScreen:onMultiplayerClick()

	local oldFunc = JoinGameScreen.startGame

	function JoinGameScreen.startGame(screen, _, serverId)
		log("JOIN", name, serverId)

		return oldFunc(screen, password, serverId)
	end

	local oldFunc = JoinGameScreen.getSelectedServer

	function JoinGameScreen.getSelectedServer(screen)
		local server = oldFunc(screen)

		if server ~= nil then
			server.hasPassword = false
		end

		return server
	end

	g_autoDevMP = {
		masterServerId = region,
		serverName = name
	}

	g_multiplayerScreen:onClickJoinGame()
end

function loadLeagueInfo()
	local xmlFile = loadXMLFile("standalone", getUserProfileAppPath() .. "standalone.xml")

	if xmlFile == 0 then
		log("ERROR: standalone.xml is required in the game folder to start the league client")

		return false
	end

	local name = getXMLString(xmlFile, "standalone.server#name")
	local password = getXMLString(xmlFile, "standalone.server#password")
	local region = getXMLInt(xmlFile, "standalone.server#region")
	local mapName = getXMLString(xmlFile, "standalone.server.map#name")
	local mapPath = getXMLString(xmlFile, "standalone.server.map#modName")

	delete(xmlFile)

	return true, name, password, region, mapName, mapPath
end

function startLeagueServer()
	log("Starting FSL server")

	local success, name, password, region, mapName, mapPath = loadLeagueInfo()

	if not success then
		return
	end

	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")

	g_careerScreen.selectedIndex = 1
	local savegameController = g_careerScreen.savegameController
	local savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)

	while savegame ~= SavegameController.NO_SAVEGAME and savegame.isValid do
		g_careerScreen.selectedIndex = g_careerScreen.selectedIndex + 1

		if g_careerScreen.selectedIndex == 21 then
			log("ERROR: FSL Server requires an empty savegame")

			return
		end

		savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)
	end

	log("LOADING IN", g_careerScreen.selectedIndex)

	g_careerScreen.currentSavegame = savegame

	g_careerScreen:onClickOk()
	g_gameSettings:setValue("nickname", "League Master")

	if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
		g_careerScreen.startMissionInfo.difficulty = 2

		g_mapSelectionScreen:selectMapByNameAndFile(mapName, mapPath)

		local success = g_characterSelectionScreen:onClickOk()

		if not success then
			g_characterSelectionScreen:onClickOk()
		end
	end

	if g_gui.currentGuiName == "ModSelectionScreen" then
		local addedMods = {}
		local modName = "FS19_League"
		local mod = g_modManager:getModByName(modName)

		if mod ~= nil and mod.isMultiplayerSupported and mod.fileHash ~= nil then
			addedMods[mod] = mod
		else
			print("Mod '" .. modName .. "' not found or not multiplayer ready")
		end

		g_modSelectionScreen.addedMods = addedMods

		g_modSelectionScreen:onClickOk()
	end

	g_createGameScreen.serverNameElement:setText(name)
	g_createGameScreen.passwordElement:setText(password)
	g_createGameScreen.portElement:setText("10823")
	g_createGameScreen.useUpnpElement:setIsChecked(true)
	g_createGameScreen.bandwidthElement:setState(g_createGameScreen.dedicatedServerConnectionIndex)
	g_createGameScreen.capacityElement:setState(6)

	g_createGameScreen.missionDynamicInfo.serverAddress = ""
	g_deepLinkingInfo = {
		masterServerId = region
	}
	local hasError = g_createGameScreen:onClickOk()

	if hasError then
		g_createGameScreen:onClickOk()
	end
end

function loadLanguageSettings(xmlFile)
	local numLanguages = getNumOfLanguages()
	local languageCodeToLanguage = {}

	for i = 0, numLanguages - 1 do
		languageCodeToLanguage[getLanguageCode(i)] = i
	end

	local language = getLanguage()
	local languageSet = false
	local availableLanguages = {}
	local i = 0

	while true do
		local key = string.format("settings.languages.language(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local code = getXMLString(xmlFile, key .. "#code")
		local languageShort = getXMLString(xmlFile, key .. "#short")
		local languageSuffix = getXMLString(xmlFile, key .. "#suffix")
		local lang = languageCodeToLanguage[code]

		if lang ~= nil then
			if lang == language or not languageSet then
				languageSet = true
				g_language = lang
				g_languageShort = languageShort
				g_languageSuffix = languageSuffix
			end

			if getIsLanguageEnabled(lang) then
				availableLanguages[lang] = true
			end
		end

		i = i + 1
	end

	g_availableLanguagesTable = {}
	g_availableLanguageNamesTable = {}

	for i = 0, numLanguages - 1 do
		if availableLanguages[i] or i == g_language then
			table.insert(g_availableLanguagesTable, i)
			table.insert(g_availableLanguageNamesTable, getLanguageName(i))

			if i == g_language then
				g_settingsLanguageGUI = table.getn(g_availableLanguagesTable) - 1
			end
		end
	end
end

function consoleCommandRenderColorAndDepthScreenShot(inWidth, inHeight)
	local width, height = nil

	if inWidth == nil or inHeight == nil then
		local curScrMode = getScreenMode()
		width, height = getScreenModeInfo(curScrMode)
	else
		width = tonumber(inWidth)
		height = tonumber(inHeight)
	end

	setDebugRenderingMode(DebugRendering.NONE)

	local strDate = getDate("%Y_%m_%d_%H_%M_%S") .. ".hdr"
	local colorScreenShot = g_screenshotsDirectory .. "fsScreen_color_" .. strDate

	print("Saving color screenshot: " .. colorScreenShot)
	renderScreenshot(colorScreenShot, width, height, width / height, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false, 4)
	setDebugRenderingMode(DebugRendering.DEPTH)

	local depthScreenShot = g_screenshotsDirectory .. "fsScreen_depth_" .. strDate

	print("Saving depth screenshot: " .. depthScreenShot)
	renderScreenshot(depthScreenShot, width, height, width / height, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false, 0)
	setDebugRenderingMode(DebugRendering.NONE)
end

function consoleCommandSetDebugRenderingMode(newMode)
	if newMode == nil or newMode == "" then
		setDebugRenderingMode(DebugRendering.NONE)

		return "Possible modes: alpha, parallax, albedo, normals, smoothness, metalness, ambientOcclusion, specularOcclusion, diffuseLighting, specularLighting, indirectLighting, lightGrid, shadowSplits, depth, showmips"
	end

	newMode = newMode:lower()
	local modeDescs = {
		alpha = {
			DebugRendering.ALPHA,
			"alpha"
		},
		parallax = {
			DebugRendering.PARALLAX,
			"parallax"
		},
		albedo = {
			DebugRendering.ALBEDO,
			"albedo"
		},
		normals = {
			DebugRendering.NORMALS,
			"normals"
		},
		smoothness = {
			DebugRendering.SMOOTHNESS,
			"smoothness"
		},
		metalness = {
			DebugRendering.METALNESS,
			"metalness"
		},
		ambient_occlusion = {
			DebugRendering.AMBIENT_OCCLUSION,
			"ambientOcclusion"
		},
		ambientocclusion = {
			DebugRendering.AMBIENT_OCCLUSION,
			"ambientOcclusion"
		},
		ao = {
			DebugRendering.AMBIENT_OCCLUSION,
			"ambientOcclusion"
		},
		specular_occlusion = {
			DebugRendering.SPECULAR_OCCLUSION,
			"specularOcclusion"
		},
		specularocclusion = {
			DebugRendering.SPECULAR_OCCLUSION,
			"specularOcclusion"
		},
		diffuse_lighting = {
			DebugRendering.DIFFUSE_LIGHTING,
			"diffuseLighting"
		},
		diffuselighting = {
			DebugRendering.DIFFUSE_LIGHTING,
			"diffuseLighting"
		},
		specular_lighting = {
			DebugRendering.SPECULAR_LIGHTING,
			"specularLighting"
		},
		specularlighting = {
			DebugRendering.SPECULAR_LIGHTING,
			"specularLighting"
		},
		indirect_lighting = {
			DebugRendering.INDIRECT_LIGHTING,
			"indirectLighting"
		},
		indirectlighting = {
			DebugRendering.INDIRECT_LIGHTING,
			"indirectLighting"
		},
		light_grid = {
			DebugRendering.LIGHT_GRID,
			"lightGrid"
		},
		lightgrid = {
			DebugRendering.LIGHT_GRID,
			"lightGrid"
		},
		shadow_splits = {
			DebugRendering.SHADOW_SPLITS,
			"shadowSplits"
		},
		depth = {
			DebugRendering.DEPTH_SCALED,
			"Depth"
		},
		showmips = {
			DebugRendering.SHOW_MIP_LEVELS,
			"showmips"
		}
	}
	local modeDesc = modeDescs[newMode]
	local modeName = "none"
	local mode = DebugRendering.NONE

	if modeDesc ~= nil then
		mode = modeDesc[1]
		modeName = modeDesc[2]
	end

	setDebugRenderingMode(mode)

	return "Changed debug rendering to " .. modeName
end

function consoleCommandChangeLanguage(newCode)
	local numLanguages = getNumOfLanguages()
	local newLang = -1

	if newCode == nil then
		local newIndex = g_settingsLanguageGUI + 1

		if table.getn(g_availableLanguagesTable) <= newIndex then
			newIndex = 0
		end

		newLang = g_availableLanguagesTable[newIndex + 1]
	else
		for i = 0, numLanguages - 1 do
			if getLanguageCode(i) == newCode then
				newLang = i

				break
			end
		end

		if newLang < 0 then
			return "Invalid language parameter " .. tostring(newCode)
		end
	end

	if setLanguage(newLang) then
		local xmlFile = loadXMLFile("SettingsFile", "dataS/settings.xml")

		loadLanguageSettings(xmlFile)
		delete(xmlFile)
		g_i18n:load()

		return "Changed language to " .. getLanguageCode(newLang)
	end

	return "Invalid language parameter " .. tostring(newCode)
end

function consoleCommandReloadCurrentGui()
	if g_gui.currentGuiName ~= nil and g_gui.currentGuiName ~= "" then
		local guiName = g_gui.currentGuiName

		g_gui:showGui("")
		g_i18n:load()
		g_gui:loadProfiles("dataS/guiProfiles.xml")

		local class = getClassObject(guiName)
		g_dummyGui = class:new()

		g_gui:loadGui("dataS/gui/" .. guiName .. ".xml", guiName, g_dummyGui)
		g_gui:showGui(guiName)
	end
end

function consoleCommandToggleUiDebug()
	if g_uiDebugEnabled then
		g_uiDebugEnabled = false

		return "UI Debug disabled"
	else
		g_uiDebugEnabled = true

		return "UI Debug enabled"
	end
end

function consoleCommandSuspendApp()
	if g_appIsSuspended then
		notifyAppResumed()
	else
		notifyAppSuspended()
	end

	return "App Suspended: " .. tostring(g_appIsSuspended)
end

function consoleCommandFuzzInput()
	beginInputFuzzing()
end

function calculateFovY(cameraNode)
	local fovY = getFovY(cameraNode)
	local maxAngle = fovY * g_fovYMax / g_fovYDefault
	local maxDelta = g_fovYMax - g_fovYDefault

	if g_fovYMax < maxAngle then
		maxDelta = g_fovYMax - fovY
	end

	local loadedFovY = g_gameSettings:getValue("fovY")

	if g_fovYDefault < loadedFovY then
		return fovY + maxDelta * (1 - (g_fovYMax - loadedFovY) / (g_fovYMax - g_fovYDefault))
	elseif loadedFovY < g_fovYDefault then
		return fovY - maxDelta * (1 - (loadedFovY - g_fovYMin) / (g_fovYDefault - g_fovYMin))
	else
		return fovY
	end
end

function finishedUserProfileSync()
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		g_lastUserName = g_gameSettings:getValue("nickname")

		loadUserSettings(g_gameSettings)
		g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
	elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
	end
end

function loadUserSettings(gameSettings, settingsModel)
	local nickname = StringUtil.trim(getUserName())

	if nickname == nil or nickname == "" then
		nickname = "Player"
	end

	gameSettings:setValue("nickname", nickname)
	gameSettings:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
	gameSettings:setValue("joystickVibrationEnabled", getGamepadVibrationEnabled())

	if g_savegameXML ~= nil then
		delete(g_savegameXML)
	end

	local gameSettingsPathTemplate = getAppBasePath() .. "profileTemplate/gameSettingsTemplate.xml"
	g_savegamePath = getUserProfileAppPath() .. "gameSettings.xml"

	copyFile(gameSettingsPathTemplate, g_savegamePath, false)

	g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)

	if settingsModel ~= nil then
		settingsModel:setSettingsFileHandle(g_savegameXML)
	end

	syncProfileFiles()

	local revision = getXMLInt(g_savegameXML, "gameSettings#revision")
	local gameSettingsTemplate = loadXMLFile("GameSettingsTemplate", gameSettingsPathTemplate)
	local revisionTemplate = getXMLInt(gameSettingsTemplate, "gameSettings#revision")

	delete(gameSettingsTemplate)

	if revision == nil or revision ~= revisionTemplate then
		copyFile(gameSettingsPathTemplate, g_savegamePath, true)
		delete(g_savegameXML)

		g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)

		if settingsModel ~= nil then
			settingsModel:setSettingsFileHandle(g_savegameXML)
		end
	end

	gameSettings:loadFromXML(g_savegameXML)
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MUSIC))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))

	if GS_IS_MOBILE_VERSION then
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.DEFAULT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
	end

	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
	g_soundMixer:setMasterVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MASTER))
	g_lifetimeStats:reload()
end

function log(...)
	local str = ""

	for i = 1, select("#", ...) do
		str = str .. " " .. tostring(select(i, ...))
	end

	print(str)
end

function registerGlobalActionEvents(inputManager)
	local function onTakeScreenShot()
		if g_screenshotsDirectory ~= nil then
			local screenshotName = g_screenshotsDirectory .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. ".png"

			print("Saving screenshot: " .. screenshotName)
			saveScreenshot(screenshotName)
		else
			print("Unable to find screenshot directory!")
		end
	end

	local eventAdded, eventId = inputManager:registerActionEvent(InputAction.TAKE_SCREENSHOT, InputBinding.NO_EVENT_TARGET, onTakeScreenShot, false, true, false, true)

	if eventAdded then
		inputManager:setActionEventTextVisibility(eventId, false)
	end
end

function print_r(tbl)
	if tbl == nil then
		print("table: nil")
	else
		DebugUtil.printTableRecursively(tbl, "  ", 0, 3)
	end
end

function printf(formatText, ...)
	print(string.format(formatText, ...))
end

if getIsUserSignedIn == nil then
	function getIsUserSignedIn()
		return true
	end
end

source("dataS/scripts/debug/ConsoleSimulator.lua")
source("dataS/scripts/debug/MobileSimulator.lua")
source("dataS/scripts/debug/MemoryLeaks.lua")
