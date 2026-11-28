import json, sys, os
save = sys.argv[1]; out = sys.argv[2]
d = json.load(open(save))
lines = ["-- generated from " + os.path.basename(save)]
os.makedirs("scripts", exist_ok=True)
scripted = []
for o in d["ObjectStates"]:
    g = o.get("GUID"); t = o["Transform"]
    script = o.get("LuaScript") or ""
    if g not in ("f06d01", "b9a001") and not (o.get("Nickname") == "Highlight Mat"): continue
    size = "{2,0.2,1.4}" if o.get("Nickname") == "Highlight Mat" else "{6,0.4,6}"
    lines.append('local o = makeObject({guid=%r, type=%r, nickname=%r, pos={%r,%r,%r}, rot={%r,%r,%r}, scale={%r,%r,%r}, locked=%s, size=%s, tags={%s}})' % (
        g, o["Name"], o.get("Nickname",""), t["posX"], t["posY"], t["posZ"], t["rotX"], t["rotY"], t["rotZ"], t["scaleX"], t["scaleY"], t["scaleZ"],
        "true" if o.get("Locked") else "false", size, ",".join(repr(x) for x in o.get("Tags") or [])))
    if g in ("f06d01", "b9a001") and script:
        open(f"scripts/{g}.lua", "w").write(script)
        lines.append(f'attachScript(o, __readfile("scripts/{g}.lua"))')
        scripted.append((g, o.get("LuaScriptState") or ""))
import re as _re
ids = sorted(set(_re.findall(r'\bid="([^"]+)"', d.get("XmlUI") or "")))
lines.append("UI_IDS = {" + ",".join("[%s]=true" % json.dumps(i) for i in ids) + "}")
lines.append("SCRIPTED = {" + ",".join("{guid=%r, state=%s}" % (g, json.dumps(s)) for g, s in scripted) + "}")
lines.append("for _, s in ipairs(SCRIPTED) do local o = OBJECTS[s.guid]; if o.env.onLoad then protected(s.guid .. '.onLoad', o.env.onLoad, s.state) end end")
open(out, "w").write("\n".join(lines).replace("'", "'").replace("True","true") + "\n")
