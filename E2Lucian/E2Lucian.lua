require("common.log")
module("E2Lucian", package.seeall, log.setup)

local _Core = _G.CoreEx
local ObjManager,
    EventManager,
    Input,
    Enums,
    Game,
    Geometry,
    Renderer,
    Vector,
    Collision,
    Orbwalker,
    Prediction,
    Nav,
    HitChance,
    DamageLib =
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
    _G.Libs.Prediction,
    _G.CoreEx.Nav,
    _G.CoreEx.Enums.HitChance,
    _G.Libs.DamageLib
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player

local OSClock = os.clock
local floor = math.floor
local format = string.format

local TickCount = 0
local Version = 1.2
local E2Lucian = {}
local TS = {}

-- Copied from Thorn's script :^)
local _Q = {
    Slot = Enums.SpellSlots.Q,
    Speed = math.huge,
    Range = 500 + Player.BoundingRadius,
    EffectRadius = 1000 + Player.BoundingRadius,
    Delay = E2Lucian.GetQDelay, --Based on level
    Radius = 60, --Width 120
    UseHitbox = true,
    Type = "Linear",
    String = "Q"
}

-- Q extended
local _QE = {
    Slot = Enums.SpellSlots.Q,
    Speed = math.huge,
    Range = 1000 + Player.BoundingRadius,
    Delay = E2Lucian.GetQDelay,
    Radius = 60, --Width 120
    Width = 120,
    Type = "Linear"
}

local _W = {
    Slot = Enums.SpellSlots.W,
    Speed = 1600,
    Range = 900,
    Delay = 0.25,
    Radius = 55, --Width 110
    Collisions = {Heroes = true, Minions = true, WindWall = true},
    UseHitbox = true,
    Type = "Linear",
    String = "W"
}
local _E = {
    Slot = Enums.SpellSlots.E,
    Speed = 1350,
    Range = 425,
    MinRange = 200,
    Delay = 0,
    Type = "Linear",
    String = "E"
}
local _R = {
    Slot = Enums.SpellSlots.R,
    Speed = math.huge,
    Range = 1200,
    Delay = 0,
    Radius = 110, --Width 220
    Type = "Linear",
    Collisions = {Heroes = true, Minions = true, WindWall = true},
    UseHitbox = true,
    String = "R",
    FollowRange = 900
}

function E2Lucian.Init()
    E2Lucian.ETypes = {"Smart", "Short", "Long"}
    E2Lucian.Spells = {_Q, _W, _E, _R}
    E2Lucian.InvalidMobs = {["CampRespawn"] = true}
    E2Lucian.RTarget = nil
    E2Lucian.RVector = nil
    E2Lucian.BlockMove = false
    E2Lucian.Menu()
end

function E2Lucian.Menu()
    E2Lucian.Menu = _G.Libs.Menu:AddMenu("E2Lucian", "E2Lucian")
    TS = _G.Libs.TargetSelector(E2Lucian.Menu)

    E2Lucian.Menu:AddMenu("Combo", "Combo")
    E2Lucian.Menu.Combo:AddBool("UseQ", "Use Q", true)
    E2Lucian.Menu.Combo:AddBool("UseQET", "Use Extended Q", true)
    E2Lucian.Menu.Combo:AddBool("UseW", "Use W", true)
    E2Lucian.Menu.Combo:AddBool("UseWCol", "^- Ignore Collision in Close Combat", true)
    E2Lucian.Menu.Combo:AddBool("UseE", "Use E", true)
    E2Lucian.Menu.Combo:AddDropDown("EMode", "E Mode", E2Lucian.ETypes)
    E2Lucian.Menu.Combo:AddBool("UseR", "Use R", false)
    E2Lucian.Menu.Combo:AddLabel("UseRLabel", "^-> Only Killable")
    E2Lucian.Menu.Combo:AddBool("UseRMagnet", "^-> Use Magent R", false)

    E2Lucian.Menu:AddMenu("Harass", "Harass")
    E2Lucian.Menu.Harass:AddBool("UseQ", "Use Q", true)
    E2Lucian.Menu.Harass:AddBool("UseQET", "Use Extended Q", true)
    E2Lucian.Menu.Harass:AddSlider("UseQMana", "^- Q Min Mana %", 0, 100, 1, 40)
    E2Lucian.Menu.Harass:AddBool("UseW", "Use W", true)
    E2Lucian.Menu.Harass:AddBool("UseWCol", "^- Ignore Collision in Close Combat", true)
    E2Lucian.Menu.Harass:AddSlider("UseWMana", "^- W Min Mana %", 0, 100, 1, 40)

    E2Lucian.Menu:AddMenu("Waveclear", "Waveclear")
    E2Lucian.Menu.Waveclear:AddBool("UseQ", "Use Q", true)
    E2Lucian.Menu.Waveclear:AddSlider("UseQMana", "^- Q Min Mana %", 0, 100, 1, 40)
    E2Lucian.Menu.Waveclear:AddSlider("UseQMinhit", "^- Q Minions Hit", 1, 10, 1, 3)
    E2Lucian.Menu.Waveclear:AddBool("UseW", "Use W", true)
    E2Lucian.Menu.Waveclear:AddSlider("UseWMana", "^- W Min Mana %", 0, 100, 1, 40)
    E2Lucian.Menu.Waveclear:AddSlider("UseWMinhit", "^- W Minions Hit", 1, 10, 1, 3)

    E2Lucian.Menu:AddMenu("Jungleclear", "Jungleclear")
    E2Lucian.Menu.Jungleclear:AddBool("UseQ", "Use Q", true)
    E2Lucian.Menu.Jungleclear:AddSlider("UseQMana", "^- Q Min Mana %", 0, 100, 1, 40)
    E2Lucian.Menu.Jungleclear:AddBool("UseW", "Use W", true)
    E2Lucian.Menu.Jungleclear:AddSlider("UseWMana", "^- W Min Mana %", 0, 100, 1, 40)

    E2Lucian.Menu:AddMenu("Drawing", "Drawing")
    E2Lucian.Menu.Drawing:AddBool("DrawQ", "Draw Q Range", true)
    E2Lucian.Menu.Drawing:AddRGBAMenu("DrawQColor", "Q Color", 0xFFFFFFFF)
    E2Lucian.Menu.Drawing:AddBool("DrawW", "Draw W Range", true)
    E2Lucian.Menu.Drawing:AddRGBAMenu("DrawWColor", "W Color", 0xFFFFFFFF)
    E2Lucian.Menu.Drawing:AddBool("DrawE", "Draw E Range", true)
    E2Lucian.Menu.Drawing:AddRGBAMenu("DrawEColor", "E Color", 0x00FF00FF)
    E2Lucian.Menu.Drawing:AddBool("DrawR", "Draw R Range", true)
    E2Lucian.Menu.Drawing:AddRGBAMenu("DrawRColor", "R Color", 0xFFFFFFFF)

    E2Lucian.Menu:AddMenu("Misc", "Misc")
    E2Lucian.Menu.Misc:AddBool("UseR", "Use Magnet R", true)
    E2Lucian.Menu.Misc:AddKeyBind("MagnetR", "Magnet R", 84) -- 84 is T
end

-- Copied from Thorn xd. Thank you always
local function IsSpellReady(slot)
    return (Player:GetSpellState(Enums.SpellSlots[slot]) == Enums.SpellStates.Ready) and
        (Player:GetSpell(Enums.SpellSlots[slot]).ManaCost <= Player.Mana)
end
local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function CanDraw()
    return Player.IsVisible and Player.IsOnScreen and not Player.IsDead
end

-- 95 / 130 / 165 / 200 / 235 (+ 60 / 75 / 90 / 105 / 120% bonus AD)
function E2Lucian.GetQDamage()
    local qlevel = Player:GetSpell(_Q.Slot).Level
    return (60 + qlevel * 35) + ((45 + (15 * qlevel)) * 0.01 * Player.BonusAD)
end

-- 0.409-0.009*level
function E2Lucian.GetQDelay()
    return (0.409 - 0.009 * Player:GetSpell(_Q.Slot).Level)
end

-- 75 / 110 / 145 / 180 / 215 (+ 90% AP)
function E2Lucian.GetWDamage()
    return (40 + 35 * Player:GetSpell(_W.Slot).Level) + (Player.TotalAP * 0.9)
end

-- 20 / 40 / 60 (+ 25% AD) (+ 10% AP) per shot
-- 22 / 28 / 34 shots fire
function E2Lucian.GetRDamage(target)
    local rlevel = Player:GetSpell(_R.Slot).Level
    local addmg = (16 + 6 * rlevel) * (20 * rlevel + (0.25 * Player.TotalAD))
    local apdmg = (0.10 * Player.TotalAP)
    return DamageLib.CalculatePhysicalDamage(Player, target, addmg) +
        DamageLib.CalculateMagicalDamage(Player, target, apdmg)
end

--@return boolean - returns Player is casting R
function E2Lucian.IsCastingR()
    return Player:GetBuff("LucianR")
end

--@return boolean - returns Player has the lucian passive
function E2Lucian.HasPassive()
    return Player:GetBuff("LucianPassiveBuff")
end

--@return number - returns E range based on the user's selection
function E2Lucian.GetEMode()
    local eMode = E2Lucian.Menu.Combo.EMode.Value
    if( eMode == "Smart") then
        return -1
    elseif (eMode == "Short") then
        return _E.MinRange
    elseif (eMode == "Long") then
        return _E.Range
    end
    return _E.Range
end

--@param mode string - orbwalker mode
--@param mode spell - spell Name
--@param mode isEorR - is the spell E or R
--@return bool - Whether player can cast the spell or not
function E2Lucian.CanCast(mode, spell, isEorR)
    return E2Lucian.HasPassive() or not IsSpellReady(spell) or
        ((IsSpellReady(_E.String) and mode == "Combo" and E2Lucian.Menu[mode].UseE.Value) and not isEorR) or
        E2Lucian.IsCastingR()
end

--@param mode string - orbwalker mode
--@param mode spell - spell Name
--@return bool - Whether player has not enough mana
function E2Lucian.IsNotEnoughMana(mode, spell)
    return E2Lucian.Menu[mode]["Use" .. spell .. "Mana"].Value * 0.01 > Player.ManaPercent
end

--@param Manacheck boolean - it checks the logic requires minimum mana
--@param mode string - orbwalker mode
function E2Lucian.QLogic(ManaCheck, mode)
    if (ManaCheck or E2Lucian.CanCast(mode, _Q.String, false)) then
        return
    end
    local isQEnabled = E2Lucian.Menu[mode].UseQ.Value

    if (isQEnabled) then
        local target = TS:GetTarget(_Q.Range)
        if (target) then
            Input.Cast(_Q.Slot, target)
            return
        end
    end
    local isQexEnabled = E2Lucian.Menu[mode].UseQET.Value
    if (isQexEnabled) then
        for k, target in ipairs(TS:GetTargets(_QE.Range)) do
            local pred = Prediction.GetPredictedPosition(target, _QE, Player.Position)
            local castPos = pred.CastPosition
            local playerPos = Player.Position
            if (pred) then
                local minions = ObjManager.Get("enemy", "minions")
                for handle, minion in pairs(minions) do
                    local cond = minion.IsVisible and minion.Position:Distance(playerPos) <= _Q.Range
                    if (cond) then
                        -- z the old Projection on linear alegbra hits me again
                        -- maybe there is a better way?
                        local extended = playerPos:Extended(minion.Position, _QE.Range)
                        local isOnSegment, pointSegment, pointLine = Vector.ProjectOn(castPos, playerPos, extended)
                        if (Vector.Distance(pointSegment, castPos) <= _QE.Width) then
                            Input.Cast(_Q.Slot, minion)
                            return
                        end
                    end
                end
            end
        end
    end
end

--@param Manacheck boolean - it checks the logic requires minimum mana
--@param mode string - orbwalker mode
function E2Lucian.WLogic(ManaCheck, mode)
    if (ManaCheck or E2Lucian.CanCast(mode, _W.String, false) or not E2Lucian.Menu[mode].UseW.Value) then
        return
    end

    local target = TS:GetTarget(_W.Range)
    if (target and target.IsValid and not target.IsDead) then
        if (E2Lucian.Menu[mode].UseWCol.Value) then
            local distance = target.Position:Distance(Player)
            if (distance < 300) then
                Input.Cast(_W.Slot, target.Position)
                return
            end
        end
        local pred = Prediction.GetPredictedPosition(target, _W, Player.Position)
        if (pred and pred.HitChanceEnum >= HitChance.Low) then
            --print(" cast w")
            Input.Cast(_W.Slot, pred.CastPosition)
        end
    end
    
end

--@param Manacheck boolean - it checks the logic requires minimum mana
--@param mode string - orbwalker mode
function E2Lucian.ELogic(ManaCheck, mode)
    if (ManaCheck or E2Lucian.CanCast(mode, _E.String, true)) then
        return
    end

    local isEEnabled = E2Lucian.Menu[mode].UseE.Value
    if (isEEnabled) then
        local eMode = E2Lucian.GetEMode()
        local target = TS:GetTarget(_Q.Range + _E.MinRange)
        local mousePos = Renderer.GetMousePos()
        if (target and target.IsValid and not target.IsDead) then
            if ( eMode == -1 ) then
                local distance = Player.Position:Distance(target.Position)
                if( distance >= _E.Range) then
                    eMode = _E.Range
                else
                    eMode = _E.MinRange
                end
            end
            Input.Cast(_E.Slot, Player.Position:Extended(mousePos, eMode))
        end
    end
end

--@param Manacheck boolean - it checks the logic requires minimum mana
--@param mode string - orbwalker mode
function E2Lucian.RLogic(ManaCheck, mode)
    if (ManaCheck or E2Lucian.CanCast(mode, _R.String, true)) then
        return
    end
    local isEEnabled = E2Lucian.Menu[mode].UseR.Value
    if (isEEnabled) then
        local target = TS:GetTarget(_R.Range)
        if (target and ( (E2Lucian.GetRDamage(target) > target.Health + target.ShieldAll) or E2Lucian.Menu.Misc.MagnetR.Value)) then
            local pred = Prediction.GetPredictedPosition(target, _R, Player.Position)
            if (pred and pred.HitChanceEnum >= HitChance.Medium) then
                local extended = pred.CastPosition:Extended(Player.Position, _R.FollowRange)
                E2Lucian.RVector = pred.CastPosition - extended
                E2Lucian.RTarget = target
                Input.Cast(_R.Slot, pred.CastPosition)
            end
        end
    end
end

function E2Lucian.Combo()
    local mode = "Combo"
    E2Lucian.ELogic(false, mode)
    E2Lucian.WLogic(false, mode)
    E2Lucian.QLogic(false, mode)
    E2Lucian.RLogic(false, mode)
end

function E2Lucian.Harass()
    local mode = "Harass"
    E2Lucian.QLogic(E2Lucian.IsNotEnoughMana(mode, _Q.String), mode)
    E2Lucian.WLogic(E2Lucian.IsNotEnoughMana(mode, _W.String), mode)
end

function E2Lucian.Waveclear()
    local mode = "Waveclear"
    local useQ = E2Lucian.Menu[mode].UseQ.Value
    local useW = E2Lucian.Menu[mode].UseW.Value

    if ( not useQ and useW ) then
        return
    end
    local pointsQ = {}
    local pointsW = {}
    local playerPos = Player.Position
    local minionList = ObjManager.Get("enemy", "minions")
    local isQReady = IsSpellReady(_Q.String)
    local isWReady = IsSpellReady(_W.String)
    if ( useQ ) then
        local isQReadyForWave = isQReady and not E2Lucian.IsNotEnoughMana("Waveclear", _Q.String)
        for handle, minion in pairs(minionList) do
            local distance = minion.Position:Distance(playerPos)
            local cond = minion.IsVisible and not minion.IsDead and distance <= _W.Range
            if cond then
                local minionPos = minion.Position
                table.insert(pointsW, minionPos)
                if (isQReadyForWave and distance <= _Q.Range) then
                    table.insert(pointsQ, minionPos)
                    local bestPos, hitCount = Geometry.BestCoveringRectangle(pointsW, playerPos, _Q.Radius * 2)
                    if bestPos and hitCount >= E2Lucian.Menu[mode].UseQMinhit.Value then
                        Input.Cast(_Q.Slot, minion)
                    end
                end
            end
        end
    end

    if ( useW ) then
        if (isWReady and not E2Lucian.IsNotEnoughMana("Waveclear", _W.String)) then
            local bestPos, hitCount = Geometry.BestCoveringRectangle(pointsW, playerPos, _W.Radius * 2)
            if bestPos and hitCount >= E2Lucian.Menu[mode].UseWMinhit.Value then
                Input.Cast(_W.Slot, bestPos)
            end
        end
    end

    local jungleList = ObjManager.Get("neutral", "minions")
    
    for handle, minion in pairs(jungleList) do
        local distance = minion.Position:Distance(playerPos)
        local cond = minion.IsVisible and not minion.IsDead and E2Lucian.InvalidMobs[minion.Name] == nil and distance <= _W.Range and not minion.AsMinion.IsJunglePlant
        
        if cond then
            if (isWReady and not E2Lucian.IsNotEnoughMana("Jungleclear", _W.String) and useW) then
                Input.Cast(_W.Slot, minion.Position)
            end
            if (distance <= _Q.Range) then
                if (isQReady and not E2Lucian.IsNotEnoughMana("Jungleclear", _Q.String) and useQ) then
                    Input.Cast(_Q.Slot, minion)
                end
            end
        end
    end
end

function OnTick()
    local tick = OSClock()
    if (TickCount < tick) then
        TickCount = tick + 0.3
        if (GameIsAvailable()) then
            if (E2Lucian.Menu.Misc.MagnetR.Value) then
                E2Lucian.MagnetR()
            end
            -- '"Combo"'|'"Harass"'|'"Waveclear"'|'"Lasthit"'|'"Flee"'|'"nil"'
            local currentMode = E2Lucian[Orbwalker.GetMode()]
            if (currentMode) then
                currentMode()
            end
        end
    end
end

function OnDraw()
    if (CanDraw()) then
        for i, v in ipairs(E2Lucian.Spells) do
            local draw = E2Lucian.Menu.Drawing["Draw" .. v.String].Value
            if (draw) then
                Renderer.DrawCircle3D(
                    Player.Position,
                    v.Range,
                    33,
                    1,
                    E2Lucian.Menu.Drawing["Draw" .. v.String .. "Color"].Value
                )
            end
        end
    end
end

local function ShouldMagentR()
    local isCastingR = E2Lucian.IsCastingR()
    if ( not isCastingR ) then
        return false
    end
    local mode = Orbwalker.GetMode()
    if ( (mode == "Combo" and E2Lucian.Menu.Combo.UseRMagnet.Value ) or E2Lucian.Menu.Misc.MagnetR.Value) then
        return true
    end
    return false
end

function E2Lucian.MagnetR()
    if (E2Lucian.IsCastingR()) then
        local target = E2Lucian.RTarget
        if (target and target.IsValid) then
            local pred = Prediction.GetPredictedPosition(target, _R, Player.Position)
            if (pred) then
                Input.MoveTo(pred.CastPosition - E2Lucian.RVector)
            end
        end
    else
        E2Lucian.RLogic(false, "Misc")
        Input.MoveTo(Renderer.GetMousePos())
    end
end

--args:{Process, Position}
function OnPreMove(args)
    local shouldMagentR = ShouldMagentR()
    if (shouldMagentR) then
        args.Process = false
        E2Lucian.MagnetR()
    end
end

function OnLoad()
    if Player.CharName == "Lucian" then
        E2Lucian.Init()
        EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
        EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
        EventManager.RegisterCallback(Enums.Events.OnPreMove, OnPreMove)
        print("[E2Slayer] E2Lucian is Loaded - " .. format("%.1f", Version))
    end
    return true
end
