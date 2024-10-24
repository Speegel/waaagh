-- Example: IzUsableAction("Ability_Warrior_Revenge")
-- To get slot texture can do :

-- for id = 1,120 do
--     local texture = GetActionTexture(i)
--     if texture then
--         print(id .. texture)
--     end
-- end

--------------------------------------------------
--
-- Handle kick commands
--
--------------------------------------------------

function Zerk_Base()

    if GetActiveStance() ~= 3 then DoShapeShift(3) end

    local overpower_usable, overpower_oom = IsUsableAction(GetTextureID("Ability_MeleeDamage"))

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

end

function Waaagh_Shouts() 
        -- Battle Shout
        if WaaaghAttack and not HasBuff("player", "Ability_Warrior_BattleShout") and UnitMana("player") >= 10 and IsSpellReady(ABILITY_BATTLE_SHOUT_WAAAGH) then
            Debug("28. Battle Shout")
            CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
            -- WaaaghLastSpellCast = GetTime()
        end
    
        -- Bloodrage
        if UnitMana("player") <= 65 and (UnitHealth("player") / UnitHealthMax("player") * 100) >= 40 and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
            Debug("46. Bloodrage")
            CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
        end

end

function Waagh_Kick()
    if HasShield() then
        if GetActiveStance() == 3 then
            if not FuryOldStance then
                FuryOldStance = GetActiveStance()
            end
            Debug("14. Battle Stance (Shield Bash)")
            DoShapeShift(2)
            CastSpellByName(ABILITY_SHIELD_BASH_FURY)
            
        else
            Debug("14. Shield Bash (interrupt)")
        end
        FuryDanceDone = true
        CastSpellByName(ABILITY_SHIELD_BASH_FURY)
        FuryLastSpellCast = GetTime()
        
    elseif IsSpellReady(ABILITY_PUMMEL_FURY) then
        if GetActiveStance() ~= 3 then
            Debug("13. Berserker Stance (Pummel)")
            if not FuryOldStance then
                FuryOldStance = GetActiveStance()
            end
            FuryLastSpellCast = GetTime()
            DoShapeShift(3)
        else
            Debug("13. Pummel")
        end
        CastSpellByName(ABILITY_PUMMEL_FURY)
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
            return
        end
    end

    if sunder_stacks and sunder_stacks < stack and UnitMana("player") >= 15 then
        Debug("4. Sunder Armor on [ %t ] has " .. tostring(sunder_stacks) .. " stacks")
        CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
        WaaaghLastSunder = GetTime()
        return
    end

    if sunder_stacks == stack then
        if WaaaghLastSunder then 
            if ( GetTime() - WaaaghLastSunder ) >= 24 and ( GetTime() - WaaaghLastSunder ) <= 30 then
                Debug("Sunder Armor on [ %t ] is timing out in less than 5 sec --> renew")
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                WaaaghLastSunder = GetTime()
                return
            elseif ( GetTime() - WaaaghLastSunder ) > 0 and ( GetTime() - WaaaghLastSunder ) < 24 then
                -- do nothing 
            else
                WaaaghLastSunder = nil
            end
        else
            -- SendChatMessage("LastSunder ain't set - assigning current time to LastSunder","SAY",nil)
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
            return
        end
    end
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
        -- Debug("distance - " .. dist)
        -- Debug("Active Stance - " .. GetActiveStance())
        -- Debug("Ability (intercept) activated - " .. tostring(Waaagh_Configuration[ABILITY_INTERCEPT_WAAAGH]))
        -- Debug("Ability (intervene) activated - " .. tostring(Waaagh_Configuration[ABILITY_INTERVENE_WAAAGH]))
        -- Debug("Ability Ready - " .. tostring(IsSpellReady(ABILITY_INTERVENE_WAAAGH)))
        if Waaagh_Configuration[ABILITY_INTERVENE_WAAAGH]
            and GetActiveStance() == 2
            and UnitMana("player") >= 10
            and WaaaghLastChargeCast + 1 < GetTime()
            and UnitIsPlayer("target")
            and IsSpellReady(ABILITY_INTERVENE_WAAAGH) then
              Debug("C2. Intervene")
              CastSpellByName(ABILITY_INTERVENE_WAAAGH)
              WaaaghLastChargeCast = GetTime()
            
        elseif Waaagh_Configuration[ABILITY_INTERCEPT_WAAAGH]
          and GetActiveStance() == 3
          and dist <= 25
          and dist > 7
          and UnitMana("player") >= 10
          and WaaaghLastChargeCast + 1 < GetTime()
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
            Debug("C2. Intercept")
            CastSpellByName(ABILITY_INTERCEPT_WAAAGH)
            WaaaghLastChargeCast = GetTime()

        elseif Waaagh_Configuration[ABILITY_INTERCEPT_WAAAGH]
          and GetActiveStance() ~= 3
          and UnitMana("player") >= 10
          and WaaaghLastChargeCast + 1 < GetTime()
          and IsSpellReadyIn(ABILITY_INTERCEPT_WAAAGH) <= 3 then
            Debug("C5. Berserker Stance (Intercept)")
            if WaaaghOldStance == nil then
                WaaaghOldStance = GetActiveStance()
            elseif WaaaghOldStance == 3 then
                WaaaghDanceDone = true
            end
            DoShapeShift(3)

        end
    else
        if Waaagh_Configuration[ABILITY_INTERVENE_WAAAGH]
            and GetActiveStance() == 2
            and UnitMana("player") >= 10
            and WaaaghLastChargeCast + 1 < GetTime()
            and UnitIsPlayer("target")
            and IsSpellReady(ABILITY_INTERVENE_WAAAGH) then
              Debug("C2. Intervene")
              CastSpellByName(ABILITY_INTERVENE_WAAAGH)
              WaaaghLastChargeCast = GetTime()
        
        elseif Waaagh_Configuration[ABILITY_CHARGE_WAAAGH]
          and GetActiveStance() == 1
          and dist <= 25
          and dist > 7
          and WaaaghLastChargeCast + 0.5 < GetTime()
          and IsSpellReady(ABILITY_CHARGE_WAAAGH) then
            Debug("O1. Charge")
            CastSpellByName(ABILITY_CHARGE_WAAAGH)
            WaaaghLastChargeCast = GetTime()

        elseif Waaagh_Configuration[ABILITY_INTERCEPT_WAAAGH]
          and GetActiveStance() == 3
          and dist <= 25
          and dist > 7
          and UnitMana("player") >= 10
          and WaaaghLastChargeCast + 2 < GetTime()
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
            Debug("O2. Intercept")
            CastSpellByName(ABILITY_INTERCEPT_WAAAGH)
            WaaaghLastChargeCast = GetTime()
            WaaaghLastSpellCast = GetTime()

        elseif Waaagh_Configuration[ABILITY_INTERCEPT_WAAAGH]
          and not IsSpellReady(ABILITY_CHARGE_WAAAGH)
          and UnitMana("player") >= 10
          and WaaaghBerserkerStance
          and WaaaghLastChargeCast + 1 < GetTime()
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH) then
            if GetActiveStance() ~= 3 then
                Debug("Berserker Stance (Intercept)")
                if WaaaghOldStance == nil then
                    WaaaghOldStance = GetActiveStance()
                end
                DoShapeShift(3)

            else
                if WaaaghOldStance == 3 then
                    WaaaghDanceDone = true
                end
                CastSpellByName(ABILITY_INTERCEPT_WAAAGH)
                WaaaghLastSpellCast = GetTime()
            end

        elseif Waaagh_Configuration[ABILITY_CHARGE_WAAAGH]
          and GetActiveStance() ~= 1
          and dist > 7
          and IsSpellReady(ABILITY_CHARGE_WAAAGH) then
            Debug("O7. Arm Stance (Charge)")
            if Waaagh_Configuration["PrimaryStance"] ~= 1
              and WaaaghOldStance == nil then
                WaaaghOldStance = GetActiveStance()
            elseif WaaaghOldstance == 1 then
                WaaaghOldStance = nil
                WaaaghDanceDone = true
            end
            DoShapeShift(1)
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