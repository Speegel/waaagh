--------------------------------------------------
--
-- Handle kick commands
--
--------------------------------------------------

function Waaag_BattleShout()
    -- Battle Shout
    if UnitMana("player") >= 10 and not HasBuff("player", "Ability_Warrior_BattleShout") then
        Debug("03. Berserker : Battle Shout")
        CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
        WaaaghLastBattleShoutCast = GetTime()
        return true
    else
        Debug("03. Berserker : Battle Shout -> Not enough rage")
        WaaaghLastBattleShoutCast = GetTime() - 110
        return false
    end
end

function Waaagh_Shouts()
    -- Bloodrage
    if UnitMana("player") <= 65 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 40 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        Debug("46. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
        return
    end


    if WaaaghLastBattleShoutCast then
        if (GetTime() - WaaaghLastBattleShoutCast) > 110 then
            Debug("Last Battle shout has been applied 110s --> renew")
            Waaag_BattleShout()
        end
    end
end

function Zerk_Base()
    if GetActiveStance() ~= 3 then DoShapeShift(3) end

    local overpower_usable, overpower_oom = IsUsableAction(GetTextureID("Ability_MeleeDamage"))

    -- 1, Auto attack closest target
    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
        return
    end

    -- Bloodthirst
    if WaaaghAttack and WaaaghBloodthirst and UnitMana("player") >= 30 and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        Debug("23. Bloodthirst")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        return
    end
end

function Waagh_Kick()
    if HasShield() then
        if GetActiveStance() ~= 2 then
            Debug("14. Shift to Def for Shield Bash")
            DoShapeShift(2)
        end
        if IsSpellReady(ABILITY_SHIELD_BASH_WAAAGH) then
            Debug("112. Shield bashing the dude")
            CastSpellByName(ABILITY_SHIELD_BASH_WAAAGH)
        end
    else
        if GetActiveStance() ~= 3 then
            Debug("13. Shift to Berserker Stance (Pummel)")
            DoShapeShift(3)
        end
        if IsSpellReady(ABILITY_PUMMEL_WAAAGH) then
            Debug("112. Pummling the dude")
            CastSpellByName(ABILITY_PUMMEL_WAAAGH)
        end
    end
end

function GetTextureID(name)
    local Slot_Id = 0
    for id = 1, 120 do
        local texture = GetActionTexture(id)
        if texture and string.find(texture, name) then
            Slot_Id = id
        end
    end
    return Slot_Id
end

function HazDebuff(unit, debuffName)
    for i = 1, 64 do
        local effect, rank, texture, stacks, dtype, duration, timeleft = pfUI.env.libdebuff:UnitDebuff(unit, i)
        if texture and string.find(texture, debuffName) then
            return stacks, duration, timeleft
        end
    end
    return 0, nil, nil
end

function DoSunder(stack)
    local IsSunderArmorReady = IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH)
    local sunder_stacks, sunder_duration, sunder_timeleft = HazDebuff("target", "Ability_Warrior_Sunder")

    if stack == 0 then
        Debug("Stack is set to 0")
        return
    end

    if not sunder_stacks then return end
    if not WaaaghAttack then return end

    if sunder_stacks == 0 then
        if UnitMana("player") >= 15 and IsSunderArmorReady then -- Sunder is not on the target
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
        end
    end

    if sunder_stacks < stack and UnitMana("player") >= 15 and IsSunderArmorReady then
        CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
        WaaaghLastSunder = GetTime()
    end

    if sunder_stacks >= stack then
        if WaaaghLastSunder then
            if (GetTime() - WaaaghLastSunder) >= 20 and (GetTime() - WaaaghLastSunder) <= 30 and IsSunderArmorReady then
                Debug("Sunder Armor on [ %t ] is timing out in less than 10 sec --> refresh")
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                WaaaghLastSunder = GetTime()
            elseif (GetTime() - WaaaghLastSunder) > 0 and (GetTime() - WaaaghLastSunder) < 20 then
                -- do nothing
            else
                WaaaghLastSunder = nil
            end
        else
            if IsSunderArmorReady then
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                WaaaghLastSunder = GetTime()
            end
        end
    end
    return
end

function Waaagh_LipAoeTaunt()
    UseContainerItemByNameOnPlayer(ITEM_CONS_LIMITED_INVULNERABILITY)
    CastSpellByName(ABILITY_CHALLENGING_SHOUT_WAAAGH)
end

function Waaagh_Charge()
    local dist = Waaagh_Distance()
    if WaaaghMount
        and dist <= 25 then
        -- Dismount as a first step
        Debug("Dismounting")
        Dismount()
        WaaaghMount = nil
    end
    if WaaaghCombat then
        if UnitIsPlayer("target") then
            if GetActiveStance() == 2
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERVENE_WAAAGH) then
                Debug("C1. Intervene")
                CastSpellByName(ABILITY_INTERVENE_WAAAGH)
                WaaaghLastChargeCast = GetTime()
            else
                Debug("C4. Switch def Stance for intervene")
                DoShapeShift(2)
            end
        else
            if GetActiveStance() == 3
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
                Debug("C2. Intercept")
                CastSpellByName(ABILITY_INTERCEPT_WAAAGH)
                WaaaghLastChargeCast = GetTime()
            elseif GetActiveStance() ~= 3
                and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
                Debug("C5. Berserker Stance (Intercept)")
                DoShapeShift(3)
            end
        end
    else
        if UnitIsPlayer("target") then
            if GetActiveStance() == 2
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERVENE_WAAAGH) then
                Debug("O3. Intervene")
                CastSpellByName(ABILITY_INTERVENE_WAAAGH)
                WaaaghLastChargeCast = GetTime()
            else
                Debug("O4. Switch def Stance for intervene")
                DoShapeShift(2)
            end
        else
            if GetActiveStance() == 1
                and IsSpellReady(ABILITY_CHARGE_WAAAGH) then
                Debug("O1. Charge")
                CastSpellByName(ABILITY_CHARGE_WAAAGH)
                WaaaghLastChargeCast = GetTime()
            elseif GetActiveStance() == 3
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
                Debug("O2. Intercept")
                CastSpellByName(ABILITY_INTERCEPT_WAAAGH)
            elseif GetActiveStance() ~= 1
                and IsSpellReady(ABILITY_CHARGE_WAAAGH) then
                Debug("O4. Switch Battle Stance for Charge")
                DoShapeShift(1)
            end
        end
    end
end

-- This function uses a Sharp stone on MainHand and, if equipped, the OffHand
function Oogla_SharpenOff(oStone)
    oBag, oSlot, oItemExists = Oogla_FindItem(oStone);
    if (oItemExists) then
        UseContainerItem(oBag, oSlot);
        PickupInventoryItem(17);
        oSharpenOffHand = false;
    end
end

-- This function finds an item in your bag and returns oBag,oSlot,oItemExists
function Oogla_FindItem(oItem)
    local oItemExists = false
    for oBag = 0, 4 do
        for oSlot = 1, GetContainerNumSlots(oBag) do
            if (GetContainerItemLink(oBag, oSlot)) then
                if (string.find(GetContainerItemLink(oBag, oSlot), oItem)) then
                    oItemExists = true
                    return oBag, oSlot, oItemExists;
                end
            end
        end
    end
end

-- Checks if the player can cast a spell (gcd, cooldown, etc)
function CanCastSpell(spellName)
    return (select(1, GetSpellCooldownByName(spellName)) == 0)
    --
end

-- Get target health percent
function TargetHealthPercent()
    return (UnitHealth("target") / UnitHealthMax("target") * 100)
    --
end

function GetSpellID(name, booktype)
    if booktype == nil then
        booktype = BOOKTYPE_SPELL;
    end

    local i = 1;
    local spellName, spellRank = GetSpellName(i, booktype);

    while (spellName ~= nil) do
        if (spellName == name) then
            return i;
        else
            i = i + 1;
            spellName, spellRank = GetSpellName(i, booktype);
        end
    end
end

function GetSpellCooldownByName(name, booktype)
    if booktype == nil then
        booktype = BOOKTYPE_SPELL;
    end

    name = string.gsub(name, "%(Rank %d+%)", "");

    local spellID = GetSpellID(name);
    local StartTime, Duration, Enable = GetSpellCooldown(spellID, booktype);
    return Duration;
end

-- Create a simple tooltip for scanning
local scanTooltip = CreateFrame("GameTooltip", "BuffScanTooltip")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

function GetBuffNameFromSlot(buffSlot)
    scanTooltip:ClearLines()
    scanTooltip:SetPlayerBuff(buffSlot)
    message(scanTooltip:NumLines())
    -- In vanilla, we need to check if the tooltip has text
    if scanTooltip:NumLines() > 0 then
        local fontString = getglobal("BuffScanTooltipTextLeft1")
        if fontString then
            message("name: " .. fontString:GetText())
            return fontString:GetText()
        end
    end
    
    return nil
end

function FindPlayerBuff(buffName)
    local i = 1

    while true do
        local buffTexture = GetPlayerBuffTexture(i)

        if not buffTexture then
            break
        end

        if name and string.lower(name) == string.lower(buffName) then
            local timeLeft = GetPlayerBuffTimeLeft(i) or 0
            local applications = GetPlayerBuffApplications(i) or 1

            return {
                present = true,
                stacks = applications,
                timeLeft = timeLeft,
                name = name
            }
        end

        i = i + 1
    end

    return {
        present = false,
        stacks = 0,
        timeLeft = 0,
        name = nil
    }
end

-- Smart Consume Function for WoW 1.12 - Enhanced with eating/drinking checks
function WaaaghSmartConsume()
    -- Check if player is already eating or drinking
    local function scIsEating()
        -- Check for eating/drinking buffs
        local i = 1
        while UnitBuff("player", i) do
            local buffTexture = UnitBuff("player", i)
            if buffTexture then

                -- DEFAULT_CHAT_FRAME:AddMessage(buffTexture)
 
                -- Common eating/drinking buff textures in vanilla
                local eatingDrinkingTextures = {
                    "Interface\\Icons\\Ability_Creature_Cursed_02", -- Food
                    "Interface\\Icons\\INV_Misc_Fork&Knife", -- Food
                    "Interface\\Icons\\INV_Misc_Food_15", -- Food
                    "Interface\\Icons\\INV_Misc_Food_28", -- Food
                    "Interface\\Icons\\INV_Misc_Food_32", -- Food
                }

                for _, texture in ipairs(eatingDrinkingTextures) do
                    if string.find(buffTexture, texture) then
                        return true
                    end
                end
            end
            i = i + 1
        end

        -- Alternative check: look for "Food" or "Drink" in buff tooltips
        i = 1
        while UnitBuff("player", i) do
            GameTooltip:SetUnitBuff("player", i)
            local tooltipText = GameTooltipTextLeft1:GetText()
            if tooltipText then
                if string.find(tooltipText, "Food") or 
                   string.find(tooltipText, "Eating") then
                    return true
                end
            end
            i = i + 1
        end

        return false
    end

    local function scIsDrinking()
        -- Check for eating/drinking buffs
        local i = 1
        while UnitBuff("player", i) do
            local buffTexture = UnitBuff("player", i)
            if buffTexture then
                -- Common eating/drinking buff textures in vanilla
                local eatingDrinkingTextures = {
                    "Interface\\Icons\\INV_Drink_07",     -- Drinking
                    "Interface\\Icons\\INV_Drink_10",     -- Drinking  
                    "Interface\\Icons\\INV_Drink_11",     -- Drinking
                    "Interface\\Icons\\INV_Drink_17",     -- Drinking
                    "Interface\\Icons\\INV_Drink_18",     -- Drinking
                    "Interface\\Icons\\INV_Drink_19",     -- Drinking
                }
                
                for _, texture in ipairs(eatingDrinkingTextures) do
                    if string.find(buffTexture, texture) then
                        return true
                    end
                end
            end
            i = i + 1
        end
        
        -- Alternative check: look for "Food" or "Drink" in buff tooltips
        i = 1
        while UnitBuff("player", i) do
            GameTooltip:SetUnitBuff("player", i)
            local tooltipText = GameTooltipTextLeft1:GetText()
            if tooltipText then
                if string.find(tooltipText, "Drink") or
                   string.find(tooltipText, "Drinking") then
                    return true
                end
            end
            i = i + 1
        end
        
        return false
    end
   
    -- Define conjured food items
    local conjuredFood = {
        "Conjured Mana Orange",
        "Conjured Mana Biscuit",
        "Conjured Sweet Roll",
        "Conjured Bread",
        "Conjured Pumpernickel",
        "Conjured Sourdough",
        "Conjured Rye"
    }
    
    -- Define conjured drink items
    local conjuredDrink = {
        "Conjured Water",
        "Conjured Fresh Water",
        "Conjured Purified Water",
        "Conjured Spring Water",
        "Conjured Mineral Water",
        "Conjured Sparkling Water",
        "Conjured Crystal Water"
    }
    
    -- Define regular food items
    local regularFood = {
        "Raw Black Truffle",
        "Sweet Nectar",
        "Bread",
        "Brown Bread",
        "Fresh Bread",
        "Moist Cornbread",
        "Dalaran Sharp",
        "Dwarven Mild",
        "Alterac Swiss",
        "Goldenbark Apple",
        "Red-speckled Mushroom",
        "Forest Mushroom Cap",
        "Spongy Morel"
    }
    
    -- Define regular drink items  
    local regularDrink = {
        "Moonberry Juice",
        "Sweet Nectar",
        "Ice Cold Milk",
        "Refreshing Spring Water",
        "Bottled Water",
        "Filtered Water",
        "Distilled Water",
        "Purified Water"
    }
    
    -- Clear modifier keys to prevent stack splitting
    -- local function clearModifiers()
    --     -- Store current modifier states
    --     local wasShiftDown = IsShiftKeyDown()
    --     local wasCtrlDown = IsControlKeyDown()
    --     local wasAltDown = IsAltKeyDown()
        
    --     -- Temporarily clear modifiers
    --     if wasShiftDown then
    --         RunScript("this.wasShiftDown = true")
    --     end
    --     if wasCtrlDown then
    --         RunScript("this.wasCtrlDown = true") 
    --     end
    --     if wasAltDown then
    --         RunScript("this.wasAltDown = true")
    --     end
        
    --     -- Return restore function
    --     return function()
    --         -- Modifiers will naturally restore when keys are released
    --         -- This is just for completeness
    --     end
    -- end

    -- Function to find and use item
    local function scUseItem(itemList)
        for _, itemName in ipairs(itemList) do
            for bag = 0, 4 do
                local numSlots = GetContainerNumSlots(bag)
                if numSlots and numSlots > 0 then
                    for slot = 1, numSlots do
                        local texture, itemCount = GetContainerItemInfo(bag, slot)
                        if texture and itemCount and itemCount > 0 then
                            local itemLink = GetContainerItemLink(bag, slot)
                            if itemLink then
                                local _, _, itemString = string.find(itemLink, "item:([%-?%d:]+)")
                                if itemString then
                                    local name = GetItemInfo("item:"..itemString)
                                    if name and name == itemName then
                                        -- local restoreModifiers = clearModifiers()
                                        -- UseContainerItem(bag, slot)
                                        -- restoreModifiers()
                                        if UseItemByName then
                                            UseItemByName(itemName)
                                            return true
                                        end
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end
    
    -- Determine what lists to use based on consumeType parameter
    local foodItemLists = {}
    local drinktemLists = {}

    table.insert(foodItemLists, conjuredFood)
    table.insert(foodItemLists, regularFood)
    table.insert(drinktemLists, conjuredDrink)
    table.insert(drinktemLists, regularDrink)

    -- Check if already consuming
    if scIsEating() then
        -- DEFAULT_CHAT_FRAME:AddMessage("Already eating!")
        if scIsDrinking() then
            -- DEFAULT_CHAT_FRAME:AddMessage("Already drinking!")
            return
        else
            -- Try each list in order until something is used
            for _, itemList in ipairs(drinktemLists) do
                if scUseItem(itemList) then
                    return
                end
            end
        end
    else
        -- Try each list in order until something is used
        for _, itemList in ipairs(foodItemLists) do
            if scUseItem(itemList) then
                return
            end
        end
    end

    -- Nothing found
    DEFAULT_CHAT_FRAME:AddMessage("No consumables found!")
end
