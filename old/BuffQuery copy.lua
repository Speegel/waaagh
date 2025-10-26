-- BuffQuery.lua - Functions to query player buffs and debuffs in WoW 1.12

BuffQuery = {}

-- Helper function to create a tooltip for scanning
local function CreateScanTooltip()
    if not BuffQuery.scanTooltip then
        BuffQuery.scanTooltip = CreateFrame("GameTooltip", "BuffQueryScanTooltip", nil, "GameTooltipTemplate")
        BuffQuery.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return BuffQuery.scanTooltip
end

-- Get buff name by scanning tooltip (more reliable than GetPlayerBuffName)
local function GetBuffNameFromTooltip(slot, isBuff)
    local tooltip = CreateScanTooltip()
    tooltip:ClearLines()
    
    if isBuff then
        tooltip:SetPlayerBuff(slot)
    else
        tooltip:SetPlayerDebuff(slot)
    end
    
    -- Get the first line which contains the spell name
    local name = BuffQueryScanTooltipTextLeft1:GetText()
    return name
end

-- Get all current buffs on player
-- Returns: table of buff data {name, texture, stacks, slot}
function BuffQuery:GetPlayerBuffs()
    local buffs = {}
    local slot = 1
    
    while UnitBuff("player", slot) do
        local texture, stacks = UnitBuff("player", slot)
        if texture then
            local name = GetBuffNameFromTooltip(slot, 1) or ("Buff" .. slot)
            
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
        local texture, stacks, debuffType = UnitDebuff("player", slot)
        if texture then
            local name = GetBuffNameFromTooltip(slot, nil) or ("Debuff" .. slot)
            
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
-- Returns: table with all auras
function BuffQuery:GetAllPlayerAuras()
    local auras = {}
    
    -- Get buffs
    local buffs = self:GetPlayerBuffs()
    for i, buff in buffs do
        table.insert(auras, buff)
    end
    
    -- Get debuffs
    local debuffs = self:GetPlayerDebuffs()
    for i, debuff in debuffs do
        table.insert(auras, debuff)
    end
    
    return auras
end

-- Check if player has a specific buff by name
-- Returns: buff data if found, nil otherwise
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
-- Returns: debuff data if found, nil otherwise
function BuffQuery:HasDebuff(debuffName)
    local debuffs = self:GetPlayerDebuffs()
    for i, debuff in debuffs do
        if debuff.name == debuffName then
            return debuff
        end
    end
    return nil
end

-- Check if player has a specific aura (buff or debuff) by name
-- Returns: aura data if found, nil otherwise
function BuffQuery:HasAura(auraName)
    return self:HasBuff(auraName) or self:HasDebuff(auraName)
end

-- Get buff/debuff by slot number
-- Returns: aura data if found, nil otherwise
function BuffQuery:GetAuraBySlot(slot, isBuff)
    if isBuff then
        local texture, stacks = UnitBuff("player", slot)
        if texture then
            local name = GetBuffNameFromTooltip(slot, 1) or ("Buff" .. slot)
            return {
                name = name,
                texture = texture,
                stacks = stacks or 1,
                slot = slot,
                type = "buff"
            }
        end
    else
        local texture, stacks, debuffType = UnitDebuff("player", slot)
        if texture then
            local name = GetBuffNameFromTooltip(slot, nil) or ("Debuff" .. slot)
            return {
                name = name,
                texture = texture,
                stacks = stacks or 1,
                slot = slot,
                debuffType = debuffType or "Unknown",
                type = "debuff"
            }
        end
    end
    return nil
end

-- Get count of buffs
-- Returns: number of active buffs
function BuffQuery:GetBuffCount()
    local count = 0
    while UnitBuff("player", count + 1) do
        count = count + 1
    end
    return count
end

-- Get count of debuffs
-- Returns: number of active debuffs
function BuffQuery:GetDebuffCount()
    local count = 0
    while UnitDebuff("player", count + 1) do
        count = count + 1
    end
    return count
end

-- Get debuffs by type (Magic, Disease, Poison, Curse)
-- Returns: table of debuffs of specified type
function BuffQuery:GetDebuffsByType(debuffType)
    local debuffs = self:GetPlayerDebuffs()
    local filtered = {}
    
    for i, debuff in debuffs do
        if debuff.debuffType == debuffType then
            table.insert(filtered, debuff)
        end
    end
    
    return filtered
end

-- Check if player can be dispelled (has magic debuffs)
-- Returns: true/false and table of magic debuffs
function BuffQuery:CanBeDispelled()
    local magicDebuffs = self:GetDebuffsByType("Magic")
    return getn(magicDebuffs) > 0, magicDebuffs
end

-- Print all current buffs and debuffs (for debugging)
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
    
    local debuffs = self:GetPlayerDebuffs()
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

-- Slash command for testing
SLASH_BUFFQUERY1 = "/buffquery"
SLASH_BUFFQUERY2 = "/bq"

SlashCmdList["BUFFQUERY"] = function(msg)
    if msg == "print" or msg == "" then
        BuffQuery:PrintAllAuras()
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
        DEFAULT_CHAT_FRAME:AddMessage("/bq buffs - Show only buffs")
        DEFAULT_CHAT_FRAME:AddMessage("/bq debuffs - Show only debuffs")
    end
end