--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Zerk_Multi()
    DoShapeShift(3)
    
    local sunder_stacks, sunder_duration, sunder_timeleft = HazDebuff("target","Ability_Warrior_Sunder")

    -- 1, Auto attack closest target
    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
    end

    -- Bloodthirst
    if WaaaghAttack and WaaaghBloodthirst and UnitMana("player") >= 30 and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        Debug("23. Bloodthirst")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
    end

    -- Whirlwind
    if WaaaghAttack and UnitMana("player") >= 25 and IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) then
        CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
        WWEnemies.WWCount = 0
        WaaaghLastSpellCast = GetTime()
        WWEnemies.WWTime = GetTime()
    end

    -- Battle Shout
    if WaaaghAttack and not HasBuff("player", "Ability_Warrior_BattleShout") and UnitMana("player") >= 10 and IsSpellReady(ABILITY_BATTLE_SHOUT_WAAAGH) then
        Debug("28. Battle Shout")
        CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
    end

    -- Sunder Armor (until 5)
    if sunder_stacks and sunder_stacks == 0 then
        if WaaaghAttack and UnitMana("player") >= 15 and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then -- Sunder is not on the target
            -- SendChatMessage("No Sunder Armor detected [ %t ]","RAID",nil)
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            return
        end
    end

    if WaaaghAttack and sunder_stacks and sunder_stacks < 5 and UnitMana("player") >= 15 and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then
        -- SendChatMessage("4. Sunder Armor on [ %t ] has "..sunder_stacks.." stacks and is timing out in "..sunder_timeleft,"RAID",nil)
        CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
        return
    end

    if WaaaghAttack and sunder_stacks and sunder_stacks == 5 then
        
        if sunder_timeleft and sunder_timeleft <= 6 then
            if WaaaghAttack and UnitMana("player") >= 15 and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then -- Sunder is not on the target
                -- SendChatMessage("zSunder Armor on [ %t ] is timing out in less than 5 sec --> refresh","RAID",nil)
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                return
            end
            return
        end
    end

    -- Bloodrage
    if UnitMana("player") <= 100 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 25 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        Debug("46. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
    end

    -- Dump rage with Cleave
    if not IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Cleave
        if UnitMana("player") >= 45 and IsSpellReady(ABILITY_CLEAVE_WAAAGH) then
            Debug("52. Heroic Strike")
            CastSpellByName(ABILITY_CLEAVE_WAAAGH)
        end
    end
end< 