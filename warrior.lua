--------------------------------------------------

-- Warrior Rotation - Handles the combat sequence

--------------------------------------------------

function WarriorRota(mode)

    local IsBloodthirstReady = (GetSpellCooldownByName(ABILITY_BLOODTHIRST_WAAAGH) == 0)
    local IsWhirlwindReady = (GetSpellCooldownByName(ABILITY_WHIRLWIND_WAAAGH) == 0)

    local PlayerHasBattleShout = HasBuff("player", "Ability_Warrior_BattleShout")
    local LastBattleShout = (GetTime() - WaaaghWarriorLastBattleShout)
    local LastSunderArmor = (GetTime() - WaaaghWarriorLastSunderArmor)

    if GetActiveStance() ~= 3 then DoShapeShift(3) end

    -- 1, Auto attack closest target
    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
    end

    if UnitMana("player") >= 10 and LastBattleShout and not PlayerHasBattleShout then
        if GetSpellCooldownByName("Battle Shout") == 0 then
            CastSpellByName("Battle Shout")
            WaaaghWarriorLastBattleShout = GetTime()
        end
        return
    end

    if not WaaagWarriorFirstSunderArmor then
        if GetSpellCooldownByName("Sunder Armor") == 0 then
            CastSpellByName("Sunder Armor")

        end
        return
    end

    -- Shield Block
    if HasShield() and WaaaghAttack and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 then
        if GetSpellCooldownByName(ABILITY_SHIELD_BLOCK_WAAAGH) == 0 then
            CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        end
        return
    end

    if mode == "multi" then
        -- Whirlwind
        if WaaaghAttack and UnitMana("player") >= 25 then
            if GetSpellCooldownByName(ABILITY_WHIRLWIND_WAAAGH) == 0 then
                CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
            end
            return
        end
    end

    -- Bloodthirst
    if WaaaghAttack and UnitMana("player") >= 30 then
        if GetSpellCooldownByName(ABILITY_BLOODTHIRST_WAAAGH) == 0 then
            CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        end
        return
    end

    if mode == "normal" then
        -- Whirlwind
        if WaaaghAttack and UnitMana("player") >= 25 then
            if GetSpellCooldownByName(ABILITY_WHIRLWIND_WAAAGH) == 0 then
                CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
            end
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
            if GetSpellCooldownByName(ABILITY_HEROIC_STRIKE_WAAAGH) == 0 then
                CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            end
            return
        end
    else
    -- Dump rage with Heroic Strike
        if UnitMana("player") >= 45 and not IsWhirlwindReady and not IsBloodthirstReady then
            if mode == "multi" then
                -- Cleave
                if GetSpellCooldownByName(ABILITY_CLEAVE_WAAAGH) == 0 then
                    CastSpellByName(ABILITY_CLEAVE_WAAAGH)
                end
                return
            else
                -- Heroic Strike
                if GetSpellCooldownByName(ABILITY_HEROIC_STRIKE_WAAAGH) == 0 then
                    CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
                end
                return
            end
        end
    end
end