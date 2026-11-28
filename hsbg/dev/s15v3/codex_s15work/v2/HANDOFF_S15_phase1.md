# Season 15 handoff (TTS slot 226)

## Save
- New save: `TS_Save_226.json`, SaveName **"Battlegrounds Tavern - HS UI v18 - Season 15 HS Cards"**.
  - Copied to NipkoPC at `C:\Users\jadin\Documents\My Games\Tabletop Simulator\Saves\TS_Save_226.json`. The SHA-256 matches the box copy (eeaac304…).
  - Slot 225 was not touched. It had no thumbnail, so none was copied.
- Box copy: `/workspace/hsbg/TS_Save_226.json`.
- How the save is built: start from slot 225, apply the Codex "Season 15 Gameplay" patch (`s15work/cx/patch.py`, with the resolveDeaths anchor fixed), then apply `s15work/final/patch_s15_final.py`. The final patch inserts these files:
  - `spellpower.lua`
  - `s15spells.lua`
  - `s15cards.lua`
  - `s15heroes.lua`

  It also edits anchors elsewhere. Each anchor must match exactly once, or the patch stops.
- Resulting script: `s15work/final/b9a001_226.lua`.
  - `luac5.1 -p` passes.
  - No new globals compared with the Codex base.
- Art: `https://raw.githubusercontent.com/Jnipko488/mtg-table-data/5e5931d3abec1a3ae33b0c350338c33a79b63197/hsbg/s15/`
  - Folders: cards, ovals, shop, spells, heroes, powers, hpcards, hsjson.
  - Every image returned 200. No `file:///` paths are left. The Codex build pointed at `C:\Users\jadin\Documents\Codex\...` and would have shown blank art on any other PC.

## Changes per category
- **Minions**
  - Tavern pool: 300 → 301. Added **Bristleback Bully** (BG35_432, Tier 2 Quilboar 3/2 Taunt, Deathrattle: Blood Gem that also gives Taunt). Nothing removed.
  - Scripted: Codex base had 26 of 299 checked pool cards unscripted; now 0 of 300 checked (fxcheck), Bully included.
  - Newly scripted cards:
    - BG26_800, BG26_159, BG26_160, BG26_867
    - BG32_891, BG33_809, BG34_694, BG25_032, BG23_016, BG32_332
    - BG35_431, BG33_884, BG34_175, BG32_892, BG31_871
    - BG30_103, BG30_124, BG30_129
    - Reverber Drake BG31_300 and Efficient Engineer BG31_301, marked "simplified" (they pick a target automatically)
  - Text fixes: BG24_003, BG22_402, BG33_884 (3 Blood Gems), BG30_103 (mission text).
  - New tokens:
    - **Growing Ooze** (2/1; given by Sickly Ooze and Ominous Ooze; when discarded it buffs your board and Deity, then the next one gets +2/+1)
    - Cubling (BG26_800t)
  - New Deity: **N'Zoth** (1/1 Taunt; awakens after 3 Aberration deaths; goes back to sleep when it dies).
    - In S15 the Deity is picked at random from 3: Drake, Elemental and N'Zoth.
    - In S15 the Deity awakens in the position of the last Aberration that died.
  - Overflow summons for Thundering Abomination and Catacomb Crasher: in combat they are permanent, in recruit they are a plain buff.
- **Spells**
  - Added to the S15 Tavern spell rotation:
    - the 4 Elemental Invocations (Earth, Fire, Air, Water)
    - Command the Elements
    - EBG_Spell_014
    - BG35_149
  - Already there from Codex: Goldrinn's Blessing, Dragonstorm, Tumultuous Growth, Unholy Ritual, Echoing Roar, Sanctify. I rewrote their casts so they use spell power.
  - No spells removed.
- **Heroes** (S15 lobbies only)
  - Added **Vanessa the Ringleader**: Strategic Edge, costs 2. It discovers a minion of Tier 1 + (minions bought this turn), up to 6. The live text shows the current tier.
  - Added **Eternus**: Dawn of the Infinite, passive. On turn 1 you get 0 Gold and visit the Major Timewarp instead. Anything you buy there is locked until you have spent 45 Gold this game, and the card shows "Locked until you spend N more Gold".
  - Lobby rules:
    - Sindragosa and Millhouse are banned when Pirates are in the lobby.
    - Murozond and Morchie ignore the Deity ban in S15.
  - King Mukla's text is updated.
  - Both new heroes have hero art, power medallions and power-card art.
- **Timewarp**
  - 24 cards Blizzard removed are filtered out of S15 Timewarp offers: E.S15_TIMEWARP_REMOVED in `s15heroes.lua`.
  - The 81 new S15 Timewarp cards were not added.
- **Trinkets and anomalies**: no changes from this pass.

## How spell power text works
- There is one source of truth. In `spellpower.lua`, `E.spellAmount(p,a,h,entry)` returns a/h after spell power. Spell power includes:
  - `p.spellAtk` / `p.spellHp`
  - aura minions
  - trinkets
  - a per-card bonus, such as Squirky's
- Every buff a spell gives goes through it: the `buffSpell` / `buffAll` / `stats` helpers, plus Tavern "this game" buffs, Eonar's Favor, Undead +8 Attack (BG28_604), the Deity blessing spell (BG36_371) and the S15 spells.
- Spell text:
  - `E.SPELL_TEXT[id]` is an editable template, for example `"Give a minion +{a}/+{h}."` with `a=3, h=3`.
    - `{a}` and `{h}` are the base value plus spell power.
    - `{a:N}` and `{h:N}` are N plus spell power.
    - `{n:N}` is N with no bonus.
  - Change one at runtime with `E.setSpellText(id, template)`.
  - Spells without a template have every `+X/+Y`, `+X Attack` and `+X Health` raised automatically. A 0 stays 0.
- `Draw.spellState` uses `BG.spellText`, so hover, Discover, shop, hand and previews all show the same numbers.
  - The old gsub, which only changed the first number on pool spells, is removed.
- Effects that recur later keep the value they had when cast. For example, Dragonstorm and Echoing Roar "gain +X/+Y at end of turn" store s15a/s15h on the enchantment.
- Not scaled:
  - Blood Gems (BG20_GEM, BG34_689)
  - Spellcraft spells, Timewarp cards, "spells give" text
  - Battlecruiser upgrades (hero cards)
- Squirky-style per-card bonuses now apply only to nonzero stats, which matches the text. Before, they also added to a 0 stat.
- Test: `h/scen_s15check.lua` casts all 82 scaling spells with spell power 0 and with +2/+3 and compares the stat change to the text. Every spell whose effect could be measured matched.

## Tests (harness, `s15work/h`)
- scen_fxcheck: 0 unscripted of 300.
- scen_s15soak and scen_s15inj: 4/4 games finish. The only errors are the same overlap and decal layout warnings as the base save.
- scen_s15hero (forces Vanessa/Eternus and N'Zoth): 4/4 games, 0 errors.
- scen_s15check covers:
  - spell power text against effect
  - Vanessa tier
  - Eternus lock and release at 45 Gold
  - Growing Ooze discard
  - N'Zoth need = 3
- Legacy scenarios (v42/v49/lane/v48soak) fail exactly as they do on the base save. They are written for older UI versions.
- Note: `gen_setup.py` writes `h/scripts/` every time. Regenerate the setup before each comparison run.

## Unfinished / unverified
- I could not run TTS itself. Art layout, hover panels, lock tooltips and the new hero medallions are untested in the real client.
- The 81 new Season 15 Timewarp cards are not added.
- The 24 "Changed Minions" got their stat changes (seasonStats.s15). Their text and behaviour changes are not done.
- Reverber Drake and Efficient Engineer pick their target automatically.
- Eternus:
  - Armor 10 is a guess.
  - The lock applies only to cards from the turn-1 Major Timewarp.
  - The visit uses the normal 2 Chronum budget.
  - The Eternus turn-1 visit was only tested directly, not in a full soak. The soak forced the hero after turn 1 had started.
- "Offered every game" for the new heroes is not implemented. They are normal picks in S15.

## Decisions for the user
1. Eternus armor (10?) and Chronum for the turn-1 visit (2, or more?).
2. Should spell power also scale Battlecruiser upgrades and Blood Gems? Currently it does not.
3. Squirky bonus on 0 stats: currently it applies only to nonzero stats.
4. Is it worth doing the 81 Timewarp cards and the changed-minion text next?
