# Last Ones Standing - Guns of 93 Compatibility

A small bridge between **[Last Ones Standing](https://steamcommunity.com/sharedfiles/filedetails/?id=3830310103)**
and **[Guns of 93: B42 Test Build](https://steamcommunity.com/sharedfiles/filedetails/?id=3183820077)**.

Last Ones Standing arms its survivors with the vanilla firearms (`Base.Pistol`,
`Base.Revolver`, `Base.Shotgun`…). Guns of 93 strips those guns out of the
world's loot and zombie spawns by default, so without a bridge the survivors
are the only people carrying guns the player can never find. This mod makes
them draw Guns of 93 weapons instead, with matching magazines and ammo, while
leaving Last Ones Standing's own ammo, reload and combat code in charge.

This is not a fork of either mod and it does not edit either one. It requires
both and loads after them.

- **Last Ones Standing:** `1.0`
- **Guns of 93:** B42 Test Build `0.8.2.8f`
- **Game:** Project Zomboid 42.22.2 (`3d39148846`), `versionMin = 42.21`

## What it changes

Only two exported Last Ones Standing functions are wrapped:

| Function | What the bridge does |
|---|---|
| `LOS.TieIns.weaponFor(itemType)` | Maps the vanilla type Last Ones Standing asks for onto one of Guns of 93's own spawn pools, using Guns of 93's rarity weights and `_Alt` caliber variants. |
| `LOS.TieIns.prepareWeapon(item)` | If a newly made Guns of 93 gun is still on `Safe`, picks a firing mode the NPC can actually use. |

The mapping follows Guns of 93's own vanilla replacements:

| Last Ones Standing asks for | Guns of 93 pool |
|---|---|
| `Base.Pistol` (30 % become revolvers, as in Last Ones Standing) | `SpawnPistol*`, `SpawnRevolver*` |
| `Base.Revolver` | `SpawnRevolver*` |
| `Base.Shotgun`, `Base.DoubleBarrelShotgun`, `Base.JS3T_Shotgun` | `SpawnSportShotgun*` |
| `Base.ShotgunSawnoff`, `Base.DoubleBarrelShotgunSawnoff` | `SpawnSBS*` (75 %) and `SpawnSawedRifle*` (25 %) |
| `Base.HuntingRifle`, `Base.VarmintRifle`, `Base.TrapperCarbine`, `Base.L94_Rifle`, `Base.L92_Carbine`, `Base.JS14_Rifle` | `SpawnSportRifle*` |
| `Base.AssaultRifle`, `Base.AssaultRifle2`, `Base.MSR7T_Rifle` | `SpawnNFAGun*` (54 %), `SpawnTacRifle*` (36 %) and `SpawnMilitaryLongGun*` (10 %) |

Two deliberate widenings beyond the plain vanilla equivalents:

- **Sawn-off rifles.** Guns of 93's `SawedRifle` pool holds rifles with the
  stock and barrel chopped — a Remington 700/788 or M24 shortened, still
  two-handed, still on a rifle caliber, 5-round internal magazine and roughly a
  third less range. Last Ones Standing only asks for a sawn-off as a raider's
  backup gun, so one in four of those becomes a sawn-off rifle instead of a
  sawn-off shotgun.
- **Military long guns.** One in ten assault-rifle requests draws from
  `MilitaryLongGun`, so M16A2, M590/M870, and occasionally M249, M723/M727/M733
  or M60, turn up on survivors. That pool's own rarity tiers still apply: the
  machine guns sit in its rare and very-rare lists, so they stay uncommon even
  inside the 10 %.

Not used at all: Guns of 93's police, SWAT, store, crime, bug-out and military
sniper pools. Those are loot tables for places and roles Last Ones Standing does
not model, and its NPCs are never handed those guns.

If one of the pools used here is empty — a player can switch off a whole caliber
in Guns of 93's sandbox options, and that empties its pool — the request falls
back to a related pool (`MilitaryLongGun` → `NFAGun` → `TacRifle` →
`SportRifle`, and so on) instead of handing out a vanilla gun that a Guns of 93
world no longer spawns.

Because the pools are Guns of 93's own, the bridge respects its sandbox
settings: a caliber the player has turned off will not be handed to an NPC
either.

## What it deliberately does not do

- **Player weapons are untouched.** Guns of 93's menus, parts, fire modes and
  sandbox options work exactly as before.
- **No damage, accuracy or recoil tuning for NPCs.** Last Ones Standing has its
  own hit and damage model; the bridge does not layer Guns of 93's
  player-side `GunStatAdjust` on top of it.
- **No retrofitting.** NPCs already in a save keep the gun they were created
  with. New survivors, new households, base guards, checkpoint guards and base
  stock use Guns of 93 guns from then on.
- **Nothing is removed.** Vanilla guns still exist as items; the bridge simply
  stops Last Ones Standing from handing them out.
- **Gunsmith1993 wins if both are installed.** Last Ones Standing's original
  `weaponFor` already maps to a Gunsmith gun when Gunsmith1993 is loaded; the
  bridge notices that answer and leaves it alone rather than replacing it.

## Ammo and magazines

Nothing extra is needed, and nothing here reimplements reloading:

- Guns of 93 registers its calibers with the engine
  (`AmmoType.register("guns93:bullets_22", "Base.22Bullets")`), so Last Ones
  Standing's `roundType` already resolves them.
- Guns of 93 magazine guns use ordinary `MagazineType` items, including its
  extended magazines and `_Alt` variants.
- Revolvers have no magazine, so Last Ones Standing's loose-round reload path
  applies as normal.
- Ammo boxes are the same `Base.Bullets9mmBox`, `Base.ShotgunShellsBox`… items,
  and Last Ones Standing's box-opening code handles them. In `1.0` that code
  finds a box by the recipes it can be used in rather than by its display
  category, and checks the craft surface and light before starting, so Guns of
  93's boxes and rounds go through the same path.
- `1.0` also fills an NPC's empty magazine from loose rounds, ejecting it to do
  so, and restocks from magazines carried in its pack. Guns of 93 guns use that
  path unchanged; the bridge adds nothing on top of it.

## Version guard

Last Ones Standing is updated often, so the bridge compares
`LastOnesStanding.VERSION` with the version it was written against
(`TESTED_LOS` in `LOSGuns93Compat.lua`).

| Situation | What happens |
|---|---|
| Versions match | The wrappers install and `console.txt` gets one `GUNS93 BRIDGE ENABLED` line. |
| Versions differ | The wrappers do not install. `console.txt` gets one `GUNS93 BRIDGE DISABLED: Last Ones Standing is X but the bridge was written for Y…` line and both mods run exactly as shipped. |
| Guns of 93 missing | The mod is not enabled (`require=guns93`). If its item tables somehow fail to load, the bridge removes its wrappers at game start and logs why. |

A disabled bridge breaks nothing: Last Ones Standing falls back to its vanilla
gun types.

## Install

1. Subscribe to **Last Ones Standing**, **Guns of 93: B42 Test Build** and this mod.
2. For a manual install, copy this folder to `%USERPROFILE%\Zomboid\mods\` so
   that `...\Zomboid\mods\<this folder>\mod.info` exists.
3. Enable all three. Load order is enforced by
   `require=LastOnesStanding1993,guns93`.

The mod id is `LOSGuns93Compat`. Removing it later is safe: it writes no mod
data of its own.

## Testing on Last Ones Standing 1.0

Use a **new save**. NPCs already in a world keep the gun they were created with,
and a save that was using Gunsmith1993 has records naming Gunsmith items.

1. Enable **Guns of 93** and this mod, and **disable Gunsmith1993** while you
   test. Last Ones Standing's own `weaponFor` answers first when Gunsmith1993 is
   loaded, and this bridge deliberately defers to it wherever it gives an
   answer: with both on you would see Gunsmith guns, not Guns of 93 guns.
2. Start a new world. Leave Guns of 93's `VanillaGuns` option off (its default);
   vanilla guns stay as items either way.
3. `console.txt` should have one `GUNS93 BRIDGE ENABLED: … (Last Ones Standing 1.0)`
   line and no `GUNS93 BRIDGE DISABLED` line.
4. Last Ones Standing logs `LOOKS npc=… draws its <item>` when a survivor arms
   itself, and this bridge logs `GUNS93 BRIDGE: put an NPC's <item> on <mode>`
   the first time it has to take each type off `Safe`. The item should be a Guns
   of 93 type (`Base.M9`, `Base.M1911_Alt`…), never `Base.Pistol`.
5. Watch a survivor with a magazine gun reload. `1.0` fills an empty magazine
   from loose rounds and restocks from magazines in the pack; the bridge does
   not take part, so a gun that never reloads is a Last Ones Standing issue, not
   a bridge one.

## Repository layout

```
mod.info                                              name, id, requirements
42/media/lua/server/LOSGuns93Compat/
    LOSGuns93Compat.lua                               version guard, gun pools, wrappers
README.md
CHANGELOG.md
```

## Rebasing after a Last Ones Standing update

1. Read the new `LOS.TieIns.weaponFor` and `LOS.TieIns.prepareWeapon` in
   `LOS_TieIns.lua`. (In `1.0` this file is unchanged from `0.2.292-dev`; the
   bridge seam is the same.)
2. Check the vanilla gun types Last Ones Standing asks for
   (`LOS_Population.lua`, `LOS_Guard.lua`, `LOS_Stock.lua`,
   `LOS_Checkpoint.lua`, `LOS_Bodies.lua`) and update `POOL_OF` if any changed.
3. Confirm Guns of 93 still builds the `Spawn*` pool globals in
   `Guns93SpawnerItemsTable.lua`.
4. Set `TESTED_LOS` in `LOSGuns93Compat.lua` to the new
   `LastOnesStanding.VERSION`, bump `modversion`, and add a CHANGELOG entry.
5. In game, check `console.txt` for `GUNS93 BRIDGE ENABLED` and no
   `GUNS93 BRIDGE DISABLED` line.

## Credit

All original code, design and content belong to the authors of Last Ones
Standing and Guns of 93. This repository only contains the bridge.

## License

No license is granted here for either mod's code. The bridge changes are
offered for the authors to take, adapt or ignore.

## Disclaimer

This is AI slop. Yes, even this disclaimer. The AI was pointed at two mods that
were never designed to talk to each other and only moderately kept in check by
a human, so read the diff before you trust it. Use at your own risk — you were
warned.
