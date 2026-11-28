import re,sys
L=open('../final/b9a001_226.lua').read().split('\n')
for i in sys.argv[2:]:
    print('#####',i)
    for n,l in enumerate(L):
        if re.search(r'(FX[\.\[]"?'+i+r'"?\]?\s*=|register\("'+i+r'"|activation\("'+i+r'"|FX\.'+i+r'\.|discardActivation\("'+i+r'"|\b'+i+r'\b.*= *function|id ?== ?"'+i+'")',l) and 'id="'+i+'"' not in l:
            print('\n'.join(f'{n+1+j}: {L[n+j][:200]}' for j in range(int(sys.argv[1]))))
