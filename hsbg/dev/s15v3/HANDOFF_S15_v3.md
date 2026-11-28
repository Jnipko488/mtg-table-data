# Season 15 v3: slot 228, "Battlegrounds Tavern - HS UI v18 - Season 15 HS Cards v3"
Built from slot 227 (Codex/Grok v2) with `python3 build_v3.py <out.json> "<SaveName>"`.
- SHA-256: 5a1d46b9dafc4a65e843f6cdc37db92df0c8bb542b649278847cb3d33945f261 (verified on the PC).
- Slots 225, 226 and 227 are untouched.

## Source of truth
- Blizzard's own card library API (hearthstone.blizzard.com/en-us/api/cards, gameMode=battlegrounds), read through the browser on Nov 27.
- It lists 1105 cards: normal and golden text and stats, plus card render images.
- Saved as `api_cards.json`: 573 rows covering shop minions, Tavern spells and Timewarp cards, each with its golden twin.
- The API leaves some numbers blank and sometimes shifts one into the wrong slot. For example, Graveyard Skulker reads "Activate (2) ... gain Gold" when the card is "Activate (0) ... gain 2 Gold". Rules in `gen_data.py`:
  - Use the API text when it is complete.
  - When the API text has blanks, fill each blank with the mod's number at the same place, using word alignment (golden text takes them from the mod's golden text).
  - `manual.json` lists the overrides: Sanguine Champion stays +2/+1 (not in the 37.2 change list), plus a few scrambled texts.

## Changes (`v3data.lua` and `lua/v3fix.lua`; Season 15 only, so other seasons are untouched)
- **Shop pool**
  - Now exactly Blizzard's 251 solo minions: 23 in each of the 10 tribes, plus 21 neutral and 5 all-type minions.
  - Naga rotated out (only the dual-type Ominous Seer and Firescale Hoarder remain). That removes 50 cards that were not in the 37.2 pool, and adds Rot Hide Gnoll.
  - Lobbies no longer roll Naga, because a tribe needs 4 scripted pool minions to be drawn.
- **Data**
  - 274 cards got text, golden text, tier or stat updates.
  - All golden texts are now the real ones.
  - Sewer Rat no longer has Taunt itself. Bloodsnout Warlord is 5/5 (golden 10/10). Nether Drake is Tier 5. Batty Terrorguard is Tier 6.
  - Tavern spell texts also switch per season.
- **Golden effects fixed to match golden text**
  - Stone Age Slab: +20/+20 and triple.
  - Prototype Builder: one Golden Automaton.
  - Ruthless Pursuer: 4 Bounties.
  - Faceless and Timewarped Necromancer: the 2 left-most Aberrations.
  - Cunning Chameleon: Discover 2.
  - Holmes: one guess, 2 copies.
  - Soldier: double the stats to the Deity.
  - Nightmare and Replicator: summon a Golden copy.
  - Muscle-o-Tron: triple.
  - Amalgadon: four 1/1 Plants.
  - Ball of Minions: double stats.
  - Looter: golden also covers Tier 3.
  - Voidpriest: 6 per turn.
- **Previously simplified cards**
  - Sergeant also improves from Attack gained in combat.
  - Graverobber counts as having a Deathrattle only while it holds a destroyed minion.
  - Replicator discards the 2 right-most cards; spells sit right of minions in hand.
  - Holmes: see above.
  - Looter acts on every Tavern fill. All fills go through E.rollTavern, including start-of-turn refreshes.
  - Butchering was already a lasting "+8 Attack this game" Undead aura. Only Squirky's bonus Health on it still goes just to current Undead.
- **Art**
  - Real golden cards (gold frame and golden text) for:
    - the 66 new minions (`cards/g`), from hsbg.cards golden renders;
    - the 61 changed cards (`override/g`), from Blizzard's golden renders.
  - Both are in commit 00afa224, `hsbg/s15/`.
  - Every HearthstoneJSON fallback now goes through `Draw.hsjsonArt`, which serves the GitHub mirror. The mirror is at commit fbcf3fa0 (`hsbg/hsjson/v1/...`) and now includes the Cubling and Plant tokens.
  - Audit (`h/scen_urls.lua`): all 2054 Season 15 art URLs (cards, ovals and goldens for 423 minions and tokens, plus 123 spells' hand and shop art) are on raw.githubusercontent.com and return 200.

## Tests (harness from s15work/h, .NET 8 + MoonSharp; scenarios in h/)
- `scen_tw`: 0 errors. Pool 251; Timewarp Minor 97 and Major 108, none missing; 140 plays, 46 activations, 140 combats.
- `scen_s15check`: 0 errors.
- `scen_fxcheck`: 0 of 251 unscripted.
- `scen_s15inj`: 4/4 games, 0 errors.
- `scen_golden` (new): golden-vs-normal differential test on all 416 Season 15 minions, covering play, Activate, spell, end of turn, start of turn, refresh, combat and sell.
  - 9 flags, each reviewed and expected: the golden difference shows up later, as with Lockboxes and Choose One cards.
- `scen_s15soak12`: 12 full Season 15 games. The only errors are harness spawn-overlap layout warnings, and fewer of them than slot 227.
- `scen_othersoak`: other seasons are identical to slot 227.
- `scen_urls` (new): 2054 URLs, 0 off GitHub, 0 not returning 200.

## Not changed / notes
- Card stats and text come from Blizzard's live 37.2 data. Real card IDs (BG37_*) are not published yet, so the new cards keep their S15_* ids.
- BGS_121 (Gentle Djinni) and the Cubling token have no golden render anywhere. They use golden-frame override art (Djinni) or the normal render (Cubling).
