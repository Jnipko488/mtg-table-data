# Hearthstone Battlegrounds for Tabletop Simulator: hosted assets

Images and models loaded by the "Hearthstone Battlegrounds" table (Battlegrounds Tavern controller in the
MTG All-in-one Table save). Built by `Tools/pack_cloud_assets.py` in the "Hearthstone Battlegrounds TTS"
project. The save loads them from raw.githubusercontent.com pinned to a commit, so files here can be
replaced without breaking older saves.

- `f/` card faces (stat numbers erased; the table draws live stats), `<id>.png` normal, `<id>_g.png` golden
- `h/` hero portraits, `p/` Hero Powers, `t/` trinkets, `a/` anomalies
- `ui/` Refresh, Tier Up, Freeze, End Turn, gold, armor, keyword art, Bob, panels
- `tts/` Tabletop Arena Setup Box model, Arena board bundle, controller model
- `manifest.json` every file with its size and SHA-256

Card and UI art is from the owner's own Hearthstone install and HearthstoneJSON renders, for personal table use.

Format (since the v4.2 table): every PNG is 32-bit RGBA. Images the table spawns as Custom Tokens (`f/`,
`ui/bob.png`) have hard alpha and a 4 px transparent border, which TTS needs to build the token shape;
older palette PNGs made TTS reopen its Custom Token import dialog.
