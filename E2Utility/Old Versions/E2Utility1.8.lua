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

local OSClock = os.clock
local floor = math.floor
local format = string.format

-- Copied from Mista's scripts :)

-- Verision
local Version = 1.8

local Profiler = _G.Libs.Profiler

-- Menu
local Menu = _G.Libs.Menu:AddMenu("E2Utility", "E2Utility")
local JungleTimer = {}
local CloneTracker = {}
local InhibitorsTimer = {}
local DragonBaronTracker = {}
local CooldownTracker = {}
local Activator = {}
local TS = {}
local TurnAround = {}
local TowerRanges = {}
local PathTracker = {}
local BlockMinion = {}

local FeaturedClasses = {
	JungleTimer,
	CloneTracker,
	InhibitorsTimer,
	DragonBaronTracker,
	CooldownTracker,
	Activator,
	TurnAround,
	TowerRanges,
	PathTracker,
	BlockMinion
}
local TextClipper = Vector(30, 15, 0)
local TickCount = 0

---@param arg number(float)
---@return number 
local function GetHash(arg)
	return (floor(arg) % 1000)
end

-- Credit to jesseadams - https://gist.github.com/jesseadams/791673
---@param seconds number(float)
---@return string 
local function SecondsToClock(seconds)
	if seconds <= 0 then
		local default = "0:00"
		return default
	else
		local hours = floor(seconds * 0.00027777777) -- 1/3600
		local mins = format("%01.f", floor(seconds * 0.01666666666 - (hours * 60))) -- 1/60
		local secs = format("%02.f", floor(seconds - hours * 3600 - mins * 60))
		local str = mins .. ":" .. secs
		return str
	end
end

--[[
		██ ██    ██ ███    ██  ██████  ██      ███████     ████████ ██ ███    ███ ███████ ██████  
		██ ██    ██ ████   ██ ██       ██      ██             ██    ██ ████  ████ ██      ██   ██ 
		██ ██    ██ ██ ██  ██ ██   ███ ██      █████          ██    ██ ██ ████ ██ █████   ██████  
   ██   ██ ██    ██ ██  ██ ██ ██    ██ ██      ██             ██    ██ ██  ██  ██ ██      ██   ██ 
    █████   ██████  ██   ████  ██████  ███████ ███████        ██    ██ ██      ██ ███████ ██   ██                                                                                                                                                                                          
]]

function JungleTimer:Init()
	-- A Bool to end Rift timer
	self.RiftOver = false
	self.TotalCamps = 16
	self.ObjName = { ["CampRespawn"] = true }
	self.ObjBuffName = { ["camprespawncountdownhidden"] = true}
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
	JungleTimer.Menu = Menu:AddMenu("JGT_Menu", "JungleTimer")
	JungleTimer.Menu:AddMenu("JGT_Settings", "Jungle Timer Settings")
	JungleTimer.Menu.JGT_Settings:AddBool("JGT_DrawMap", "Use on the Map", true)
	JungleTimer.Menu.JGT_Settings:AddRGBAMenu("JGT_MapTextCol", "Timer Text on Map Color", 0x00FF00FF)
	JungleTimer.Menu.JGT_Settings:AddBool("JGT_BGColT", "Use a Background Color", true)
	JungleTimer.Menu.JGT_Settings:AddRGBAMenu("JGT_BGCol", "Background Color", 0x008000FF)
	JungleTimer.Menu.JGT_Settings:AddBool("JGT_OnMinimap", "Use on the Minimap", true)
	JungleTimer.Menu.JGT_Settings:AddRGBAMenu("JGT_MiniMapTextCol", "Timer Text on Minimap Color", 0x00FF00FF)
	JungleTimer.Menu:AddBool("JGT_ToggleTimer", "Activate Jungle Timer", true)
	JungleTimer.Menu:AddLabel("JGT_ExplainLabel", "A Unique Feature Included")
	JungleTimer.Menu:AddLabel("JGT_ExplainLabel2", "Read the forum for the details")
end

function JungleTimer:OnDraw()
	-- ForLooping only table has at least one element
	local menu = JungleTimer.Menu
	if (menu.JGT_ToggleTimer.Value and #self.JungleTimerTable > 0 ) then
		local currentGameTime = Game:GetTime()
		local totalCamps = self.TotalCamps
		local JungleMobsData = self.JungleMobsData
		menu = JungleTimer.Menu.JGT_Settings
		for i = 1, totalCamps do
			local hash = self.JungleTimerTable[i]
			if (JungleMobsData[hash]["active"]) then
				local timeleft = JungleMobsData[hash]["saved_time"] - currentGameTime
				-- First condition for removing ended timers and the second one for removing rift timer after baron spawned.
				if (timeleft <= 0) then
					JungleMobsData[hash]["active"] = false
				else
					if (hash == 7 and currentGameTime >= 1200 and self.RiftOver == false) then
						self.RiftOver = true
						JungleMobsData[hash]["active"] = false
					else
						-- adjustment vector for correcting position for some jungle mobs
						local pos = JungleMobsData[hash]["position"] + JungleMobsData[hash]["adjustment"]
						-- convert time into m:ss format
						local time = SecondsToClock(timeleft)
						-- draw only pos is on the screen
						if (Renderer.IsOnScreen(pos)) then
							local worldPos = Renderer.WorldToScreen(pos)
							if (menu.JGT_DrawMap.Value) then
								if (menu.JGT_BGColT.Value) then
									Renderer.DrawFilledRect(worldPos, TextClipper, 2, menu.JGT_BGCol.Value)
								end
								Renderer.DrawText(worldPos, TextClipper, time, menu.JGT_MapTextCol.Value)
							end
						end
						if (menu.JGT_OnMinimap.Value) then
							local miniPos = Renderer.WorldToMinimap(pos) + Vector(-10, -10, 0)
							Renderer.DrawText(miniPos, TextClipper, time, menu.JGT_MiniMapTextCol.Value)
						end
					end
				end
			end
		end
	end
end

local function TimerStarter(t, objHandle)
	local ObjectAI = ObjManager.GetObjectByHandle(objHandle).AsAI
	if (ObjectAI) then
		local JungleMobsData = JungleTimer.JungleMobsData
		local objBuffCount = ObjectAI.BuffCount
		for i = 0, objBuffCount do
			local buff = ObjectAI:GetBuff(i)
			if (buff) then
				local buffName = buff.Name
				if (JungleTimer.ObjBuffName[buffName] ) then
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

function JungleTimer:OnCreate(obj)
	-- Jungle Timer
	local menu = JungleTimer.Menu
	if (menu.JGT_ToggleTimer.Value and self.ObjName[obj.Name]) then
		delay(100, TimerStarter, self, obj.Handle)
	end
end

function JungleTimer:OnDelete(obj)
	local menu = JungleTimer.Menu
	if (menu.JGT_ToggleTimer.Value and self.ObjName[obj.Name]) then
		local hashID = GetHash(obj.AsAI.Position.x)
		local target = self.JungleMobsData[hashID]
		if (target) then
			target["saved_time"] = -1
			target["active"] = false
		end
	end
end


--[[
	 ██████ ██       ██████  ███    ██ ███████     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
	██      ██      ██    ██ ████   ██ ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	██      ██      ██    ██ ██ ██  ██ █████          ██    ██████  ███████ ██      █████   █████   ██████  
	██      ██      ██    ██ ██  ██ ██ ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	 ██████ ███████  ██████  ██   ████ ███████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                                                                                                                                                                                                                                                      
]]

function CloneTracker:Init()
	-- Clone Tracker Variables
	self.CloneEnum = {}
	self.CloneEnumCount = 1
	self.CloneActiveCount = 0
	self.CloneAdjustment = Vector(-15, -50, 0)
	local tableTemplate = {nil, false}
	self.CloneTrackerList = {
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
			if (self.CloneTrackerList[charName]) then
				self.CloneTrackerList[charName] = template
				self.CloneEnum[self.CloneEnumCount] = charName
				self.CloneEnumCount = self.CloneEnumCount + 1
			end
		end
	end

	if (self.CloneEnumCount < 1) then
		CloneTracker.OnDraw = nil
		CloneTracker.OnCreate = nil
		CloneTracker.OnDelete = nil
		self.CloneEnum = nil
		self.CloneEnumCount = nil
		self.CloneActiveCount = nil
		self.CloneAdjustment = nil
		self.CloneTrackerList = nil
		self.Text = nil
		self.TextRectVec = nil
	end

	CloneTracker:Menu()
end

function CloneTracker:Menu()
	-- Start Clone Tracker Menus
	CloneTracker.Menu = Menu:AddMenu("CT_Menu", "CloneTracker")
	CloneTracker.Menu:AddMenu("CT_Settings", "CloneTracker")
	CloneTracker.Menu.CT_Settings:AddBool("CT_TrackOnMap", "Track Clones", true)
	CloneTracker.Menu.CT_Settings:AddRGBAMenu("CT_MapTextCol", "Clone Tracker on Text Color", 0x000000FF)
	CloneTracker.Menu.CT_Settings:AddBool("CT_DrawBGCol", "Use a Clone Background Color", true)
	CloneTracker.Menu.CT_Settings:AddRGBAMenu("CT_BGCol", "Clone Background Color", 0xDF0101FF)
	CloneTracker.Menu:AddBool("CT_Toggle", "Activate Clone Tracker", true)
	CloneTracker.Menu:AddLabel("CT_InfoLabel", "Works on Shaco/Wukong/Leblanc/Neeko")
	-- End of Clone Tracker Section
end

function CloneTracker:OnDraw()
	local menu = CloneTracker.Menu
	if (menu.CT_Toggle.Value and self.CloneActiveCount > 0) then
		local enumCount = self.CloneEnumCount - 1
		local cloneTracker = self.CloneTrackerList
		for i = 1, enumCount do
			local charName = self.CloneEnum[i]
			if (cloneTracker[charName][1] and cloneTracker[charName][2] == true) then
				local pos = cloneTracker[charName][1].Position
				menu = CloneTracker.Menu.CT_Settings
				if (Renderer.IsOnScreen(pos)) then
					local posw2s = Renderer.WorldToScreen(pos) + self.CloneAdjustment
					if (menu.CT_DrawBGCol.Value) then
						Renderer.DrawFilledRect(posw2s, self.TextRectVec, 2, menu.CT_BGCol.Value)
					end
					if (menu.CT_TrackOnMap.Value) then
						Renderer.DrawText(posw2s, TextClipper, self.Text, menu.CT_MapTextCol.Value)
					end
				end
			end
		end
	end
end

function CloneTracker:OnCreate(obj)
	local menu = CloneTracker.Menu
	if (menu.CT_Toggle.Value and obj.IsAI) then
		local cloneChamp = obj.AsAI
		if (cloneChamp ~= nil and cloneChamp.IsValid) then
			local cloneTracker = self.CloneTrackerList
			local charName = cloneChamp.CharName
			if (cloneTracker[charName] and cloneTracker[charName][2] == true) then
				cloneTracker[charName][1] = cloneChamp
				self.CloneActiveCount = self.CloneActiveCount + 1
			end
		end
	end
end

function CloneTracker:OnDelete(obj)
	local menu = CloneTracker.Menu
	if (menu.CT_Toggle.Value and obj.IsAI) then
		local cloneChamp = obj.AsAI
		if (cloneChamp and cloneChamp.IsValid) then
			local cloneTracker = self.CloneTrackerList
			local charName = cloneChamp.CharName
			if (cloneTracker[charName] and cloneTracker[charName][2] == true) then
				cloneTracker[charName][1] = nil
				-- Decrease the count only greater than 0
				local activeCount = self.CloneActiveCount
				if (activeCount > 0) then
					self.CloneActiveCount = activeCount - 1
				end
			end
		end
	end
end


--[[
	██ ███    ██ ██   ██ ██ ██████  ██ ████████  ██████  ██████  ███████     ████████ ██ ███    ███ ███████ ██████  
	██ ████   ██ ██   ██ ██ ██   ██ ██    ██    ██    ██ ██   ██ ██             ██    ██ ████  ████ ██      ██   ██ 
	██ ██ ██  ██ ███████ ██ ██████  ██    ██    ██    ██ ██████  ███████        ██    ██ ██ ████ ██ █████   ██████  
	██ ██  ██ ██ ██   ██ ██ ██   ██ ██    ██    ██    ██ ██   ██      ██        ██    ██ ██  ██  ██ ██      ██   ██ 
	██ ██   ████ ██   ██ ██ ██████  ██    ██     ██████  ██   ██ ███████        ██    ██ ██      ██ ███████ ██   ██                                                                                                                                                                                                                                                                                                                                                                                                     
]]

function InhibitorsTimer:Init()
	self.InhibitorsTable = {
		-- Blue Top, Mid, Bot
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
		-- Red Top, Mid, Bot
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

	self.RespawnComparor = {
		["SRUAP_Chaos_Inhibitor_Spawn_sound.troy"] = {Destroy = false},
		["SRUAP_Order_Inhibitor_Spawn_sound.troy"] = {Destroy = false},
		["SRUAP_Chaos_Inhibitor_Idle1_soundy.troy"] = {Destroy = true},
		["SRUAP_Order_Inhibitor_Idle1_sound.troy"] = {Destroy = true}
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
	InhibitorsTimer.Menu = Menu:AddMenu("IT_Menu", "InhibitorsTimer")
	InhibitorsTimer.Menu:AddMenu("IT_Settings", "Inhibitors Timer Settings")
	InhibitorsTimer.Menu.IT_Settings:AddBool("IT_TimerText", "Use a Inhibitors Timer Text", true)
	InhibitorsTimer.Menu.IT_Settings:AddRGBAMenu("IT_TextCol", "Inhibitors Timer Text Color", 0x000000FF)
	InhibitorsTimer.Menu.IT_Settings:AddBool("IT_BGToggle", "Use a Inhibitors Timer Background", true)
	InhibitorsTimer.Menu.IT_Settings:AddRGBAMenu("IT_BGCol", "Inhibitors Timer Background Color", 0xDF0101FF)
	InhibitorsTimer.Menu.IT_Settings:AddBool("IT_MapToggle", "Use a Inhibitors Timer Minimap", false)
	InhibitorsTimer.Menu.IT_Settings:AddRGBAMenu("IT_MapCol", "Inhibitors Timer Minimap Color", 0x00FF00FF)
	InhibitorsTimer.Menu:AddBool("IT_Toggle", "Activate Inhibitors Timer", true)
end

function InhibitorsTimer:OnDelete(obj)
	local comparor = self.RespawnComparor[obj.Name]
	if (InhibitorsTimer.Menu.IT_Toggle.Value and comparor) then
		local hash = GetHash(obj.Position.x)
		local InhibitorsTable = self.InhibitorsTable[hash]
		if (InhibitorsTable) then
			if (comparor.Destroy) then
				InhibitorsTable.IsDestroyed = true
				local respawnTime = OSClock() + self.ConstRespawnTime
				InhibitorsTable.RespawnTime = respawnTime
				self.DestroyedInhibitors = self.DestroyedInhibitors + 1
			else
				InhibitorsTable.IsDestroyed = false
				InhibitorsTable.RespawnTime = 0.0
				if (self.DestroyedInhibitors > 0) then
					self.DestroyedInhibitors = self.DestroyedInhibitors - 1
				end
			end
		end
	end
end

function InhibitorsTimer:OnDraw()
	local menu = InhibitorsTimer.Menu
	if (menu.IT_Toggle.Value and self.DestroyedInhibitors > 0) then
		for i = 1, self.Inhibitors do
			local index = self.InhibitorsEnum[i]
			if (self.InhibitorsTable[index].IsDestroyed) then
				local time = self.InhibitorsTable[index].RespawnTime - OSClock()
				local timeleft = SecondsToClock(time)
				if (time <= 0) then
					self.InhibitorsTable[index].IsDestroyed = false
					self.InhibitorsTable[index].RespawnTime = 0.0
					if (self.DestroyedInhibitors > 0) then
						self.DestroyedInhibitors = self.DestroyedInhibitors - 1
					end
				else
					local pos = self.InhibitorsTable[index].Position
					local posw2s = Renderer.WorldToScreen(pos)
					local posw2m = Renderer.WorldToMinimap(pos) + Vector(-15, -10, 0)
					menu = InhibitorsTimer.Menu.IT_Settings
					--draw only pos is on the screen
					if (Renderer.IsOnScreen(pos)) then
						if (menu.IT_TimerText.Value) then
							if (menu.IT_BGToggle.Value) then
								Renderer.DrawFilledRect(posw2s, TextClipper, 2, menu.IT_BGCol.Value)
							end
							Renderer.DrawText(posw2s, TextClipper, timeleft, menu.IT_TextCol.Value)
						end
					end

					if (menu.IT_MapToggle.Value) then
						Renderer.DrawText(posw2m, TextClipper, timeleft, menu.IT_MapCol.Value)
					end
				end
			end
		end
	end
end

--[[
	██████  ██████   █████   ██████   ██████  ███    ██ ██████   █████  ██████   ██████  ███    ██     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
	██   ██ ██   ██ ██   ██ ██       ██    ██ ████   ██ ██   ██ ██   ██ ██   ██ ██    ██ ████   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	██   ██ ██████  ███████ ██   ███ ██    ██ ██ ██  ██ ██████  ███████ ██████  ██    ██ ██ ██  ██        ██    ██████  ███████ ██      █████   █████   ██████  
	██   ██ ██   ██ ██   ██ ██    ██ ██    ██ ██  ██ ██ ██   ██ ██   ██ ██   ██ ██    ██ ██  ██ ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	██████  ██   ██ ██   ██  ██████   ██████  ██   ████ ██████  ██   ██ ██   ██  ██████  ██   ████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                                                                                                                                                                                                                                                     
]]

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
	self.DragonMessage = "DRAGON IS UNDER ATTACK"
	self.BaronMessage = "BARON IS UNDER ATTACK"
	self.DragonBaronStatus = {2, 2}
	local playerResolution = Renderer.GetResolution()
	self.AlertPosition = Vector(floor(playerResolution.x) * 0.5 - 80.0, floor(playerResolution.y) * 0.16666666666, 0)
	self.AlertRectPosition = Vector(self.AlertPosition.x - 15, self.AlertPosition.y, self.AlertPosition.z)
	self.BaronAlertPosition = Vector(self.AlertPosition.x, self.AlertPosition.y - 20, self.AlertPosition.z)
	self.BaronRectAlertPosition =
		Vector(self.BaronAlertPosition.x - 15, self.BaronAlertPosition.y, self.BaronAlertPosition.z)
	self.BaronActiveStatus = 0
	self.TextClipper = Vector(200, 15, 0)

	DragonBaronTracker:Menu()
end

function DragonBaronTracker:Menu()
	DragonBaronTracker.Menu = Menu:AddMenu("DBTracker", "DragonBaronTracker")
	DragonBaronTracker.Menu:AddMenu("DBT_Settings", "Dragon Baron Tracker Settings")
	DragonBaronTracker.Menu.DBT_Settings:AddBool("DBT_DragonToggle", "Track Dragon", true)
	DragonBaronTracker.Menu.DBT_Settings:AddRGBAMenu("DBT_DragonTextCol", "Dragon Tracker Text Color", 0x000000FF)
	DragonBaronTracker.Menu.DBT_Settings:AddRGBAMenu("DBT_DragonBGCol", "Dragon Tracker Background Color", 0xCC6600FF)
	DragonBaronTracker.Menu.DBT_Settings:AddBool("DBT_BaronToggle", "Track Baron", true)
	DragonBaronTracker.Menu.DBT_Settings:AddRGBAMenu("DBT_BaronTextCol", "Baron Tracker Text Color", 0x000000FF)
	DragonBaronTracker.Menu.DBT_Settings:AddRGBAMenu("DBT_BaronBGCol", "Baron Tracker Background Color", 0x990099FF)
	DragonBaronTracker.Menu:AddBool("DBT_Toggle", "Activate Dragon Baron Tracker", true)
	DragonBaronTracker.Menu:AddLabel("DBT_ExploitLabel", "The Exploit Works on Fog of War")
end

local function IsBaronAttacking()
	local time = OSClock()
	if (time >= DragonBaronTracker.BaronActiveStatus) then
		DragonBaronTracker.DragonBaronStatus[2] = 2
	end
end

function DragonBaronTracker:OnDelete(obj)
	local menu = DragonBaronTracker.Menu
	if (menu.DBT_Toggle.Value) then
		local DragonBaronTable = self.DragonBaronTable[obj.Name]
		if (DragonBaronTable) then
			self.DragonBaronStatus[DragonBaronTable.IsDragon] = DragonBaronTable.IsAttacking
			-- only baron
			if (DragonBaronTable.IsDragon == 2 and DragonBaronTable.IsAttacking ~= 3) then
				local time = OSClock()
				self.BaronActiveStatus = time + 2.0
				delay(3000, IsBaronAttacking)
			end
		end
	end
end

function DragonBaronTracker:OnDraw()
	local menu = DragonBaronTracker.Menu
	if (menu.DBT_Toggle.Value) then
		menu = DragonBaronTracker.Menu.DBT_Settings
		-- Maybe I can reduce below lines later..
		if (menu.DBT_DragonToggle.Value and self.DragonBaronStatus[1] == 1) then
			Renderer.DrawFilledRect(self.AlertRectPosition, self.TextClipper, 2, menu.DBT_DragonBGCol.Value)
			Renderer.DrawText(self.AlertPosition, self.TextClipper, self.DragonMessage, menu.DBT_DragonTextCol.Value)
		end

		if (menu.DBT_BaronToggle.Value and self.DragonBaronStatus[2] == 1) then
			Renderer.DrawFilledRect(self.BaronRectAlertPosition, self.TextClipper, 2, menu.DBT_BaronBGCol.Value)
			Renderer.DrawText(self.BaronAlertPosition, self.TextClipper, self.BaronMessage, menu.DBT_BaronTextCol.Value)
		end
	end
end

--[[
	 ██████  ██████   ██████  ██      ██████   ██████  ██     ██ ███    ██     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
	██      ██    ██ ██    ██ ██      ██   ██ ██    ██ ██     ██ ████   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	██      ██    ██ ██    ██ ██      ██   ██ ██    ██ ██  █  ██ ██ ██  ██        ██    ██████  ███████ ██      █████   █████   ██████  
	██      ██    ██ ██    ██ ██      ██   ██ ██    ██ ██ ███ ██ ██  ██ ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	 ██████  ██████   ██████  ███████ ██████   ██████   ███ ███  ██   ████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                                                                                                                   
]]

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
		["Pantheon"] = {1, Vector(0, 10, 0)},
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
	CooldownTracker.Menu = Menu:AddMenu("CDTracker", "CooldownTracker")
	CooldownTracker.Menu:AddMenu("CDTracker_Settings", "Cooldown Tracker Settings")
	CooldownTracker.Menu.CDTracker_Settings:AddBool("CDTracker_TrackMe", "Track Me", true)
	CooldownTracker.Menu.CDTracker_Settings:AddBool("CDTracker_TrackAlly", "Track Ally", true)
	CooldownTracker.Menu.CDTracker_Settings:AddBool("CDTracker_TrackEnemy", "Track Enemy", true)
	CooldownTracker.Menu.CDTracker_Settings:AddBool("CDTracker_Adjustment", "Adjust CDTracker Position", true)
	CooldownTracker.Menu.CDTracker_Settings:AddLabel("CDTracker_AdjustmentLabel", "^- EX) Annie, Jhin, Zoey...", true)
	CooldownTracker.Menu:AddBool("CDTracker_Toggle", "Activate Cooldown Tracker", true)
end

local function CDCondition(objHero)
	local menu = CooldownTracker.Menu.CDTracker_Settings
	return (objHero.IsMe and menu.CDTracker_TrackMe.Value) or
		(objHero.IsAlly and not objHero.IsMe and menu.CDTracker_TrackAlly.Value) or
		(objHero.IsEnemy and menu.CDTracker_TrackEnemy.Value)
end

function CooldownTracker:OnTick()
	local menu = CooldownTracker.Menu
	if (menu.CDTracker_Toggle.Value) then
		local Heroes = self.Heroes
		local maxHeroes = self.count
		local IsOnScreen = Renderer.IsOnScreen
		for h = 1, maxHeroes do
			local objHero = Heroes[h][2].AsHero
			if (objHero.IsVisible and not objHero.IsDead and IsOnScreen(objHero.Position)) then
				if (CDCondition(objHero)) then
					for i = SpellSlots.Q, SpellSlots.R do
						local copySpell = Heroes[h][1]

						if (copySpell[i].Spell.IsLearned) then
							copySpell[i].IsLearned = true
							local cd = copySpell[i].Spell.RemainingCooldown
							local tcd = copySpell[i].Spell.TotalCooldown
							copySpell[i].RemainingCooldown = cd
							-- Got from 48656c6c636174
							local pct = floor((25 * cd / tcd))

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
							--copySpell[i].Spell = t_spell
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
	local menu = CooldownTracker.Menu
	if (menu.CDTracker_Toggle.Value) then
		local IsOnScreen2D = Renderer.IsOnScreen2D
		local Heroes = self.Heroes
		local maxHeroes = self.count

		for h = 1, maxHeroes do
			local objHero = Heroes[h][2].AsHero
			local adjustment = Heroes[h][3]
			local hpPos = objHero.HealthBarScreenPos

			if (objHero and objHero.IsValid and objHero.IsVisible and not objHero.IsDead and IsOnScreen2D(hpPos)) then
				local cond = CDCondition(objHero)
				if (cond) then
					if (adjustment[1] == 1 and menu.CDTracker_Settings.CDTracker_Adjustment.Value) then
						hpPos = hpPos + adjustment[2]
					end
					Renderer.DrawFilledRect(
						Vector(hpPos.x - 45, hpPos.y - 2, 0),
						self.SpellBackground,
						2,
						self.ColorList[self.EnumColor.NotLearned]
					)
					local SpellBoxVector = self.SpellBoxVector
					for i = SpellSlots.Q, SpellSlots.R do
						local copySpell = Heroes[h][1]

						local color = self.ColorList[copySpell[i].Color]
						local color2 = self.ColorList[copySpell[i].Color2]
						local pos = hpPos + Vector(26 * i - 45, -2, 0)
						if (color and color2) then
							if (copySpell[i].RemainingCooldown > 0) then
								local pctPos = Vector(26 - copySpell[i].PctCooldown, 5, 0)
								Renderer.DrawFilledRect(pos, pctPos, 1, color2)
								Renderer.DrawRectOutline(pos, SpellBoxVector, 2, 2, self.BoxOutline)
								pos = Vector(pos.x + 4, pos.y + 7, 0)
								Renderer.DrawText(pos, TextClipper, format(self.StringFormat, copySpell[i].RemainingCooldown), self.TextColor)
							else
								Renderer.DrawFilledRect(pos, SpellBoxVector, 2, color)
								Renderer.DrawRectOutline(pos, SpellBoxVector, 2, 2, self.BoxOutline)
							end
						end
					end

					local ssBox = self.SSBoxVector
					hpPos = objHero.HealthBarScreenPos
					if (adjustment[1] == 2 and self.S_Menu_Adjust.Value) then
						hpPos = hpPos + adjustment[2]
					end

					for i = SpellSlots.Summoner1, SpellSlots.Summoner2 do
						local copySpell = Heroes[h][1]
						local pos = Vector(hpPos.x + 65, 13 * (i - 1) + hpPos.y - 65, 0)
						if (copySpell) then
							local posText = Vector(hpPos.x + 70, 13 * (i - 1) + hpPos.y - 65, 0)
							if (copySpell[i].RemainingCooldown > 0) then
								Renderer.DrawFilledRect(pos, ssBox, 2, self.SummonerSpellsStructure[copySpell[i].Name].CDColor)
								Renderer.DrawText(posText, TextClipper, format(self.StringFormat, copySpell[i].RemainingCooldown), self.TextColorBlack)
							else
								Renderer.DrawFilledRect(pos, ssBox, 2, self.SummonerSpellsStructure[copySpell[i].Name].Color)
							end
						end
						Renderer.DrawRectOutline(pos, ssBox, 2, 2, self.BoxOutline)
					end
				end
			end
		end
	end
end

--[[
	 █████   ██████ ████████ ██ ██    ██  █████  ████████  ██████  ██████  
	██   ██ ██         ██    ██ ██    ██ ██   ██    ██    ██    ██ ██   ██ 
	███████ ██         ██    ██ ██    ██ ███████    ██    ██    ██ ██████  
	██   ██ ██         ██    ██  ██  ██  ██   ██    ██    ██    ██ ██   ██ 
	██   ██  ██████    ██    ██   ████   ██   ██    ██     ██████  ██   ██                                                                                                                                                                                                                                                                                                                                      
]]

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
	Activator.Menu = Menu:AddMenu("Activator", "Activator")
	TS = _G.Libs.TargetSelector(Activator.Menu)
	Activator.Menu:AddMenu("Offensive", "Offensive")
	for k, v in pairs(self.Offensive) do
		local menuName = v.MenuName
		Activator.Menu.Offensive:AddMenu(menuName, v.Name)
		v.Menu.EnemyHealth = Activator.Menu.Offensive[menuName]:AddSlider(menuName .. "EnemyHealth", "Enemy Health %", 0, 100, 1, v.EnemyHealth)
		v.Menu.MyHealth = Activator.Menu.Offensive[menuName]:AddSlider(menuName .. "MyHealth", "My Health %", 0, 100, 1, v.MyHealth)
		v.Menu.Active = Activator.Menu.Offensive[menuName]:AddBool(menuName .. "_Toggle", "Active " .. v.Name, true)
	end

	local mName = self.Offensive[itemID.Tiamat].MenuName
	self.Offensive[itemID.Tiamat].Menu.FarmActive = Activator.Menu.Offensive[mName]:AddBool(mName .. "_FarmToggle", "Use Tiamet during Farming", true)
	mName = self.Offensive[itemID.RavenousHydra].MenuName
	self.Offensive[itemID.RavenousHydra].Menu.FarmActive = Activator.Menu.Offensive[mName]:AddBool(mName .. "_FarmToggle", "Use Hydra during Farming", true)

	Activator.Menu.Offensive:AddBool("FocusedOnly", "Use items on Focused Target ONLY", true)
	Activator.Menu.Offensive:AddBool("ATOF_Toggle", "Use Offensive Items", true)
end

local function FocusedCondition (Range)
	local focusedT = TS:GetForcedTarget()
	local toggle = Activator.Menu.Offensive.FocusedOnly.Value
	local target = TS:GetTarget(Range)
	return (toggle and ((focusedT and focusedT == target) or (focusedT == nil))) or not toggle
end

function Activator:OnTick()
	local menu = Activator.Menu.Offensive
	if ( menu.ATOF_Toggle.Value ) then

		if (Orbwalker.GetMode() == self.EnumMode[1]) then
			local target = TS:GetTarget(1000)
			if (target == nil) then
				return
			end
			for k, v in pairs(Player.Items) do
				local itemslot = k + 6
				local item = self.Offensive[v.ItemId]
				if (item and item.Menu.Active.Value and Player:GetSpellState(itemslot) == SpellStates.Ready) then
					target = TS:GetTarget(item.Range)
					local focusedCond = FocusedCondition(item.Range)
					if (target and focusedCond) then
						if (Player.HealthPercent <= item.Menu.MyHealth.Value or target.HealthPercent <= item.Menu.EnemyHealth.Value) then
							if (item.Type == self.EnumOffensiveType.Targeted) then
								Input.Cast(itemslot, target)
							elseif (item.Type == self.EnumOffensiveType.Active) then
								Input.Cast(itemslot)
							elseif (item.Type == self.EnumOffensiveType.NonTargeted) then
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
end

local function IsTiamentOrHydra(_ItemID)
	local temp = {[itemID.Tiamat] = true , [itemID.RavenousHydra] = true}
	return (temp[_ItemID] and Activator.Offensive[_ItemID].Menu.FarmActive.Value)
end

function Activator:OnUnkillableMinion(minion)
	local menu = Activator.Menu.Offensive
	if ( menu.ATOF_Toggle.Value ) then
		if (minion:Distance(Player) <= self.Offensive[itemID.Tiamat].Range) then
			for k, v in pairs(Player.Items) do
				local itemslot = k + 6
				local cond = IsTiamentOrHydra(v.ItemId)
				if ( cond ) then
				local item = self.Offensive[v.ItemId]
					if (item and item.Menu.Active.Value and Player:GetSpellState(itemslot) == SpellStates.Ready) then
						Input.Cast(itemslot, minion)
					end
				end
			end
		end
	end
end

local function IsTeam(IsAlly, this, MenuType)
	return (this.Menu[MenuType .. "_Toggle"].Value) and
		((IsAlly and this.Menu[MenuType .. "_Ally"].Value) or (not IsAlly and this.Menu[MenuType .. "_Enemy"].Value))
end

local function TeamColor(isAlly, this, menuType)
	if (isAlly) then
		return this.Menu[menuType .. "_AllyColor"].Value
	else
		return this.Menu[menuType .. "_EnemyColor"].Value
	end
end

--[[
	████████ ██    ██ ██████  ███    ██  █████  ██████   ██████  ██    ██ ███    ██ ██████  
	   ██    ██    ██ ██   ██ ████   ██ ██   ██ ██   ██ ██    ██ ██    ██ ████   ██ ██   ██ 
	   ██    ██    ██ ██████  ██ ██  ██ ███████ ██████  ██    ██ ██    ██ ██ ██  ██ ██   ██ 
       ██    ██    ██ ██   ██ ██  ██ ██ ██   ██ ██   ██ ██    ██ ██    ██ ██  ██ ██ ██   ██ 
	   ██     ██████  ██   ██ ██   ████ ██   ██ ██   ██  ██████   ██████  ██   ████ ██████                                                                                                                                                                                                                                                                                                                                                                                                                        
]]

function TurnAround:Init()
	self.TurnAroundActive = false
	self.SpellData = {
		["Cassiopeia"] = {
			["CassiopeiaR"] = {Range = 850, PreDelay = 0, PostDealy = 525, Delay = 0.5, FacingFront = false, MoveTo = 100}
		},
		["Tryndamere"] = {
			["TryndamereW"] = {Range = 850, PreDelay = 100, PostDealy = 425, Delay = 0.3, FacingFront = true, MoveTo = -100}
		}
	}
	local enemyList = ObjManager.Get("enemy", "heroes")
	for handle, enemy in pairs(enemyList) do
		if (enemy) then
			local enemyHero = enemy.AsHero
			local tr = self.SpellData[enemyHero.CharName]
			if (tr) then
				self.TurnAroundActive = true
				break
			end
		end
	end
	self.LimitIssueOrder = 0
	self.OriginalPath = Vector(0, 0, 0)

	-- if there is no turn around champion, unload the Turnaround
	if (not self.TurnAroundActive) then
		EventManager.RemoveCallback(Enums.Events.OnIssueOrder, OnIssueOrder)
		EventManager.RemoveCallback(Enums.Events.OnProcessSpell, OnProcessSpell)
		TurnAround.OnIssueOrder = nil
		TurnAround.OnProcessSpell = nil
		self.SpellData = nil
		self.TurnAroundActive = nil
	end
	TurnAround:Menu()
end

function TurnAround:Menu()
	TurnAround.Menu = Menu:AddMenu("TA_Menu", "TurnAround")
	TurnAround.Menu:AddBool("TA_Toggle", "Activate TurnAround", true)
	TurnAround.Menu:AddLabel("TA_Label", "Cassiopeia/Tryndamere Supported", true)
end

function TurnAround:OnIssueOrder(Args)
	if (Args and TurnAround.Menu["TA_Toggle"].Value) then
		self.OriginalPath = Args.Position
		if (self.LimitIssueOrder > OSClock()) then
			Args.Process = false
		end
	end
end

function TurnAround:OnProcessSpell(obj, spellcast)
	if (TurnAround.Menu["TA_Toggle"].Value) then
		local objHero = obj.AsHero
		local cond = self.TurnAroundActive and obj and objHero and Player.IsAlive and objHero.IsEnemy
		if (cond) then
			local spell = self.SpellData[objHero.CharName][spellcast.Name]
			if (objHero and spell) then
				local condSpell = Player:Distance(objHero.Position) + Player.BoundingRadius <= spell.Range
				local isFacing = Player:IsFacing(objHero, 120)
				local condFacing = (isFacing and not spell.FacingFront) or (not isFacing and spell.FacingFront)
				if (condSpell and condFacing) then
					local overridePos =
						objHero.Position:Extended(Player.Position, Player.Position:Distance(objHero.Position) + spell.MoveTo)
					Input.MoveTo(overridePos)
					Input.MoveTo(overridePos)
					self.LimitIssueOrder = OSClock() + (spell.Delay)
					delay((spell.PostDealy), Input.MoveTo, self.OriginalPath)
				end
			end
		end
	end
end

--[[
	████████  ██████  ██     ██ ███████ ██████      ██████   █████  ███    ██  ██████  ███████ ███████ 
	   ██    ██    ██ ██     ██ ██      ██   ██     ██   ██ ██   ██ ████   ██ ██       ██      ██      
	   ██    ██    ██ ██  █  ██ █████   ██████      ██████  ███████ ██ ██  ██ ██   ███ █████   ███████ 
	   ██    ██    ██ ██ ███ ██ ██      ██   ██     ██   ██ ██   ██ ██  ██ ██ ██    ██ ██           ██ 
	   ██     ██████   ███ ███  ███████ ██   ██     ██   ██ ██   ██ ██   ████  ██████  ███████ ███████                                                                                                                                                                                                                                                                                                                                                                                                                    
]]

function TowerRanges:Init()
	local FountainTurrets = {["Turret_OrderTurretShrine_A"] = false, ["Turret_ChaosTurretShrine_A"] = false}
	self.TurretNames = {["SRU_Chaos_Turret1_Explode.troy"] = true, ["SRU_Order_Turret1_Explode.troy"] = true}
	self.TurretHashList = {
		866,
		327,
		624,
		955,
		767,
		134,
		318,
		943,
		481,
		611,
		52,
		504,
		919,
		281,
		846,
		48,
		651,
		981,
		512,
		169,
		748,
		177
	}
	local TurretData = {
		-- red team bot
		[866] = {Position = Vector(13866, 38, 4505), IsAlly = false},
		[327] = {Position = Vector(13327, 38, 8226), IsAlly = false},
		[624] = {Position = Vector(13624, 88, 10572), IsAlly = false},
		-- red team mid
		[955] = {Position = Vector(8955, 38, 8510), IsAlly = false},
		[767] = {Position = Vector(9767, 38, 10113), IsAlly = false},
		[134] = {Position = Vector(11134, 88, 11207), IsAlly = false},
		-- red team top
		[318] = {Position = Vector(4318, 38, 13875), IsAlly = false},
		[943] = {Position = Vector(7943, 38, 13411), IsAlly = false},
		[481] = {Position = Vector(10481, 88, 13650), IsAlly = false},
		-- red team twins
		[611] = {Position = Vector(12611, 88, 13084), IsAlly = false},
		[52] = {Position = Vector(13052, 88, 12612), IsAlly = false},
		-- blue team bot
		[504] = {Position = Vector(10504, 41, 1029), IsAlly = false},
		[919] = {Position = Vector(6919, 43, 1483), IsAlly = false},
		[281] = {Position = Vector(4281, 86, 1253), IsAlly = false},
		-- blue team mid
		[846] = {Position = Vector(5846, 44, 6396), IsAlly = false},
		[48] = {Position = Vector(5048, 43, 4812), IsAlly = false},
		[651] = {Position = Vector(3651, 91, 3696), IsAlly = false},
		-- blue team top
		[981] = {Position = Vector(981, 37, 10441), IsAlly = false},
		[512] = {Position = Vector(1512, 42, 6699), IsAlly = false},
		[169] = {Position = Vector(1169, 87, 4287), IsAlly = false},
		-- blue team twins
		[748] = {Position = Vector(1748, 88, 2270), IsAlly = false},
		[177] = {Position = Vector(2177, 89, 1807), IsAlly = false}
	}

	self.ActiveTurrets = {}

	local TurretList = ObjManager.Get("all", "turrets")
	for k, turret in pairs(TurretList) do
		local isAlly = turret.IsAlly
		local isFountain = FountainTurrets[turret.Name]
		if (not isFountain) then
			local hash = GetHash(turret.Position.x)
			local data = TurretData[hash]
			if (data) then
				local test = turret.AsAttackableUnit
				if (test.IsAlive) then
					data.IsAlly = isAlly
					self.ActiveTurrets[hash] = data
				end
			end
		end
	end
	self.MenuStr = "TR"
	TowerRanges:Menu()
end

function TowerRanges:Menu()
	TowerRanges.Menu = Menu:AddMenu("TR_Menu", "TowerRanges")
	TowerRanges.Menu:AddBool("TR_Enemy", "Track Enemy Towers", true)
	TowerRanges.Menu:AddRGBAMenu("TR_EnemyColor", "Enemy Tower Range Color", 0xFF0000FF)
	TowerRanges.Menu:AddBool("TR_Ally", "Track Ally Towers", true)
	TowerRanges.Menu:AddRGBAMenu("TR_AllyColor", "Ally Tower Range Color", 0x00FF00FF)
	TowerRanges.Menu:AddBool("TR_Toggle", "Activate Tower Ranges", true)
end

function TowerRanges:OnDraw()
	local value = TowerRanges.Menu.TR_Toggle.Value
	if (value) then
		for i = 1, #TowerRanges.TurretHashList do
			local hash = TowerRanges.TurretHashList[i]
			local turret = TowerRanges.ActiveTurrets[hash]
			if (turret) then
				local isScreen = Renderer.IsOnScreen(turret.Position)
				if (isScreen) then
					local isTeam = IsTeam(turret.IsAlly, TowerRanges, TowerRanges.MenuStr)
					if (not turret.IsDestroyed and isTeam) then
						local color = TeamColor(turret.IsAlly, TowerRanges, TowerRanges.MenuStr)
						Renderer.DrawCircle3D(turret.Position, 870, 25, 1, color)
					end
				end
			end
		end
	end
end

function TowerRanges:OnDelete(obj)
	local value = TowerRanges.Menu.TR_Toggle.Value
	if (value) then
		local name = self.TurretNames[obj.Name]
		if (name) then
			local hash = GetHash(obj.Position.x)
			self.ActiveTurrets[hash] = nil
			for i = 1, #self.TurretHashList do
				local hashActive = self.TurretHashList[i]
				if (hash == hashActive) then
					self.TurretHashList[i] = nil
				end
			end
		end
	end
end

--[[
	██████   █████  ████████ ██   ██     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
	██   ██ ██   ██    ██    ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	██████  ███████    ██    ███████        ██    ██████  ███████ ██      █████   █████   ██████  
	██      ██   ██    ██    ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
	██      ██   ██    ██    ██   ██        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
]]

function PathTracker:Init()
	self.HeroList = {}
	self.DrawBox = Vector(15, 15, 0)
	self.TextClipper = Vector(55, 15, 0)
	self.HandleList = {}
	local handleCount = 0
	local heroList = ObjManager.Get("all", "heroes")
	for handle, hero in pairs(heroList) do
		if (hero) then
			local ObjHero = hero.AsHero
			self.HeroList[handle] = {ObjHero, 0, 0}
			handleCount = handleCount + 1
			self.HandleList[handleCount] = handle
		end
	end
	PathTracker:Menu()
end

function PathTracker:Menu()
	PathTracker.Menu = Menu:AddMenu("PT_Menu", "PathTracker")
	PathTracker.Menu:AddBool("PT_Enemy", "Track Enemy", true)
	PathTracker.Menu:AddBool("PT_Ally", "Track Ally", false)
	PathTracker.Menu:AddBool("PT_Waypoints", "Track Waypoints", true)
	PathTracker.Menu:AddRGBAMenu("PT_WaypointsColor", "WayPoints Color", 0xFFFF00FF)
	PathTracker.Menu:AddBool("PT_ETA", "Show Estimated Arrival Time", true)
	PathTracker.Menu:AddBool("PT_CharName", "Show Champion Name", true)
	PathTracker.Menu:AddRGBAMenu("PT_ETAColor", "ETA/Champ Name Color", 0xFFFFFFFF)
	PathTracker.Menu:AddRGBAMenu("PT_AllyColor", "ETA Ally Background Color", 0x008000FF)
	PathTracker.Menu:AddRGBAMenu("PT_EnemyColor", "ETA Enemy Background Color", 0xDF0101FF)
	PathTracker.Menu:AddBool("PT_Toggle", "Activate Path Tracker", true)
end

local function CalculateETA(dis, MoveSpeed)
	return (dis / MoveSpeed)
end

local function ETAToSeconds(Seconds)
	return format("%02.f", floor(Seconds))
end

function PathTracker:OnDraw()
	if (PathTracker.Menu["PT_Toggle"].Value) then
		for i = 1, #self.HandleList do
			local value = self.HeroList[self.HandleList[i]]
			local v = value[2]
			local charName = value[1].CharName
			local IsOnScreen = Renderer.IsOnScreen

			if (v ~= 0 and #v.Waypoints > 1 and value[1].IsVisible) then
				for i = v.CurrentWaypoint, #v.Waypoints - 1 do
					local startPos, endPos = 0, v.Waypoints[i + 1]
					if (i == v.CurrentWaypoint) then
						startPos = value[1].Position
					else
						startPos = v.Waypoints[i]
					end
					if (IsOnScreen(endPos)) then
						Renderer.DrawLine3D(startPos, endPos, 1, 0xFFFF00FF)
					end
				end
				local vEndPos = v.EndPos
				if (IsOnScreen(vEndPos)) then
					local color = PathTracker.Menu.PT_ETAColor.Value
					if (PathTracker.Menu.PT_CharName.Value) then
						local drawName = Renderer.WorldToScreen(Vector(vEndPos.x - 30, vEndPos.y, vEndPos.z))
						Renderer.DrawText(drawName, self.TextClipper, charName, color)
					end

					if (PathTracker.Menu.PT_ETA.Value) then
						local drawTime = Renderer.WorldToScreen(Vector(vEndPos.x - 10, vEndPos.y - 35, vEndPos.z))
						Renderer.DrawFilledRect(drawTime, self.DrawBox, 2, TeamColor(value[1].IsAlly, PathTracker, "PT"))
						local time = value[3] - OSClock()
						if (time < 0) then
							value[2] = 0
							value[3] = 0
						else
							Renderer.DrawText(drawTime, self.TextClipper, ETAToSeconds(time), color)
						end
					end
				end
			end
		end
	end
end

function PathTracker:OnNewPath(obj, pathing)
	local cond = obj and obj.IsHero and obj.IsVisible and not obj.IsMe and (IsTeam(obj.IsAlly, PathTracker, "PT"))
	if (cond) then
		local Handle = obj.Handle
		if (Handle) then
			local enemy = self.HeroList[Handle]
			if (enemy) then
				self.HeroList[Handle][2] = pathing
				if (PathTracker.Menu.PT_ETA.Value) then
					local ETA = 0.0
					local movespeed = obj.MoveSpeed
					for i = 1, #pathing.Waypoints - 1 do
						local startPos, endPos = pathing.Waypoints[i], pathing.Waypoints[i + 1]
						local dis = startPos:Distance(endPos)
						ETA = ETA + CalculateETA(dis, movespeed)
					end

					if (ETA > 0.0) then
						self.HeroList[Handle][3] = OSClock() + ETA
					end
				end
			end
		end
	end
end

--[[
	██████  ██       ██████   ██████ ██   ██     ███    ███ ██ ███    ██ ██  ██████  ███    ██ 
	██   ██ ██      ██    ██ ██      ██  ██      ████  ████ ██ ████   ██ ██ ██    ██ ████   ██ 
	██████  ██      ██    ██ ██      █████       ██ ████ ██ ██ ██ ██  ██ ██ ██    ██ ██ ██  ██ 
	██   ██ ██      ██    ██ ██      ██  ██      ██  ██  ██ ██ ██  ██ ██ ██ ██    ██ ██  ██ ██ 
	██████  ███████  ██████   ██████ ██   ██     ██      ██ ██ ██   ████ ██  ██████  ██   ████                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
]]

function BlockMinion:Init()
	self.TargetMinion = nil
	self.GetMinion = false
	self.ToggleCondition = false
	self.BlockOnMsg = "Blocking ON"
	self.FindingMsg = "Fidning a Minion.."
	self.TextClipper = Vector(150, 15, 0)
	self.LocalTick = 0
	BlockMinion:Menu()
end

function BlockMinion:Menu()
	BlockMinion.Menu = Menu:AddMenu("BM_Menu", "BlockMinion")
	BlockMinion.Menu:AddBool("BM_Toggle", "Activate Block Minion", true)
	BlockMinion.Menu:AddKeyBind("BM_Key", "Blocking Key", 90) -- 90 is Z
end

local function TurnOffBlockMinion()
	BlockMinion.targetMinion = nil
	BlockMinion.GetMinion = false
end

local function BlockCondition()
	local toggle = BlockMinion.Menu.BM_Toggle.Value
	local key = BlockMinion.Menu.BM_Key.Value
	if (toggle and not key) then
		TurnOffBlockMinion()
		return false
	end
	return (toggle and key)
end

local function GetTheClosetMinion()
	local closetMinion = nil
	local minionList = ObjManager.Get("ally", "minions")
	local mindis = 500
	for handle, minion in pairs(minionList) do
		local distance = Player:Distance(minion)
		local minionAI = minion.AsAI
		local isFacing = minionAI:IsFacing(Player, 120)
		if (minionAI and distance < mindis and isFacing and minionAI.MoveSpeed > 0) then
			local direction = minionAI.Direction
			if (direction) then
				closetMinion = minion
				mindis = distance
			end
		end
	end
	return closetMinion
end

function BlockMinion:OnUpdate()
	local tick = OSClock()
	if (self.LocalTick < tick) then
		self.LocalTick = tick + 0.1
		local cond = BlockCondition()
		if (cond) then
			local tgminion = self.targetMinion
			if (not self.GetMinion) then
				tgminion = GetTheClosetMinion()
				if (not tgminion) then
					self.targetMinion = nil
					return
				end
				self.targetMinion = tgminion
				self.GetMinion = true
			end
			if (tgminion) then
				local minionAI = tgminion.AsAI
				if (minionAI) then
					local direction = minionAI.Direction
					local isFacing = minionAI:IsFacing(Player, 160)
					if (not isFacing) then
						TurnOffBlockMinion()
					else
						if (direction and minionAI.Pathing.IsMoving and minionAI.IsVisible) then
							local extend = minionAI.Position:Extended(direction, -150)
							local mousepos = Renderer:GetMousePos()
							local newextend = extend:Extended(mousepos, 40)
							Input.MoveTo(newextend)
						end
					end
				end
			end
		end
	end
end

function BlockMinion:OnDraw()
	if (BlockMinion.Menu.BM_Key.Value) then
		local cond = BlockCondition()
		self.ToggleCondition = cond
		if (cond) then
			local color = 0x00FF00FF
			local str = self.FindingMsg
			local tg = self.targetMinion
			if (tg) then
				local tgMinion = tg.AsAI
				if (tgMinion) then
					Renderer.DrawCircle3D(tgMinion.Position, 50, 15, 1, color)
					str = self.BlockOnMsg
				end
			end
			local adjust = Renderer.WorldToScreen(Player.Position) + Vector(0, 20, 0)
			Renderer.DrawText(adjust, self.TextClipper, str, color)
		end
	end
end

--[[
	███    ███  █████  ██ ███    ██ 
	████  ████ ██   ██ ██ ████   ██ 
	██ ████ ██ ███████ ██ ██ ██  ██ 
	██  ██  ██ ██   ██ ██ ██  ██ ██ 
	██      ██ ██   ██ ██ ██   ████ 
]]

function OnUnkillableMinion(minion)
	Activator:OnUnkillableMinion(minion)
end

function OnUpdate()
	BlockMinion:OnUpdate()
end

function OnIssueOrder(Args)
	TurnAround:OnIssueOrder(Args)
end

function OnProcessSpell(obj, spellcast)
	TurnAround:OnProcessSpell(obj, spellcast)
end

function OnNewPath(obj, pathing)
	PathTracker:OnNewPath(obj, pathing)
end

function OnTick()
	local tick = OSClock()
	if (TickCount < tick) then
		TickCount = tick + 0.3
		for i = 1, #FeaturedClasses do
			local onTick = FeaturedClasses[i].OnTick
			if (onTick ~= nil) then
				FeaturedClasses[i]:OnTick()
			end
		end
	end
end

function OnDraw()
	for i = 1, #FeaturedClasses do
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
	for i = 1, #FeaturedClasses do
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
	for i = 1, #FeaturedClasses do
		local onDelete = FeaturedClasses[i].OnDelete
		if (onDelete ~= nil) then
			FeaturedClasses[i]:OnDelete(obj)
		end
	end
end

function OnLoad()
	EventManager.RegisterCallback(Enums.Events.OnUpdate, OnUpdate)
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnCreateObject, OnCreate)
	EventManager.RegisterCallback(Enums.Events.OnDeleteObject, OnDelete)
	EventManager.RegisterCallback(Enums.Events.OnIssueOrder, OnIssueOrder)
	EventManager.RegisterCallback(Enums.Events.OnProcessSpell, OnProcessSpell)
	EventManager.RegisterCallback(Enums.Events.OnNewPath, OnNewPath)
	EventManager.RegisterCallback(Enums.Events.OnUnkillableMinion, OnUnkillableMinion)

	for i = 1, #FeaturedClasses do
		local Init = FeaturedClasses[i].Init
		if (Init ~= nil) then
			FeaturedClasses[i]:Init()
		end
	end
	print("[E2Slayer] E2Utility is Loaded - " .. format("%.1f", Version))
	return true
end
