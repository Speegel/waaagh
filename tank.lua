--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------
 
function Tank()

    local revenge_usable, revenge_oom = IsUsableAction(GetTextureID("Ability_Warrior_Revenge"))

    -- 1, Auto attack closest target
    if not WaaaghAttack then
        AttackTarget()
        -- Waaagh_Print("autoattack")
    end

    -- Revenge
    if WaaaghAttack and UnitMana("player") >= 5 and IsSpellReady(ABILITY_REVENGE_WAAAGH) and revenge_usable then
        CastSpellByName(ABILITY_REVENGE_WAAAGH)
        return
    end

    -- Shield Block
    if HasShield() and WaaaghAttack and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        -- Waaagh_Print("1. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        return
    end

    if WaaaghAttack and UnitMana("player") >= 30 and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- -- Debug("5. Bloodthirst")
        -- Waaagh_Print("5. BT")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        return
    end
    if not WaaaghClientSunderCount then WaaaghClientSunderCount = 5 end 
    -- Sunder Armor (until 5)
    DoSunder(WaaaghClientSunderCount)

    if not HasBuff("player", "Ability_Warrior_BattleShout") and UnitMana("player") >= 10 and IsSpellReady(ABILITY_BATTLE_SHOUT_WAAAGH) then
        -- Waaagh_Print("2. Battle Shout")
        CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
        return
    end

    -- Bloodthirst


    -- Bloodrage
    if UnitMana("player") <= 100 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 25 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        -- Waaagh_Print("6. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
        
    end

    -- Dump rage with Heroic Strike or Cleave
    if WaaaghAttack and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Heroic Strike
        if UnitMana("player") >= 45 then
            -- Waaagh_Print("7. Heroic Strike")
            CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            -- WaaaghLastSpellCast = GetTime()
            -- No global cooldown, added anyway to prevent Heroic Strike from being spammed over other abilities
        end
    end
    
    if not WaaaghClientSunderCount then WaaaghClientSunderCount = 5 end 
    
    -- Sunder Armor (until 5)
    if not UnitIsPlayer("target") then DoSunder(WaaaghClientSunderCount) end
end