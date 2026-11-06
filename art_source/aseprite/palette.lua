-- Named colours shared by the unit and building kits. Team colour is drawn with the TEAM_* placeholder ramp and
-- swapped per team at export (t0 = blue, t1 = red, same as FactionArtManager.TEAM_COLORS).
local P = dofile(GEN_ROOT .. "/px.lua")
local C = {}
local function add(name, hex) C[name] = P.hex(hex) end

add("outline", "#1c1626")
-- team placeholder ramp, 5 tones (never appears in exported PNGs; swapped per team at export)
add("TEAM_H", "#ffb0ff"); add("TEAM_L", "#ff60ff"); add("TEAM", "#d020d0"); add("TEAM_D", "#801080"); add("TEAM_DD", "#500850")
C.TEAMS = {
  [0] = { H = P.hex("#b4dcff"), L = P.hex("#6fb0ff"), M = P.hex("#2e85f2"), D = P.hex("#1b4f9e"), DD = P.hex("#132f63") },
  [1] = { H = P.hex("#ffc0b4"), L = P.hex("#ff7a6e"), M = P.hex("#eb3838"), D = P.hex("#93202a"), DD = P.hex("#5a1420") },
}
-- placeholder -> team colour, for P.recolor at export
function C.team_map(team)
  local t = C.TEAMS[team]
  return { [C.TEAM_H] = t.H, [C.TEAM_L] = t.L, [C.TEAM] = t.M, [C.TEAM_D] = t.D, [C.TEAM_DD] = t.DD }
end
-- canvas force map: every team tone lands on the "team" layer
function C.team_force(extra)
  local f = { [C.TEAM_H] = "team", [C.TEAM_L] = "team", [C.TEAM] = "team", [C.TEAM_D] = "team", [C.TEAM_DD] = "team" }
  for k, v in pairs(extra or {}) do f[k] = v end
  return f
end

-- skin & hair
add("skin", "#e8b48a"); add("skin_tan", "#c98c5e"); add("skin_dark", "#9c6644")
add("hair_brown", "#5a3a22"); add("hair_black", "#2a2028"); add("hair_blond", "#c99a4a"); add("hair_red", "#8a3a1c")
add("hair_grey", "#8c8a8a")
-- cloth
add("cream", "#e9dcbc"); add("linen", "#cdbf9a"); add("white", "#eeeae0"); add("grey_cloth", "#8a8a8e")
add("black_cloth", "#2e2a33"); add("brown", "#7a5233"); add("brown_dark", "#4e3220"); add("leather", "#8e5f36")
add("red", "#b8323a"); add("red_dark", "#7c1f2b"); add("purple", "#6d2f86"); add("royal", "#2d4fa8")
add("navy", "#22305e"); add("blue", "#3f74c8"); add("sky", "#8cc0e6"); add("green", "#2f7a3f")
add("green_dark", "#1f4f2c"); add("olive", "#6b7a3a"); add("yellow", "#e8c64a"); add("orange", "#d27a2c")
add("teal", "#2f8a86"); add("sand", "#d9c08a"); add("fur", "#b59a74"); add("fur_dark", "#6e5a44")
add("straw", "#d6b45e"); add("straw_dark", "#9c7c34")
-- metal
add("steel", "#b8c0cc"); add("iron", "#7c8594"); add("iron_dark", "#4b5260"); add("gold", "#e3b341")
add("gold_dark", "#a2752a"); add("bronze", "#b07a3a"); add("lacquer_red", "#a3262c"); add("lacquer_black", "#2b2630")
-- wood
add("wood", "#9a6a3e"); add("wood_dark", "#5f3d22"); add("wood_light", "#c2915c")
-- building materials
add("stone", "#b9b2a4"); add("stone_dark", "#8a8478"); add("stone_light", "#d8d2c4"); add("stone_grey", "#9c9ea4")
add("plaster", "#e6dcc6"); add("adobe", "#d4b07c"); add("brick", "#a8553c")
add("slate_blue", "#4a5f8c"); add("slate_dark", "#353f5c"); add("tile_red", "#b8503a"); add("thatch", "#c9a456")
add("roof_green", "#3f8a78"); add("roof_black", "#3a3a48"); add("shingle", "#7a5434"); add("felt", "#e2d6b8")
add("dirt", "#9c7a52"); add("dirt_dark", "#7a5c3c"); add("grass", "#6e9a44"); add("water", "#4a86b8")
add("window", "#2a2230"); add("glow", "#f0c060"); add("lead", "#7e8a99")
-- mounts
add("horse_bay", "#7a4a2a"); add("horse_dark", "#3c2a24"); add("horse_grey", "#b4aca0"); add("horse_white", "#e4dfd4")
add("horse_chestnut", "#9a5a2e"); add("horse_dun", "#b8925e"); add("camel", "#c9a36a"); add("mane_dark", "#2a1e1a")

return C
