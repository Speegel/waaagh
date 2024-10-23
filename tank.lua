--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------
 
function Tank(isMulti)

    local revenge_usable, revenge_oom = IsUsableAction(GetTextureID("Ability_Warrior_Revenge"))

    -- 1, Auto attack closest target
    if not WaaaghAttack then
        AttackTarget()
    end

    -- Revenge
    if WaaaghAttack and UnitMana("player") >= 5 and IsSpellReady(ABILITY_REVENGE_WAAAGH) and revenge_usable then
        CastSpellByName(ABILITY_REVENGE_WAAAGH)
        return
    end

    -- Shield Block
    if HasShield() and WaaaghAttack and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        return
    end

    if WaaaghAttack and UnitMana("player") >= 30 and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        return
    end
   
    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") then DoSunder(Waaagh_Configuration["SunderCount"]) end

    Waaagh_Shouts()

    -- Dump rage with Heroic Strike or Cleave
    if WaaaghAttack and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        -- Heroic Strike
        if UnitMana("player") >= 45 then
            if isMulti == 1 then
                CastSpellByName(ABILITY_CLEAVE_WAAAGH)
            else
                CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            end
        end
    end        

end