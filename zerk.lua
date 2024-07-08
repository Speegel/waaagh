--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Zerk()
    DoShapeShift(3)
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

    if not WaaaghClientSunderCount then WaaaghClientSunderCount = 5 end 
    -- Sunder Armor (until 5)
    DoSunder(WaaaghClientSunderCount)

    -- Battle Shout
    if WaaaghAttack and not HasBuff("player", "Ability_Warrior_BattleShout") and UnitMana("player") >= 10 and IsSpellReady(ABILITY_BATTLE_SHOUT_WAAAGH) then
        Debug("28. Battle Shout")
        CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
    end



    -- Bloodrage
    if UnitMana("player") <= 100 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 25 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        Debug("46. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
    end

    -- Shield Block
    if HasShield() and WaaaghCombat and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        Debug("32. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
    end

    -- Dump rage with Heroic Strike or Cleave
    if not IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Heroic Strike
        if UnitMana("player") >= 45 and IsSpellReady(ABILITY_HEROIC_STRIKE_WAAAGH) then
            Debug("52. Heroic Strike")
            CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            -- WaaaghLastSpellCast = GetTime()
            -- No global cooldown, added anyway to prevent Heroic Strike from being spammed over other abilities
        end
    end
end