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

function DroodCatBleed()

    local RakeSlotID = GetTextureID("Ability_Druid_Disembowel")
    local RipSlotID = GetTextureID("Ability_GhoulFrenzy")

    local rake_usable = IsUsableAction(RakeSlotID)
    local rip_usable = IsUsableAction(RipSlotID)

    local isBehind = UnitXP("behind", "player", "target")

    local PlayerHasClearCast = HasBuff("player","Spell_Shadow_ManaBurn")

    local ComboPoints = GetComboPoints("player","target")

    local LastRip = (GetTime() - WaaaghLastRipCast)
    local LastRake = (GetTime() - WaaaghLastRakeCast)

    -- message("Last Rip Cast :"..LastRip)
    -- message("Last Rake Cast :"..LastRake)

    -- 1, Auto attack closest target
    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
        -- message("enable combat - out")
        return
    end

    if WaaaghAttack and not HasDebuff("target","Spell_Nature_FaerieFire") then
        CastSpellByName("Faerie Fire (Feral)()")
        -- message("Cast FF - out")
        return
    end

    if WaaaghAttack and UnitMana("player") >= 30 and not HasBuff("player", "Ability_Mount_JungleTiger") then
        CastSpellByName("Tiger's Fury")
        return
    end

    if PlayerHasClearCast then
        if isBehind then
            -- message("Cast Shred --")
            CastSpellByName("Shred")
            return
        else
            -- message("Cast Claw ----")
            CastSpellByName("Claw")
            return
        end
    else
        if ComboPoints >= 4 then
            if LastRip > 10 then
                if IsCurrentAction(RipSlotID) then return end
                -- message("cast RIP ---")
                WaaaghLastRipCast = GetTime()
                CastSpellByName("Rip")
                return
            else
                -- message("cast FB ---")
                CastSpellByName("Ferocious Bite")
                return
            end
        else
            if LastRake > 7 then
                if IsCurrentAction(RakeSlotID) then return end
                -- message("Cast RAKE ----")
                WaaaghLastRakeCast = GetTime()
                CastSpellByName("Rake")
                return
            else
                if UnitMana("player") > 60 then
                    -- message("Cast Claw ----")
                    CastSpellByName("Claw")
                    return
                end
            end
        end
    end
    -- if (GetTime() - WaaaghLastRakeCast) >= 8 then
    --     message("Cast RAKE ----")
    --     WaaaghLastRakeCast = GetTime()
    --     CastSpellByName("Rake")
    --     return
    -- end

    -- if not PlayerHasClearCast and UnitMana("player") >= 60 then
    --     message("Cast Claw ----")
    --     CastSpellByName("Claw")
    --     return
    -- end
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

    if WaaaghAttack and not HasDebuff("target","Spell_Nature_FaerieFire") then
        CastSpellByName("Faerie Fire (Feral)()")
    end

    if UnitMana("player") >= 10 and maul_usable and IsMaulReady then
        CastSpellByName("Maul")
    end

    if sbite_usable and IsSBiteReady then
        CastSpellByName("Savage Bite")
    end

end


function HealingShift(Spell)

    CurrentShift = GetActiveStance()

    if CurrentShift == 1 or CurrentShift == 3 then LastDroodShift = CurrentShift end

    if Spell == 'Regrowth' and not HasBuff("player", "Spell_Nature_ResistNature") then CastSpellByName("Regrowth") end
    if Spell == 'Rejuvenation' and not HasBuff("player", "Spell_Nature_Rejuvenation") then CastSpellByName("Rejuvenation") end

    message(LastDroodShift)

    if LastDroodShift == 1 or LastDroodShift == 3 then
        DoShapeShift(LastDroodShift)
    end
end