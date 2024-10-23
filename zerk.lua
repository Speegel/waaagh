--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Zerk()

    Zerk_Base()

    -- Whirlwind
    if WaaaghAttack and UnitMana("player") >= 25 and IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) then
        CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
    end

    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") then DoSunder(Waaagh_Configuration["SunderCount"]) end

    Waaagh_Shouts()

    -- Shield Block
    if HasShield() and WaaaghCombat and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        Debug("32. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
    end

    -- Dump rage with Heroic Strike
    if not IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Heroic Strike
        if UnitMana("player") >= 45 and IsSpellReady(ABILITY_HEROIC_STRIKE_WAAAGH) then
            Debug("52. Heroic Strike")
            CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
        end
    end
end