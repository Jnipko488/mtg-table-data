import sys
exec(open('test_quest_ui.py').read().split("urls = lua.execute")[0].replace("ART = sys.argv[2]","ART=''"))
r = lua.execute(r'''
local E = env.BG
local out = {}
for hi, h in ipairs(env.BG_HEROES or E.HEROES) do
  local x = hi * 7919
  local g = E.new({season = "s14", pool = env.BG_SEASONS[1].pool, trinkets = true, buddies = true, timewarp = true, quests = false, allTribes = true,
     rand = function(n) x = (x * 1103515245 + 12345) % 2147483648; return (x % n) + 1 end})
  local a = E.addPlayer(g, "White", "Host", false)
  local b = E.addPlayer(g, "Red", "Bot", true)
  local info = {ok = 0, fail = {}, err = nil}
  local okRun, err = pcall(function()
    assert(E.startGame(g))
    E.chooseHero(g, "Red", 1)
    a.heroOptions = a.heroOptions or {}
    a.heroOptions[1] = h.id
    local okc, cerr = E.chooseHero(g, "White", 1)
    if not okc then info.err = "choose: " .. tostring(cerr) end
    for t = 1, 11 do
      if g.phase == "over" then break end
      E.beginRecruit(g)
      local function clear()
        for _ = 1, 6 do
          if not E.hasChoice(a) then break end
          if a.discover then E.discoverPick(g, "White", 1)
          elseif a.offer then E.offerPick(g, "White", 1)
          elseif a.questOffer then E.questPick(g, "White", 1)
          else local ok3 = pcall(E.pickSpellChoice, g, a, 1); if not ok3 then break end end
        end
      end
      clear()
      a.gold = 10
      if #a.board == 0 then E.buy(g, "White", 1); if a.hand[1] then E.play(g, "White", 1) end end
      local targets = {false, {zone = "board", index = 1}, {zone = "tavern", index = 1}, 1}
      for ti = 1, 4 do local tg = targets[ti] or nil
        local ok2, done, msg = pcall(E.heroPower, g, "White", tg)
        if not ok2 then info.err = info.err or ("power: " .. tostring(done)) break end
        if done then info.ok = info.ok + 1; clear(); break else info.fail[tostring(msg)] = true end
      end
      clear()
      E.buy(g, "White", 1); if a.hand[1] then pcall(E.play, g, "White", 1) end
      clear()
      E.endRecruit(g, {fast = true}); E.applyCombat(g)
    end
  end)
  if not okRun then info.err = tostring(err) end
  local fails = {}
  for k in pairs(info.fail) do fails[#fails + 1] = k end
  local hp = E.HP[h.id]
  out[#out + 1] = string.format("%s|%s|%s|uses=%d|%s|%s", h.id, h.name, hp.active and "A" or "P", info.ok, info.err or "", table.concat(fails, " / "):sub(1, 160))
end
return table.concat(out, "\n")
''')
print(r)
