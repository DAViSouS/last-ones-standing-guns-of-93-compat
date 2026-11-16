# Changelog

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
