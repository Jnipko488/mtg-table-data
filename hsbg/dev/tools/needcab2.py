import UnityPy, sys
UnityPy.config.FALLBACK_UNITY_VERSION = "6000.3.11f1"
W='/mnt/user-data/uploads/Hearthstone/Data/Win/'
env=UnityPy.load(W+'initial_base_global-2ebe64b8-prefab-4.unity3d')
ext={}
for f in env.files.values():
    for sf in (f.files.values() if hasattr(f,'files') else []):
        if hasattr(sf,'externals'):
            for i,e in enumerate(sf.externals,1): ext[i]=e.path.split('/')[-1]
need=set()
def walk(g):
    for c in g.m_Component:
        ptr=c.component if hasattr(c,'component') else c
        try: ob=ptr.deref()
        except Exception: continue
        if ob.type.name=='ParticleSystemRenderer':
            tt=ob.read_typetree()
            for m in tt.get('m_Materials',[]):
                if m['m_FileID']: need.add((g.m_Name, ext.get(m['m_FileID'])))
        if ob.type.name=='Transform':
            for ch in ob.read().m_Children:
                try: walk(ch.read().m_GameObject.read())
                except Exception: pass
for o in env.objects:
    if o.type.name=='GameObject' and o.peek_name() in sys.argv[1:]: walk(o.read())
print(sorted(need))
