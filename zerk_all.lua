--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Berserker(mode)

    local HeroicStrikeSlotID = GetTextureID("Ability_Rogue_Ambush")
    local CleaveSlotID = GetTextureID("Ability_Warrior_Cleave")
    local IsShieldBlockReady = IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH)
    local IsWhirlwindReady = IsSpellReady(ABILITY_WHIRLWIND_WAAAGH)
    local IsBloodthirstReady = IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH)
    local IsBloodrageReady = IsSpellReady(ABILITY_BLOODRAGE_WAAAGH)

    -- Debug("HeroicStrikeSlotID is " .. HeroicStrikeSlotID)
    -- Debug("CleaveSlotID is " .. CleaveSlotID)

    if GetActiveStance() ~= 3 then DoShapeShift(3) end

    -- 1, Auto attack closest target
    if not WaaaghAttack then
        AttackTarget()
    end

    Waaagh_Shouts()

    -- Shield Block
    if HasShield() and WaaaghCombat and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsShieldBlockReady then
        Debug("32. Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        return
    end

    if mode == "multi" then
        -- Whirlwind
        if WaaaghAttack and UnitMana("player") >= 25 and IsWhirlwindReady then
            Debug("32. WW MULTI")
            CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
            return
        end
    end

    -- Bloodthirst
    if WaaaghAttack and UnitMana("player") >= 30 and IsBloodthirstReady then
        Debug("02. Berserker : Bloodthirst")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
        return
    end

    if mode == "normal" then
        -- Whirlwind
        if WaaaghAttack and UnitMana("player") >= 25 and IsWhirlwindReady then
            Debug("32. WW NORMAL")
            CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
            return
        end
    end

    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") then
        DoSunder(Waaagh_Configuration["SunderCount"])
    end

    if mode == "mono" then
        -- Heroic Strike
        if UnitMana("player") >= 45 and not IsBloodthirstReady then
            if IsCurrentAction(HeroicStrikeSlotID) then return end
            Debug("52. Heroic Strike - mono")
            CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            WaaaghLastHeroicStrikeCast = GetTime()
            return
        end
    else
    -- Dump rage with Heroic Strike
        if UnitMana("player") >= 45 and not IsWhirlwindReady and not IsBloodthirstReady then
            if mode == "multi" then
                if IsCurrentAction(CleaveSlotID) then return end
                -- Cleave
                Debug("52. Cleave - multi")
                CastSpellByName(ABILITY_CLEAVE_WAAAGH)
                return
            else
                if IsCurrentAction(HeroicStrikeSlotID) then return end
                -- Heroic Strike
                Debug("52. Heroic Strike - normal")
                CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
                WaaaghLastHeroicStrikeCast = GetTime()
                return
            end
        end
    end

end