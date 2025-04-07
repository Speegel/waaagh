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

    -- local RakeSlotID = GetTextureID("Ability_Druid_Disembowel")
    -- local RipSlotID = GetTextureID("Ability_GhoulFrenzy")

    -- local rake_usable = IsUsableAction(RakeSlotID)
    -- local rip_usable = IsUsableAction(RipSlotID)

    UnitXP("behindThreshold", "set", 2)

    local isBehind = UnitXP("behind", "player", "target")

    local PlayerHasClearCast = HasBuff("player","Spell_Shadow_ManaBurn")

    local ComboPoints = GetComboPoints("player","target")

    local LastRip = (GetTime() - WaaaghLastRipCast)
    local LastRake = (GetTime() - WaaaghLastRakeCast)

    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
    end

    -- if WaaaghAttack and not HasDebuff("target","Spell_Nature_FaerieFire") then
    --     if GetSpellCooldownByName("Faerie Fire (Feral)") == 0 then
    --         CastSpellByName("Faerie Fire (Feral)()")
    --         if not (GetSpellCooldownByName("Faerie Fire (Feral)") == 0) then
    --             WaaaghLastFaerieFireCast = GetTime()
    --         end
    --     end
    --     return
    -- end

    if WaaaghAttack and UnitMana("player") >= 30 and not HasBuff("player", "Ability_Mount_JungleTiger") then
        CastSpellByName("Tiger's Fury")
        return
    end

    if PlayerHasClearCast then
        -- message(tostring(isBehind))
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
                    -- message(tostring(RakeSuccess))
                    -- if not (GetSpellCooldownByName("Rake") == 0) and RakeSuccess then
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

    if WaaaghAttack and not HasDebuff("target","Spell_Nature_FaerieFire") then
        CastSpellByName("Faerie Fire (Feral)()")
    end

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