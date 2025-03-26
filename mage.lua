function FrostDPS()

    local IsIceBarrierReady = IsSpellReady(ABILITY_ICE_BARRIER_WAAAGH)
    local IsIcilesReady = IsSpellReady("Icicles")
    local IsArcaneSurgeReady = IsSpellReady("Arcane Surge")
    local IsFrostNovaR1Ready = IsSpellReady("Frost Nova(Rank 1)")

    if IsIceBarrierReady and not HasBuff("player", "Spell_Ice_Lament") then
        CastSpellByName(ABILITY_ICE_BARRIER_WAAAGH)
    end

    if not pfUI.env.UnitChannelInfo("player") then
        if IsIcilesReady then CastSpellByName("Icicles") end
        if CheckInteractDistance("target", 3) then
            if IsFrostNovaR1Ready then CastSpellByName("Frost Nova(Rank 1)") end
        end
        if IsArcaneSurgeReady then CastSpellByName("Arcane Surge") end
        CastSpellByName("Frostbolt")
    end
end