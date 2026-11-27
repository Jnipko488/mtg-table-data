import UnityPy, glob, json, os
UnityPy.config.FALLBACK_UNITY_VERSION = "6000.3.11f1"
want=['02a44e4b','179fe96d','7896b02e','80feb78a']
seen=json.load(open('/tmp/cabseen.json')) if os.path.exists('/tmp/cabseen.json') else {}
for f in sorted(glob.glob('/mnt/user-data/uploads/Hearthstone/Data/Win/*material*')):
    b=f.split('/')[-1]
    if b in seen: continue
    try:
        env=UnityPy.load(f); names=[]
        for x in env.files.values(): names+=list(x.files.keys()) if hasattr(x,'files') else []
        seen[b]=[n for n in names if not n.endswith('.resS')]
    except Exception: seen[b]=[]
json.dump(seen,open('/tmp/cabseen.json','w'))
for b,ns in seen.items():
    for n in ns:
        for w in want:
            if w in n.lower(): print('FOUND',w,b)
