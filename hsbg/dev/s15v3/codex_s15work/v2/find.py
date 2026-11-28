import re,sys
s=open('../final/b9a001_226.lua').read()
L=s.split('\n')
def ids_for(name):
    out=[]
    for m in re.finditer(r'\[?"?([A-Za-z0-9_]+)"?\]? *= *\{id="([A-Za-z0-9_]+)",name="'+re.escape(name)+'"',s):
        out.append(m.group(2))
    return sorted(set(out))
for name in sys.argv[1:]:
    ids=ids_for(name)
    print('#####',name,ids)
    for i in ids:
        for n,l in enumerate(L):
            if re.search(r'(FX[\.\[]"?'+i+r'"?\]?\s*=|register\("'+i+r'"|activation\("'+i+r'"|FX\.'+i+r'\.)',l) or ('"'+i+'"' in l and ('id="'+i+'"' in l)):
                print(n+1, l[:300])
