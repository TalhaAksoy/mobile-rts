-- Environment props (trees, bushes, mines per biome), farm fields and the civ "upgrade kits" at 32 px/m in the same
-- 3/4 oblique view as the buildings. Fields and kit walls use the ground scale (32 px/m in depth) so they line up
-- with their footprint seen from above.
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local A = dofile(GEN_ROOT .. "/arch.lua")
local Pr = dofile(GEN_ROOT .. "/props.lua")
local BL = dofile(GEN_ROOT .. "/buildings.lua")
local CIVS = dofile(GEN_ROOT .. "/civs.lua")
local E = {}
E.PX_PER_M = 32
local col, tone = A.col, A.tone
local function hx(h) return P.hex(h) end
local function N(x, y, s) return P.noise(x, y, s or 7) end
local function put(K, x, y, c) if c then P.put(K, math.floor(x), math.floor(y), c) end end
local SHADOW = P.hex("#221c2a")

local function shadow(K, cx, cy, rx, ry)
  P.use(K, "shadow")
  for y = -ry, ry do for x = -rx, rx do
    if (x * x) / ((rx + 0.5) ^ 2) + (y * y) / ((ry + 0.5) ^ 2) <= 1 and (cx + x + cy + y) % 2 == 0 then put(K, cx + x, cy + y, SHADOW) end
  end end
  P.use(K, "structure")
end

-- foliage clump: lobed blob, lit from the upper left, leaf-cluster highlights, dark underside
local function clump(K, cx, cy, rx, ry, pal, seed)
  for y = -ry - 2, ry + 2 do for x = -rx - 2, rx + 2 do
    local a = math.atan(y, x)
    local edge = 1 + 0.12 * math.sin(a * 6 + seed) + (N(cx + x, cy + y, seed) - 0.5) * 0.16
    local v = (x * x) / (rx * rx) + (y * y) / (ry * ry)
    if v <= edge then
      local t = -(x / rx) * 0.55 - (y / ry) * 0.85 + (N((cx + x) // 2, (cy + y) // 2, seed + 1) - 0.5) * 0.7
      local c = pal[3]
      if t > 0.75 then c = pal[1] elseif t > 0.3 then c = pal[2] elseif t < -0.75 then c = pal[5] elseif t < -0.25 then c = pal[4] end
      if N((cx + x) // 3, (cy + y) // 3, seed + 2) > 0.86 and t > -0.1 then c = pal[1] end
      put(K, cx + x, cy + y, c)
    end
  end end
end
local function pal5(h1, h2, h3, h4, h5) return { hx(h1), hx(h2), hx(h3), hx(h4), hx(h5) } end
local PALS = {
  oak = pal5("#a6d05a", "#76b048", "#4f8f3a", "#356b2e", "#22472a"),
  pine = pal5("#7cb06a", "#5a9454", "#3a7444", "#285636", "#1a3a2a"),
  autumn = pal5("#ffc458", "#f0a43a", "#d0702a", "#a44a24", "#6e2e1e"),
  autumn_pine = pal5("#e8c860", "#d8b04a", "#b07a2e", "#7e5426", "#4e3420"),
  bush = pal5("#90c060", "#6aa84a", "#3f7f38", "#2c5e2e", "#1d3f24"),
  dry = pal5("#c8c870", "#a8b05a", "#7c8a44", "#5a6a36", "#3c4628"),
  juniper = pal5("#78a886", "#5a8a6a", "#3c6a52", "#2a4c3e", "#1c3330"),
  rock = pal5("#d0ceca", "#b4b2ae", "#8c8a88", "#686668", "#48464c"),
  sandrock = pal5("#ead0a0", "#d6b483", "#b48e5e", "#8a6a44", "#5e4630"),
}
local function trunk(K, x, yb, h, w, c)
  c = col(c or "wood")
  for y = yb - h, yb do for xx = x, x + w - 1 do
    local s = (xx == x) and 2 or ((xx == x + w - 1) and 4 or 3)
    if N(xx, y // 3, 5) > 0.8 then s = s + 1 end
    put(K, xx, y, tone(c, s))
  end end
  put(K, x - 1, yb, tone(c, 4)); put(K, x + w, yb, tone(c, 4)); put(K, x - 2, yb, tone(c, 5))
end
local function rock(K, cx, yb, rx, ry, pal, seed)
  clump(K, cx, yb - ry, rx, ry, pal, seed)
  P.line(K, cx - rx // 2, yb - ry, cx, yb - ry - ry // 2, pal[2], 1)
  P.line(K, cx + 1, yb - ry + 2, cx + rx // 2, yb - 2, pal[4], 1)
end
local function nuggets(K, cx, yb, w, h, c, seed)
  for i = 0, 26 do
    local x = cx - w + math.floor(N(i, 1, seed) * w * 2)
    local y = yb - math.floor(N(i, 2, seed) * h) - 3
    if P.alpha(P.get(K, x, y)) > 0 then put(K, x, y, c); put(K, x + 1, y, P.shade(c, 0.72)); put(K, x, y - 1, P.shade(c, 1.3)) end
  end
end

---------------------------------------------------------------------------------------------- props
local ENV = {}
ENV.tree_oak = function(K, pal)
  pal = pal or PALS.oak
  shadow(K, 4, 0, 24, 6)
  trunk(K, -3, 0, 30, 7, "wood")
  P.line(K, 0, -20, -9, -30, C.wood_dark, 2); P.line(K, 2, -22, 10, -33, C.wood_dark, 2)
  clump(K, -11, -38, 15, 12, pal, 3); clump(K, 12, -40, 15, 12, pal, 4); clump(K, 0, -52, 18, 14, pal, 5); clump(K, -2, -32, 13, 7, pal, 6)
end
ENV.tree_pine = function(K, pal)
  pal = pal or PALS.pine
  shadow(K, 3, 0, 18, 5)
  trunk(K, -2, 0, 12, 5, "wood_dark")
  for _, t in ipairs({ { -9, 22, 11 }, { -24, 18, 11 }, { -38, 14, 11 }, { -51, 10, 10 }, { -61, 6, 8 } }) do
    local yb, hw, h = t[1], t[2], t[3]
    for y = 0, h + 4 do
      local w = math.floor(hw * (y / (h + 4)) + 0.5)
      for x = -w, w do
        local c = pal[3]
        local n = N(x, yb - h - 4 + y, 9)
        if x < -w * 0.35 and n > 0.3 then c = pal[2] elseif x > w * 0.45 then c = pal[4] end
        if x < -w * 0.65 and n > 0.6 then c = pal[1] end
        if y >= h + 3 then c = pal[5] end
        if y == h + 4 and (x % 3 == 0) then c = nil end
        put(K, x, yb - h - 4 + y, c)
      end
    end
  end
  put(K, 0, -66, pal[1]); put(K, 0, -65, pal[2])
end
ENV.berry_bush = function(K, pal, berry)
  pal = pal or PALS.bush
  shadow(K, 2, 0, 20, 5)
  clump(K, -9, -10, 12, 9, pal, 11); clump(K, 9, -10, 12, 9, pal, 12); clump(K, 0, -17, 13, 10, pal, 13)
  local bc = berry or C.red
  for i = 0, 26 do
    local x = math.floor(N(i, 3, 7) * 44) - 22
    local y = -math.floor(N(i, 4, 7) * 22) - 3
    if P.alpha(P.get(K, x, y)) > 0 then put(K, x, y, bc); put(K, x + 1, y + 1, P.shade(bc, 0.65)); put(K, x, y - 1, P.shade(bc, 1.3)) end
  end
end
ENV.gold_mine = function(K, pal)
  pal = pal or PALS.rock
  shadow(K, 2, 0, 30, 6)
  rock(K, -12, 0, 16, 13, pal, 21); rock(K, 11, 0, 17, 15, pal, 22); rock(K, 0, -12, 15, 13, pal, 23)
  nuggets(K, 0, 0, 24, 36, C.gold, 31)
  for _, q in ipairs({ { -3, -22 }, { 9, -15 }, { -10, -8 } }) do put(K, q[1], q[2], C.yellow); put(K, q[1] + 1, q[2], C.white) end
end
ENV.stone_mine = function(K, pal)
  pal = pal or PALS.rock
  shadow(K, 2, 0, 30, 6)
  rock(K, -13, 0, 15, 12, pal, 41); rock(K, 12, 0, 16, 13, pal, 42); rock(K, -1, -11, 16, 15, pal, 43); rock(K, 22, 0, 6, 5, pal, 44)
end
ENV.prickly_pear = function(K)
  local pal = pal5("#a8d088", "#8cc070", "#5a9a4e", "#3e7240", "#28502e")
  shadow(K, 2, 0, 14, 4)
  for i, q in ipairs({ { 0, -9, 6, 9 }, { -9, -17, 5, 7 }, { 8, -20, 5, 7 }, { 0, -27, 4, 6 } }) do clump(K, q[1], q[2], q[3], q[4], pal, 50 + i) end
  for _, q in ipairs({ { -9, -24 }, { 8, -27 }, { 0, -33 } }) do put(K, q[1], q[2], C.red); put(K, q[1] + 1, q[2], C.red_dark); put(K, q[1], q[2] - 1, C.orange) end
end
ENV.tree_acacia = function(K)
  local pal = PALS.dry
  shadow(K, 4, 0, 28, 5)
  trunk(K, -2, 0, 32, 5, "wood")
  P.line(K, 0, -26, -16, -38, C.wood, 3); P.line(K, 2, -26, 18, -40, C.wood, 3)
  clump(K, -16, -44, 18, 6, pal, 61); clump(K, 16, -46, 18, 6, pal, 62); clump(K, 0, -49, 22, 7, pal, 63)
end
ENV.tree_palm = function(K)
  shadow(K, 10, 0, 22, 5)
  for i = 0, 56 do
    local x = math.floor(6 * math.sin(i / 56 * 1.4) + 0.5)
    put(K, x - 2, -i, C.wood_light); put(K, x - 1, -i, C.wood); put(K, x, -i, (i % 5 == 0) and C.wood_dark or C.wood); put(K, x + 1, -i, C.wood_dark)
  end
  local tx, ty = 6, -58
  local pal = { hx("#a8d070"), hx("#8cc05a"), hx("#5a9a3e"), hx("#3e7232") }
  for _, a in ipairs({ { -30, 10 }, { 30, 10 }, { -24, -6 }, { 24, -8 }, { -10, -16 }, { 10, -16 }, { -32, 20 }, { 32, 20 } }) do
    local ex, ey = tx + a[1], ty + a[2]
    P.line(K, tx, ty, ex, ey, pal[3], 3); P.line(K, tx, ty - 1, ex, ey - 1, pal[2], 1); P.line(K, tx, ty + 2, ex, ey + 2, pal[4], 1)
    for t = 0.3, 0.9, 0.2 do local px, py = tx + a[1] * t, ty + a[2] * t put(K, px, py + 3, pal[4]); put(K, px, py - 2, pal[1]) end
  end
  P.ellipse(K, tx, ty + 2, 4, 3, C.wood_dark); put(K, tx - 2, ty + 4, C.orange); put(K, tx + 2, ty + 4, C.orange)
end
ENV.rosehip_bush = function(K) ENV.berry_bush(K, PALS.dry, C.red) end
ENV.tree_juniper = function(K)
  local pal = PALS.juniper
  shadow(K, 2, 0, 15, 4)
  trunk(K, -2, 0, 9, 4, "wood_dark")
  clump(K, 0, -18, 13, 12, pal, 71); clump(K, -1, -32, 10, 10, pal, 72); clump(K, 0, -43, 6, 7, pal, 73)
end
ENV.tree_scots_pine = function(K)
  local pal = PALS.pine
  shadow(K, 4, 0, 18, 5)
  trunk(K, -2, 0, 46, 5, "orange")
  P.line(K, 0, -38, -12, -47, C.wood, 2); P.line(K, 2, -41, 14, -52, C.wood, 2)
  clump(K, -14, -50, 14, 8, pal, 81); clump(K, 14, -55, 14, 8, pal, 82); clump(K, 0, -63, 15, 9, pal, 83)
end

E.ENV = {
  tree_oak = { ENV.tree_oak }, tree_pine = { ENV.tree_pine }, berry_bush = { ENV.berry_bush },
  gold_mine = { ENV.gold_mine }, stone_mine = { ENV.stone_mine },
  ["autumn/tree_oak"] = { ENV.tree_oak, PALS.autumn }, ["autumn/tree_pine"] = { ENV.tree_pine, PALS.autumn_pine },
  ["autumn/berry_bush"] = { ENV.berry_bush, pal5("#d8c060", "#b8a04a", "#8a7a36", "#62582a", "#423c22"), C.blue },
  ["desert/gold_mine"] = { ENV.gold_mine, PALS.sandrock }, ["desert/stone_mine"] = { ENV.stone_mine, PALS.sandrock },
  ["desert/prickly_pear"] = { ENV.prickly_pear }, ["desert/tree_acacia"] = { ENV.tree_acacia },
  ["desert/tree_palm"] = { ENV.tree_palm },
  ["steppe/gold_mine"] = { ENV.gold_mine }, ["steppe/stone_mine"] = { ENV.stone_mine },
  ["steppe/rosehip_bush"] = { ENV.rosehip_bush }, ["steppe/tree_juniper"] = { ENV.tree_juniper },
  ["steppe/tree_scots_pine"] = { ENV.tree_scots_pine },
}

---------------------------------------------------------------------------------------------- fields
-- 2x2 tiles (4 m) = 128 x 128 px of ground seen from above; crop rows, fence, team pennant
E.FIELDS = {
  field = { soil = "#7a5634", crop = { "#f0d070", "#e6c45a", "#c49a3a", "#8a6a2a" }, kind = "wheat" },
  ["desert/field"] = { soil = "#a07a4a", crop = { "#b8e070", "#9ccf5a", "#6aa03e", "#3e6e2e" }, kind = "leafy" },
  ["steppe/field"] = { soil = "#6e5636", crop = { "#e8e0a0", "#d8d08a", "#b0a460", "#7a7240" }, kind = "wheat" },
  ["autumn/field"] = { soil = "#6a4a2e", crop = { "#7aa850", "#5a8a3a", "#3e6a2e", "#2a4a24" }, kind = "pumpkin" },
}
local function draw_field(K, f)
  local x0, x1, y0, y1 = -61, 61, -124, -3
  P.use(K, "ground")
  local soil = hx(f.soil)
  for y = y0, y1 do for x = x0, x1 do
    local row = (y - y0) % 6
    local v = (row >= 4) and tone(soil, 4) or tone(soil, (N(x, y, 91) > 0.9) and 2 or 3)
    put(K, x, y, v)
  end end
  local c = { hx(f.crop[1]), hx(f.crop[2]), hx(f.crop[3]), hx(f.crop[4]) }
  for y = y0 + 1, y1 - 2, 6 do
    for x = x0 + 2, x1 - 2 do
      local n = N(x, y, 93)
      if f.kind == "wheat" then
        local hgt = 2 + math.floor(n * 3)
        for k = 0, hgt do put(K, x, y + 2 - k, (k == hgt) and ((x % 2 == 0) and c[1] or c[2]) or ((k > hgt - 2) and c[2] or c[3])) end
        put(K, x, y + 3, c[4])
      elseif f.kind == "leafy" then
        if x % 6 < 4 then put(K, x, y, c[2]); put(K, x, y + 1, c[3]); put(K, x, y + 2, c[4]); if x % 6 == 1 then put(K, x, y - 1, c[1]) end end
      else
        if x % 4 ~= 3 then put(K, x, y + 1, c[2]); put(K, x, y + 2, c[3]) end
        if x % 13 == 6 then P.rect(K, x - 2, y - 2, x + 2, y + 1, C.orange); put(K, x - 1, y - 2, C.yellow); put(K, x, y - 3, c[3]); put(K, x + 2, y + 1, P.shade(C.orange, 0.7)) end
      end
    end
  end
  P.use(K, "props")
  for x = x0 - 1, x1 + 1 do put(K, x, y0 - 3, C.wood); put(K, x, y0 - 2, C.wood_dark) end
  for x = x0 - 1, x1 + 1, 10 do P.rect(K, x, y0 - 8, x + 1, y0 - 1, C.wood_dark) end
  P.vline(K, x0 - 3, y0 - 3, y1, C.wood); P.vline(K, x1 + 3, y0 - 3, y1, C.wood_dark)
  for x = x0 - 1, x1 + 1, 10 do P.rect(K, x, y1 - 6, x + 1, y1 + 1, C.wood_dark) end
  for x = x0 - 1, x1 + 1 do put(K, x, y1 - 4, C.wood); put(K, x, y1 - 1, C.wood_dark) end
  P.use(K, "structure")
  A.flag(K, (x1 + 2) / 32, 0.1, 0.9, 12)
end

---------------------------------------------------------------------------------------------- upgrade kits
-- one civ enclosure drawn for a 3.6 m footprint (the game scales it to the building). The back half (rear wall,
-- rear posts, side walls behind the centre) sorts behind the building, the front half (front wall with a gate,
-- front posts, team banners, side walls in front of the centre) in front of it.
local KHW, KD = 1.8, 1.8
local function kit_style(civ)
  local s = CIVS[civ]._buildings
  return s, (s.kit_wall or s.castle_wall or s.wall), (s.kit_wall_c or s.castle_wall_c or s.wall_c)
end
local function post(K, s, wall, wc, x, d, h)
  if s.kit_post == "lantern" then Pr.stone_lantern(K, x, d) return end
  if s.kit_post == "tug" then A.tug(K, x, d, 2.4) return end
  if s.kit_post == "runestone" then Pr.runestone(K, x, d) return end
  A.round_tower(K, x, d - 0.2, 0.25, h, wall, wc, s.kit_cap or (s.tower_top == "dome" and "dome") or "cone",
    { top_c = s.tower_c or s.dome_c or s.roof_c, top_mat = s.tower_mat, finial = s.finial, band_c = s.band_c, cone_h = 0.6, dome_h = 0.3 })
end
local function wall_run(K, s, wall, wc, x0, x1, d, h)
  if s.kit_fence then Pr.fence(K, x0, x1, d) return end
  A.facade(K, x0, x1, d, h, wall, wc, { band_c = s.band_c, glazed = s.glazed_c })
  local c = col(wc)
  P.use(K, "structure")
  for x = A.px(x0), A.px(x1) - 1 do P.put(K, x, A.vy(d, h), tone(c, 2)); P.put(K, x, A.vy(d, h) - 1, tone(c, 1)) end
end
local function side_wall(K, s, wall, wc, x, d0, d1, h)
  if s.kit_fence then
    P.use(K, "props")
    for y = A.vy(d1, 0), A.vy(d0, 0) do P.put(K, A.px(x), y, C.wood) end
    P.use(K, "structure")
    return
  end
  local c = col(wc)
  P.use(K, "structure")
  for y = A.vy(d1, h), A.vy(d0, h) do for k = -2, 2 do P.put(K, A.px(x) + k, y, tone(c, (k < 0) and 2 or ((k > 0) and 4 or 3))) end end
  local yb = A.vy(d0, 0)
  for y = A.vy(d0, h), yb do for k = -2, 2 do P.put(K, A.px(x) + k, y, tone(c, 4)) end end
end
local function kit_back(K, civ)
  local s, wall, wc = kit_style(civ)
  side_wall(K, s, wall, wc, -KHW, KD * 0.0, KD, 0.5); side_wall(K, s, wall, wc, KHW, 0.0, KD, 0.5)
  wall_run(K, s, wall, wc, -KHW, KHW, KD, 0.5)
  post(K, s, wall, wc, -KHW, KD, 1.1); post(K, s, wall, wc, KHW, KD, 1.1)
end
local function kit_front(K, civ)
  local s, wall, wc = kit_style(civ)
  wall_run(K, s, wall, wc, -KHW, -0.55, 0, 0.5); wall_run(K, s, wall, wc, 0.55, KHW, 0, 0.5)
  post(K, s, wall, wc, -KHW, 0, 1.1); post(K, s, wall, wc, KHW, 0, 1.1)
  for _, x in ipairs({ -0.85, 0.85 }) do
    local px, yb = A.px(x), A.vy(0.05, 0)
    P.use(K, "props")
    P.vline(K, px, A.vy(0.05, 2.1), yb, C.wood_dark); P.rect(K, px - 1, A.vy(0.05, 2.1) - 2, px + 1, A.vy(0.05, 2.1) - 1, C.gold)
    P.use(K, "structure")
    A.banner(K, x, 0.05, 2.0, 0.42, 0.9, s.emblem, s.ec)
  end
end

---------------------------------------------------------------------------------------------- output
function E.build_all(root, out, want, want_civ)
  local godot = root .. "/sample_project"
  local done = {}
  local function paths(section, key, file)
    local flat = key:gsub("/", "__")
    return { aseprite = string.format("%s/art_source/aseprite/src/%s/%s.aseprite", root, section, flat),
             png = string.format("%s/%s/%s/%s", godot, out, section, file),
             res = string.format("res://%s/%s/%s", out, section, file),
             meta = string.format("%s/build/px_meta/%s/%s.json", root, section, flat) }
  end
  if want.environment then
    for key, def in pairs(E.ENV) do
      local f, a1, a2 = def[1], def[2], def[3]
      BL.emit(function(K) f(K, a1, a2) end, false, 0.3, paths("environment", key, key .. ".png"))
      done[#done + 1] = "environment/" .. key
    end
  end
  if want.fields then
    for key, f in pairs(E.FIELDS) do
      BL.emit(function(K) draw_field(K, f) end, true, 2.0, paths("fields", key, key .. ".png"), { ground = true })
      done[#done + 1] = "fields/" .. key
    end
  end
  if want.upgrade_kits then
    for civ, v in pairs(CIVS) do
      if type(v) == "table" and v._buildings and (not want_civ or want_civ[civ]) then
        BL.emit(function(K) kit_back(K, civ) end, true, 0.0, paths("upgrade_kits", civ .. "/back", civ .. "_back.png"))
        BL.emit(function(K) kit_front(K, civ) end, true, 1.8, paths("upgrade_kits", civ .. "/front", civ .. "_front.png"))
        done[#done + 1] = "upgrade_kits/" .. civ
      end
    end
  end
  return done
end

return E
