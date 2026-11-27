# Battlegrounds TTS mod – handoff notes (Claude session, 2026-11-26/27)

## Saves installed (Tabletop Simulator\Saves) – load fresh, never save an older session over them
| Slot | SaveName | Contents |
|---|---|---|
| 191 | Season 14 HS Cards | HS in-play ovals for every minion, live-patch data, standings/End Turn/Hero Power fixes |
| 192 | Season 14 HS Cards v2 | + minion types under "Choose a Hero", health gems without the grey bracket |
| 193/194 | v3 / v4 | full-card spells in the tavern – **wrong look, do not use** |
| **196** | **Season 14 HS Cards v5** | **current build**: v2 + live (buffed) spell text on hover previews and Discover |

Controller object GUID `b9a001`. The script is built by applying Python patch modules on top of Codex's
"Battlegrounds Tavern - Season 14 Polish.json" (module order: popups leaderboard fixes heroselect malchezaar
portraits_text spells fixes3 leaderboard2 giftbox noability nooverlay dimsize assetfix opponent2 fixes4 ovals
livepatch fixes5 fixes6b).

## Done this session
- **Minion ovals**: Hearthstone's in-play oval (stone frame; gold frame when golden) rendered from the HS install
  for all 1,092 minions. Hosted at `Jnipko488/mtg-table-data` commit `49ee3940…` under
  `hsbg/battlegrounds-multiplayer/s14-leaderboard/ov2/{n,g}/<cardId>.png` (RGBA, 300x372).
  `Draw.HSOVAL` lists the ids; `Draw.ovalArt` prefers them. Stat gems moved to x ±.37, z .20 so they sit on the frame
  brackets; deathrattle/trigger icons at z .47; the old `mo/gold.png` glow is skipped for these.
- **Live patch**: Rot Hide Gnoll (BG25_013) removed from the Season 14 pool and `pool=false`;
  Transport Reactor (BGDUO31_211) 3/3, golden 6/6. Tier 7 minions stay out of the pool (reachable only via Tier 7 effects);
  Duos-only cards stay out of solo. Other stats/tiers matched the live client.
- **Hero select**: "Minion Types:" + tribe names drawn as image chips
  (`s14-leaderboard/tribes/<RACE>.png`, commit `b430b1cd…`) inside the ribbon at near -4.45.
  TTS button labels were not rendering at that spot, cause not found.
- **Health gems**: `s14-leaderboard/hpgem/{w,g,r}/0-99.png` (commit `b430b1cd…`) replaced `refined/mg/h/` – grey bracket removed.
- **Spell text**: `Draw.spellTextOver` re-enabled (previews + Discover) with an opaque tan box and wider coverage;
  shows buffed +X/+Y values from `Draw.spellCardText` (only the first +X/+Y in the text is adjusted).
- Standings column on the HS leaderboard frame, End Turn slot, Hero Power medallions with the real coin (fixes4).

## Not done (for Codex)
1. **Exact Hearthstone spell text**: TTS labels can't use HS fonts. Plan: pre-render text-box images with
   `FranklinGothic.ttf` (bold keywords, centred lines like the card) for each of the 25 Tavern spells with +X/+Y,
   per bonus value, on parchment that matches the card render's text box (Draw.SPELL_TEXT_BOX = cx .473, cy .700,
   w .545, h .195 of the 512x776 HearthstoneJSON render). Then have `Draw.spellTextOver` place the image instead of the label.
2. **Real tavern spell frame**: HS uses the `Bacon_Play_Ability` actor in the shop. Frame texture
   `Bacon_Play_Ability_Frame_Atlas.png` (from `essential_base_global-texture-3.unity3d`) is in this folder. Spell portraits are
   not extracted yet (CardDef → `.tif:GUID` → bundle via asset_manifest, same as the minion pipeline). Composite portrait + frame
   + gold coin per price, replacing `recruit-combat/shop/<id>_<price>.png` (`Draw.shopSpellArt`).
3. Keyword overlays (Taunt, Divine Shield, Reborn, Stealth) still use the mod's art, sized for the old oval.
4. Tavern-spell price coin, combat and pop-up visuals have not had a match-to-Hearthstone pass.

## Files in this folder
- `FranklinGothic.ttf`, `Belwe.ttf` – Hearthstone fonts from `essential_base_global-content-0.unity3d`
- `Bacon_Play_Ability_Frame_Atlas.png`, `TavernSpellBuff.png` – HS textures for the tavern spell look

Note: the art in the GitHub repo is extracted from Blizzard's game files and the repo is public.

## Batch 2 (keyword art search)
- Searched every staged HS bundle for keyword textures. Found and saved in `keyword_textures\`:
  - `GenFX_ally_taunt_d.png` (Taunt shield diffuse; no alpha – it's mapped onto a mesh, so you'll need to mask it to a
    shield shape before using it in TTS) and `ally_taunt_GleamSpec.png` (its highlight/spec map);
  - `GenFX_AllyInPlayFrozen_D.png` / `_N.png`, `FrozenFrost_D.png`, `HeroFrozen_D.png`, `GenFX_FrozenFrostHero_D.png` (Frozen ice);
  - `BGSFX_Murloc_PoisonStreamer.png`, `352_PoisonBottle_Rare.png` (probably not needed).
- No textures exist for Divine Shield, Reborn, Stealth or Windfury in these bundles. In Hearthstone they're shader/particle effects,
  so in TTS keep image overlays (the mod's `refined/mo/*.png`), resized to the new oval (mod uses 1.5 x 1.4 of the token).
- Next step for Codex: mask `GenFX_ally_taunt_d.png` to a shield, scale it so the oval sits in its opening, upload it,
  and point the taunt overlay in `Draw.ovalDecals` (`mo/taunt.png`) at it for ids in `Draw.HSOVAL`.

## Batch 3 (Taunt) – save slot 197 "Season 14 HS Cards v6"
- Masked HS Taunt shield: `s14-leaderboard/kw/taunt_hs.png` (commit 9cd0aa77…). Module `fixes8.py`: for HS ovals the taunt
  decal is that image at x 0, z .04, size 1.75 x 1.33 (token units). Opening is slightly wide on the left – tweak size/mask if needed.
- v6 = v5 + fixes8. Use slot 197.

## Batch 4 (standings column) – save slot 198 "Season 14 HS Cards v7"
- User screenshot: hero tiles sat left of the leaderboard column's middle. `fixes9.py` draws the tiles at SPOT.lead x + .45
  and 8% larger (size L[4]*1.08). The column art (lb2/b3_*.png) is unchanged at x -13.05, width 3.1.
- If it is still off, compare a new screenshot: the light-grey column's centre vs the tiles' centre, and adjust the +.45.

## Batch 5 (standings, corrected) – save slot 199 "Season 14 HS Cards v8"
- Looking closer at the screenshot: the tiles were centred on OUR backer; the backer itself sat ~1 unit left of the board's
  leaderboard pillar. `fixes9.py` now moves SPOT.lead x -13.05 -> -12.05 (backer + tiles together), tiles 8% larger.
  v7 (slot 198) only shifted the tiles – skip it. Preview mockup: `standings_preview.png`.

## Batch 6 (standings on the board's own bar) – save slot 200 "Season 14 HS Cards v9"
- User: portraits must sit on the board's leaderboard bar, no separate backer. `fixes9.py` now also makes
  `Draw.renderLeaderBacker` remove its tiles and return (no crown/column art). Tiles at x -12.05 (board bar centre measured
  from the screenshot), pitch 1.95 from near -6.715, size 1.62*1.08. Mockup: `standings_preview2.png`.
- If the tiles need nudging, change `lead = {-12.05, ...}` in fixes9.py (x = left/right, 2nd value = top tile, 3rd = spacing).

## Batch 7 (standings like the HS reference screenshot) – save slot 201 "Season 14 HS Cards v10"
- From the HS client: `BaconLeaderboardIcons.png` (crown, rank coins, sword, emotes atlas) and
  `Default_T_Leaderboard_Frame_Texture.png` (bar texture + small icons incl. skull, with masks). Both copied here.
- Uploaded `s14-leaderboard/lb4/crown.png` (244x215) and `lb4/skull.png` (74x70), commit 2c40891a….
- `fixes10.py`: lead = {-12.05, -8.55, 2.46, 2.0} (tile size 2.0*1.08 = 2.16, pitch 2.46 – measured from the HS screenshot),
  crown above tile 1, dead players keep their portrait with dim.png + skull instead of kt_dead.png.
- Still to compare with HS: frame thickness/colour (lb_frame_*.png are ours), HP bar inside the tile.

## Status after batch 7
- User says the standings (v10, slot 201) are "still way off" – no screenshot of v10 yet.
- Suggested approach for Codex: take a TTS screenshot of v10 next to the HS reference, then:
  1. measure the board's bar centre and the top/bottom of the bar in TTS world units (SPOT.lead x, first tile near, pitch);
  2. rebuild the tile frame from the HS client textures instead of our lb_frame_*.png;
  3. keep the crown/skull from lb4/.

## Batch 8 (live ability text in Hearthstone's font) – save slot 206 "Battlegrounds Tavern - HS Text"
- Base: the user's latest save TS_Save_286160191 ("MTG All-in-one Table", contains Codex's slot-205 BG script). From now on
  patches are applied to the latest save with `apply_latest.py SRC DEST NAME modules...` (no more rebuild from the old chain).
- `hstext.py`: Draw.hsText(color, key, text, baseText, cx, cz, w, h, layer, lift) lays out text with FranklinGothic glyph decals
  (extracted from the HS client, `s14-leaderboard/hstext/{r,b,g}/<ascii>.png`, commit b578cc88…) on an HS parchment patch
  (`hstext/patch.png`, cut from HS `Card_Inhand_Generic`). Keywords bold, numbers that differ from the printed text green, word wrap +
  auto shrink. Used by: spell previews/Discover (Draw.spellTextOver), Hero Power + Trinket previews with a live state
  (preview.ability, base = h.text / tr.text). Tile keys are prefixes, cleared with removeTiles.
- Hero check: smoke test of all 118 heroes (pick hero, 11 turns, use power with each target type): no Lua errors; every active
  power fired except ones gated by Tier/turn/lobby size in the test.

## Batch 9 (Dark Gift + Timewarp purchasing) – save slot 207 "Battlegrounds Tavern - HS Text, Dark Gifts, Timewarp"
- Modules applied to the latest save: hstext darkgift2 timewarp2.
- `hstext.py` now takes opts {white, allBold, panel=url|false, lines}. White glyphs `hstext/{w,v}/` + `hstext/giftpanel.png`
  (commit d3b9295c…).
- `darkgift2.py` (redone after user feedback): uses Hearthstone's own Dark Gift banner. Found by exporting the prefab
  `BaconFX_DarkGift_Choice_Reveal_Battlegrounds` (bundle initial_base_global-64194cb9-prefab-1 + texture deps): its
  BigCardEnchantmentPanel = EnchantBannerBody/Bottom meshes with `EnchantmentBannerBlue` + an enchantment tile
  (`History_Tiles_D_gold` frame, `HS34-218_S` icon). Rendered top-down to `s14-leaderboard/darkgift/banner.png` (commit 6df43cbf…).
  Banner hangs under each minion; gift name (bold cream) + text (white) in HS font to the right of the icon.
  Every gift shows the same icon (HS34-218) – per-gift icons would need each gift's enchantment card art. The purple "my own panel"
  version (giftpanel.png) is no longer used.
- `timewarp2.py`: Timewarp offers ordered by Chronum cost (per the HS wiki), minions drawn as HS in-play ovals with atk/hp gems,
  Tier badge on top and the Chronum coin directly under it (wiki: "Chronum cost under the Tier"). Spells keep their card art.
- HS client assets found for later: Timewarp_Medalion_Icon / _Shadow (Timewarp button), Bacon_DarkGiftMedallion (Dark Gift
  button ring), prefabs BaconFX_TimewarpTavern_SandVignette, BaconFX_DarkGift_Choice_Reveal_Battlegrounds (VFX, not extracted).
- Not done: Nozdormu bartender swap, sand vignette VFX, animations; no live TTS check (the game must be started from the BG menu).

## Batch 10 (looked at the live game in TTS) – save slot 208 "Battlegrounds Tavern - HS UI v2"
Modules on the latest save: hstext darkgift2 timewarp2 ui3. Seen in the live game (slot 207) and fixed in `ui3.py`:
- Right column was a pile-up: Dark Gift button, "Turn N" label, countdown and "Tier X / Upgrades in N turns" all overlapped above
  End Turn. Now: no Turn label (HS has none); countdown in HS's tooltip stone frame (`ui/tooltip_frame.png` from HS
  `TooltipFrame1`, commit d33ef6e0…) under End Turn, shown as "51s" like HS (m:ss above 59 s); Dark Gift button moved to
  (11.45, -3.75) clear of End Turn and the 7th tavern slot (HS puts it at Zone_Friendly_GameModeButton5_DarkGifts = right end
  of the tavern row; HS zone coords read from BoardStandardGame/ZoneMgr in essential_base_global-prefab-0).
- Dark Gift hover: the TTS tooltip text is replaced by an HS tooltip panel (stone frame, "Dark Gift" bold title + rule text in HS
  font). New preview field `preview.tooltip = {title, text}` handled in Draw.renderPreview; preview.abilityBase now passed through.
- Standings: portraits sat left of the board bar's middle and were narrower than the bar → SPOT.lead right -13.08 → -12.82,
  height 1.80 → 2.05.
- Minion Tier badge floated above the oval → tierNear -.54 → -.47 (taunt -.72 → -.62).
- Still seen: Timewarp spells keep their full card with the printed gold coin and the Chronum coin below the card; "Return to
  Tavern" is a plain TTS button; Turn label in old saves.
HS board zones (HS units, x right / z up from board centre; mod ≈ right = x*1.84, near = -z*1.84): Hero (0.16,-3.61),
HeroPower (2.14,-3.65), Trinket1 (-1.42,-4.18), Trinket2 (-2.29,-3.39), Buddy/QuestReward (-1.87,-3.63),
DarkGift button (5.79,1.32), Anomaly (7.48,0.91).

## Batch 11 (real tavern-spell look) – save slot 209 "Battlegrounds Tavern - HS UI v3"
Modules on the latest save: hstext darkgift2 timewarp2 ui3 spellshop.
- Spell portraits: CardDef → `.tif:GUID` → bundle (catalog) for the 61 Tavern spells + 26 Timewarp spells; staged 33
  cardtexture bundles from the user's HS install; portraits in /home/claude/hs/spell_portraits (512²).
- Frame: HS `Bacon_Play_Ability_Frame_Atlas` (the shop/in-play actor for BG spells). make_spellshop.py masks the stone frame,
  fills the opening with the portrait, adds the atlas's gold coin with the price in Belwe. Output `s14-leaderboard/spellshop/
  <id>_<price>.png` (prices 0..cost+1, 360x400, commit 17cc69d8…) and `<id>_tw.png` without coin for Timewarp (commit 9bd40519…).
- `spellshop.py`: Draw.shopSpellArt prefers these (Draw.HSSPELL). `timewarp2.py`: Timewarp spells use the frame + Tier badge +
  Chronum coin under it, like the minions; hover still shows the full card.
- Dark Gift icon: every HS Dark Gift enchantment (BG36_MidGameEffect_*) uses portrait HS34-218 → the single icon is correct.

## Batch 12 (user screenshots of v3) – save slot 210 "Battlegrounds Tavern - HS UI v4"
- Spell frames: HS portrait textures carry white padding rows at the bottom → make_spellshop.py trims them (spellshop images
  re-uploaded, commit d9038fe6…).
- Minion Tier badge: my move to -.47 made it overlap the portrait decal and TTS sorted it behind at most angles → reverted to
  Codex's -.54 (taunt -.72).
- Empty stone box under End Turn = the countdown frame; its label had a fully clear background, and TTS does not draw labels
  on a clear background (same reason the hero-select chips had to be images). Label now has the frame's grey background.
- Constant "attempt to index a nil value" when the Dark Gift button showed: Draw.pulseDarkGift read card.labels[1] after I
  removed the labels → guarded.
- Dark Gift button now at HS's Zone_Friendly_GameModeButton5_DarkGifts spot (10.65, -2.43). Hover = HS card
  BG36_Button_DarkGift "Dark Discovery" text: "Discover a Tier X or Y minion with a Dark Gift. (N uses left)" in the HS tooltip
  frame. (Its portrait is HS34-218_HP1 in cardtexture_base_global-48ae08f3-texture-22 if someone builds the full big card.)
- 8-player standings: Codex's extra dark rail covered the top portraits → removed; >4 players: pitch = min(2.42, 15.6/(n-1)),
  tile size = pitch*0.86, centred at near -0.75.

## Batch 13 (user screenshots of v4) – save slot 213 "Battlegrounds Tavern - HS UI v7" (skip 211/212; 212 had a nil-concat bug)
Modules on the latest save: hstext darkgift2 timewarp2 ui3 spellshop ui4 heropowers.
- Taunt: shield decal now added before the portrait so the oval + stone frame sit in front of it.
- Timer: whole seconds (deadline is a float → "40.3150184s"), small stone box left of End Turn (SPOT.endturn x - 2.55).
- Opponent panel: red glow box (b_preview_lbglow) removed; panel moved 2.2 further right (x + 3.2); "Played by", top tribe
  ("Undead x3") and "Combat History" drawn with HS-font glyphs (the old labels had clear backgrounds → never drawn).
- Crown: above the first tile's frame (near - size*.93) so it never overlaps/sorts behind the frame.
- Progress labels under Hero Powers / Trinkets removed (Draw.progressLabel → removeTile); the live card text has the counter.
- Timewarp Tier badge / Chronum coin: drawn higher and with more lift so they stay above the card at all angles.
- Dark Gift hover: the real HS card BG36_Button_DarkGift "Dark Discovery" (user's screenshot of the HS render, text box
  inpainted: `ui/dark_discovery.png`, commit 72f0ebbe…) with the live text drawn in HS font ("Discover a Tier X or Y minion with a
  Dark Gift. (N uses left!)"). Field preview.boxText = {text, base, cx, cy, w, h} (fractions of the card).
- Hero Powers (`heropowers.py`): real HS art for all 118 powers (CardDef portraits extracted from the user's install,
  /home/claude/hs/hp_portraits). Board medallion `hp4/<heroId>_{n,r,u}.png` (HS ring, ready glow, used grey + padlock) + gold
  cost coin; hover card `hpcard/<heroId>.png` = HS BG power card frame (from the Dark Discovery render) with the power's
  portrait and name in Belwe, rule text drawn live (counters/buffs, changed numbers green). Second power and the opponent
  panel's power card use the same cards. Commit 1b6d2900….
- Not done: drag-to-buy in the Timewarp tavern (offers are board decals, not tokens); slow first loads (TTS downloads each
  image on first use — a preload step could fetch the common ones at game start); Dark Gift button position still at HS's
  GameModeButton5 zone (10.65, -2.43) – user says it is wrong, needs a screenshot from real HS to place it.
- Starting a game for testing: Setup Box → its top button opens the settings panel next to it (faces the host) → Start.

## Batch 14 — Timewarp drag-to-buy + asset preloading (save slot 214, "Battlegrounds Tavern - HS UI v8")
Module order: `hstext darkgift2 timewarp2 ui3 spellshop ui4 heropowers warpdrag preload`

**warpdrag.py**
- While `p.timewarpVisit` is open, each Timewarp *minion* offer becomes a real tavern token (`entry("w"..turn.."x"..i, "tavern", ...)`, `d.warpIndex = i`, `d.combat = false`), sorted by cost, using the normal HS oval art (`Draw.warpToken`).
- Drag the token into your hand or onto the lower board (`near > -0.6`) to buy it: `resolveDrop` handles kind `"w"` → `BG.timewarpPick(game, owner, warpIndex)`; otherwise it snaps back (`syncSeat`).
- Token-backed slots draw only the Chronum cost coin `b_pkcoin*`, now at `near - .49*H - .62` (≈ -4.63), above the Tier badge so it no longer sits inside the card.
- Timewarp **spells** are still click-to-buy: `Draw.spellState`/`tokenDescription` index `BG.SPELLS`, which has no entry for Timewarp spells. To make them draggable, add nil-safe paths there first.

**preload.py** (slow pop-in)
- `Draw.preload(urls)` adds URLs to a growing list and calls `self.UI.setCustomAssets(list)` on the controller. TTS downloads and caches every custom asset, so images are already local when tiles spawn.
- `Draw.preloadCore()` runs 3 s after `onLoad`: Dark Gift banner, Dark Discovery card, tooltip frame, crown, skull, parchment, plus every hsText glyph (`r/b` from Draw.HSG, `w/v` from Draw.HSG2, green digits).
- `Draw.preloadGame()` runs from `renderAll` once per phase:turn: offered heroes' `hpcard`/`hp4_n`, chosen heroes' `hp4_{n,r,u}`, and `ov2/n` ovals for pool minions up to the highest player tier + 1.
- Test: `test_ui3.py <lua> preload` → 393 core + about 270 game URLs, no errors.

**Still open**
- Dark Gift button spot: HS zone data puts GameModeButton5 at mod (10.65, -2.43), but the user says that is wrong. An HS screenshot showing the button during a Dark Gift turn is needed.
- Animations/VFX (Dark Gift reveal, Timewarp sand vignette), Nozdormu bartender, "Return to Tavern" button style, Timewarp spell drag.

## Batch 15 — fixes from user screenshot round (save slot 215, "Battlegrounds Tavern - HS UI v9")
Module order: `hstext darkgift2 timewarp2 ui3 spellshop ui4 heropowers warpdrag preload fix9`  (modules/fix9.py)
- **Death Speaker Blackthorn (BG20_HERO_103):** Bloodbound now puts 2 Blood Gem cards in hand (`E.giveSpell(g,p,"BG20_GEM")`, twice per turn) instead of silently applying them to random minions. The old NOTE was removed.
- **Live text on spells in hand:** `Draw.spellDecals` adds hsText glyph decals on the card itself when `Draw.spellCardText` differs from the base text: Blood Gem +X/+Y in green, spell bonuses, Spellcraft power. `Draw.hsText` can capture into `Draw.HSCAP` instead of drawing board tiles (`Draw.hsPut`).
- **Taunt shield:** `kw/taunt_hs2.png` (commit 65728a0a). Alpha is rebuilt from the convex hull minus the portrait hole, so there are no see-through patches.
- **Timewarp shop composition:** `E.timewarpSlots`. 5 cards = 3 minions + 2 non-minions; 3 cost 1 Chronum and 2 cost 2+; the Minor (Tier 3) visit always has exactly one 2nd Hero Power (none if you already have two); the Major has none.
- **Timewarp spells and Hero Powers are draggable tokens** (`Draw.warpSpellToken`, `d.warp`, `d.spell`). New 2nd Hero Power shop art `spellshop/BG34_HeroPowerSpell_*_tw.png` (commit 65728a0a), made from the real hero power portraits in the Timewarp frame.
- **Asset audit:** every GitHub URL in the script (182 fixed files, 28 folders, and 1855 generated oval, hero power and spell-shop paths) exists in the repo.
- **Still served from art.hearthstonejson.com** (public, so it works in multiplayer): full card renders for hand spells and previews, hero portraits, quest paintings. About 2,800 paths are listed in `/tmp/hsjson_paths.txt`. Mirroring them into GitHub needs either a GitHub Action (blocked here without the user's approval) or re-rendering from HS app bundles.
- **Open:**
  - Dark Gift button: HS zone `Zone_Friendly_GameModeButton5_DarkGifts` is local (5.86, 5.04, 1.38), scale .47, under ZoneMgr. With the button-derived mapping right=(x-.23)*1.94, near=-7.35-(z-3.4)*1.92, that gives mod ≈ (10.9, -3.5). The user says the current spot is wrong; a screenshot is needed.
  - Heroes to check in a live game: Galewing, Jim Raynor, Putricide, Akazamzarak, Cariel (after-combat improvement choice not in the engine), Bigglesworth, Silas. The engine smoke test passes for all 7.

## Batch 16 — named heroes (save slot 216, "Battlegrounds Tavern - HS UI v10")
Module order: `... fix9 fix10` (modules/fix10.py)
- **Cariel Roame:** Conviction gives (1+carielN) random minions +(1+carielA)/+(1+carielH). After each combat a choice of Offensive Stance (+1 Attack), Defensive Stance (+1 Health) or United Stance (+1 minion), using the `mode()` and `resolvers` hero_option system. Live HP text is in `Draw.powerState`. NOTE removed.
- **Galewing:** current HS flightpaths (wiki, patches 33.6–34.2): Westfall = in 1 turn get a random 1-Cost Tavern spell; Ironforge = in 2 turns gain 2 Gold; Eastern Plaguelands = in 3 turns Discover a minion of your Tier. The Flight Trainer buddy still repeats the bonus. HP text shows the flightpath and "(N turns left!)".
- **Silas Darkmoon:** Tavern minions with a Darkmoon Ticket now show the real HS ticket (`DMFFX_DarkmoonTicket` from essential_base_global-texture-2) at the bottom of the oval. Asset `ui/darkmoon_ticket.png` (commit a6673688). Before this, tickets were invisible.
- **Checked and working in the engine:** Jim Raynor (Battlecruiser at start, Upgrades on refresh), Professor Putricide (2-step craft; the Creation has its HS oval), Akazamzarak (choose 1 of 3 Secrets, max 5), Mr. Bigglesworth (Discover from an eliminated warband, keeps enchantments).
- **Not verified visually in TTS yet:** the Stance and flightpath choice cards use the generic hero_option card, not HS's own card art.

## Batch 17 — Dark Gift button position from the user's HS screenshot (slot 217, "HS UI v11")
- `fix11.py`: the Dark Gift medallion sits on the stone rail above End Turn: right 14.1, near -4.8, size 2.3 (was 10.65, -2.43, 1.6). In the HS screenshot it is centred on the rail groove, about 35% of the way down from the skull ornament to the Recruit/End Turn button.
- The Dark Discovery hover card hangs to its left: right 10.75, near -4.9, size 4.8.
- If it needs nudging, change those numbers in `fix11.py` (right = toward the rail, near negative = toward Bob).

## Batch 18 — wrap-up (slot 218, "Battlegrounds Tavern - HS UI v12")
Module order: `hstext darkgift2 timewarp2 ui3 spellshop ui4 heropowers warpdrag preload fix9 fix10 fix11 fix12`. `apply_latest.py` now also runs a module's `patch_save(save, replace)` to patch other objects.
- **Taunt:** `kw/taunt_hs3.png` (commit 815a923a). The shield has a clear elliptical window over the portrait, so no grey covers the art even when decals sort badly.
- **Lag spikes:** the per-turn `setCustomAssets` calls are gone. There is now a single preload per game when hero offers appear: core UI, glyphs, offered heroes' power art, every pool minion oval, pool spell art and shop art. It prints "Downloading Hearthstone Cards for better Performance. Please wait." and then "Hearthstone Cards downloaded." once `self.UI.loading` clears.
- **Start messages:** no "table is moving" or "wait for the MTG mats" messages. The start retries quietly for up to 90 s. The Setup Box (f06d01) no longer blocks on `mtBusy`.
- **Right-click:** the custom Setup Box context entries (Advance Arena phase, Arena lane game, flip card text, keyword art) are removed and `clearContextMenu()` is called.
- **HearthstoneJSON mirrored to GitHub:** `.github/workflows/mirror-hsjson.yml` downloads `hsbg/hsjson/paths.txt` (2,835 paths) and commits on top of the branch head. 2,607 files are at commit 0d1188d1 under `hsbg/hsjson/v1/...`. The 228 missing ones don't exist upstream (speculative hero ids); every URL the script actually names was mirrored. The script now points every `art.hearthstonejson.com` URL at the mirror, so all BG art loads from the user's GitHub. To add more art, append paths to paths.txt and push; the workflow re-runs.

## Batch 19 — on Codex's save 219 ("HS UI v12 - Card Art Fix") → slot 220, "Battlegrounds Tavern - HS UI v13"
New base: `TS_Save_219.json`. Apply only new modules on top: `apply_latest.py TS_Save_219.json out.json NAME fix13 fix14` (workdir /home/claude/polish2). Codex had switched the dynamic card-render builders back to art.hearthstonejson.com; that choice was kept.
- `fix13.py`, heroes closer to current HS:
  - **Cariel** counters unified with her buddy: carielAttack/Health/Targets, base 1.
  - **Scabbs** I Spy uses the NEXT opponent from `E.recruitPairings` (the ghost when paired with one).
  - **Malygos** can target the Tavern or the warband.
  - **Saurfang** uses buys this game for both refresh and start of turn.
  - **Dancin' Deryl**'s hat passes on sell (via `buddyHats`).
  - **Y'Shaarj** picks a minion at end of turn, summons it at Start of Combat and puts that same minion in hand after combat.
  - Matching NOTEs were cleared.
- `fix14.py`: Galewing flightpaths and Cariel Stances are real HS hero-power choice cards. They are built from HS card portraits (BG20_HERO_283p_t1-3, BG21_HERO_000_Buddyt/_Buddyt2, BG21_HERO_000p_t1, from cardtexture_base_global-48ae08f3-texture-1/5). Template = median of hpcard images, Belwe name, description drawn with hsText on the parchment. Assets: `hpcard/<id>.png` at commit c969a94d. United Stance text matches HS exactly.
- Tested: crawl errors 0; hero smoke test for all 118 heroes passes; test modes `stance` and `yshaarj` added.

## Batch 20 — VFX + Activate (slot 221, "Battlegrounds Tavern - HS UI v14"; modules fix13 fix14 fix15 on save 219)
- **VFX player** (`fix15.py`):
  - A pool of up to 14 invisible locked Custom_Token "carriers" (GMNotes `hsbg_fx`, removed on load) plays decal flipbooks at 3 frames per image.
  - Triggers: combat damage = `hit`; a Divine Shield lost = `shield`; a combat token removed = `death`; event `combine` = `golden`; `upgrade` = `tierup` at the Tavern-tier button; `buy`/`sell` = `coin`; a Dark Gift purchase = `darkgift` at the button.
  - The frames are preloaded with the one-time card download.
- **Flipbooks** (`fx/<kind>/<n>.png`, commit 96a36fac): built by `tools/mkfx.py` ONLY from Hearthstone GenFX textures pulled from the user's install (cardtexture_base_global-41caf0cf-texture-0: Shockwave8, BlastWhite, FlareStarWhite2/Gold2, glow_ring2b, Starburst_ThinLines, SpinRing4, Smoke03, CloudPuff1, Smoke6, MiniMotes1, Flare_White2, CloudFireBW_Alpha, FlareWarlock1, embers02). The arrangement and timing are hand-made, not taken from HS's particle systems.
- **Toward exact HS effects:** `tools/vfx.py` simulates the game's own ParticleSystem data (Initial/Emission bursts/Shape/Size/Color/Rotation/UV modules, renderer material + texture) and renders top-down flipbooks. It works (tested on `Death_Root` + `FX_Death_Motes`).
  - Exact HS effect prefabs found in initial_base_global-2ebe64b8-prefab-4: Divine Shield pop = `FX_DivineShards` + `FX_Pop` (material CAB-179fe96d…, bundle not yet found); damage = `PS_FlashHit` (mat in 5c47a539-material-2, texture bundle not staged), `PS_Flare` (0fde4609-material-1), `FX_DamageShards` (CAB-179fe96d), `FX_Portrait_HitBlast`; triple = `Card_Play_Ally_Bacon_LastofaTriple/FX_Arrow` (75c96a85-material-0); reborn = `FX_Reborn_Minion_Fragments` (CAB-80feb78a).
  - Many use HS's custom ramp shaders (`_LookupTex` = GenFX_ColorRamps with _MidColor/_LastColor/_WhiteColor), which vfx.py does not emulate yet.
  - CAB→bundle lookup: stage material deps (list in `/tmp/p4deps.txt`, from deps.pkl) and scan with `scancab.py`.
- **Activate:** the button art is now a decal on the minion token (moves while dragging and when reordered), plus a transparent object button (`bgActivateClick`, 330×330, scaled 1/obj scale) for the click. The old fixed board tile is disabled.

## Batch 21 — fixes from the user's test (slot 222, "Battlegrounds Tavern - HS UI v15")
- **Import pop-ups and errors (on buying, in combat):** caused by the VFX carriers. They were Custom_Tokens with a fully transparent image, so TTS could not build a mesh and opened the Custom Token import dialog. Carriers are now built-in `BlockSquare` objects (scale 0.1, sunk 1.2 below the effect point, decal raised above). Built-in objects never open an import dialog.
- **Black box on tier-up:** the same failed carrier. FX frames were also re-saved with transparent pixels coloured like the effect (no dark fringes); commit 0b2598b6. All frames are used now (n = 8/9/10/12/10/8/12).
- **Hero power notch:** new `hp4b/<hero>_{n,r,u}.png` (commit bc1d2f61) has the cost-coin notch filled with mirrored ring art. It is used when no cost coin is drawn (free/passive powers, the 2nd power).
- **URL audit:** every card/spell art URL the mod can build (4,759: tokens, ovals, shop spells, previews, golden) was checked.
  - All 3,358 GitHub URLs exist.
  - All but 7 of the HearthstoneJSON URLs exist; the 7 are golden "_triple" renders HearthstoneJSON doesn't have, and those now fall back to the normal render.
  - The GitHub mirror now covers all 3,001 paths (`hsbg/hsjson`, commit f98c7043; missing.txt lists the 404s).
- **Spawn audit:** the script spawns objects in only two places: card tokens (images verified above) and the FX carriers (now built-in objects).

## Batch 22 — Activate look + text fixes (slot 223, "HS UI v16"; modules fix13-16 on save 219)
- **Activate:** a gold cost coin (`hp3/coin/N.png`) sits top-right of the portrait (oval x .33, z -.40). A green oval glow (`ui/oval_glow_green.png`, commit 505f29f2, built from the ov2 frame alpha) shows when the activation is usable. Once used, the coin becomes the round Activate icon without the cost (`ui/activate_used.png`). The object button sits over the coin (210×210) and is removed once used.
- **While choosing an activate target** (`p.discover.kind == "activate_target"`), every legal target (`options` uids) gets the green glow.
- **Text at any camera angle:** hsText glyphs are now +.05 above their parchment (was +.01); hand-card text decals +.03.
- **Spell text box** re-measured on the real render: `Draw.SPELL_TEXT_BOX = {cx=.500, cy=.727, w=.640, h=.225}`. It now covers the printed text fully (Blood Gem +X/+Y).

## Season 15 "Warped Empire" — research (patch 37.2, live December 1, 2026)
Sources: Blizzard "An Early Look at Patch 37.2" (hearthstone.blizzard.com/en-us/news/24316976), hsbg.cards/patch-notes/37.2 (516 card changes: 146 removed, 171 returning, 79 changed, 162 new), Developer Insights on bluetracker.gg.
- **System:**
  - Trinkets and Dark Gifts rotate OUT.
  - The Timewarped Tavern returns (Turns 6 & 9, Chronum).
  - Stealth leaves the Bonus Keyword pool (replaced by Resilient).
  - "When you have space" effects now trigger after all Start of Combat effects ("Once you have space each combat").
  - Each Deity has its own Aberration-death count (C'Thun/Y'Shaarj 4, N'Zoth 3).
- **New keywords:**
  - **Resilient:** takes half damage when attacked (rounded up); its own attack damage is unchanged.
  - **Mission:** a one-time goal while in play; a tripled Mission minion resets and keeps progress.
  - **Elemental Invocation:** the Invocation spells (Earth T2 +3/+3 Taunt; Fire T3 +4/+4 Reborn; Air T4 +5/+5 Windfury; Water T5 +6/+6 Divine Shield; the keyword lasts until next turn, Elementals only). Command the Elements (T5) gets all 4.
- **New heroes:**
  - **Vanessa the Ringleader**, "Strategic Edge": Discover a Tier 1 minion, improved by each minion bought this turn.
  - **Eternus**, "Dawn of the Infinite": skips turn 1 to visit the Major Timewarp; cards bought stay locked until 45 Gold is spent.
- **New Deity:** N'Zoth (T1 1/1 Aberration, Deity (3), Taunt; Deathrattle: goes back to sleep and reawakens after 3 more friendly Aberration deaths).
- **New spells:** Goldrinn's Blessing (T4, Beasts +1/+1 this game), the Invocations above, Dragonstorm (T6, Dragons get "end of turn +2/+2"), Tumultuous Growth (T4, cast 2 random Tavern spells on a minion), Unholy Ritual.
- **New minions (names; exact stats/text still to collect):**
  - Aberration: Growing/Sickly/Ominous Ooze, Faceless Necromancer, Shambling Shadowfiend, Tainted Tormentor, Erupting Eyestalk, Underrot Infestor, Vindictive Preacher, Merciless Warden.
  - Beast: Great Wolf Cub, Great Direwolf, Young Mukla, Flying Monkey, Cunning Chameleon, U'cha the Mighty, Loti (Devilsaur Form), Ribbiting Magician, Elder Moonbeast.
  - Demon: Hardy Felhound, Imp-erial, Pain Promoter, Nonchalant Napper.
  - Dragon: Timeless Mount, Scaled Sovereign, Twilight Traverser, Future Fighter.
  - Elemental: Tsunami Surfer, Effusive Dancer, Thunder Knight, Driftaway Djinni, Crafty Cookfire, Wave Watcher, Desert Duelist, Land Upheaver.
  - Mech: Bot Launcher, Prototype Builder, Hammer Hero, Defense Mechanism, Light Generator, Surging Sanctifier.
  - Murloc: Greymist Infiltrator, Squirky, Ambitious Recruit, Bloodfin Scholar, Gorloc Gardener.
  - Pirate: Cut-rate Crewman, Ambitious Cannoneer, Hostile Haggler, Ruthless Pursuer, Crooked Banker, Freedom Fighter.
  - Quilboar: Tenacious Thorn-witch, Brutal Bristlethorn, Dauntless Adventurer, Voidtouched Geopriestess.
  - Undead: Patrolling Gargoyle, Crypt Crawler (T3 5/6, Mission: after 18 friendly deaths give Undead +10 Attack), Graveyard Skulker, Ossifier, Saronite Colossus, Scaretaker, Shackled Shade.
  - Neutral: Patron Gatherer, Obsessive Artisan, Temple Keeper, Eclectic Musician.
  - Plus about 37 new Minor and 44 new Major Timewarped cards.
- **Changed (examples):**
  - C'Thun: Deity (4), awakened stats split among your other minions.
  - Goldrinn: T6 5/5, Deathrattle Beasts +5/+5 this game.
  - Hooktusk, Master Marauder: 8/8, after you Discover, other Pirates +2/+2.
  - Wizened Captain: T6 6/6, spell → Pirates +3/+2.
  - Echoing Roar: cost 2, "end of turn +3/+3".
  - Sanctify: T4, +4 Attack.
  - Nether Drake: 4/12.
- **Plan:**
  1. Add an "s15" season (pool = returning + new; trinkets/dark gifts off; timewarp on; Stealth out of the bonus pool).
  2. Implement Resilient in the combat damage path, Mission (progress counters + reward) and Invocations.
  3. Implement the two heroes and N'Zoth.
  4. Implement the minions type by type once exact stats/text are available. HearthstoneJSON cards.json and renders appear after the Dec 1 client patch; the Season 15 art also arrives in the user's HS install then.

## Batch 23 — Season 15 batch 1 (slot 224, "HS UI v17"; modules fix13-17 on save 219)
- **Settings:**
  - The season row is now a button cycling Season 14 (default) / Season 15.
  - The roster defaults to **Five Tribes**; the "Scripted Minions" mode is gone, and every game uses scripted minions only (`fullMinions=false`).
  - Season 15 games force Trinkets OFF, Dark Gifts OFF and Timewarp ON.
- **Data** (`modules/s15/data.py` → `gen.py` → `defs.lua`/`season.lua`/`stats.lua`):
  - All 66 new S15 minions have exact tier/stats/type/text from Blizzard's 37.2 notes, ids `S15_<name>` until the real ids exist.
  - The s15 pool = S14 pool − 108 removed + 41 returning + the new ids.
  - 27 stat/tier changes go into `E.seasonStats.s15`.
  - Unscripted new cards have `fx="none"`, so they never appear.
- **Rules:**
  - Resilient (`m.resilient`; attack damage on it is halved, rounded up).
  - New FX hook `beAttacked(C,S,self,attacker)`.
  - "Beasts have +X/+Y this game" aura (`p.beastA/H`, applied with the Undead aura).
  - `fixedCost` on cards (Cut-rate Crewman costs 2).
- **Scripted now (24):** Hardy Felhound, Cut-rate Crewman, Young Mukla, Flying Monkey, Eclectic Musician, Wave Watcher, Gorloc Gardener, Defense Mechanism, Nonchalant Napper, Merciless Warden, Vindictive Preacher, Ribbiting Magician, Light Generator, Hammer Hero, Shackled Shade, Elder Moonbeast, Ossifier, Freedom Fighter, Patron Gatherer (Mission), Obsessive Artisan (Mission), Ambitious Cannoneer (Mission), Brutal Bristlethorn, Graveyard Skulker (Activate), Temple Keeper (Activate).
- **Art:** placeholder ovals (tribe-coloured portrait with the name, real HS oval frame) at `s15ov/{n,g}/S15_*.png` (commit 4da08918). Used for board and hand until the real art ships Dec 1.
- **Next batch:**
  - New spells: Goldrinn's Blessing, the Invocations, Command the Elements, Unholy Ritual, Dragonstorm, Tumultuous Growth; returning Echoing Roar and Sanctify.
  - The minions that need them (Great Wolf Cub, Direwolf, Patrolling Gargoyle, Scaretaker, Effusive Dancer, Tsunami Surfer, Thunder Knight, Timeless Mount, Scaled Sovereign, Surging Sanctifier, Oozes).
  - "Gains a Bonus Keyword" hook (Djinni, Desert Duelist, Geopriestess, Cookfire).
  - Combat-persistent Missions (Crypt Crawler, Imp-erial, Loti, Greymist, Bot Launcher, Thorn-witch); Mission "(N left!)" live text.
  - The behaviour changes of the returning/changed minions; Timewarp card changes; Vanessa, Eternus and N'Zoth.

## TS_Save_225 — "Battlegrounds Tavern - HS UI v18" (fix13…fix18) — Season 15 batch 2
- fix18.py: Season 15 spells (ids `S15S_*`, defined in /home/claude/s15/spells.py):
  - Goldrinn's Blessing (Beasts +1/+1 for the rest of the game, via E.beastAura).
  - Invocations of Earth/Fire/Air/Water (Elemental only: +3/+3 Taunt, +4/+4 Reborn, +5/+5 Windfury, +6/+6 Divine Shield, all until next turn).
  - Command the Elements (gives all 4 Invocations).
  - Dragonstorm (Dragons get an end-of-turn +2/+2 enchantment, `S15E_dragonstorm`).
  - Tumultuous Growth (casts 2 random Tavern spells on a minion).
  - Echoing Roar (end-of-turn +3/+3 enchantment, `S15E_echo`).
  - Sanctify (Divine Shield minions get +4 Attack).
  - Costs are estimates until the patch data exists.
- `E.seasonSpells.s15` = the S14 rotation minus the 6 removed spells, plus the new pool spells (62 total).
- Enchantments sit in m.attachments with enchant=true. They show on the card's detail lines (Draw.ENCHANT_TEXT) and do not count as magnetizations.
- 12 more S15 minions scripted: Great Wolf Cub, Great Direwolf, Timeless Mount, Effusive Dancer, Tsunami Surfer, Thunder Knight, Twilight Traverser, Surging Sanctifier, Dauntless Adventurer, Land Upheaver, Scaled Sovereign (Activate 2 → Dragonstorm; refreshes after you play a Dragon), Faceless Necromancer (Activate 0, hand target → discard, left-most Aberration gets Reborn until next turn).
- New spells use placeholder card and shop art (commit fd109990, s14-leaderboard/s15sp/).
- Tests: crawl 0 errors; s15cards 35 scripted / 0 errors; /tmp/s15spells.py (cast every new spell and fire every hook); herosmoke; s15smoke.
### Real S15 art status (Nov 27)
- The installed client (Data/Win/dbf.unity3d, updated Nov 27) has NO Season 15 cards: no BG37 ids and none of the new names. Real art and ids arrive with patch 37.2 (season starts Dec 1).
- Blizzard's article (hearthstone.blizzard.com/en-us/news/24316976) has official card images for:
  - Hardy Felhound, Nonchalant Napper, Obsessive Artisan, Loti, Effusive Dancer
  - Invocations of Earth/Fire/Air/Water, Command the Elements
  - Treasure Parrot, plus the heroes Eternus and Vanessa
  - These are bnetcmsus-a.akamaihd.net URLs. The sandbox can't download them (proxy 403). A GitHub Action that would mirror them was blocked pending the user's OK.
- Once 37.2 is installed: re-stage dbf.unity3d plus the card texture bundles, map the `S15_*`/`S15S_*` keys to real ids, and regenerate ovals, hand and shop art like S14.
