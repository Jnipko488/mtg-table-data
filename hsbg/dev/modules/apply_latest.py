"""Apply patch modules to the user's latest save (keeps Codex's and earlier work). usage: apply_latest.py SRC DEST NAME mod..."""
import json, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent; sys.path.insert(0, str(HERE))
src, dest, name = sys.argv[1], sys.argv[2], sys.argv[3]
def replace(s, old, new, count=1):
    n = s.count(old)
    if n != count: raise SystemExit(f"{n} matches for {old[:90]!r}")
    return s.replace(old, new)
save = json.loads(Path(src).read_text(encoding='utf-8'))
ctl = next(o for o in save['ObjectStates'] if o['GUID'] == 'b9a001')
s = ctl['LuaScript']
mods = [__import__(m) for m in sys.argv[4:]]
for mod in mods: s = mod.patch(s, replace, HERE)
for mod in mods:
    if hasattr(mod, 'patch_save'): mod.patch_save(save, replace)
ctl['LuaScript'] = s; save['SaveName'] = name
(HERE / 'latest.lua').write_text(s, encoding='utf-8')
Path(dest).write_text(json.dumps(save, ensure_ascii=False, indent=2), encoding='utf-8')
print('wrote', dest)
