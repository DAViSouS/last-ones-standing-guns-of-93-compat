-- Last Ones Standing - Guns of 93 Compatibility
--
-- Last Ones Standing arms its survivors with vanilla firearms (Base.Pistol,
-- Base.Revolver, Base.Shotgun...).  Guns of 93 removes those from the world's
-- loot and zombie spawns, so without a bridge the survivors are the only people
-- carrying guns the player can never find, and nothing sets up Guns of 93's
-- parts and fire modes for them.
--
-- This file only wraps two exported Last Ones Standing functions:
--
--   LOS.TieIns.weaponFor(itemType)    the item an NPC is armed with
--   LOS.TieIns.prepareWeapon(item)    last chance to fix a gun before it is held
--
-- Everything else - ammo types, magazines, reloads, ammo boxes, accuracy and
-- damage - is Last Ones Standing's own code, and it already understands Guns
-- of 93's items because Guns of 93 registers its calibers with the engine.
-- Player weapons are not touched at all.
--
-- A Last Ones Standing update turns the bridge off until it is rebased.

-- No require of Last Ones Standing here: the engine already loads its files, and
-- requiring them again would run their top-level event registration twice.
-- The wrappers install at boot, after every mod's Lua has loaded.

local C = {}
LOSGuns93Compat = C

-- Upstream LastOnesStanding.VERSION this bridge was written against.
C.TESTED_LOS = "0.2.292-dev"


---------------------------------------------------------------------------
-- Version guard
---------------------------------------------------------------------------
local reason = nil

local function report(msg)
    print(msg)
    local los = LastOnesStanding
    if los and type(los.log) == "function" then pcall(los.log, "%s", msg) end
end


local function disable(why)
    if reason ~= why then
        reason = why
        report("GUNS93 BRIDGE DISABLED: " .. why ..
            ". Last Ones Standing and Guns of 93 run as shipped. Rebase the bridge, then update TESTED_LOS in LOSGuns93Compat.lua.")
    end
    return false
end


-- True once Guns of 93 has loaded the pieces the bridge needs.  Called again at
-- game start because server files load in path order and this folder can come
-- before Guns of 93's server/items files.
local function guns93Here()
    if type(Gun93Registries) ~= "table" or type(Gun93Registries.guns93) ~= "table" then return false end
    if type(SpawnPistolCommon) ~= "table" or type(SpawnRevolverCommon) ~= "table" then return false end
    local sm = ScriptManager and ScriptManager.instance
    if not sm then return false end
    return sm:getItem("Base.M9") ~= nil
end


local function active()
    local los = LastOnesStanding
    if not los then return disable("Last Ones Standing is not loaded") end
    if los.VERSION ~= C.TESTED_LOS then
        return disable("Last Ones Standing is " .. tostring(los.VERSION) ..
            " but the bridge was written for " .. C.TESTED_LOS)
    end
    return true
end


---------------------------------------------------------------------------
-- Choosing a Guns of 93 gun
---------------------------------------------------------------------------
-- The vanilla types Last Ones Standing asks for, mapped onto Guns of 93's own
-- spawn pools.  The pools are globals built by Guns93SpawnerItemsTable.lua and
-- follow the player's Guns of 93 sandbox choices (which calibers may spawn).
local POOL_OF = {
    ["Base.Pistol"]                    = "PistolMix",
    ["Base.Pistol2"]                   = "PistolMix",
    ["Base.Pistol3"]                   = "PistolMix",

    ["Base.Revolver"]                  = "Revolver",
    ["Base.Revolver_Short"]            = "Revolver",
    ["Base.Revolver_Long"]             = "Revolver",

    ["Base.Shotgun"]                   = "SportShotgun",
    ["Base.DoubleBarrelShotgun"]       = "SportShotgun",
    ["Base.ShotgunSawnoff"]            = "SBS",
    ["Base.DoubleBarrelShotgunSawnoff"] = "SBS",

    ["Base.HuntingRifle"]              = "SportRifle",
    ["Base.VarmintRifle"]              = "SportRifle",
    ["Base.TrapperCarbine"]            = "SportRifle",
    ["Base.L94_Rifle"]                 = "SportRifle",
    ["Base.L92_Carbine"]               = "SportRifle",
    ["Base.JS14_Rifle"]                = "SportRifle",

    -- Guns of 93 sends vanilla assault rifles mostly to its "no formal army"
    -- pool (SMGs and the like) and the rest to its tactical rifle pool.
    ["Base.AssaultRifle"]              = "RifleMix",
    ["Base.AssaultRifle2"]             = "RifleMix",
    ["Base.MSR7T_Rifle"]               = "RifleMix",
}

-- Last Ones Standing arms 30 % of its "pistol" people with a revolver; keep
-- that mix now that the type comes from Guns of 93.
local REVOLVER_SHARE = 30
local NFA_SHARE = 60
local ALT_SHARE = 22          -- Guns of 93's own chance of an _Alt caliber
local LOOKS = 5               -- candidates tried per pool before giving up

local existsCache = {}

local function itemExists(ft)
    local ok = existsCache[ft]
    if ok ~= nil then return ok end
    local sm = ScriptManager and ScriptManager.instance
    ok = (sm ~= nil and sm:getItem(ft) ~= nil)
    existsCache[ft] = ok
    return ok
end


local function fullType(name)
    if type(name) ~= "string" then return nil end
    if string.find(name, ".", 1, true) then return name end
    return "Base." .. name
end


-- Same weights as Guns of 93's own picker: common, uncommon, rare, very rare.
local function poolsInOrder()
    local roll = ZombRand(100)
    if roll >= 65 then
        return { "Common", "Uncommon", "Rare", "VaryRare" }
    elseif roll >= 35 then
        return { "Uncommon", "Rare", "Common", "VaryRare" }
    elseif roll >= 5 then
        return { "Rare", "Uncommon", "Common", "VaryRare" }
    end
    return { "VaryRare", "Rare", "Uncommon", "Common" }
end


local function pickFromPool(pool)
    for _, suffix in ipairs(poolsInOrder()) do
        local list = _G["Spawn" .. pool .. suffix]
        if type(list) == "table" and #list > 0 then
            for _ = 1, LOOKS do
                local ft = fullType(list[ZombRand(#list) + 1])
                if ft and itemExists(ft) then
                    if ZombRand(100) < ALT_SHARE then
                        local alt = ft .. "_Alt"
                        if itemExists(alt) then ft = alt end
                    end
                    return ft
                end
            end
        end
    end
    return nil
end


local function pickFor(pool)
    if pool == "PistolMix" then
        pool = (ZombRand(100) < REVOLVER_SHARE) and "Revolver" or "Pistol"
    elseif pool == "RifleMix" then
        pool = (ZombRand(100) < NFA_SHARE) and "NFAGun" or "TacRifle"
    end
    return pickFromPool(pool)
end


---------------------------------------------------------------------------
-- Fixing a gun before an NPC holds it
---------------------------------------------------------------------------
local ORIG_WEAPON_FOR, ORIG_PREPARE = nil, nil

local notedSafe = {}

local function firstMode(item)
    local modes = item:getFireModePossibilities()
    local fallback = nil
    if modes then
        for i = 0, modes:size() - 1 do
            local m = modes:get(i)
            if m ~= "Safe" then
                if m == "Single" then return m end
                fallback = fallback or m
            end
        end
    end
    return fallback or "Single"
end


-- Mirrors Guns of 93's own required-part rule, for the log line only: an NPC
-- still gets a working trigger, because a survivor that cannot fire is worse
-- than one holding an incomplete gun.
local function missingPart(item, reg)
    if reg.ReqTrigger and item:hasTag(reg.ReqTrigger) and not item:getWeaponPart("Trigger") then
        return "trigger"
    end
    if reg.ReqGrip and item:hasTag(reg.ReqGrip) then
        local grip = item:getWeaponPart("Grip")
        if not grip then
            local stock = item:getWeaponPart("Stock")
            if not (stock and reg.Sport and stock:hasTag(reg.Sport)) then return "grip" end
        end
    end
    if reg.ReqStock and item:hasTag(reg.ReqStock) and not item:getWeaponPart("Stock") then
        return "stock"
    end
    return nil
end


local function prepareWeaponPatched(item)
    if ORIG_PREPARE then ORIG_PREPARE(item) end
    if not item or not instanceof(item, "HandWeapon") or not item:isRanged() then return end
    local reg = Gun93Registries and Gun93Registries.guns93
    if not reg or not reg.Guns93 or not item:hasTag(reg.Guns93) then return end

    -- A saved record can carry a round count written for a vanilla gun (the
    -- checkpoint guard's 29-round rifle).  Never leave a Guns of 93 gun
    -- holding more rounds than its magazine can take.
    local most = item:getMaxAmmo()
    if most and most > 0 and item:getCurrentAmmoCount() > most then
        item:setCurrentAmmoCount(most)
    end

    if item:getFireMode() ~= "Safe" then return end

    local mode = firstMode(item)
    item:setFireMode(mode)

    local ft = item:getFullType()
    if not notedSafe[ft] then
        notedSafe[ft] = true
        local lacking = missingPart(item, reg)
        report("GUNS93 BRIDGE: put an NPC's " .. ft .. " on " .. mode ..
            (lacking and (" (its " .. lacking .. " is missing)") or " (it was on Safe)"))
    end
end


local function weaponForPatched(itemType)
    local upstream = itemType
    if ORIG_WEAPON_FOR then
        local picked = ORIG_WEAPON_FOR(itemType)
        if picked ~= nil then upstream = picked end
    end
    -- Another bridge (Gunsmith1993) already answered; leave its choice alone.
    if upstream ~= itemType then return upstream end

    local pool = POOL_OF[itemType]
    if not pool then return upstream end
    return pickFor(pool) or upstream
end


---------------------------------------------------------------------------
-- Install / re-install (mod load order safety)
---------------------------------------------------------------------------
local installed = false

local function install()
    if installed then return end
    if not active() then return end

    local los = LastOnesStanding
    local T = los and los.TieIns
    if not T then return end
    if type(T.weaponFor) ~= "function" or type(T.prepareWeapon) ~= "function" then return end

    if not ORIG_WEAPON_FOR then ORIG_WEAPON_FOR = T.weaponFor end
    if not ORIG_PREPARE then ORIG_PREPARE = T.prepareWeapon end
    if T.weaponFor ~= weaponForPatched then T.weaponFor = weaponForPatched end
    if T.prepareWeapon ~= prepareWeaponPatched then T.prepareWeapon = prepareWeaponPatched end

    installed = true
    report("GUNS93 BRIDGE ENABLED: Last Ones Standing NPCs draw Guns of 93 weapons (Last Ones Standing " ..
        tostring(los.VERSION) .. (guns93Here() and "" or "; waiting for Guns of 93's item tables") .. ")")
end


local function uninstall(why)
    local los = LastOnesStanding
    local T = los and los.TieIns
    if T then
        if ORIG_WEAPON_FOR and T.weaponFor == weaponForPatched then T.weaponFor = ORIG_WEAPON_FOR end
        if ORIG_PREPARE and T.prepareWeapon == prepareWeaponPatched then T.prepareWeapon = ORIG_PREPARE end
    end
    installed = false
    disable(why)
end


local function lateCheck()
    if reason then return end
    if not installed then
        if not LastOnesStanding or not LastOnesStanding.TieIns then
            disable("Last Ones Standing's TieIns could not be found")
        elseif not guns93Here() then
            disable("Guns of 93 did not load its items or spawn tables")
        end
        return
    end
    if not guns93Here() then
        uninstall("Guns of 93 did not load its items or spawn tables")
    end
end


if type(LastOnesStanding) == "table" then install() end
Events.OnGameBoot.Add(install)
Events.OnGameStart.Add(install)
Events.OnGameStart.Add(lateCheck)
