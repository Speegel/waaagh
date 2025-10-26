function FrostDPS()

    local IsIceBarrierReady = IsSpellReady(ABILITY_ICE_BARRIER_WAAAGH)
    local IsIcilesReady = IsSpellReady("Icicles")
    local IsArcaneSurgeReady = IsSpellReady("Arcane Surge")
    local IsFrostNovaR1Ready = IsSpellReady("Frost Nova(Rank 1)")

    if IsIceBarrierReady and not HasBuff("player", "Spell_Ice_Lament") then
        CastSpellByName(ABILITY_ICE_BARRIER_WAAAGH)
    end

    if not pfUI.env.UnitChannelInfo("player") then
        if IsIcilesReady then CastSpellByName("Icicles") end
        if CheckInteractDistance("target", 3) then
            if IsFrostNovaR1Ready then CastSpellByName("Frost Nova(Rank 1)") end
        end
        if IsArcaneSurgeReady then CastSpellByName("Arcane Surge") end
        CastSpellByName("Frostbolt")
    end
end

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
-- Arcane Mage DPS Rotation for Turtle WoW
-- Optimized for nampower v2.10.8 / unitXp v42 / SuperWow / PFui
-- Based on official Turtle WoW rotation guide
-- Compatible with Lua 5.0, Vanilla WoW API, and pfUI

local ArcaneMageRotation = {}

-- Configuration
local CONFIG = {
    HASTE_THRESHOLD = 25, -- Below 25% haste, use Surge
    MQG_ACTIVE_CHECK = true, -- Check for Mind Quickening Gem active
    ARCANE_POWER_ACTIVE_CHECK = true, -- Check for Arcane Power active
    DEBUG = false -- Set to true for debug messages
}

-- Spell names (adjust if localized)
local SPELLS = {
    ARCANE_SURGE = "Arcane Surge",
    ARCANE_RUPTURE = "Arcane Rupture", 
    ARCANE_MISSILES = "Arcane Missiles",
    ARCANE_POWER = "Arcane Power",
    PRESENCE_OF_MIND = "Presence of Mind",
    FIRE_BLAST = "Fire Blast"
}

-- Buff names
local BUFFS = {
    ARCANE_POWER = "Arcane Power",
    PRESENCE_OF_MIND = "Presence of Mind",
    RUPTURE_BUFF = "Arcane Rupture", -- Adjust based on actual buff name
    MQG = "Mind Quickening Gem", -- Adjust based on actual buff name
    MISSILE_BARRAGE = "Missile Barrage",
    ARCANE_SURGE_READY = "Arcane Surge" -- Buff that indicates surge is available after resist
}

-- Casting state tracking
local castingState = {
    isChanneling = false,
    channelSpell = nil,
    channelEndTime = 0,
    lastSpellResisted = false,
    resistTime = 0
}

-- Helper Functions
local function DebugPrint(msg)
    if CONFIG.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: " .. msg)
    end
end

-- pfUI compatible spell cooldown check
local function IsSpellReady(spellName)
    -- Check if pfUI's spell functions are available
    if pfUI and pfUI.api and pfUI.api.GetSpellCooldown then
        local start, duration = pfUI.api.GetSpellCooldown(spellName)
        return start == 0 or (GetTime() - start) >= duration
    end
    
    -- Fallback: try to find spell by name and get cooldown
    local spellId = nil
    local spellBook = "spell"
    
    -- Search spellbook for the spell
    local i = 1
    while true do
        local spellName_found, spellRank = GetSpellName(i, spellBook)
        if not spellName_found then
            break
        end
        if spellName_found == spellName then
            spellId = i
            break
        end
        i = i + 1
    end
    
    if spellId then
        local start, duration = GetSpellCooldown(spellId, spellBook)
        return start == 0 or (GetTime() - start) >= duration
    end
    
    -- If we can't find the spell, assume it's ready
    DebugPrint("Could not find spell: " .. spellName)
    return true
end

-- Check if Arcane Surge is actually usable (after a resist)
local function IsArcaneSurgeUsable()
    -- Check for the buff that indicates surge is available
    if HasBuff("player", BUFFS.ARCANE_SURGE_READY) then
        return true
    end
    
    -- Alternative: check if we recently had a resist
    if castingState.lastSpellResisted and (GetTime() - castingState.resistTime) < 10 then
        return true
    end
    
    return false
end

-- pfUI compatible buff checking
local function HasBuff(unit, buffName)
    -- Use pfUI's buff detection if available
    if pfUI and pfUI.api and pfUI.api.UnitHasBuff then
        return pfUI.api.UnitHasBuff(unit, buffName)
    end
    
    -- Fallback to standard method
    local i = 1
    while UnitBuff(unit, i) do
        local name = UnitBuff(unit, i)
        if name and string.find(name, buffName) then
            return true
        end
        i = i + 1
    end
    return false
end

-- Vanilla WoW compatible channeling detection
local function IsChanneling()
    -- Check if we have UnitChannelInfo (some vanilla clients have it)
    if UnitChannelInfo then
        local spell, _, _, _, endTime = UnitChannelInfo("player")
        return spell ~= nil and endTime > GetTime() * 1000
    end
    
    -- Fallback: use our own tracking
    return castingState.isChanneling and GetTime() < castingState.channelEndTime
end

-- Vanilla WoW compatible casting detection
local function IsCasting()
    -- Check pfUI casting detection first
    if pfUI and pfUI.api and pfUI.env.UnitChannelInfo then
        DebugPrint(" PFUI IS CASTING")
        return pfUI.env.UnitChannelInfo("player")
    end
    DebugPrint(" IS CASTING FALLBACK ")
    -- Fallback methods
    return SpellIsTargeting() or castingState.isChanneling
end

local function GetHastePercent()
    -- This is a simplified haste calculation
    local haste = 0
    
    -- Check for common haste buffs
    if HasBuff("player", BUFFS.ARCANE_POWER) then
        haste = haste + 30 -- Arcane Power gives 30% haste
    end
    
    if HasBuff("player", BUFFS.MQG) then
        haste = haste + 33 -- MQG gives 33% haste
    end
    
    -- Add base haste from Accelerated Arcana (5%)
    haste = haste + 5
    
    return haste
end

-- pfUI compatible spell casting
local function CastSpell(spellName)
    if not IsSpellReady(spellName) then
        DebugPrint(spellName .. " is not ready")
        return false
    end
    
    -- Special check for Arcane Surge
    if spellName == SPELLS.ARCANE_SURGE and not IsArcaneSurgeUsable() then
        DebugPrint("Arcane Surge not usable (no recent resist)")
        return false
    end
    
    -- Track channeling spells
    if spellName == SPELLS.ARCANE_MISSILES then
        castingState.isChanneling = true
        castingState.channelSpell = spellName
        castingState.channelEndTime = GetTime() + 5 -- Approximate channel time
    end
    
    -- Use pfUI's casting function if available
    if pfUI and pfUI.api and pfUI.api.CastSpellByName then
        pfUI.api.CastSpellByName(spellName)
    else
        CastSpellByName(spellName)
    end
    
    DebugPrint("Casting: " .. spellName)
    return true
end

-- Event handler for spell casting and resists
local function OnEvent(event)
    if event == "SPELLCAST_CHANNEL_START" then
        castingState.isChanneling = true
        castingState.channelSpell = arg1
        castingState.channelEndTime = GetTime() + 5
    elseif event == "SPELLCAST_CHANNEL_STOP" or event == "SPELLCAST_INTERRUPTED" then
        castingState.isChanneling = false
        castingState.channelSpell = nil
        castingState.channelEndTime = 0
    elseif event == "SPELLCAST_STOP" then
        -- Reset casting state when any spell finishes
        if castingState.channelSpell ~= SPELLS.ARCANE_MISSILES then
            castingState.isChanneling = false
            castingState.channelSpell = nil
        end
    elseif event == "SPELLCAST_FAILED" then
        -- Check if the failure was due to resist
        if arg1 and (string.find(arg1, "resist") or string.find(arg1, "immune")) then
            castingState.lastSpellResisted = true
            castingState.resistTime = GetTime()
            DebugPrint("Spell resisted - Arcane Surge now available")
        end
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- Alternative way to detect resists from combat log
        if arg1 and string.find(arg1, "resist") then
            castingState.lastSpellResisted = true
            castingState.resistTime = GetTime()
            DebugPrint("Resist detected from combat log")
        end
    end
end

-- Check if player is moving
local function IsMoving()
    -- pfUI might have movement detection
    if pfUI and pfUI.api and pfUI.api.UnitIsMoving then
        return pfUI.api.UnitIsMoving("player")
    end
    
    -- Fallback: check if GetUnitSpeed exists
    if GetUnitSpeed then
        return GetUnitSpeed("player") > 0
    end
    
    -- Ultimate fallback: always assume not moving
    return false
end

-- Main Rotation Function
function ArcaneMageRotation.Execute()
    -- Safety checks
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        DebugPrint("No valid target")
        return
    end
    
    if not UnitAffectingCombat("player") then
        DebugPrint("Not in combat")
        return
    end
    
    -- Don't interrupt current casts/channels unless it's missiles and we need to refresh rupture
    if IsCasting() then
        DebugPrint("Currently casting, waiting...")
        return
    end
    
    -- Check if we're channeling missiles
    local isChannelingMissiles = IsChanneling()
    if isChannelingMissiles then
        if castingState.channelSpell and string.find(castingState.channelSpell, SPELLS.ARCANE_MISSILES) then
            -- Only interrupt missiles if we need to refresh rupture and don't have the buff
            if not HasBuff("player", BUFFS.RUPTURE_BUFF) and IsSpellReady(SPELLS.ARCANE_RUPTURE) then
                SpellStopChanneling()
                castingState.isChanneling = false
                castingState.channelSpell = nil
                DebugPrint("Interrupting missiles to refresh rupture")
            else
                DebugPrint("Channeling missiles, continuing...")
                return
            end
        end
    end
    
    -- Get current haste percentage
    local currentHaste = GetHastePercent()
    local isHasted = HasBuff("player", BUFFS.ARCANE_POWER) or HasBuff("player", BUFFS.MQG)
    
    DebugPrint("Current haste: " .. currentHaste .. "%, Surge usable: " .. (IsArcaneSurgeUsable() and "yes" or "no"))
    
    -- Movement handling - use Fire Blast to fish for resists for Arcane Surge
    if IsMoving() then
        if IsSpellReady(SPELLS.FIRE_BLAST) then
            CastSpell(SPELLS.FIRE_BLAST)
            return
        end
    end
    
    -- Full opener rotation: PoM -> Rupture -> MQG -> Arcane Power -> Missiles
    if IsSpellReady(SPELLS.PRESENCE_OF_MIND) and IsSpellReady(SPELLS.ARCANE_POWER) then
        if not HasBuff("player", BUFFS.PRESENCE_OF_MIND) then
            CastSpell(SPELLS.PRESENCE_OF_MIND)
            return
        end
    end
    
    -- Rotation during Arcane Power or MQG: Rupture -> Missiles
    if isHasted then
        DebugPrint("Hasted rotation (AP/MQG active)")
        
        -- Rupture if we don't have the buff
        if not HasBuff("player", BUFFS.RUPTURE_BUFF) and IsSpellReady(SPELLS.ARCANE_RUPTURE) then
            CastSpell(SPELLS.ARCANE_RUPTURE)
            return
        end
        
        -- Cast missiles
        if IsSpellReady(SPELLS.ARCANE_MISSILES) then
            CastSpell(SPELLS.ARCANE_MISSILES)
            return
        end
    else
        -- Normal rotation: Surge (if available after resist) -> Rupture -> Missiles
        DebugPrint("Normal rotation")
        
        -- Use Surge if we have less than 25% haste, it's available, AND we can actually cast it
        if currentHaste < CONFIG.HASTE_THRESHOLD and IsSpellReady(SPELLS.ARCANE_SURGE) and IsArcaneSurgeUsable() then
            CastSpell(SPELLS.ARCANE_SURGE)
            return
        end
        
        -- Rupture if we don't have the buff
        if not HasBuff("player", BUFFS.RUPTURE_BUFF) and IsSpellReady(SPELLS.ARCANE_RUPTURE) then
            CastSpell(SPELLS.ARCANE_RUPTURE)
            return
        end
        
        -- Cast missiles
        if IsSpellReady(SPELLS.ARCANE_MISSILES) then
            CastSpell(SPELLS.ARCANE_MISSILES)
            return
        end
    end
    
    -- If we can't do anything else and we're moving, try Fire Blast to fish for resists
    if IsMoving() and IsSpellReady(SPELLS.FIRE_BLAST) then
        CastSpell(SPELLS.FIRE_BLAST)
        return
    end
    
    -- Fallback - shouldn't normally reach here
    DebugPrint("Fallback - no action taken")
end

-- Event frame setup for spell casting events and resists
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("SPELLCAST_STOP")
eventFrame:RegisterEvent("SPELLCAST_FAILED")
eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
eventFrame:SetScript("OnEvent", OnEvent)

-- Slash command setup
SLASH_ARCANEROT1 = "/arcane"
SLASH_ARCANEROT2 = "/arcrot"
SlashCmdList["ARCANEROT"] = function(msg)
    if msg == "debug" then
        CONFIG.DEBUG = not CONFIG.DEBUG
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Debug mode " .. (CONFIG.DEBUG and "enabled" or "disabled"))
    elseif msg == "config" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Configuration")
        DEFAULT_CHAT_FRAME:AddMessage("- Haste threshold: " .. CONFIG.HASTE_THRESHOLD .. "%")
        DEFAULT_CHAT_FRAME:AddMessage("- Debug mode: " .. (CONFIG.DEBUG and "enabled" or "disabled"))
        DEFAULT_CHAT_FRAME:AddMessage("- pfUI detected: " .. (pfUI and "yes" or "no"))
        DEFAULT_CHAT_FRAME:AddMessage("- Surge usable: " .. (IsArcaneSurgeUsable() and "yes" or "no"))
    elseif msg == "resetresist" then
        castingState.lastSpellResisted = false
        castingState.resistTime = 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Resist state reset")
    else
        ArcaneMageRotation.Execute()
    end
end

-- Keybind function (assign this to a key)
function ArcaneMageRotation_KeyPress()
    ArcaneMageRotation.Execute()
end

-- Integration with nampower (if available)
if nampower then
    local originalExecute = ArcaneMageRotation.Execute
    ArcaneMageRotation.Execute = function()
        if nampower.IsChanneling and nampower.IsChanneling() then
            return
        end
        originalExecute()
    end
end

-- Global functions for external access
function ExecuteArcaneRotation()
    ArcaneMageRotation.Execute()
end

ArcaneMageRotationAPI = {
    Execute = ArcaneMageRotation.Execute,
    ToggleDebug = function()
        CONFIG.DEBUG = not CONFIG.DEBUG
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Debug mode " .. (CONFIG.DEBUG and "enabled" or "disabled"))
    end,
    SetHasteThreshold = function(threshold)
        CONFIG.HASTE_THRESHOLD = threshold
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Haste threshold set to " .. threshold .. "%")
    end,
    ResetResistState = function()
        castingState.lastSpellResisted = false
        castingState.resistTime = 0
    end
}

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Arcane Mage Rotation loaded! Use /arcane to execute, /arcane debug to toggle debug mode")