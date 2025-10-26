-- BuffQuery.lua - Fast, event-driven buff/debuff tracking for WoW 1.12

BuffQuery = {}
BuffQuery.buffs = {}
BuffQuery.debuffs = {}
BuffQuery.callbacks = {}
BuffQuery.initialized = false

-- Fast lookup tables
BuffQuery.buffsByName = {}
BuffQuery.debuffsByName = {}

-- Known debuff textures for better identification
local DEBUFF_TEXTURES = {
    ["Interface\\Icons\\Spell_Nature_AbolishMagic"] = "Natural Solstice",
    ["Interface\\Icons\\Spell_Arcane_StarFire"] = "Arcane Solstice",
}

-- Tooltip for buff name scanning
local scanTooltip = nil

-- Initialize the system
function BuffQuery:Initialize()
    if self.initialized then return end
    
    -- Create scanning tooltip
    scanTooltip = CreateFrame("GameTooltip", "BuffQueryTooltip", nil, "GameTooltipTemplate")
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    -- Create event frame
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
    
    self.eventFrame:SetScript("OnEvent", function()
        BuffQuery:OnEvent(event, arg1)
    end)
    
    -- Initial scan
    self:FullScan()
    self.initialized = 1
end

-- Fast event handler
function BuffQuery:OnEvent(event, arg1)
    if event == "PLAYER_AURAS_CHANGED" then
        -- Only do incremental update, much faster than full scan
        self:IncrementalUpdate()
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        self:ParseCombatLogBuff(arg1, 1)
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        self:ParseCombatLogBuff(arg1, nil)
    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        self:ParseAuraRemoval(arg1)
    end
end

-- Fast buff name lookup with caching
local buffNameCache = {}
local function GetBuffName(slot)
    if buffNameCache[slot] then
        return buffNameCache[slot]
    end
    
    scanTooltip:ClearLines()
    scanTooltip:SetPlayerBuff(slot)
    local name = BuffQueryTooltipTextLeft1:GetText()
    
    if name then
        buffNameCache[slot] = name
        return name
    end
    
    return "Unknown Buff"
end

-- Fast debuff name lookup
local function GetDebuffName(texture, slot)
    return DEBUFF_TEXTURES[texture] or ("Debuff " .. slot)
end

-- Incremental update - only check what changed
function BuffQuery:IncrementalUpdate()
    local newBuffs = {}
    local newDebuffs = {}
    local newBuffsByName = {}
    local newDebuffsByName = {}
    
    -- Quick buff scan
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
                type = "buff"
            }
            newBuffs[slot] = buff
            newBuffsByName[name] = buff
        end
        slot = slot + 1
    end
    
    -- Quick debuff scan
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
                type = "debuff"
            }
            newDebuffs[slot] = debuff
            newDebuffsByName[name] = debuff
        end
        slot = slot + 1
    end
    
    -- Check for changes and fire callbacks only if needed
    local changed = nil
    
    -- Compare buffs
    for slot, buff in newBuffs do
        local oldBuff = self.buffs[slot]
        if not oldBuff or oldBuff.stacks ~= buff.stacks then
            changed = 1
        end
    end
    
    for slot, oldBuff in self.buffs do
        if not newBuffs[slot] then
            changed = 1
        end
    end
    
    -- Compare debuffs
    for slot, debuff in newDebuffs do
        local oldDebuff = self.debuffs[slot]
        if not oldDebuff or oldDebuff.stacks ~= debuff.stacks then
            changed = 1
        end
    end
    
    for slot, oldDebuff in self.debuffs do
        if not newDebuffs[slot] then
            changed = 1
        end
    end
    
    -- Update if changed
    if changed then
        self.buffs = newBuffs
        self.debuffs = newDebuffs
        self.buffsByName = newBuffsByName
        self.debuffsByName = newDebuffsByName
        
        -- Clear cache periodically
        if math.random(100) == 1 then
            buffNameCache = {}
        end
        
        self:FireCallbacks()
    end
end

-- Full scan (only used on initialization)
function BuffQuery:FullScan()
    buffNameCache = {} -- Clear cache
    self:IncrementalUpdate()
end

-- Parse combat log for better debuff names
function BuffQuery:ParseCombatLogBuff(message, isBuff)
    local _, _, spellName = string.find(message, "You .* ([^%(%.]+)")
    if spellName then
        spellName = string.gsub(spellName, "%s+$", "")
        -- Update texture mapping if we can correlate it
        self:UpdateTextureMapping(spellName, isBuff)
    end
end

-- Parse aura removal
function BuffQuery:ParseAuraRemoval(message)
    local _, _, spellName = string.find(message, "([^%s]+) fades from you")
    if spellName then
        -- Could update our tracking here if needed
    end
end

-- Update texture mapping from combat log
function BuffQuery:UpdateTextureMapping(spellName, isBuff)
    if not isBuff then
        -- Try to find the debuff and update our mapping
        for slot, debuff in self.debuffs do
            if debuff.name == ("Debuff " .. slot) then
                DEBUFF_TEXTURES[debuff.texture] = spellName
                debuff.name = spellName
                self.debuffsByName[spellName] = debuff
                self.debuffsByName["Debuff " .. slot] = nil
                break
            end
        end
    end
end

-- Callback system for external addons
function BuffQuery:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

function BuffQuery:FireCallbacks()
    for i, callback in self.callbacks do
        callback()
    end
end

-- Fast API functions using cached data
function BuffQuery:GetPlayerBuffs()
    local result = {}
    for slot, buff in self.buffs do
        table.insert(result, buff)
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
    return result
end

-- Instant lookups using cached data
function BuffQuery:HasBuff(buffName)
    return self.buffsByName[buffName]
end

function BuffQuery:HasDebuff(debuffName)
    return self.debuffsByName[debuffName]
end

function BuffQuery:HasAura(auraName)
    return self.buffsByName[auraName] or self.debuffsByName[auraName]
end

-- Fast counts
function BuffQuery:GetBuffCount()
    local count = 0
    for slot, buff in self.buffs do
        count = count + 1
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

-- Fast filtered queries
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

-- Add custom texture mappings
function BuffQuery:AddDebuffMapping(texture, name)
    DEBUFF_TEXTURES[texture] = name
end

-- Debug function
function BuffQuery:PrintAllAuras()
    DEFAULT_CHAT_FRAME:AddMessage("=== Current Player Auras (Cached) ===")
    
    local buffCount = self:GetBuffCount()
    local debuffCount = self:GetDebuffCount()
    
    if buffCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Buffs (" .. buffCount .. "):")
        for slot, buff in self.buffs do
            local stackText = buff.stacks > 1 and (" x" .. buff.stacks) or ""
            DEFAULT_CHAT_FRAME:AddMessage("  " .. buff.name .. stackText)
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
        DEFAULT_CHAT_FRAME:AddMessage("/bq print - Show all cached auras")
        DEFAULT_CHAT_FRAME:AddMessage("/bq rescan - Force full rescan")
    end
end

-- Auto-initialize
BuffQuery:Initialize()