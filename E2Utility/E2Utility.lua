-- Requirements

require("common.log")
module("E2Utility", package.seeall, log.setup)

local Menu = require("lol/Modules/Common/Menu")

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
local currentVersion = 1.0

-- Menu
local M_Menu = Menu:AddMenu("E2Utility")
local S_Menu1 = M_Menu:AddMenu("JungleTimer")
local S_Menu1_Settings = S_Menu1:AddMenu("Jungle Timer Settings")
local S_Menu1_OnMap = S_Menu1_Settings:AddBool("Use on the Map", true)
local S_Menu1_OnMapColor = S_Menu1_Settings:AddRGBAMenu("Timer Text on Map Color", 0x00FF00FF)
local S_Menu1_OnMapBackground = S_Menu1_Settings:AddBool("Use a Background Color", true)
local S_Menu1_OnMapBackgroundColor = S_Menu1_Settings:AddRGBAMenu("Background Color", 0x008000FF)

local S_Menu1_OnMinimap = S_Menu1_Settings:AddBool("Used on the Minimap", true)
local S_Menu1_OnMinimapColor = S_Menu1_Settings:AddRGBAMenu("Timer Text on Minimap Color", 0x00FF00FF)

local S_Menu1_Mobs = S_Menu1:AddMenu("Jungle Mobs List")
local S_Menu1_JTActive = S_Menu1:AddBool("Activate Jungle Timer", true)
local S_Menu1_Label1 = S_Menu1:AddLabel("An Exploit Included")

local JungleMobsData = {}
local JungleTimerTable = {821, 783, 61, 762, 131, 59, 820, 66, 499, 394, 288, 703, 400, 500, 866, 7}

-- A Bool to end Rift timer
local RiftOver = false

-- [id] hashtable ID
-- ["m_name"] Name for the menu
-- ["position"] Position for the jungle mob
-- ["adjustment"] A Vector to adjust the position because some of them are at the accurate position
-- ["respawn_timer"] Respawning time
-- ["saved_time"] GameTime + Respawning Time
-- ["active"] Active status for the current jungle mob
-- ["b_menu"] Menu boolean value
JungleMobsData = {
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

function OnDraw()
	-- ForLooping only table has at least one element
	if (#JungleTimerTable > 0 and S_Menu1_JTActive.Value) then
		for i, hash in ipairs(JungleTimerTable) do
			if (JungleMobsData[hash]["active"]) then
				local currentGameTime = Game.GetTime()
				local timeleft = JungleMobsData[hash]["saved_time"] - currentGameTime
				-- First condition for removing ended timers and the second one for removing rift timer after baron spawned.
				if (timeleft <= 0) then
					JungleMobsData[hash]["active"] = false
					table.remove(JungleTimerTable, 1)
				else
					if (hash == 7 and currentGameTime >= 1200 and RiftOver == false) then
						RiftOver = true
						JungleMobsData[hash]["active"] = false
						table.remove(JungleTimerTable, 1)
					else
						-- adjustment vector for correcting position for some jungle mobs
						local pos = JungleMobsData[hash]["position"] + JungleMobsData[hash]["adjustment"]
						-- convert time into m:ss format
						local time = tostring(SecondsToClock(timeleft))
						-- draw only pos is on the screen
						if (Renderer.IsOnScreen(pos)) then
							if (S_Menu1_OnMap.Value) then
								if (S_Menu1_OnMapBackground.Value) then
									Renderer.DrawFilledRect(Renderer.WorldToScreen(pos), Vector(30, 15, 0), 2, S_Menu1_OnMapBackgroundColor.Value)
								end
								Renderer.DrawText(Renderer.WorldToScreen(pos), Vector(30, 15, 0), time, S_Menu1_OnMapColor.Value)
							end
						end

						if (S_Menu1_OnMinimap.Value) then
							Renderer.DrawText(
								Renderer.WorldToMinimap(pos) + Vector(-10, -10, 0),
								Vector(30, 15, 0),
								time,
								S_Menu1_OnMinimapColor.Value
							)
						end
					end
				end
			end
		end
	end
end

function GetHash(arg)
	return (math.floor(arg) % 1000)
end

function GetJungleTimer(handle_t)
	local ObjectAI = ObjManager.GetObjectByHandle(handle_t).AsAI
	for i = 0, ObjectAI.BuffCount do
		local buff = ObjectAI:GetBuff(i)
		if (buff and buff.Name == "camprespawncountdownhidden") then
			local hashID = GetHash(ObjectAI.Position.x)
			JungleMobsData[hashID]["saved_time"] = buff.StartTime + JungleMobsData[hashID]["respawn_timer"] + 1
			JungleMobsData[hashID]["active"] = true
			table.insert(JungleTimerTable, hashID)
		end
	end
end

function OnCreate(obj)
	if (obj ~= nil and obj.Name == "CampRespawn" and S_Menu1_JTActive.Value) then
		delay(100, GetJungleTimer, obj.Handle)
	end
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

function OnDelete(obj)
	if (obj ~= nil and obj.Name == "CampRespawn" and S_Menu1_JTActive.Value) then
		local hashID = GetHash(obj.AsAI.Position.x)
		JungleMobsData[hashID]["saved_time"] = -1
		JungleMobsData[hashID]["active"] = false
		local key = getIndex(JungleTimerTable, hashID)
		table.remove(JungleTimerTable, key)
	end
end

function OnLoad()
	--EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnCreateObject, OnCreate)
	EventManager.RegisterCallback(Enums.Events.OnDeleteObject, OnDelete)

	-- Add menu for the jungle mobs
	for i, hash in ipairs(JungleTimerTable) do
		JungleMobsData[hash]["b_menu"] = S_Menu1_Mobs:AddBool(JungleMobsData[hash]["m_name"], true)
	end

	-- GamePrint Chat
	Game.PrintChat(
		'<font color="#A4A4A4">[E2Slayer]</font> <font color="#5882FA">E2Utility</font><font color="#FFFFFF"> is Loaded - ' ..
			string.format("%.1f", currentVersion) .. "</font>"
	)
	return true
end
