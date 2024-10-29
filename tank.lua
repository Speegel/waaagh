--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------
 
function Tank(isMulti)

    local HeroicStrikeSlotID = GetTextureID("Ability_Rogue_Ambush")
    local CleaveSlotID = GetTextureID("Ability_Warrior_Cleave")
    local revenge_usable, revenge_oom = IsUsableAction(GetTextureID("Ability_Warrior_Revenge"))
    local IsRevengeReady = IsSpellReady(ABILITY_REVENGE_WAAAGH)
    local IsShieldBlockReady = IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH)
    local IsBloodthirstReady = IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH)

    -- 1, Auto attack closest target
    if not WaaaghAttack then
        AttackTarget()
    end

    Waaagh_Shouts()

    -- Shield Block
    if HasShield() and WaaaghAttack and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsShieldBlockReady then
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        return
    end

    -- Revenge
    if WaaaghAttack and UnitMana("player") >= 5 and IsRevengeReady and revenge_usable then
        CastSpellByName(ABILITY_REVENGE_WAAAGH)
        return
    end

    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") then DoSunder(Waaagh_Configuration["SunderCount"]) end

    -- Cast Bloodthirst if ready and rage >= 30 
    if WaaaghAttack and UnitMana("player") >= 30 and IsBloodthirstReady then
        Debug("02. Waaagh - Tank - Bloodthirst")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        return
    end
   
    -- Dump rage with Heroic Strike or Cleave
    if WaaaghAttack and not IsBloodthirstReady then
        -- Heroic Strike
        if UnitMana("player") >= 45 then
            if isMulti == 1 then
                -- Skip if Cleave is in queue
                if IsCurrentAction(CleaveSlotID) then return end
                Debug("03. Waaagh - Tank - Cleave")
                CastSpellByName(ABILITY_CLEAVE_WAAAGH)
            else
                -- Skip if HS is in queue
                if IsCurrentAction(HeroicStrikeSlotID) then return end
                Debug("03. Waaagh - Tank - Heroic Strike")
                CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            end
        end
    end        

end