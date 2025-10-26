-- BuffQuery.lua - Ultra-responsive buff/debuff tracking for WoW 1.12

BuffQuery = {}
BuffQuery.buffs = {}
BuffQuery.debuffs = {}
BuffQuery.callbacks = {}
BuffQuery.initialized = false
BuffQuery.lastUpdate = 0

-- Fast lookup tables
BuffQuery.buffsByName = {}
BuffQuery.debuffsByName = {}

-- Configuration
local FAST_UPDATE_INTERVAL = 0.1 -- 100ms for short buffs
local SLOW_UPDATE_INTERVAL = 1.0 -- 1s fallback
local SHORT_BUFF_THRESHOLD = 10 -- Buffs under 10s get fast tracking

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
}

-- Tooltip for buff name scanning
local scanTooltip = nil

-- Tracking variables
local hasShortBuffs = nil
local updateTimer = 0
local forceUpdate = nil

function BuffQuery:DebugBuff(searchName)
    DEFAULT_CHAT_FRAME:AddMessage("=== Debug: Looking for '" .. searchName .. "' ===")
    
    -- Check current cached buffs
    DEFAULT_CHAT_FRAME:AddMessage("Cached buffs by name:")
    for name, buff in self.buffsByName do
        DEFAULT_CHAT_FRAME:AddMessage("  '" .. name .. "' (slot " .. buff.slot .. ", stacks: " .. buff.stacks .. ")")
        if string.find(string.lower(name), string.lower(searchName)) then
            DEFAULT_CHAT_FRAME:AddMessage("    ^^ PARTIAL MATCH!")
        end
    end
    
    -- Check raw buff slots
    DEFAULT_CHAT_FRAME:AddMessage("Raw buff slots:")
    local slot = 1
    while UnitBuff("player", slot) do
        local texture, stacks = UnitBuff("player", slot)
        if texture then
            -- Get name directly from tooltip
            scanTooltip:ClearLines()
            scanTooltip:SetPlayerBuff(slot)
            local name = BuffQueryTooltipTextLeft1:GetText() or "Unknown"
            
            DEFAULT_CHAT_FRAME:AddMessage("  Slot " .. slot .. ": '" .. name .. "' (stacks: " .. (stacks or 1) .. ")")
            DEFAULT_CHAT_FRAME:AddMessage("    Texture: " .. texture)
            
            if string.find(string.lower(name), string.lower(searchName)) then
                DEFAULT_CHAT_FRAME:AddMessage("    ^^ PARTIAL MATCH!")
            end
        end
        slot = slot + 1
    end
    
    -- Check if it's in our short buffs list
    if SHORT_BUFFS[searchName] then
        DEFAULT_CHAT_FRAME:AddMessage("'" .. searchName .. "' is in SHORT_BUFFS list")
    else
        DEFAULT_CHAT_FRAME:AddMessage("'" .. searchName .. "' is NOT in SHORT_BUFFS list - adding it now")
        SHORT_BUFFS[searchName] = 1
        hasShortBuffs = 1 -- Force fast updates
    end
    
    -- Show update status
    DEFAULT_CHAT_FRAME:AddMessage("Fast updates: " .. (hasShortBuffs and "ENABLED" or "DISABLED"))
    DEFAULT_CHAT_FRAME:AddMessage("Last update: " .. string.format("%.1f", GetTime() - self.lastUpdate) .. "s ago")
end

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
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
    self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
    
    self.eventFrame:SetScript("OnEvent", function()
        BuffQuery:OnEvent(event, arg1)
    end)
    
    -- High-frequency update timer for short buffs
    self.eventFrame:SetScript("OnUpdate", function()
        BuffQuery:OnUpdate()
    end)
    
    -- Initial scan
    self:FullScan()
    self.initialized = 1
end

-- High-frequency update handler
function BuffQuery:OnUpdate()
    local now = GetTime()
    updateTimer = updateTimer + arg1
    
    local shouldUpdate = nil
    
    if arcaneEclipseData and arcaneEclipseData.active and (now - arcaneEclipseData.startTime) > arcaneEclipseData.duration then
        arcaneEclipseData.active = nil
        self.buffsByName["Arcane Eclipse"] = nil
        DEFAULT_CHAT_FRAME:AddMessage("Arcane Eclipse expired (timer)")
        self:FireCallbacks()
    end

    -- Always update if forced
    if forceUpdate then
        shouldUpdate = 1
        forceUpdate = nil
    -- Fast updates if we have short buffs
    elseif hasShortBuffs and updateTimer >= FAST_UPDATE_INTERVAL then
        shouldUpdate = 1
    -- Slow updates as fallback
    elseif updateTimer >= SLOW_UPDATE_INTERVAL then
        shouldUpdate = 1
    end
    
    if shouldUpdate then
        updateTimer = 0
        self:IncrementalUpdate()
    end
end

-- Event handler
function BuffQuery:OnEvent(event, arg1)
    -- if event == "PLAYER_AURAS_CHANGED" then
    --     -- Force immediate update on aura changes
    --     forceUpdate = 1
    -- elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
    --     self:ParseCombatLogBuff(arg1, 1)
    --     forceUpdate = 1
    -- elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
    --     self:ParseCombatLogBuff(arg1, nil)
    --     forceUpdate = 1
    -- elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
    --     self:ParseAuraRemoval(arg1)
    --     forceUpdate = 1
    -- elseif event == "PLAYER_ENTERING_WORLD" then
    --     self:FullScan()
    -- end
    if event == "PLAYER_AURAS_CHANGED" then
        forceUpdate = 1
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        self:ParseCombatLogBuff(arg1, 1)
        self:ParseCombatLogForArcaneEclipse(arg1)
        forceUpdate = 1
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        self:ParseCombatLogBuff(arg1, nil)
        self:ParseCombatLogForArcaneEclipse(arg1)
        forceUpdate = 1
    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        self:ParseAuraRemoval(arg1)
        self:ParseCombatLogForArcaneEclipse(arg1)
        forceUpdate = 1
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:FullScan()
    -- Add more combat log events
    elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then
        self:ParseCombatLogForArcaneEclipse(arg1)
    elseif event == "CHAT_MSG_COMBAT_SELF_HITS" then
        self:ParseCombatLogForArcaneEclipse(arg1)
    end
end

-- Fast buff name lookup with caching
local buffNameCache = {}
local cacheTime = {}
local CACHE_DURATION = 30 -- Cache names for 30 seconds

local function GetBuffName(slot)
    local now = GetTime()
    
    -- Check cache first
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

-- Fast debuff name lookup
local function GetDebuffName(texture, slot)
    return DEBUFF_TEXTURES[texture] or ("Debuff " .. slot)
end

-- Check if we have any short-duration buffs
local function CheckForShortBuffs(buffs)
    for slot, buff in buffs do
        if SHORT_BUFFS[buff.name] then
            return 1
        end
    end
    return nil
end

-- Incremental update with smart frequency adjustment
-- function BuffQuery:IncrementalUpdate()
--     local newBuffs = {}
--     local newDebuffs = {}
--     local newBuffsByName = {}
--     local newDebuffsByName = {}
    
--     -- Quick buff scan
--     local slot = 1
--     while UnitBuff("player", slot) do
--         local texture, stacks = UnitBuff("player", slot)
--         if texture then
--             local name = GetBuffName(slot)
--             local buff = {
--                 name = name,
--                 texture = texture,
--                 stacks = stacks or 1,
--                 slot = slot,
--                 type = "buff",
--                 timestamp = GetTime()
--             }
--             newBuffs[slot] = buff
--             newBuffsByName[name] = buff
--         end
--         slot = slot + 1
--     end
    
--     -- Quick debuff scan
--     slot = 1
--     while UnitDebuff("player", slot) do
--         local texture, stacks, debuffType = UnitDebuff("player", slot)
--         if texture then
--             local name = GetDebuffName(texture, slot)
--             local debuff = {
--                 name = name,
--                 texture = texture,
--                 stacks = stacks or 1,
--                 slot = slot,
--                 debuffType = debuffType or "Unknown",
--                 type = "debuff",
--                 timestamp = GetTime()
--             }
--             newDebuffs[slot] = debuff
--             newDebuffsByName[name] = debuff
--         end
--         slot = slot + 1
--     end
    
--     -- Check if we need fast updates
--     hasShortBuffs = CheckForShortBuffs(newBuffs)
    
--     -- Check for changes
--     local changed = nil
    
--     -- Compare buffs (including stacks and presence)
--     for slot, buff in newBuffs do
--         local oldBuff = self.buffs[slot]
--         if not oldBuff or oldBuff.stacks ~= buff.stacks or oldBuff.name ~= buff.name then
--             changed = 1
--         end
--     end
    
--     for slot, oldBuff in self.buffs do
--         if not newBuffs[slot] then
--             changed = 1
--         end
--     end
    
--     -- Compare debuffs
--     for slot, debuff in newDebuffs do
--         local oldDebuff = self.debuffs[slot]
--         if not oldDebuff or oldDebuff.stacks ~= debuff.stacks or oldDebuff.name ~= debuff.name then
--             changed = 1
--         end
--     end
    
--     for slot, oldDebuff in self.debuffs do
--         if not newDebuffs[slot] then
--             changed = 1
--         end
--     end
    
--     -- Update if changed
--     if changed then
--         self.buffs = newBuffs
--         self.debuffs = newDebuffs
--         self.buffsByName = newBuffsByName
--         self.debuffsByName = newDebuffsByName
--         self.lastUpdate = GetTime()
        
--         -- Periodic cache cleanup
--         if math.random(100) == 1 then
--             local now = GetTime()
--             for slot, time in cacheTime do
--                 if (now - time) > CACHE_DURATION then
--                     buffNameCache[slot] = nil
--                     cacheTime[slot] = nil
--                 end
--             end
--         end
        
--         self:FireCallbacks()
--     end
-- end

function BuffQuery:IncrementalUpdate()
    local newBuffs = {}
    local newDebuffs = {}
    local newBuffsByName = {}
    local newDebuffsByName = {}
    
    -- Preserve existing special buffs FIRST
    for name, buff in self.buffsByName do
        if buff.source == "combat_log" then
            newBuffsByName[name] = buff
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Preserved special buff: " .. name)
        end
    end
    
    -- Then scan normal buffs
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
    
    -- Scan debuffs (unchanged)
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
    
    -- Update tables
    self.buffs = newBuffs
    self.debuffs = newDebuffs
    self.buffsByName = newBuffsByName
    self.debuffsByName = newDebuffsByName
    
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: IncrementalUpdate completed, buffsByName has " .. 
        self:CountTable(self.buffsByName) .. " entries")
end

-- Full scan (used on initialization and manual refresh)
function BuffQuery:FullScan()
    -- Clear all caches
    buffNameCache = {}
    cacheTime = {}
    forceUpdate = 1
end

-- Parse combat log for better names and immediate updates
function BuffQuery:ParseCombatLogBuff(message, isBuff)
    local _, _, spellName = string.find(message, "You .* ([^%(%.]+)")
    if spellName then
        spellName = string.gsub(spellName, "%s+$", "")
        
        -- Mark as short buff if it's known to be short
        if isBuff and not SHORT_BUFFS[spellName] then
            -- Auto-detect potential short buffs based on common patterns
            if string.find(spellName, "Potion") or 
               string.find(spellName, "Elixir") or
               string.find(spellName, "Flask") or
               string.find(spellName, "Scroll") then
                -- These are usually longer, don't mark as short
            else
                -- Could be a short buff, enable fast tracking temporarily
                hasShortBuffs = 1
            end
        end
        
        self:UpdateTextureMapping(spellName, isBuff)
    end
end

-- Parse aura removal for immediate updates
function BuffQuery:ParseAuraRemoval(message)
    local _, _, spellName = string.find(message, "([^%s]+) fades from you")
    if spellName then
        -- Force immediate update when auras fade
        forceUpdate = 1
    end
end

-- Update texture mapping from combat log
function BuffQuery:UpdateTextureMapping(spellName, isBuff)
    if not isBuff then
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

-- Callback system
function BuffQuery:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

function BuffQuery:FireCallbacks()
    for i, callback in self.callbacks do
        callback()
    end
end

-- Add a buff to short tracking list
function BuffQuery:AddShortBuff(buffName)
    SHORT_BUFFS[buffName] = 1
end

-- API functions (same as before but with improved responsiveness)
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

-- function BuffQuery:HasBuff(buffName)
--     -- return self.buffsByName[buffName]
--     local buff = self.buffsByName[buffName]
--     if buff then
--         -- For special buffs, verify they haven't expired
--         if buff.source == "combat_log" and buff.duration then
--             local elapsed = GetTime() - buff.timestamp
--             if elapsed > buff.duration then
--                 -- Expired, clean up
--                 self.buffsByName[buffName] = nil
--                 if self.specialBuffs then
--                     self.specialBuffs[buffName] = nil
--                 end
--                 return nil
--             end
--         end
--         return buff
--     end
    
--     return nil
-- end

function BuffQuery:HasBuff(buffName)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: HasBuff called with '" .. buffName .. "'")
    
    -- Check if buffsByName table exists
    if not self.buffsByName then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: ERROR - buffsByName table doesn't exist!")
        self.buffsByName = {}
        return nil
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: buffsByName table exists, checking contents...")
    
    -- List all keys in buffsByName for debugging
    local count = 0
    for key, value in self.buffsByName do
        count = count + 1
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: buffsByName['" .. key .. "'] exists")
        if key == buffName then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: EXACT MATCH FOUND!")
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Total buffs in buffsByName: " .. count)
    
    -- Direct lookup
    local buff = self.buffsByName[buffName]
    if buff then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Direct lookup SUCCESS")
        
        -- Check if it's expired (for special buffs)
        if buff.source == "combat_log" and buff.duration then
            local elapsed = GetTime() - buff.timestamp
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Special buff elapsed time: " .. string.format("%.1f", elapsed) .. "s")
            
            if elapsed > buff.duration then
                DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Special buff EXPIRED, removing")
                self.buffsByName[buffName] = nil
                return nil
            end
        end
        
        return buff
    else
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Direct lookup FAILED")
        
        -- Check arcaneEclipseData as fallback
        if buffName == "Arcane Eclipse" and arcaneEclipseData and arcaneEclipseData.active then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Found in arcaneEclipseData, checking expiry...")
            local elapsed = GetTime() - arcaneEclipseData.startTime
            if elapsed <= arcaneEclipseData.duration then
                DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Creating fallback buff data")
                -- Create and return fallback data
                local fallback = {
                    name = "Arcane Eclipse",
                    stacks = 1,
                    type = "special",
                    source = "combat_log_fallback"
                }
                return fallback
            else
                DEFAULT_CHAT_FRAME:AddMessage("DEBUG: arcaneEclipseData expired")
            end
        end
    end
    
    return nil
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

-- Debug functions
function BuffQuery:PrintAllAuras()
    DEFAULT_CHAT_FRAME:AddMessage("=== Current Player Auras ===")
    DEFAULT_CHAT_FRAME:AddMessage("Update mode: " .. (hasShortBuffs and "FAST (100ms)" or "NORMAL (1s)"))
    DEFAULT_CHAT_FRAME:AddMessage("Last update: " .. string.format("%.1f", GetTime() - self.lastUpdate) .. "s ago")
    
    local buffCount = self:GetBuffCount()
    local debuffCount = self:GetDebuffCount()
    
    if buffCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Buffs (" .. buffCount .. "):")
        for slot, buff in self.buffs do
            local stackText = buff.stacks > 1 and (" x" .. buff.stacks) or ""
            local shortText = SHORT_BUFFS[buff.name] and " [SHORT]" or ""
            DEFAULT_CHAT_FRAME:AddMessage("  " .. buff.name .. stackText .. shortText)
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

function BuffQuery:HasBuffFuzzy(buffName)
    -- Try exact match first
    local exact = self.buffsByName[buffName]
    if exact then return exact end
    
    -- Try case-insensitive partial match
    local lowerSearch = string.lower(buffName)
    for name, buff in self.buffsByName do
        if string.find(string.lower(name), lowerSearch) then
            return buff
        end
    end
    
    return nil
end

function BuffQuery:DebugArcaneEclipse()
    DEFAULT_CHAT_FRAME:AddMessage("=== Debug: Searching for Arcane Eclipse everywhere ===")
    
    -- Check normal buffs (we already know it's not here, but let's confirm)
    DEFAULT_CHAT_FRAME:AddMessage("1. Normal buff slots:")
    local slot = 1
    local foundInBuffs = nil
    while UnitBuff("player", slot) do
        local texture, stacks = UnitBuff("player", slot)
        if texture then
            scanTooltip:ClearLines()
            scanTooltip:SetPlayerBuff(slot)
            local name = BuffQueryTooltipTextLeft1:GetText() or "Unknown"
            DEFAULT_CHAT_FRAME:AddMessage("  Slot " .. slot .. ": '" .. name .. "'")
            if string.find(string.lower(name), "eclipse") or string.find(string.lower(name), "arcane") then
                foundInBuffs = 1
                DEFAULT_CHAT_FRAME:AddMessage("    ^^ FOUND ECLIPSE/ARCANE!")
            end
        end
        slot = slot + 1
    end
    if not foundInBuffs then
        DEFAULT_CHAT_FRAME:AddMessage("  No eclipse/arcane buffs found in normal slots")
    end
    
    -- Check weapon enchants (main hand and off hand)
    DEFAULT_CHAT_FRAME:AddMessage("2. Weapon enchants:")
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
    
    if hasMainHandEnchant then
        DEFAULT_CHAT_FRAME:AddMessage("  Main hand enchant: " .. (mainHandExpiration or 0) .. "ms remaining, " .. (mainHandCharges or 0) .. " charges")
    else
        DEFAULT_CHAT_FRAME:AddMessage("  No main hand enchant")
    end
    
    if hasOffHandEnchant then
        DEFAULT_CHAT_FRAME:AddMessage("  Off hand enchant: " .. (offHandExpiration or 0) .. "ms remaining, " .. (offHandCharges or 0) .. " charges")
    else
        DEFAULT_CHAT_FRAME:AddMessage("  No off hand enchant")
    end
    
    -- Check if it appears in any tooltip when hovering over weapon
    DEFAULT_CHAT_FRAME:AddMessage("3. Try hovering over your weapon to see if Arcane Eclipse appears in tooltip")
    
    -- Set up combat log monitoring
    DEFAULT_CHAT_FRAME:AddMessage("4. Combat log monitoring enabled - watch for Arcane Eclipse messages")
end

-- Enhanced combat log parser specifically for Arcane Eclipse
local arcaneEclipseData = {
    active = nil,
    startTime = 0,
    duration = 15, -- Assume 15 seconds
    lastSeen = 0
}

function BuffQuery:ParseCombatLogForArcaneEclipse(message)
    local now = GetTime()
    
    -- Look for gain messages
    if string.find(message, "Arcane Eclipse") then
        DEFAULT_CHAT_FRAME:AddMessage("COMBAT LOG: " .. message)
        
        if string.find(message, "You gain") or string.find(message, "You are affected") then
            arcaneEclipseData.active = 1
            arcaneEclipseData.startTime = now
            arcaneEclipseData.lastSeen = now
            DEFAULT_CHAT_FRAME:AddMessage("Arcane Eclipse GAINED via combat log")
            
            -- Add to our tracking as a special case
            self.buffsByName["Arcane Eclipse"] = {
                name = "Arcane Eclipse",
                texture = "Interface\\Icons\\Spell_Arcane_Arcane01", -- Guess
                stacks = 1,
                slot = -1, -- Special slot for non-buff effects
                type = "special",
                timestamp = now,
                duration = 15,
                source = "combat_log"
            }
            self:FireCallbacks()
            
        elseif string.find(message, "fades") or string.find(message, "removed") then
            arcaneEclipseData.active = nil
            DEFAULT_CHAT_FRAME:AddMessage("Arcane Eclipse REMOVED via combat log")
            
            -- Remove from tracking
            self.buffsByName["Arcane Eclipse"] = nil
            self:FireCallbacks()
        end
    end
end

-- function BuffQuery:ParseCombatLogForArcaneEclipse(message)
--     local now = GetTime()
    
--     if string.find(message, "Arcane Eclipse") then
--         DEFAULT_CHAT_FRAME:AddMessage("COMBAT LOG: " .. message)
        
--         if string.find(message, "You gain") or string.find(message, "You are affected") then
--             arcaneEclipseData.active = 1
--             arcaneEclipseData.startTime = now
--             arcaneEclipseData.lastSeen = now
            
--             -- Create proper buff entry
--             local buffData = {
--                 name = "Arcane Eclipse",
--                 texture = "Interface\\Icons\\Spell_Arcane_Arcane01",
--                 stacks = 1,
--                 slot = -1, -- Special slot
--                 type = "special",
--                 timestamp = now,
--                 duration = 15,
--                 source = "combat_log"
--             }
            
--             -- Store in BOTH places for consistency
--             self.buffsByName["Arcane Eclipse"] = buffData
--             -- Also store in a special buffs table
--             if not self.specialBuffs then
--                 self.specialBuffs = {}
--             end
--             self.specialBuffs["Arcane Eclipse"] = buffData
            
--             DEFAULT_CHAT_FRAME:AddMessage("Arcane Eclipse added to tracking")
--             self:FireCallbacks()
            
--         elseif string.find(message, "fades") or string.find(message, "removed") then
--             arcaneEclipseData.active = nil
            
--             -- Remove from BOTH places
--             self.buffsByName["Arcane Eclipse"] = nil
--             if self.specialBuffs then
--                 self.specialBuffs["Arcane Eclipse"] = nil
--             end
            
--             DEFAULT_CHAT_FRAME:AddMessage("Arcane Eclipse removed from tracking")
--             self:FireCallbacks()
--         end
--     end
-- end
function BuffQuery:ParseCombatLogForArcaneEclipse(message)
    local now = GetTime()
    
    if string.find(message, "Arcane Eclipse") then
        DEFAULT_CHAT_FRAME:AddMessage("COMBAT LOG: " .. message)
        
        if string.find(message, "You gain") or string.find(message, "You are affected") then
            arcaneEclipseData.active = 1
            arcaneEclipseData.startTime = now
            arcaneEclipseData.lastSeen = now
            
            -- Create proper buff entry
            local buffData = {
                name = "Arcane Eclipse",
                texture = "Interface\\Icons\\Spell_Arcane_Arcane01",
                stacks = 1,
                slot = -1,
                type = "special",
                timestamp = now,
                duration = 15,
                source = "combat_log"
            }
            
            -- EXPLICIT storage with debug
            self.buffsByName["Arcane Eclipse"] = buffData
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Stored Arcane Eclipse in buffsByName")
            
            -- Verify it was stored
            local verify = self.buffsByName["Arcane Eclipse"]
            if verify then
                DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Verification successful - buff stored")
                DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Stored name: '" .. verify.name .. "'")
            else
                DEFAULT_CHAT_FRAME:AddMessage("DEBUG: ERROR - buff NOT stored!")
            end
            
            self:FireCallbacks()
            
        elseif string.find(message, "fades") or string.find(message, "removed") then
            arcaneEclipseData.active = nil
            self.buffsByName["Arcane Eclipse"] = nil
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Removed Arcane Eclipse from buffsByName")
            self:FireCallbacks()
        end
    end
end

function BuffQuery:DebugHasBuff(buffName)
    DEFAULT_CHAT_FRAME:AddMessage("=== Debug HasBuff('" .. buffName .. "') ===")
    
    -- Check buffsByName directly
    local directLookup = self.buffsByName[buffName]
    DEFAULT_CHAT_FRAME:AddMessage("Direct buffsByName lookup: " .. (directLookup and "FOUND" or "NOT FOUND"))
    
    if directLookup then
        DEFAULT_CHAT_FRAME:AddMessage("  Name: " .. directLookup.name)
        DEFAULT_CHAT_FRAME:AddMessage("  Source: " .. (directLookup.source or "normal"))
        DEFAULT_CHAT_FRAME:AddMessage("  Slot: " .. directLookup.slot)
        if directLookup.timestamp then
            DEFAULT_CHAT_FRAME:AddMessage("  Age: " .. string.format("%.1f", GetTime() - directLookup.timestamp) .. "s")
        end
    end
    
    -- Check arcaneEclipseData specifically for Arcane Eclipse
    if buffName == "Arcane Eclipse" then
        DEFAULT_CHAT_FRAME:AddMessage("Arcane Eclipse data:")
        DEFAULT_CHAT_FRAME:AddMessage("  Active: " .. (arcaneEclipseData.active and "YES" or "NO"))
        if arcaneEclipseData.active then
            local elapsed = GetTime() - arcaneEclipseData.startTime
            local remaining = arcaneEclipseData.duration - elapsed
            DEFAULT_CHAT_FRAME:AddMessage("  Started: " .. string.format("%.1f", elapsed) .. "s ago")
            DEFAULT_CHAT_FRAME:AddMessage("  Remaining: " .. string.format("%.1f", remaining) .. "s")
        end
    end
    
    -- Test HasBuff function
    local result = self:HasBuff(buffName)
    DEFAULT_CHAT_FRAME:AddMessage("HasBuff() result: " .. (result and "FOUND" or "NOT FOUND"))
    
    if result then
        DEFAULT_CHAT_FRAME:AddMessage("  Returned buff name: " .. result.name)
        DEFAULT_CHAT_FRAME:AddMessage("  Returned buff source: " .. (result.source or "normal"))
    end
end

function BuffQuery:CountTable(t)
    local count = 0
    for k, v in t do
        count = count + 1
    end
    return count
end
-- Add to slash commands
SLASH_BUFFQUERY1 = "/buffquery"
SLASH_BUFFQUERY2 = "/bq"

SlashCmdList["BUFFQUERY"] = function(msg)
    BuffQuery:Initialize()
    
    if msg == "print" or msg == "" then
        BuffQuery:PrintAllAuras()
    elseif msg == "eclipse" then
        BuffQuery:DebugArcaneEclipse()
    elseif msg == "rescan" then
        BuffQuery:FullScan()
        DEFAULT_CHAT_FRAME:AddMessage("Full rescan completed")
    elseif string.find(msg, "debug ") then
        local buffName = string.gsub(msg, "debug ", "")
        BuffQuery:DebugBuff(buffName)
    elseif string.find(msg, "testbuff ") then
        local buffName = string.gsub(msg, "testbuff ", "")
        BuffQuery:DebugHasBuff(buffName)
    elseif string.find(msg, "short ") then
        local buffName = string.gsub(msg, "short ", "")
        BuffQuery:AddShortBuff(buffName)
        DEFAULT_CHAT_FRAME:AddMessage("Added '" .. buffName .. "' to short buff list")
    else
        DEFAULT_CHAT_FRAME:AddMessage("BuffQuery commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/bq print - Show all cached auras")
        DEFAULT_CHAT_FRAME:AddMessage("/bq debug <name> - Debug specific buff")
        DEFAULT_CHAT_FRAME:AddMessage("/bq eclipse - Debug Arcane Eclipse specifically")
        DEFAULT_CHAT_FRAME:AddMessage("/bq rescan - Force full rescan")
        DEFAULT_CHAT_FRAME:AddMessage("/bq short <name> - Add buff to short tracking list")
    end
end

-- Auto-initialize
BuffQuery:Initialize()