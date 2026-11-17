# Changelog

## 0.3.0 — 17 November 2026

Wider draw for sawn-offs and assault rifles. Still **Last Ones Standing `1.0`** and
**Guns of 93: B42 Test Build `0.8.2.8f`**.

### Changed

- **Sawn-off rifles.** `Base.ShotgunSawnoff` and
  `Base.DoubleBarrelShotgunSawnoff` now split 75 % `SBS` / 25 %
  `SpawnSawedRifle*` instead of always being a sawn-off shotgun.
  `SawedRifle` is Guns of 93's rifle counterpart: a Remington 700/788 or M24
  with the stock and barrel cut down, `WeaponReloadType = boltactionnomag`, a
  5-round internal magazine and 32 units of range against the full .223
  Remington 700's 45. Last Ones Standing only asks for a sawn-off as a raider's
  backup gun (15 % of a raider's gun rolls in `LOS_Population`), so the sawn
  rifle lands where a sawn-off would have.
- **Military long guns.** `Base.AssaultRifle`, `Base.AssaultRifle2` and
  `Base.MSR7T_Rifle` now split 54 % `SpawnNFAGun*` / 36 % `SpawnTacRifle*` /
  10 % `SpawnMilitaryLongGun*`. The 60/40 mix Last Ones Standing had is kept for
  the non-military share; one in ten becomes an M16A2, M590 or M870, and only
  rarely an M249, M723, M727, M733 or M60, because those sit in the pool's rare
  and very-rare lists. Guns of 93's own per-caliber ammo-distribution options
  (and `Guns93AutoDistro`) still decide whether the pool has anything in it at
  all.

### Not used

- Guns of 93's police, SWAT, store, crime, bug-out and military sniper pools
  stay out of the mapping.

### Tuning

- `MILITARY_SHARE` (10) and `SAWN_RIFLE_SHARE` (25) at the top of
  `LOSGuns93Compat.lua` are the only two numbers behind the new splits.

## 0.2.0 — 17 November 2026

Rebased onto **Last Ones Standing `1.0`** (the 16 November update). Guns of 93:
B42 Test Build `0.8.2.8f` is unchanged.

### Rebase result

- **The bridge seam did not move.** `LOS_TieIns.lua` — the only upstream file
  this mod wraps — is byte-identical to `0.2.292-dev`, and `weaponFor` /
  `prepareWeapon` still take the same single argument. `TESTED_LOS` is now
  `"1.0"`; `POOL_OF` needed no change.
- **The requests did not change.** `1.0` still asks for `Base.Pistol`,
  `Base.Revolver`, `Base.Shotgun`, `Base.ShotgunSawnoff`, `Base.HuntingRifle`
  and `Base.AssaultRifle` (`LOS_Population`, `LOS_Guard`, `LOS_Stock`,
  `LOS_Checkpoint`, `LOS_Bodies`), so every type an NPC can be given is already
  in the pool map.

### Checked against 1.0's new gun code

- **Magazine filling and ejection** (`LOS_Ammo`): `1.0` fills an NPC's empty
  magazine from loose rounds, ejecting the magazine to do it, and restocks from
  magazines carried in its pack. Guns of 93 magazine guns use ordinary
  `MagazineType` items, so this path applies to them unchanged. The bridge adds
  nothing.
- **Ammo boxes** (`LOS_Ammo`): box discovery now goes by the recipes an item can
  be used in, rather than `DisplayCategory == "Ammo"`, and checks the craft
  surface and light before starting. Guns of 93's boxes and rounds work through
  it; nothing to bridge.
- **NPC loadout** (`LOS_Loadout`): a fresh gun now gets a loaded magazine
  (`loadFresh`, then a magazine at full or partial rounds). Guns of 93 magazine
  types are `Base.*` items, so this works as-is.
- **Saved guns** (`LOS_Items`): `restoreGun` is unchanged in `1.0` (the file's
  only edit is a cosmetic expression in `colorOf`). A record stores the item
  type plus `magType` and `clip`, so a Guns of 93 gun written to the save comes
  back as the same item type with its own magazine; nothing to reconcile.
- **Checkpoint guards** (`LOS_Guard`): still armed through `TieIns.weaponFor`,
  now with a magazine supplied the same way.
- **Stamina** (`LOS_Stamina`): new in `1.0`, and it can make an NPC refuse a
  melee swing. It does not touch firearms or `TieIns`.
- **Version guard**: `1.0` passes; any other version still disables the bridge
  with one `GUNS93 BRIDGE DISABLED` line.

### Testing notes

- Use a new save: existing NPCs keep the gun they were created with.
- Disable **Gunsmith1993** while testing. Its own `weaponFor` answer wins
  wherever it gives one and this bridge defers to it, so with both loaded you
  see Gunsmith guns, not Guns of 93 guns.
- The bridge takes a gun off `Safe` only for types it actually hands out; the
  log line is written once per type.

## 0.1.0 — 16 November 2026

First release. A standalone bridge for **Last Ones Standing** `0.2.292-dev`
and **Guns of 93: B42 Test Build** `0.8.2.8f`. Neither mod is edited.

### What it fixes

- **Survivors now carry Guns of 93 guns.** Last Ones Standing asked for
  `Base.Pistol`, `Base.Revolver`, `Base.Shotgun`, `Base.HuntingRifle`,
  `Base.AssaultRifle` and friends. Guns of 93 removes those guns from loot and
  zombie spawns by default, so survivors were the only people with guns the
  player could never find. `LOS.TieIns.weaponFor` is wrapped and now returns a
  type from Guns of 93's own `Spawn*` pools.
- **The mix matches Guns of 93's world.** Pools and rarity weights are the
  same ones Guns of 93 uses: common, uncommon, rare and very rare, with the
  same `_Alt` caliber chance. Last Ones Standing's 30 % revolver share for
  `Base.Pistol` is preserved, and vanilla assault rifles split 60/40 between
  Guns of 93's NFA pool (SMGs and the like) and its tactical rifle pool, as in
  Guns of 93's own vanilla replacement.
- **Sandbox settings are respected.** The spawn pools are the ones Guns of 93
  builds from its sandbox options, so a caliber the player disabled will not
  appear on an NPC either.
- **NPC guns are not left on `Safe`.** Guns of 93 sets a newly made gun to
  `Safe` when a required part is missing, and its `GunStatAdjust` only runs for
  `IsoPlayer`, so an NPC would never have the safety taken off.
  `LOS.TieIns.prepareWeapon` is wrapped: an NPC's Guns of 93 gun that is still
  on `Safe` is put on its first usable firing mode, and the missing part (if
  any) is named once in `console.txt`.
- **Ammo and magazines need no bridge.** Guns of 93 registers its calibers with
  `AmmoType.register`, its magazine guns use ordinary `MagazineType` items, its
  revolvers use loose rounds, and its ammo boxes are the same `Base` items.
  Last Ones Standing's existing reload, magazine, box-opening and loadout code
  handles all of it, so none of it is copied here.
- **No changes for the player.** Guns of 93's own weapons, parts, menus, fire
  modes and sandbox options behave as before. Last Ones Standing's NPC combat
  model is untouched: no Guns of 93 damage or accuracy adjustments are applied
  to NPCs.
- **Round counts are capped to the new magazine.** A saved record written for a
  vanilla gun (the checkpoint guard's 29-round rifle, for example) can ask for
  more rounds than a Guns of 93 magazine holds; those guns are clamped to
  `getMaxAmmo()` before an NPC holds them.

### Version guard

- New `TESTED_LOS = "0.2.292-dev"` check. A differing
  `LastOnesStanding.VERSION` leaves the wrappers uninstalled and logs one
  `GUNS93 BRIDGE DISABLED` line, so a Last Ones Standing update cannot leave
  the bridge pointing at functions that changed.
- At game start the bridge re-checks that Guns of 93 loaded its item scripts
  and spawn pools. If not, it removes its wrappers and logs why.

### Known limitations

- NPCs already in an existing save keep the gun they were created with. Only
  new survivors, new households, guards and new base stock use Guns of 93 guns.
- An NPC's Guns of 93 gun can fire even if its required trigger/grip/stock is
  missing. The log names the part; the alternative is a survivor that stands
  there doing nothing.
- Last Ones Standing's NPC damage numbers come from the gun's base
  `MinDamage`/`MaxDamage`, not from Guns of 93's player-side sandbox damage
  multiplier.
