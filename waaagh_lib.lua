-- Example: IzUsableAction("Ability_Warrior_Revenge")
-- To get slot texture can do :

-- for id = 1,120 do
--     local texture = GetActionTexture(i)
--     if texture then
--         print(id .. texture)
--     end
-- end


function GetTextureID(name)
    for id = 1,120 do
        local texture = GetActionTexture(id)
        if texture and string.find(texture, name) then
            return id
        end
    end
end


function DoSunder(stack)

    local sunder_stacks, sunder_duration, sunder_timeleft = HazDebuff("target","Ability_Warrior_Sunder")

    if not sunder_stacks then return end
    if not WaaaghAttack then return end
    if not IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then return end
    
    if sunder_stacks == 0 then
        if UnitMana("player") >= 15 then -- Sunder is not on the target
            SendChatMessage("No Sunder Armor detected [ %t ]","SAY",nil)
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
                SendChatMessage("Sunder Armor on [ %t ] is timing out in less than 5 sec --> renew","SAY",nil)
                CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
                WaaaghLastSunder = GetTime()
                return
            elseif ( GetTime() - WaaaghLastSunder ) > 0 and ( GetTime() - WaaaghLastSunder ) < 24 then
                -- do nothing 
            else
                WaaaghLastSunder = nil
            end
        else
            SendChatMessage("LastSunder ain't set - assigning current time to LastSunder","SAY",nil)
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
            return
        end
    end
end