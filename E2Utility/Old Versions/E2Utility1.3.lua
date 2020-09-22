require("common.log")
module("E2Utility", package.seeall, log.setup)


local _Core = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Geometry, Renderer, Vector, Collision =
	_Core.ObjectManager,
	_Core.EventManager,
	_Core.Input,
	_Core.Enums,
	_Core.Game,
	_Core.Geometry,
	_Core.Renderer,
	_Core.Geometry.Vector,
	_G.Libs.CollisionLib
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player

-- Copied from Mista's scripts :)

-- Verision
local currentVersion = 1.3

-- Menu
local i_Menu = _G.Libs.Menu
local M_Menu = i_Menu:AddMenu("E2Utility", "E2Utility")

local BaseClass = {}
function BaseClass:OnDraw() end
function BaseClass:OnCreate(obj) end
function BaseClass:OnDelete(obj) end

local JungleTimer = {}
setmetatable(JungleTimer, {__index = BaseClass})
local CloneTracker = {}
setmetatable(CloneTracker, {__index = BaseClass})
local InhibitorsTimer = {}
setmetatable(InhibitorsTimer, {__index = BaseClass})
local DragonBaronTracker = {}
setmetatable(DragonBaronTracker, {__index = BaseClass})
local T_Classes = {JungleTimer, CloneTracker, InhibitorsTimer, DragonBaronTracker}
local TextClipper = Vector(30, 15, 0)

function JungleTimer:Init()
	-- A Bool to end Rift timer
	self.RiftOver = false

	-- [id] hashtable ID
	-- ["m_name"] Name for the menu
	-- ["position"] Position for the jungle mob
	-- ["adjustment"] A Vector to adjust the position because some of them are at the accurate position
	-- ["respawn_timer"] Respawning time
	-- ["saved_time"] GameTime + Respawning Time
	-- ["active"] Active status for the current jungle mob
	-- ["b_menu"] Menu boolean value
	self.JungleMobsData = {
		[821] = {
			["m_name"] = "Blue (West)",
			["position"] = Vector(3821.48, 51.12, 8101.05),
			["adjustment"] = Vector(0, -300, 0),
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[288] = {
			["m_name"] = "Gromp (West)",
			["position"] = Vector(2288.01, 51.77, 8448.13),
			["adjustment"] = Vector(-100, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true,
			["b_menu"] = true
		},
		[783] = {
			["m_name"] = "Wovles (West)",
			["position"] = Vector(3783.37, 52.46, 6495.56),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[61] = {
			["m_name"] = "Raptors (South)",
			["position"] = Vector(7061.5, 50.12, 5325.50),
			["adjustment"] = Vector(-100, 100, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[762] = {
			["m_name"] = "Red (South)",
			["position"] = Vector(7762.24, 53.96, 4011.18),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[394] = {
			["m_name"] = "Krugs (South)",
			["position"] = Vector(8394.76, 50.73, 2641.59),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true,
			["b_menu"] = true
		},
		[400] = {
			["m_name"] = "Scuttler (Baron)",
			["position"] = Vector(4400.00, -66.53, 9600.00),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 150,
			["saved_time"] = 195,
			["active"] = true,
			["b_menu"] = true
		},
		[500] = {
			["m_name"] = "Scuttler (Dragon)",
			["position"] = Vector(10500.00, -62.81, 5170.00),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 150,
			["saved_time"] = 195,
			["active"] = true,
			["b_menu"] = true
		},
		[866] = {
			["m_name"] = "Dragon",
			["position"] = Vector(9866.14, -71.24, 4414.01),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 300,
			["saved_time"] = 300,
			["active"] = true,
			["b_menu"] = true
		},
		[7] = {
			["m_name"] = "Baron/Rift",
			["position"] = Vector(5007.12, -71.24, 10471.44),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 360,
			["saved_time"] = 480,
			["active"] = true,
			["b_menu"] = true
		},
		[131] = {
			["m_name"] = "Blue (East)",
			["position"] = Vector(11131.72, 51.72, 6990.84),
			["adjustment"] = Vector(-100, 0, 0),
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[703] = {
			["m_name"] = "Gromp (East)",
			["position"] = Vector(12703.62, 51.69, 6443.98),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true,
			["b_menu"] = true
		},
		[59] = {
			["m_name"] = "Wovles (East)",
			["position"] = Vector(11059.76, 60.35, 8419.83),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[820] = {
			["m_name"] = "Raptors (North)",
			["position"] = Vector(7820.22, 52.19, 9644.45),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[66] = {
			["m_name"] = "Red (North)",
			["position"] = Vector(7066.86, 56.18, 10975.54),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 300,
			["saved_time"] = 90,
			["active"] = true,
			["b_menu"] = true
		},
		[499] = {
			["m_name"] = "Krugs (North)",
			["position"] = Vector(6499.49, 56.47, 12287.37),
			["adjustment"] = Vector(0, 0, 0),
			["respawn_timer"] = 120,
			["saved_time"] = 102,
			["active"] = true,
			["b_menu"] = true
		}
	}
	self.JungleTimerTable = {821, 783, 61, 762, 131, 59, 820, 66, 499, 394, 288, 703, 400, 500, 866, 7}
	JungleTimer:Menu()
end

function JungleTimer:Menu()
	-- Start Jungle Timer Menu
	self.S_Menu1 = M_Menu:AddMenu("JGT_Menu", "JungleTimer")
	self.S_Menu1_Settings = self.S_Menu1:AddMenu("JGT_Settings", "Jungle Timer Settings")
	self.S_Menu1_OnMap = self.S_Menu1_Settings:AddBool("JGT_DrawMap", "Use on the Map", true)
	self.S_Menu1_OnMapColor = self.S_Menu1_Settings:AddRGBAMenu("JGT_MapTextCol", "Timer Text on Map Color", 0x00FF00FF)
	self.S_Menu1_OnMapBackground = self.S_Menu1_Settings:AddBool("JGT_BGColT", "Use a Background Color", true)
	self.S_Menu1_OnMapBackgroundColor = self.S_Menu1_Settings:AddRGBAMenu("JGT_BGCol", "Background Color", 0x008000FF)

	self.S_Menu1_OnMinimap = self.S_Menu1_Settings:AddBool("JGT_OnMinimap", "Use on the Minimap", true)
	self.S_Menu1_OnMinimapColor = self.S_Menu1_Settings:AddRGBAMenu("JGT_MiniMapTextCol", "Timer Text on Minimap Color", 0x00FF00FF)

	self.S_Menu1_Mobs = self.S_Menu1:AddMenu("JGT_MobList", "Jungle Mobs List")
	self.S_Menu1_JTActive = self.S_Menu1:AddBool("JGT_ToggleTimer", "Activate Jungle Timer", true)
	self.S_Menu1_Label1 = self.S_Menu1:AddLabel("JGT_ExploitLabel", "An Exploit Included")

	--Add menu for the jungle mobs
	for i, hash in ipairs(self.JungleTimerTable) do
		self.JungleMobsData[hash]["b_menu"] = self.S_Menu1_Mobs:AddBool(self.JungleMobsData[hash]["m_name"], self.JungleMobsData[hash]["m_name"], true)
	end

	-- End of Jungle Menu Section
end

-- Credit to jesseadams - https://gist.github.com/jesseadams/791673
function SecondsToClock(seconds)
	local seconds = tonumber(seconds)
	if seconds <= 0 then
		return "0:00"
	else
		local hours = string.format("%02.f", math.floor(seconds / 3600))
		local mins = string.format("%01.f", math.floor(seconds / 60 - (hours * 60)))
		local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))
		return mins .. ":" .. secs
	end
end

function GetHash(arg)
	return (math.floor(arg) % 1000)
end

local function getIndex(tab, val)
	local index = nil
	for i, v in ipairs(tab) do
		if (v == val) then
			index = i
		end
	end
	return index
end

function JungleTimer:OnDraw()
	-- ForLooping only table has at least one element
	if (#self.JungleTimerTable > 0 and self.S_Menu1_JTActive.Value) then
		local currentGameTime = Game.GetTime()
		for i, hash in pairs(self.JungleTimerTable) do
			if (self.JungleMobsData[hash]["active"]) then
				local timeleft = self.JungleMobsData[hash]["saved_time"] - currentGameTime
				-- First condition for removing ended timers and the second one for removing rift timer after baron spawned.
				if (timeleft <= 0) then
					self.JungleMobsData[hash]["active"] = false
					self.JungleTimerTable[i] = nil
				else
					if (hash == 7 and currentGameTime >= 1200 and self.RiftOver == false) then
						self.RiftOver = true
						self.JungleMobsData[hash]["active"] = false
						self.JungleTimerTable[i] = nil
					else
						-- adjustment vector for correcting position for some jungle mobs
						local pos = self.JungleMobsData[hash]["position"] + self.JungleMobsData[hash]["adjustment"]
						-- convert time into m:ss format
						local time = tostring(SecondsToClock(timeleft))
						-- draw only pos is on the screen
						if (Renderer.IsOnScreen(pos)) then
							if (self.S_Menu1_OnMap.Value) then
								if (self.S_Menu1_OnMapBackground.Value) then
									Renderer.DrawFilledRect(Renderer.WorldToScreen(pos), TextClipper, 2, self.S_Menu1_OnMapBackgroundColor.Value)
								end
								Renderer.DrawText(Renderer.WorldToScreen(pos), TextClipper, time, self.S_Menu1_OnMapColor.Value)
							end
						end

						if (self.S_Menu1_OnMinimap.Value) then
							Renderer.DrawText(
								Renderer.WorldToMinimap(pos) + Vector(-10, -10, 0),
								TextClipper,
								time,
								self.S_Menu1_OnMinimapColor.Value
							)
						end
					end
				end
			end
		end
	end
end

function JungleTimer:OnCreate(obj)
	-- Jungle Timer
	if (self.S_Menu1_JTActive.Value and obj.Name == "CampRespawn") then
		delay(
			100,
			function()
				local ObjectAI = ObjManager.GetObjectByHandle(obj.Handle).AsAI
				for i = 0, ObjectAI.BuffCount do
					local buff = ObjectAI:GetBuff(i)
					if (buff and buff.Name == "camprespawncountdownhidden") then
						local hashID = GetHash(ObjectAI.Position.x)
						if (self.JungleMobsData[hashID] ~= nil) then
							self.JungleMobsData[hashID]["saved_time"] = buff.StartTime + self.JungleMobsData[hashID]["respawn_timer"] + 1
							self.JungleMobsData[hashID]["active"] = true
							local index = getIndex(self.JungleTimerTable, nil)
							if (index == nil) then
								table.insert(self.JungleTimerTable, hashID)
							else
								self.JungleTimerTable[index] = hashID
							end
						end
					end
				end
			end
		)
	end
end

function JungleTimer:OnDelete(obj)
	if (self.S_Menu1_JTActive.Value and obj.Name == "CampRespawn") then
		local hashID = GetHash(obj.AsAI.Position.x)
		if (self.JungleMobsData[hashID] ~= nil) then
			self.JungleMobsData[hashID]["saved_time"] = -1
			self.JungleMobsData[hashID]["active"] = false
			self.JungleTimerTable[hashID] = nil
		end
	end
end

function CloneTracker:Init()
	-- Clone Tracker Variables
	self.CloneEnum = {}
	self.CloneActiveCount = 0
	self.CloneAdjustment = Vector(-15, -50, 0)
	self.CloneTracker = {
		["Shaco"] = {nil, false},
		["Leblanc"] = {nil, false},
		["MonkeyKing"] = {nil, false},
		["Neeko"] = {nil, false}
	}
	self.Text = "CLONE"
	-- End of Clone Tracker Variables

	local enemyList = ObjManager.Get("enemy", "heroes")
	for handle, enemy in pairs(enemyList) do
		if (enemy ~= nil and enemy.IsAI) then
			local cloneChamp = enemy.AsAI
			if (self.CloneTracker[cloneChamp.CharName] ~= nil) then
				self.CloneTracker[cloneChamp.CharName] = {nil, true}
				table.insert(self.CloneEnum, cloneChamp.CharName)
			end
		end
	end

	CloneTracker:Menu()
end

function CloneTracker:Menu()
	-- Start Clone Tracker Menus
	self.S_Menu2 = M_Menu:AddMenu("CT_Menu", "CloneTracker")
	self.S_Menu2_Settings = self.S_Menu2:AddMenu("CT_Settings", "Clone Tracker Settings")
	self.S_Menu2_OnMap = self.S_Menu2_Settings:AddBool("CT_TrackOnMap", "Track Clones", true)
	self.S_Menu2_OnMapColor = self.S_Menu2_Settings:AddRGBAMenu("CT_MapTextCol", "Clone Tracker on Text Color", 0x000000FF)
	self.S_Menu2_OnMapBackground = self.S_Menu2_Settings:AddBool("CT_DrawBGCol", "Use a Clone Background Color", true)
	self.S_Menu2_OnMapBackgroundColor = self.S_Menu2_Settings:AddRGBAMenu("CT_BGCol", "Clone Background Color", 0xDF0101FF)
	self.S_Menu2_CTActive = self.S_Menu2:AddBool("CT_Toggle", "Activate Clone Tracker", true)
	self.S_Menu2_Label1 = self.S_Menu2:AddLabel("CT_InfoLabel", "Works on Shaco/Wukong/Leblanc/Neeko")
	-- End of Clone Tracker Section
end

function CloneTracker:OnDraw()
	if (self.S_Menu2_CTActive.Value and self.CloneActiveCount > 0 and #self.CloneEnum > 0) then
		for i, val in ipairs(self.CloneEnum) do
			if (self.CloneTracker[val][1] ~= nil and self.CloneTracker[val][2] == true) then
				if (Renderer.IsOnScreen(self.CloneTracker[val][1].Position)) then
					if (self.S_Menu2_OnMapBackground.Value) then
						Renderer.DrawFilledRect(
							Renderer.WorldToScreen(self.CloneTracker[val][1].Position) + self.CloneAdjustment,
							Vector(36, 15, 0),
							2,
							self.S_Menu2_OnMapBackgroundColor.Value
						)
					end
					if (self.S_Menu2_OnMap.Value) then
						Renderer.DrawText(
							Renderer.WorldToScreen(self.CloneTracker[val][1].Position) + self.CloneAdjustment,
							TextClipper,
							self.Text,
							self.S_Menu2_OnMapColor.Value
						)
					end
				end
			end
		end
	end
end

function CloneTracker:OnCreate(obj)
	if (self.S_Menu2_CTActive.Value and obj.IsAI) then
		local cloneChamp = obj.AsAI
		if (cloneChamp ~= nil and cloneChamp.IsValid) then
			if (self.CloneTracker[cloneChamp.CharName] ~= nil and self.CloneTracker[cloneChamp.CharName][2] == true) then
				self.CloneTracker[cloneChamp.CharName][1] = cloneChamp
				self.CloneActiveCount = self.CloneActiveCount + 1
			end
		end
	end
end

function CloneTracker:OnDelete(obj)
	if (self.S_Menu2_CTActive.Value and obj.IsAI) then
		local cloneChamp = obj.AsAI
		if (cloneChamp ~= nil and cloneChamp.IsValid) then
			if (self.CloneTracker[cloneChamp.CharName] ~= nil and self.CloneTracker[cloneChamp.CharName][2] == true) then
				self.CloneTracker[cloneChamp.CharName][1] = nil
				-- Decrease the count only greater than 0
				if (self.CloneActiveCount > 0) then
					self.CloneActiveCount = self.CloneActiveCount - 1
				end
			end
		end
	end
end

function InhibitorsTimer:Init()
	self.InhibitorsTable = {
		[171] = {IsDestroyed = false, IsAlly = true, Position = Vector(1171, 91, 3571), RespawnTime = 0.0, Name = "Ally Top"},
		[203] = {IsDestroyed = false, IsAlly = true, Position = Vector(3203, 92, 3208), RespawnTime = 0.0, Name = "Ally Mid"},
		[452] = {IsDestroyed = false, IsAlly = true, Position = Vector(3452, 89, 1236), RespawnTime = 0.0, Name = "Ally Bot"},
		[261] = {
			IsDestroyed = false,
			IsAlly = false,
			Position = Vector(11261, 88, 13676),
			RespawnTime = 0.0,
			Name = "Enemy Top"
		},
		[598] = {
			IsDestroyed = false,
			IsAlly = false,
			Position = Vector(11598, 89, 11667),
			RespawnTime = 0.0,
			Name = "Enemy Mid"
		},
		[604] = {
			IsDestroyed = false,
			IsAlly = false,
			Position = Vector(13604, 89, 11316),
			RespawnTime = 0.0,
			Name = "Enemy Bot"
		}
	}

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
	for i, obj in ipairs(inhibitorsList) do
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
	self.S_Menu = M_Menu:AddMenu("IT_Menu", "InhibitorsTimer")
	self.S_Menu_Settings = self.S_Menu:AddMenu("IT_Settings", "Inhibitors Timer Settings")
	self.S_Menu_OnMap = self.S_Menu_Settings:AddBool("IT_TimerText", "Use a Inhibitors Timer Text", true)
	self.S_Menu_OnMapColor = self.S_Menu_Settings:AddRGBAMenu("IT_TextCol", "Inhibitors Timer Text Color", 0x000000FF)
	self.S_Menu_OnMapBackground = self.S_Menu_Settings:AddBool("IT_BGToggle", "Use a Inhibitors Timer Background", true)
	self.S_Menu_OnMapBackgroundColor = self.S_Menu_Settings:AddRGBAMenu("IT_BGCol", "Inhibitors Timer Background Color", 0xDF0101FF)
	self.S_Menu_OnMinimap = self.S_Menu_Settings:AddBool("IT_MapToggle", "Use a Inhibitors Timer Minimap", false)
	self.S_Menu_OnMinimapColor = self.S_Menu_Settings:AddRGBAMenu("IT_MapCol", "Inhibitors Timer Minimap Color", 0x00FF00FF)
	-- TODO Maybe I gotta add them later
	--self.S_Menu_AllyActive = self.S_Menu:AddBool("Track Ally Inhibitors Timer", true)
	--self.S_Menu_EnemyActive = self.S_Menu:AddBool("Track Enemy Inhibitors Timer", true)
	self.S_Menu_Active = self.S_Menu:AddBool("IT_Toggle", "Activate Inhibitors Timer", true)
end

function InhibitorsTimer:OnDelete(obj)
	local objName = obj.Name
	if (not obj.IsAttackbleUnit and not obj.IsValid and not self.S_Menu_Active.Value and not objName) then
		return
	end

	local hash = GetHash(obj.Position.x)
	if (self.DestroyComparor[objName]) then
		self.InhibitorsTable[hash].IsDestroyed = true
		self.InhibitorsTable[hash].RespawnTime = Game:GetTime() + self.ConstRespawnTime
		self.DestroyedInhibitors = self.DestroyedInhibitors + 1
	else
		if (self.SpawnComparor[objName]) then
			self.InhibitorsTable[hash].IsDestroyed = false
			self.InhibitorsTable[hash].RespawnTime = 0.0
			if( self.DestroyedInhibitors > 0) then
				self.DestroyedInhibitors = self.DestroyedInhibitors - 1
			end
		end
	end
end

function InhibitorsTimer:OnDraw()
	if (self.S_Menu_Active.Value and self.DestroyedInhibitors > 0) then
		for k, v in pairs(self.InhibitorsTable) do
			if (self.InhibitorsTable[k].IsDestroyed) then
				local time = self.InhibitorsTable[k].RespawnTime - Game.GetTime()
				local timeleft = tostring(SecondsToClock(time))
				if (time <= 0) then
					self.InhibitorsTable[k].IsDestroyed = false
					self.InhibitorsTable[k].RespawnTime = 0.0
					if( self.DestroyedInhibitors > 0) then
						self.DestroyedInhibitors = self.DestroyedInhibitors - 1
					end
				else
					local pos = self.InhibitorsTable[k].Position
					--draw only pos is on the screen
					if (Renderer.IsOnScreen(pos)) then
						if (self.S_Menu_OnMap.Value) then
							if (self.S_Menu_OnMapBackground.Value) then
								Renderer.DrawFilledRect(Renderer.WorldToScreen(pos), TextClipper, 2, self.S_Menu_OnMapBackgroundColor.Value)
							end
							Renderer.DrawText(Renderer.WorldToScreen(pos), TextClipper, timeleft, self.S_Menu_OnMapColor.Value)
						end
					end

					if (self.S_Menu_OnMinimap.Value) then
						Renderer.DrawText(
							Renderer.WorldToMinimap(pos) + Vector(-15, -10, 0),
							TextClipper,
							timeleft,
							self.S_Menu_OnMinimapColor.Value
						)
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

	self.DragonBaronStatus = {2, 2}
	local playerResolution = Renderer.GetResolution()
	self.AlertPosition = Vector(math.floor(playerResolution.x) / 2.0 - 80.0, math.floor(playerResolution.y) / 6.0, 0)
	self.AlertRectPosition = self.AlertPosition - Vector(15, 0, 0)
	self.BaronAlertPosition = self.AlertPosition - Vector(0, 20, 0)
	self.BaronRectAlertPosition = self.BaronAlertPosition - Vector(15, 0, 0)
	self.BaronActiveStatus = Game.GetTime()
	self.TextClipper = Vector(200, 15, 0)

	DragonBaronTracker:Menu()
	
end

function DragonBaronTracker:Menu()
	self.S_Menu = M_Menu:AddMenu("DBTracker", "DragonBaronTracker")
	self.S_Menu_Settings = self.S_Menu:AddMenu("DBT_Settings", "Dragon Baron Tracker Settings")
	self.S_Menu_Dragon = self.S_Menu_Settings:AddBool("DBT_DragonToggle", "Track Dragon", true)
	self.S_Menu_DragonColor = self.S_Menu_Settings:AddRGBAMenu("DBT_DragonTextCol", "Dragon Tracker Text Color", 0x000000FF)
	self.S_Menu_DragonBackground = self.S_Menu_Settings:AddBool("DBT_DragonBGToggle", "Use a Dragon Tracker Background", true)
	self.S_Menu_DragonBackgroundColor = self.S_Menu_Settings:AddRGBAMenu("DBT_DragonBGCol", "Dragon Tracker Background Color", 0xCC6600FF)

	self.S_Menu_Baron = self.S_Menu_Settings:AddBool("DBT_BaronToggle", "Track Baron", true)
	self.S_Menu_BaronColor = self.S_Menu_Settings:AddRGBAMenu("DBT_BaronTextCol", "Baron Tracker Text Color", 0x000000FF)
	self.S_Menu_BaronBackground = self.S_Menu_Settings:AddBool("DBT_BaronBGToggle", "Use a Baron Tracker Background", true)
	self.S_Menu_BaronBackgroundColor = self.S_Menu_Settings:AddRGBAMenu("DBT_BaronBGCol", "Baron Tracker Background Color", 0x990099FF)

	self.S_Menu_Active = self.S_Menu:AddBool("DBT_Toggle", "Activate Dragon Baron Tracker", true)
	self.S_Menu_Label1 = self.S_Menu:AddLabel("DBT_ExploitLabel", "The Exploit Works on Fog of War")

end

function DragonBaronTracker:OnDelete(obj)
	if (self.S_Menu_Active.Value and obj) then
		local objName = obj.Name
		if (objName and self.DragonBaronTable[objName]) then
			self.DragonBaronStatus[self.DragonBaronTable[objName].IsDragon] = self.DragonBaronTable[objName].IsAttacking
			-- only baron
			if (self.DragonBaronTable[objName].IsDragon == 2 and self.DragonBaronTable[objName].IsAttacking ~= 3) then
				self.BaronActiveStatus = Game.GetTime() + 2
				delay(
					3000,
					function()
						if (Game.GetTime() >= self.BaronActiveStatus) then
							self.DragonBaronStatus[self.DragonBaronTable[objName].IsDragon] = 2
						end
					end
				)
			end
		end
	end
end

function DragonBaronTracker:OnDraw()

	if( not self.S_Menu_Active.Value ) then
		return
	end

	-- Maybe I can reduce below lines later..
	if (self.S_Menu_Dragon.Value and self.DragonBaronStatus[1] == 1) then
		Renderer.DrawFilledRect(self.AlertRectPosition, self.TextClipper, 2, self.S_Menu_DragonBackgroundColor.Value)
		Renderer.DrawText(self.AlertPosition, self.TextClipper, "DRAGON IS BEING ATTACKED", self.S_Menu_DragonColor.Value)
	end

	if (self.S_Menu_Baron.Value and self.DragonBaronStatus[2] == 1) then
		Renderer.DrawFilledRect(self.BaronRectAlertPosition, self.TextClipper, 2, self.S_Menu_BaronBackgroundColor.Value)
		Renderer.DrawText(self.BaronAlertPosition, self.TextClipper, "BARON IS BEING ATTACKED", self.S_Menu_BaronColor.Value)
	end
end



function OnDraw()
	for i, class in ipairs(T_Classes) do
		class:OnDraw()
	end
end

function OnCreate(obj)
	if (obj == nil) then
		return
	end

	for i, class in ipairs(T_Classes) do
		class:OnCreate(obj)
	end
end

function OnDelete(obj)
	if (obj == nil) then
		return
	end

	for i, class in ipairs(T_Classes) do
		class:OnDelete(obj)
	end
end

function OnLoad()
	--EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnCreateObject, OnCreate)
	EventManager.RegisterCallback(Enums.Events.OnDeleteObject, OnDelete)

	for i, class in ipairs(T_Classes) do
		class:Init()
	end

	-- GamePrint Chat
	Game.PrintChat(
		'<font color="#A4A4A4">[E2Slayer]</font> <font color="#5882FA">E2Utility</font><font color="#FFFFFF"> is Loaded - ' ..
			string.format("%.1f", currentVersion) .. "</font>"
	)
	return true
end