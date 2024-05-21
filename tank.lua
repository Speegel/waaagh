--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------
 
function Tank()

    local sunder_stacks, sunder_timeleft = HazDebuff("target","Ability_Warrior_Sunder")
    local revenge_usable, revenge_oom = IsUsableAction(GetTextureID("Ability_Warrior_Revenge"))

    -- 1, Auto attack closest target
    if not WaaaghAttack then
        AttackTarget()
        -- Waaagh_Print("autoattack")
    end

    -- Revenge
    if WaaaghCombat and UnitMana("player") >= 5 and IsSpellReady(ABILITY_REVENGE_WAAAGH) and revenge_usable then
        -- if revenge_oom then
        --     Waaagh_Print("not enough rage to revenge, duh")
        -- end
        CastSpellByName(ABILITY_REVENGE_WAAAGH)
        return
    end

    -- Shield Block
    if HasShield() and WaaaghCombat and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        -- Waaagh_Print("1. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        return
    end

    if not HasBuff("player", "Ability_Warrior_BattleShout") and UnitMana("player") >= 10 and IsSpellReady(ABILITY_BATTLE_SHOUT_WAAAGH) then
        -- Waaagh_Print("2. Battle Shout")
        CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
        return
    end

    if not sunder_stacks then
        -- Sunder Armor if none
        if WaaaghCombat and UnitMana("player") >= 15 and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then -- Sunder is not on the target
            Waaagh_Print("3. Sunder Armor not on target")
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
        end
    end

    if WaaaghCombat and sunder_stacks and sunder_stacks < 5 and UnitMana("player") >= 15 and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then
        Waaagh_Print("4. Sunder Armor (not 5) and rage is > 35 : "..sunder_stacks)
        CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
        return
    end

    if WaaaghCombat and sunder_stacks and sunder_stacks == 5 and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then
        if WaaaghLastSunder then 
            if ( GetTime() - WaaaghLastSunder ) >= 24 and ( GetTime() - WaaaghLastSunder ) <= 30 then
                SendChatMessage("Sunder on [ %t ] is timing out in less than 5 sec --> renew","RAID",nil)
                SendChatMessage("Sunder on [ %t ] is timing out in less than 5 sec --> renew","SAY",nil)
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                WaaaghLastSunder = GetTime()
                return
            elseif ( GetTime() - WaaaghLastSunder ) > 0 and ( GetTime() - WaaaghLastSunder ) < 24 then
                -- do nothing 
            else
                WaaaghLastSunder = nil
            end
        -- Waaagh_Print("4. WaaaghLastSunder is at : "..( GetTime() - WaaaghLastSunder ))
        else
            Waaagh_Print("4.1 Sunder Armor 5 +1 for timer")
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
            return
        end
    end

    -- Bloodthirst
    if WaaaghCombat and UnitMana("player") >= 30 and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Debug("5. Bloodthirst")
        Waaagh_Print("5. BT")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        return
    end

    -- Bloodrage
    if UnitMana("player") <= 100 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 25 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        -- Waaagh_Print("6. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
        
    end

    -- Dump rage with Heroic Strike or Cleave
    if WaaaghCombat and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Heroic Strike
        if UnitMana("player") >= 45 then
            -- Waaagh_Print("7. Heroic Strike")
            CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            -- WaaaghLastSpellCast = GetTime()
            -- No global cooldown, added anyway to prevent Heroic Strike from being spammed over other abilities
        end
    end
end