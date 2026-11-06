-- Command-line wrapper: aseprite -b --script-param root=<repo> [--script-param civs=franks,teutons]
--   [--script-param kinds=units,buildings] --script art_source/aseprite/cli.lua
local function list(s) if not s or s == "" then return nil end local t = {} for v in s:gmatch("[^,]+") do t[#t + 1] = v end return t end
local p = app.params
_G.GEN_ARGS = { root = p.root, civs = list(p.civs), units = list(p.units), buildings = list(p.buildings), kinds = list(p.kinds), ages = list(p.ages) }
local r = dofile(p.root .. "/art_source/aseprite/run.lua")
print(string.format("built %d sprites", #r.built))
