--------------------------------------------------
--
-- Variables
--
--------------------------------------------------
-- Setup configuration to default or only new ones
local function DoUpdateConfiguration(defaults)
    local configs = {

      {"AutoAttack", true},       -- Set to false to disable auto-attack
      {"BerserkHealth", 60},      -- Set this to the minimum percent of health to have when using Berserk
      {"BloodrageHealth", 50},    -- Set this to the minimum percent of health to have when using Bloodrage
      {"DeathWishHealth", 60},    -- Set this to the minimum percent of health to have when using Death Wish
      {"Debug", false},           -- Set to true to enable debugging feedback
      {"DebugChannel", nil},      -- Channel to log to
      {"DemoDiff", 7},            -- When level difference is greater don't do Demoralizing Shout
      {"Enabled", true},          -- Set to false to disable the addon
      {"ExecuteSwap", false},     -- Swap weapon at execute
      {"ExecuteSwapped", false},  -- If execute outfit is equipped
      {"FlurryTriggerRage", 52},  -- Set this to the minimum rage to use Hamtring to trigger Flurry
      {"HamstringHealth", 40},    -- Set this to the maximum percent of health allowed when using Hamstring on NPCs
      {"InstantBuildTime", 2},    -- Set the time to spend building rage for upcoming 31 point instant attacks
      {"MaximumRage", 60},        -- Set this to the maximum amount of rage allowed when using abilities to increase rage
      {"NextAttackRage", 30},     -- Set this to the minimum rage to have to use next attack abilities (Cleave and Heroic Strike)
      {"StanceChangeRage", 25},   -- Set this to the amount of rage allowed to be wasted when switching stances
      {"PrimaryStance", false},   -- Set this to the stance to fall back to after performing an attack requiring another stance

      {MODE_HEADER_PROT, false },              -- Use threat and defensive abilities
      {MODE_HEADER_AOE, false},                -- Disable auto use of aoe (Disables OP, HS, BT, Exe, Enablse Cleave, Whirlwind)
      {MODE_HEADER_DEBUFF, false},             -- use cures when player have a debuff

      {ABILITY_BATTLE_SHOUT_WAAAGH, true},       -- Set to false to disable use of ability
      {ABILITY_BERSERKER_RAGE_WAAAGH, true},     -- Used to counter fears
      {ABILITY_BLOODRAGE_WAAAGH, true},          -- Gives extra rage
      {ABILITY_BLOODTHIRST_WAAAGH, true},        -- Waaagh main attack
      {ABILITY_CHARGE_WAAAGH, true},             -- Charge when out of combat
      {ABILITY_CLEAVE_WAAAGH, false},            -- Cleave to lower threat and on used in aoe situations
      {ABILITY_DEMORALIZING_SHOUT_WAAAGH, true}, -- Decreases enemy attack power
      {ABILITY_DISARM_WAAAGH, true},             -- Used in pvp against hard hitters
      {ABILITY_EXECUTE_WAAAGH, true},            -- Execute
      {ABILITY_HAMSTRING_WAAAGH, true},          -- Hamstring
      {ABILITY_PIERCING_HOWL_WAAAGH, true},      -- Piercing Howl
      {ABILITY_HEROIC_STRIKE_WAAAGH, true},      -- HS, to dump rage and at low levels
      {ABILITY_INTERCEPT_WAAAGH, true},          -- in combat charge
      {ABILITY_MORTAL_STRIKE_WAAAGH, true},      -- Arms main attack
      {ABILITY_SWEEPING_STRIKES_WAAAGH, true},   -- Aoe for arms
      {ABILITY_OVERPOWER_WAAAGH, true},          -- Counterattack dodge
      {ABILITY_PUMMEL_WAAAGH, true},             -- Counter spellcast
      {ABILITY_REND_WAAAGH, true},               -- Counter rogues vanish
      {ABILITY_SHIELD_BASH_WAAAGH, true},        -- Prot
      {ABILITY_SHIELD_SLAM_WAAAGH, true},        -- Prot
      {ABILITY_DEATH_WISH_WAAAGH, true},         -- Death wish on cooldown
      {ABILITY_THUNDER_CLAP_WAAAGH, true},       -- slow enemies
      {ABILITY_WHIRLWIND_WAAAGH, true},          -- Waaagh rotation and aoe
      {ABILITY_REVENGE_WAAAGH, false},           -- Prot

      {ITEM_CONS_JUJU_CHILL, true},            -- use on cooldown for bosses with frost dmg
      {ITEM_CONS_JUJU_EMBER, true},            -- use on cooldown for bosses with fire dmg
      {ITEM_CONS_JUJU_FLURRY, false},          -- use on cooldown
      {ITEM_CONS_JUJU_MIGHT, false},           -- use on cooldown
      {ITEM_CONS_JUJU_POWER, false},           -- use on cooldown
      {ITEM_CONS_OIL_OF_IMMOLATION, false},    -- use on cooldown

      {ITEM_TRINKET_EARTHSTRIKE, true},        -- use on cooldown
      {ITEM_TRINKET_KOTS, true},               -- use on cooldown
      {ITEM_TRINKET_SLAYERS_CREST, true},      -- use on cooldown

      {RACIAL_BERSERKING_WAAAGH, true},          -- Racial
      {RACIAL_BLOOD_WAAAGH, true},               -- Racial
      {RACIAL_STONEFORM_WAAAGH, true},           -- Racial
    }

    for _, v in pairs(configs) do
        if defaults
          or Waaagh_Configuration[v[1]] == nil then
            Waaagh_Configuration[v[1]] = v[2]
        end
    end
end

--------------------------------------------------
-- Init function
local function Waaagh_Configuration_Init()

    WAAAGH_VERSION = "1.17.4"

    if not Waaagh_Configuration then
        Waaagh_Configuration = { }
    end
    if not Waaagh_Runners then
        Waaagh_Runners = { }
    end
    if not Waaagh_ImmuneDisarm then
        Waaagh_ImmuneDisarm = { }
    end
    DoUpdateConfiguration(false) -- Set to value if nil
end

--------------------------------------------------
--
-- Normal Functions
--
--------------------------------------------------
-- Print msg to console
local function Print(msg)
    if not DEFAULT_CHAT_FRAME then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage(BINDING_HEADER_WAAAGH..": "..(msg or ""))
end

--------------------------------------------------
-- Output debug info to console
local function Debug(msg)
    if (msg
      or "") == "" then
        WaaaghRageDumped = nil
        return
    end
    if Waaagh_Configuration
      and Waaagh_Configuration["Debug"] then
        Print(msg)
    end
    if Waaagh_Configuration["DebugChannel"]
      and UnitLevel("player") >= 10 then
        if GetTime() > WaaaghLastLog + 0.1 then
            SendChatMessage(msg..(WaaaghLogMsg or ""), "CHANNEL", nil, Waaagh_Configuration["DebugChannel"])
            WaaaghLastLog = GetTime()
            WaaaghLogMsg = nil
        else
            WaaaghLogMsg = (WaaaghLogMsg or "")..", "..msg
        end
    end
    WaaaghRageDumped = nil
end

--------------------------------------------------
-- Log fury debug to channel and log file
local function LogToFile(enable)
    if enable then
        LoggingChat(1)
        LoggingCombat(1)
        if Waaagh_Configuration["DebugChannel"] == nil then
            local channel = "Waaagh_"..tostring(GetTime() * 1000)
            JoinChannelByName(channel, "test", nil, 1)
            local id, _ = GetChannelName(channel)
            Waaagh_Configuration["DebugChannel"] = id
        else
            local _, channel = GetChannelName(Waaagh_Configuration["DebugChannel"])
            if channel ~= nil then
                Print("Joining channel : "..channel)
                JoinChannelByName(channel, "test", nil, 1)
            else
                Waaagh_Configuration["DebugChannel"] = nil
                LogToFile(enable)
            end
        end
        Print(TEXT_WAAAGH_LOGGING_CHANNEL_ON)
    else
        LoggingChat(0)
        LoggingCombat(0)
        Waaagh_Configuration["DebugChannel"] = nil
        Print(TEXT_WAAAGH_LOGGING_CHANNEL_OFF)
    end
end

--------------------------------------------------
-- Check if unit has debuff of specific type
local function HasDebuffType(unit, type)
    local id = 1
    if not type then
        return nil
    end
    while UnitDebuff(unit, id) do
        local _,_,debuffType = UnitDebuff(unit, id)
        if type
          and debuffType ==  type then
            return true
        end
        id = id + 1
    end
    return nil
end

--------------------------------------------------

local function DoShapeShift(stance)
    local stances = {ABILITY_BATTLE_STANCE_WAAAGH, ABILITY_DEFENSIVE_STANCE_WAAAGH, ABILITY_BERSERKER_STANCE_WAAAGH}
    CastShapeshiftForm(stance)
    WaaaghLastStanceCast = GetTime()
    Debug("Changed to "..stances[stance])
end

--------------------------------------------------
-- Print unit buffs and debuffs
local function PrintEffects(unit)
    local id = 1
    if UnitBuff(unit, id) then
        Print(SLASH_BUFFS_WAAAGH)
        while (UnitBuff(unit, id)) do
            Print(UnitBuff(unit, id))
            id = id + 1
        end
        id = 1
    end
    if HasDebuffType(unit) then
        Print(TEXT_WAAAGH_HAVE_DEBUFF)
    end
    if UnitDebuff(unit, id) then
        Print(CHAT_DEBUFFS_WAAAGH)
        while UnitDebuff(unit, id) do
            Print(UnitDebuff(unit, id))
            id = id + 1
        end
    end
end

--------------------------------------------------
-- list of targets where resistance is useful
local res = {
    ["fire"] = {
        BOSS_NAX_GRAND_WIDOW_FAERLINA_WAAAGH,
        BOSS_NAX_THANE_KORTH_AZZ_WAAAGH,
        BOXX_MC_RAGNAROS_WAAAGH,
        BOSS_ONYXIA_WAAAGH
    },
    ["frost"] = {
        BOSS_NAX_KEL_THUZAD_WAAAGH,
        BOSS_NAX_SAPPHIRON_WAAAGH
    },
    ["nature"] = {
        BOSS_NAX_HEIGAN_THE_UNCLEAN_WAAAGH,
        BOSS_NAX_LOATHEB_WAAAGH,
        BOSS_AQ40_PRINCESS_HUHURAN_WAAAGH,
        BOSS_AQ40_VISCIDUS_WAAAGH,
    },
    ["shadow"] = {
        BOSS_NAX_LOATHEB_WAAAGH,
        BOSS_STRAT_BARON_RIVENDERE_WAAAGH,
        BOSS_NAX_LADY_BLAUMEUX_WAAAGH
    },
    ["arcane"] = {
        BOSS_NAX_GOTHIK_THE_HARVESTER_WAAAGH,
        BOSS_AQ40_THE_PROPHET_SKERAM_WAAAGH,
        BOSS_AQ40_EMPEROR_VEK_LOR_WAAAGH,
        BOSS_MC_SHAZZRATH_WAAAGH
    },
    ["holy"] = {
        BOSS_NAX_SIR_ZELIEK_WAAAGH
    }
}

--------------------------------------------------
-- Check if boss 'requires' resistance of specific type
local function IsUseRes(type)
    for _, name in pairs(res[type]) do
        if UnitName("target") == name then
            return true
        end
    end
    return false
end

--------------------------------------------------
--
-- Distance handling
--
--------------------------------------------------
-- Detect spells on action bars, to be used for range checks
local function Waaagh_InitDistance()
    local found = 0
    yard30 = nil
    yard25 = nil
    yard10 = nil
    yard08 = nil
    yard05 = nil
    for i = 1, 120 do
        t = GetActionTexture(i)
        if t then
            if not yard30 then
                if string.find(t, "Ability_Marksmanship") -- Shoot
                  or string.find(t, "Ability_Throw") then -- Throw
                    yard30 = i
                    Debug("30 yard: "..t)
                    found = found + 1
                end
            end
            if not yard25 then
                if string.find(t, "Ability_Warrior_Charge") -- Charge
                  or string.find(t, "Ability_Rogue_Sprint") then -- Intercept
                    yard25 = i
                    Debug("25 yard: "..t)
                    found = found + 1
                end
            end
            if not yard10 then
                if string.find(t, "Ability_GolemThunderClap")
                  or string.find(t, "Spell_Nature_ThunderClap") then -- Thunder Clap
                    yard10 = i
                    Debug("10 yard: "..t)
                    found = found + 1
                end
            end
            if not yard08 then
                if string.find(t, "Ability_Marksmanship") -- Shoot
                  or string.find(t, "Ability_Throw") then -- Throw
                    yard08 = i
                    Debug("8 yard: "..t)
                    found = found + 1
                end
            end
            if not yard05 then
                if string.find(t, "Ability_Warrior_Sunder") -- Sunder Armor
                  or string.find(t, "Ability_Warrior_DecisiveStrike") -- Slam
                  or string.find(t, "Ability_Warrior_Disarm") -- Disarm
                  or string.find(t, "INV_Gauntlets_04") -- Pummel
                  or string.find(t, "Ability_MeleeDamage") -- Overpower
                  or string.find(t, "Ability_Warrior_PunishingBlow") -- Mocking blow
                  or string.find(t, "Ability_Warrior_Revenge") -- Revenge
                  or string.find(t, "Ability_Gouge") -- Rend
                  or string.find(t, "INV_Sword_48") -- Execute
                  or string.find(t, "ability_warrior_savageblow") -- Mortal Strike
                  or string.find(t, "INV_Shield_05") -- Shield Slam
                  or string.find(t, "Ability_ShockWave") -- Hamtstring
                  or string.find(t, "Spell_Nature_Bloodlust") then -- Bloodthirst
                    yard05 = i
                    Debug("5 yard: "..t)
                    found = found + 1
                end
            end
            if found == 5 then
                Debug("Found all distance check spells ("..i..")")
                return
            end
        end
    end
    -- Print message if any distance check spell is missing
    if not yard30
      or not yard08 then
        Print(CHAT_MISSING_SPELL_SHOOT_THROW_WAAAGH)
    end
    if not yard25 then
        Print(CHAT_MISSING_SPELL_INTERCEPT_CHARGE_WAAAGH)
    end
    if not yard10 then
        Print(CHAT_MISSING_SPELL_THUNDERCLAP_WAAAGH)
    end
    if not yard05 then
        Print(CHAT_MISSING_SPELL_PUMMEL_WAAAGH)
    end
end

--------------------------------------------------
-- Detect distance to target
local function Waaagh_Distance()
    if not UnitCanAttack("player", "target") then
        return 100 -- invalid target
    elseif yard05
      and IsActionInRange(yard05) == 1 then
        return 5 -- 0 - 5 yards
    elseif yard10
      and IsActionInRange(yard10) == 1 then
        if yard08
          and IsActionInRange(yard08) == 0 then
            return 7 -- 6 - 7 yards
        end
        return 10 -- 8 - 10 yards
    elseif yard25
      and IsActionInRange(yard25) == 1 then
        return 25 -- 11 - 25 yards
    elseif yard30
      and IsActionInRange(yard30) == 1 then
        return 30 -- 26 - 30 yards
    end
    return 100 -- 31 - <na> yards
end

--------------------------------------------------
-- Get spell id from name
local function SpellId(spellname)
    local id = 1
    for i = 1, GetNumSpellTabs() do
        local _, _, _, numSpells = GetSpellTabInfo(i)
        for j = 1, numSpells do
            local spellName = GetSpellName(id, BOOKTYPE_SPELL)
            if spellName == spellname then
                return id
            end
            id = id + 1
        end
    end
    return nil
end

--------------------------------------------------
-- Check remaining cooldown on spell (0 - Ready)
local function IsSpellReadyIn(spellname)
    local id = SpellId(spellname)
    if id then
        local start, duration = GetSpellCooldown(id, 0)
        if start == 0
          and duration == 0
          and WaaaghLastSpellCast + 1 <= GetTime() then
            return 0
        end
        local remaining = duration - (GetTime() - start)
        if remaining >= 0 then
            return remaining
        end
    end
    return 86400 -- return max time (i.e not ready)
end

--------------------------------------------------
-- Return if spell is ready
local function IsSpellReady(spellname)
    return IsSpellReadyIn(spellname) == 0
 end

--------------------------------------------------
-- Detect if unit has specific number of debuffs
local function HasDebuff(unit, texturename, amount)
    local id = 1
    while UnitDebuff(unit, id) do
        local debuffTexture, debuffAmount = UnitDebuff(unit, id)
        if string.find(debuffTexture, texturename) then
            if (amount
              or 1) <= debuffAmount then
                return true
            else
                return false
            end
        end
        id = id + 1
    end
    return nil
end

--------------------------------------------------
-- Detect if unit has buff
local function HasBuff(unit, texturename)
    local id = 1
    while UnitBuff(unit, id) do
        local buffTexture = UnitBuff(unit, id)
        if string.find(buffTexture, texturename) then
            return true
        end
        id = id + 1
    end
    return nil
end
--------------------------------------------------
-- Detect if unit has buff id
local function HasBuffId(unit, spellId)
    for i = 1, 40 do
        if select(11, UnitBuff(unit, i)) == spellid then
            return true
        end
    end
    return nil
end

--------------------------------------------------
-- Use item on player
local function UseContainerItemByNameOnPlayer(name)
    for bag = 0, 4 do
        for slot = 1,GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag, slot)
            if item then
                local _, _, itemCode = strfind(item, "(%d+):")
                local itemName = GetItemInfo(itemCode)
                if itemName == name then
                    UseContainerItem(bag, slot)
                    if SpellIsTargeting() then
                        SpellTargetUnit("player")
                    end
                end
            end
        end
    end
end

--------------------------------------------------
-- Return active stance
local function GetActiveStance()
    --Detect the active stance
    for i = 1, 3 do
        local _, _, active = GetShapeshiftFormInfo(i)
        if active then
            return i
        end
    end
    return nil
end

--------------------------------------------------
-- Detect if a suitable weapon (not a skinning knife/mining pick and not broken) is present
local function HasWeapon()
    if HasDebuff("player", "Ability_Warrior_Disarm") then
        return nil
    end
    local item = GetInventoryItemLink("player", 16)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName, itemLink, _, _, itemType = GetItemInfo(itemCode)
        if itemLink ~= "item:7005:0:0:0" -- Skining knife
          and itemLink ~= "item:2901:0:0:0" -- Mining pick
          and not GetInventoryItemBroken("player", 16) then
            return true
        end
    end
    return nil
end

--------------------------------------------------
-- Detect if a shield is present
local function HasShield()
    if HasDebuff("player", "Ability_Warrior_Disarm") then
        return nil
    end
    local item = GetInventoryItemLink("player", 17)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local _, _, _, _, _, itemType = GetItemInfo(itemCode)
        if itemType == ITEM_TYPE_SHIELDS_WAAAGH
          and not GetInventoryItemBroken("player", 17) then
            return true
        end
    end
    return nil
end

--------------------------------------------------
-- Return trinket slot if trinket is equipped and not on cooldown
local function IsTrinketEquipped(name)
    for slot = 13, 14 do
        local item = GetInventoryItemLink("player", slot)
        if item then
            local _, _, itemCode = strfind(item, "(%d+):")
            local itemName = GetItemInfo(itemCode)
            if itemName == name
              and GetInventoryItemCooldown("player", slot) == 0 then
                return slot
            end
        end
    end
    return nil
end
--------------------------------------------------

local function Ranged()
    --Detect if a ranged weapon is equipped and return type
    local item = GetInventoryItemLink("player", 18)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local _, _, _, _, _, itemType = GetItemInfo(itemCode)
        return itemType
    end
    return nil
end
--------------------------------------------------

local function HamstringCost()
    -- Calculate the cost of Hamstring based on gear
    local i = 0
    local item = GetInventoryItemLink("player", 10)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if itemName == ITEM_GAUNTLETS1_WAAAGH
          or itemName == ITEM_GAUNTLETS2_WAAAGH
          or itemName == ITEM_GAUNTLETS3_WAAAGH
          or itemName == ITEM_GAUNTLETS4_WAAAGH then
            i = i + 3
        end
    end
    item = GetInventoryItemLink("player", 2)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if itemName == ITEM_NECK_RAGE_OF_MUGAMBA_WAAAGH then
            i = i + 2
        end
    end
    return 10 - i
end
--------------------------------------------------
local function CheckDebuffs(unit, list)
    for _, v in pairs(list) do
        if HasDebuff(unit, v) then
            return true
        end
    end
    return nil
end
--------------------------------------------------
local function HasAntiStealthDebuff()
    --Detect anti-stealth debuffs
    --Rend, Deep Wounds, Serpent Sting, Immolate, Curse of Agony , Garrote, Rupture, Deadly Poison, Fireball, Ignite, Pyroblast, Corruption, Siphon Life, Faerie Fire, Moonfire, Rake, Rip, Pounce, Insect Swarm, Holy Fire, Wyvern Sting, Devouring Plague
    return CheckDebuffs("target", {
        "Ability_Gouge",
        "Ability_Hunter_Quickshot",
        "Spell_Fire_Immolation",
        "Spell_Shadow_CurseOfSargeras",
        "Ability_Rogue_Garrote",
        "Ability_Rogue_Rupture",
        "Ability_Rogue_DualWeild",
        "Spell_Shadow_ShadowWordPain",
        "Spell_Fire_FlameBolt",
        "Spell_Fire_Incinerate",
        "Spell_Fire_Fireball02",
        "Spell_Shadow_AbominationExplosion",
        "Spell_Shadow_Requiem",
        "Spell_Nature_FaerieFire",
        "Spell_Nature_StarFall",
        "Ability_Druid_Disembowel",
        -- "Ability_GhoulFrenzy", -- triggered on fury warrs Flurry
        "Ability_Druid_SurpriseAttack",
        "Spell_Nature_InsectSwarm",
        "Spell_Holy_SearingLight",
        "INV_Spear_02",
        "Spell_Shadow_BlackPlague"
    })
end
--------------------------------------------------

local function HasImmobilizingDebuff()
    return CheckDebuffs("player", {
        "Spell_Frost_FrostNova",
        "spell_Nature_StrangleVines"
    })
end
--------------------------------------------------

local function SnareDebuff(unit)
    -- Detect snaring debuffs
    -- Hamstring, Wing Clip, Curse of Exhaustion, Crippling Poison, Frostbolt, Cone of Cold, Frost Shock, Piercing Howl
    return CheckDebuffs(unit, {
        "Ability_ShockWave",
        "Ability_Rogue_Trip",
        "Spell_Shadow_GrimWard",
        "Ability_PoisonSting",
        "Spell_Frost_FrostBolt02",
        "Spell_Frost_Glacier",
        "Spell_Shadow_DeathScream",
        "Spell_Frost_FrostShock"
    })
end
--------------------------------------------------

local function Waaagh_RunnerDetect(arg1, arg2)
    -- Thanks to HateMe
    if arg1 == CHAT_RUNNER_WAAAGH then
        Waaagh_Runners[arg2] = true
        WaaaghFleeing = true
    end
end
--------------------------------------------------

local function ItemExists(itemName)
    for bag = 4, 0, -1 do
        for slot = 1, GetContainerNumSlots(bag) do
            local _, itemCount = GetContainerItemInfo(bag, slot)
            if itemCount then
                local itemLink = GetContainerItemLink(bag,slot)
                local _, _, itemParse = strfind(itemLink, "(%d+):")
                local queryName, _, _, _, _, _ = GetItemInfo(itemParse)
                if queryName
                  and queryName ~= "" then
                    if queryName == itemName then
                        return true
                    end
                end
            end
        end
    end
    return false
end
--------------------------------------------------

local function IsItemReady(item)
    if ItemExists(item) == false then
        return false
    end
    local _, duration, _ = GetItemCooldown(item)
    if duration == 0 then
        return true
    end
    return false
end
--------------------------------------------------

local function IsEquippedAndReady(slot, name)
    local item = GetInventoryItemLink("player", slot)
    if item then
        local _, _, itemCode = strfind(item, "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if itemName == name
          and GetInventoryItemCooldown("player", slot) == 0 then
            return true
        end
    end
    return nil
end
--------------------------------------------------

local function CheckCooldown(slot)
    local start, duration = GetInventoryItemCooldown("player", slot)
    if duration > 30 then
        -- Alllow duration for 30 seconds since it's when you equip the item
        local item = GetInventoryItemLink("player", slot)
        if item then
            local _, _, itemCode = strfind(item, "(%d+):")
            local itemName = GetItemInfo(itemCode)
            return itemName
        end
    end
    return nil
end
--------------------------------------------------

local function Waaagh_SetEnemies(count)
    for i = 5, 1, -1 do
        WWEnemies.Hist[i] = WWEnemies.Hist[i - 1]
    end
    WWEnemies.Hist[0] = Enemies
end
--------------------------------------------------

local function AddEnemyCount(Enemies)
    Waaagh_SetEnemies(Enemies)
    Debug("Enemies "..Enemies)
    if Enemies < 2
      and Waaagh_Configuration[MODE_HEADER_AOE] then
        Print(TEXT_WAAAGH_DISABLING_AOE)
        Waaagh_Configuration[MODE_HEADER_AOE] = false
    end
end
--------------------------------------------------

local function Waaagh_GetEnemies()
    return WWEnemies.Hist[0] or 0
end
--------------------------------------------------

local function Waaagh_Shoot()
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
        WaaaghLastSpellCast = GetTime()
    end
    return true
end
--------------------------------------------------
-- Treat debuff on player
local function Waaagh_TreatDebuffPlayer()
    local allowCombatCooldown = true
    if UnitName("target") == BOSS_NAX_LOATHEB_WAAAGH
      or UnitName("target") == BOSS_NAX_SAPPHIRON_WAAAGH then
        allowCombatCooldown = false -- Save for Shadow/frost Protection Potion
    end
    -- add Restorative Potion (magic, poison curse or disease)
    if HasDebuffType("player", ITEM_DEBUFF_TYPE_POISON) then
        if UnitName("target") == BOSS_NAX_GROBBULUS_WAAAGH then
            return false
        end
        if IsTrinketEquipped(ITEM_TRINKET_HEART_OF_NOXXION) then
            local slot = IsTrinketEquipped(ITEM_TRINKET_HEART_OF_NOXXION)
            UseInventoryItem(slot)

        elseif UnitRace("player") == RACE_DWARF
          and Waaagh_Configuration[RACIAL_STONEFORM_WAAAGH]
          and IsSpellReady(RACIAL_STONEFORM_WAAAGH) then
            CastSpellByName(RACIAL_STONEFORM_WAAAGH)

        elseif allowCombatCooldown
          and IsItemReady(ITEM_CONS_JUNGLE_REMEDY) then
            Print(ITEM_CONS_JUNGLE_REMEDY)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUNGLE_REMEDY)

        elseif IsItemReady(ITEM_CONS_POWERFUL_ANTIVENOM) then
            Print(ITEM_CONS_POWERFUL_ANTIVENOM)
            UseContainerItemByNameOnPlayer(ITEM_CONS_POWERFUL_ANTIVENOM)

        elseif IsItemReady(ITEM_CONS_ELIXIR_OF_POISION_RESISTANCE) then
            Print(ITEM_CONS_ELIXIR_OF_POISION_RESISTANCE)
            UseContainerItemByNameOnPlayer(ITEM_CONS_ELIXIR_OF_POISION_RESISTANCE)

        elseif allowCombatCooldown
          and IsItemReady(ITEM_CONS_PURIFICATION_POTION) then
            Print(ITEM_CONS_PURIFICATION_POTION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_PURIFICATION_POTION)

        elseif allowCombatCooldown
          and IsItemReady(ITEM_CONS_RESTORATIVE_POTION) then
            Print(ITEM_CONS_RESTORATIVE_POTION_POTION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_RESTORATIVE_POTION_POTION)

        else
            return false

        end
        Print(ITEM_DEBUFF_TYPE_POISON)
    elseif HasDebuffType("player", ITEM_DEBUFF_TYPE_DISEASE) then
        if UnitRace("player") == RACE_DWARF
          and IsSpellReady(ABILITY_STONEFORM_WAAAGH) then
            CastSpellByName(ABILITY_STONEFORM_WAAAGH)

        elseif allowCombatCooldown
          and IsItemReady(ITEM_CONS_JUNGLE_REMEDY) then
            Print(ITEM_CONS_JUNGLE_REMEDY)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUNGLE_REMEDY)

        elseif allowCombatCooldown
          and IsItemReady(ITEM_CONS_RESTORATIVE_POTION) then
            Print(ITEM_CONS_RESTORATIVE_POTION_POTION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_RESTORATIVE_POTION_POTION)

            else
            return false
        end
        Print(ITEM_DEBUFF_TYPE_DISEASE)
    elseif HasDebuffType("player", ITEM_DEBUFF_TYPE_CURSE) then
        if allowCombatCooldown
          and IsItemReady(ITEM_CONS_PURIFICATION_POTION) then
            Print(ITEM_CONS_PURIFICATION_POTION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_PURIFICATION_POTION)

        elseif allowCombatCooldown
          and IsItemReady(ITEM_CONS_RESTORATIVE_POTION) then
            Print(ITEM_CONS_RESTORATIVE_POTION_POTION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_RESTORATIVE_POTION_POTION)

            else
            return false
        end
        Print(ITEM_DEBUFF_TYPE_CURSE)
    elseif HasDebuffType("player", ITEM_DEBUFF_TYPE_MAGIC) then
        
        if allowCombatCooldown
          and IsItemReady(ITEM_CONS_RESTORATIVE_POTION) then
            Print(ITEM_CONS_RESTORATIVE_POTION_POTION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_RESTORATIVE_POTION_POTION)

        else
            return false
        end
        Print(ITEM_DEBUFF_TYPE_MAGIC)
    else
        return false

    end
    return true
end

--------------------------------------------------

-- Waaagh - Handles the combat sequence

--------------------------------------------------

function Waaagh()
    if Waaagh_Configuration["Enabled"]
      and not UnitIsCivilian("target")
      and UnitClass("player") == CLASS_WARRIOR_WAAAGH
      and WaaaghTalents then
        local debuffImmobilizing = HasImmobilizingDebuff()

        -- 1, Auto attack closest target
        if Waaagh_Configuration["AutoAttack"]
          and not WaaaghAttack then
            AttackTarget()
        end

        -- 2, Overpower
        if WaaaghOverpower then
            if (GetTime() - WaaaghOverpower) > 4 then
                WaaaghOverpower = nil
            end
        end

        -- 3, Spell interrupts
        if WaaaghSpellInterrupt then
            if (GetTime() - WaaaghSpellInterrupt) > 2 then
                WaaaghSpellInterrupt = nil
            end
        end

        -- 4, Add number of enemies
        if WWEnemies.CleaveCount ~= nil
          and (GetTime() - WWEnemies.CleaveTime ) > 1 then
            AddEnemyCount(WWEnemies.CleaveCount)
            WWEnemies.CleaveCount = nil
        elseif WWEnemies.WWCount ~= nil
          and (GetTime() - WWEnemies.WWTime) > 1 then
            AddEnemyCount(WWEnemies.WWCount)
            WWEnemies.WWCount = nil
        end

        -- 5, Dismount if mounted
        if WaaaghMount then
            Debug("5. Dismount")
            Dismount()
            WaaaghMount = nil

        -- 6, Use Berserker rage to interrupt fears and....
        elseif Waaagh_Configuration[ABILITY_BERSERKER_RAGE_WAAAGH]
          and (WaaaghIncapacitate
          or WaaaghFear)
          and GetActiveStance() == 3
          and IsSpellReady(ABILITY_BERSERKER_RAGE_WAAAGH) then
            Debug("6. Berserker Rage")
            CastSpellByName(ABILITY_BERSERKER_RAGE_WAAAGH)

        -- 7, Spider Belt, remove existing immobilizing effects
        elseif debuffImmobilizing
          and IsEquippedAndReady(6, ITEM_BELT_SPIDER_BELT_WAAAGH) then
            Debug("7. Spider Belt")
            UseInventoryItem(6)

        -- 8, Ornate Mithril Boots, remove existing immobilizing effects
        elseif debuffImmobilizing
          and IsEquippedAndReady(8, ITEM_BOOTS_ORNATE_MITHRIL_BOOTS_WAAAGH) then
            Debug("8. Ornate Mithril Boots")
            UseInventoryItem(8)

        -- 9, PVP Trinket, Horde
        elseif (WaaaghFear
          or WaaaghIncapacitate
          or debuffImmobilizing)
          and IsTrinketEquipped(ITEM_TRINKET_INSIGNIA_OF_THE_HORDE_WAAAGH) then
            slot = IsTrinketEquipped(ITEM_TRINKET_INSIGNIA_OF_THE_HORDE_WAAAGH)
            Debug("9. Insignia of the Horde")
            UseInventoryItem(slot)

        -- PVP Trinket, Alliance
        elseif (WaaaghFear
          or WaaaghIncapacitate
          or debuffImmobilizing)
          and IsTrinketEquipped(ITEM_TRINKET_INSIGNIA_OF_THE_ALLIANCE_WAAAGH) then
            slot = IsTrinketEquipped(ITEM_TRINKET_INSIGNIA_OF_THE_ALLIANCE_WAAAGH)
            Debug("10. Insignia of the Alliance")
            UseInventoryItem(slot)

        -- Execute, this will stance dance in prot mode?
        elseif Waaagh_Configuration[ABILITY_EXECUTE_WAAAGH]
          and HasWeapon()
          and not Waaagh_Configuration[MODE_HEADER_AOE]
          and UnitMana("player") >= WaaaghExecuteCost
          and (GetActiveStance() ~= 2
          or (Waaagh_Configuration["PrimaryStance"] ~= 2
          and UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and (UnitHealth("target") / UnitHealthMax("target") * 100) <= 20
          and IsSpellReady(ABILITY_EXECUTE_WAAAGH) then
            if GetActiveStance() == 2 then
                Debug("11. Berserker Stance (Execute)")
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                DoShapeShift(1)
            else
                Debug("11. Execute")
                if WaaaghOldStance == GetActiveStance() then
                    WaaaghDanceDone = true
                end
            end
            CastSpellByName(ABILITY_EXECUTE_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Overpower when available
        elseif Waaagh_Configuration[ABILITY_OVERPOWER_WAAAGH]
          and WaaaghOverpower
          and HasWeapon()
          and not Waaagh_Configuration[MODE_HEADER_AOE]
          and UnitMana("player") >= 5
          and (GetActiveStance() == 1
          or (((Waaagh_Configuration["PrimaryStance"] ~= 2
          and (UnitHealth("target") / UnitHealthMax("target") * 100) > 20
          and not (Flurry and HasBuff("player", "Ability_GhoulFrenzy")))
          or UnitIsPlayer("target"))
          and UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_OVERPOWER_WAAAGH) then
            if GetActiveStance() ~= 1 then
                Debug("12. Battle Stance (Overpower)")
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                DoShapeShift(1)
            else
                Debug("12. Overpower")
                CastSpellByName(ABILITY_OVERPOWER_WAAAGH)
                WaaaghLastSpellCast = GetTime()
            end

        -- Pummel if casting
        elseif Waaagh_Configuration[ABILITY_PUMMEL_WAAAGH]
          and WaaaghSpellInterrupt
          and UnitMana("player") >= 10
          and (not UnitIsPlayer("target")
          or (UnitIsPlayer("target")
          and (UnitClass("target") ~= CLASS_ROGUE_WAAAGH
          and UnitClass("target") ~= CLASS_WARRIOR_WAAAGH
          and UnitClass("target") ~= CLASS_HUNTER_WAAAGH)))
          and (GetActiveStance() == 3
          or (UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_PUMMEL_WAAAGH) then
            if GetActiveStance() ~= 3 then
                Debug("13. Berserker Stance (Pummel)")
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                WaaaghLastSpellCast = GetTime()
                if UnitName("target") == BOSS_NAX_KEL_THUZAD_WAAAGH then
                    SendChatMessage(CHAT_KICKED_WAAAGH ,"SAY" ,"common")
                end
                DoShapeShift(3)
            else
                Debug("13. Pummel")
            end
            CastSpellByName(ABILITY_PUMMEL_WAAAGH)
            if UnitName("target") == BOSS_NAX_KEL_THUZAD_WAAAGH then
                SendChatMessage(CHAT_KICKED_WAAAGH ,"SAY" ,"common")
            end

        -- Shield bash to interrupt
        elseif Waaagh_Configuration[ABILITY_SHIELD_BASH_WAAAGH]
          and WaaaghSpellInterrupt
          and not Waaagh_Configuration[MODE_HEADER_AOE]
          and UnitMana("player") >= 10
          and HasShield()
          and (not UnitIsPlayer("target")
          or (UnitIsPlayer("target")
          and (UnitClass("target") ~= CLASS_ROGUE_WAAAGH
          and UnitClass("target") ~= CLASS_WARRIOR_WAAAGH
          and UnitClass("target") ~= CLASS_HUNTER_WAAAGH)))
          and (GetActiveStance() ~= 3
          or (UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])))
          and IsSpellReady(ABILITY_SHIELD_BASH_WAAAGH) then
            if GetActiveStance() == 3 then
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                Debug("14. Battle Stance (Shield Bash)")
                DoShapeShift(1)
                CastSpellByName(ABILITY_SHIELD_BASH_WAAAGH)
            else
                Debug("14. Shield Bash (interrupt)")
            end
            WaaaghDanceDone = true
            CastSpellByName(ABILITY_SHIELD_BASH_WAAAGH)
            WaaaghLastSpellCast = GetTime()
            if UnitName("target") == BOSS_NAX_KEL_THUZAD_WAAAGH then
                SendChatMessage(CHAT_KICKED_WAAAGH ,"SAY" ,"common")
            end

        -- Cast hamstring to stop runners
        elseif Waaagh_Configuration[ABILITY_HAMSTRING_WAAAGH]
          and (UnitIsPlayer("target")
          or (Waaagh_Runners[UnitName("target")]
          and (UnitHealth("target") / UnitHealthMax("target") * 100) <= tonumber(Waaagh_Configuration["HamstringHealth"])))
          and HasWeapon()
          and (not SnareDebuff("target")
          or (WaaaghImpHamstring
          and UnitMana("player") < 30))
          and WaaaghAttack == true
          and not HasBuff("target", "INV_Potion_04")
          and not HasBuff("target", "Spell_Holy_SealOfValor")
          and Waaagh_Distance() == 5
          and UnitMana("player") >= HamstringCost()
          and (GetActiveStance() ~= 2
          or (UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_HAMSTRING_WAAAGH) then
            if GetActiveStance() ~= 2 then
                Debug("15. Hamstring")
                if WaaaghOldStance == 2 then
                    WaaaghDanceDone = true
                end
            else
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                Debug("15. Berserker Stance (Hamstring)")
                if Waaagh_Configuration["PrimaryStance"] == 3 then
                    DoShapeShift(3);
                else
                    DoShapeShift(1);
                end
            end
            CastSpellByName(ABILITY_HAMSTRING_WAAAGH)

        -- Rend to antistealth
        elseif Waaagh_Configuration[ABILITY_REND_WAAAGH]
          and UnitIsPlayer("target")
          and HasWeapon()
          and (UnitClass("target") == CLASS_ROGUE_WAAAGH
          or UnitClass("target") == CLASS_HUNTER_WAAAGH)
          and UnitMana("player") >= 10
          and not HasAntiStealthDebuff()
          and (GetActiveStance() ~= 3
          or (UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_REND_WAAAGH) then
            if GetActiveStance() ~= 3 then
                Debug("16. Rend")
                if WaaaghOldStance == 3 then
                    WaaaghDanceDone = true
                end
            else
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                Debug("16. Battle Stance (Rend)")
                DoShapeShift(1)
            end
            CastSpellByName(ABILITY_REND_WAAAGH)

        -- slow target
        elseif Waaagh_Configuration[ABILITY_PIERCING_HOWL_WAAAGH]
          and WaaaghPiercingHowl
          and (UnitIsPlayer("target")
          or (Waaagh_Runners[UnitName("target")]
          and (UnitHealth("target") / UnitHealthMax("target") * 100) <= tonumber(Waaagh_Configuration["HamstringHealth"])))
          and Waaagh_Distance() <= 10
          and WaaaghAttack == true
          and not SnareDebuff("target")
          and not HasBuff("target", "INV_Potion_04")
          and not HasBuff("target", "Spell_Holy_SealOfValor")
          and UnitMana("player") >= 10
          and IsSpellReady(ABILITY_PIERCING_HOWL_WAAAGH) then
                Debug("17. Piercing Howl")
                CastSpellByName(ABILITY_PIERCING_HOWL_WAAAGH)
                WaaaghLastSpellCast = GetTime()

        -- Rooted
        elseif debuffImmobilizing
          and Waaagh_Distance() >= 8 then
            if GetActiveStance() ~= 2 then
                Debug("18. Defensive Stance (Rooted)")
                DoShapeShift(2)
            else
                if WaaaghOldStance == 2 then
                    WaaaghDanceDone = true
                end
            end
            local slot = IsTrinketEquipped(ITEM_TRINKET_LINKENS_BOOMERANG_WAAAGH)
            if slot ~= nil
              and (WaaaghSpellInterrupt
              or UnitClass("target") == CLASS_HUNTER_WAAAGH) then
                Debug("18. Linken's Boomerang")
                UseInventoryItem(slot)
            else
                slot = IsTrinketEquipped(ITEM_TRINKET_TIDAL_CHARM)
                if slot ~= nil
                  and WaaaghSpellInterrupt then
                    Debug("18. Tidal Charm")
                    UseInventoryItem(slot)
                else
                    Waaagh_Shoot()
                end
            end

        -- Berserker rage
        elseif Waaagh_Configuration[ABILITY_BERSERKER_RAGE_WAAAGH]
          and WaaaghBerserkerRage
          and not UnitIsPlayer("target")
          and UnitName("target") ~= BOSS_MC_MAGMADAR_WAAAGH
          and UnitMana("player") <= Waaagh_Configuration["MaximumRage"]
          and (GetActiveStance() == 3
          or (Waaagh_Configuration["PrimaryStance"] ~= 2
          and UnitMana("player") <= WaaaghTacticalMastery
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_BERSERKER_RAGE_WAAAGH) then
            if GetActiveStance() ~= 3 then
                Debug("19. Berserker Stance (Berserker Rage)")
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                DoShapeShift(3)
            else
                Debug("19. Berserker Rage")
                if WaaaghOldStance ~= 3 then
                    WaaaghDanceDone = true
                end
            end
            CastSpellByName(ABILITY_BERSERKER_RAGE_WAAAGH)

        -- Stance dance
        elseif Waaagh_Configuration["PrimaryStance"]
          and Waaagh_Configuration["PrimaryStance"] ~= false
          and not WaaaghOldStance
          and not WaaaghDanceDone
          and (Waaagh_Configuration["PrimaryStance"] ~= 3
          or WaaaghBerserkerStance)
          and ((WaaaghLastStanceCast
          and WaaaghLastStanceCast + 1 <= GetTime())
          or not WaaaghLastStanceCast)
          and Waaagh_Configuration["PrimaryStance"] ~= GetActiveStance()
          and UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0 then
            -- Initiate stance dance
            Debug("20. Primary Stance ("..Waaagh_Configuration["PrimaryStance"]..")")
            DoShapeShift(Waaagh_Configuration["PrimaryStance"])

        -- Disarm (PVP only)
        elseif Waaagh_Configuration[ABILITY_DISARM_WAAAGH]
          and HasWeapon()
          and UnitIsPlayer("target")
          and (UnitClass("target") == CLASS_HUNTER_WAAAGH
          or UnitClass("target") == CLASS_PALADIN_WAAAGH
          or UnitClass("target") == CLASS_ROGUE_WAAAGH
          or UnitClass("target") == CLASS_SHAMAN_WAAAGH
          or UnitClass("target") == CLASS_WARRIOR_WAAAGH)
          and UnitMana("player") >= 20
          and Waaagh_ImmuneDisarm[UnitName("target")] == nil
          and (GetActiveStance() == 2
          or (UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_DISARM_WAAAGH) then
            if GetActiveStance() ~= 2 then
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                Debug("21. Defensive Stance (Disarm)")
                DoShapeShift(2)
            else
                Debug("21. Disarm")
                if WaaaghOldStance ~= 2 then
                    WaaaghDanceDone = true
                end
            end
            CastSpellByName(ABILITY_DISARM_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Sweeping Strikes
        elseif WaaaghSweepingStrikes
          and Waaagh_Configuration[ABILITY_SWEEPING_STRIKES_WAAAGH]
          and Waaagh_GetEnemies() > 1
          and UnitMana("player") >= 30
          and IsSpellReady(ABILITY_SWEEPING_STRIKES_WAAAGH) then
            Debug("22. Sweeping Strikes")
            CastSpellByName(ABILITY_SWEEPING_STRIKES_WAAAGH)

        -- Bloodthirst
        elseif WaaaghBloodthirst
          and Waaagh_Configuration[ABILITY_BLOODTHIRST_WAAAGH]
          and not Waaagh_Configuration[MODE_HEADER_AOE]
          and UnitMana("player") >= 30
          and IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH) then
            Debug("23. Bloodthirst")
            CastSpellByName(ABILITY_BLOODTHIRST_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Mortal Strike
        elseif WaaaghMortalStrike
          and Waaagh_Configuration[ABILITY_MORTAL_STRIKE_WAAAGH]
          and HasWeapon()
          and not Waaagh_Configuration[MODE_HEADER_AOE]
          and UnitMana("player") >= 30
          and IsSpellReady(ABILITY_MORTAL_STRIKE_WAAAGH) then
            Debug("24. Mortal Strike")
            CastSpellByName(ABILITY_MORTAL_STRIKE_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Whirlwind
        elseif (Waaagh_Configuration[ABILITY_WHIRLWIND_WAAAGH]
          or Waaagh_Configuration[MODE_HEADER_AOE])
          and Waaagh_Distance() <= 10
          and HasWeapon()
          and UnitMana("player") >= 25
          and (GetActiveStance() == 3
          or (Waaagh_Configuration["PrimaryStance"] ~= 2
          and UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"])
          and Waaagh_Configuration["PrimaryStance"] ~= 0))
          and IsSpellReady(ABILITY_WHIRLWIND_WAAAGH) then
            if GetActiveStance() ~= 3 then
                if not WaaaghOldStance then
                    WaaaghOldStance = GetActiveStance()
                end
                Debug("25. Berserker Stance (Whirlwind)")
                DoShapeShift(3)
            else
                Debug("25. Whirlwind")
                if WaaaghOldStance ~= 3 then
                    WaaaghDanceDone = true
                end
            end
            CastSpellByName(ABILITY_WHIRLWIND_WAAAGH)
            WWEnemies.WWCount = 0
            WaaaghLastSpellCast = GetTime()
            WWEnemies.WWTime = GetTime()

        -- Shield Slam
        elseif Waaagh_Configuration[ABILITY_SHIELD_SLAM_WAAAGH]
          and WaaaghShieldSlam
          and HasShield()
          and UnitMana("player") >= 20
          and IsSpellReady(ABILITY_SHIELD_SLAM_WAAAGH) then
            Debug("26. Shield Slam")
            CastSpellByName(ABILITY_SHIELD_SLAM_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Sunder Armor (until 5)
        elseif Waaagh_Configuration[ABILITY_SUNDER_ARMOR_WAAAGH]
          and not HasDebuff("target", "Ability_Warrior_Sunder", 5)
          and UnitMana("player") >= 15
          and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then
            Debug("27. Sunder Armor (not 5)")
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
            WaaaghLastSpellCast = GetTime()

        -- Battle Shout
        elseif Waaagh_Configuration[ABILITY_BATTLE_SHOUT_WAAAGH]
          and not HasBuff("player", "Ability_Warrior_BattleShout")
          and UnitMana("player") >= 10
          and IsSpellReady(ABILITY_BATTLE_SHOUT_WAAAGH) then
            Debug("28. Battle Shout")
            CastSpellByName(ABILITY_BATTLE_SHOUT_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Demoralizing Shout (PVE only)
        elseif Waaagh_Configuration[ABILITY_DEMORALIZING_SHOUT_WAAAGH]
          and not HasDebuff("target", "Ability_Warrior_WarCry")
          and not HasDebuff("target", "Ability_Druid_DemoralizingRoar")
          and UnitMana("player") >= 10
          and not UnitIsPlayer("target")
          and not WaaaghFleeing
          and (UnitClass("target") == CLASS_WARRIOR_WAAAGH
          or UnitClass("target") == CLASS_ROGUE_WAAAGH)
          and UnitLevel("Player") - UnitLevel("Target") < Waaagh_Configuration["DemoDiff"]
          and WaaaghAttack == true
          and IsSpellReady(ABILITY_DEMORALIZING_SHOUT_WAAAGH) then
            Debug("29. Demoralizing Shout")
            CastSpellByName(ABILITY_DEMORALIZING_SHOUT_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Revenge
        elseif Waaagh_Configuration[ABILITY_REVENGE_WAAAGH]
          and WaaaghCombat
          and UnitMana("player") >= 5
          and WaaaghRevengeReadyUntil > GetTime()
          and IsSpellReady(ABILITY_REVENGE_WAAAGH) then
            Debug("30. Revenge")
            CastSpellByName(ABILITY_REVENGE_WAAAGH)

        -- Sunder Armor (Refresh)
        elseif Waaagh_Configuration[ABILITY_SUNDER_ARMOR_WAAAGH]
          and HasDebuff("target", "Ability_Warrior_Sunder", 5)
          and UnitMana("player") >= 15
          and GetTime() > WaaaghLastSunder + 25
          and IsSpellReady(ABILITY_SUNDER_ARMOR_WAAAGH) then
            Debug("31. Sunder Armor (refresh)")
            CastSpellByName(ABILITY_SUNDER_ARMOR_WAAAGH)
            WaaaghLastSunder = GetTime()
            WaaaghLastSpellCast = GetTime()

        -- Shield Block
        elseif Waaagh_Configuration[ABILITY_SHIELD_BLOCK_WAAAGH]
          and HasShield()
          and WaaaghCombat
          and GetActiveStance() == 2
          and UnitName("targettarget") == UnitName("player")
          and UnitLevel("Target") > UnitLevel("Player") - Waaagh_Configuration["DemoDiff"]
          and UnitMana("player") >= 10
          and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
            Debug("32. Shield Block")
            CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)

        -- Stance dance (part 2)
        elseif WaaaghDanceDone
          and WaaaghOldStance
          and WaaaghLastStanceCast + 1.5 <= GetTime()
          and UnitMana("player") <= (WaaaghTacticalMastery + Waaagh_Configuration["StanceChangeRage"]) then
            -- Initiate stance dance
            if not Waaagh_Configuration["PrimaryStance"] then
                Debug("33. Old Stance ("..WaaaghOldStance..")")
                DoShapeShift(WaaaghOldStance)
            elseif Waaagh_Configuration["PrimaryStance"] ~= 0 then
                Debug("33. Primary Stance ("..Waaagh_Configuration["PrimaryStance"]..")")
                DoShapeShift(Waaagh_Configuration["PrimaryStance"])
            end
            if WaaaghOldStance == GetActiveStance()
              or Waaagh_Configuration["PrimaryStance"] == GetActiveStance() then
                Debug("33. Variables cleared (Dance done)")
                WaaaghOldStance = nil
                WaaaghDanceDone = nil
            end

        -- Juju Flurry
        elseif WaaaghCombat
          and Waaagh_Configuration[ITEM_CONS_JUJU_FLURRY]
          and not HasBuff("player", "INV_Misc_MonsterScales_17")
          and WaaaghAttack == true
          and IsItemReady(ITEM_CONS_JUJU_FLURRY) then
            Debug("34. "..ITEM_CONS_JUJU_FLURRY)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUJU_FLURRY)

        -- Juju Chill
        elseif WaaaghCombat
          and WaaaghAttack == true
          and Waaagh_Configuration[ITEM_CONS_JUJU_CHILL]
          and not HasBuff("player", "INV_Misc_MonsterScales_09")
          and IsUseRes("frost")
          and IsItemReady(ITEM_CONS_JUJU_CHILL) then
            Debug("35. "..ITEM_CONS_JUJU_CHILL)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUJU_CHILL)

        -- Juju Ember
        elseif WaaaghCombat
          and Waaagh_Configuration[ITEM_CONS_JUJU_EMBER]
          and not HasBuff("player", "INV_Misc_MonsterScales_15")
          and IsUseRes("fire")
          and IsItemReady(ITEM_CONS_JUJU_EMBER) then
            Debug("36. "..ITEM_CONS_JUJU_EMBER)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUJU_EMBER)

        -- Juju Might
        elseif WaaaghCombat
          and WaaaghAttack == true
          and Waaagh_Configuration[ITEM_CONS_JUJU_MIGHT]
          and not HasBuff("player", "INV_Misc_MonsterScales_07")
          and not HasBuff("player", "INV_Potion_92") -- Winterfall Firewater
          and IsItemReady(ITEM_CONS_JUJU_MIGHT) then
            Debug("37. "..ITEM_CONS_JUJU_MIGHT)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUJU_MIGHT)

        -- Juju Power
        elseif WaaaghCombat
          and WaaaghAttack == true
          and Waaagh_Configuration[ITEM_CONS_JUJU_POWER]
          and not HasBuff("player", "INV_Misc_MonsterScales_11")
          and not HasBuff("player", "INV_Potion_61") -- Elixir of Giants
          and IsItemReady(ITEM_CONS_JUJU_POWER) then
            Debug("38. "..ITEM_CONS_JUJU_POWER)
            UseContainerItemByNameOnPlayer(ITEM_CONS_JUJU_POWER)

        -- Immolation potion
        elseif WaaaghCombat
          and Waaagh_Configuration[ITEM_CONS_OIL_OF_IMMOLATION]
          and not HasBuff("player", "Spell_Fire_Immolation")
          and IsItemReady(ITEM_CONS_OIL_OF_IMMOLATION) then
            Debug("39. "..ITEM_CONS_OIL_OF_IMMOLATION)
            UseContainerItemByNameOnPlayer(ITEM_CONS_OIL_OF_IMMOLATION)

        -- Racial berserking
        elseif WaaaghRacialBerserking
          and Waaagh_Configuration[RACIAL_BERSERKING_WAAAGH]
          and UnitMana("player") >= 5
          and (UnitHealth("player") / UnitHealthMax("player") * 100) <= tonumber(Waaagh_Configuration["BerserkHealth"])
          and not HasBuff("player", "Racial_Berserk")
          and IsSpellReady(RACIAL_BERSERKING_WAAAGH) then
            Debug("40. Berserking")
            CastSpellByName(RACIAL_BERSERKING_WAAAGH)
            WaaaghLastSpellCast = GetTime()

        -- Blood Waaagh (Orc racial ability)
        elseif WaaaghRacialBloodWaaagh
          and Waaagh_Configuration[RACIAL_BLOOD_WAAAGH]
          and WaaaghAttack == true
          and GetActiveStance() ~= 2
          and WaaaghCombat
          and (UnitHealth("player") / UnitHealthMax("player") * 100) >= tonumber(Waaagh_Configuration["DeathWishHealth"])
          and IsSpellReady(RACIAL_BLOOD_WAAAGH) then
            Debug("41. Blood Waaagh")
            CastSpellByName(RACIAL_BLOOD_WAAAGH)

        -- Death Wish
        elseif WaaaghDeathWish
          and Waaagh_Configuration[ABILITY_DEATH_WISH_WAAAGH]
          and UnitMana("player") >= 10
          and WaaaghAttack == true
          and GetActiveStance() ~= 2
          and WaaaghCombat
          and (UnitHealth("player") / UnitHealthMax("player") * 100) >= tonumber(Waaagh_Configuration["DeathWishHealth"])
          and IsSpellReady(ABILITY_DEATH_WISH_WAAAGH) then
            Debug("42. Death Wish")
            CastSpellByName(ABILITY_DEATH_WISH_WAAAGH)

        -- Earthstrike
        elseif Waaagh_Configuration[ITEM_TRINKET_EARTHSTRIKE]
          and WaaaghCombat
          and WaaaghAttack == true
          and IsTrinketEquipped(ITEM_TRINKET_EARTHSTRIKE) then
            Debug("43. Earthstrike")
            UseInventoryItem(IsTrinketEquipped(ITEM_TRINKET_EARTHSTRIKE))

        -- Slayer's Crest
        elseif Waaagh_Configuration[ITEM_TRINKET_SLAYERS_CREST]
          and WaaaghCombat
          and WaaaghAttack == true
          and IsTrinketEquipped(ITEM_TRINKET_SLAYERS_CREST) then
            Debug("44. Slayer's Crest")
            UseInventoryItem(IsTrinketEquipped(ITEM_TRINKET_SLAYERS_CREST))

        -- Kiss of the Spider
        elseif Waaagh_Configuration[ITEM_TRINKET_KOTS]
          and WaaaghCombat
          and WaaaghAttack == true
          and IsTrinketEquipped(ITEM_TRINKET_KOTS) then
            Debug("45. Kiss of the Spider")
            UseInventoryItem(IsTrinketEquipped(ITEM_TRINKET_KOTS))

        -- Bloodrage
        elseif Waaagh_Configuration[ABILITY_BLOODRAGE_WAAAGH]
          and UnitMana("player") <= tonumber(Waaagh_Configuration["MaximumRage"])
          and (UnitHealth("player") / UnitHealthMax("player") * 100) >= tonumber(Waaagh_Configuration["BloodrageHealth"])
          and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
            Debug("46. Bloodrage")
            CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)

        -- Treat debuffs (poisons)
        elseif Waaagh_Configuration[MODE_HEADER_DEBUFF]
          and Waaagh_TreatDebuffPlayer() then
            Debug("47. Treated debuff")

        -- Swap to Execute weapon
        elseif Waaagh_Configuration[ABILITY_EXECUTE_WAAAGH]
          and HasWeapon()
          and not Waaagh_Configuration[MODE_HEADER_AOE]
          and (UnitHealth("target") / UnitHealthMax("target") * 100) <= 21
          and Waaagh_Configuration["ExecuteSwap"]
          and Waaagh_Configuration["ExecuteSwapped"]
          and Outfitter_ExecuteCommand then
                Debug("48. Swap to Execute Profile in Outfitter")
                Outfitter_ExecuteCommand("wear Execute")
                Waaagh_Configuration["ExecuteSwapped"] = true

        -- Swap back to normal weapons
        elseif Waaagh_Configuration["ExecuteSwapped"]
          and Outfitter_ExecuteCommand
          and (((UnitHealth("target") / UnitHealthMax("target") * 100) > 21)
          or (UnitHealth("target") == 0)
          or not WaaaghCombat) then
            Debug("49. unwear Execute weapon")
            Outfitter_ExecuteCommand("unwear Execute")
            Waaagh_Configuration["ExecuteSwapped"] = false

        -- Dump rage with Heroic Strike or Cleave
        elseif (Waaagh_Configuration[MODE_HEADER_AOE]
          or Waaagh_Configuration["PrimaryStance"] == 2
          or ((Waaagh_Configuration[ABILITY_MORTAL_STRIKE_WAAAGH]
          and WaaaghMortalStrike
          and not IsSpellReady(ABILITY_MORTAL_STRIKE_WAAAGH))
          or not Waaagh_Configuration[ABILITY_MORTAL_STRIKE_WAAAGH]
          or not WaaaghMortalStrike)
          and ((Waaagh_Configuration[ABILITY_BLOODTHIRST_WAAAGH]
          and WaaaghBloodthirst
          and not IsSpellReady(ABILITY_BLOODTHIRST_WAAAGH))
          or not Waaagh_Configuration[ABILITY_BLOODTHIRST_WAAAGH]
          or not WaaaghBloodthirst)
          and ((Waaagh_Configuration[ABILITY_WHIRLWIND_WAAAGH]
          and not IsSpellReady(ABILITY_WHIRLWIND_WAAAGH))
          or not Waaagh_Configuration[ABILITY_WHIRLWIND_WAAAGH]
          or not WaaaghWhirlwind))  then

            -- Will try to lessen the amounts of Heroic Strike, when instanct attacks (MS, BT, WW) are enabled
            -- Hamstring
            if Waaagh_Configuration[ABILITY_HAMSTRING_WAAAGH]
              and HasWeapon()
              and UnitMana("player") >= HamstringCost()
              and UnitMana("player") >= tonumber(Waaagh_Configuration["FlurryTriggerRage"])
              and ((WaaaghFlurry
              and not HasBuff("player", "Ability_GhoulFrenzy"))
              or WaaaghImpHamstring
              or WaaaghSwordSpec
              or WaaaghMaceSpec)
              and IsSpellReady(ABILITY_HAMSTRING_WAAAGH) then
                -- Try trigger...
                -- stun,imp attack speed, extra swing
                Debug("51. Hamstring (Trigger ...)")
                CastSpellByName(ABILITY_HAMSTRING_WAAAGH)
                WaaaghLastSpellCast = GetTime()

            -- Heroic Strike
            elseif Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH]
              and HasWeapon()
              and not Waaagh_Configuration[MODE_HEADER_AOE]
              and UnitMana("player") >= WaaaghHeroicStrikeCost
              and (UnitMana("player") >= tonumber(Waaagh_Configuration["NextAttackRage"])
              or (not WaaaghMortalStrike
              and not WaaaghWhirlwind
              and not WaaaghBloodthirst)
              or Waaagh_Configuration["PrimaryStance"] == 2)
              and IsSpellReady(ABILITY_HEROIC_STRIKE_WAAAGH) then
                Debug("52. Heroic Strike")
                CastSpellByName(ABILITY_HEROIC_STRIKE_WAAAGH)
                WaaaghLastSpellCast = GetTime()
                -- No global cooldown, added anyway to prevent Heroic Strike from being spammed over other abilities

            -- Cleave
            elseif (Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH]
              or Waaagh_Configuration[MODE_HEADER_AOE])
              and HasWeapon()
              and UnitMana("player") >= 20
              and ((UnitMana("player") >= tonumber(Waaagh_Configuration["NextAttackRage"]))
              or (Waaagh_Configuration[MODE_HEADER_AOE] and UnitMana("player") >= 25)
              or Waaagh_Configuration["PrimaryStance"] == 2)
              and IsSpellReady(ABILITY_CLEAVE_WAAAGH) then
                Debug("53. Cleave")
                CastSpellByName(ABILITY_CLEAVE_WAAAGH)
                WaaaghLastSpellCast = GetTime()
                -- No global cooldown, added anyway to prevent Cleave from being spammed over other abilities
            elseif not WaaaghRageDumped then
                --Debug("54. Rage: "..tostring(UnitMana("player")))
                WaaaghRageDumped = true
            end
          elseif not WaaaghRageDumped then
            -- Debug("55. Rage: "..tostring(UnitMana("player")))
            WaaaghRageDumped = true
        end
    end
end

--------------------------------------------------
--
-- Handle Block command
--
--------------------------------------------------

local function Waaagh_Block()
    if GetActiveStance() ~= 2 then
        if WaaaghLastStanceCast + 1.5 <= GetTime() then
            if not WaaaghOldStance then
                WaaaghOldStance = GetActiveStance()
            end
            Debug("B1. Defensive Stance (Block")
            DoShapeShift(2)
        end
    end
    if Waaagh_Configuration[ABILITY_SHIELD_BLOCK_WAAAGH]
      and HasShield()
      and UnitMana("player") >= 10
      and IsSpellReady(ABILITY_SHIELD_BLOCK_WAAAGH) then
        CastSpellByName(ABILITY_SHIELD_BLOCK_WAAAGH)
        Debug("B2. Shield Block")
        WaaaghDanceDone = true
        WaaaghLastSpellCast = GetTime()
    elseif Waaagh_Configuration[ABILITY_BLOODRAGE_WAAAGH]
      and UnitMana("player") < 10
      and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
        Debug("B3. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)
    end
end

--------------------------------------------------
--
-- Handle charge command
--
--------------------------------------------------

local function Waaagh_Charge()
    local dist = Waaagh_Distance()
    if not UnitExists("target") and
      not WaaaghCombat then
        if Waaagh_Configuration["PrimaryStance"]
           and Waaagh_Configuration["PrimaryStance"] ~= 0
           and GetActiveStance() ~= Waaagh_Configuration["PrimaryStance"] then
            DoShapeShift(Waaagh_Configuration["PrimaryStance"])
        end
        Debug("No target")
        return
    end
    if WaaaghMount
      and dist <= 25 then
        -- Dismount as a first step
        Debug("Dismounting")
        Dismount()
        WaaaghMount = nil
    end
    if WaaaghCombat then
        if Waaagh_Configuration["AutoAttack"]
          and not WaaaghAttack then
            -- Auto attack closest target
            AttackTarget()
        end
        if Waaagh_Configuration[ABILITY_THUNDER_CLAP_WAAAGH]
          and WaaaghLastChargeCast + 0.6 <= GetTime()
          and dist <= 7
          and not SnareDebuff("target")
          and UnitMana("player") >= WaaaghThunderClapCost
          and IsSpellReady(ABILITY_THUNDER_CLAP_WAAAGH) then
            if GetActiveStance() ~= 1 then
                if WaaaghOldStance == nil then
                    WaaaghOldStance = GetActiveStance()
                end
                Debug("C1.Arms Stance, Thunder Clap")
                DoShapeShift(1)
            else
                Debug("C1.Thunder Clap")
                if WaaaghOldStance == 1 then
                    WaaaghDanceDone = true
                end
                CastSpellByName(ABILITY_THUNDER_CLAP_WAAAGH)
                WaaaghLastSpellCast = GetTime()
            end

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

        elseif Waaagh_Configuration[ABILITY_BLOODRAGE_WAAAGH]
          and GetActiveStance() == 3
          and UnitMana("player") < 10
          and dist <= 25
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH)
          and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
            Debug("C3. Bloodrage")
            CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)

        elseif Waaagh_Configuration[ABILITY_BERSERKER_RAGE_WAAAGH]
          and WaaaghBerserkerRage
          and GetActiveStance() == 3
          and UnitMana("player") < 10
          and not IsSpellReady(ABILITY_BLOODRAGE_WAAAGH)
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH)
          and IsSpellReady(ABILITY_BERSERKER_RAGE_WAAAGH) then
            Debug("C4. Berserker Rage")
            CastSpellByName(ABILITY_BERSERKER_RAGE_WAAAGH)

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
        if Waaagh_Configuration[ABILITY_CHARGE_WAAAGH]
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

        elseif Waaagh_Configuration[ABILITY_THUNDER_CLAP_WAAAGH]
          and GetActiveStance() == 1
          and dist <= 5
          and not SnareDebuff("target")
          and UnitMana("player") >= WaaaghThunderClapCost
          and IsSpellReady(ABILITY_THUNDER_CLAP_WAAAGH) then
            Debug("O3. Thunder Clap")
            CastSpellByName(ABILITY_THUNDER_CLAP_WAAAGH)
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

        elseif Waaagh_Configuration[ABILITY_BERSERKER_RAGE_WAAAGH]
          and WaaaghBerserkerRage
          and GetActiveStance() == 3
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH)
          and not IsSpellReady(ABILITY_CHARGE_WAAAGH)
          and dist <= 25
          and UnitMana("player") < 10
          and not IsSpellReady(ABILITY_BLOODRAGE_WAAAGH)
          and IsSpellReady(ABILITY_BERSERKER_RAGE_WAAAGH) then
            Debug("O5. Berserker Rage")
            CastSpellByName(ABILITY_BERSERKER_RAGE_WAAAGH)

        elseif Waaagh_Configuration[ABILITY_BLOODRAGE_WAAAGH]
          and GetActiveStance() == 3
          and dist <= 25
          and IsSpellReady(ABILITY_INTERCEPT_WAAAGH)
          and not IsSpellReady(ABILITY_CHARGE_WAAAGH)
          and UnitMana("player") < 10
          and IsSpellReady(ABILITY_BLOODRAGE_WAAAGH) then
            Debug("O6. Bloodrage")
            CastSpellByName(ABILITY_BLOODRAGE_WAAAGH)

        elseif Waaagh_Configuration[ABILITY_CHARGE_WAAAGH]
          and GetActiveStance() ~= 1
          and dist > 7
          and IsSpellReadyIn(ABILITY_CHARGE_WAAAGH) <= 5 then
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

--------------------------------------------------
-- Scan spell book and talents
local function Waaagh_ScanTalents()
    local i = 1
    Debug("Scanning Spell Book")
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then
            break
        end
        if spellName == ABILITY_BERSERKER_STANCE_WAAAGH then
            WaaaghBerserkerStance = true
            Debug(ABILITY_BERSERKER_STANCE_WAAAGH)
        elseif spellName == ABILITY_DEFENSIVE_STANCE_WAAAGH then
            WaaaghDefensiveStance = true
            Debug(ABILITY_DEFENSIVE_STANCE_WAAAGH)
        end
        i = i + 1
    end
    Debug("Scanning Talent Tree")
    -- Calculate the cost of Heroic Strike based on talents
    local _, _, _, _, currRank = GetTalentInfo(1, 1)
    WaaaghHeroicStrikeCost = (15 - tonumber(currRank))
    if WaaaghHeroicStrikeCost < 15 then
        Debug("Heroic Cost")
    end
    -- Calculate the rage retainment of Tactical Mastery
    local _, _, _, _, currRank = GetTalentInfo(1, 5)
    WaaaghTacticalMastery = (tonumber(currRank) * 5)
    if WaaaghTacticalMastery > 0 then
        Debug("Tactical Mastery")
    end
    local _, _, _, _, currRank = GetTalentInfo(1, 6)
    WaaaghThunderClapCost = (20 - tonumber(currRank))
    if WaaaghThunderClapCost < 20 then
        Debug("Improved Thunder Clap")
    end
    -- Check for Sweeping Strikes
    local _, _, _, _, currRank = GetTalentInfo(1, 13)
    if currRank > 0 then
        Debug("Sweeping Strikes")
        WaaaghSweepingStrikes = true
    else
        WaaaghSweepingStrikes = false
    end
    -- Check for Mace Specializaton
    local _, _, _, _, currRank = GetTalentInfo(1, 14)
    if currRank > 0 then
        Debug("Mace Specializaton")
        WaaaghMaceSpec = true
    else
        WaaaghMaceSpec = false
    end
    -- Check for Sword Specializaton
    local _, _, _, _, currRank = GetTalentInfo(1, 15)
    if currRank > 0 then
        Debug("Sword Specializaton")
        WaaaghSwordSpec = true
    else
        WaaaghSwordSpec = false
    end
    -- Check for Improved Hamstring
    local _, _, _, _, currRank = GetTalentInfo(1, 17)
    if currRank > 0 then
        Debug("Improved Hamstring")
        WaaaghImpHamstring = true
    else
        WaaaghImpHamstring = false
    end
    -- Check for Mortal Strike
    local _, _, _, _, currRank = GetTalentInfo(1, 18)
    if currRank > 0 then
        Debug("Mortal Strike")
        WaaaghMortalStrike = true
    else
        WaaaghMortalStrike = false
    end
    -- Check for Piercing Howl
    local _, _, _, _, currRank = GetTalentInfo(2, 6)
    if currRank > 0 then
        Debug("Piercing Howl")
        WaaaghPiercingHowl = true
    else
        WaaaghPiercingHowl = false
    end
    -- Calculate the cost of Execute based on talents
    local _, _, _, _, currRank = GetTalentInfo(2, 10)
    WaaaghExecuteCost = (15 - strsub(tonumber(currRank) * 2.5, 1, 2))
    if WaaaghExecuteCost < 15 then
        Debug("Execute Cost")
    end
    -- Check for Death Wish
    local _, _, _, _, currRank = GetTalentInfo(2, 13)
    if currRank > 0 then
        Debug("Death Wish")
        WaaaghDeathWish = true
    else
        WaaaghDeathWish = false
    end
    -- Check for Improved Berserker Rage
    local _, _, _, _, currRank = GetTalentInfo(2, 15)
    if currRank > 0 then
        Debug("Improved Berserker Rage")
        WaaaghBerserkerRage = true
    else
        WaaaghBerserkerRage = false
    end
    -- Check for Flurry
    local _, _, _, _, currRank = GetTalentInfo(2, 16)
    if currRank > 0 then
        Debug("Flurry")
        WaaaghFlurry = true
    else
        WaaaghFlurry = false
    end

    -- Check for Bloodthirst
    local _, _, _, _, currRank = GetTalentInfo(2, 17)
    if currRank > 0 then
        Debug("Bloodthirst")
        WaaaghBloodthirst =  true
    else
        WaaaghBloodthirst = false
    end
    -- Check for Shield Slam
    local _, _, _, _, currRank = GetTalentInfo(3, 17)
    if currRank > 0 then
        Debug("Shield Slam")
        WaaaghShieldSlam =  true
    else
        WaaaghShieldSlam = false
    end
    if UnitRace("player") == RACE_ORC then
        Debug("Blood Waaagh")
        WaaaghRacialBloodWaaagh = true
    else
        WaaaghRacialBloodWaaagh = false
    end
    if UnitRace("player") == RACE_TROLL then
        Debug("Berserking")
        WaaaghRacialBerserking = true
    else
        WaaaghRacialBerserking = false
    end
    if SpellId("Whirlwind") then
        Debug("Whirlwind")
        WaaaghWhirlwind = true
    else
        WaaaghWhirlwind = false
    end
    WaaaghTalents = true
end

--------------------------------------------------
--
-- Chat Handlers
--
--------------------------------------------------
-- Helper to set option to value
local function SetOptionRange(option, text, value, vmin, vmax)
    if value ~= "" then
        if tonumber(value) < vmin then
            value = vmin
        elseif tonumber(value) > vmax then
            value = vmax
        end
        Waaagh_Configuration[option] = tonumber(value)
    else
        value = Waaagh_Configuration[option]
    end
    Print(text..value..".")
end

--------------------------------------------------
-- Print option if it is enabled
local function PrintEnabledOption(option, text)
    if Waaagh_Configuration[option] == true then
        Print(text.." "..TEXT_WAAAGH_ENABLED..".")
    end
end

--------------------------------------------------
-- Helper to toggle option
local function ToggleOption(option, text)
    if Waaagh_Configuration[option] == true then
        Waaagh_Configuration[option] = false
        Print(text.." "..TEXT_WAAAGH_DISABLED..".")
    elseif Waaagh_Configuration[option] == false then
        Waaagh_Configuration[option] = true
        Print(text.." "..TEXT_WAAAGH_ENABLED..".")
    else
        return false
    end
    return true
end

--------------------------------------------------
-- Help
local function DoHelp(commands, options)
    Print(options)
    if options == nil
      or options == "" then
        local cmds = ""
        cmds = SLASH_WAAAGH_HELP
        for k,_ in pairs(commands) do
            if cmds ~= ""
              and cmds ~= SLASH_WAAAGH_HELP then
                cmds = cmds..", "
            end
            cmds = cmds..k
            if string.len(cmds) > 80 then
                Print(cmds)
                cmds = ""
            end
        end
        Print(cmds)
    elseif commands[options] ~= nil then
        Print(commands[options].help)
    else
        Print(HELP_UNKNOWN)
    end
end
--------------------------------------------------
local tankmode = {
 {"PrimaryStance", 2 },
 {ABILITY_SUNDER_ARMOR_WAAAGH, true },
 {ABILITY_REVENGE_WAAAGH, true },
 {ABILITY_OVERPOWER_WAAAGH, false },
 {ABILITY_DEMORALIZING_SHOUT_WAAAGH, true }
}

function Waaagh_Togglemode(mode, prefix)
    if Waaagh_Configuration[prefix] == true then
        -- Enable damage setup
        Waaagh_Configuration[prefix] = false
        for i, k in mode do
            Waaagh_Configuration[k[1]] = Waaagh_Configuration[prefix..k[1]]
        end
        Print(prefix.." "..TEXT_WAAAGH_DISABLED..".")
    else
        -- Enable Tank setup
        Waaagh_Configuration[prefix] = true
        for i, k in mode do
            Waaagh_Configuration[prefix..k[1]] = Waaagh_Configuration[k[1]]
            Waaagh_Configuration[k[1]] = k[2]
        end
        Print(prefix.." "..TEXT_WAAAGH_ENABLED..".")
    end
end

--------------------------------------------------
-- Handle incomming slash commands
function Waaagh_SlashCommand(msg)
    local _, _, command, options = string.find(msg, "([%w%p]+)%s*(.*)$")
    if command then
        command = string.lower(command)
    end
    if not (UnitClass("player") == CLASS_WARRIOR_WAAAGH) then
        return
    end
    local commands = {
        ["ability"] = { help = HELP_ABILITY, fn = function(options)
                if options == ABILITY_HEROIC_STRIKE_WAAAGH
                  and not Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] then
                    Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] = true
                    Print(ABILITY_HEROIC_STRIKE_WAAAGH.." "..TEXT_WAAAGH_ENABLED..".")
                    if Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH] then
                        Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH] = false
                        Print(ABILITY_CLEAVE_WAAAGH.." "..TEXT_WAAAGH_DISABLED..".")
                    end
                elseif options == ABILITY_CLEAVE_WAAAGH
                  and not Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH] then
                    Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH] = true
                    Print(ABILITY_CLEAVE_WAAAGH.." "..TEXT_WAAAGH_ENABLED..".")
                    if Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] then
                        Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] = falses
                        Print(ABILITY_HEROIC_STRIKE_WAAAGH.." "..TEXT_WAAAGH_DISABLED..".")
                    end
                elseif Waaagh_Configuration[options] then
                    Waaagh_Configuration[options] = false
                    Print(options.." "..TEXT_WAAAGH_DISABLED..".")
                elseif Waaagh_Configuration[options] == false then
                    Waaagh_Configuration[options] = true
                    Print(options.." "..TEXT_WAAAGH_ENABLED..".")
                else
                    Print(options.." "..TEXT_WAAAGH_NOT_FOUND..".")
                end
            end },

        ["aoe"] = { help = HELP_AOE, fn = function(options)
                ToggleOption(MODE_HEADER_AOE, MODE_HEADER_AOE)
            end },

        ["attack"] = { help = HELP_ATTACK, fn = function(options)
                ToggleOption("AutoAttack", SLASH_WAAAGH_AUTOATTACK)
            end },

        ["attackrage"] = { help = HELP_ATTACKRAGE, fn = function(options)
                SetOptionRange("NextAttackRage", SLASH_WAAAGH_ATTACKRAGE, options, 0 , 100)
            end },

        ["berserk"] = { help = HELP_BERSERK, fn = function(options)
                SetOptionRange("BerserkHealth", SLASH_WAAAGH_TROLL, options, 1, 100)
            end },

        ["block"] = { help = HELP_BLOCK, fn = function(options)
                Waaagh_Block()
            end },

        ["bloodrage"] = { help = HELP_BLOODRAGE, fn = function(options)
                SetOptionRange("BloodrageHealth", SLASH_WAAAGH_BLOODRAGE, options, 1, 100)
            end },

        ["charge"] = { help = HELP_CHARGE, fn = function(options)
                Waaagh_Charge()
            end },

        ["cons"] = { help = HELP_CONS, fn = function(options)
                PrintEnabledOption(ITEM_CONS_JUJU_FLURRY, ITEM_CONS_JUJU_FLURRY)
                PrintEnabledOption(ITEM_CONS_JUJU_CHILL, ITEM_CONS_JUJU_CHILL)
                PrintEnabledOption(ITEM_CONS_JUJU_MIGHT, ITEM_CONS_JUJU_MIGHT)
                PrintEnabledOption(ITEM_CONS_JUJU_EMBER, ITEM_CONS_JUJU_EMBER)
                PrintEnabledOption(ITEM_CONS_JUJU_POWER, ITEM_CONS_JUJU_POWER)
                PrintEnabledOption(ITEM_CONS_OIL_OF_IMMOLATION, ITEM_CONS_OIL_OF_IMMOLATION)
                PrintEnabledOption(MODE_HEADER_DEBUFF, MODE_HEADER_DEBUFF)
            end },

        ["dance"] = { help = HELP_DANCE, fn = function(options)
                SetOptionRange("StanceChangeRage", SLASH_WAAAGH_DANCE, options, 0, 100)
            end },

        ["deathwish"] = { help = HELP_DEATHWISH, fn = function(options)
                SetOptionRange("DeathWishHealth", SLASH_WAAAGH_DEATHWISH, options, 1, 100)
            end },

        ["debuff"] = { help = HELP_DEBUFF, fn = function(options)
                ToggleOption(MODE_HEADER_DEBUFF, MODE_HEADER_DEBUFF)
            end },

        ["debug"] = { help = HELP_DEBUG, fn = function(options)
                ToggleOption("Debug", SLASH_WAAAGH_DEBUG)
            end },

        ["default"] = { help = HEL_DEFAULT, fn = function(options)
                UpdateConfiguration(true) -- Set configurtion to default
            end },

        ["demodiff"] = { help = HELP_DEMODIFF, fn = function(options)
                SetOptionRange("DemoDiff", SLASH_WAAAGH_DEMODIFF, options, -3, 60)
            end },

        ["distance"] = { help = HELP_DISTANCE, fn = function(options)
                if UnitCanAttack("player", "target") then
                    Print(TEXT_WAAAGH_DISTANCE.." "..Waaagh_Distance().." "..TEXT_WAAAGH_YARDS)
                else
                    Print(TEXT_WAAAGH_NO_ATTACKABLE_TARGET)
                end
            end },

        ["earthstrike"] = { help = HELP_EARTHSTRIKE, fn = function(options)
                ToggleOption(ITEM_TRINKET_EARTHSTRIKE, ITEM_TRINKET_EARTHSTRIKE)
            end },

        ["executeswap"] = { help = HELP_EXECUTESWAP, fn = function(options)
                ToggleOption("ExecuteSwap", "Execute Swap")
            end },

        ["flurrytrigger"] = { help = HELP_FLURRYTRIGGER, fn = function(options)
                SetOptionRange("FlurryTriggerRage", SLASH_WAAAGH_FLURRYTRIGGER, options, 0, 100)
            end },

        ["hamstring"] = { help = HELP_HAMSTRING, fn = function(options)
                SetOptionRange("HamstringHealth", SLASH_WAAAGH_HAMSTRING, options, 1, 100)
            end },

        ["help"] = { help = HELP_HELP, fn = nil },

        ["juju"] = { help = HELP_JUJU, fn = function(options)
                local juju = {
                    flurry = function()
                            ToggleOption(ITEM_CONS_JUJU_FLURRY, ITEM_CONS_JUJU_FLURRY)
                        end,
                    chill = function()
                            ToggleOption(ITEM_CONS_JUJU_CHILL, ITEM_CONS_JUJU_CHILL)
                        end,
                    might = function()
                            ToggleOption(ITEM_CONS_JUJU_MIGHT, ITEM_CONS_JUJU_MIGHT)
                        end,
                    ember = function()
                            ToggleOption(ITEM_CONS_JUJU_EMBER, ITEM_CONS_JUJU_EMBER)
                        end,
                    power = function()
                            ToggleOption(ITEM_CONS_JUJU_POWER, ITEM_CONS_JUJU_POWER)
                        end
                    }
                if juju[options] then
                    juju[options]()
                else
                    Print(HELP_JUJU)
                end
            end },

        ["kots"] = { help = HELP_KOTS, fn = function(options)
                ToggleOption(ITEM_TRINKET_KOTS, ITEM_TRINKET_KOTS)
            end },

        ["log"] = { help = HELP_LOG, fn = function(options)
                if options == "on" then
                    LogToFile(true)
                else
                    LogToFile(false)
                end
            end },

        ["ooi"] = { help = HELP_OOI, fn = function(options)
                ToggleOption(ITEM_CONS_OIL_OF_IMMOLATION, ITEM_CONS_OIL_OF_IMMOLATION)
            end },

        ["prot"] = { help = HELP_PROT, fn = function()
                Waaagh_Togglemode(tankmode, MODE_HEADER_PROT)
            end },

        ["rage"] = { help = HELP_RAGE, fn = function(options)
                SetOptionRange("MaximumRage", SLASH_WAAAGH_RAGE, options, 0, 100)
            end },

        ["shoot"] = { help = HELP_SHOOT, fn = function(options)
                Waaagh_Shoot()
            end },

        slayer = { help = HELP_SLAYERS_CREST, fn = function(options)
                ToggleOption(ITEM_TRINKET_SLAYERS_CREST, ITEM_TRINKET_SLAYERS_CREST)
            end },
        ["slayer's"] = { help = HELP_SLAYERS_CREST, fn = function(options)
                ToggleOption(ITEM_TRINKET_SLAYERS_CREST, ITEM_TRINKET_SLAYERS_CREST)
            end },

        ["stance"] = { help = HELP_STANCE, fn = function(options)
                if options == ABILITY_BATTLE_STANCE_WAAAGH
                  or options == "1" then
                    Waaagh_Configuration["PrimaryStance"] = 1
                    Print(SLASH_WAAAGH_STANCE..ABILITY_BATTLE_STANCE_WAAAGH..".")
                elseif options == ABILITY_DEFENSIVE_STANCE_WAAAGH
                  or options == "2" then
                    Waaagh_Configuration["PrimaryStance"] = 2
                    Print(SLASH_WAAAGH_STANCE..ABILITY_DEFENSIVE_STANCE_WAAAGH..".")
                elseif options == ABILITY_BERSERKER_STANCE_WAAAGH
                  or options == "3" then
                    Waaagh_Configuration["PrimaryStance"] = 3
                    Print(SLASH_WAAAGH_STANCE..ABILITY_BERSERKER_STANCE_WAAAGH..".")
                elseif options == "default" then
                    Waaagh_Configuration["PrimaryStance"] = false
                    Print(SLASH_WAAAGH_STANCE..TEXT_WAAAGH_DEFAULT..".")
                else
                    Waaagh_Configuration["PrimaryStance"] = 0
                    Print(SLASH_WAAAGH_NOSTANCE..TEXT_WAAAGH_DISABLED..".")
                end
            end },

        ["talents"] = { help = HELP_TALENTS, fn = function(options)
                Print(CHAT_TALENTS_RESCAN_WAAAGH)
                Waaagh_InitDistance()
                Waaagh_ScanTalents()
            end },

        ["threat"] = { help = HELP_THREAT, fn = function(options)
                -- If HS then use cleave, if cleave then use HS
                if Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] then
                    Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] = false
                    Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH] = true
                    Print(SLASH_WAAAGH_LOWTHREAT)
                else
                    Waaagh_Configuration[ABILITY_CLEAVE_WAAAGH] = false
                    Waaagh_Configuration[ABILITY_HEROIC_STRIKE_WAAAGH] = true
                    Print(SLASH_WAAAGH_HIGHTHREAT)
                end
            end },

        ["toggle"] = { help = HELP_TOGGLE, fn = function(options)
                ToggleOption("Enabled", BINDING_HEADER_WAAAGH)
            end },

        ["unit"] = { help = HELP_UNIT, fn = function(options)
                if options ~= nil
                  and options ~= "" then
                    target = options
                elseif UnitName("target") ~= nil then
                    target = "target"
                else
                    target = "player"
                end
                Print(TEXT_WAAAGH_NAME..(UnitName(target) or "")..TEXT_WAAAGH_CLASS..(UnitClass(target) or "")..TEXT_WAAAGH_CLASSIFICATION..(UnitClassification(target) or ""))
                if UnitRace(target) then
                    Print(TEXT_WAAAGH_RACE..(UnitRace(target) or ""))
                else
                    Print(TEXT_WAAAGH_TYPE..(UnitCreatureType(target) or ""))
                end
                PrintEffects(target)
            end },

        ["version"] = { help = HELP_VERSION, fn = function(options)
                Print(SLASH_WAAAGH_VERSION.." "..WAAAGH_VERSION)
            end },

        ["where"] = { help = HELP_WHERE, fn = function(options)
        
                Print(TEXT_WAAAGH_MAP_ZONETEXT..(GetMinimapZoneText() or ""))
                Print(TEXT_WAAAGH_REAL_ZONETEXT..(GetRealZoneText() or ""))
                Print(TEXT_WAAAGH_SUB_ZONETEXT..(GetSubZoneText() or ""))
                Print(TEXT_WAAAGH_PVP_INFO..(GetZonePVPInfo() or ""))
                Print(TEXT_WAAAGH_ZONETEXT..(GetZoneText() or ""))
            end },

        }

    if command == nil
      or command == "" then
        Waaagh()
    else
        local cmd = commands[command]
        if cmd ~= nil
          and cmd.fn ~= nil then
            cmd.fn(options)
        elseif command == "help" then
            DoHelp(commands, options)
        elseif cmd then
            Print(HELP_UNKNOWN..command)
        else
            DoHelp(commands, "")
        end
    end
end

--------------------------------------------------
--
-- Event Handlers
--
--------------------------------------------------
-- Callback on load
function Waaagh_OnLoad()
    local evs = {
        "CHARACTER_POINTS_CHANGED",
        "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
        "CHAT_MSG_COMBAT_SELF_MISSES",
        "CHAT_MSG_MONSTER_EMOTE",
        "CHAT_MSG_SPELL_AURA_GONE_SELF",
        "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
        "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF",
        "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
        "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
        "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
        "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",
        "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
        "CHAT_MSG_SPELL_SELF_DAMAGE",
        "PLAYER_AURAS_CHANGED",
        "PLAYER_ENTER_COMBAT",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVE_COMBAT",
        "PLAYER_LEVEL_UP",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "PLAYER_TARGET_CHANGED",
        "VARIABLES_LOADED",
    }
    for _, ev in pairs(evs) do
        this:RegisterEvent(ev)
    end

    WWEnemies = { Hist = {}, WWTime = 0, WWCount = nil, CleaveTime = 0, CleaveCount = nil }
    for i = 0,5 do
        WWEnemies.Hist[i] = 0
    end

    WaaaghLastSpellCast = GetTime()
    WaaaghLastStanceCast = GetTime()
    WaaaghLastLog = GetTime()
    WaaaghRevengeTime = 0
    WaaaghLastChargeCast = 0
    WaaaghRevengeReadyUntil = 0
    FlurryCombatTotal = 0
    WaaaghCombatTotal = 0
    SlashCmdList["WAAAGH"] = Waaagh_SlashCommand
    SLASH_WAAAGH1 = "/waaagh"
end

--------------------------------------------------
-- Event handler
function Waaagh_OnEvent(event)

    if event == "VARIABLES_LOADED" then
        -- Check for settings
        Waaagh_Configuration_Init()

    elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES"
      or event == "CHAT_MSG_SPELL_SELF_DAMAGE"
      or event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
      and (string.find(arg1, CHAT_OVERPOWER1_WAAAGH)
      or string.find(arg1, CHAT_OVERPOWER2_WAAAGH)) then
        -- Check to see if enemy dodges
        WaaaghOverpower = GetTime()

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE"
      and (string.find(arg1, CHAT_OVERPOWER3_WAAAGH)
      or string.find(arg1, CHAT_OVERPOWER4_WAAAGH)
      or string.find(arg1, CHAT_OVERPOWER5_WAAAGH)) then
        -- Check to see if Overpower is used
        WaaaghOverpower = nil

    elseif event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE"
      or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"
      or event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF"
      or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"  then
        -- Check to see if enemy casts spell
        for mob, spell in string.gfind(arg1, CHAT_CAST_WAAAGH) do
            if mob == UnitName("target")
              and UnitCanAttack("player", "target")
              and mob ~= spell then
                WaaaghSpellInterrupt = GetTime()
                return
            end
        end

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE"
      and string.find(arg1, CHAT_INTERRUPT1_WAAAGH)
      or event == "CHAT_MSG_COMBAT_SELF_MISSES"
      and (string.find(arg1, CHAT_INTERRUPT2_WAAAGH)
      or string.find(arg1, CHAT_INTERRUPT3_WAAAGH)
      or string.find(arg1, CHAT_INTERRUPT4_WAAAGH)
      or string.find(arg1, CHAT_INTERRUPT5_WAAAGH)) then
        -- Check to see if Pummel/Shield Bash is used
        WaaaghSpellInterrupt = nil

    elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE"
      or event == "CHAT_MSG_COMBAT_SELF_MISSES")
      and string.find(arg1, CHAT_WHIRLWIND_WAAAGH) then
        if WWEnemies.WWCount == nil then
            WWEnemies.WWCount = 1
        else
            WWEnemies.WWCount = WWEnemies.WWCount + 1
        end

    elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE"
      or event == "CHAT_MSG_COMBAT_SELF_MISSES")
      and string.find(arg1, CHAT_CLEAVE_WAAAGH) then
        if WWEnemies.CleaveCount == nil then
            WWEnemies.CleaveCount = 1
            WWEnemies.CleaveTime = GetTime()
        else
            WWEnemies.CleaveCount = WWEnemies.CleaveCount + 1
        end

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        -- Check to see if getting affected by breakable effects
        if arg1 == CHAT_SAP_WAAAGH
          or arg1 == CHAT_GOUGE_WAAAGH
          or arg1 == CHAT_REPENTANCE_WAAAGH
          or arg1 == CHAT_ROCKET_HELM_WAAAGH then
            WaaaghIncapacitate = true

        elseif arg1 == CHAT_FEAR_WAAAGH
          or arg1 == CHAT_INTIMIDATING_SHOUT_WAAAGH
          or arg1 == CHAT_PSYCHIC_SCREAM_WAAAGH
          or arg1 == CHAT_PANIC_WAAAGH
          or arg1 == CHAT_BELLOWING_ROAR_WAAAGH
          or arg1 == CHAT_ANCIENT_DESPAIR_WAAAGH
          or arg1 == CHAT_TERRIFYING_SCREECH_WAAAGH
          or arg1 == CHAT_HOWL_OF_TERROR_WAAAGH then
            WaaaghFear = true
        end

    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        -- Check to see if breakable effects fades
        if arg1 == CHAT_SAP2_WAAAGH
          or arg1 == CHAT_GOUGE2_WAAAGH
          or arg1 == CHAT_REPENTANCE2_WAAAGH
          or arg1 == CHAT_ROCKET_HELM2_WAAAGH then
            WaaaghIncapacitate = nil

        elseif arg1 == CHAT_FEAR2_WAAAGH
          or arg1 == CHAT_INTIMIDATING_SHOUT2_WAAAGH
          or arg1 == CHAT_PSYCHIC_SCREAM2_WAAAGH
          or arg1 == CHAT_PANIC2_WAAAGH
          or arg1 == CHAT_BELLOWING_ROAR2_WAAAGH
          or arg1 == CHAT_ANCIENT_DESPAIR2_WAAAGH
          or arg1 == CHAT_TERRIFYING_SCREECH2_WAAAGH
          or arg1 == CHAT_HOWL_OF_TERROR2_WAAAGH then
            WaaaghFear = nil

        elseif arg1 == CHAT_LOST_FLURRY_WAAAGH then
            if WaaaghFlurryStart then
                FlurryCombatTotal = FlurryCombatTotal + (GetTime() - WaaaghFlurryStart)
                WaaaghFlurryStart = nil
            end
            if WaaaghAttackEnd
              and WaaaghFlurry
              and (FlurryCombatTotal > 0) 
              and (WaaaghCombatTotal > 0) then
                local p = math.floor(FlurryCombatTotal / WaaaghCombatTotal * 100)
                Debug(TEXT_WAAAGH_FLURRY..p.."%")
                FlurryCombatTotal = 0
                WaaaghCombatTotal = 0
            end
        end

    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" then
        -- set up time for revenge
        if string.find(arg1, CHAT_BLOCK_WAAAGH)
          or string.find(arg1, CHAT_PARRY_WAAAGH)
          or string.find(arg1, CHAT_DODGE_WAAAGH) then
            WaaaghRevengeReadyUntil = GetTime() + 4
        end

    elseif event == "CHAT_MSG_MONSTER_EMOTE" then
        -- Check to see if enemy flees
        Waaagh_RunnerDetect(arg1, arg2)

    elseif event == "PLAYER_AURAS_CHANGED" then
        -- Check to see if mounted
        if UnitIsMounted("player") then
            WaaaghMount = true
        else
            WaaaghMount = false
        end

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        if arg1 == CHAT_GAINED_FLURRY_WAAAGH then
            WaaaghFlurryStart = GetTime()
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Reset Overpower and interrupts, check to see if talents are being calculated
        Waaagh_SetEnemies(1)
        WaaaghOverpower = nil
        WaaaghFleeing = nil
        WaaaghSpellInterrupt = nil
        if not WaaaghTalents
          and UnitClass("player") == CLASS_WARRIOR_WAAAGH then
            if Waaagh_Configuration["DebugChannel"] then
                LogToFile(true)
            end
            Waaagh_InitDistance()
            Waaagh_ScanTalents()
         end

      elseif (event == "CHARACTER_POINTS_CHANGED"
        and arg1 == -1)
        or event == "PLAYER_LEVEL_UP"
        or event == "PLAYER_ENTERING_WORLD"
        and UnitClass("player") == CLASS_WARRIOR_WAAAGH then
            if Waaagh_Configuration["DebugChannel"] then
                LogToFile(true)
            end
            Waaagh_InitDistance()
            Waaagh_ScanTalents()

    elseif event == "PLAYER_REGEN_DISABLED" then
        WaaaghCombat = true
        WaaaghCombatStart = GetTime()
        FlurryCombatTotal = 0
        WaaaghCombatTotal = 0
        if not WaaaghAttackStart then
            WaaaghAttackEnd = nil
            WaaaghAttackStart = WaaaghCombatStart
         end

    elseif event == "PLAYER_REGEN_ENABLED" then
        WaaaghCombatEnd = GetTime()
        WaaaghCombat = nil
        WaaaghDanceDone = nil
        WaaaghOldStance = nil
        WaaaghFlurryStart = nil
        if WaaaghFlurry
          and (FlurryCombatTotal > 0) then
            local p = math.floor(FlurryCombatTotal / WaaaghCombatTotal * 100)
            Debug(TEXT_WAAAGH_FLURRY..p.."%")
            FlurryCombatTotal = 0
            WaaaghCombatTotal = 0
        end
        for slot = 1, 18 do
            local name = CheckCooldown(slot)
            if name then
                Print(name.." "..CHAT_IS_ON_CD_WAAAGH)
            end
        end

    elseif event == "PLAYER_ENTER_COMBAT" then
        WaaaghAttack = true
        WaaaghAttackEnd = nil
        WaaaghAttackStart = GetTime()
        if HasBuff("player", "Ability_GhoulFrenzy") then
            WaaaghFlurryStart = GetTime()
        end

    elseif event == "PLAYER_LEAVE_COMBAT" then
        WaaaghAttack = nil
        if WaaaghAttackStart then
            WaaaghAttackEnd = GetTime()
            WaaaghCombatTotal = WaaaghCombatTotal + (WaaaghAttackEnd - WaaaghAttackStart)
            if WaaaghFlurryStart then
                FlurryCombatTotal = FlurryCombatTotal + (WaaaghAttackEnd - WaaaghFlurryStart)
                WaaaghFlurryStart = nil
            end
        end

    elseif event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
        local _,_,name = string.find(arg1, CHAT_DISARM_IMMUNE_WAAAGH)
        if name ~= nil then
            Waaagh_ImmuneDisarm[name] = true
            Print(TEXT_WAAAGH_IMMUNE_TO_DISARM1..name..TEXT_WAAAGH_IMMUNE_TO_DISARM2)
        end
    end
end

--------------------------------------------------
