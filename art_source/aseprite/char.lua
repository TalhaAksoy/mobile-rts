-- Character kit v2 (32 px/m): one frame of a unit in the 3/4 view facing front-left (the game mirrors it when
-- walking right). Pixels relative to the feet (0,0), y grows downwards. A man is ~56 px tall with headgear.
-- Light from the upper left; 5-tone ramps; material patterns (mail, lamellar, scale, plate, quilt, brocade, fur).
-- Civ x role looks live in civs.lua (researched in docs/art/culture/<civ>.md).
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local M = {}

---------------------------------------------------------------------------------------------- colours
local function col(v)
  if v == nil or v == false then return nil end
  if v == "team" then return C.TEAM end
  if type(v) == "string" then
    if v:sub(1, 1) == "#" then return P.hex(v) end
    return C[v] or error("unknown colour " .. v)
  end
  return v
end
M.col = col
local TEAMR = { C.TEAM_H, C.TEAM_L, C.TEAM, C.TEAM_D, C.TEAM_DD }
-- 5-tone ramp: 1 highlight, 2 light, 3 base, 4 shade, 5 deep shade
local function ramp5(c)
  if c == C.TEAM then return TEAMR end
  return { P.shade(c, 1.32), P.shade(c, 1.14), c, P.shade(c, 0.76), P.shade(c, 0.56) }
end
M.ramp5 = ramp5
local function tone(c, i) return ramp5(c)[math.max(1, math.min(5, i))] end
M.tone = tone

-- material colour at a pixel: kind = cloth | mail | lamellar | scale | plate | quilt | brocade | embroidery |
-- fur | leather | stripes; t = shade index 1..5 from the form; (x, y) = pixel for the pattern; c2 = second colour
local function mat(kind, c, t, x, y, c2)
  local r = ramp5(c)
  local function T(i) return r[math.max(1, math.min(5, i))] end
  local cc2 = col(c2)
  if kind == "mail" then
    local ring = ((x + (y % 2)) % 2 == 0)
    if y % 3 == 0 and ring then return T(t - 1) end
    return ring and T(t) or T(t + 1)
  elseif kind == "lamellar" then
    local row = y // 4
    if y % 4 == 3 then return cc2 and tone(cc2, t) or T(t + 2) end   -- lacing row
    return (((x + row) % 2) == 0) and T(t - 1) or T(t)
  elseif kind == "scale" then
    local sx, sy = (x + (y // 2 % 2) * 2) % 4, y % 2
    if sy == 1 and (sx == 0 or sx == 3) then return T(t + 1) end
    if sy == 0 and sx == 1 then return T(t - 1) end
    return T(t)
  elseif kind == "plate" then
    if (x + y) % 7 == 0 and t <= 3 then return T(t - 1) end
    return T(t)
  elseif kind == "quilt" then
    if (x + y) % 4 == 0 or (x - y) % 4 == 0 then return T(t + 1) end
    return T(t)
  elseif kind == "brocade" then
    local mx, my = x % 6, y % 6
    if (mx == 2 or mx == 3) and (my == 2 or my == 3) then return cc2 and tone(cc2, t) or T(t - 2) end
    if (mx + my) % 6 == 0 then return T(t + 1) end
    return T(t)
  elseif kind == "embroidery" then
    if y % 5 == 0 and x % 2 == 0 then return cc2 and tone(cc2, t) or T(t - 2) end
    return T(t)
  elseif kind == "fur" then
    local n = P.noise(x, y, 61)
    if n < 0.3 then return T(t + 1) elseif n > 0.82 then return T(t - 1) end
    return T(t)
  elseif kind == "leather" then
    if P.noise(x, y, 67) > 0.9 then return T(t + 1) end
    return T(t)
  elseif kind == "stripes" then
    if x % 4 < 2 then return cc2 and tone(cc2, t) or T(t + 1) end
    return T(t)
  end
  return T(t)
end
M.mat = mat

-- cylinder shading index across a width (x0..x1), lit from the left
local function cyl(x, x0, x1)
  local f = (x - x0) / math.max(1, x1 - x0)
  if f < 0.12 then return 2 elseif f < 0.55 then return 3 elseif f < 0.82 then return 4 end
  return 5
end
M.cyl = cyl
local function put(K, x, y, c) if c then P.put(K, x, y, c) end end
local INK = P.hex("#2a1e24")

---------------------------------------------------------------------------------------------- legs
local function leg(K, st, x0, hipy, dx, lift, back)
  local footy = -1 - lift
  local legc = col(st.legs) or C.brown
  local bootc = col(st.boots) or C.brown_dark
  local lpat = st.legs_pattern or "cloth"
  local boot_h = st.boot_h or 7
  local sh = back and 1 or 0
  local n = footy - hipy
  for y = hipy, footy do
    local t = (n == 0) and 1 or (y - hipy) / n
    local xo = math.floor(dx * t + 0.5)
    local is_boot = y > footy - boot_h
    local c = is_boot and bootc or legc
    for i = 0, 4 do
      local s = cyl(i, 0, 4) + sh
      if y == hipy + math.floor(n * 0.5) and not is_boot then s = s + 1 end
      put(K, x0 + xo + i, y, is_boot and mat(st.boot_pattern or "leather", c, s, x0 + i, y) or mat(lpat, c, s, x0 + xo + i, y, st.legs2))
    end
    if st.leg_wraps and not is_boot and (y - hipy) > n * 0.45 and (y + xo) % 3 == 0 then
      for i = 0, 4 do put(K, x0 + xo + i, y, tone(col(st.leg_wraps), 4 + sh)) end
    end
  end
  local xo = math.floor(dx + 0.5)
  put(K, x0 + xo - 1, footy, tone(bootc, 3 + sh)); put(K, x0 + xo - 2, footy, tone(bootc, 4 + sh))
  for i = -1, 4 do put(K, x0 + xo + i, footy, tone(bootc, 5)) end
  if st.boots_cuff then for i = 0, 4 do put(K, x0 + xo + i, footy - boot_h + 1, tone(col(st.boots_cuff), 3 + sh)) end end
end

---------------------------------------------------------------------------------------------- torso
local function torso(K, st, p)
  local b, lean = p.bob, p.lean
  local top, waist = -38 + b, -22 + b
  local x0, x1 = -8 + lean - math.max(0, st.build_px or 0), 7 + lean + math.min(0, st.build_px or 0)   -- physique.lua build
  local akind = st.armor_kind or (st.armor and "mail") or "cloth"
  local base = col(st.armor) or col(st.shirt) or C.cream
  P.use(K, (akind ~= "cloth") and "armor" or "body")
  for y = top, waist do
    local w0, w1 = x0, x1
    if y == top then w0, w1 = x0 + 2, x1 - 2 elseif y == top + 1 then w0, w1 = x0 + 1, x1 - 1 end
    for x = w0, w1 do
      local s = cyl(x, x0, x1)
      if y > waist - 3 then s = s + 1 end
      put(K, x, y, mat(akind, base, s, x, y, st.armor2))
    end
  end
  P.use(K, "body")
  local oc = col(st.coat)
  if oc then
    local okind = st.coat_kind or "tabard"
    local ctop = top + (st.coat_top or 2)
    local len = st.coat_len or 6
    for y = ctop, waist + len do
      local below = y > waist
      local narrow = (okind == "tabard" and not below) and 1 or 0
      local w0 = x0 + narrow - (below and math.min(2, (y - waist) // 3) or 0)
      local w1 = x1 - narrow + (below and math.min(1, (y - waist) // 4) or 0)
      for x = w0, w1 do
        local s = cyl(x, w0, w1)
        if below and (x - w0) % 4 == 2 and y > waist + 2 then s = s + 1 end
        local v = mat(st.coat_pattern or "cloth", oc, s, x, y, st.coat2)
        if st.coat_open and below and x >= w0 + 4 and x <= w0 + 5 then v = nil end
        if okind == "kaftan" and not below and x == x0 + 4 then v = tone(oc, 5) end   -- front closure
        put(K, x, y, v)
      end
    end
    local trim = col(st.trim)
    if trim then
      for y = ctop, waist + len do put(K, x0 + 3, y, tone(trim, (y % 3 == 0) and 2 or 3)) end
      for x = x0 - 2, x1 + 1 do put(K, x, waist + len, tone(trim, 3)) end
      if st.collar then for x = x0 + 2, x1 - 2 do put(K, x, ctop, tone(trim, 2)) end end
    end
    if st.coat_emblem then M.emblem(K, x0 + 6, top + 8, st.coat_emblem, col(st.coat_emblem_color) or C.gold, 1) end
  end
  local cape = col(st.cape)
  if cape then for y = top + 1, waist + (st.cape_len or 10) do for x = x1 - 1, x1 + 2 do put(K, x, y, tone(cape, (x == x1 - 1) and 3 or 4)) end end end
  local belt = col(st.belt)
  if belt then
    for x = x0, x1 do put(K, x, waist - 1, tone(belt, cyl(x, x0, x1))); put(K, x, waist, tone(belt, cyl(x, x0, x1) + 1)) end
    if st.buckle then local bc = col(st.buckle) P.rect(K, x0 + 3, waist - 1, x0 + 4, waist, bc); put(K, x0 + 3, waist - 1, tone(bc, 1)) end
    if st.pouch then P.rect(K, x1 - 3, waist + 1, x1 - 1, waist + 3, tone(col(st.pouch), 3)); put(K, x1 - 3, waist + 1, tone(col(st.pouch), 2)) end
  end
  local sash = col(st.sash)
  if sash then
    for x = x0, x1 do for y = waist - 2, waist do put(K, x, y, tone(sash, cyl(x, x0, x1) + ((y == waist) and 1 or 0))) end end
    P.rect(K, x1 - 1, waist + 1, x1, waist + 5, tone(sash, 4))
  end
  local cb = col(st.crossbelt)
  if cb then for i = 0, 14 do put(K, x1 - 2 - i, top + 2 + i, tone(cb, 3)); put(K, x1 - 1 - i, top + 2 + i, tone(cb, 4)) end end
  local sh = col(st.shoulders)
  if sh then
    P.use(K, "armor")
    local sk = st.shoulders_kind or "plate"
    for y = top - 1, top + 6 do for x = x0 - 3, x0 + 4 do
      if (x - (x0 + 1)) ^ 2 / 14 + (y - (top + 2)) ^ 2 / 16 <= 1 then put(K, x, y, mat(sk, sh, (x < x0 + 1) and 2 or 3, x, y, st.shoulders2)) end
    end end
    P.use(K, "body")
  end
  local skin = col(st.skin) or C.skin
  P.rect(K, -4 + lean, top - 2, -1 + lean, top, tone(skin, 4))
end

---------------------------------------------------------------------------------------------- head
-- face in the 3/4 front-left view: box hx..hx+11, hy..hy+12
local function face(K, st, hx, hy, opt)
  opt = opt or {}
  local skin = col(st.skin) or C.skin
  local hair = col(st.hair) or C.hair_brown
  local R = ramp5(skin)
  for y = hy, hy + 12 do for x = hx, hx + 11 do
    local cx, cy = x - (hx + 5.5), y - (hy + 6)
    local inside = (cx * cx) / 36 + (cy * cy) / 46 <= 1
    if y >= hy + 10 and x > hx + 8 then inside = false end
    if inside then
      local s = 3
      if x <= hx + 1 then s = 2 elseif x >= hx + 8 then s = 4 end
      if y >= hy + 11 then s = s + 1 end
      put(K, x, y, R[s])
    end
  end end
  if not opt.no_hair then
    local style = st.hair_style or "short"
    if style == "shaved" or style == "mongol" then
      put(K, hx + 9, hy + 3, tone(hair, 3)); put(K, hx + 3, hy + 2, tone(hair, 3)); put(K, hx + 4, hy + 2, tone(hair, 3))  -- forelock
      if style == "mongol" then for y = hy + 6, hy + 12 do put(K, hx + 8, y, tone(hair, (y % 2 == 0) and 3 or 4)) end; P.rect(K, hx + 7, hy + 11, hx + 9, hy + 12, tone(hair, 4)) end
    else
      for y = hy, hy + 4 do for x = hx + 1, hx + 11 do
        if ((y == hy and x > hx + 2 and x < hx + 10) or y > hy) and not (y >= hy + 3 and x < hx + 5) then put(K, x, y, tone(hair, (x > hx + 8) and 4 or 3)) end
      end end
      for y = hy + 4, hy + 9 do for x = hx + 8, hx + 11 do put(K, x, y, tone(hair, 4)) end end
      if style == "long" then for y = hy + 9, hy + 15 do for x = hx + 8, hx + 11 do put(K, x, y, tone(hair, (x == hx + 8) and 3 or 4)) end end end
      if style == "topknot" or style == "bun" then P.rect(K, hx + 6, hy - 3, hx + 9, hy, tone(hair, 3)); put(K, hx + 6, hy - 3, tone(hair, 2)) end
      if style == "bun" then put(K, hx + 7, hy - 4, tone(hair, 2)); put(K, hx + 8, hy - 4, tone(hair, 3)) end
      if style == "bowl" then for x = hx + 1, hx + 4 do put(K, x, hy + 3, tone(hair, 3)) end; put(K, hx + 1, hy + 4, tone(hair, 4)) end  -- straight fringe
      if style == "braids" then for y = hy + 9, hy + 17 do put(K, hx + 9, y, tone(hair, (y % 2 == 0) and 3 or 4)) end end
      put(K, hx + 3, hy + 1, tone(hair, 2))
    end
  end
  put(K, hx + 7, hy + 6, R[4]); put(K, hx + 7, hy + 7, R[4]); put(K, hx + 8, hy + 6, R[5])          -- ear
  local ex, ey = hx + 1, hy + 6
  put(K, ex, ey, C.white); put(K, ex + 1, ey, INK); put(K, ex + 4, ey, C.white); put(K, ex + 5, ey, INK)
  local brow = col(st.brow) or tone(hair, 4)
  for _, x in ipairs({ ex, ex + 1, ex + 4, ex + 5 }) do put(K, x, ey - 2, brow) end
  put(K, hx - 1, ey + 2, R[3]); put(K, hx, ey + 3, R[4])                                           -- nose
  put(K, ex + 1, ey + 5, R[5]); put(K, ex + 2, ey + 5, R[5])                                       -- mouth
  local bstyle = st.beard
  if bstyle and bstyle ~= "none" then
    local bc = col(st.beard_color) or hair
    if bstyle ~= "goatee" then
      put(K, ex, ey + 4, tone(bc, 3)); put(K, ex + 1, ey + 4, tone(bc, 3)); put(K, ex + 2, ey + 4, tone(bc, 4)); put(K, ex - 1, ey + 5, tone(bc, 3))
    end
    if bstyle == "moustache_long" then put(K, ex - 1, ey + 6, tone(bc, 3)); put(K, ex + 3, ey + 5, tone(bc, 4)); put(K, ex + 3, ey + 6, tone(bc, 4)) end
    if bstyle == "braided" then                     -- Norse: a long beard bound into a braid with a ring
      for y = ey + 5, ey + 8 do for x = hx, hx + 7 do
        if not (y == ey + 5 and (x == ex + 1 or x == ex + 2)) and x < hx + 7 - (y - ey - 5) then put(K, x, y, tone(bc, (x > hx + 5) and 4 or 3)) end
      end end
      for y = ey + 9, ey + 11 do put(K, ex + 1, y, tone(bc, 3)); put(K, ex + 2, y, tone(bc, 4)) end
      put(K, ex + 1, ey + 12, C.gold); put(K, ex + 2, ey + 12, tone(C.gold, 4))
    end
    if bstyle == "full" or bstyle == "short" then
      local len = (bstyle == "full") and 4 or 2
      for y = ey + 5, ey + 5 + len do for x = hx, hx + 7 do
        if not (y == ey + 5 and (x == ex + 1 or x == ex + 2)) and (y < ey + 5 + len or x < hx + 6) then put(K, x, y, tone(bc, (x > hx + 5) and 4 or 3)) end
      end end
    end
    if bstyle == "goatee" then put(K, ex + 1, ey + 6, tone(bc, 3)); put(K, ex + 1, ey + 7, tone(bc, 4)); put(K, ex, ey + 4, tone(bc, 3)); put(K, ex + 2, ey + 4, tone(bc, 3)) end
  end
end
M.face = face

local HATS = {}
M.HATS = HATS
-- helmet bowl over the head box, centred on hx + 5.5
local function dome(K, hx, hy, w, h, c, kind, c2)
  for y = hy - h, hy + 2 do for x = hx - 1, hx + 12 do
    local cx, cy = (x - (hx + 5.5)) / (w / 2), (y - (hy + 2)) / (h + 2)
    if cx * cx + cy * cy <= 1 then
      local s = (x < hx + 3) and 2 or ((x > hx + 8) and 4 or 3)
      if y == hy - h + 1 and x > hx + 2 and x < hx + 8 then s = 1 end
      put(K, x, y, mat(kind or "plate", c, s, x, y, c2))
    end
  end end
end
M.dome = dome

HATS.none = function(K, st, hx, hy) face(K, st, hx, hy) end
HATS.hood = function(K, st, hx, hy)
  local c = col(st.hat_color) or C.linen
  for y = hy - 2, hy + 14 do for x = hx - 1, hx + 13 do
    local cx, cy = (x - (hx + 6)) / 7.5, (y - (hy + 6)) / 9
    if cx * cx + cy * cy <= 1 then put(K, x, y, tone(c, (x < hx + 2) and 2 or ((x > hx + 9) and 4 or 3))) end
  end end
  P.rect(K, hx + 9, hy - 3, hx + 13, hy + 2, tone(c, 4)); P.rect(K, hx + 12, hy + 2, hx + 14, hy + 8, tone(c, 4))
  for x = hx - 3, hx + 14 do for y = hy + 13, hy + 16 do put(K, x, y, tone(c, (x < hx) and 2 or ((x > hx + 10) and 4 or 3))) end end
  face(K, st, hx, hy + 1, { no_hair = true })
  for y = hy, hy + 12 do for x = hx + 8, hx + 12 do put(K, x, y, tone(c, 4)) end end
  local lin = col(st.hood_lining)
  if lin then for x = hx, hx + 6 do put(K, x, hy + 1, tone(lin, 3)) end end
end
HATS.coif_only = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  P.use(K, "armor")
  local mc = col(st.coif) or C.iron
  for y = hy - 1, hy + 15 do for x = hx - 1, hx + 13 do
    local cx, cy = (x - (hx + 6)) / 7.2, (y - (hy + 6)) / 9.5
    local in_face = x >= hx and x <= hx + 6 and y >= hy + 3 and y <= hy + 11
    if cx * cx + cy * cy <= 1 and not in_face then put(K, x, y, mat("mail", mc, (x < hx + 3) and 2 or 3, x, y)) end
  end end
  P.use(K, "body")
end
HATS.nasal = function(K, st, hx, hy)
  if st.coif then HATS.coif_only(K, st, hx, hy) else face(K, st, hx, hy, { no_hair = true }) end
  P.use(K, "armor")
  local c = col(st.hat_color) or C.steel
  dome(K, hx, hy, 14, 6, c, "plate")
  P.rect(K, hx + 5, hy - 6, hx + 6, hy - 5, tone(c, 2))
  local band = col(st.helm_band)
  if band then for x = hx - 1, hx + 12 do put(K, x, hy + 2, tone(band, (x < hx + 3) and 2 or 3)) end end
  for y = hy + 2, hy + 7 do put(K, hx + 2, y, tone(c, 2)); put(K, hx + 3, y, tone(c, 4)) end
  P.use(K, "body")
end
HATS.spangen = function(K, st, hx, hy)
  HATS.nasal(K, st, hx, hy)
  P.use(K, "armor")
  local b = col(st.helm_band) or C.bronze
  for y = hy - 6, hy + 2 do put(K, hx + 5, y, tone(b, 3)); put(K, hx + 6, y, tone(b, 4)) end
  for x = hx - 1, hx + 12 do put(K, x, hy + 2, tone(b, 3)) end
  put(K, hx + 2, hy - 1, tone(b, 1)); put(K, hx + 9, hy - 1, tone(b, 1))
  if st.spectacle then
    local c = col(st.hat_color) or C.iron
    P.rect(K, hx - 1, hy + 3, hx + 6, hy + 4, tone(c, 3)); put(K, hx + 1, hy + 4, INK); put(K, hx + 4, hy + 4, INK)
  end
  P.use(K, "body")
end
HATS.kettle = function(K, st, hx, hy)
  if st.coif then HATS.coif_only(K, st, hx, hy) else face(K, st, hx, hy, { no_hair = true }) end
  P.use(K, "armor")
  local c = col(st.hat_color) or C.iron
  dome(K, hx, hy, 12, 5, c, "plate")
  for x = hx - 4, hx + 15 do put(K, x, hy + 2, tone(c, (x < hx) and 2 or 4)); put(K, x, hy + 3, tone(c, 5)) end
  P.use(K, "body")
end
HATS.great = function(K, st, hx, hy)
  P.use(K, "armor")
  local c = col(st.hat_color) or C.steel
  for y = hy - 3, hy + 13 do for x = hx - 1, hx + 12 do
    if not (y == hy - 3 and (x == hx - 1 or x == hx + 12)) then
      put(K, x, y, mat("plate", c, (x < hx + 2) and 2 or ((x > hx + 8) and 4 or 3), x, y))
    end
  end end
  for x = hx - 1, hx + 7 do put(K, x, hy + 5, P.hex("#1a1420")); put(K, x, hy + 6, tone(c, 5)) end
  for y = hy + 8, hy + 12, 2 do for x = hx, hx + 4, 2 do put(K, x, y, tone(c, 5)) end end
  local band = col(st.helm_band)
  if band then for y = hy - 3, hy + 13 do put(K, hx + 3, y, tone(band, 3)) end; for x = hx - 1, hx + 7 do put(K, x, hy + 8, tone(band, 3)) end end
  if st.helm_crest then local cc = col(st.helm_crest) P.rect(K, hx + 3, hy - 7, hx + 8, hy - 4, tone(cc, 3)); P.rect(K, hx + 3, hy - 7, hx + 4, hy - 4, tone(cc, 2)) end
  P.use(K, "body")
end
HATS.turban = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  local c = col(st.hat_color) or C.white
  local cap = col(st.hat_cap)
  if cap then dome(K, hx + 2, hy - 5, 8, 5, cap, "cloth") end
  for y = hy - 5, hy + 3 do for x = hx - 2, hx + 13 do
    local cx, cy = (x - (hx + 5.5)) / 7.6, (y - (hy - 1)) / 4.6
    if cx * cx + cy * cy <= 1 and not (cap and y < hy - 3 and math.abs(x - (hx + 6)) < 3) then
      put(K, x, y, tone(c, (x < hx + 1) and 2 or ((x > hx + 9) and 4 or ((((x + y * 2) % 6) < 2) and 4 or 3))))
    end
  end end
  if st.turban_helmet then dome(K, hx + 3, hy - 6, 6, 3, col(st.turban_helmet), "plate"); put(K, hx + 6, hy - 10, tone(col(st.turban_helmet), 2)) end
  if st.hat_jewel then put(K, hx + 1, hy - 1, col(st.hat_jewel)) end
end
HATS.bork = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  local c = col(st.hat_color) or C.white
  for y = hy - 14, hy + 2 do for x = hx + 1, hx + 10 do put(K, x, y, tone(c, (x < hx + 3) and 2 or ((x > hx + 8) and 4 or 3))) end end
  for y = hy - 10, hy + 10 do for x = hx + 10, hx + 13 do put(K, x, y, tone(c, 4)) end end
  local band = col(st.hat_band) or C.gold
  for x = hx, hx + 11 do put(K, x, hy + 1, tone(band, 3)); put(K, x, hy + 2, tone(band, 4)) end
  P.rect(K, hx + 3, hy - 8, hx + 5, hy, tone(band, 2))                                       -- spoon holder (kaşıklık)
  if st.plume then for i = 0, 6 do put(K, hx + 4 - i // 2, hy - 15 - i, tone(col(st.plume), 2 + i % 2)) end end
end
HATS.kabuto = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  if st.mask then local mc = col(st.mask) P.rect(K, hx - 1, hy + 8, hx + 6, hy + 12, tone(mc, 3)); P.hline(K, hx, hx + 5, hy + 10, tone(mc, 5)) end
  P.use(K, "armor")
  local c = col(st.hat_color) or C.lacquer_black
  for row = 0, 3 do for x = hx + 5 + row, hx + 14 + row do for y = hy + 2 + row * 3, hy + 4 + row * 3 do
    put(K, x, y, mat("lamellar", c, (row % 2 == 0) and 3 or 4, x, y, st.lacing or "red"))
  end end end
  dome(K, hx, hy, 14, 5, c, "plate")
  for x = hx - 2, hx + 2 do for y = hy + 1, hy + 4 do put(K, x, y, tone(c, 3)) end end      -- fukigaeshi
  local cr = col(st.crest) or C.gold
  for i = 0, 5 do put(K, hx + 3 - i, hy - 4 - i, tone(cr, 2)); put(K, hx + 7 + i // 2, hy - 4 - i, tone(cr, 3)) end
  put(K, hx + 5, hy - 4, tone(cr, 1)); put(K, hx + 5, hy - 5, tone(cr, 2))
  P.use(K, "body")
end
HATS.jingasa = function(K, st, hx, hy)
  face(K, st, hx, hy)
  local c = col(st.hat_color) or C.lacquer_black
  for i = 0, 6 do
    local w = 3 + i * 2
    for x = hx + 6 - w, hx + 5 + w do put(K, x, hy - 5 + i, tone(c, (x < hx + 9 - w) and 2 or ((x > hx + 1 + w) and 4 or 3))) end
  end
  for x = hx - 6, hx + 17 do put(K, x, hy + 2, tone(c, 5)) end
  if st.hat_mon then M.emblem(K, hx + 6, hy - 2, st.hat_mon, col(st.hat_mon_color) or C.gold, 0) end
end
HATS.straw = function(K, st, hx, hy)
  face(K, st, hx, hy)
  local c = col(st.hat_color) or C.straw
  for i = 0, 6 do
    local w = 2 + i * 2
    for x = hx + 6 - w, hx + 5 + w do
      local s = (x < hx + 9 - w) and 2 or ((x > hx + 1 + w) and 4 or 3)
      if (x + i) % 3 == 0 then s = s + 1 end
      put(K, x, hy - 4 + i, tone(c, s))
    end
  end
  for x = hx - 6, hx + 17 do put(K, x, hy + 3, tone(c, 5)) end
  for x = hx - 1, hx + 8 do put(K, x, hy + 4, tone(col(st.skin) or C.skin, 4)) end
end
HATS.conical = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  P.use(K, "armor")
  local c = col(st.hat_color) or C.steel
  local av = col(st.aventail)
  if av then for y = hy + 2, hy + 14 do for x = hx + 6, hx + 13 do put(K, x, y, mat(st.aventail_kind or "lamellar", av, (x > hx + 10) and 4 or 3, x, y, st.lacing)) end end end
  for i = 0, 8 do
    local w = 1 + math.floor(i * 0.8)
    for x = hx + 6 - w, hx + 5 + w do put(K, x, hy - 7 + i, mat("plate", c, (x <= hx + 7 - w) and 2 or ((x >= hx + 4 + w) and 4 or 3), x, hy - 7 + i)) end
  end
  P.rect(K, hx + 5, hy - 11, hx + 6, hy - 8, tone(c, 2))
  local rim = col(st.hat_rim)
  if rim then for x = hx - 2, hx + 13 do put(K, x, hy + 2, mat(st.rim_kind or "fur", rim, (x < hx + 2) and 2 or 3, x, hy + 2)); put(K, x, hy + 3, mat(st.rim_kind or "fur", rim, 4, x, hy + 3)) end end
  if st.plume then local pc = col(st.plume) for i = 0, 5 do put(K, hx + 6 + (i % 2), hy - 12 - i, tone(pc, 2 + i % 3)) end end
  P.use(K, "body")
end
HATS.fur = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  local c = col(st.hat_color) or C.fur
  for y = hy - 5, hy + 3 do for x = hx - 2, hx + 13 do
    local cx, cy = (x - (hx + 5.5)) / 7.5, (y - (hy - 1)) / 4.8
    if cx * cx + cy * cy <= 1 + (P.noise(x, y, 41) - 0.5) * 0.3 then put(K, x, y, mat("fur", c, (x < hx + 2) and 2 or ((x > hx + 9) and 4 or 3), x, y)) end
  end end
  local top = col(st.hat_cap)
  if top then dome(K, hx + 2, hy - 5, 8, 4, top, "cloth"); put(K, hx + 6, hy - 10, col(st.hat_knob) or C.gold) end
  if st.ear_flaps then P.rect(K, hx + 8, hy + 3, hx + 12, hy + 10, tone(c, 4)) end
  if st.wolf then
    P.rect(K, hx - 4, hy - 1, hx, hy + 2, tone(c, 3)); put(K, hx - 4, hy + 1, INK)
    P.rect(K, hx + 2, hy - 8, hx + 3, hy - 5, tone(c, 4)); P.rect(K, hx + 7, hy - 8, hx + 8, hy - 5, tone(c, 4))
    for y = hy + 3, hy + 18 do for x = hx + 9, hx + 14 do put(K, x, y, mat("fur", c, 4, x, y)) end end
  end
end
HATS.cap = function(K, st, hx, hy)
  face(K, st, hx, hy)
  local c = col(st.hat_color) or C.brown
  dome(K, hx, hy, 13, 4, c, "cloth")
  for x = hx - 1, hx + 12 do put(K, x, hy + 2, tone(c, 4)) end
  if st.cap_kind == "futou" then P.rect(K, hx + 3, hy - 7, hx + 8, hy - 3, tone(c, 3)); P.rect(K, hx + 9, hy - 3, hx + 16, hy - 2, tone(c, 4)) end
  if st.cap_kind == "phrygian" then P.rect(K, hx + 1, hy - 7, hx + 5, hy - 4, tone(c, 3)); put(K, hx, hy - 6, tone(c, 2)) end
end
HATS.headband = function(K, st, hx, hy)
  face(K, st, hx, hy)
  local c = col(st.hat_color) or C.white
  for x = hx, hx + 11 do put(K, x, hy + 3, tone(c, (x < hx + 3) and 2 or 3)) end
  P.rect(K, hx + 11, hy + 3, hx + 13, hy + 7, tone(c, 4))
end
HATS.byz = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  P.use(K, "armor")
  local c = col(st.hat_color) or C.steel
  local av = col(st.aventail)
  if av then for y = hy + 2, hy + 14 do for x = hx + 5, hx + 13 do put(K, x, y, mat(st.aventail_kind or "mail", av, (x > hx + 10) and 4 or 3, x, y)) end end end
  if st.mail_veil then for y = hy + 4, hy + 12 do for x = hx - 1, hx + 6 do put(K, x, y, mat("mail", col(st.mail_veil), (x < hx + 1) and 2 or 3, x, y)) end end end
  dome(K, hx, hy, 14, 6, c, "plate")
  local band = col(st.helm_band) or C.gold
  for x = hx - 1, hx + 12 do put(K, x, hy + 2, tone(band, 3)) end
  put(K, hx + 3, hy - 3, tone(band, 2)); put(K, hx + 8, hy - 3, tone(band, 3))
  if st.plume then local pc = col(st.plume) for i = 0, 9 do local yy = hy - 7 - math.floor(math.sin(i / 9 * math.pi) * 3) put(K, hx + 3 + i, yy, tone(pc, 2)); put(K, hx + 3 + i, yy + 1, tone(pc, 3)) end end
  P.use(K, "body")
end
HATS.chinese = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  P.use(K, "armor")
  local c = col(st.hat_color) or C.steel
  local av = col(st.aventail) or c
  for y = hy + 1, hy + 12 do for x = hx + 6, hx + 13 do put(K, x, y, mat("lamellar", av, (x > hx + 10) and 4 or 3, x, y, st.lacing)) end end
  dome(K, hx, hy, 14, 6, c, "plate")
  for x = hx - 2, hx + 13 do put(K, x, hy + 2, tone(c, 4)) end
  P.rect(K, hx + 5, hy - 9, hx + 6, hy - 6, tone(col(st.helm_band) or C.gold, 2))
  local ts = col(st.plume) or C.red
  for y = hy - 13, hy - 9 do for x = hx + 3, hx + 8 do if (x - (hx + 5.5)) ^ 2 + (y - (hy - 10)) ^ 2 < 9 then put(K, x, y, tone(ts, (x < hx + 5) and 2 or 3)) end end end
  P.use(K, "body")
end
HATS.mongol_hat = function(K, st, hx, hy)
  face(K, st, hx, hy, { no_hair = true })
  local c = col(st.hat_color) or C.felt
  dome(K, hx + 1, hy - 3, 10, 6, c, "cloth")
  local brim = col(st.hat_rim) or C.fur
  for x = hx - 2, hx + 13 do put(K, x, hy + 1, mat("fur", brim, 3, x, hy + 1)); put(K, x, hy + 2, mat("fur", brim, 4, x, hy + 2)) end
  put(K, hx + 6, hy - 10, col(st.hat_knob) or C.red)
  if st.ribbons then P.rect(K, hx + 11, hy + 3, hx + 12, hy + 12, tone(col(st.ribbons), 3)) end
end
HATS.mamluk = function(K, st, hx, hy)                         -- red / yellow cap (kalawta) with a turban wound round
  face(K, st, hx, hy, { no_hair = true })
  local cap = col(st.hat_cap) or C.red
  dome(K, hx + 1, hy - 6, 10, 6, cap, "cloth")
  local c = col(st.hat_color) or C.white
  for y = hy - 3, hy + 3 do for x = hx - 2, hx + 13 do
    local cx, cy = (x - (hx + 5.5)) / 7.6, (y - (hy)) / 3.6
    if cx * cx + cy * cy <= 1 then put(K, x, y, tone(c, (x < hx + 1) and 2 or ((x > hx + 9) and 4 or ((((x + y * 2) % 6) < 2) and 4 or 3)))) end
  end end
  if st.turban_helmet then P.use(K, "armor"); dome(K, hx + 2, hy - 7, 8, 5, col(st.turban_helmet), "plate"); put(K, hx + 6, hy - 13, tone(col(st.turban_helmet), 2)); P.use(K, "body") end
end

local function head(K, st, p)
  local hx, hy = -7 + p.lean + (p.hlean or 0), -52 + p.bob
  P.use(K, "body")
  ;(HATS[st.hat or "none"] or HATS.none)(K, st, hx, hy)
  local plume = col(st.plume)
  if plume and (st.hat == "great" or st.hat == "nasal" or st.hat == "kettle" or st.hat == "spangen") then
    for i = 0, 7 do put(K, hx + 6 + i // 2, hy - 6 - i, tone(plume, 2 + i % 2)); put(K, hx + 7 + i // 2, hy - 6 - i, tone(plume, 3 + i % 2)) end
  end
end

---------------------------------------------------------------------------------------------- arms
local function arm(K, st, sx, sy, a, back, len)
  len = len or 13
  local sleeve = col(st.sleeve) or col(st.armor) or col(st.shirt) or C.cream
  local skind = st.sleeve_kind or "cloth"
  local hx, hy = P.along(sx, sy, a, len)
  local ex, ey = P.along(sx, sy, a, 7)
  local sh = back and 1 or 0
  P.use(K, (skind ~= "cloth") and "armor" or "body")
  local segs = { { sx, sy, ex, ey, sleeve, skind }, { ex, ey, hx, hy, col(st.bracers) or sleeve, st.bracers and "leather" or skind } }
  for _, seg in ipairs(segs) do
    local n = math.max(1, math.floor(math.sqrt((seg[3] - seg[1]) ^ 2 + (seg[4] - seg[2]) ^ 2)))
    for k = 0, n do
      local x = seg[1] + (seg[3] - seg[1]) * k / n
      local y = seg[2] + (seg[4] - seg[2]) * k / n
      for ox = -1, 1 do for oy = -1, 1 do
        local s = 3 + sh + ((ox > 0) and 1 or 0) - ((ox < 0 and oy < 0) and 1 or 0)
        put(K, math.floor(x + ox + 0.5), math.floor(y + oy + 0.5), mat(seg[6], seg[5], s, math.floor(x + ox), math.floor(y + oy)))
      end end
    end
  end
  P.use(K, "body")
  local hand = col(st.gloves) or col(st.skin) or C.skin
  local hxi, hyi = math.floor(hx + 0.5), math.floor(hy + 0.5)
  P.rect(K, hxi - 1, hyi - 1, hxi + 1, hyi + 1, tone(hand, 3 + sh))
  put(K, hxi - 1, hyi - 1, tone(hand, 2 + sh)); put(K, hxi + 1, hyi + 1, tone(hand, 4 + sh))
  return hxi, hyi
end

---------------------------------------------------------------------------------------------- emblems
-- small heraldic emblems at (cx, cy); size 0 = 5 px, 1 = 7 px
function M.emblem(K, cx, cy, e, c, size)
  local s = size or 1
  local function p(x, y) put(K, cx + x, cy + y, c) end
  if e == "cross" then for i = -2 - s, 2 + s do p(0, i); p(i, -1) end
  elseif e == "cross_pattee" then for i = -3, 3 do p(0, i); p(i, 0) end; for _, q in ipairs({ { -1, -3 }, { 1, -3 }, { -1, 3 }, { 1, 3 }, { -3, -1 }, { -3, 1 }, { 3, -1 }, { 3, 1 } }) do p(q[1], q[2]) end
  elseif e == "fleur" then for _, q in ipairs({ { 0, -3 }, { 0, -2 }, { 0, -1 }, { -1, -1 }, { 1, -1 }, { -2, -2 }, { 2, -2 }, { -2, 0 }, { 2, 0 }, { -2, 1 }, { -1, 1 }, { 0, 1 }, { 1, 1 }, { 2, 1 }, { 0, 2 }, { -1, 3 }, { 1, 3 } }) do p(q[1], q[2]) end
  elseif e == "lions" then for i = 0, 2 do local y = -3 + i * 3 for x = -2, 1 do p(x, y) end; p(-2, y - 1); p(2, y + 1) end
  elseif e == "eagle" then for _, q in ipairs({ { 0, -3 }, { 0, -2 }, { -3, -2 }, { 3, -2 }, { 0, 0 }, { -1, 1 }, { 1, 1 }, { 0, 2 } }) do p(q[1], q[2]) end; for i = -3, 3 do p(i, -1) end
  elseif e == "chirho" then for i = -3, 3 do p(0, i) end; for _, q in ipairs({ { 1, -3 }, { 2, -2 }, { 1, -1 }, { -2, 0 }, { -1, 1 }, { 1, 1 }, { 2, 0 } }) do p(q[1], q[2]) end
  elseif e == "crescent" then for _, q in ipairs({ { -1, -3 }, { -2, -2 }, { -2, -1 }, { -2, 0 }, { -2, 1 }, { -1, 2 }, { 0, 3 }, { 1, -2 }, { 1, 1 }, { 0, -3 } }) do p(q[1], q[2]) end
  elseif e == "star8" or e == "sun" then for y = -1, 1 do for x = -1, 1 do p(x, y) end end; for _, q in ipairs({ { 0, -3 }, { 0, 3 }, { -3, 0 }, { 3, 0 }, { -2, -2 }, { 2, 2 }, { -2, 2 }, { 2, -2 } }) do p(q[1], q[2]) end
  elseif e == "cup" then for _, q in ipairs({ { -2, -2 }, { 2, -2 }, { -2, -1 }, { 2, -1 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { 0, 1 }, { 0, 2 }, { -1, 3 }, { 0, 3 }, { 1, 3 } }) do p(q[1], q[2]) end; for x = -2, 2 do p(x, -3) end
  elseif e == "tomoe" then for a = 0, 330, 30 do local r = math.rad(a) p(math.floor(math.cos(r) * 3 + 0.5), math.floor(math.sin(r) * 3 + 0.5)) end; p(0, 0); p(1, -1); p(-1, 1); p(1, 1)
  elseif e == "mon" then for a = 0, 330, 30 do local r = math.rad(a) p(math.floor(math.cos(r) * 3 + 0.5), math.floor(math.sin(r) * 3 + 0.5)) end; p(0, 0)
  elseif e == "raven" then for _, q in ipairs({ { -2, -1 }, { -1, -2 }, { 0, -2 }, { 1, -1 }, { 2, -1 }, { 3, -2 }, { 0, -1 }, { 0, 0 }, { -1, 1 }, { 1, 1 }, { -2, 2 }, { 2, 2 } }) do p(q[1], q[2]) end
  elseif e == "tug" then for i = -3, 3 do p(0, i) end; p(-1, 0); p(1, 0); p(-1, 1); p(1, 1); p(-2, 2); p(2, 2); p(-1, 3); p(1, 3)
  elseif e == "hanzi" then for x = -2, 2 do p(x, -3); p(x, 0); p(x, 3) end; for y = -3, 3 do p(-2, y); p(2, y) end; p(0, -2); p(0, -1)
  elseif e == "boss" then for y = -1, 1 do for x = -1, 1 do p(x, y) end end
  elseif e == "band" then for i = -3, 3 do p(i, 0) end
  else for y = -1, 1 do for x = -1, 1 do p(x, y) end end end
end

---------------------------------------------------------------------------------------------- weapons
local W = {}
M.WEAPONS = W
local function pt(x, y, a, len) local px, py = P.along(x, y, a, len) return { px, py } end
local function grip(K, x, y, a, len, c) P.line(K, x, y, pt(x, y, a + 180, len), c or C.wood_dark, 2) end

W.sword = function(K, st, x, y, a, o)
  grip(K, x, y, a, 4, C.brown_dark)
  local px, py = P.along(x, y, a + 180, 5)
  P.rect(K, math.floor(px), math.floor(py), math.floor(px) + 1, math.floor(py) + 1, col(st.guard) or C.gold)
  local gx, gy = P.along(x, y, a, 2)
  P.line(K, pt(gx, gy, a + 90, 4), pt(gx, gy, a - 90, 4), col(st.guard) or C.gold, 1)
  local len = o.len or st.blade_len or 19
  local bx, by = P.along(gx, gy, a, 1)
  P.line(K, bx, by, pt(bx, by, a, len), C.steel, 2)
  P.line(K, bx, by, pt(bx, by, a, len - 2), P.shade(C.steel, 0.78), 1)
  local tx, ty = P.along(bx, by, a, len + 1)
  put(K, math.floor(tx + 0.5), math.floor(ty + 0.5), P.shade(C.steel, 1.2))
end
W.messer = function(K, st, x, y, a, o)                         -- Langes Messer: single edge, nagel on the guard
  grip(K, x, y, a, 5, C.wood_dark)
  P.line(K, pt(x, y, a + 90, 3), pt(x, y, a - 90, 3), C.iron, 1)
  local px, py = x, y
  for i = 2, 20 do
    local cx, cy = P.along(x, y, a, i)
    cx, cy = P.along(cx, cy, a - 90, (i / 20) ^ 3 * 2)
    P.line(K, px, py, cx, cy, C.steel, 2); px, py = cx, cy
  end
end
W.scimitar = function(K, st, x, y, a, o)
  grip(K, x, y, a, 4, C.black_cloth)
  P.line(K, pt(x, y, a + 90, 3), pt(x, y, a - 90, 3), col(st.guard) or C.gold, 1)
  local px, py = x, y
  for i = 2, 18 do
    local cx, cy = P.along(x, y, a, i)
    cx, cy = P.along(cx, cy, a - 90, (i / 18) ^ 2 * 5)
    P.line(K, px, py, cx, cy, C.steel, (i > 13) and 3 or 2); px, py = cx, cy
  end
end
W.dao = function(K, st, x, y, a, o)                            -- Chinese single-edged sabre, red tassel
  W.scimitar(K, st, x, y, a, o)
  local qx, qy = P.along(x, y, a + 180, 5)
  P.rect(K, math.floor(qx) - 1, math.floor(qy), math.floor(qx), math.floor(qy) + 3, C.red)
end
W.katana = function(K, st, x, y, a, o)
  grip(K, x, y, a, 7, C.black_cloth)
  for i = 1, 6, 2 do local qx, qy = P.along(x, y, a + 180, i) put(K, math.floor(qx), math.floor(qy), C.white) end
  P.rect(K, math.floor(x) - 1, math.floor(y) - 1, math.floor(x) + 1, math.floor(y) + 1, C.gold)
  local px, py = P.along(x, y, a, 2)
  for i = 3, 22 do
    local cx, cy = P.along(x, y, a, i)
    cx, cy = P.along(cx, cy, a - 90, (i / 22) ^ 2 * 2.5)
    P.line(K, px, py, cx, cy, C.steel, 2); put(K, math.floor(cx), math.floor(cy), P.shade(C.steel, 1.2))
    px, py = cx, cy
  end
end
W.axe = function(K, st, x, y, a, o)
  local len = o.len or 13
  local ex, ey = P.along(x, y, a, len)
  P.line(K, pt(x, y, a + 180, 3), { ex, ey }, C.wood, 2)
  local h1x, h1y = P.along(ex, ey, a + 180, 4)
  local f1x, f1y = P.along(ex, ey, a + 90, 5)
  local f2x, f2y = P.along(h1x, h1y, a + 90, 5)
  P.poly(K, { { ex, ey }, { f1x, f1y }, { f2x, f2y }, { h1x, h1y } }, C.iron)
  P.line(K, f1x, f1y, f2x, f2y, C.steel, 1)
end
W.dane_axe = function(K, st, x, y, a, o)
  local ex, ey = P.along(x, y, a, 22)
  P.line(K, pt(x, y, a + 180, 6), { ex, ey }, C.wood, 2)
  local h1x, h1y = P.along(ex, ey, a + 180, 7)
  local tx, ty = P.along(ex, ey, a, 2)
  local f1x, f1y = P.along(tx, ty, a + 90, 7)
  local f2x, f2y = P.along(h1x, h1y, a + 90, 5)
  P.poly(K, { { ex, ey }, { f1x, f1y }, { f2x, f2y }, { h1x, h1y } }, C.iron)
  P.line(K, f1x, f1y, f2x, f2y, C.steel, 1)
end
W.hammer = function(K, st, x, y, a, o)
  local ex, ey = P.along(x, y, a, 11)
  P.line(K, x, y, ex, ey, C.wood, 2)
  P.line(K, pt(ex, ey, a + 90, 3), pt(ex, ey, a - 90, 3), C.iron, 3)
end
W.spear = function(K, st, x, y, a, o)
  local fwd, back = o.len or 26, o.back or 14
  local tx, ty = P.along(x, y, a, fwd)
  P.line(K, pt(x, y, a + 180, back), { tx, ty }, col(st.shaft) or C.wood, 2)
  local hx, hy = P.along(x, y, a, fwd + 6)
  P.poly(K, { pt(tx, ty, a + 90, 2), { hx, hy }, pt(tx, ty, a - 90, 2) }, C.steel)
  P.line(K, tx, ty, hx, hy, P.shade(C.steel, 1.2), 1)
  if st.spear_hook then local kx, ky = P.along(tx, ty, a - 90, 3) P.line(K, tx, ty, kx, ky, C.iron, 1); put(K, math.floor(kx), math.floor(ky) + 1, C.iron) end
  local tas = col(st.tassel)
  if tas then local qx, qy = P.along(x, y, a, fwd - 1) P.rect(K, math.floor(qx) - 1, math.floor(qy), math.floor(qx) + 1, math.floor(qy) + 3, tas) end
  local pen = col(st.pennant)
  if pen then
    local qx, qy = P.along(x, y, a, fwd - 3)
    for i = 0, 6 do local ax_, ay_ = P.along(qx, qy, a + 180, i) P.line(K, ax_, ay_, pt(ax_, ay_, a - 90, 7 - i), tone(pen, (i % 2 == 0) and 3 or 4), 1) end
  end
end
W.yari = W.spear
W.lance = function(K, st, x, y, a, o) o.len = o.len or 38; o.back = 12; W.spear(K, st, x, y, a, o) end
W.halberd = function(K, st, x, y, a, o)
  o.len = 26; W.spear(K, st, x, y, a, o)
  local tx, ty = P.along(x, y, a, 22)
  local b1 = pt(tx, ty, a + 90, 6)
  P.poly(K, { { tx, ty }, b1, pt(b1[1], b1[2], a, 5), pt(tx, ty, a, 5) }, C.iron)
  P.line(K, tx, ty, pt(tx, ty, a - 90, 4), C.iron, 2)
end
W.naginata = function(K, st, x, y, a, o)
  local tx, ty = P.along(x, y, a, 22)
  P.line(K, pt(x, y, a + 180, 12), { tx, ty }, C.lacquer_black, 2)
  local px, py = tx, ty
  for i = 1, 9 do
    local cx, cy = P.along(tx, ty, a, i)
    cx, cy = P.along(cx, cy, a - 90, (i / 9) ^ 2 * 3)
    P.line(K, px, py, cx, cy, C.steel, 2); px, py = cx, cy
  end
  P.rect(K, math.floor(tx) - 1, math.floor(ty) - 1, math.floor(tx) + 1, math.floor(ty) + 1, C.gold)
end
W.guandao = function(K, st, x, y, a, o)
  local tx, ty = P.along(x, y, a, 22)
  P.line(K, pt(x, y, a + 180, 12), { tx, ty }, C.red_dark, 2)
  local b1 = pt(tx, ty, a - 90, 4)
  P.poly(K, { { tx, ty }, pt(tx, ty, a, 10), pt(b1[1], b1[2], a, 6), b1 }, C.steel)
  P.rect(K, math.floor(tx) - 1, math.floor(ty) - 1, math.floor(tx) + 1, math.floor(ty) + 1, C.gold)
end
W.mace = function(K, st, x, y, a, o)
  local ex, ey = P.along(x, y, a, 12)
  P.line(K, x, y, ex, ey, C.wood_dark, 2)
  P.ellipse(K, math.floor(ex), math.floor(ey), 2, 2, C.iron); put(K, math.floor(ex) - 1, math.floor(ey) - 1, C.steel)
end
-- bows held upright in the front hand; o.draw = string pull (px), o.arrow
W.bow = function(K, st, x, y, a, o)
  local kind = st.bow or "recurve"
  local up, down = 10, 10
  if kind == "long" then up, down = 18, 18 elseif kind == "yumi" then up, down = 24, 12 elseif kind == "short" then up, down = 9, 9 end
  local bc = col(st.bow_color) or C.wood
  local prev
  for t = -up, down do
    local f = (t < 0) and (t / up) or (t / down)
    local bulge = 3.5 * (1 - f * f)
    if kind == "recurve" and math.abs(f) > 0.8 then bulge = bulge - (math.abs(f) - 0.8) * 10 end
    local px, py = x - math.floor(bulge + 0.5) + 1, y + t
    if prev then P.line(K, prev[1], prev[2], px, py, bc, 2) end
    prev = { px, py }
  end
  local sx = x + 2 + (o.draw or 0)
  P.line(K, x + 1, y - up, sx, y, C.cream, 1); P.line(K, sx, y, x + 1, y + down, C.cream, 1)
  if kind == "yumi" then P.rect(K, x - 1, y - 1, x + 1, y + 1, C.red_dark) end
  if o.arrow then
    P.hline(K, x - 6, sx, y, C.wood_light)
    P.poly(K, { { x - 9, y }, { x - 6, y - 2 }, { x - 6, y + 2 } }, C.steel)
    P.rect(K, sx - 1, y - 2, sx, y + 2, C.white)
  end
end
W.crossbow = function(K, st, x, y, a, o)
  P.rect(K, x - 12, y - 1, x + 4, y, C.wood); P.hline(K, x - 12, x + 4, y - 1, C.wood_light)
  P.line(K, x - 10, y - 6, x - 10, y + 5, C.wood_dark, 2)
  if st.repeater then P.rect(K, x - 9, y - 8, x - 3, y - 2, C.wood); P.hline(K, x - 9, x - 3, y - 8, C.wood_light); P.line(K, x - 2, y - 7, x + 3, y - 1, C.wood_dark, 1) end
  if o.arrow then P.hline(K, x - 15, x - 8, y - 2, C.steel) end
end
W.musket = function(K, st, x, y, a, o)
  local tx, ty = P.along(x, y, a, 22)
  P.line(K, pt(x, y, a + 180, 9), { x, y }, C.wood, 3)
  P.line(K, x, y, tx, ty, C.iron_dark, 2)
  P.line(K, x, y, pt(x, y, a, 18), C.wood, 1)
  P.rect(K, math.floor(x) + 1, math.floor(y) - 2, math.floor(x) + 2, math.floor(y) - 1, C.gold)
  if st.match_cord then put(K, math.floor(x) + 2, math.floor(y) - 3, C.orange) end
  if o.flash then local fx, fy = P.along(tx, ty, a, 3) P.ellipse(K, math.floor(fx), math.floor(fy), 2, 2, C.yellow); put(K, math.floor(fx), math.floor(fy), C.white) end
  if o.smoke then local fx, fy = P.along(tx, ty, a, 4 + o.smoke * 2) P.ellipse(K, math.floor(fx), math.floor(fy) - o.smoke, 2 + o.smoke, 2, C.grey_cloth) end
end

---------------------------------------------------------------------------------------------- shields
local function shield(K, st, cx, cy)
  P.use(K, "armor")
  local field = col(st.shield_color) or C.TEAM
  local rim = col(st.shield_rim) or C.wood_dark
  local shape = st.shield
  local function inside(x, y)
    if shape == "round" then return (x * x + y * y) <= 49 end
    if shape == "small_round" then return (x * x + y * y) <= 25 end
    if shape == "heater" then
      if y < -7 or y > 9 or math.abs(x) > 6 then return false end
      if y > 2 then return math.abs(x) <= 6 - (y - 2) * 0.9 end
      return true
    end
    if shape == "kite" then
      if y < -8 or y > 13 or math.abs(x) > 6 then return false end
      if y < -5 then return math.abs(x) <= 6 - (-5 - y) end
      if y > 0 then return math.abs(x) <= 6 - y * 0.46 end
      return true
    end
    if shape == "oval" then return (x * x) / 30 + (y * y) / 90 <= 1 end
    if shape == "rect" or shape == "pavise" then return math.abs(x) <= 6 and y >= -9 and y <= 9 end
    if shape == "tall" then return math.abs(x) <= 6 and y >= -11 and y <= 11 and not (math.abs(x) == 6 and math.abs(y) >= 10) end
    return false
  end
  for y = -14, 14 do for x = -8, 8 do
    if inside(x, y) then
      local edge = not inside(x - 1, y) or not inside(x + 1, y) or not inside(x, y - 1) or not inside(x, y + 1)
      local s = (x < -2) and 2 or ((x > 3) and 4 or 3)
      if shape == "round" or shape == "small_round" then s = (x + y < -4) and 2 or ((x + y > 5) and 4 or 3) end
      local v = edge and tone(rim, s) or mat(st.shield_pattern or "cloth", field, s, cx + x, cy + y, st.shield_color2)
      if not edge and st.shield_pattern == "quarters" and ((x < 0) ~= (y < 0)) then v = tone(col(st.shield_color2) or C.white, s) end
      if not edge and st.shield_pattern == "halves" and x > 0 then v = tone(col(st.shield_color2) or C.white, s) end
      put(K, cx + x, cy + y, v)
    end
  end end
  if st.shield_face == "tiger" then                                   -- Chinese painted tiger-face shield
    local tc = col(st.shield_color2) or C.yellow
    P.rect(K, cx - 3, cy - 5, cx + 3, cy + 3, tone(tc, 3))
    put(K, cx - 2, cy - 3, INK); put(K, cx + 2, cy - 3, INK); P.hline(K, cx - 2, cx + 2, cy + 1, INK); put(K, cx, cy - 1, C.red)
    for i = -3, 3, 2 do put(K, cx + i, cy - 6, INK) end
  end
  if (shape == "round" or shape == "small_round") and st.emblem ~= "none" and not st.shield_face then
    local bc = col(st.boss) or C.iron
    P.ellipse(K, cx, cy, 2, 2, tone(bc, 3)); put(K, cx - 1, cy - 1, tone(bc, 1))
  end
  local e = st.emblem
  if e and e ~= "boss" and e ~= "none" then M.emblem(K, cx, cy - ((shape == "kite") and 2 or 0), e, col(st.emblem_color) or C.gold, 1) end
  P.use(K, "body")
end
M.shield = shield

---------------------------------------------------------------------------------------------- back items
local function back_items(K, st, p)
  local b, lean = p.bob, p.lean
  if st.quiver then
    local q = col(st.quiver)
    for y = -40 + b, -26 + b do for x = 6 + lean, 9 + lean do put(K, x, y, tone(q, (x == 6 + lean) and 2 or 4)) end end
    for i = 0, 3 do put(K, 6 + lean + i, -43 + b + (i % 2), (i % 2 == 0) and C.white or col(st.fletch or "red")); put(K, 6 + lean + i, -42 + b, C.wood_light) end
  end
  if st.bow_case then
    local q = col(st.bow_case)
    for y = -30 + b, -16 + b do for x = 7 + lean, 10 + lean do put(K, x, y, tone(q, (x == 7 + lean) and 2 or 4)) end end
  end
  if st.sashimono then
    local x = 6 + lean
    P.vline(K, x + 2, -68 + b, -30 + b, C.wood_dark)
    P.use(K, "team")
    for y = -68 + b, -52 + b do for xx = x + 3, x + 10 do put(K, xx, y, (xx == x + 3) and C.TEAM_L or ((xx == x + 10) and C.TEAM_D or C.TEAM)) end end
    P.use(K, "body")
    M.emblem(K, x + 7, -60 + b, st.sashimono, col(st.sashimono_color) or C.white, 0)
  end
  if st.back_shield then
    local keep = st.shield
    st.shield = st.back_shield
    shield(K, st, 7 + lean, -30 + b)
    st.shield = keep
  end
end

---------------------------------------------------------------------------------------------- frame
function M.draw(K, st, p)
  p.bob = p.bob or 0; p.lean = p.lean or 0
  local lf, lb = p.lf or { 0, 0 }, p.lb or { 0, 0 }
  local b, lean = p.bob, p.lean
  local hipy = -20 + b
  local sfx, sfy = -7 + lean, -36 + b
  local sbx, sby = 6 + lean, -36 + b
  local weapon = p.weapon
  if weapon == nil then weapon = st.weapon end
  local wa = p.w or p.af or 20
  local wopt = p.wopt or {}
  local two_hand = st.two_hand or weapon == "bow" or weapon == "musket" or weapon == "crossbow" or weapon == "dane_axe"

  if not st.shield and not two_hand then arm(K, st, sbx, sby, p.ab or -10, true) end
  back_items(K, st, p)
  P.use(K, st.legs_pattern == "mail" and "armor" or "body")
  if p.mounted then
    local legc = col(st.legs) or C.brown
    for y = hipy, hipy + 4 do for x = -8 + lean, -2 + lean do put(K, x, y, tone(legc, cyl(x, -8 + lean, -2 + lean))) end end
    local bootc = col(st.boots) or C.brown_dark
    for y = hipy + 5, hipy + 14 do for x = -8 + lean, -4 + lean do put(K, x, y, tone(bootc, cyl(x, -8 + lean, -4 + lean))) end end
    P.rect(K, -10 + lean, hipy + 13, -5 + lean, hipy + 14, tone(bootc, 4))
  else
    leg(K, st, 1, hipy, lb[1], lb[2], true)
    leg(K, st, -6, hipy, lf[1], lf[2], false)
  end
  P.use(K, "body")
  torso(K, st, p)
  head(K, st, p)
  if st.shield then
    arm(K, st, sbx, sby, p.ab or 10, true, 9)
    shield(K, st, 5 + lean + (p.shield_dx or 0), -26 + b + (p.shield_dy or 0))
  end
  local hx, hy
  if two_hand and weapon ~= "bow" then
    hx, hy = P.along(sfx, sfy, p.af or 80, 11)
    hx, hy = math.floor(hx + 0.5), math.floor(hy + 0.5)
    local bhx, bhy = P.along(hx, hy, wa + 180, 7)
    arm(K, st, sbx, sby, math.deg(math.atan(-(bhx - sbx), (bhy - sby))), true, math.min(13, math.sqrt((bhx - sbx) ^ 2 + (bhy - sby) ^ 2)))
  end
  if weapon == "bow" then
    hx, hy = arm(K, st, sfx, sfy, p.af or 70)
    P.use(K, "weapon"); W.bow(K, st, hx, hy, wa, wopt); P.use(K, "body")
    local sx = hx + 2 + (wopt.draw or 0)
    arm(K, st, sbx, sby, math.deg(math.atan(-(sx - sbx), (hy - sby))), false, math.min(13, math.sqrt((sx - sbx) ^ 2 + (hy - sby) ^ 2)))
    return
  end
  local behind = (wa > 185 or wa < -20)
  if weapon and behind then
    local px_, py_ = P.along(sfx, sfy, p.af or 20, 13)
    P.use(K, "weapon"); W[weapon](K, st, math.floor(px_ + 0.5), math.floor(py_ + 0.5), wa, wopt); P.use(K, "body")
  end
  hx, hy = arm(K, st, sfx, sfy, p.af or 20)
  if weapon and not behind then P.use(K, "weapon"); W[weapon](K, st, hx, hy, wa, wopt); P.use(K, "body") end
end

---------------------------------------------------------------------------------------------- mounts
local function mount(K, st, p)
  P.use(K, "mount")
  local camel = st.mount == "camel"
  local coat = col(st.mount_color) or (camel and C.camel or C.horse_bay)
  local mane = col(st.mane) or (camel and P.shade(coat, 0.7) or C.mane_dark)
  local hb = p.hb or 0
  local small = st.mount_small and 3 or 0                            -- ponies (Mongol, Nordic, Japanese)
  local top = (camel and -32 or -24) + small
  local ph = p.gait and (2 * math.pi * p.gait / 8) or nil
  local legs = { { -6, math.pi, true }, { 16, 0, true }, { -11, 0, false }, { 11, math.pi, false } }
  local function legdraw(x, phase, far)
    local dx, lift = 0, 0
    if ph then dx = math.floor(3.5 * math.sin(ph + phase) + 0.5); lift = (math.cos(ph + phase) > 0.45) and 3 or 0 end
    local foot = -lift
    local n = foot - (top + hb)
    for y = top + hb - 6, foot do
      local t = math.max(0, (y - top - hb) / math.max(1, n))
      local xo = math.floor(dx * t + 0.5)
      -- muscled upper leg (forearm / gaskin) tapering to a thin cannon bone, knobbly knee / hock, hoof
      local wdt = (t < 0.35) and (6 - math.floor(t * 6)) or ((t > 0.5 and t < 0.6) and 4 or 3)
      local off = (t < 0.35) and -1 or 0
      for i = 0, wdt - 1 do
        local s = ((i == 0) and 2 or 3) + (far and 1 or 0) + ((i == wdt - 1) and 1 or 0)
        local v = tone(coat, s)
        if y >= foot - 2 then v = tone(C.mane_dark, (i == 0) and 3 or 4); if i >= 3 then v = nil end end
        if y == foot - 3 and st.socks then v = tone(C.white, 3) end
        put(K, x + xo + i + off, y, v)
      end
    end
  end
  for _, L in ipairs(legs) do if L[3] then legdraw(L[1], L[2], true) end end
  local by = (camel and -38 or -31) + hb + small
  for i = 0, 14 do put(K, 20 + i // 4, by - 2 + i, tone(mane, 3 + i % 2)); put(K, 21 + i // 4, by - 2 + i, tone(mane, 4)) end
  for y = -11, 11 do for x = -20, 21 do
    if (x * x) / 440 + (y * y) / 121 <= 1 then
      local s = 3
      if y < -5 then s = 2 end
      if y < -8 then s = 1 end
      if y > 4 then s = 4 end
      if y > 7 then s = 5 end
      if x > 15 then s = math.min(5, s + 1) end
      put(K, x + 1, by + y, tone(coat, s))
    end
  end end
  if camel then
    for y = -10, 0 do for x = -8, 10 do
      if (x * x) / 90 + (y * y) / 100 <= 1 then put(K, x + 2, by - 9 + y, tone(coat, (y < -6) and 1 or ((x > 5) and 4 or 2))) end
    end end
  end
  local bard = col(st.barding)
  if bard then
    local pat = st.barding_pattern or "cloth"
    for y = by - 9, by + 16 do for x = -18, 21 do
      local inb = ((x - 1) ^ 2) / 440 + ((math.min(y, by + 2) - by) ^ 2) / 110 <= 1 or (y > by and x > -17 and x < 21)
      if inb and y <= by + 16 - ((x * 7) % 3) then
        local s = (x < -12) and 2 or ((x > 14) and 4 or 3)
        if y > by + 8 and (x % 6 == 0) then s = s + 1 end
        put(K, x, y, mat(pat, bard, s, x, y, st.barding2))
      end
    end end
    local trim = col(st.barding_trim) or C.gold
    for x = -17, 20 do put(K, x, by + 16 - ((x * 7) % 3), tone(trim, 3)) end
    if st.barding_emblem then M.emblem(K, 2, by + 4, st.barding_emblem, col(st.barding_emblem_color) or C.gold, 1) end
  end
  local blanket = col(st.blanket)
  if blanket and not bard then
    for y = by - 9, by + 6 do for x = -9, 9 do put(K, x, y, mat(st.blanket_pattern or "cloth", blanket, (x < -6) and 2 or ((x > 6) and 4 or 3), x, y, st.blanket2)) end end
    local tr = col(st.blanket_trim) or C.gold
    for x = -9, 9 do put(K, x, by + 6, tone(tr, 3)) end
    for y = by - 9, by + 6 do put(K, 9, y, tone(tr, 4)) end
  end
  if camel then
    for i = 0, 14 do local x, y = -14 - i * 0.6, by - 4 + i * 0.4 P.rect(K, math.floor(x), math.floor(y), math.floor(x) + 4, math.floor(y) + 4, tone(coat, (i % 3 == 0) and 2 or 3)) end
    for i = 0, 14 do local x, y = -22 - i * 0.2, by + 1 - i * 1.4 P.rect(K, math.floor(x), math.floor(y), math.floor(x) + 4, math.floor(y) + 3, tone(coat, 3)) end
    P.rect(K, -33, by - 24, -22, by - 18, tone(coat, 3)); P.hline(K, -33, -22, by - 24, tone(coat, 2))
    put(K, -27, by - 22, INK); P.rect(K, -34, by - 21, -32, by - 19, tone(coat, 4)); put(K, -24, by - 26, tone(coat, 4))
  else
    for i = 0, 15 do
      local x, y = -15 - i * 0.55, by - 3 - i * 1.15
      P.rect(K, math.floor(x), math.floor(y), math.floor(x) + 6, math.floor(y) + 2, tone(coat, (i > 10) and 2 or 3))
      put(K, math.floor(x) + 6, math.floor(y), tone(mane, 3)); put(K, math.floor(x) + 7, math.floor(y) + 1, tone(mane, 4))
    end
    local hx, hy = -26, by - 22
    P.poly(K, { { hx, hy }, { hx + 8, hy - 1 }, { hx + 6, hy + 11 }, { hx - 3, hy + 12 }, { hx - 4, hy + 9 } }, tone(coat, 3))
    P.line(K, hx, hy, hx - 3, hy + 10, tone(coat, 2), 1)
    P.rect(K, hx - 4, hy + 9, hx, hy + 12, tone(coat, 4)); put(K, hx - 3, hy + 10, INK)
    put(K, hx + 2, hy + 3, INK); put(K, hx + 3, hy + 3, C.white)
    P.rect(K, hx + 5, hy - 4, hx + 6, hy - 1, tone(coat, 3)); P.rect(K, hx + 7, hy - 3, hx + 8, hy, tone(coat, 4))
    local chan = col(st.chanfron)
    if chan then P.poly(K, { { hx + 1, hy - 1 }, { hx + 7, hy - 1 }, { hx + 3, hy + 9 }, { hx - 1, hy + 9 } }, tone(chan, 2)); P.line(K, hx + 3, hy, hx + 1, hy + 8, tone(chan, 4), 1) end
    P.line(K, hx + 6, hy + 4, hx - 2, hy + 10, C.brown_dark, 1)
    P.line(K, hx + 6, hy + 4, -10, by - 6, C.brown_dark, 1)
  end
  for _, L in ipairs(legs) do if not L[3] then legdraw(L[1], L[2], false) end end
  local sad = col(st.saddle) or C.leather
  local sy = camel and (by - 18) or (by - 10)
  P.rect(K, -5, sy, 7, sy + 2, tone(sad, 3)); P.hline(K, -5, 7, sy, tone(sad, 2)); P.rect(K, -6, sy - 2, -5, sy, tone(sad, 3)); P.rect(K, 7, sy - 3, 8, sy, tone(sad, 4))
  P.vline(K, -2, sy + 3, sy + 12, C.brown_dark); P.rect(K, -3, sy + 12, -1, sy + 13, C.iron)
  P.use(K, "body")
  return sy
end

function M.draw_mounted(K, st, p)
  local sy = mount(K, st, p)
  local ox, oy = K.ox, K.oy
  K.oy = oy + sy + 20 - 1
  K.rider_oy = K.oy                                 -- the rider's feet line, for the stature rows (units.lua)
  K.ox = ox + 2
  local rp = {}
  for k, v in pairs(p) do rp[k] = v end
  rp.mounted = true
  M.draw(K, st, rp)
  K.ox, K.oy = ox, oy
end

return M
