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
        SendChatMessage(CHAT_KICKED_FURY ,"SAY" ,"common")
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
        SendChatMessage(CHAT_KICKED_FURY ,"SAY" ,"common")
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
    -- local id = 1
    -- while pfUI.env.libdebuff:UnitDebuff(unit, id) do
    -- while UnitDebuff(unit, id) do
    for i = 1,64 do
        local effect, rank, texture, stacks, dtype, duration, timeleft = pfUI.env.libdebuff:UnitDebuff(unit, i)
        -- local debuffTexture, debuffAmount = UnitDebuff(unit, id)
        if texture and string.find(texture,debuffName) then
            return stacks, duration, timeleft
        -- else
        --     return 0, nil
        end
        -- id = id + 1
    end
    return 0, nil, nil
end

function DoSunder(stack)

    local sunder_stacks, sunder_duration, sunder_timeleft = HazDebuff("target","Ability_Warrior_Sunder")

    if not sunder_stacks then return end
    if not WaaaghAttack then return end
    
    if sunder_stacks == 0 then
        if UnitMana("player") >= 15 then -- Sunder is not on the target
            -- if not WaaaghNoSunderMessage then
            --     WaaaghNoSunderMessage = GetTime()
            --     SendChatMessage("No Sunder Armor detected [ %t ]","SAY",nil)
            -- end
            -- if ( GetTime() - WaaaghNoSunderMessage ) >= 5
            --     WaaaghNoSunderMessage = GetTime()
            --     SendChatMessage("No Sunder Armor detected [ %t ]","SAY",nil)
            -- end
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
            return
        end
    end

    if sunder_stacks < stack and UnitMana("player") >= 15 then
        -- SendChatMessage("4. Sunder Armor on [ %t ] has "..sunder_stacks.." stacks and is timing out in "..sunder_timeleft,"RAID",nil)
        CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
        WaaaghLastSunder = GetTime()
        return
    end

    if sunder_stacks == stack then
        if WaaaghLastSunder then 
            if ( GetTime() - WaaaghLastSunder ) >= 24 and ( GetTime() - WaaaghLastSunder ) <= 30 then
                -- SendChatMessage("Sunder Armor on [ %t ] is timing out in less than 5 sec --> renew","SAY",nil)
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