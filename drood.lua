-- local recentBuffs = {}

-- -- Function to parse combat log
-- local function OnCombatLogEvent()
--     local message = arg1
    
--     -- Look for buff gain messages like "You gain Power Word: Fortitude"
--     local buffName = string.match(message, "You gain (.+)%.")
--     if buffName then
--         recentBuffs[buffName] = GetTime()
--     end
-- end

-- -- Hook the combat log
-- local frame = CreateFrame("Frame")
-- frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
-- frame:SetScript("OnEvent", OnCombatLogEvent)

-- function FindPlayerBuffWithLog(buffName)
--     local i = 1
    
--     while true do
--         local buffTexture = GetPlayerBuffTexture(i)
--         if not buffTexture then break end
        
--         local timeLeft = GetPlayerBuffTimeLeft(i) or 0
--         local applications = GetPlayerBuffApplications(i) or 1
        
--         -- Check if this buff was recently applied according to combat log
--         if recentBuffs[buffName] and (GetTime() - recentBuffs[buffName]) < 5 then
--             -- Assume this is the buff we're looking for if it matches our recent log
--             return {
--                 present = true,
--                 stacks = applications,
--                 timeLeft = timeLeft,
--                 name = buffName
--             }
--         end
        
--         i = i + 1
--     end
    
--     return {present = false, stacks = 0, timeLeft = 0, name = nil}
-- end

function DroodCat()

    local isBehind = UnitXP("behind", "player", "target")

    -- 1, Auto attack closest target
    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
        return
    end

    if WaaaghAttack and not HasDebuff("target","Spell_Nature_FaerieFire") then
        CastSpellByName("Faerie Fire (Feral)()")
        return
    end

    if WaaaghAttack and UnitMana("player") >= 30 and not HasBuff("player", "Ability_Mount_JungleTiger") then
        CastSpellByName("Tiger's Fury")
        return
    end

    if isBehind then
        if WaaaghAttack and UnitMana("player") >= 48 and IsSpellReady("Shred") then
            CastSpellByName("Shred")
            return
        end
    else
        if WaaaghAttack and UnitMana("player") >= 40 and IsSpellReady("Claw") then
            CastSpellByName("Claw")
            return
        end
    end
end

function BoomkinDot()
    local MoonfireParams = {
        refreshtime=2,
        priotarget,
        name=arcane
    }
    local LastInsectSwarmParams = {
        refreshtime=2,
        priotarget,
        minhp=10000
    }
    if not Cursive:Multicurse("Moonfire","RAID_MARK", MoonfireParams) then
        Cursive:Multicurse("Insect Swarm","RAID_MARK", LastInsectSwarmParams)
    end
end

function BoomkinDotInsectSwarm()
    local LastInsectSwarmParams = {
        refreshtime=2,
        priotarget,
        minhp=100
    }
    Cursive:Multicurse("Insect Swarm","RAID_MARK", LastInsectSwarmParams)
end

function GetDotTimeLeft(SpellName)

    local _, guid = UnitExists("target")
    local data = Cursive.curses:GetCurseData(SpellName, guid)
    if data then
        local DotTimeLeft = Cursive.curses:TimeRemaining(data)
        return DotTimeLeft
    end
    
    return 0

end

function BoomkinWrath()
    CastSpellByName("Wrath")
end


function BoomkinStarfire()
    CastSpellByName("Starfire")
end

function Boomkin()
    local HasArcaneEclipse = BuffQuery:HasBuff ("Arcane Eclipse")
    local HasArcaneSolstice = BuffQuery:HasDebuff("Arcane Solstice")
    local HasNaturalBoon = BuffQuery:HasBuff("Natural Boon")
    local HasNaturalSolstice = BuffQuery:HasDebuff("Natural Solstice")
    local HasNatureEclipse = BuffQuery:HasBuff("Nature Eclipse")
    local HasNatureGrace = BuffQuery:HasBuff("Nature's Grace")

    if GetSpellCooldownByName("Moonfire") == 0 then
        if GetDotTimeLeft("Moonfire") <= 1 then
            CastSpellByName("Moonfire")
            return
        end
        if GetDotTimeLeft("Insect Swarm") <= 1 then
            CastSpellByName("Insect Swarm")
            return
        end
        if HasArcaneEclipse then
            CastSpellByName("Starfire")
            return
        end
        if HasNatureEclipse then
            CastSpellByName("Wrath")
            return
        end
        if HasNaturalSolstice and not HasArcaneSolstice then
            CastSpellByName("Starfire")
            return
        end
        CastSpellByName("Wrath")

    end
end

function DroodCatBleed()
    UnitXP("behindThreshold", "set", 2)

    local isBehind = UnitXP("behind", "player", "target")

    local PlayerHasClearCast = HasBuff("player","Spell_Shadow_ManaBurn")
    local PlayerHasProwl = HasBuff("player","Ability_Ambush")

    local ComboPoints = GetComboPoints("player","target")

    local LastRip = (GetTime() - WaaaghLastRipCast)
    local LastRake = (GetTime() - WaaaghLastRakeCast)

    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
    end

    if WaaaghAttack and UnitMana("player") >= 30 and not HasBuff("player", "Ability_Mount_JungleTiger") then
        CastSpellByName("Tiger's Fury")
        return
    end

    if PlayerHasProwl then
        if GetSpellCooldownByName("Ravage") == 0 then
            CastSpellByName("Ravage")
        end
        return
    end

    if PlayerHasClearCast then
        if isBehind then
            if GetSpellCooldownByName("Shred") == 0 then
                CastSpellByName("Shred")
            end
            return
        else
            if GetSpellCooldownByName("Claw") == 0 then
                CastSpellByName("Claw")
            end
            return
        end
    else
        if ComboPoints >= 4 then
            if LastRip > 10 and TargetHealthPercent() >= 20 then
                if GetSpellCooldownByName("Rip") == 0 then
                    CastSpellByName("Rip")
                    if not (GetSpellCooldownByName("Rip") == 0) then
                        WaaaghLastRipCast = GetTime()
                    end
                end
                return
            else
                if GetSpellCooldownByName("Ferocious Bite") == 0 then
                    CastSpellByName("Ferocious Bite")
                end
                return
            end
        else
            -- message(LastRake)
            if LastRake > 7 then
                if GetSpellCooldownByName("Rake") == 0 then
                    CastSpellByName("Rake")
                    if not (GetSpellCooldownByName("Rake") == 0) then
                        WaaaghLastRakeCast = GetTime()
                    end
                end
                return
            else
                if UnitMana("player") > 40 then
                    if GetSpellCooldownByName("Claw") == 0 then
                        CastSpellByName("Claw")
                    end
                    return
                end
            end
        end
    end
end

function DroodBear()

    local maul_usable, maul_oom = IsUsableAction(GetTextureID("Ability_Druid_Maul"))
    local sbite_usable, sbite_oom = IsUsableAction(GetTextureID("Ability_Racial_Cannibalize"))

    local IsMaulReady = IsSpellReady("Maul")
    local IsSBiteReady = IsSpellReady("Savage Bite")

    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
        return
    end

    -- if WaaaghAttack and not HasDebuff("target","Spell_Nature_FaerieFire") then
    --     CastSpellByName("Faerie Fire (Feral)()")
    -- end

    if UnitMana("player") >= 10 and maul_usable and IsMaulReady then
        if GetSpellCooldownByName("Maul") == 0 then
            CastSpellByName("Maul")
        end
    end

    if sbite_usable and IsSBiteReady then
        if GetSpellCooldownByName("Savage Bite") == 0 then
            CastSpellByName("Savage Bite")
        end
    end

end

function HealingShift(Spell)

    CurrentShift = GetActiveStance()

    if CurrentShift == 1 or CurrentShift == 3 then LastDroodShift = CurrentShift end

    if Spell == 'Regrowth' and not HasBuff("player", "Spell_Nature_ResistNature") then
        if GetSpellCooldownByName("Regrowth") == 0 then
            CastSpellByName("Regrowth")
        end
    end

    if Spell == 'Rejuvenation' and not HasBuff("player", "Spell_Nature_Rejuvenation") then
        if GetSpellCooldownByName("Rejuvenation") == 0 then
            CastSpellByName("Rejuvenation")
        end
    end

    if LastDroodShift == 1 then
        if GetSpellCooldownByName("Dire Bear Form") == 0 then
            CastSpellByName("Dire Bear Form")
        end
    end

    if LastDroodShift == 3 then
        if GetSpellCooldownByName("Cat Form") == 0 then
            CastSpellByName("Cat Form")
        end
    end

end