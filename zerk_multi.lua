--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Zerk_Multi()

    Zerk_Base()

    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") then DoSunder(Waaagh_Configuration["SunderCount"]) end

    Waaagh_Shouts()

    -- Shield Block
    if HasShield() and WaaaghCombat and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        Debug("32. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
    end

    -- Dump rage with Cleave
    if not IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Cleave
        if UnitMana("player") >= 45 and IsSpellReady(ABILITY_CLEAVE_FURY) then
            Debug("52. Heroic Strike")
            CastSpellByName(ABILITY_CLEAVE_FURY)
        end
    end
end