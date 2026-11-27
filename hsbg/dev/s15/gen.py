import json, sys
sys.path.insert(0, '/home/claude/s15')
from data import NEW, DONE
R = json.load(open('/home/claude/s15/resolved.json'))
def lua_str(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
defs = []
for key, name, tier, atk, hp, races, text, flags in NEW:
    i = "S15_" + key
    f = ",".join("%s=%s" % (k, ("true" if v is True else str(v))) for k, v in flags.items())
    defs.append('BG_CARDS["%s"] = {id="%s",name=%s,tier=%d,atk=%d,hp=%d,races={%s},all=false,text=%s,gtext=%s,pool=false,season=true,legend=false,gatk=%d,ghp=%d,gid="%s",fx="%s"%s}'
                % (i, i, lua_str(name), tier, atk, hp, ",".join(lua_str(r) for r in races), lua_str(text), lua_str(text), atk * 2, hp * 2, i,
                   "full" if key in DONE else "none", ("," + f) if f else ""))
pool = [x for x in R['pool14'] if x not in set(R['rem'])]
for x in R['ret']:
    if x not in pool: pool.append(x)
pool += ["S15_" + k for k, *_ in NEW]
stats = []
for i, (t, a, h) in R['stats'].items():
    stats.append('["%s"]={%s,%s,%s,%s,%s}' % (i, t if t is not None else 'BG_CARDS["%s"].tier' % i, a if a is not None else 'BG_CARDS["%s"].atk' % i,
                 h if h is not None else 'BG_CARDS["%s"].hp' % i, (a * 2) if a is not None else 'BG_CARDS["%s"].gatk' % i, (h * 2) if h is not None else 'BG_CARDS["%s"].ghp' % i))
open('/home/claude/s15/defs.lua', 'w').write("\n".join(defs) + "\n")
open('/home/claude/s15/season.lua', 'w').write('  {key="s15",season=15,patch="37.2",title="Warped Empire",build=0,pool={%s}},\n' % ",".join('"%s"' % x for x in pool))
open('/home/claude/s15/stats.lua', 'w').write("E.seasonStats.s15 = {%s}\n" % ",".join(stats))
print(len(defs), len(pool), len(stats))
