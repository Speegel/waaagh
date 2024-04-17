--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------
function Shoot()
    local ranged_type = Ranged()
    local spell
    if ranged_type == ITEM_TYPE_BOWS_WAAAGH then
        spell = ABILITY_SHOOT_BOW_WAAAGH
    elseif ranged_type == ITEM_TYPE_CROSSBOWS_WAAAGH then
        spell = ABILITY_SHOOT_CROSSBOW_WAAAGH
    elseif ranged_type == ITEM_TYPE_GUNS_WAAAGH then
        spell = ABILITY_SHOOT_GUN_WAAAGH
    elseif ranged_type == ITEM_TYPE_THROWN_WAAAGH then
        spell = ABILITY_THROW_WAAAGH
    else
        return false
    end
    if IsSpellReady(spell) then
        Debug(spell)
        CastSpellByName(spell)
        -- WaaaghLastSpellCast = GetTime()
    end
    return true
end