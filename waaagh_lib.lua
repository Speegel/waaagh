--------------------------------------------------
--
-- Handle kick commands
--
--------------------------------------------------

function Waaag_BattleShout()
        -- Battle Shout
    -- if not UnitHasBuff("player", "Ability_Warrior_BattleShout") 
    if UnitMana("player") >= 10 then
        Debug("03. Berserker : Battle Shout")
        CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
        WaaaghLastBattleShoutCast = GetTime()
    else
        Debug("03. Berserker : Battle Shout -> Not enough rage")
        return false
    end
end

function Waaagh_Shouts() 
    -- Debug("Waaagh_shouts")
    -- Bloodrage
    if UnitMana("player") <= 65 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 40 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        Debug("46. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
    end

    
    if not WaaaghLastBattleShoutCast then
        Debug("Battle shout missing --> apply")
        if not Waaag_BattleShout() then return end
        -- Debug("Battle Shout var : " .. WaaaghLastBattleShoutCast)
    else
        -- Debug("Battle Shout time left : " .. (GetTime() - WaaaghLastBattleShoutCast))
        if (GetTime() - WaaaghLastBattleShoutCast) > 110 then
            Debug("Last Battle shout has been applied 100s --> renew")
            Waaag_BattleShout()
        end
    end
end

function Zerk_Base()

    if GetActiveStance() ~= 3 then DoShapeShift(3) end

    local overpower_usable, overpower_oom = IsUsableAction(GetTextureID("Ability_MeleeDamage"))

    -- 1, Auto attack closest target
    if Waaagh_Configuration["AutoAttack"] and not WaaaghAttack then
        AttackTarget()
        return
    end

    -- Bloodthirst
    if WaaaghAttack and WaaaghBloodthirst and UnitMana("player") >= 30 and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
        Debug("23. Bloodthirst")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        -- WaaaghLastSpellCast = GetTime()
        return
    end

end


function Waagh_Kick()
    if HasShield() then
        if GetActiveStance() ~= 2 then
            Debug("14. Shift to Def for Shield Bash")
            DoShapeShift(2)
        end
        if IsSpellReady(ABILITY_SHIELD_BASH_WAAAGH) then
            Debug("112. Shield bashing the dude")
            CastSpellByName(ABILITY_SHIELD_BASH_WAAAGH)
        end
    else 
        if GetActiveStance() ~= 3 then
            Debug("13. Shift to Berserker Stance (Pummel)")
            DoShapeShift(3)
        end
        if IsSpellReady(ABILITY_PUMMEL_WAAAGH) then
            Debug("112. Pummling the dude")
            CastSpellByName(ABILITY_PUMMEL_WAAAGH)
        end
    end
end


function GetTextureID(name)
    for id = 1,120 do
        local texture = GetActionTexture(id)
        if texture and string.find(texture, name) then
            return id
        end
    end
end

function HazDebuff(unit, debuffName)
    for i = 1,64 do
        local effect, rank, texture, stacks, dtype, duration, timeleft = pfUI.env.libdebuff:UnitDebuff(unit, i)
        if texture and string.find(texture,debuffName) then
            return stacks, duration, timeleft
        end
    end
    return 0, nil, nil
end

function DoSunder(stack)

    local sunder_stacks, sunder_duration, sunder_timeleft = HazDebuff("target","Ability_Warrior_Sunder")

    if stack == 0 then
        Debug("Stack is set to 0")
        return 
    end

    if not sunder_stacks then return end
    if not WaaaghAttack then return end
    
    if sunder_stacks == 0 then
        if UnitMana("player") >= 15 then -- Sunder is not on the target
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
        end
    end

    if sunder_stacks < stack and UnitMana("player") >= 15 then
        -- if IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then
            -- Debug("4. Sunder Armor on [ %t ] has " .. tostring(sunder_stacks) .. " stacks")
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
        -- end
    end

    if sunder_stacks >= stack then
        if WaaaghLastSunder then 
            if ( GetTime() - WaaaghLastSunder ) >= 20 and ( GetTime() - WaaaghLastSunder ) <= 30 then
                Debug("Sunder Armor on [ %t ] is timing out in less than 10 sec --> refresh")
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                WaaaghLastSunder = GetTime()
            elseif ( GetTime() - WaaaghLastSunder ) > 0 and ( GetTime() - WaaaghLastSunder ) < 20 then
                -- do nothing
            else
                WaaaghLastSunder = nil
            end
        else
            -- SendChatMessage("LastSunder ain't set - assigning current time to LastSunder","SAY",nil)
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
        end
    end

    return

end

function Waaagh_LipAoeTaunt()
    UseContainerItemByNameOnPlayer(ITEM_CONS_LIMITED_INVULNERABILITY)
    CastSpellByName(ABILITY_CHALLENGING_SHOUT_WAAAGH)
end

function Waaagh_Charge()
    local dist = Waaagh_Distance()
    if WaaaghMount
      and dist <= 25 then
        -- Dismount as a first step
        Debug("Dismounting")
        Dismount()
        WaaaghMount = nil
    end
    if WaaaghCombat then
        if UnitIsPlayer("target") then
            if GetActiveStance() == 2
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERVENE_WAAAGH) then
                Debug("C1. Intervene")
                CastSpellByName(ABILITY_INTERVENE_WAAAGH)
                WaaaghLastChargeCast = GetTime()
            else
                Debug("C4. Switch def Stance for intervene")
                DoShapeShift(2)
            end 
        else
            if GetActiveStance() == 3
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
                    Debug("C2. Intercept")
                    CastSpellByName(ABILITY_INTERCEPT_WAAAGH)
                    WaaaghLastChargeCast = GetTime()

            elseif GetActiveStance() ~= 3
                and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
                    Debug("C5. Berserker Stance (Intercept)")
                    DoShapeShift(3)
            end
        end
    else
        if UnitIsPlayer("target") then
            if GetActiveStance() == 2
                and UnitMana("player") >= 10
                and IsSpellReady(ABILITY_INTERVENE_WAAAGH) then
                Debug("O3. Intervene")
                CastSpellByName(ABILITY_INTERVENE_WAAAGH)
                WaaaghLastChargeCast = GetTime()
            else 
                Debug("O4. Switch def Stance for intervene")
                DoShapeShift(2)
            end 
        else
            if GetActiveStance() == 1
            and IsSpellReady(ABILITY_CHARGE_WAAAGH) then
                Debug("O1. Charge")
                CastSpellByName(ABILITY_CHARGE_WAAAGH)
                WaaaghLastChargeCast = GetTime()

            elseif GetActiveStance() == 3
            and UnitMana("player") >= 10
            and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
                Debug("O2. Intercept")
                CastSpellByName(ABILITY_INTERCEPT_WAAAGH)

            elseif GetActiveStance() ~= 1
            and IsSpellReady(ABILITY_CHARGE_WAAAGH) then
                Debug("O4. Switch Battle Stance for Charge")
                DoShapeShift(1)
            end
        end
    end
end

-- This function uses a Sharp stone on MainHand and, if equipped, the OffHand
function Oogla_SharpenOff(oStone)
    oBag,oSlot,oItemExists = Oogla_FindItem(oStone);
    if (oItemExists) then
       UseContainerItem(oBag,oSlot);
       PickupInventoryItem(17);
       oSharpenOffHand = false;
    end
 end
 
 -- This function finds an item in your bag and returns oBag,oSlot,oItemExists
function Oogla_FindItem(oItem)
    local oItemExists = false
    for oBag=0,4 do
        for oSlot=1,GetContainerNumSlots(oBag) do
            if (GetContainerItemLink(oBag,oSlot)) then
                if (string.find(GetContainerItemLink(oBag,oSlot), oItem)) then
                    oItemExists = true
                    return oBag, oSlot, oItemExists;
                end
            end
        end
    end
end