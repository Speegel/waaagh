-- BuffQuery.lua - Functions to query player buffs and debuffs in WoW 1.12 (Fixed)

BuffQuery = {}

-- Helper function to create a tooltip for scanning
local function CreateScanTooltip()
    if not BuffQuery.scanTooltip then
        BuffQuery.scanTooltip = CreateFrame("GameTooltip", "BuffQueryScanTooltip", nil, "GameTooltipTemplate")
        BuffQuery.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return BuffQuery.scanTooltip
end

-- Get buff name by scanning tooltip
local function GetBuffNameFromTooltip(slot)
    local tooltip = CreateScanTooltip()
    tooltip:ClearLines()
    tooltip:SetPlayerBuff(slot)
    
    -- Get the first line which contains the spell name
    local name = BuffQueryScanTooltipTextLeft1:GetText()
    return name
end

-- Get debuff name - fallback to texture-based identification or generic names
local function GetDebuffNameFromSlot(slot)
    -- Since SetPlayerDebuff doesn't exist, we'll use a fallback approach
    -- You can expand this table with known debuff textures -> names
    local knownDebuffTextures = {
        ["Interface\\Icons\\Spell_Nature_AbolishMagic"] = "Natural Solstice",
        ["Interface\\Icons\\Spell_Arcane_StarFire"] = "Arcane Solstice",
        -- Add more known debuff textures here
    }
    
    local texture = UnitDebuff("player", slot)
    if texture and knownDebuffTextures[texture] then
        return knownDebuffTextures[texture]
    end
    
    -- Fallback to generic name
    return "Debuff " .. slot
end

-- Alternative method using UnitDebuffType (if available on Turtle WoW)
local function GetDebuffInfo(slot)
    local texture, stacks, debuffType = UnitDebuff("player", slot)
    if not texture then
        return nil
    end
    
    -- Try to get name from texture mapping
    local name = GetDebuffNameFromSlot(slot)
    
    return {
        name = name,
        texture = texture,
        stacks = stacks or 1,
        slot = slot,
        debuffType = debuffType or "Unknown",
        type = "debuff"
    }
end

-- Get all current buffs on player
-- Returns: table of buff data {name, texture, stacks, slot}
function BuffQuery:GetPlayerBuffs()
    local buffs = {}
    local slot = 1
    
    while UnitBuff("player", slot) do
        local texture, stacks = UnitBuff("player", slot)
        if texture then
            local name = GetBuffNameFromTooltip(slot) or ("Buff " .. slot)
            
            table.insert(buffs, {
                name = name,
                texture = texture,
                stacks = stacks or 1,
                slot = slot,
                type = "buff"
            })
        end
        slot = slot + 1
    end
    
    return buffs
end

-- Get all current debuffs on player
-- Returns: table of debuff data {name, texture, stacks, slot, debuffType}
function BuffQuery:GetPlayerDebuffs()
    local debuffs = {}
    local slot = 1
    
    while UnitDebuff("player", slot) do
        local debuffInfo = GetDebuffInfo(slot)
        if debuffInfo then
            table.insert(debuffs, debuffInfo)
        end
        slot = slot + 1
    end
    
    return debuffs
end

-- Enhanced debuff texture mapping - add more as you discover them
function BuffQuery:AddDebuffMapping(texture, name)
    if not self.debuffMappings then
        self.debuffMappings = {}
    end
    self.debuffMappings[texture] = name
end

-- Alternative method using combat log to track debuff names
BuffQuery.trackedDebuffs = {}

-- Function to track debuffs via combat log (more accurate names)
function BuffQuery:StartCombatLogTracking()
    if not self.combatLogFrame then
        self.combatLogFrame = CreateFrame("Frame")
        self.combatLogFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
        self.combatLogFrame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
        
        self.combatLogFrame:SetScript("OnEvent", function()
            if event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
                -- Parse "You are afflicted by X"
                local _, _, spellName = string.find(arg1, "You are afflicted by ([^%.]+)")
                if spellName then
                    BuffQuery.trackedDebuffs[spellName] = GetTime()
                end
            elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
                -- Parse "X fades from you"
                local _, _, spellName = string.find(arg1, "([^%s]+) fades from you")
                if spellName and BuffQuery.trackedDebuffs[spellName] then
                    BuffQuery.trackedDebuffs[spellName] = nil
                end
            end
        end)
    end
end

-- Get debuffs with combat log enhanced names
function BuffQuery:GetPlayerDebuffsEnhanced()
    local debuffs = {}
    local slot = 1
    
    while UnitDebuff("player", slot) do
        local texture, stacks, debuffType = UnitDebuff("player", slot)
        if texture then
            -- Try to find a tracked name from combat log
            local name = nil
            for trackedName, timestamp in self.trackedDebuffs do
                -- Simple heuristic - if we have a recent debuff, it might match this slot
                if GetTime() - timestamp < 1 then
                    name = trackedName
                    break
                end
            end
            
            -- Fallback to texture-based name
            if not name then
                name = GetDebuffNameFromSlot(slot)
            end
            
            table.insert(debuffs, {
                name = name,
                texture = texture,
                stacks = stacks or 1,
                slot = slot,
                debuffType = debuffType or "Unknown",
                type = "debuff"
            })
        end
        slot = slot + 1
    end
    
    return debuffs
end

-- Get all buffs and debuffs combined
function BuffQuery:GetAllPlayerAuras()
    local auras = {}
    
    -- Get buffs
    local buffs = self:GetPlayerBuffs()
    for i, buff in buffs do
        table.insert(auras, buff)
    end
    
    -- Get debuffs (use enhanced version if combat log tracking is active)
    local debuffs = self.combatLogFrame and self:GetPlayerDebuffsEnhanced() or self:GetPlayerDebuffs()
    for i, debuff in debuffs do
        table.insert(auras, debuff)
    end
    
    return auras
end

-- Check if player has a specific buff by name
function BuffQuery:HasBuff(buffName)
    local buffs = self:GetPlayerBuffs()
    for i, buff in buffs do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end

-- Check if player has a specific debuff by name
function BuffQuery:HasDebuff(debuffName)
    local debuffs = self.combatLogFrame and self:GetPlayerDebuffsEnhanced() or self:GetPlayerDebuffs()
    for i, debuff in debuffs do
        if debuff.name == debuffName then
            return debuff
        end
    end
    return nil
end

-- Check if player has a specific aura by name
function BuffQuery:HasAura(auraName)
    return self:HasBuff(auraName) or self:HasDebuff(auraName)
end

-- Get buff count
function BuffQuery:GetBuffCount()
    local count = 0
    while UnitBuff("player", count + 1) do
        count = count + 1
    end
    return count
end

-- Get debuff count
function BuffQuery:GetDebuffCount()
    local count = 0
    while UnitDebuff("player", count + 1) do
        count = count + 1
    end
    return count
end

-- Get debuffs by type
function BuffQuery:GetDebuffsByType(debuffType)
    local debuffs = self.combatLogFrame and self:GetPlayerDebuffsEnhanced() or self:GetPlayerDebuffs()
    local filtered = {}
    
    for i, debuff in debuffs do
        if debuff.debuffType == debuffType then
            table.insert(filtered, debuff)
        end
    end
    
    return filtered
end

-- Check if player can be dispelled
function BuffQuery:CanBeDispelled()
    local magicDebuffs = self:GetDebuffsByType("Magic")
    return getn(magicDebuffs) > 0, magicDebuffs
end

-- Print all current buffs and debuffs
function BuffQuery:PrintAllAuras()
    DEFAULT_CHAT_FRAME:AddMessage("=== Current Player Auras ===")
    
    local buffs = self:GetPlayerBuffs()
    if getn(buffs) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Buffs:")
        for i, buff in buffs do
            local stackText = buff.stacks > 1 and (" x" .. buff.stacks) or ""
            DEFAULT_CHAT_FRAME:AddMessage("  " .. buff.name .. stackText)
        end
    end
    
    local debuffs = self.combatLogFrame and self:GetPlayerDebuffsEnhanced() or self:GetPlayerDebuffs()
    if getn(debuffs) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Debuffs:")
        for i, debuff in debuffs do
            local stackText = debuff.stacks > 1 and (" x" .. debuff.stacks) or ""
            DEFAULT_CHAT_FRAME:AddMessage("  " .. debuff.name .. stackText .. " (" .. debuff.debuffType .. ")")
        end
    end
    
    if getn(buffs) == 0 and getn(debuffs) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("No active auras")
    end
end

-- Slash commands
SLASH_BUFFQUERY1 = "/buffquery"
SLASH_BUFFQUERY2 = "/bq"

SlashCmdList["BUFFQUERY"] = function(msg)
    if msg == "print" or msg == "" then
        BuffQuery:PrintAllAuras()
    elseif msg == "track" then
        BuffQuery:StartCombatLogTracking()
        DEFAULT_CHAT_FRAME:AddMessage("Combat log tracking enabled for better debuff names")
    elseif msg == "buffs" then
        local buffs = BuffQuery:GetPlayerBuffs()
        DEFAULT_CHAT_FRAME:AddMessage("Active buffs: " .. getn(buffs))
        for i, buff in buffs do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. buff.name .. " (stacks: " .. buff.stacks .. ")")
        end
    elseif msg == "debuffs" then
        local debuffs = BuffQuery:GetPlayerDebuffs()
        DEFAULT_CHAT_FRAME:AddMessage("Active debuffs: " .. getn(debuffs))
        for i, debuff in debuffs do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. debuff.name .. " (" .. debuff.debuffType .. ", stacks: " .. debuff.stacks .. ")")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("BuffQuery commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/bq print - Show all auras")
        DEFAULT_CHAT_FRAME:AddMessage("/bq track - Enable combat log tracking for better debuff names")
        DEFAULT_CHAT_FRAME:AddMessage("/bq buffs - Show only buffs")
        DEFAULT_CHAT_FRAME:AddMessage("/bq debuffs - Show only debuffs")
    end
end

-- Auto-start combat log tracking
BuffQuery:StartCombatLogTracking()