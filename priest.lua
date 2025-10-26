function MindBlastFlayRotation()
    local target = "target"
    
    -- Check if we have a valid target
    if not UnitExists(target) or UnitIsDead(target) or not UnitCanAttack("player", target) then
        return
    end
    
    -- Check basic range
    if not IsSpellInRange("Mind Blast", target) then
        return
    end
    
    -- Don't interrupt targeting
    if SpellIsTargeting() then
        return
    end
    
    -- If Shift is pressed, cast Vampiric Embrace
    if IsShiftKeyDown() then
        CastSpellByName("Vampiric Embrace")
        return
    end
    
    -- Try Mind Blast first, if it fails (on cooldown), cast Mind Flay
    CastSpellByName("Mind Blast")
    if SpellIsTargeting() then
        return
    end
    
    -- If Mind Blast didn't work (cooldown/etc), cast Mind Flay
    CastSpellByName("Mind Flay")
end
-- Optional: Create a macro or keybind to call this function
-- You can bind this to a key or call it from a macro with: /script ShadowPriestRotation()

function PriestDot()
    local ShadowWord = {
        refreshtime=1,
        priotarget,
        -- name=arcane
    }
    local LastInsectSwarmParams = {
        refreshtime=2,
        priotarget,
        minhp=10000
    }
    -- if not Cursive:Multicurse("Moonfire","RAID_MARK", MoonfireParams) then
        Cursive:Multicurse("Shadow Word: Pain","RAID_MARK", ShadowWord)
    -- end

end