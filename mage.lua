function FrostDPS()

    local IsIceBarrierReady = IsSpellReady(ABILITY_ICE_BARRIER_WAAAGH)

    if not UnitHasBuff("player", "spell_ice_lament") and IsIceBarrierReady then
        CastSpellByName(ABILITY_ICE_BARRIER_WAAAGH)
    end

    if not pfUI.env.UnitChannelInfo("player") then
        CastSpellByName("Icicles")
        if CheckInteractDistance("target", 3) then
            CastSpellByName("Frost Nova(Rank 1)")
        end
        CastSpellByName("Arcane Surge")
        if IsControlKeyDown() then
            CastSpellByName("Berserking")
        end
        CastSpellByName("Frostbolt")
    end
end