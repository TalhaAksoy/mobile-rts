-- Yard props for the 2D-style buildings (32 px/m, 3/4 view). Positions in metres: (x, d) = ground point
-- (d = metres behind the footprint's front edge). Each prop casts a small dithered shadow.
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local A = dofile(GEN_ROOT .. "/arch.lua")
local CH = dofile(GEN_ROOT .. "/char.lua")
local col, tone = A.col, A.tone
local Pr = {}
local function put(K, x, y, c) if c then P.put(K, math.floor(x), math.floor(y), c) end end
local function at(x, d) return A.px(x), A.vy(d, 0) end
local function N(x, y, s) return P.noise(x, y, s or 7) end
local INK = P.hex("#241c26")

local function blob(K, cx, cy, rx, ry, c, seed)
  for y = -ry, ry do for x = -rx, rx do
    local v = (x * x) / ((rx + 0.5) ^ 2) + (y * y) / ((ry + 0.5) ^ 2)
    local n = N(cx + x, cy + y, seed or 5)
    if v <= 1 - ((n > 0.85) and 0.1 or 0) then
      local t = -(x / rx) * 0.55 - (y / ry) * 0.85 + (n - 0.5) * 0.5
      put(K, cx + x, cy + y, tone(c, (t > 0.55) and 1 or ((t > 0.1) and 2 or ((t > -0.35) and 3 or ((t > -0.75) and 4 or 5)))))
    end
  end end
end
Pr.blob = blob

local function use(K, l) P.use(K, l) end

Pr.cypress = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.2, d, 8, 3)
  use(K, "props")
  P.rect(K, px - 1, py - 4, px + 1, py, C.wood_dark)
  local g = P.hex("#2f5a34")
  for y = py - 46, py - 3 do
    local t = (y - (py - 46)) / 43
    local hw = math.floor(1 + 6 * math.sin(t * math.pi * 0.9) + 0.5)
    for xx = px - hw, px + hw do
      local s = (xx < px - hw * 0.3) and 2 or ((xx > px + hw * 0.4) and 4 or 3)
      if N(xx, y, 41) > 0.82 then s = s + 1 end
      put(K, xx, y, tone(g, s))
    end
  end
  use(K, "structure")
end
Pr.fountain = function(K, x, d, c)                     -- şadırvan: octagonal basin with a small dome on columns
  local px, py = at(x, d)
  c = col(c or "#E3D7BF")
  A.shadow_ellipse(K, x + 0.3, d, 22, 6)
  use(K, "props")
  for y = py - 8, py do for xx = px - 20, px + 20 do put(K, xx, y, tone(c, (xx < px - 14) and 2 or ((xx > px + 14) and 4 or 3))) end end
  for xx = px - 18, px + 18 do put(K, xx, py - 9, tone(P.hex("#4a86b8"), 2)); put(K, xx, py - 10, tone(P.hex("#4a86b8"), 3)) end
  for _, ox in ipairs({ -14, -5, 5, 14 }) do P.rect(K, px + ox, py - 30, px + ox + 1, py - 10, tone(c, 2)) end
  for y = 0, 10 do local hw = math.floor(17 * math.sqrt(math.max(0, 1 - (y / 10) ^ 2))) for xx = px - hw, px + hw do put(K, xx, py - 31 - y, tone(P.hex("#7D8790"), (xx < px) and 2 or 4)) end end
  P.vline(K, px, py - 46, py - 41, C.gold)
  use(K, "structure")
end
Pr.carpet = function(K, x, d)                          -- carpet hung over a rail to air
  local px, py = at(x, d)
  use(K, "props")
  P.vline(K, px - 12, py - 26, py, C.wood_dark); P.vline(K, px + 12, py - 26, py, C.wood_dark); P.hline(K, px - 13, px + 13, py - 26, C.wood)
  local r, b, g = P.hex("#A8323A"), P.hex("#1F4FA0"), C.gold
  for y = py - 25, py - 8 do for xx = px - 10, px + 10 do
    local v = r
    if xx == px - 10 or xx == px + 10 or y == py - 25 or y == py - 8 then v = b
    elseif math.abs(xx - px) + math.abs(y - (py - 16)) < 5 then v = g
    elseif (xx + y) % 4 == 0 then v = P.shade(r, 0.8) end
    put(K, xx, y, v)
  end end
  for xx = px - 10, px + 10, 2 do put(K, xx, py - 7, C.cream) end
  use(K, "structure")
end
Pr.copper_pot = function(K, x, d)                      -- the janissary kazan: big copper cauldron on a tripod
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.1, d, 9, 3)
  use(K, "props")
  local cu = P.hex("#B8642E")
  for y = -8, 0 do local hw = math.floor(8 * math.sqrt(math.max(0, 1 - ((y + 4) / 5) ^ 2)) + 1) for xx = -hw, hw do put(K, px + xx, py - 4 + y, tone(cu, (xx < -3) and 1 or ((xx > 3) and 4 or 2))) end end
  P.hline(K, px - 8, px + 8, py - 12, tone(cu, 5)); P.line(K, px - 6, py, px - 3, py - 4, C.iron_dark, 1); P.line(K, px + 6, py, px + 3, py - 4, C.iron_dark, 1)
  use(K, "structure")
end
Pr.barrel = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.15, d, 6, 2)
  use(K, "props")
  for y = py - 13, py do for xx = px - 5, px + 5 do
    local bulge = (math.abs(y - (py - 6.5)) < 4) and 0 or 1
    if math.abs(xx - px) <= 5 - bulge then put(K, xx, y, tone(C.wood, (xx < px - 2) and 2 or ((xx > px + 2) and 4 or 3))) end
  end end
  P.hline(K, px - 5, px + 5, py - 10, C.iron_dark); P.hline(K, px - 5, px + 5, py - 3, C.iron_dark)
  P.hline(K, px - 4, px + 4, py - 13, tone(C.wood, 2))
  use(K, "structure")
end
Pr.crate = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.15, d, 7, 2)
  use(K, "props")
  for y = py - 11, py do for xx = px - 6, px + 6 do put(K, xx, y, tone(C.wood_light, (xx < px - 4) and 2 or ((xx > px + 4) and 4 or 3))) end end
  P.line(K, px - 6, py, px + 6, py - 11, tone(C.wood, 4), 1); P.rect(K, px - 6, py - 11, px + 6, py - 11, tone(C.wood, 4)); P.vline(K, px + 6, py - 11, py, tone(C.wood, 4))
  for xx = px - 6, px + 6 do put(K, xx, py - 14, tone(C.wood_light, 1)); put(K, xx, py - 13, tone(C.wood_light, 2)); put(K, xx, py - 12, tone(C.wood_light, 2)) end
  use(K, "structure")
end
Pr.sacks = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.2, d, 10, 3)
  use(K, "props")
  for _, q in ipairs({ { -5, 0 }, { 5, 0 }, { 0, -6 } }) do blob(K, px + q[1], py - 5 + q[2], 5, 5, C.linen, 3); put(K, px + q[1], py - 10 + q[2], tone(C.linen, 4)) end
  use(K, "structure")
end
Pr.logs = function(K, x, d, len, rows)                 -- stacked logs, cut ends facing the camera
  local px, py = at(x, d)
  rows = rows or 3
  A.shadow_ellipse(K, x + len / 2, d, math.floor(len * 16), 4)
  use(K, "props")
  local lx = A.px(len)
  for r = 0, rows - 1 do
    for i = 0, rows - 1 - r do
      local cx, cy = px + i * 9 + r * 4, py - 4 - r * 8
      -- log body running back
      for y = cy - 4, cy + 4 do for xx = cx, cx + lx - (rows - 1) * 9 do put(K, xx + 4, y - 3, tone(C.wood, (y < cy - 1) and 2 or 4)) end end
      blob(K, cx, cy, 4, 4, C.wood_light, 7)
      put(K, cx, cy, tone(C.wood, 4)); put(K, cx - 1, cy - 1, tone(C.wood_light, 1))
    end
  end
  use(K, "structure")
end
Pr.sawhorse = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  P.line(K, px - 10, py, px - 6, py - 10, C.wood_dark, 1); P.line(K, px - 2, py, px - 6, py - 10, C.wood_dark, 1)
  P.line(K, px + 2, py, px + 6, py - 10, C.wood_dark, 1); P.line(K, px + 10, py, px + 6, py - 10, C.wood_dark, 1)
  P.rect(K, px - 14, py - 13, px + 14, py - 9, C.wood); P.hline(K, px - 14, px + 14, py - 13, C.wood_light)
  P.line(K, px + 3, py - 22, px - 2, py - 13, C.steel, 1)
  use(K, "structure")
end
Pr.stump = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  P.rect(K, px - 5, py - 6, px + 5, py, C.wood); P.ellipse(K, px, py - 7, 5, 2, C.wood_light); put(K, px, py - 7, C.wood)
  P.line(K, px + 2, py - 8, px + 7, py - 16, C.wood_dark, 2); P.rect(K, px + 6, py - 19, px + 9, py - 15, C.steel)
  use(K, "structure")
end
Pr.anvil = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.1, d, 7, 2)
  use(K, "props")
  P.rect(K, px - 3, py - 7, px + 3, py, C.wood_dark)
  P.rect(K, px - 7, py - 11, px + 6, py - 8, C.iron); P.hline(K, px - 7, px + 6, py - 11, C.steel); P.poly(K, { { px - 7, py - 11 }, { px - 12, py - 10 }, { px - 7, py - 8 } }, C.iron)
  use(K, "structure")
end
Pr.forge = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  for y = py - 14, py do for xx = px - 12, px + 12 do put(K, xx, y, A.WALL.ashlar(C.stone_dark, (xx < px - 8) and 2 or 3, xx, y, xx, y, {})) end end
  for xx = px - 9, px + 9 do put(K, xx, py - 15, C.orange); put(K, xx, py - 16, (xx % 3 == 0) and C.yellow or C.red) end
  for xx = px - 6, px + 6, 3 do put(K, xx, py - 18, C.yellow); put(K, xx + 1, py - 20, C.orange) end
  use(K, "structure")
end
Pr.trough = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  P.rect(K, px - 14, py - 7, px + 14, py, C.wood); P.rect(K, px - 12, py - 7, px + 12, py - 5, P.hex("#4a86b8")); P.hline(K, px - 14, px + 14, py, C.wood_dark)
  use(K, "structure")
end
Pr.hay = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.2, d, 10, 3)
  use(K, "props")
  for y = py - 11, py do for xx = px - 9, px + 9 do
    local v = tone(C.straw, (xx < px - 6) and 2 or ((xx > px + 6) and 4 or 3))
    if (xx + y * 3) % 7 == 0 then v = tone(C.straw, 4) end
    put(K, xx, y, v)
  end end
  P.vline(K, px - 3, py - 11, py, C.straw_dark); P.vline(K, px + 3, py - 11, py, C.straw_dark)
  for xx = px - 9, px + 9 do put(K, xx, py - 12, tone(C.straw, 1)) end
  use(K, "structure")
end
Pr.ore = function(K, x, d, c, r)
  local px, py = at(x, d)
  r = r or 9
  A.shadow_ellipse(K, x + 0.2, d, r + 2, 3)
  use(K, "props")
  c = col(c)
  for i = 0, 7 do
    local ox = math.floor((N(i, 1, 13) - 0.5) * r * 1.6)
    local oy = -math.floor(N(i, 2, 13) * r * 0.8) - 3
    blob(K, px + ox, py + oy, 3 + math.floor(N(i, 3, 13) * 3), 3, c, i)
  end
  use(K, "structure")
end
Pr.cart = function(K, x, d, load)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.4, d, 16, 3)
  use(K, "props")
  P.rect(K, px - 14, py - 13, px + 14, py - 6, C.wood); P.hline(K, px - 14, px + 14, py - 13, C.wood_light); P.rect(K, px - 14, py - 13, px - 13, py - 6, C.wood_dark)
  P.line(K, px + 14, py - 8, px + 26, py - 4, C.wood_dark, 2)
  for _, wx in ipairs({ -8, 8 }) do P.ellipse(K, px + wx, py - 4, 4, 4, C.wood_dark); P.ellipse(K, px + wx, py - 4, 2, 2, C.wood); put(K, px + wx, py - 4, C.iron) end
  use(K, "structure")
  if load then Pr.ore(K, x, d + 0.15, load, 8) end
end
Pr.headframe = function(K, x, d)                       -- mine shaft head-frame with a winch wheel
  local px, py = at(x, d)
  use(K, "props")
  P.line(K, px - 14, py, px - 3, py - 44, C.wood_dark, 2); P.line(K, px + 14, py, px + 3, py - 44, C.wood_dark, 2)
  P.hline(K, px - 10, px + 10, py - 22, C.wood); P.hline(K, px - 6, px + 6, py - 36, C.wood)
  P.ellipse(K, px, py - 46, 6, 6, C.wood_dark); P.ellipse(K, px, py - 46, 4, 4, C.wood); put(K, px, py - 46, C.iron)
  P.vline(K, px, py - 40, py - 8, C.linen)
  P.rect(K, px - 10, py - 6, px + 10, py, P.hex("#1a1418")); P.hline(K, px - 11, px + 11, py - 7, C.wood)
  use(K, "structure")
end
Pr.target = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.15, d, 6, 2)
  use(K, "props")
  P.line(K, px - 4, py, px - 2, py - 16, C.wood_dark, 1); P.line(K, px + 4, py, px + 2, py - 16, C.wood_dark, 1)
  P.ellipse(K, px, py - 18, 7, 7, C.straw); P.ellipse(K, px, py - 18, 5, 5, C.white); P.ellipse(K, px, py - 18, 3, 3, C.red); P.ellipse(K, px, py - 18, 1, 1, C.yellow)
  use(K, "structure")
end
Pr.nisan_tasi = function(K, x, d, c)                   -- Ottoman archery record stone: slender pillar with a turban-like cap
  local px, py = at(x, d)
  c = col(c or "#E3D7BF")
  A.shadow_ellipse(K, x + 0.2, d, 5, 2)
  use(K, "props")
  for y = py - 34, py do for xx = px - 2, px + 2 do put(K, xx, y, tone(c, (xx == px - 2) and 2 or ((xx == px + 2) and 4 or 3))) end end
  P.ellipse(K, px, py - 37, 4, 3, tone(c, 2)); P.hline(K, px - 4, px + 4, py - 36, tone(c, 4))
  for y = py - 30, py - 14, 3 do put(K, px, y, tone(c, 5)) end                              -- inscription
  use(K, "structure")
end
Pr.dummy = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.1, d, 5, 2)
  use(K, "props")
  P.vline(K, px, py - 30, py, C.wood_dark); P.hline(K, px - 9, px + 9, py - 24, C.wood_dark)
  for y = py - 26, py - 12 do for xx = px - 3, px + 3 do put(K, xx, y, tone(C.straw, (xx < px - 1) and 2 or 3)) end end
  P.ellipse(K, px, py - 30, 3, 3, C.linen)
  use(K, "structure")
end
Pr.rack = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  P.vline(K, px - 12, py - 20, py, C.wood_dark); P.vline(K, px + 12, py - 20, py, C.wood_dark); P.hline(K, px - 12, px + 12, py - 16, C.wood)
  for i = -9, 9, 4 do P.vline(K, px + i, py - 30, py - 2, C.wood); P.rect(K, px + i - 1, py - 33, px + i + 1, py - 30, C.steel) end
  use(K, "structure")
end
Pr.fence = function(K, x0, x1, d)
  local px0, py = at(x0, d)
  local px1 = A.px(x1)
  use(K, "props")
  for xx = px0, px1, 8 do P.rect(K, xx, py - 12, xx + 1, py, C.wood_dark) end
  P.hline(K, px0, px1, py - 10, C.wood); P.hline(K, px0, px1, py - 5, C.wood); P.hline(K, px0, px1, py - 9, C.wood_dark)
  use(K, "structure")
end
Pr.horse = function(K, x, d, c)
  local px, py = at(x, d)
  c = col(c or "horse_bay")
  A.shadow_ellipse(K, x + 0.2, d, 14, 3)
  use(K, "props")
  for _, lx in ipairs({ -9, -5, 6, 10 }) do P.rect(K, px + lx, py - 14, px + lx + 1, py, tone(c, 4)); P.rect(K, px + lx, py - 1, px + lx + 1, py, INK) end
  for y = -6, 6 do for xx = -13, 13 do if (xx * xx) / 180 + (y * y) / 40 <= 1 then put(K, px + xx, py - 18 + y, tone(c, (y < -2) and 2 or ((y > 3) and 4 or 3))) end end end
  P.line(K, px - 11, py - 20, px - 16, py - 30, tone(c, 3), 3); P.rect(K, px - 20, py - 32, px - 15, py - 27, tone(c, 3)); put(K, px - 18, py - 30, INK)
  P.line(K, px + 13, py - 20, px + 15, py - 9, col("mane_dark"), 2); P.line(K, px - 13, py - 21, px - 17, py - 31, col("mane_dark"), 1)
  use(K, "structure")
end
Pr.palm = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.6, d, 14, 3)
  use(K, "props")
  for i = 0, 50 do local xo = math.floor(5 * math.sin(i / 50 * 1.4) + 0.5) put(K, px + xo - 1, py - i, C.wood_light); put(K, px + xo, py - i, (i % 5 == 0) and C.wood_dark or C.wood); put(K, px + xo + 1, py - i, C.wood_dark) end
  local tx, ty = px + 5, py - 52
  for _, a in ipairs({ { -24, 8 }, { 24, 8 }, { -18, -5 }, { 18, -6 }, { -8, -12 }, { 8, -12 }, { -26, 16 }, { 26, 16 } }) do
    P.line(K, tx, ty, tx + a[1], ty + a[2], P.hex("#5a9a3e"), 3); P.line(K, tx, ty - 1, tx + a[1], ty + a[2] - 1, P.hex("#8cc05a"), 1)
  end
  P.ellipse(K, tx, ty + 2, 3, 2, C.wood_dark)
  use(K, "structure")
end
Pr.jar = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  local c = P.hex("#B4654A")
  for y = py - 12, py do local hw = math.floor(5 * math.sin((y - (py - 13)) / 13 * math.pi) + 1) for xx = px - hw, px + hw do put(K, xx, y, tone(c, (xx < px - 1) and 2 or ((xx > px + 2) and 4 or 3))) end end
  P.hline(K, px - 2, px + 2, py - 13, tone(c, 4))
  use(K, "structure")
end
Pr.stone_lantern = function(K, x, d)                   -- tōrō
  local px, py = at(x, d)
  local c = C.stone_grey
  A.shadow_ellipse(K, x + 0.1, d, 5, 2)
  use(K, "props")
  P.rect(K, px - 4, py - 3, px + 4, py, tone(c, 3)); P.rect(K, px - 1, py - 14, px + 1, py - 3, tone(c, 3))
  P.rect(K, px - 4, py - 20, px + 4, py - 14, tone(c, 3)); P.rect(K, px - 2, py - 18, px + 2, py - 16, C.glow)
  P.poly(K, { { px - 7, py - 20 }, { px + 8, py - 20 }, { px + 1, py - 26 } }, tone(c, 2)); put(K, px, py - 28, tone(c, 2))
  use(K, "structure")
end
Pr.lion = function(K, x, d)                            -- Chinese guardian lion on a plinth
  local px, py = at(x, d)
  local c = C.stone_grey
  use(K, "props")
  P.rect(K, px - 6, py - 6, px + 6, py, tone(c, 3)); P.hline(K, px - 6, px + 6, py - 6, tone(c, 2))
  blob(K, px, py - 13, 5, 7, c, 3); blob(K, px - 2, py - 21, 4, 4, c, 4); put(K, px - 4, py - 21, INK)
  use(K, "structure")
end
Pr.bamboo = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  for i, ox in ipairs({ -4, 0, 4 }) do
    local hgt = 40 + i * 6
    for y = py - hgt, py do put(K, px + ox, y, ((py - y) % 9 == 0) and P.hex("#5a7a2e") or P.hex("#8cb04a")) end
    for k = 1, 3 do local ly = py - hgt + k * 10 P.line(K, px + ox, ly, px + ox + ((k % 2 == 0) and 6 or -6), ly - 3, P.hex("#4a8a3a"), 1) end
  end
  use(K, "structure")
end
Pr.runestone = function(K, x, d)
  local px, py = at(x, d)
  local c = C.stone_grey
  A.shadow_ellipse(K, x + 0.15, d, 6, 2)
  use(K, "props")
  for y = py - 26, py do local hw = math.floor(5 - math.max(0, (py - 20 - y)) * 0.4) for xx = px - hw, px + hw do put(K, xx, y, tone(c, (xx < px - 2) and 2 or ((xx > px + 2) and 4 or 3))) end end
  for y = py - 22, py - 4, 2 do put(K, px + ((y // 2) % 3 - 1) * 2, y, P.hex("#a8323a")) end                -- red-painted runic band
  use(K, "structure")
end
Pr.hitching = function(K, x0, x1, d)                   -- Mongol horse line
  local px0, py = at(x0, d)
  local px1 = A.px(x1)
  use(K, "props")
  P.vline(K, px0, py - 16, py, C.wood_dark); P.vline(K, px1, py - 16, py, C.wood_dark); P.line(K, px0, py - 14, px1, py - 14, C.linen, 1)
  use(K, "structure")
end
Pr.well = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  for y = py - 9, py do for xx = px - 9, px + 9 do put(K, xx, y, A.WALL.ashlar(C.stone, (xx < px - 6) and 2 or 3, xx, y, xx, y, {})) end end
  P.hline(K, px - 8, px + 8, py - 10, P.hex("#1a2230")); P.vline(K, px - 8, py - 24, py - 9, C.wood_dark); P.vline(K, px + 8, py - 24, py - 9, C.wood_dark)
  P.hline(K, px - 9, px + 9, py - 24, C.wood); P.vline(K, px, py - 23, py - 14, C.linen); P.rect(K, px - 1, py - 14, px + 1, py - 12, C.wood)
  use(K, "structure")
end
-- windmill sails (8 for the Aegean type, 4 for a post mill), centred at screen point (px, py)
Pr.sails = function(K, px, py, r, n, c)
  c = col(c or "cream")
  use(K, "props")
  for k = 0, n - 1 do
    local a = 45 + k * 360 / n
    local ex, ey = P.along(px, py, a, r)
    P.line(K, px, py, ex, ey, C.wood_dark, 1)
    if n > 4 then
      local s1x, s1y = P.along(px, py, a, 5)
      local ox, oy = P.dir(a + 90)
      P.poly(K, { { s1x, s1y }, { ex, ey }, { s1x + ox * 7, s1y + oy * 7 } }, tone(c, (k % 2 == 0) and 2 or 3))
    else
      local s1x, s1y = P.along(px, py, a, 6)
      local ox, oy = P.dir(a + 90)
      P.poly(K, { { s1x, s1y }, { ex, ey }, { ex + ox * 6, ey + oy * 6 }, { s1x + ox * 6, s1y + oy * 6 } }, tone(c, 2))
      for t = 0.25, 1, 0.25 do local lx, ly = P.along(px, py, a, 6 + (r - 6) * t) P.line(K, lx, ly, lx + ox * 6, ly + oy * 6, C.wood_dark, 1) end
    end
  end
  P.ellipse(K, px, py, 2, 2, C.wood_dark)
  use(K, "structure")
end
Pr.waterwheel = function(K, px, py, r)
  use(K, "props")
  for a = 0, 359, 2 do local x, y = P.along(px, py, a, r) put(K, x, y, C.wood_dark); local x2, y2 = P.along(px, py, a, r - 2) put(K, x2, y2, C.wood) end
  for a = 0, 359, 30 do P.line(K, px, py, { P.along(px, py, a, r) }, C.wood, 1); local bx, by = P.along(px, py, a, r) P.rect(K, math.floor(bx) - 1, math.floor(by) - 1, math.floor(bx) + 1, math.floor(by) + 1, C.wood_dark) end
  P.ellipse(K, px, py, 2, 2, C.iron)
  for x = px - r - 4, px + r + 4 do put(K, x, py + r - 1, P.hex("#4a86b8")); put(K, x, py + r, P.hex("#3a6e9a")) end
  use(K, "structure")
end
Pr.tug = function(K, x, d) A.tug(K, x, d, 3.2) end
Pr.tree_small = function(K, x, d, c)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.3, d, 10, 3)
  use(K, "props")
  P.rect(K, px - 1, py - 12, px + 1, py, C.wood)
  blob(K, px, py - 20, 9, 9, col(c or "#4f8f3a"), 3)
  use(K, "structure")
end

---------------------------------------------------------------------------------------------- workshop / camp props
-- chimney stack (h0 -> h1 m tall at depth d) with a dithered smoke plume
Pr.chimney = function(K, x, d, h0, h1, c, smoke)
  local cx, y0, y1 = A.px(x), A.vy(d, h0), A.vy(d, h1)
  use(K, "props")
  c = col(c or "brick")
  for y = y1, y0 do for xx = cx - 3, cx + 3 do put(K, xx, y, A.WALL.brick(c, (xx == cx - 3) and 2 or ((xx == cx + 3) and 4 or 3), xx, y, xx - cx, y, {})) end end
  P.hline(K, cx - 4, cx + 4, y1, tone(c, 2))
  if smoke ~= false then
    for _, q in ipairs({ { 2, -6, 3 }, { 5, -13, 4 }, { 1, -21, 4 } }) do for yy = -q[3], q[3] do for xx = -q[3], q[3] do
      if xx * xx + yy * yy <= q[3] * q[3] and (xx + yy) % 2 == 0 then put(K, cx + q[1] + xx, y1 + q[2] + yy, C.grey_cloth) end end end end
  end
  use(K, "structure")
end
-- forge glow inside an opening: a dark mouth with embers (x0..x1 m, at depth d, from h0 to h1 m)
Pr.glow = function(K, x0, x1, d, h0, h1)
  local px0, px1, yb, yt = A.px(x0), A.px(x1), A.vy(d, h0), A.vy(d, h1)
  use(K, "props")
  for y = yt, yb do for x = px0, px1 do
    local t = (y - yt) / math.max(1, yb - yt)
    put(K, x, y, (t > 0.7) and (((x + y) % 3 == 0) and C.yellow or C.orange) or ((t > 0.45) and C.red_dark or P.hex("#2a2234")))
  end end
  use(K, "structure")
end
Pr.basket = function(K, x, d, load)
  local px, py = at(x, d)
  use(K, "props")
  for y = py - 8, py do for xx = px - 6, px + 6 do put(K, xx, y, tone(C.straw, ((xx + y) % 3 == 0) and 4 or ((xx < px - 3) and 2 or 3))) end end
  if load then Pr.blob(K, px, py - 9, 5, 3, col(load), 3) end
  use(K, "structure")
end
Pr.donkey = function(K, x, d)
  local px, py = at(x, d)
  local c = col("#8A7C6E")
  A.shadow_ellipse(K, x + 0.1, d, 10, 2)
  use(K, "props")
  for _, lx in ipairs({ -6, -3, 4, 7 }) do P.rect(K, px + lx, py - 10, px + lx + 1, py, tone(c, 4)) end
  for y = -4, 4 do for xx = -9, 9 do if (xx * xx) / 85 + (y * y) / 18 <= 1 then put(K, px + xx, py - 13 + y, tone(c, (y < -1) and 2 or 3)) end end end
  P.line(K, px - 8, py - 15, px - 11, py - 22, tone(c, 3), 2); P.rect(K, px - 14, py - 24, px - 10, py - 20, tone(c, 3))
  P.vline(K, px - 12, py - 29, py - 24, tone(c, 4)); P.vline(K, px - 10, py - 29, py - 24, tone(c, 4))       -- long ears
  for _, sx in ipairs({ -1, 1 }) do Pr.blob(K, px + sx * 4, py - 16, 3, 3, C.straw, 4) end                  -- panniers
  use(K, "structure")
end
-- dark shaft mouth with a timber collar
Pr.shaft = function(K, x, d, w)
  local px, py = at(x, d)
  w = w or 10
  use(K, "props")
  P.rect(K, px - w, py - 5, px + w, py, P.hex("#1a1418")); P.hline(K, px - w - 1, px + w + 1, py - 6, C.wood); P.hline(K, px - w - 1, px + w + 1, py, C.wood_dark)
  use(K, "structure")
end
-- hand windlass over a shaft: two posts, a drum with a crank and a rope
Pr.windlass = function(K, x, d)
  local px, py = at(x, d)
  Pr.shaft(K, x, d, 9)
  use(K, "props")
  P.vline(K, px - 9, py - 18, py - 5, C.wood_dark); P.vline(K, px + 9, py - 18, py - 5, C.wood_dark)
  P.rect(K, px - 8, py - 18, px + 8, py - 15, C.wood); P.line(K, px + 9, py - 16, px + 13, py - 12, C.iron, 1)
  P.vline(K, px, py - 15, py - 6, C.linen)
  use(K, "structure")
end
-- treadwheel windlass (Agricola): a big wheel beside a head-frame
Pr.treadwheel = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  for k = 0, 99 do                                                          -- rim
    local ang = k * math.pi / 50
    put(K, px + math.floor(math.cos(ang) * 15 + 0.5), py - 18 + math.floor(math.sin(ang) * 15 + 0.5), C.wood_dark)
    put(K, px + math.floor(math.cos(ang) * 14 + 0.5), py - 18 + math.floor(math.sin(ang) * 14 + 0.5), C.wood)
  end
  for a = 0, 7 do
    local ang = a * math.pi / 4
    P.line(K, px, py - 18, px + math.floor(math.cos(ang) * 14), py - 18 + math.floor(math.sin(ang) * 14), C.wood, 1)
  end
  put(K, px, py - 18, C.iron)
  P.line(K, px - 12, py, px - 4, py - 16, C.wood_dark, 1); P.line(K, px + 12, py, px + 4, py - 16, C.wood_dark, 1)
  use(K, "structure")
end
-- clay shaft furnace (bloomery) with a glowing tuyere
Pr.furnace = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.2, d, 9, 3)
  use(K, "props")
  local c = col("#9A6A48")
  for y = py - 26, py do
    local hw = 7 - math.floor((py - y) / 8)
    for xx = px - hw, px + hw do put(K, xx, y, tone(c, (xx < px - hw + 2) and 2 or ((xx > px + hw - 2) and 4 or 3))) end
  end
  P.rect(K, px - 2, py - 6, px + 2, py - 3, C.orange); put(K, px, py - 5, C.yellow)
  for _, q in ipairs({ { 1, -31, 2 }, { 3, -37, 3 } }) do for yy = -q[3], q[3] do for xx = -q[3], q[3] do
    if xx * xx + yy * yy <= q[3] * q[3] and (xx + yy) % 2 == 0 then put(K, px + q[1] + xx, py + q[2] + yy, C.grey_cloth) end end end end
  use(K, "structure")
end
-- quarry face: stepped benches of cut stone rising behind
Pr.quarry = function(K, x0, x1, d, c)
  c = col(c or "sand")
  use(K, "props")
  for step = 0, 2 do
    local yb, yt = A.vy(d + step * 0.35, 0.8 * step), A.vy(d + step * 0.35, 0.8 * (step + 1))
    for y = yt, yb do for x = A.px(x0 + step * 0.25), A.px(x1 - step * 0.25) do
      put(K, x, y, A.WALL.ashlar(c, (y < yt + 2) and 2 or ((N(x, y, 9) < 0.2) and 4 or 3), x, y, x, y, {}))
    end end
  end
  use(K, "structure")
end
-- adit: a timber-framed tunnel mouth into an earth bank
Pr.adit = function(K, x, d, bank)
  local px, py = at(x, d)
  use(K, "props")
  Pr.blob(K, px, py - 14, 26, 14, col(bank or "#8A6A48"), 6)
  P.rect(K, px - 7, py - 18, px + 7, py, P.hex("#1a1418"))
  P.rect(K, px - 9, py - 20, px - 7, py, C.wood_dark); P.rect(K, px + 7, py - 20, px + 9, py, C.wood_dark)
  P.rect(K, px - 11, py - 22, px + 11, py - 19, C.wood)
  use(K, "structure")
end
-- half-built boat: curved keel and a few strakes on trestles
Pr.boat = function(K, x, d)
  local px, py = at(x, d)
  A.shadow_ellipse(K, x + 0.6, d, 30, 4)
  use(K, "props")
  for i = -28, 28 do
    local yy = math.floor((i * i) / 90)
    put(K, px + i, py - 14 + yy, C.wood_dark); put(K, px + i, py - 13 + yy, C.wood_dark)
    if math.abs(i) < 22 then put(K, px + i, py - 17 + yy, C.wood); put(K, px + i, py - 18 + yy, C.wood_light) end
  end
  P.line(K, px - 28, py - 14, px - 32, py - 26, C.wood_dark, 2); P.line(K, px + 28, py - 14, px + 32, py - 26, C.wood_dark, 2)
  for _, tx in ipairs({ -14, 14 }) do P.vline(K, px + tx, py - 10, py, C.wood_dark) end
  use(K, "structure")
end
-- horseshoes / tools hung on a wall (row at depth d, height h)
Pr.horseshoes = function(K, x0, x1, d, h)
  use(K, "props")
  local y = A.vy(d, h)
  for x = A.px(x0), A.px(x1), 7 do
    P.ellipse(K, x, y, 2, 3, C.iron); put(K, x, y + 1, P.hex("#2a2234")); put(K, x, y, P.hex("#2a2234"))
  end
  use(K, "structure")
end
Pr.swords = function(K, x0, x1, d, h)
  use(K, "props")
  local y = A.vy(d, h)
  for x = A.px(x0), A.px(x1), 6 do
    P.vline(K, x, y - 12, y, C.steel); P.hline(K, x - 2, x + 2, y - 9, C.gold); put(K, x, y - 13, C.brown)
  end
  use(K, "structure")
end
-- box bellows / leather bellows beside a forge
Pr.bellows = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  P.rect(K, px - 8, py - 9, px + 8, py, C.wood); P.hline(K, px - 8, px + 8, py - 9, C.wood_light); P.line(K, px + 8, py - 6, px + 13, py - 6, C.wood_dark, 1)
  P.vline(K, px - 10, py - 13, py - 4, C.wood_dark)
  use(K, "structure")
end
-- shimenawa: straw rope with white zigzag paper (shide) hung across x0..x1 at height h
Pr.shimenawa = function(K, x0, x1, d, h)
  use(K, "props")
  local y = A.vy(d, h)
  for x = A.px(x0), A.px(x1) do
    local sag = math.floor(3 * math.sin((x - A.px(x0)) / math.max(1, A.px(x1) - A.px(x0)) * math.pi))
    put(K, x, y + sag, C.straw); put(K, x, y + sag + 1, C.straw_dark)
  end
  for x = A.px(x0) + 6, A.px(x1) - 4, 10 do
    local sag = math.floor(3 * math.sin((x - A.px(x0)) / math.max(1, A.px(x1) - A.px(x0)) * math.pi))
    for k = 0, 5 do put(K, x + ((k % 2 == 0) and 0 or 1), y + sag + 2 + k, C.white) end
  end
  use(K, "structure")
end
-- saw pit: a dark trench with a log across it on trestles, the top sawyer's saw
Pr.sawpit = function(K, x, d)
  local px, py = at(x, d)
  use(K, "props")
  P.rect(K, px - 18, py - 5, px + 18, py, P.hex("#2a2026")); P.hline(K, px - 19, px + 19, py - 6, C.wood_dark)
  P.rect(K, px - 22, py - 11, px + 22, py - 7, C.wood); P.hline(K, px - 22, px + 22, py - 11, C.wood_light)
  Pr.blob(K, px - 22, py - 9, 3, 3, C.wood_light, 2)
  P.vline(K, px + 2, py - 22, py - 1, C.steel); P.hline(K, px - 1, px + 5, py - 22, C.wood_dark)
  use(K, "structure")
end
-- marble / ashlar blocks
Pr.blocks = function(K, x, d, c)
  local px, py = at(x, d)
  c = col(c or "#E8E2D6")
  use(K, "props")
  for _, q in ipairs({ { -8, 0, 8, 7 }, { 4, 0, 9, 6 }, { -3, -7, 7, 6 } }) do
    local x0, y0 = px + q[1], py + q[2] - q[4]
    P.rect(K, x0, y0, x0 + q[3], y0 + q[4], tone(c, 3)); P.hline(K, x0, x0 + q[3], y0, tone(c, 1)); P.vline(K, x0 + q[3], y0, y0 + q[4], tone(c, 4))
  end
  use(K, "structure")
end
-- cedar / palm logs: long logs lying sideways (reddish cedar or ringed palm trunks)
Pr.long_logs = function(K, x, d, c, n)
  local px, py = at(x, d)
  c = col(c or "wood")
  use(K, "props")
  for i = 0, (n or 3) - 1 do
    local y = py - 3 - i * 5
    P.rect(K, px - 22 + i * 3, y - 2, px + 22 - i * 3, y + 2, tone(c, 3)); P.hline(K, px - 22 + i * 3, px + 22 - i * 3, y - 2, tone(c, 2))
    P.ellipse(K, px + 22 - i * 3, y, 2, 2, tone(c, 1))
  end
  use(K, "structure")
end

return Pr
