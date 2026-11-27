# HSBG TTS mod — dev sources
- `build/b9a001_latest.lua`: the controller (GUID b9a001) script as installed in TS_Save_225 ("Battlegrounds Tavern - HS UI v18").
- `modules/`: patch modules applied on top of TS_Save_219 with `apply_latest.py <base save> <out> "<SaveName>" fix13 … fix18`.
- `s15/`: Season 15 (patch 37.2) data. `data.py`/`spells.py` are the sources; `gen.py` writes `defs.lua`/`season.lua`/`stats.lua`.
- `tools/`: VFX particle simulator, texture indexers and the test harness scripts.
- `HANDOFF_NOTES.md`: full change log and the open work list.
