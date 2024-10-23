--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Zerk_Solo()

    Zerk_Base()

    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") then DoSunder(Waaagh_Configuration["SunderCount"]) end

    Waaagh_Shouts() 

    -- Shield Block
    if HasShield() and WaaaghCombat and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        Debug("32. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
    end

    -- Dump rage with Heroic Strike or Cleave
    if not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Heroic Strike
        if UnitMana("player") >= 45 and IsSpellReady(ABILITY_HEROIC_STRIKE_WAAAGH) then
            Debug("52. Heroic Strike")
            CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            -- WaaaghLastSpellCast = GetTime()
            -- No global cooldown, added anyway to prevent Heroic Strike from being spammed over other abilities
        end
    end
end