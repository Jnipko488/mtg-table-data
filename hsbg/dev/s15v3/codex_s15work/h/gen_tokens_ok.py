"""TOKEN_OK for world.lua: hosted images that pass pack_cloud_assets.check_png as token images.
    python3 gen_tokens_ok.py <project> <packed hsbg folder> tokens_ok.lua"""
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1] + "/Tools")
import pack_cloud_assets as pk
cloud = Path(sys.argv[2])
base = json.load(open(sys.argv[1] + "/Tools/cloud_assets.json"))["base"]
ok = []
for p in sorted(cloud.rglob("*.png")):
    rel = p.relative_to(cloud).as_posix()
    if pk.is_token(rel):
        try:
            pk.check_png(p, True); ok.append(rel)
        except ValueError as e:
            print("NOT OK", e, file=sys.stderr)
lines = ["TOKEN_BASE = %s" % json.dumps(base), "TOKEN_OK = {"] + ['[%s] = true,' % json.dumps(r) for r in ok] + ["}"]
open(sys.argv[3], "w").write("\n".join(lines) + "\n")
print(len(ok), "token images verified")
