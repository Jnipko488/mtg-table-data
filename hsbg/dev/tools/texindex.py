import UnityPy, glob, pickle
UnityPy.config.FALLBACK_UNITY_VERSION = "6000.3.11f1"
idx={}
for f in sorted(glob.glob('/mnt/user-data/uploads/Hearthstone/Data/Win/*texture*')):
    try: env=UnityPy.load(f)
    except Exception: continue
    for o in env.objects:
        if o.type.name=='Texture2D':
            try: idx[o.path_id]=(f, o.peek_name())
            except Exception: pass
pickle.dump(idx, open('/tmp/texidx.pkl','wb')); print(len(idx))
