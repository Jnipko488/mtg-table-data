import json, re, collections, sys
api=json.load(open('api_cards.json'))
inv=json.load(open(sys.argv[1] if len(sys.argv)>1 else '/tmp/unf/HSBG_Season15_Unfinished/s15work/v3/inv.json'))
def norm(s): return re.sub(r'[^a-z0-9]','',(s or '').lower())
def ntext(s):
    s=re.sub(r'<[^>]+>','',s or ''); s=s.replace('’',"'").replace('’',"'")
    s=re.sub(r'\[x\]','',s); s=re.sub(r'\s+',' ',s).strip().lower()
    s=re.sub(r'[^a-z0-9+/()!\' ]','',s)
    return re.sub(r'\s+',' ',s).strip()
A={}
for r in api:
    if r['duos']: continue
    A.setdefault(norm(r['name']),[]).append(r)
rep=collections.defaultdict(list)
seen=set()
for i in inv:
    k=i['kind']
    if k=='token': continue
    rs=A.get(norm(i['name']))
    if not rs: rep['NOAPI '+k].append(i['id']+' '+i['name']); continue
    r=rs[0]; seen.add(r['dbf'])
    issues=[]
    if i.get('minion'):
        if str(i['tier'])!=str(r['tier']): issues.append('tier %s->%s'%(i['tier'],r['tier']))
        if str(i['atk'])!=str(r['atk']) or str(i['hp'])!=str(r['hp']): issues.append('stats %s/%s->%s/%s'%(i['atk'],i['hp'],r['atk'],r['hp']))
        if r['gdbf'] and (str(i.get('gatk'))!=str(r['gatk']) or str(i.get('ghp'))!=str(r['ghp'])): issues.append('gstats %s/%s->%s/%s'%(i.get('gatk'),i.get('ghp'),r['gatk'],r['ghp']))
    mt,at=ntext(i['text']),ntext(r['text'])
    # API strips numbers inside templated text: compare with digits removed when api has gaps
    def loose(s): return re.sub(r'[0-9]+','#',s).replace('# ','#').replace(' #','#')
    def gapfree(s): return re.sub(r'\s+','',re.sub(r'[0-9]','',s))
    if mt!=at:
        if gapfree(mt)!=gapfree(at): issues.append('TEXT\n      mod: %s\n      api: %s'%(i['text'],r['text']))
        else: issues.append('textnum\n      mod: %s\n      api: %s'%(i['text'],r['text']))
    if r['gdbf'] and r['gtext']:
        mg=ntext(i.get('gtext') or ''); ag=ntext(r['gtext'])
        if mg!=ag:
            if not mg: issues.append('NOGTEXT api: %s'%r['gtext'])
            elif gapfree(mg)!=gapfree(ag): issues.append('GTEXT\n      mod: %s\n      api: %s'%(i.get('gtext'),r['gtext']))
            else: issues.append('gtextnum\n      mod: %s\n      api: %s'%(i.get('gtext'),r['gtext']))
    for x in issues: rep[x.split()[0]+' '+k].append('%s %s: %s'%(i['id'],i['name'],x))
for k in sorted(rep):
    print('=====',k,len(rep[k]))
    if '-q' not in sys.argv:
        for x in rep[k]: print('  ',x)
# API cards not in inv
invn={norm(i['name']) for i in inv}
miss=[r for r in api if not r['duos'] and norm(r['name']) not in invn and r['type'] in (4,42,999)]
print('===== API not in mod', len(miss)); 
for r in miss: print('   ',r['type'],r['name'],r['tier'],r['text'][:80])
