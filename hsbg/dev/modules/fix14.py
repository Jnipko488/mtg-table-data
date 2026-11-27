"""Galewing flightpaths and Cariel Stances show as real Hearthstone hero-power choice cards (HS portraits, Belwe name,
live description on the parchment in the HS font)."""
HP19 = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/c969a94d7d110f50d839e408133f168dd4dac075/hsbg/battlegrounds-multiplayer/s14-leaderboard/hpcard/"
def patch(s, replace, HERE):
    s = replace(s, '["United Stance"] = "\'Conviction\' affects an extra minion this game."}',
                   '["United Stance"] = "\'Conviction\' gives stats to an extra friendly minion this game."}')
    s = replace(s, '        elseif o.kind=="hero_option" and (Draw.OPTION_CARDS[o.text] or game.players[o.text]) then\n',
'''        elseif o.kind=="hero_option" and Draw.OPTION_HP[o.text] then
            local W = CH * 500 / 650
            ensureTile(color,"pick"..i,{url="@HP19@"..Draw.OPTION_HP[o.text]..".png",face={r=500/650},size=CH,right=right,near=CN,
                lift=lift,layer=8,click=true,action="pick",kind="hero_option",index=o.index})
            Draw.hsText(color,"b_pkhp"..i,o.description or "",nil,right+(256/500-.5)*W,CN+(467/650-.5)*CH,270/500*W,108/650*CH,9,lift+.03,{panel=false})
        elseif o.kind=="hero_option" and (Draw.OPTION_CARDS[o.text] or game.players[o.text]) then
'''.replace("@HP19@", HP19))
    s = replace(s, 'Draw.OPTION_CARDS = {Westfall = "BG20_HERO_283p_t1",',
                   'Draw.OPTION_HP = {Westfall = "BG20_HERO_283p_t1", Ironforge = "BG20_HERO_283p_t2", ["Eastern Plaguelands"] = "BG20_HERO_283p_t3",\n'
                   '    ["Offensive Stance"] = "BG21_HERO_000_Buddyt", ["Defensive Stance"] = "BG21_HERO_000_Buddyt2", ["United Stance"] = "BG21_HERO_000p_t1"}\n'
                   'Draw.OPTION_CARDS = {Westfall = "BG20_HERO_283p_t1",')
    return s
