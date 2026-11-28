-- The v4.2 strict checks must fire: each case below has to add one CUSTOM_FAILS entry.
local function tok(url, extra)
    local d = {Name = "Custom_Token", Nickname = "neg", Transform = {posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1},
        CustomImage = {ImageURL = url, ImageSecondaryURL = "", ImageScalar = 1, WidthScale = 0,
            CustomToken = {Thickness = 0.1, MergeDistancePixels = 15, StandUp = false, Stackable = false}}}
    if extra then extra(d) end
    return d
end
local good = TOKEN_BASE .. "f/BG20_100.png"
local n0 = #CUSTOM_FAILS
spawnObjectData({data = tok(good), position = {50, 2, 50}})
print("good token fails: " .. (#CUSTOM_FAILS - n0))
local cases = {
    {"no CustomToken", function() spawnObjectData({data = tok(good, function(d) d.CustomImage.CustomToken = nil end), position = {60, 2, 60}}) end},
    {"no image", function() spawnObjectData({data = tok("", nil), position = {61, 2, 61}}) end},
    {"file url", function() spawnObjectData({data = tok("file:///C:/x.png"), position = {62, 2, 62}}) end},
    {"v4.1 palette face", function() spawnObjectData({data = tok("https://raw.githubusercontent.com/Jnipko488/mtg-table-data/c2ce202dbc9e92b13c8529e88556ebb3e278b96d/hsbg/f/BG20_100.png"), position = {63, 2, 63}}) end},
    {"decal art as token", function() spawnObjectData({data = tok(TOKEN_BASE .. "ui/btn_refresh.png"), position = {64, 2, 64}}) end},
    {"tile without CustomTile", function() spawnObjectData({data = {Name = "Custom_Tile", CustomImage = {ImageURL = good}}, position = {65, 2, 65}}) end},
    {"overlapping spawn", function() spawnObjectData({data = tok(good), position = {50.1, 2, 50.1}}) end},
    {"overlapping decals", function()
        local b = makeObject({type = "Custom_Model", pos = {80, 1, 80}})
        b.proxy.setDecals({{name = "hsbg_a", url = good, position = {0, 0.2, 0}, rotation = {90, 0, 0}, scale = {2, 2, 1}},
                           {name = "hsbg_b", url = good, position = {1, 0.2, 0}, rotation = {90, 0, 0}, scale = {2, 2, 1}}})
    end},
}
local bad = 0
for _, c in ipairs(cases) do
    local before = #CUSTOM_FAILS
    c[2]()
    local fired = #CUSTOM_FAILS > before
    print((fired and "caught: " or "MISSED: ") .. c[1])
    if not fired then bad = bad + 1 end
end
ERRORS = {}
if bad > 0 then ERRORS[1] = bad .. " strict checks missed" end
print("== NEGATIVE MISSED: " .. bad)
