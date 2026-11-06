-- Entry point, run through the Aseprite MCP run_lua tool (`_G.GEN_ARGS = {...}; dofile(".../run.lua")`) or the
-- command line (cli.lua). args: root = repo root, civs / units / buildings = filters (default: all),
-- kinds = units, buildings, environment, fields, upgrade_kits, ui (default: all, in that order; ui reads the
-- unit and building sheets written by the first two).
local args = GEN_ARGS or args
local root = args.root
GEN_ROOT = root .. "/art_source/aseprite"
local CIVS = dofile(GEN_ROOT .. "/civs.lua")

local godot = root .. "/sample_project"
local out = "assets/sprites_px"
local game_dir = godot .. "/" .. out
local ui_only_dir = root .. "/build/ui_only"          -- gallery-only buildings (market, stone wall)
local function set(list) if not list then return nil end local s = {} for _, v in ipairs(list) do s[v] = true end return s end
local want_civ, want_unit, want_bld = set(args.civs), set(args.units), set(args.buildings)
local kinds = set(args.kinds or { "units", "buildings", "environment", "fields", "upgrade_kits", "ui" })
local done = {}

local civ_ids = {}
for k, v in pairs(CIVS) do if type(v) == "table" then civ_ids[#civ_ids + 1] = k end end
table.sort(civ_ids)
local function civs()
  local i = 0
  return function()
    repeat i = i + 1 until civ_ids[i] == nil or not want_civ or want_civ[civ_ids[i]]
    return civ_ids[i]
  end
end
local function roles(civ)
  local r = {}
  for role in pairs(CIVS[civ]) do if not role:match("^_") and (not want_unit or want_unit[role]) then r[#r + 1] = role end end
  table.sort(r)
  return r
end

-- ages: which age looks to build (default 1,2,3; 2 = base files without a suffix, see ages.lua)
local ages = {}
for _, a in ipairs(args.ages or { 1, 2, 3 }) do ages[#ages + 1] = tonumber(a) end
local AG = dofile(GEN_ROOT .. "/ages.lua")
local PH = dofile(GEN_ROOT .. "/physique.lua")
local function sfx(age) return (age == 2) and "" or ("@a" .. age) end
local function nm(id, age) return (age == 2) and id or (id .. "_a" .. age) end

if kinds.units then
  local U = dofile(GEN_ROOT .. "/units.lua")
  for civ in civs() do
    for _, role in ipairs(roles(civ)) do
      for _, age in ipairs(ages) do
        if age == 2 or not CIVS[civ][role].villager then
          U.build(PH.apply(AG.unit(CIVS[civ][role], age, civ, role), civ, role), civ, role, {
            name = nm(role, age),
            aseprite = string.format("%s/art_source/aseprite/src/units/%s/%s.aseprite", root, civ, nm(role, age)),
            png_dir = string.format("%s/units/%s", game_dir, civ),
            res_dir = string.format("res://%s/units/%s", out, civ),
            meta = string.format("%s/build/px_meta/units/%s/%s%s.json", root, civ, role, sfx(age)) })
          done[#done + 1] = "units/" .. civ .. "/" .. nm(role, age)
        end
      end
    end
  end
end
if kinds.buildings then
  local B = dofile(GEN_ROOT .. "/buildings.lua")
  for civ in civs() do
    local all = {}
    for bid in pairs(B.TYPES) do all[bid] = true end
    for bid in pairs(B.UI_ONLY) do all[bid] = true end
    for bid in pairs(all) do
      if not want_bld or want_bld[bid] then
        local base = B.UI_ONLY[bid] and ui_only_dir or game_dir
        for _, age in ipairs(ages) do
          -- UI-only gallery pieces keep one look; the castle needs Age II, so it has no Age I look
          if age == 2 or not (B.UI_ONLY[bid] or (age == 1 and bid == "castle")) then
            B.build(civ, bid, {
              aseprite = string.format("%s/art_source/aseprite/src/buildings/%s/%s.aseprite", root, civ, nm(bid, age)),
              png_dir = string.format("%s/buildings/%s", base, civ),
              res_dir = string.format("res://%s/buildings/%s", out, civ),
              meta = string.format("%s/build/px_meta/buildings/%s/%s%s.json", root, civ, bid, sfx(age)) }, age)
            done[#done + 1] = "buildings/" .. civ .. "/" .. nm(bid, age)
          end
        end
      end
    end
  end
end
local env_kinds
for _, k in ipairs({ "environment", "fields", "upgrade_kits" }) do
  if kinds[k] then env_kinds = env_kinds or {}; env_kinds[k] = true end
end
if env_kinds then
  local E = dofile(GEN_ROOT .. "/env.lua")
  for _, d in ipairs(E.build_all(root, out, env_kinds, want_civ)) do done[#done + 1] = d end
end
-- UI portraits, building icons and gallery posters, made from the sheets above
if kinds.ui then
  local UI = dofile(GEN_ROOT .. "/ui.lua")
  local B = dofile(GEN_ROOT .. "/buildings.lua")
  for civ in civs() do
    local rs = {}
    for role in pairs(CIVS[civ]) do if not role:match("^_") then rs[#rs + 1] = role end end
    table.sort(rs, function(a, b) return (a == "villager" and "0" or a) < (b == "villager" and "0" or b) end)
    local frames = {}
    for _, role in ipairs(rs) do frames[#frames + 1] = UI.unit(godot, game_dir, civ, role) end
    local blds = {}
    for bid in pairs(B.TYPES) do blds[bid] = UI.building(godot, game_dir, civ, bid) end
    for bid in pairs(B.UI_ONLY) do blds[bid] = UI.building(godot, ui_only_dir, civ, bid) end
    UI.poster(godot, civ, frames, blds)
    done[#done + 1] = "ui/" .. civ
  end
end
return { built = done }
