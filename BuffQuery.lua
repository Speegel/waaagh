-- BuffQuery.lua - Clean version with support for combat-log-only buffs
BuffQuery = {}
BuffQuery.buffs = {}
BuffQuery.debuffs = {}
BuffQuery.callbacks = {}
BuffQuery.initialized = false
BuffQuery.lastUpdate = 0

-- Fast lookup tables
BuffQuery.buffsByName = {}
BuffQuery.debuffsByName = {}

-- Special buffs that only appear in combat log (not in buff slots)
local COMBAT_LOG_BUFFS = {
    ["Arcane Eclipse"] = {duration = 15, texture = "Interface\\Icons\\Spell_Arcane_Arcane01"},
    ["Nature Eclipse"] = {duration = 15, texture = "Interface\\Icons\\Spell_Nature_Abolishpoison"},
    ["Temporal Convergence"] = {duration = 10, texture = "Interface\\Icons\\Spell_Nature_StormReach"},
    -- Add more as needed
}

-- Tracking data for combat log buffs
local combatLogBuffs = {}

-- Configuration
local FAST_UPDATE_INTERVAL = 0.1
local SLOW_UPDATE_INTERVAL = 1.0

-- Known short-duration buffs that need fast tracking
local SHORT_BUFFS = {
    ["Nature's Grace"] = 1,
    ["Nature Eclipse"] = 1,
    ["Natural Boon"] = 1,
    ["Arcane Eclipse"] = 1,
    ["Astral Boon"] = 1,
}

-- Known debuff textures
local DEBUFF_TEXTURES = {
    ["Interface\\Icons\\Spell_Nature_AbolishMagic"] = "Natural Solstice",
    ["Interface\\Icons\\Spell_Arcane_StarFire"] = "Arcane Solstice",
    ["Interface\\Icons\\Spell_Arcane_Blast"] = "Arcane Rupture",
}

-- Tooltip for buff name scanning
local scanTooltip = nil

-- Tracking variables
local hasShortBuffs = nil
local updateTimer = 0
local forceUpdate = nil

-- Initialize the system
function BuffQuery:Initialize()
    if self.initialized then return end
    
    scanTooltip = CreateFrame("GameTooltip", "BuffQueryTooltip", nil, "GameTooltipTemplate")
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    self.eventFrame:SetScript("OnEvent", function()
        BuffQuery:OnEvent(event, arg1)
    end)
    
    self.eventFrame:SetScript("OnUpdate", function()
        BuffQuery:OnUpdate()
    end)
    
    self:FullScan()
    self.initialized = 1
end

-- High-frequency update handler
function BuffQuery:OnUpdate()
    local now = GetTime()
    updateTimer = updateTimer + arg1
    
    local shouldUpdate = nil
    
    if forceUpdate then
        shouldUpdate = 1
        forceUpdate = nil
    elseif hasShortBuffs and updateTimer >= FAST_UPDATE_INTERVAL then
        shouldUpdate = 1
    elseif updateTimer >= SLOW_UPDATE_INTERVAL then
        shouldUpdate = 1
    end
    
    if shouldUpdate then
        updateTimer = 0
        self:IncrementalUpdate()
        self:CheckCombatLogBuffExpiry()
    end
end

-- Event handler
function BuffQuery:OnEvent(event, arg1)
    if event == "PLAYER_AURAS_CHANGED" then
        forceUpdate = 1
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" or 
           event == "CHAT_MSG_SPELL_SELF_BUFF" then
        self:ParseCombatLogBuff(arg1, 1)
        forceUpdate = 1
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        self:ParseCombatLogBuff(arg1, nil)
        forceUpdate = 1
    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        self:ParseAuraRemoval(arg1)
        forceUpdate = 1
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:FullScan()
    end
end

-- Parse combat log for special buffs
function BuffQuery:ParseCombatLogBuff(message, isBuff)
    if not isBuff then return end
    
    local now = GetTime()
    
    -- Check for any combat-log-only buffs
    for buffName, data in COMBAT_LOG_BUFFS do
        if string.find(message, buffName) then
            if string.find(message, "You gain") or string.find(message, "You are affected") then
                -- Buff gained
                combatLogBuffs[buffName] = {
                    startTime = now,
                    duration = data.duration
                }
                
                local buffData = {
                    name = buffName,
                    texture = data.texture,
                    stacks = 1,
                    slot = -1,
                    type = "special",
                    timestamp = now,
                    duration = data.duration,
                    source = "combat_log"
                }
                
                self.buffsByName[buffName] = buffData
                self:FireCallbacks()
                
            elseif string.find(message, "fades") or string.find(message, "removed") then
                -- Buff removed
                combatLogBuffs[buffName] = nil
                self.buffsByName[buffName] = nil
                self:FireCallbacks()
            end
        end
    end
end

-- Parse aura removal
function BuffQuery:ParseAuraRemoval(message)
    for buffName, data in COMBAT_LOG_BUFFS do
        if string.find(message, buffName) and string.find(message, "fades from you") then
            combatLogBuffs[buffName] = nil
            self.buffsByName[buffName] = nil
            self:FireCallbacks()
        end
    end
end

-- Check for expired combat log buffs
function BuffQuery:CheckCombatLogBuffExpiry()
    local now = GetTime()
    local changed = nil
    
    for buffName, data in combatLogBuffs do
        if (now - data.startTime) > data.duration then
            combatLogBuffs[buffName] = nil
            self.buffsByName[buffName] = nil
            changed = 1
        end
    end
    
    if changed then
        self:FireCallbacks()
    end
end

-- Fast buff name lookup with caching
local buffNameCache = {}
local cacheTime = {}
local CACHE_DURATION = 30

local function GetBuffName(slot)
    local now = GetTime()
    
    if buffNameCache[slot] and cacheTime[slot] and (now - cacheTime[slot]) < CACHE_DURATION then
        return buffNameCache[slot]
    end
    
    scanTooltip:ClearLines()
    scanTooltip:SetPlayerBuff(slot)
    local name = BuffQueryTooltipTextLeft1:GetText()
    
    if name then
        buffNameCache[slot] = name
        cacheTime[slot] = now
        return name
    end
    
    return "Unknown Buff"
end

local function GetDebuffName(texture, slot)
    return DEBUFF_TEXTURES[texture] or ("Debuff " .. slot)
end

local function CheckForShortBuffs(buffs, buffsByName)
    for slot, buff in buffs do
        if SHORT_BUFFS[buff.name] then
            return 1
        end
    end
    
    -- Also check combat log buffs
    for name, data in combatLogBuffs do
        if SHORT_BUFFS[name] then
            return 1
        end
    end
    
    return nil
end

-- Incremental update with combat log buff preservation
function BuffQuery:IncrementalUpdate()
    local newBuffs = {}
    local newDebuffs = {}
    local newBuffsByName = {}
    local newDebuffsByName = {}
    
    -- Preserve combat log buffs first
    for name, buff in self.buffsByName do
        if buff.source == "combat_log" then
            newBuffsByName[name] = buff
        end
    end
    
    -- Scan normal buffs
    local slot = 1
    while UnitBuff("player", slot) do
        local texture, stacks = UnitBuff("player", slot)
        if texture then
            local name = GetBuffName(slot)
            local buff = {
                name = name,
                texture = texture,
                stacks = stacks or 1,
                slot = slot,
                type = "buff",
                timestamp = GetTime()
            }
            newBuffs[slot] = buff
            newBuffsByName[name] = buff
        end
        slot = slot + 1
    end
    
    -- Scan debuffs
    slot = 1
    while UnitDebuff("player", slot) do
        local texture, stacks, debuffType = UnitDebuff("player", slot)
        if texture then
            local name = GetDebuffName(texture, slot)
            local debuff = {
                name = name,
                texture = texture,
                stacks = stacks or 1,
                slot = slot,
                debuffType = debuffType or "Unknown",
                type = "debuff",
                timestamp = GetTime()
            }
            newDebuffs[slot] = debuff
            newDebuffsByName[name] = debuff
        end
        slot = slot + 1
    end
    
    hasShortBuffs = CheckForShortBuffs(newBuffs, newBuffsByName)
    
    -- Check for changes
    local changed = nil
    
    for slot, buff in newBuffs do
        local oldBuff = self.buffs[slot]
        if not oldBuff or oldBuff.stacks ~= buff.stacks or oldBuff.name ~= buff.name then
            changed = 1
        end
    end
    
    for slot, oldBuff in self.buffs do
        if not newBuffs[slot] then
            changed = 1
        end
    end
    
    for slot, debuff in newDebuffs do
        local oldDebuff = self.debuffs[slot]
        if not oldDebuff or oldDebuff.stacks ~= debuff.stacks or oldDebuff.name ~= debuff.name then
            changed = 1
        end
    end
    
    for slot, oldDebuff in self.debuffs do
        if not newDebuffs[slot] then
            changed = 1
        end
    end
    
    if changed then
        self.buffs = newBuffs
        self.debuffs = newDebuffs
        self.buffsByName = newBuffsByName
        self.debuffsByName = newDebuffsByName
        self.lastUpdate = GetTime()
        
        if math.random(100) == 1 then
            local now = GetTime()
            for slot, time in cacheTime do
                if (now - time) > CACHE_DURATION then
                    buffNameCache[slot] = nil
                    cacheTime[slot] = nil
                end
            end
        end
        
        self:FireCallbacks()
    end
end

-- Full scan
function BuffQuery:FullScan()
    buffNameCache = {}
    cacheTime = {}
    forceUpdate = 1
end

-- Callback system
function BuffQuery:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

function BuffQuery:FireCallbacks()
    for i, callback in self.callbacks do
        callback()
    end
end

-- API functions
function BuffQuery:GetPlayerBuffs()
    local result = {}
    for slot, buff in self.buffs do
        table.insert(result, buff)
    end
    
    -- Add combat log buffs
    for name, buff in self.buffsByName do
        if buff.source == "combat_log" then
            table.insert(result, buff)
        end
    end
    
    return result
end

function BuffQuery:GetPlayerDebuffs()
    local result = {}
    for slot, debuff in self.debuffs do
        table.insert(result, debuff)
    end
    return result
end

function BuffQuery:GetAllPlayerAuras()
    local result = {}
    for slot, buff in self.buffs do
        table.insert(result, buff)
    end
    for slot, debuff in self.debuffs do
        table.insert(result, debuff)
    end
    
    -- Add combat log buffs
    for name, buff in self.buffsByName do
        if buff.source == "combat_log" then
            table.insert(result, buff)
        end
    end
    
    return result
end

function BuffQuery:HasBuff(buffName)
    local buff = self.buffsByName[buffName]
    if buff and buff.source == "combat_log" and buff.duration then
        local elapsed = GetTime() - buff.timestamp
        if elapsed > buff.duration then
            self.buffsByName[buffName] = nil
            combatLogBuffs[buffName] = nil
            return nil
        end
    end
    return buff
end

function BuffQuery:HasDebuff(debuffName)
    return self.debuffsByName[debuffName]
end

function BuffQuery:HasAura(auraName)
    return self.buffsByName[auraName] or self.debuffsByName[auraName]
end

function BuffQuery:GetBuffCount()
    local count = 0
    for slot, buff in self.buffs do
        count = count + 1
    end
    
    -- Add combat log buffs
    for name, buff in self.buffsByName do
        if buff.source == "combat_log" then
            count = count + 1
        end
    end
    
    return count
end

function BuffQuery:GetDebuffCount()
    local count = 0
    for slot, debuff in self.debuffs do
        count = count + 1
    end
    return count
end

function BuffQuery:GetDebuffsByType(debuffType)
    local result = {}
    for slot, debuff in self.debuffs do
        if debuff.debuffType == debuffType then
            table.insert(result, debuff)
        end
    end
    return result
end

function BuffQuery:CanBeDispelled()
    local magicDebuffs = self:GetDebuffsByType("Magic")
    return getn(magicDebuffs) > 0, magicDebuffs
end

-- Add new combat log buffs
function BuffQuery:AddCombatLogBuff(name, duration, texture)
    COMBAT_LOG_BUFFS[name] = {
        duration = duration or 15,
        texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
    }
    SHORT_BUFFS[name] = 1
end

-- Debug function (simplified)
function BuffQuery:PrintAllAuras()
    DEFAULT_CHAT_FRAME:AddMessage("=== Current Player Auras ===")
    
    local buffCount = self:GetBuffCount()
    local debuffCount = self:GetDebuffCount()
    
    if buffCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Buffs (" .. buffCount .. "):")
        for slot, buff in self.buffs do
            local stackText = buff.stacks > 1 and (" x" .. buff.stacks) or ""
            DEFAULT_CHAT_FRAME:AddMessage("  " .. buff.name .. stackText)
        end
        
        -- Show combat log buffs
        for name, buff in self.buffsByName do
            if buff.source == "combat_log" then
                local remaining = buff.duration - (GetTime() - buff.timestamp)
                DEFAULT_CHAT_FRAME:AddMessage("  " .. name .. " [" .. string.format("%.1f", remaining) .. "s]")
            end
        end
    end
    
    if debuffCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Debuffs (" .. debuffCount .. "):")
        for slot, debuff in self.debuffs do
            local stackText = debuff.stacks > 1 and (" x" .. debuff.stacks) or ""
            DEFAULT_CHAT_FRAME:AddMessage("  " .. debuff.name .. stackText .. " (" .. debuff.debuffType .. ")")
        end
    end
    
    if buffCount == 0 and debuffCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("No active auras")
    end
end

-- Slash commands
SLASH_BUFFQUERY1 = "/buffquery"
SLASH_BUFFQUERY2 = "/bq"

SlashCmdList["BUFFQUERY"] = function(msg)
    BuffQuery:Initialize()
    
    if msg == "print" or msg == "" then
        BuffQuery:PrintAllAuras()
    elseif msg == "rescan" then
        BuffQuery:FullScan()
        DEFAULT_CHAT_FRAME:AddMessage("Full rescan completed")
    else
        DEFAULT_CHAT_FRAME:AddMessage("BuffQuery commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/bq print - Show all auras")
        DEFAULT_CHAT_FRAME:AddMessage("/bq rescan - Force full rescan")
    end
end

-- Auto-initialize
BuffQuery:Initialize()