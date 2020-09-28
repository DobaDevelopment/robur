require("common.log")
module("E2Utility", package.seeall, log.setup)

local _Core = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Geometry, Renderer, Vector, Collision, Orbwalker, Prediction =
	_Core.ObjectManager,
	_Core.EventManager,
	_Core.Input,
	_Core.Enums,
	_Core.Game,
	_Core.Geometry,
	_Core.Renderer,
	_Core.Geometry.Vector,
	_G.Libs.CollisionLib,
	_G.Libs.Orbwalker,
	_G.Libs.Prediction
local itemID = require("lol\\Modules\\Common\\itemID")
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player

-- Copied from Mista's scripts :)

-- Verision
local Version = 1.5

-- Menu
local Menu = _G.Libs.Menu:AddMenu("E2Utility", "E2Utility")
local JungleTimer = {}
local CloneTracker = {}
local InhibitorsTimer = {}
local DragonBaronTracker = {}
local CooldownTracker = {}
local Activator = {}
local TS = {}

local features = 6
local FeaturedClasses = {JungleTimer, CloneTracker, InhibitorsTimer, DragonBaronTracker, CooldownTracker, Activator}
local TextClipper = Vector(30, 15, 0)
local TickCount = 0

function JungleTimer:Init()
	-- A Bool to end Rift timer
	self.RiftOver = false
	self.TotalCamps = 16
	self.ObjName = "CampRespawn"
	self.ObjBuffName = "camprespawncountdownhidden"

	-- [id] hashtable ID
	-- ["m_name"] Name for the menu
	-- ["position"] Position for the jungle mob
	-- ["adjustment"] A Vector to adjust the position because some of them are at the accurate position
	-- ["respawn_timer"] Respawning time
	-- ["saved_time"] GameTime + Respawning Time
	-- ["active"] Active status for the current jungle mob
	-- ["b_menu"] Menu boolean value (Deleted)
	local emptyVector = Vector(0, 0, 0)
	self.JungleMobsData = {
		[821] = {
			["m_name"] = "Blue (West)",
			["position"] = Vector(3821.48, 51.12, 8101.05),
			["adjustment"] = Vector(0, -300, 0),
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true
		},
		[288] = {
			["m_name"] = "Gromp (West)",
			["position"] = Vector(2288.01, 51.77, 8448.13),
			["adjustment"] = Vector(-100, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true
		},
		[783] = {
			["m_name"] = "Wovles (West)",
			["position"] = Vector(3783.37, 52.46, 6495.56),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true
		},
		[61] = {
			["m_name"] = "Raptors (South)",
			["position"] = Vector(7061.5, 50.12, 5325.50),
			["adjustment"] = Vector(-100, 100, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true
		},
		[762] = {
			["m_name"] = "Red (South)",
			["position"] = Vector(7762.24, 53.96, 4011.18),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true
		},
		[394] = {
			["m_name"] = "Krugs (South)",
			["position"] = Vector(8394.76, 50.73, 2641.59),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true
		},
		[400] = {
			["m_name"] = "Scuttler (Baron)",
			["position"] = Vector(4400.00, -66.53, 9600.00),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 150,
			["saved_time"] = 195,
			["active"] = true
		},
		[500] = {
			["m_name"] = "Scuttler (Dragon)",
			["position"] = Vector(10500.00, -62.81, 5170.00),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 150,
			["saved_time"] = 195,
			["active"] = true
		},
		[866] = {
			["m_name"] = "Dragon",
			["position"] = Vector(9866.14, -71.24, 4414.01),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 300,
			["saved_time"] = 300,
			["active"] = true
		},
		[7] = {
			["m_name"] = "Baron/Rift",
			["position"] = Vector(5007.12, -71.24, 10471.44),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 360,
			["saved_time"] = 480,
			["active"] = true
		},
		[131] = {
			["m_name"] = "Blue (East)",
			["position"] = Vector(11131.72, 51.72, 6990.84),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true
		},
		[703] = {
			["m_name"] = "Gromp (East)",
			["position"] = Vector(12703.62, 51.69, 6443.98),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true
		},
		[59] = {
			["m_name"] = "Wovles (East)",
			["position"] = Vector(11059.76, 60.35, 8419.83),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true
		},
		[820] = {
			["m_name"] = "Raptors (North)",
			["position"] = Vector(7820.22, 52.19, 9644.45),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true
		},
		[66] = {
			["m_name"] = "Red (North)",
			["position"] = Vector(7066.86, 56.18, 10975.54),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true
		},
		[499] = {
			["m_name"] = "Krugs (North)",
			["position"] = Vector(6499.49, 56.47, 12287.37),
			["adjustment"] = emptyVector,
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true
		}
	}

	self.JungleTimerTable = {821, 783, 61, 762, 131, 59, 820, 66, 499, 394, 288, 703, 400, 500, 866, 7}
	JungleTimer:Menu()
end

function JungleTimer:Menu()
	local this = self
	this.S_Menu1 = Menu:AddMenu("JGT_Menu", "JungleTimer")
	this.S_Menu1_Settings = this.S_Menu1:AddMenu("JGT_Settings", "Jungle Timer Settings")
	this.S_Menu1_OnMap = this.S_Menu1_Settings:AddBool("JGT_DrawMap", "Use on the Map", true)
	this.S_Menu1_OnMapColor = this.S_Menu1_Settings:AddRGBAMenu("JGT_MapTextCol", "Timer Text on Map Color", 0x00FF00FF)
	this.S_Menu1_OnMapBackground = this.S_Menu1_Settings:AddBool("JGT_BGColT", "Use a Background Color", true)
	this.S_Menu1_OnMapBackgroundColor = this.S_Menu1_Settings:AddRGBAMenu("JGT_BGCol", "Background Color", 0x008000FF)
	this.S_Menu1_OnMinimap = this.S_Menu1_Settings:AddBool("JGT_OnMinimap", "Use on the Minimap", true)
	this.S_Menu1_OnMinimapColor =
		this.S_Menu1_Settings:AddRGBAMenu("JGT_MiniMapTextCol", "Timer Text on Minimap Color", 0x00FF00FF)
	this.S_Menu1_JTActive = this.S_Menu1:AddBool("JGT_ToggleTimer", "Activate Jungle Timer", true)
	this.S_Menu1_Label1 = this.S_Menu1:AddLabel("JGT_ExploitLabel", "An Exploit Included")
end

-- Credit to jesseadams - https://gist.github.com/jesseadams/791673
local function SecondsToClock(seconds)
	--local seconds = tonumber(seconds)
	if seconds <= 0 then
		local default = "0:00"
		return default
	else
		local floor = math.floor
		local format = string.format
		local hours = floor(seconds * (1 / 3600))
		local mins = format("%01.f", floor(seconds * (1 / 60) - (hours * 60)))
		local secs = format("%02.f", floor(seconds - hours * 3600 - mins * 60))
		local str = mins .. ":" .. secs
		return str
	end
end

local function GetHash(arg)
	local floor = math.floor
	return (floor(arg) % 1000)
end

function JungleTimer:OnDraw()
	-- ForLooping only table has at least one element
	local this = self
	local renderer = Renderer
	local DrawFilledRect = renderer.DrawFilledRect
	local DrawText = renderer.DrawText
	if (#this.JungleTimerTable > 0 and this.S_Menu1_JTActive.Value) then
		local currentGameTime = Game.GetTime()
		local totalCamps = this.TotalCamps
		local JungleMobsData = this.JungleMobsData
		for i = 1, totalCamps do
			local hash = this.JungleTimerTable[i]
			if (JungleMobsData[hash]["active"]) then
				local timeleft = JungleMobsData[hash]["saved_time"] - currentGameTime
				-- First condition for removing ended timers and the second one for removing rift timer after baron spawned.
				if (timeleft <= 0) then
					JungleMobsData[hash]["active"] = false
				else
					if (hash == 7 and currentGameTime >= 1200 and this.RiftOver == false) then
						this.RiftOver = true
						JungleMobsData[hash]["active"] = false
					else
						-- adjustment vector for correcting position for some jungle mobs
						local pos = JungleMobsData[hash]["position"] + JungleMobsData[hash]["adjustment"]
						-- convert time into m:ss format
						local time = SecondsToClock(timeleft)
						-- draw only pos is on the screen
						if (renderer.IsOnScreen(pos)) then
							local worldPos = renderer.WorldToScreen(pos)
							if (this.S_Menu1_OnMap.Value) then
								if (this.S_Menu1_OnMapBackground.Value) then
									DrawFilledRect(worldPos, TextClipper, 2, this.S_Menu1_OnMapBackgroundColor.Value)
								end
								DrawText(worldPos, TextClipper, time, this.S_Menu1_OnMapColor.Value)
							end
						end
						if (this.S_Menu1_OnMinimap.Value) then
							local miniPos = renderer.WorldToMinimap(pos) + Vector(-10, -10, 0)
							DrawText(miniPos, TextClipper, time, this.S_Menu1_OnMinimapColor.Value)
						end
					end
				end
			end
		end
	end
end

local function TimerStarter(t, objHandle)
	local objhandle = objHandle
	local this = t
	local ObjectAI = ObjManager.GetObjectByHandle(objhandle).AsAI
	if (ObjectAI) then
		local JungleMobsData = this.JungleMobsData
		local objBuffCount = ObjectAI.BuffCount
		for i = 0, objBuffCount do
			local buff = ObjectAI:GetBuff(i)
			if (buff) then
				local buffName = buff.Name
				if (buffName == this.ObjBuffName) then
					local hashID = GetHash(ObjectAI.Position.x)
					if (JungleMobsData[hashID]) then
						local endTime = buff.StartTime + JungleMobsData[hashID]["respawn_timer"] + 1
						JungleMobsData[hashID]["saved_time"] = endTime
						JungleMobsData[hashID]["active"] = true
						break
					end
				end
			end
		end
	end
end

function JungleTimer:OnCreate(objArg)
	-- Jungle Timer
	local obj = objArg
	local this = self
	local objName = this.ObjName
	if (this.S_Menu1_JTActive.Value and obj.Name == objName) then
		delay(100, TimerStarter, this, obj.Handle)
	end
end

function JungleTimer:OnDelete(objArg)
	local obj = objArg
	local this = self
	local objName = this.ObjName
	if (this.S_Menu1_JTActive.Value and obj.Name == objName) then
		local hashID = GetHash(obj.AsAI.Position.x)
		local target = this.JungleMobsData[hashID]
		if (target) then
			target["saved_time"] = -1
			target["active"] = false
		end
	end
end

function CloneTracker:Init()
	-- Clone Tracker Variables
	self.CloneEnum = {}
	self.CloneEnumCount = 1
	self.CloneActiveCount = 0
	self.CloneAdjustment = Vector(-15, -50, 0)
	local tableTemplate = {nil, false}
	self.CloneTracker = {
		["Shaco"] = tableTemplate,
		["Leblanc"] = tableTemplate,
		["MonkeyKing"] = tableTemplate,
		["Neeko"] = tableTemplate
	}
	self.Text = "CLONE"
	self.TextRectVec = Vector(36, 15, 0)
	-- End of Clone Tracker Variables

	local enemyList = ObjManager.Get("enemy", "heroes")
	local template = {nil, true}
	for handle, enemy in pairs(enemyList) do
		if (enemy and enemy.IsAI) then
			local cloneChamp = enemy.AsAI
			local charName = cloneChamp.CharName
			if (self.CloneTracker[charName]) then
				self.CloneTracker[charName] = template
				self.CloneEnum[self.CloneEnumCount] = charName
				self.CloneEnumCount = self.CloneEnumCount + 1
			end
		end
	end

	CloneTracker:Menu()
end

function CloneTracker:Menu()
	-- Start Clone Tracker Menus
	local this = self
	this.S_Menu2 = Menu:AddMenu("CT_Menu", "CloneTracker")
	this.S_Menu2_Settings = this.S_Menu2:AddMenu("CT_Settings", "Clone Tracker Settings")
	this.S_Menu2_OnMap = this.S_Menu2_Settings:AddBool("CT_TrackOnMap", "Track Clones", true)
	this.S_Menu2_OnMapColor = this.S_Menu2_Settings:AddRGBAMenu("CT_MapTextCol", "Clone Tracker on Text Color", 0x000000FF)
	this.S_Menu2_OnMapBackground = this.S_Menu2_Settings:AddBool("CT_DrawBGCol", "Use a Clone Background Color", true)
	this.S_Menu2_OnMapBackgroundColor = this.S_Menu2_Settings:AddRGBAMenu("CT_BGCol", "Clone Background Color", 0xDF0101FF)
	this.S_Menu2_CTActive = this.S_Menu2:AddBool("CT_Toggle", "Activate Clone Tracker", true)
	this.S_Menu2_Label1 = this.S_Menu2:AddLabel("CT_InfoLabel", "Works on Shaco/Wukong/Leblanc/Neeko")
	-- End of Clone Tracker Section
end

function CloneTracker:OnDraw()
	local this = self
	local enumCount = this.CloneEnumCount - 1
	local activeCount = this.CloneActiveCount
	local cloneEnum = this.CloneEnum
	local renderer = Renderer
	local DrawFilledRect = renderer.DrawFilledRect
	local DrawText = renderer.DrawText
	if (this.S_Menu2_CTActive.Value and enumCount > 0 and activeCount > 0) then
		local cloneTracker = this.CloneTracker
		for i = 1, enumCount do
			local charName = cloneEnum[i]
			if (cloneTracker[charName][1] and cloneTracker[charName][2] == true) then
				local pos = cloneTracker[charName][1].Position
				if (renderer.IsOnScreen(pos)) then
					local posw2s = renderer.WorldToScreen(pos) + this.CloneAdjustment
					if (this.S_Menu2_OnMapBackground.Value) then
						DrawFilledRect(posw2s, this.TextRectVec, 2, this.S_Menu2_OnMapBackgroundColor.Value)
					end
					if (this.S_Menu2_OnMap.Value) then
						DrawText(posw2s, TextClipper, this.Text, this.S_Menu2_OnMapColor.Value)
					end
				end
			end
		end
	end
end

function CloneTracker:OnCreate(objArg)
	local obj = objArg
	local this = self
	if (this.S_Menu2_CTActive.Value and obj.IsAI) then
		local cloneChamp = obj.AsAI
		if (cloneChamp ~= nil and cloneChamp.IsValid) then
			local cloneTracker = this.CloneTracker
			local charName = cloneChamp.CharName
			if (cloneTracker[charName] and cloneTracker[charName][2] == true) then
				cloneTracker[charName][1] = cloneChamp
				this.CloneActiveCount = this.CloneActiveCount + 1
			end
		end
	end
end

function CloneTracker:OnDelete(objArg)
	local obj = objArg
	local this = self
	if (this.S_Menu2_CTActive.Value and obj.IsAI) then
		local cloneChamp = obj.AsAI
		if (cloneChamp and cloneChamp.IsValid) then
			local cloneTracker = this.CloneTracker
			local charName = cloneChamp.CharName
			if (cloneTracker[charName] and cloneTracker[charName][2] == true) then
				cloneTracker[charName][1] = nil
				-- Decrease the count only greater than 0
				local activeCount = this.CloneActiveCount
				if (activeCount > 0) then
					this.CloneActiveCount = activeCount - 1
				end
			end
		end
	end
end

function InhibitorsTimer:Init()
	self.InhibitorsTable = {
		-- Ally Top, Mid, Bot
		[171] = {
			IsDestroyed = false,
			Position = Vector(1171, 91, 3571),
			RespawnTime = 0.0
		},
		[203] = {
			IsDestroyed = false,
			Position = Vector(3203, 92, 3208),
			RespawnTime = 0.0
		},
		[452] = {
			IsDestroyed = false,
			Position = Vector(3452, 89, 1236),
			RespawnTime = 0.0
		},
		-- Enemy Top, Mid, Bot
		[261] = {
			IsDestroyed = false,
			Position = Vector(11261, 88, 13676),
			RespawnTime = 0.0
		},
		[598] = {
			IsDestroyed = false,
			Position = Vector(11598, 89, 11667),
			RespawnTime = 0.0
		},
		[604] = {
			IsDestroyed = false,
			Position = Vector(13604, 89, 11316),
			RespawnTime = 0.0
		}
	}
	self.InhibitorsEnum = {171, 203, 452, 261, 598, 604}
	self.Inhibitors = 6
	self.DestroyedInhibitors = 0
	self.ConstRespawnTime = 300.0

	self.SpawnComparor = {
		["SRUAP_Chaos_Inhibitor_Spawn_sound.troy"] = true,
		["SRUAP_Order_Inhibitor_Idle1_sound.troy"] = true
	}
	self.DestroyComparor = {
		["SRUAP_Chaos_Inhibitor_Idle1_soundy.troy"] = true,
		["SRUAP_Order_Inhibitor_Idle1_sound.troy"] = true
	}

	local inhibitorsList = ObjManager.Get("all", "inhibitors")
	for k, obj in pairs(inhibitorsList) do
		local objAT = obj.AsAttackableUnit
		if (obj and obj.IsValid and objAT.Health <= 0.0) then
			local hash = GetHash(obj.Position.x)
			self.InhibitorsTable[hash].IsDestroyed = true
			self.DestroyedInhibitors = self.DestroyedInhibitors + 1
		end
	end

	InhibitorsTimer:Menu()
end

function InhibitorsTimer:Menu()
	local this = self
	this.S_Menu = Menu:AddMenu("IT_Menu", "InhibitorsTimer")
	this.S_Menu_Settings = this.S_Menu:AddMenu("IT_Settings", "Inhibitors Timer Settings")
	this.S_Menu_OnMap = this.S_Menu_Settings:AddBool("IT_TimerText", "Use a Inhibitors Timer Text", true)
	this.S_Menu_OnMapColor = this.S_Menu_Settings:AddRGBAMenu("IT_TextCol", "Inhibitors Timer Text Color", 0x000000FF)
	this.S_Menu_OnMapBackground = this.S_Menu_Settings:AddBool("IT_BGToggle", "Use a Inhibitors Timer Background", true)
	this.S_Menu_OnMapBackgroundColor =
		this.S_Menu_Settings:AddRGBAMenu("IT_BGCol", "Inhibitors Timer Background Color", 0xDF0101FF)
	this.S_Menu_OnMinimap = this.S_Menu_Settings:AddBool("IT_MapToggle", "Use a Inhibitors Timer Minimap", false)
	this.S_Menu_OnMinimapColor =
		this.S_Menu_Settings:AddRGBAMenu("IT_MapCol", "Inhibitors Timer Minimap Color", 0x00FF00FF)
	-- TODO Maybe I gotta add them later
	--self.S_Menu_AllyActive = self.S_Menu:AddBool("Track Ally Inhibitors Timer", true)
	--self.S_Menu_EnemyActive = self.S_Menu:AddBool("Track Enemy Inhibitors Timer", true)
	self.S_Menu_Active = self.S_Menu:AddBool("IT_Toggle", "Activate Inhibitors Timer", true)
end

function InhibitorsTimer:OnDelete(objArg)
	local obj = objArg
	local objName = obj.Name
	local this = self
	if (not obj.IsAttackbleUnit and not obj.IsValid and not this.S_Menu_Active.Value and not objName) then
		return
	end
	local DestroyComparor = this.DestroyComparor
	local SpawnComparor = this.SpawnComparor
	local InhibitorsTable = this.InhibitorsTable
	local hash = GetHash(obj.Position.x)
	if (DestroyComparor[objName]) then
		InhibitorsTable[hash].IsDestroyed = true
		local respawnTime = Game:GetTime() + this.ConstRespawnTime
		InhibitorsTable[hash].RespawnTime = respawnTime
		this.DestroyedInhibitors = this.DestroyedInhibitors + 1
	else
		if (SpawnComparor[objName]) then
			InhibitorsTable[hash].IsDestroyed = false
			InhibitorsTable[hash].RespawnTime = 0.0
			if (this.DestroyedInhibitors > 0) then
				this.DestroyedInhibitors = this.DestroyedInhibitors - 1
			end
		end
	end
end

function InhibitorsTimer:OnDraw()
	local this = self
	local DestroyedInhibitors = this.DestroyedInhibitors
	local renderer = Renderer
	local DrawFilledRect = renderer.DrawFilledRect
	local DrawText = renderer.DrawText
	if (this.S_Menu_Active.Value and DestroyedInhibitors > 0) then
		local Inhibitors = this.Inhibitors
		local InhibitorsEnum = this.InhibitorsEnum
		local InhibitorsTable = this.InhibitorsTable
		for i = 1, Inhibitors do
			local index = InhibitorsEnum[i]
			if (InhibitorsTable[index].IsDestroyed) then
				local time = InhibitorsTable[index].RespawnTime - Game.GetTime()
				local timeleft = SecondsToClock(time)
				if (time <= 0) then
					InhibitorsTable[index].IsDestroyed = false
					InhibitorsTable[index].RespawnTime = 0.0
					if (DestroyedInhibitors > 0) then
						self.DestroyedInhibitors = DestroyedInhibitors - 1
					end
				else
					local pos = InhibitorsTable[index].Position
					local posw2s = renderer.WorldToScreen(pos)
					local posw2m = renderer.WorldToMinimap(pos) + Vector(-15, -10, 0)
					--draw only pos is on the screen
					if (renderer.IsOnScreen(pos)) then
						if (this.S_Menu_OnMap.Value) then
							if (this.S_Menu_OnMapBackground.Value) then
								DrawFilledRect(posw2s, TextClipper, 2, this.S_Menu_OnMapBackgroundColor.Value)
							end
							DrawText(posw2s, TextClipper, timeleft, this.S_Menu_OnMapColor.Value)
						end
					end

					if (this.S_Menu_OnMinimap.Value) then
						DrawText(posw2m, TextClipper, timeleft, this.S_Menu_OnMinimapColor.Value)
					end
				end
			end
		end
	end
end

function DragonBaronTracker:Init()
	--[[
		IsDragon: 1 - Dragon, 2 - Baron
		IsAttacking: 1 - Attacking, 2 - Resetting, 3 - Dead
	]]
	self.DragonBaronTable = {
		["SRU_Dragon_Spawn_Praxis.troy"] = {IsDragon = 1, IsAttacking = 1},
		["SRU_Dragon_idle1_landing_sound.troy"] = {IsDragon = 1, IsAttacking = 2},
		["SRU_Dragon_death_sound.troy"] = {IsDragon = 1, IsAttacking = 3},
		["SRU_Baron_Base_BA1_tar.troy"] = {IsDragon = 2, IsAttacking = 1},
		["SRU_Baron_death_sound.troy"] = {IsDragon = 2, IsAttacking = 3}
	}
	self.DragonMessage = "DRAGON IS BEING ATTACKED"
	self.BaronMessage = "BARON IS BEING ATTACKED"
	self.DragonBaronStatus = {2, 2}
	local playerResolution = Renderer.GetResolution()
	local floor = math.floor
	self.AlertPosition = Vector(floor(playerResolution.x) * (1 / 2) - 80.0, floor(playerResolution.y) * (1 / 6), 0)
	self.AlertRectPosition = self.AlertPosition - Vector(15, 0, 0)
	self.BaronAlertPosition = self.AlertPosition - Vector(0, 20, 0)
	self.BaronRectAlertPosition = self.BaronAlertPosition - Vector(15, 0, 0)
	self.BaronActiveStatus = Game.GetTime()
	self.TextClipper = Vector(200, 15, 0)

	DragonBaronTracker:Menu()
end

function DragonBaronTracker:Menu()
	local this = self
	this.S_Menu = Menu:AddMenu("DBTracker", "DragonBaronTracker")
	this.S_Menu_Settings = this.S_Menu:AddMenu("DBT_Settings", "Dragon Baron Tracker Settings")
	this.S_Menu_Dragon = this.S_Menu_Settings:AddBool("DBT_DragonToggle", "Track Dragon", true)
	this.S_Menu_DragonColor =
		this.S_Menu_Settings:AddRGBAMenu("DBT_DragonTextCol", "Dragon Tracker Text Color", 0x000000FF)
	this.S_Menu_DragonBackground =
		this.S_Menu_Settings:AddBool("DBT_DragonBGToggle", "Use a Dragon Tracker Background", true)
	this.S_Menu_DragonBackgroundColor =
		this.S_Menu_Settings:AddRGBAMenu("DBT_DragonBGCol", "Dragon Tracker Background Color", 0xCC6600FF)

	this.S_Menu_Baron = this.S_Menu_Settings:AddBool("DBT_BaronToggle", "Track Baron", true)
	this.S_Menu_BaronColor = this.S_Menu_Settings:AddRGBAMenu("DBT_BaronTextCol", "Baron Tracker Text Color", 0x000000FF)
	this.S_Menu_BaronBackground = this.S_Menu_Settings:AddBool("DBT_BaronBGToggle", "Use a Baron Tracker Background", true)
	this.S_Menu_BaronBackgroundColor =
		this.S_Menu_Settings:AddRGBAMenu("DBT_BaronBGCol", "Baron Tracker Background Color", 0x990099FF)

	this.S_Menu_Active = this.S_Menu:AddBool("DBT_Toggle", "Activate Dragon Baron Tracker", true)
	this.S_Menu_Label1 = this.S_Menu:AddLabel("DBT_ExploitLabel", "The Exploit Works on Fog of War")
end

function DragonBaronTracker:OnDelete(objArg)
	local obj = objArg
	local objName = obj.Name
	local this = self
	if (this.S_Menu_Active.Value and obj and objName) then
		local DragonBaronTable = this.DragonBaronTable
		if (DragonBaronTable[objName]) then
			local DragonBaronStatus = this.DragonBaronStatus
			DragonBaronStatus[DragonBaronTable[objName].IsDragon] = DragonBaronTable[objName].IsAttacking
			-- only baron
			if (DragonBaronTable[objName].IsDragon == 2 and DragonBaronTable[objName].IsAttacking ~= 3) then
				local time = Game.GetTime()
				local status = time + 2
				this.BaronActiveStatus = status
				delay(
					3000,
					function()
						if (time >= this.BaronActiveStatus) then
							DragonBaronStatus[DragonBaronTable[objName].IsDragon] = 2
						end
					end
				)
			end
		end
	end
end

function DragonBaronTracker:OnDraw()
	local this = self
	if (not self.S_Menu_Active.Value) then
		return
	end
	local renderer = Renderer
	local DrawFilledRect = renderer.DrawFilledRect
	local DrawText = renderer.DrawText

	-- Maybe I can reduce below lines later..
	if (this.S_Menu_Dragon.Value and this.DragonBaronStatus[1] == 1) then
		DrawFilledRect(this.AlertRectPosition, this.TextClipper, 2, this.S_Menu_DragonBackgroundColor.Value)
		DrawText(this.AlertPosition, this.TextClipper, this.DragonMessage, this.S_Menu_DragonColor.Value)
	end

	if (this.S_Menu_Baron.Value and this.DragonBaronStatus[2] == 1) then
		DrawFilledRect(this.BaronRectAlertPosition, this.TextClipper, 2, self.S_Menu_BaronBackgroundColor.Value)
		DrawText(this.BaronAlertPosition, this.TextClipper, this.BaronMessage, this.S_Menu_BaronColor.Value)
	end
end

function CooldownTracker:Init()
	self.Heroes = {true, true, true, true, true, true, true, true, true, true}
	self.StringFormat = "%.f"
	self.EnumColor = {
		NotLearned = 1,
		Ready = 2,
		OnCooldown = 3,
		AlmostReady = 4,
		NoMana = 5
	}
	self.ColorList = {
		[1] = 0x666666FF, --NotLearned
		[2] = 0x00CC00FF, --Ready
		[3] = 0xE60000FF, --OnCooldown
		[4] = 0xff6A00FF, --AlmostReady
		[5] = 0x1AffffFF --NoMana
	}

	self.BoxOutline = 0x333333FF
	self.TextColor = 0x00FF00FF
	self.TextColorBlack = 0x0d0d0dFF

	self.SpellBackground = Vector(104, 5, 0)
	self.SpellBoxVector = Vector(25, 5, 0)
	self.SSBoxVector = Vector(30, 12, 0)
	self.SummonerSpellsStructure = {
		["SummonerBarrier"] = {Name = "Barrier", Color = 0xffb833ff, CDColor = 0xbd7b00ff},
		["SummonerBoost"] = {Name = "Cleanse", Color = 0x33ffffff, CDColor = 0x00bdbdff},
		["SummonerDot"] = {Name = "Ignite", Color = 0xff3333ff, CDColor = 0xbd0000ff},
		["SummonerExhaust"] = {Name = "Exhaust", Color = 0xb3b300ff, CDColor = 0x3d3d00ff},
		["SummonerFlash"] = {Name = "Flash", Color = 0xffff33ff, CDColor = 0xbdbd00ff},
		["SummonerFlashPerksHextechFlashtraptionV2"] = {Name = "HexFlash", Color = 0xff9ecfff, CDColor = 0xff42a1ff},
		["SummonerHaste"] = {Name = "Ghost", Color = 0x00b3b3ff, CDColor = 0x009999ff},
		["SummonerHeal"] = {Name = "Heal", Color = 0x00b300ff, CDColor = 0x003d00ff},
		["SummonerMana"] = {Name = "Clarity", Color = 0x3333ffff, CDColor = 0x0000f0ff},
		["SummonerSmite"] = {Name = "Smite", Color = 0xcead82ff, CDColor = 0xc0955dff},
		["S5_SummonerSmiteDuel"] = {Name = "RedSmite", Color = 0xff6a00ff, CDColor = 0x8a3900ff},
		["S5_SummonerSmitePlayerGanker"] = {Name = "BlueSmite", Color = 0xff6a00ff, CDColor = 0x8a3900ff},
		["SummonerSnowball"] = {Name = "SnowBall", Color = 0x3333ffff, CDColor = 0x0000bdff},
		["SummonerTeleport"] = {Name = "Teleport", Color = 0xff33ffff, CDColor = 0xbd00bdff},
		["Empty"] = {Name = "Empty", Color = 0x999999ff, CDColor = 0x5e5e5eff}
	}

	local AdjustmentRequired = {
		["Annie"] = {1, Vector(0, 10, 0)},
		["Jhin"] = {1, Vector(0, 10, 0)},
		["Zoe"] = {2, Vector(25, 0, 0)},
		["Aphelios"] = {2, Vector(52, 0, 0)},
		["Sylas"] = {2, Vector(28, 0, 0)}
	}

	self.count = 1
	local champList = ObjManager.Get("all", "heroes")
	for k, v in pairs(champList) do
		local objHero = v.AsHero
		if (objHero and objHero.IsValid) then
			self.Heroes[self.count] = {true, true, true}

			local adjust = AdjustmentRequired[objHero.CharName]

			if (adjust) then
				self.Heroes[self.count][3] = adjust
			else
				self.Heroes[self.count][3] = {3, nil}
			end

			local copySpell = {
				[0] = {
					Spell = nil,
					IsLearned = false,
					PctCooldown = 0.0,
					RemainingCooldown = 0.0,
					IsEnoughMana = false,
					Color = 1,
					Color2 = 1
				},
				[1] = {
					Spell = nil,
					IsLearned = false,
					PctCooldown = 0.0,
					RemainingCooldown = 0.0,
					IsEnoughMana = false,
					Color = 1,
					Color2 = 1
				},
				[2] = {
					Spell = nil,
					IsLearned = false,
					PctCooldown = 0.0,
					RemainingCooldown = 0.0,
					IsEnoughMana = false,
					Color = 1,
					Color2 = 1
				},
				[3] = {
					Spell = nil,
					IsLearned = false,
					PctCooldown = 0.0,
					RemainingCooldown = 0.0,
					IsEnoughMana = false,
					Color = 1,
					Color2 = 1
				},
				[4] = {Spell = nil, RemainingCooldown = 0.0, Name = "Empty"},
				[5] = {Spell = nil, RemainingCooldown = 0.0, Name = "Empty"}
			}

			for i = SpellSlots.Q, SpellSlots.R do
				local t_spell = objHero:GetSpell(i)

				if (t_spell) then
					copySpell[i].Spell = t_spell
					if (t_spell.IsLearned) then
						copySpell[i].IsLearned = true
						local cd = t_spell.RemainingCooldown
						local tcd = t_spell.TotalCooldown

						copySpell[i].RemainingCooldown = cd
						-- Got from 48656c6c636174
						local pct = (25 * (1 / tcd)) * cd
						if (pct) then
							copySpell[i].PctCooldown = pct
						end
						if (cd > 0.0) then
							copySpell[i].Color = self.EnumColor.NotLearned

							if (cd <= 10.0) then
								copySpell[i].Color2 = self.EnumColor.AlmostReady
							else
								copySpell[i].Color2 = self.EnumColor.OnCooldown
							end
						else
							copySpell[i].Color = self.EnumColor.Ready
							local mana = objHero.Mana - t_spell.ManaCost
							if (mana < 0) then
								copySpell[i].IsEnoughMana = false
								copySpell[i].Color = self.EnumColor.NoMana
							else
								copySpell[i].IsEnoughMana = true
							end
						end
					else
						copySpell[i].IsLearned = false
						copySpell[i].Color = self.EnumColor.NotLearned
					end
				end
			end

			for i = SpellSlots.Summoner1, SpellSlots.Summoner2 do
				local t_spell = objHero:GetSpell(i)

				if (t_spell) then
					copySpell[i].Spell = t_spell
					local cd = t_spell.RemainingCooldown
					copySpell[i].RemainingCooldown = cd

					local ssName = t_spell.Name
					local ss = self.SummonerSpellsStructure[ssName]
					if (ss) then
						copySpell[i].Name = ssName
					end
				end
			end
			self.Heroes[self.count][1] = copySpell
			self.Heroes[self.count][2] = objHero
			self.count = self.count + 1
		end
	end
	self.count = self.count - 1
	CooldownTracker:Menu()
end

function CooldownTracker:Menu()
	local this = self
	this.S_Menu = Menu:AddMenu("CDTracker", "CooldownTracker")
	this.S_Menu_Settings = this.S_Menu:AddMenu("CDTracker_Settings", "Cooldown Tracker Settings")
	this.S_Menu_TrackMe = this.S_Menu_Settings:AddBool("CDTracker_TrackMe", "Track Me", true)
	this.S_Menu_TrackAlly = this.S_Menu_Settings:AddBool("CDTracker_TrackAlly", "Track Ally", true)
	this.S_Menu_TrackEnemy = this.S_Menu_Settings:AddBool("CDTracker_TrackEnemy", "Track Enemy", true)
	this.S_Menu_Adjust = this.S_Menu_Settings:AddBool("CDTracker_Adjustment", "Adjust CDTracker Position", true)
	this.S_Menu_Settings:AddLabel("CDTracker_AdjustmentLabel", "^-Annie, Aphelios, Jhin, Zoe, Sylas", true)

	this.S_Menu_Active = this.S_Menu:AddBool("CDTracker_Toggle", "Activate Cooldown Tracker", true)
end

function CooldownTracker:OnTick()
	local this = self
	if (this.S_Menu_Active.Value ) then
		local Heroes = this.Heroes
		local maxHeroes = self.count
		local floor = math.floor
		local IsOnScreen = Renderer.IsOnScreen
		for h = 1, maxHeroes do
			local objHero = Heroes[h][2].AsHero
			if (objHero and objHero.IsValid and objHero.IsVisible and not objHero.IsDead and IsOnScreen(objHero.Position)) then
				if
					((objHero.IsMe and this.S_Menu_TrackMe.Value) or
						(objHero.IsAlly and not objHero.IsMe and this.S_Menu_TrackAlly.Value) or
						(objHero.IsEnemy and this.S_Menu_TrackEnemy.Value))
				 then
					for i = SpellSlots.Q, SpellSlots.R do
						local copySpell = Heroes[h][1]

						if (copySpell[i].Spell.IsLearned) then
							copySpell[i].IsLearned = true
							local cd = copySpell[i].Spell.RemainingCooldown
							local tcd = copySpell[i].Spell.TotalCooldown
							copySpell[i].RemainingCooldown = cd
							-- Got from 48656c6c636174
							local pct = floor((25 * (1 / tcd)) * cd)

							if (pct) then
								copySpell[i].PctCooldown = pct
							end

							if (cd > 0.0) then
								copySpell[i].Color = self.EnumColor.NotLearned
								if (cd <= 10.0) then
									copySpell[i].Color2 = self.EnumColor.AlmostReady
								else
									copySpell[i].Color2 = self.EnumColor.OnCooldown
								end
							else
								copySpell[i].Color = self.EnumColor.Ready
								local mana = objHero.Mana - copySpell[i].Spell.ManaCost
								if (mana < 0) then
									copySpell[i].IsEnoughMana = false
									copySpell[i].Color = self.EnumColor.NoMana
								else
									copySpell[i].IsEnoughMana = true
								end
							end
						else
							copySpell[i].IsLearned = false
							copySpell[i].Color = self.EnumColor.NotLearned
						end
						Heroes[h][1] = copySpell
					end

					for i = SpellSlots.Summoner1, SpellSlots.Summoner2 do
						local copySpell = Heroes[h][1]
						local objHero = Heroes[h][2]
						local t_spell = objHero:GetSpell(i)
						if (t_spell) then
							copySpell[i].Spell = t_spell
							local cd = t_spell.RemainingCooldown
							copySpell[i].RemainingCooldown = cd
							local ssName = t_spell.Name
							local ss = self.SummonerSpellsStructure[ssName]
							if (ss) then
								copySpell[i].Name = ssName
							end
						end
						Heroes[h][1] = copySpell
					end
				end
			end
		end
	end
end

function CooldownTracker:OnDraw()
	local this = self
	if (this.S_Menu_Active.Value) then
		local renderer = Renderer
		local DrawFilledRect = renderer.DrawFilledRect
		local DrawText = renderer.DrawText
		local DrawRectOutline = renderer.DrawRectOutline
		local IsOnScreen2D = renderer.IsOnScreen2D

		local Heroes = this.Heroes
		local maxHeroes = this.count
		local format = string.format

		for h = 1, maxHeroes do
			local objHero = Heroes[h][2].AsHero
			local adjustment = Heroes[h][3]
			local hpPos = objHero.HealthBarScreenPos

			if (objHero and objHero.IsValid and objHero.IsVisible and not objHero.IsDead and IsOnScreen2D(hpPos)) then
				if
					((objHero.IsMe and this.S_Menu_TrackMe.Value) or
						(objHero.IsAlly and not objHero.IsMe and this.S_Menu_TrackAlly.Value) or
						(objHero.IsEnemy and this.S_Menu_TrackEnemy.Value))
				 then
					if (adjustment[1] == 1 and this.S_Menu_Adjust.Value) then
						hpPos = hpPos + adjustment[2]
					end
					DrawFilledRect(
						Vector(hpPos.x - 45, hpPos.y - 2, 0),
						this.SpellBackground,
						2,
						this.ColorList[this.EnumColor.NotLearned]
					)
					local SpellBoxVector = this.SpellBoxVector
					for i = SpellSlots.Q, SpellSlots.R do
						local copySpell = Heroes[h][1]

						local color = this.ColorList[copySpell[i].Color]
						local color2 = this.ColorList[copySpell[i].Color2]
						local pos = hpPos + Vector(26 * i - 45, -2, 0)
						if (color and color2) then
							if (copySpell[i].RemainingCooldown > 0) then
								local pctPos = Vector(26 - copySpell[i].PctCooldown, 5, 0)
								DrawFilledRect(pos, pctPos, 1, color2)
								DrawRectOutline(pos, SpellBoxVector, 2, 2, this.BoxOutline)
								pos = Vector(pos.x + 4, pos.y + 7, 0)
								DrawText(pos, TextClipper, format(this.StringFormat, copySpell[i].RemainingCooldown), this.TextColor)
							else
								DrawFilledRect(pos, SpellBoxVector, 2, color)
								DrawRectOutline(pos, SpellBoxVector, 2, 2, this.BoxOutline)
							end
						end
					end

					local ssBox = this.SSBoxVector
					hpPos = objHero.HealthBarScreenPos
					if (adjustment[1] == 2 and this.S_Menu_Adjust.Value) then
						hpPos = hpPos + adjustment[2]
					end

					for i = SpellSlots.Summoner1, SpellSlots.Summoner2 do
						local copySpell = Heroes[h][1]
						local pos = Vector(hpPos.x + 65, 13 * (i - 1) + hpPos.y - 65, 0)
						if (copySpell) then
							local posText = Vector(hpPos.x + 70, 13 * (i - 1) + hpPos.y - 65, 0)
							if (copySpell[i].RemainingCooldown > 0) then
								DrawFilledRect(pos, ssBox, 2, this.SummonerSpellsStructure[copySpell[i].Name].CDColor)
								DrawText(posText, TextClipper, format(this.StringFormat, copySpell[i].RemainingCooldown), this.TextColorBlack)
							else
								DrawFilledRect(pos, ssBox, 2, this.SummonerSpellsStructure[copySpell[i].Name].Color)
							end
						end
						DrawRectOutline(pos, ssBox, 2, 2, this.BoxOutline)
					end
				end
			end
		end
	end
end

function Activator:Init()
	self.EnumMode = {"Combo", "Harass"}
	self.EnumOffensiveType = {
		Targeted = 1,
		NonTargeted = 2,
		Active = 3
	}

	self.Offensive = {
		[itemID.HextechGunblade] = {
			Name = "Hextech Gunblade",
			Type = self.EnumOffensiveType.Targeted,
			Range = 700,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Gunblade",
			Menu = {}
		},
		[itemID.BladeOftheRuinedKing] = {
			Name = "Blade of the Ruined King",
			Type = self.EnumOffensiveType.Targeted,
			Range = 600,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Botrk",
			Menu = {}
		},
		[itemID.BilgewaterCutlass] = {
			Name = "Bilgewater Cutlass",
			Type = self.EnumOffensiveType.Targeted,
			Range = 600,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Cutlass",
			Menu = {}
		},
		[itemID.YoumuusGhostblade] = {
			Name = "Youmuus Ghostblade",
			Type = self.EnumOffensiveType.Targeted,
			Range = 600,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Youmuus",
			Menu = {}
		},
		[itemID.Tiamat] = {
			Name = "Tiamat",
			Type = self.EnumOffensiveType.Active,
			Range = 350,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Tiamat",
			Menu = {}
		},
		[itemID.RavenousHydra] = {
			Name = "Ravenous Hydra",
			Type = self.EnumOffensiveType.Active,
			Range = 350,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Ravenous",
			Menu = {}
		},
		[itemID.TitanicHydra] = {
			Name = "Titanic Hydra",
			Type = self.EnumOffensiveType.Active,
			Range = 350,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Titanic",
			Menu = {}
		},
		[itemID.HextechGLP800] = {
			Name = "Hextech GLP-800",
			Type = self.EnumOffensiveType.NonTargeted,
			Range = 1000,
			Speed = 2000,
			Delay = 0.25,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "GLP",
			Menu = {}
		},
		[itemID.HextechProtobelt01] = {
			Name = "Hextech Protobelt-01",
			Type = self.EnumOffensiveType.NonTargeted,
			Range = 400,
			Speed = 1150,
			Delay = 0,
			EnemyHealth = 80,
			MyHealth = 35,
			MenuName = "Protobelt",
			Menu = {}
		}
	}
	Activator:Menu()
end

function Activator:Menu()
	local this = self
	this.S_Menu = Menu:AddMenu("Activator", "Activator")
	TS = _G.Libs.TargetSelector(this.S_Menu)
	this.S_Menu_Offensive = this.S_Menu:AddMenu("Offensive", "Offensive")
	for k, v in pairs(this.Offensive) do
		v.Menu.Main = this.S_Menu_Offensive:AddMenu(v.MenuName, v.Name)
		v.Menu.EnemyHealth = v.Menu.Main:AddSlider(v.MenuName .. "EnemyHealth", "Enemy Health %", 0, 100, 1, v.EnemyHealth)
		v.Menu.MyHealth = v.Menu.Main:AddSlider(v.MenuName .. "MyHealth", "My Health %", 0, 100, 1, v.MyHealth)
		v.Menu.Active = v.Menu.Main:AddBool(v.MenuName .. "_Toggle", "Active " .. v.Name, true)
	end
	this.S_Menu_Focused = this.S_Menu_Offensive:AddBool("FocusedOnly", "Use items on Focused Target ONLY", true)
end

function Activator:OnTick()
	local this = self

	if (Orbwalker.GetMode() == this.EnumMode[1]) then
		local target = TS:GetTarget(1000)
		if (target == nil) then
			return
		end
		local myhealthpct = Player.Health * (1 / Player.MaxHealth) * 100
		for k, v in pairs(Player.Items) do
			local itemslot = k + 6
			local item = self.Offensive[v.ItemId]
			if (item and item.Menu.Active.Value and Player:GetSpellState(itemslot) == SpellStates.Ready) then
				local focusedT = TS:GetForcedTarget()
				target = TS:GetTarget(item.Range)
				local focusedCond = (this.S_Menu_Focused.Value and ((focusedT and focusedT == target) or (focusedT == nil))) or not this.S_Menu_Focused.Value
				if (target and focusedCond) then
					local targethealthpct = target.Health * (1 / target.MaxHealth) * 100
					if (myhealthpct <= item.Menu.MyHealth.Value or targethealthpct <= item.Menu.EnemyHealth.Value) then
						if (item.Type == this.EnumOffensiveType.Targeted) then
							Input.Cast(itemslot, target)
						elseif (item.Type == this.EnumOffensiveType.Active) then
							Input.Cast(itemslot)
						elseif (item.Type == this.EnumOffensiveType.NonTargeted) then
							-- Credit to Thron's Ashe
							local collision = Collision.SearchMinions(Player.Position, target.Position, 30, item.Speed, item.Delay * 1000, 1)
							if not collision.Result then
								Input.Cast(itemslot, target.Position)
							end
						end
					end
				end
			end
		end
	end
end

function OnTick()
	local tick = os.clock()
	if (TickCount < tick) then
		TickCount = tick + 0.3
		for i = 1, features do
			local onTick = FeaturedClasses[i].OnTick
			if (onTick ~= nil) then
				FeaturedClasses[i]:OnTick()
			end
		end
	end
end

function OnDraw()
	for i = 1, features do
		local onDraw = FeaturedClasses[i].OnDraw
		if (onDraw ~= nil) then
			FeaturedClasses[i]:OnDraw()
		end
	end
end

function OnCreate(obj)
	if (obj == nil) then
		return
	end
	for i = 1, features do
		local onCreate = FeaturedClasses[i].OnCreate
		if (onCreate ~= nil) then
			FeaturedClasses[i]:OnCreate(obj)
		end
	end
end

function OnDelete(obj)
	if (obj == nil) then
		return
	end
	for i = 1, features do
		local onDelete = FeaturedClasses[i].OnDelete
		if (onDelete ~= nil) then
			FeaturedClasses[i]:OnDelete(obj)
		end
	end
end

function OnLoad()
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnCreateObject, OnCreate)
	EventManager.RegisterCallback(Enums.Events.OnDeleteObject, OnDelete)
	for i = 1, features do
		local Init = FeaturedClasses[i].Init
		if (Init ~= nil) then
			FeaturedClasses[i]:Init()
		end
	end
	print("[E2Slayer] E2Utility is Loaded - " .. string.format("%.1f", Version))
	return true
end
