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
-- Compatible with Lua 5.0, Vanilla WoW 1.12 API

local ArcaneMageRotation = {}

-- Configuration
local CONFIG = {
    HASTE_THRESHOLD = 25, -- Below 25% haste, use Surge
    MQG_ACTIVE_CHECK = true, -- Check for Mind Quickening Gem active
    ARCANE_POWER_ACTIVE_CHECK = true, -- Check for Arcane Power active
    DEBUG = false, -- Set to true for debug messages
    PRECAST_RUPTURE = true -- Allow casting Rupture out of combat
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
    MISSILE_BARRAGE = "Missile Barrage"
}

-- Casting state tracking
local castingState = {
    isChanneling = false,
    channelSpell = nil,
    channelEndTime = 0,
    lastSpellResisted = false,
    resistTime = 0,
    shouldInterruptChannel = false
}

-- Helper Functions
local function DebugPrint(msg)
    if CONFIG.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: " .. msg)
    end
end

-- Check if shift key is pressed (vanilla compatible)
local function IsShiftPressed()
    -- In vanilla WoW, we need to check the actual key state
    -- IsShiftKeyDown() is the correct function name in vanilla
    if IsShiftKeyDown then
        return IsShiftKeyDown()
    end
    return false
end

-- Vanilla-compatible spell cooldown check with spellbook scanning
local function IsSpellReady(spellName)
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

-- Check if a spell is actually usable (not grayed out)
local function IsSpellUsable(spellName)
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
        -- Check if spell is usable (not grayed out)
        local isUsable, notEnoughMana = IsUsableAction(spellId)
        local isSpellReady = IsSpellReady(spellName)
        print(spellId .. " - " .. tostring(isUsable) .. " - " .. tostring(isSpellReady))
        -- local revenge_usable, revenge_oom = IsUsableAction(RevengeSlotID)
        if isUsable and isSpellReady then
            return true
        end
    end
    
    return false
end

-- Check if Arcane Surge is actually usable (after a resist)
local function IsArcaneSurgeUsable()
    -- Check if the spell is actually usable (not grayed out)
    local isUsable = IsSpellUsable(SPELLS.ARCANE_SURGE)
    
    if CONFIG.DEBUG then
        DebugPrint("Arcane Surge usable check: " .. (isUsable and "yes" or "no"))
    end
    
    return isUsable
end

-- Standard buff checking (no pfUI dependencies)
local function HasBuff(unit, buffName)
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
        -- DebugPrint(" PFUI IS CASTING")
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

-- Standard spell casting (no pfUI dependencies)
local function CastSpell(spellName)
    if not IsSpellReady(spellName) then
        DebugPrint(spellName .. " is not ready")
        return false
    end
    
    -- Special check for Arcane Surge - check if it's actually usable
    if spellName == SPELLS.ARCANE_SURGE and not IsArcaneSurgeUsable() then
        DebugPrint("Arcane Surge not usable (no recent resist)")
        return false
    end
    
    -- Track channeling spells
    if spellName == SPELLS.ARCANE_MISSILES then
        castingState.isChanneling = true
        castingState.channelSpell = spellName
        castingState.channelEndTime = GetTime() + 5 -- Approximate channel time
        castingState.shouldInterruptChannel = false
    end
    
    CastSpellByName(spellName)
    DebugPrint("Casting: " .. spellName)
    return true
end

-- Event handler for spell casting and resists
local function OnEvent(event)
    if event == "SPELLCAST_CHANNEL_START" then
        castingState.isChanneling = true
        castingState.channelSpell = arg1
        castingState.channelEndTime = GetTime() + 5
        castingState.shouldInterruptChannel = false
    elseif event == "SPELLCAST_CHANNEL_STOP" or event == "SPELLCAST_INTERRUPTED" then
        castingState.isChanneling = false
        castingState.channelSpell = nil
        castingState.channelEndTime = 0
        castingState.shouldInterruptChannel = false
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
            DebugPrint("Spell resisted - Arcane Surge should now be available")
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

-- Check if player is moving (simplified)
local function IsMoving()
    -- Check if GetUnitSpeed exists (might not be in vanilla)
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
    
    -- Check if we're in combat
    local inCombat = UnitAffectingCombat("player")
    
    -- Pre-combat: Cast Arcane Rupture if we don't have the buff
    if not inCombat and CONFIG.PRECAST_RUPTURE then
        if not HasBuff("player", BUFFS.RUPTURE_BUFF) and IsSpellReady(SPELLS.ARCANE_RUPTURE) then
            DebugPrint("Pre-combat: Casting Arcane Rupture")
            CastSpell(SPELLS.ARCANE_RUPTURE)
            return
        end
    end
    
    -- If not in combat and rupture is already up, do nothing
    if not inCombat then
        DebugPrint("Not in combat and rupture is active")
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
            -- Check if we need to refresh rupture and don't have the buff
            if not HasBuff("player", BUFFS.RUPTURE_BUFF) and IsSpellReady(SPELLS.ARCANE_RUPTURE) then
                -- In vanilla, we can't stop channeling directly
                -- Instead, we flag that we want to interrupt and let the player handle it
                castingState.shouldInterruptChannel = true
                DebugPrint("Should interrupt missiles to refresh rupture (move slightly or press ESC)")
                return
            else
                DebugPrint("Channeling missiles, continuing...")
                return
            end
        end
    end
    
    -- Get current haste percentage and shift key state
    local currentHaste = GetHastePercent()
    local isHasted = HasBuff("player", BUFFS.ARCANE_POWER) or HasBuff("player", BUFFS.MQG)
    local shiftPressed = IsShiftPressed()
    local surgeUsable = IsArcaneSurgeUsable()
    
    DebugPrint("Current haste: " .. currentHaste .. "%, Surge usable: " .. (surgeUsable and "yes" or "no") .. ", Shift: " .. (shiftPressed and "yes" or "no"))
    
    -- Movement handling - use Fire Blast to fish for resists for Arcane Surge
    if IsMoving() then
        if IsSpellReady(SPELLS.FIRE_BLAST) then
            CastSpell(SPELLS.FIRE_BLAST)
            return
        end
    end
    
    -- Cooldown usage (only if shift is pressed)
    if shiftPressed then
        -- Presence of Mind first
        if IsSpellReady(SPELLS.PRESENCE_OF_MIND) and not HasBuff("player", BUFFS.PRESENCE_OF_MIND) then
            CastSpell(SPELLS.PRESENCE_OF_MIND)
            return
        end
        
        -- Then Arcane Power if PoM is already up or on cooldown
        if IsSpellReady(SPELLS.ARCANE_POWER) and not HasBuff("player", BUFFS.ARCANE_POWER) then
            -- Only cast if we already have PoM or it's on cooldown
            if HasBuff("player", BUFFS.PRESENCE_OF_MIND) or not IsSpellReady(SPELLS.PRESENCE_OF_MIND) then
                CastSpell(SPELLS.ARCANE_POWER)
                return
            end
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
        -- Normal rotation: Surge (if usable after resist) -> Rupture -> Missiles
        DebugPrint("Normal rotation")
        
        -- Use Surge if we have less than 25% haste, it's off cooldown, AND it's actually usable
        if currentHaste < CONFIG.HASTE_THRESHOLD and IsSpellReady(SPELLS.ARCANE_SURGE) and surgeUsable then
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
        DEFAULT_CHAT_FRAME:AddMessage("- Pre-combat rupture: " .. (CONFIG.PRECAST_RUPTURE and "enabled" or "disabled"))
        DEFAULT_CHAT_FRAME:AddMessage("- pfUI detected: " .. (pfUI and "yes" or "no"))
        DEFAULT_CHAT_FRAME:AddMessage("- Surge usable: " .. (IsArcaneSurgeUsable() and "yes" or "no"))
        DEFAULT_CHAT_FRAME:AddMessage("- Should interrupt channel: " .. (castingState.shouldInterruptChannel and "yes" or "no"))
        DEFAULT_CHAT_FRAME:AddMessage("- Shift key pressed: " .. (IsShiftPressed() and "yes" or "no"))
    elseif msg == "resetresist" then
        castingState.lastSpellResisted = false
        castingState.resistTime = 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Resist state reset")
    elseif msg == "interrupt" then
        castingState.shouldInterruptChannel = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Interrupt flag cleared")
    elseif msg == "precast" then
        CONFIG.PRECAST_RUPTURE = not CONFIG.PRECAST_RUPTURE
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Pre-combat rupture " .. (CONFIG.PRECAST_RUPTURE and "enabled" or "disabled"))
    elseif msg == "surge" then
        -- Test surge usability
        local usable = IsArcaneSurgeUsable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Arcane Surge usable: " .. (usable and "yes" or "no"))
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
    end,
    ClearInterruptFlag = function()
        castingState.shouldInterruptChannel = false
    end,
    TogglePrecastRupture = function()
        CONFIG.PRECAST_RUPTURE = not CONFIG.PRECAST_RUPTURE
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Arcane Rotation]: Pre-combat rupture " .. (CONFIG.PRECAST_RUPTURE and "enabled" or "disabled"))
    end
}

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Arcane Mage Rotation loaded! Use /arcane to execute, hold Shift for cooldowns")