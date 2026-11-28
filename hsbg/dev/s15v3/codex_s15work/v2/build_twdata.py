import json, re
L = open('blizz.txt').read().split('\n')
tm = json.load(open('tw/thumbmap.json'))
TRIBES = {
 'Amalgam of the Deep':'ALL','Assistant':'DEMON','Avalanche Caller':'ELEMENTAL','Breakout':'PIRATE','Clan Trainer':'',
 'Contortionist':'MURLOC','Cub':'BEAST','Cutlassier':'PIRATE','Duke':'ABERRATION','Fruit Vendor':'BEAST','Graverobber':'',
 'Holmes':'MURLOC','Morchie':'','Muscle-o-Tron':'MECHANICAL','Mycologist':'MURLOC','Necromancer':'ABERRATION',
 'Outpourer':'ELEMENTAL','Picky Eater':'DEMON','Prophet of the Boar':'QUILBOAR','Recyclebot':'MECHANICAL','Reflector':'',
 'Reverber Drake':'DRAGON','Rot':'ABERRATION','Rylak':'BEAST','Scrapsmith':'QUILBOAR','Soldier':'ABERRATION','Sr. Scout':'',
 'Traverser':'DRAGON','Tumor':'ABERRATION','Willbreaker':'ABERRATION','Amalgadon':'ALL','Ball of Minions':'ALL',
 'Bronze Gatekeeper':'MECHANICAL','Bubblebot':'MECHANICAL','Cage Gnawer':'BEAST','Clunker':'MECHANICAL','Concierge':'PIRATE',
 'Converter':'ABERRATION','Deliverer':'PIRATE','Endurer':'QUILBOAR','Engineer':'DRAGON',"Eye of Go'rath":'ABERRATION',
 'Flat Tusk':'QUILBOAR','Future Fighter':'DRAGON','Gem Smuggler':'QUILBOAR','Hardlight':'MECHANICAL','Huhuran':'UNDEAD',
 "K'Thir":'ABERRATION','Looter':'PIRATE','Mecherel':'MECHANICAL','Mirror Mage':'','Mosher':'DEMON','Mount':'DRAGON',
 'Murozond':'DRAGON','Nether Construct':'ELEMENTAL','Nightmare':'UNDEAD','Phalanx':'ALL','Replicator':'ABERRATION',
 'Sabercat':'BEAST','Sanctifier':'MECHANICAL','Sergeant':'UNDEAD','Slinger':'MURLOC',"Spawn of N'Zoth":'ABERRATION',
 'Sweet Tooth':'ABERRATION','Terrorguard':'DEMON','Thunder Knight':'ELEMENTAL','Tickatus':'DEMON','Tour Group':'ALL',
 'Voidpriest':'ABERRATION','Wallow':''}
KW = {'Divine Shield':'shield','Taunt':'taunt','Windfury':'windfury','Venomous':'venom','Reborn':'reborn','Resilient':'resilient','Magnetic':'magnetic'}
def slug(n): return re.sub(r'[^a-z0-9]+','_',n.lower().replace("'","").replace('.','')).strip('_')
def section(start, end, pool):
    a = L.index(start); b = L.index(end, a)
    out = []
    i = a+1
    while i < b:
        name = L[i]
        if name and not name.startswith('\t'):
            desc = L[i+1].strip()
            m = re.match(r'\[(\d) Cost\]\s*(?:(\d+)/(\d+)\.?)?\s*(.*)', desc)
            cost, atk, hp, text = int(m.group(1)), m.group(2), m.group(3), m.group(4).strip()
            short = name.replace('Timewarped ','')
            if name.startswith('Power of'):
                kind = 'power'; cid = 'S15_tw_power_'+slug(name[9:])
            elif atk is None:
                kind = 'spell'; cid = 'S15_tw_'+slug(short)
            else:
                kind = 'minion'; cid = 'S15_tw_'+slug(short)
            c = dict(id=cid, name=name, pool=pool, cost=cost, kind=kind, text=text, files=tm[name])
            if kind == 'minion':
                c['atk'], c['hp'] = int(atk), int(hp)
                t = TRIBES[short]
                c['tribes'] = [] if t in ('', 'ALL') else [t]
                c['all'] = t == 'ALL'
                kws = {}
                first = re.split(r'(?<=\.)\s', text)[0]
                for k, v in KW.items():
                    if re.search(r'(^|[\s,.])'+k+r'([\s,.]|$)', text) and not re.search(k+r' (prevents|until|and)|gain '+k+'|give it '+k+'|give .* '+k+'|'+k+r' to|lose|loses', text):
                        kws[v] = True
                c['kw'] = kws
            out.append(c)
            i += 2
        else:
            i += 1
    return out
data = section('New to Minor Timewarp', 'Returning to Minor Timewarp', 3) + section('New to Major Timewarp', 'Returning to Major Timewarp', 5)
print(len(data), sum(1 for c in data if c['kind']=='minion'), sum(1 for c in data if c['kind']=='spell'), sum(1 for c in data if c['kind']=='power'))
for c in data:
    if c['kind']=='minion': print(c['id'], c['atk'], c['hp'], c['tribes'], c['all'], c['kw'])
json.dump(data, open('v2/twdata.json','w'), indent=1)
