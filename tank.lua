--------------------------------------------------

-- Tank - Handles the combat sequence

--------------------------------------------------

function Tank(isMulti)

    local HeroicStrikeSlotID = GetTextureID("Ability_Rogue_Ambush")
    local CleaveSlotID = GetTextureID("Ability_Warrior_Cleave")
    -- local ShieldSlamSlotID = GetTextureID("INV_Shield_05")
    -- local ConcussionBlowSlotID = GetTextureID("Ability_ThunderBolt")
    local RevengeSlotID = GetTextureID("Ability_Warrior_Revenge")
    local revenge_usable, revenge_oom = IsUsableAction(RevengeSlotID)
    local IsRevengeReady = IsSpellReady(ABILITY_REVENGE_WAAAGH)
    local IsShieldBlockReady = IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH)
    local IsBloodthirstReady = IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH)

    if Waaagh_Configuration["dp"] then
        -- ShieldSlam_usable, Shieldslam_oom = IsUsableAction(ShieldSlamSlotID)
        -- ConcussionBlow_usable, Concussionblow_oom = IsUsableAction(ConcussionBlowSlotID)
        IsConcussionBlowReady = IsSpellReady(ABILITY_CONCUSSION_BLOW_WAAAGH)
        IsShieldSlamReady = IsSpellReady(ABILITY_SHIELD_SLAM_WAAAGH)
    end

    -- 1, Auto attack closest target
    if not WaaaghAttack then
        Debug("01. Waaagh - Tank - Auto Attack")
        AttackTarget()
    end

    Waaagh_Shouts()

    -- Shield Block
    if HasShield() and WaaaghAttack and (UnitName("targettarget") == UnitName("player")) and UnitMana("player") >= 10 and IsShieldBlockReady then
        Debug("02. Waaagh - Tank - Shield Block")
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        return
    end

    -- Revenge
    if WaaaghAttack and UnitMana("player") >= 5 and IsRevengeReady and revenge_usable then
        Debug("03. Waaagh - Tank - Revenge")
        CastSpellByName(ABILITY_REVENGE_WAAAGH)
        return
    end

    -- Shield Slam
    if WaaaghAttack and UnitMana("player") >= 20 and Waaagh_Configuration["dp"] and IsShieldSlamReady and not Waaagh_Configuration["raz"] then
        Debug("01. Waaagh - Tank - Deep Prot - Shield Slam")
        CastSpellByName(ABILITY_SHIELD_SLAM_WAAAGH)
        return
    end

    -- Concussion Blow
    if WaaaghAttack and UnitMana("player") >= 15 and Waaagh_Configuration["dp"] and IsConcussionBlowReady and not Waaagh_Configuration["raz"] then
        Debug("02. Waaagh - Tank - Deep Prot - Concussion Blow")
        CastSpellByName(ABILITY_CONCUSSION_BLOW_WAAAGH)
        return
    end

    -- Cast Bloodthirst if ready and rage >= 30
    if WaaaghAttack and UnitMana("player") >= 30 and IsBloodthirstReady and not Waaagh_Configuration["raz"] then
        Debug("04. Waaagh - Tank - Bloodthirst")
        CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
        return
    end

    -- Sunder Armor (until SunderCount)
    if not UnitIsPlayer("target") and not Waaagh_Configuration["raz"] then DoSunder(Waaagh_Configuration["SunderCount"]) end

    -- Dump rage with Heroic Strike or Cleave
    if WaaaghAttack and not IsBloodthirstReady and not Waaagh_Configuration["raz"] then
        -- Heroic Strike
        if UnitMana("player") >= 45 then
            if isMulti == 1 then
                -- Skip if Cleave is in queue
                if IsCurrentAction(CleaveSlotID) then return end
                Debug("05. Waaagh - Tank - Cleave")
                CastSpellByName(ABILITY_CLEAVE_WAAAGH)
            else
                -- Skip if HS is in queue
                if IsCurrentAction(HeroicStrikeSlotID) then return end
                Debug("05. Waaagh - Tank - Heroic Strike")
                CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
            end
        end
    end
end