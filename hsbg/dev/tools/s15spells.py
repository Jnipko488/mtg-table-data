import sys
exec(open('test_quest_ui.py').read().split("urls = lua.execute")[0].replace("ART = sys.argv[2]","ART=''"))
r = lua.execute(r'''
local E = env.BG
local out = {}
local function log(...) local t={} for i=1,select('#',...) do t[#t+1]=tostring(select(i,...)) end out[#out+1]=table.concat(t," ") end
local s15; for _, ss in ipairs(env.BG_SEASONS) do if ss.key == "s15" then s15 = ss end end
E.activateSeason("s15")
local x=7
local g = E.new({season = "s15", pool = s15.pool, fullMinions = false, trinkets = false, buddies = false, timewarp = true, quests = false, allTribes = true,
   rand = function(n) x = (x * 1103515245 + 12345) % 2147483648; return (x % n) + 1 end})
local a = E.addPlayer(g, "White", "Host", false)
local b = E.addPlayer(g, "Red", "Bot", true)
assert(E.startGame(g)); E.chooseHero(g,"Red",1); E.chooseHero(g,"White",1)
E.beginRecruit(g)
for _=1,6 do if a.discover then E.discoverPick(g,"White",1) elseif a.offer then E.offerPick(g,"White",1) else break end end
local function put(id) local m=E.newMinion(g,id); table.insert(a.board,m); return m end
local function cast(id, idx)
  a.spellHand = {}; E.giveSpell(g,a,id)
  local ok,err = E.castTavernSpell(g,"White",1, idx and {zone="board",index=idx} or nil)
  return ok,err
end
a.board={}
local el=put("S15_tsunami_surfer")
for _,id in ipairs({"S15S_invocation_earth","S15S_invocation_fire","S15S_invocation_air","S15S_invocation_water"}) do
  local ok,err=cast(id,1); log(id,ok,err,el.atk.."/"..el.hp,"taunt",el.taunt,"reborn",el.reborn,"wf",el.windfury,"ds",el.shield)
end
local beast=put("S15_great_wolf_cub")
local b0=beast.atk; local ok,err=cast("S15S_goldrinns_blessing"); E.applyUndead(a); log("goldrinn",ok,err,b0,"->",beast.atk, a.beastA)
local ok,err=cast("S15S_command_elements"); local n=0; for _,s in ipairs(a.spellHand) do n=n+1 end; log("command",ok,err,"hand",n, a.spellHand[1] and a.spellHand[1].id)
a.board={}
local d=put("S15_timeless_mount"); local ok,err=cast("S15S_dragonstorm"); log("dragonstorm",ok,err,"attach",d.attachments and #d.attachments)
local ok,err=cast("S15S_echoing_roar",1); log("echo",ok,err,"attach",#d.attachments)
local d0=d.atk; E.dispatchAttached(d,"endTurn",function(f,k) f(g,a,d,k) end); log("endturn attached",d0,"->",d.atk)
local t0=d.atk; local ok,err=cast("S15S_tumultuous_growth",1); log("tumult",ok,err,t0,"->",d.atk)
local s=put("S15_surging_sanctifier"); s.shield=true; local s0=s.atk
local ok,err=cast("S15S_sanctify"); log("sanctify",ok,err,s0,"->",s.atk)
-- minion hooks
local FX=E.FX
for _,id in ipairs({"S15_great_wolf_cub","S15_effusive_dancer","S15_dauntless_adventurer","S15_tsunami_surfer","S15_twilight_traverser","S15_thunder_knight","S15_scaled_sovereign","S15_faceless_necromancer","S15_land_upheaver","S15_great_direwolf","S15_timeless_mount","S15_surging_sanctifier"}) do
  local f=FX and FX[id]; local keys={} if f then for k in pairs(f) do keys[#keys+1]=k end end; table.sort(keys)
  log(id, f and table.concat(keys,",") or "NO FX", "act", E.activation(g,{id=id}) )
end
a.board={}; a.spellHand={}
local q=put("S15_scaled_sovereign"); a.gold=10
local ok,err=E.activateMinion(g,"White",1); log("sovereign act",ok,err,"gold",a.gold, q.attachments and #q.attachments)
local ok,err=E.activateMinion(g,"White",1); log("sovereign again",ok,err)
-- play a dragon to refresh
a.hand={E.newMinion(g,"S15_timeless_mount")}; local okp,perr=E.play(g,"White",1); log("play dragon",okp,perr,"refresh",q.activatedTurn)
-- thunder knight sell
a.board={put and E.newMinion(g,"S15_thunder_knight")}; a.spellHand={}
local oks,serr=E.sell(g,"White",1); log("sell TK",oks,serr,a.spellHand[1] and a.spellHand[1].id)
-- tavern spell rotation
local rot=E.seasonSpells.s15; local n=0; for k in pairs(rot) do n=n+1 end; log("rotation",n, rot.S15S_dragonstorm, rot.BG36_246, rot.S15S_invocation_fire)
return table.concat(out,"\n")
''')
print(r)
