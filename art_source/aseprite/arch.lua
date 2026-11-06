-- Architecture kit v2 (32 px/m) for the 2D style's 3/4 "oblique" buildings. All sizes in metres; textures are
-- drawn at native pixels, so materials read as real brick courses, ashlar, tiles, thatch, felt.
-- Projection (same as the game's sprites): x -> 32 px/m; a point d metres behind the front edge and h metres
-- high -> y = -(d + h) * 22.63 px (anchor = front centre of the footprint on the ground). Light from the upper left.
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local CH = dofile(GEN_ROOT .. "/char.lua")
local A = {}
A.X, A.Z = 32, 22.627
local col, tone = CH.col, CH.tone
A.col, A.tone = col, tone
local function N(x, y, s) return P.noise(x, y, s or 7) end
local function put(K, x, y, c) if c then P.put(K, math.floor(x), math.floor(y), c) end end
local INK = P.hex("#241c26")

function A.px(x) return math.floor(x * A.X + 0.5) end
-- darken an already drawn pixel in place (shadows cast onto roofs / ground); empty pixels stay empty
function A.darken(K, x, y, f)
  x, y = math.floor(x), math.floor(y)
  local c = P.get(K, x, y)
  if c == nil or P.alpha(c) == 0 then return end
  local pc = app.pixelColor
  P.put(K, x, y, pc.rgba(math.floor(pc.rgbaR(c) * f), math.floor(pc.rgbaG(c) * f), math.floor(pc.rgbaB(c) * f * 1.04), 255))
end
function A.vy(d, h) return math.floor(-(d + h) * A.Z + 0.5) end

---------------------------------------------------------------------------------------------- materials
-- colour of a wall material at pixel (x, y), local coordinates (rx, ry) from the wall's top-left, shade s (1..5)
local WALL = {}
WALL.ashlar = function(c, s, x, y, rx, ry, o)
  local bh, bw = 6, 12
  local row = ry // bh
  local off = (row % 2) * (bw // 2) + (row * 5) % 3
  if ry % bh == 0 or (rx + off) % bw == 0 then return tone(c, s + 1) end
  local t = N((rx + off) // bw, row, 3)
  local v = tone(c, s + ((t < 0.2) and 1 or 0) - ((t > 0.85) and 1 or 0))
  if ry % bh == 1 and t > 0.4 then v = tone(c, s - 1) end
  if N(x, y, 5) > 0.97 then v = tone(c, s + 1) end
  return v
end
WALL.ashlar_banded = function(c, s, x, y, rx, ry, o)          -- one stone course framed by thin brick courses
  local band = col(o.band_c) or C.brick
  local cyc = ry % 15
  if cyc >= 10 then
    if cyc == 10 or cyc == 12 or cyc == 14 then return tone(c, s + 1) end
    return (((rx + (cyc == 13 and 2 or 0)) % 5) == 0) and tone(band, s + 1) or tone(band, s)
  end
  local bw = 14
  local off = ((ry // 15) % 2) * 7
  if (rx + off) % bw == 0 then return tone(band, s) end                           -- brick verticals between stones
  if cyc == 0 then return tone(c, s - 1) end
  return tone(c, s + ((N((rx + off) // bw, ry // 15, 9) < 0.25) and 1 or 0))
end
WALL.brick = function(c, s, x, y, rx, ry, o)
  local row = ry // 3
  local off = (row % 2) * 3
  if ry % 3 == 2 or (rx + off) % 6 == 0 then return tone(col(o.mortar) or P.hex("#c8b8a0"), s + 1) end
  local v = tone(c, s + ((N((rx + off) // 6, row, 13) < 0.25) and 1 or 0))
  if o.glazed then                                                                 -- dark glazed headers in diamonds
    local dx, dy = (rx // 6) % 6, row % 6
    if (dx + dy) % 6 == 0 or (dx - dy) % 6 == 0 then v = tone(col(o.glazed), s) end
  end
  return v
end
WALL.ablaq = function(c, s, x, y, rx, ry, o)                     -- Mamluk striped courses (light / dark)
  local row = ry // 6
  local cc = (row % 2 == 0) and c or (col(o.ablaq_c) or P.hex("#a8463a"))
  if ry % 6 == 0 or ((rx + (row % 2) * 6) % 12 == 0) then return tone(cc, s + 1) end
  return tone(cc, s)
end
WALL.plaster = function(c, s, x, y, rx, ry, o)
  local t = N(x, y, 11)
  local v = tone(c, s)
  if t < 0.05 then v = tone(c, s + 1) end
  if ry > (o.h_px or 99) - 4 and N(x, 1, 17) > 0.4 then v = tone(c, s + 1) end     -- weathering at the foot
  return v
end
WALL.adobe = function(c, s, x, y, rx, ry, o)
  local t = N(x // 2, y // 2, 21)
  local v = tone(c, s + ((t < 0.15) and 1 or 0))
  if N(x, y, 23) > 0.985 then v = tone(c, s + 2) end
  return v
end
WALL.planks = function(c, s, x, y, rx, ry, o)
  local k = rx % 5
  if k == 0 then return tone(c, s + 2) end
  local v = tone(c, s + ((k == 4) and 1 or 0) - ((k == 1) and 1 or 0))
  if N(rx // 5, ry // 9, 5) > 0.9 and ry % 9 == 4 then v = tone(c, s + 2) end      -- knots
  return v
end
WALL.stave = function(c, s, x, y, rx, ry, o)                     -- vertical staves with a rounded face
  local k = rx % 6
  return tone(c, s + ((k == 0) and 2 or ((k == 5) and 1 or ((k == 1) and -1 or 0))))
end
WALL.logs = function(c, s, x, y, rx, ry, o)
  local k = ry % 5
  return tone(c, s + ((k == 0) and -1 or ((k == 4) and 2 or ((k == 3) and 1 or 0))))
end
WALL.felt = function(c, s, x, y, rx, ry, o)
  local v = tone(c, s)
  if N(x, y, 19) < 0.08 then v = tone(c, s + 1) end
  return v
end
WALL.rammed = function(c, s, x, y, rx, ry, o)                    -- rammed earth: horizontal lifts
  if ry % 8 == 0 then return tone(c, s + 1) end
  return tone(c, s + ((N(x // 3, ry // 8, 29) < 0.2) and 1 or 0))
end
WALL.brick_banded = function(c, s, x, y, rx, ry, o)             -- Byzantine: brick courses, thick mortar, stone bands
  local stone = col(o.band_c) or P.hex("#D9CDB4")
  local cyc = ry % 20
  if cyc >= 14 then
    if cyc == 14 or cyc == 19 then return tone(stone, s + 1) end
    local off = ((ry // 20) % 2) * 6
    if (rx + off) % 12 == 0 then return tone(stone, s + 1) end
    return tone(stone, s + ((N((rx + off) // 12, ry // 20, 9) < 0.2) and 1 or 0))
  end
  local row = cyc // 2
  if cyc % 2 == 1 then return tone(col(o.mortar) or P.hex("#C9B9A0"), s) end      -- wide lime mortar joints
  if (rx + (row % 2) * 4) % 8 == 0 then return tone(col(o.mortar) or P.hex("#C9B9A0"), s) end
  return tone(c, s + ((N((rx + (row % 2) * 4) // 8, row, 13) < 0.25) and 1 or 0))
end
A.WALL = WALL

-- roof surface colour: d = rows from the eave along the slope, u = position along the eave
local ROOF = {}
ROOF.tiles = function(c, s, u, d, x, y)                          -- round pan tiles (Mediterranean / Ottoman)
  if d % 4 == 3 then return tone(c, s + 2) end
  local k = (u + (d // 4 % 2) * 3) % 6
  if k == 0 then return tone(c, s + 1) elseif k == 2 then return tone(c, s - 1) end
  return tone(c, s)
end
ROOF.east = function(c, s, u, d, x, y)                           -- grey kawara / Chinese tube tiles in vertical runs
  local k = u % 5
  if k == 0 then return tone(c, s + 2) elseif k == 1 then return tone(c, s - 1) end
  if d % 3 == 2 then return tone(c, s + 1) end
  return tone(c, s)
end
ROOF.slate = function(c, s, u, d, x, y)
  if d % 3 == 2 then return tone(c, s + 2) end
  if (u + (d // 3 % 2) * 3) % 6 == 0 then return tone(c, s + 1) end
  return tone(c, s + ((N(u // 6, d // 3, 3) > 0.85) and -1 or 0))
end
ROOF.thatch = function(c, s, u, d, x, y)
  local t = N(u, d // 2, 17)
  if d % 7 == 6 then return tone(c, s + 1) end
  return tone(c, s + ((t < 0.25) and 1 or 0) - ((t > 0.85) and 1 or 0))
end
ROOF.shingle = function(c, s, u, d, x, y)
  if d % 4 == 3 then return tone(c, s + 2) end
  if (u + (d // 4 % 2) * 2) % 4 == 0 then return tone(c, s + 1) end
  return tone(c, s)
end
ROOF.turf = function(c, s, u, d, x, y)
  local t = N(x, y, 31)
  return tone(c, s + ((t < 0.3) and 1 or 0) - ((t > 0.8) and 1 or 0))
end
ROOF.lead = function(c, s, u, d, x, y)
  return (u % 6 == 0) and tone(c, s + 1) or tone(c, s)
end
ROOF.felt = function(c, s, u, d, x, y) return tone(c, s + ((N(x, y, 19) < 0.1) and 1 or 0)) end
ROOF.stone = function(c, s, u, d, x, y)
  if d % 5 == 4 or (u + (d // 5 % 2) * 4) % 8 == 0 then return tone(c, s + 1) end
  return tone(c, s)
end
A.ROOF = ROOF

---------------------------------------------------------------------------------------------- walls
-- front face of a block: x0..x1 m, at depth d, from the ground (or h0) to height h. opt: base (plinth height m,
-- material colour), timber (frame colour), band (courses), eave_shadow
function A.facade(K, x0, x1, d, h, mat, c, opt)
  opt = opt or {}
  c = col(c)
  local px0, px1 = A.px(x0), A.px(x1) - 1
  local yb = A.vy(d, opt.h0 or 0)
  local yt = A.vy(d, h) + 1
  local h_px = yb - yt
  opt.h_px = h_px
  local f = WALL[mat] or WALL.plaster
  for y = yt, yb do
    for x = px0, px1 do
      local s = 3
      if x - px0 < 2 then s = 2 elseif px1 - x < 2 then s = 4 end
      put(K, x, y, f(c, s, x, y, x - px0, y - yt, opt))
    end
  end
  if opt.timber then                                                               -- timber framing
    local tc = col(opt.timber)
    local step = opt.timber_step or 22
    for x = px0, px1 do put(K, x, yt, tone(tc, 3)); put(K, x, yb, tone(tc, 4)) end
    local mid = yt + math.floor(h_px * 0.5)
    for x = px0, px1 do put(K, x, mid, tone(tc, 3)) end
    for x = px0, px1, step do for y = yt, yb do put(K, x, y, tone(tc, 3)); put(K, x + 1, y, tone(tc, 4)) end end
    for y = yt, yb do put(K, px1, y, tone(tc, 4)) end
    if opt.braces then
      for x = px0, px1 - step, step do
        for i = 0, step - 1 do
          local yy = mid - math.floor(i * (mid - yt) / step)
          put(K, x + i, yy, tone(tc, 3)); put(K, x + step - i, mid + math.floor(i * (yb - mid) / step), tone(tc, 3))
        end
      end
    end
  end
  if opt.posts then                                                                -- red lacquer columns (China)
    local pc = col(opt.posts)
    for x = px0 + 2, px1 - 2, opt.post_step or 24 do for y = yt, yb do put(K, x, y, tone(pc, 2)); put(K, x + 1, y, tone(pc, 3)); put(K, x + 2, y, tone(pc, 4)) end end
  end
  if opt.blind_arches then                                                         -- white blind arcades on brick
    local wc = col(opt.blind_arches)
    for x = px0 + 6, px1 - 10, 14 do
      for y = yt + 6, yb - 8 do for xx = x, x + 7 do
        local top_arc = (y - (yt + 6)) < 3 and math.abs(xx - (x + 3.5)) > 1 + (y - (yt + 6))
        if not top_arc then put(K, xx, y, tone(wc, (xx == x) and 2 or 3)) end
      end end
    end
  end
  if opt.stripe then for x = px0, px1 do put(K, x, yt + math.floor(h_px * 0.3), tone(col(opt.stripe), 3)); put(K, x, yt + math.floor(h_px * 0.3) + 1, tone(col(opt.stripe), 4)) end end
  if opt.base then                                                                 -- plinth / socle
    local bc = col(opt.base)
    local bh = math.max(3, math.floor((opt.base_h or 0.5) * A.Z))
    for y = yb - bh, yb do for x = px0 - 1, px1 + 1 do put(K, x, y, WALL.ashlar(bc, (x < px0 + 2) and 2 or ((x > px1 - 2) and 4 or 3), x, y, x - px0, y - (yb - bh), {})) end end
    for x = px0 - 1, px1 + 1 do put(K, x, yb - bh, tone(bc, 2)) end
  end
  local es = opt.eave_shadow or 0
  for i = 0, es - 1 do for x = px0, px1 do local cur = P.get(K, x, yt + i) if P.alpha(cur) > 0 then put(K, x, yt + i, P.shade(cur, 0.6 + 0.13 * i)) end end end
  for x = px0, px1 do local cur = P.get(K, x, yb) if P.alpha(cur) > 0 then put(K, x, yb, P.shade(cur, 0.7)) end end
  return { x0 = px0, x1 = px1, yt = yt, yb = yb }
end

-- battlements along the top of a facade: rectangular (europe), swallowtail (ghibelline), stepped (mamluk)
function A.merlons(K, x0, x1, d, h, c, kind)
  c = col(c)
  local px0, px1, yt = A.px(x0), A.px(x1) - 1, A.vy(d, h)
  local mw, gap = 5, 4
  for x = px0, px1, mw + gap do
    local xe = math.min(x + mw - 1, px1)
    for y = yt - 6, yt do for xx = x, xe do
      local v = tone(c, (xx == x) and 2 or ((xx == xe) and 4 or 3))
      if kind == "stepped" and y < yt - 3 and (xx == x or xx == xe) then v = nil end
      if kind == "stepped" and y < yt - 5 and (xx <= x + 1 or xx >= xe - 1) then v = nil end
      if kind == "swallow" and y < yt - 3 and xx == x + 2 then v = nil end
      put(K, xx, y, v)
    end end
  end
  for x = px0, px1 do put(K, x, yt + 1, tone(c, 4)) end
end

---------------------------------------------------------------------------------------------- roofs
-- roof over a block whose front wall is at depth d, depth D, eave height h, ridge rise r (all m). forms:
--   hip / gable (ridge parallel to the front), gable_front (gable faces the camera), stepped (Brick Gothic
--   stepped gable facing the camera), curved (Chinese / Japanese: hip with up-swept eaves), shed (lean-to)
-- opt: over (eave overhang m), ridge = team | colour, ornament = chiwen | shachi | dragon | cross | none, mat
function A.roof(K, form, x0, x1, d, D, h, r, mat, c, opt)
  opt = opt or {}
  c = col(c)
  local f = ROOF[mat or "tiles"] or ROOF.tiles
  local o = opt.over or 0.3
  local L, R = A.px(x0 - o), A.px(x1 + o)
  local ye = A.vy(d - o * 0.6, h - o * 0.4)                          -- front eave row
  local yr = A.vy(d + D / 2, h + r)                                  -- ridge row
  local yb = A.vy(d + D + o * 0.6, h - o * 0.4)                      -- back eave row (above the ridge if shallow)
  local cx = (L + R) / 2
  local P2 = {}
  local function fill(pts, shade, along_u, seed)
    local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
    for _, p in ipairs(pts) do minx = math.min(minx, p[1]); maxx = math.max(maxx, p[1]); miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
    for y = math.floor(miny), math.ceil(maxy) do
      local yc = y + 0.5
      local xs = {}
      for i = 1, #pts do
        local a, b = pts[i], pts[i % #pts + 1]
        if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1]) end
      end
      table.sort(xs)
      for i = 1, #xs - 1, 2 do
        for x = math.floor(xs[i] + 0.5), math.floor(xs[i + 1] - 0.5) do
          local dd = along_u and (x - math.floor(minx)) or (math.floor(maxy) - y)
          local uu = along_u and (math.floor(maxy) - y) or (x - math.floor(minx))
          put(K, x, y, f(c, shade, uu, dd, x, y))
        end
      end
    end
  end
  P.use(K, "roof")
  local ridge_pts
  if form == "hip" or form == "gable" or form == "curved" then
    local inset = (form == "gable") and 0 or math.floor((ye - yr) * 0.7)
    if form == "curved" then inset = math.floor((ye - yr) * 0.45) end
    if yb < yr then fill({ { L + inset, yr }, { R - inset, yr }, { R, yb }, { L, yb } }, 2) end     -- back slope
    fill({ { L, ye }, { R + 1, ye }, { R + 1 - inset, yr }, { L + inset, yr } }, 3)                  -- front slope
    if inset > 0 then
      -- hip ends reach the back eave corners (yb) when the back slope shows above the ridge, so the roof
      -- outline stays a closed box instead of an hourglass with the back eave floating as wings
      local yc = (yb < yr) and yb or (yr + (ye - yr) * 0.3)
      fill({ { L, ye }, { L + inset, yr }, { L, yc } }, 2, true)
      fill({ { R + 1, ye }, { R + 1 - inset, yr }, { R + 1, yc } }, 4, true)
      for i = 0, inset do
        local t = i / math.max(1, inset)
        put(K, L + i, math.floor(ye - (ye - yr) * t), tone(c, 4)); put(K, R - i, math.floor(ye - (ye - yr) * t), tone(c, 5))
      end
    end
    ridge_pts = { L + inset, R - inset, yr }
    for x = L, R do put(K, x, ye, tone(c, 5)); put(K, x, ye - 1, tone(c, 4)) end                     -- eave edge
    if form == "curved" then                                                                        -- up-swept corners
      for i = 0, 4 do put(K, L - i, ye - i // 2 - 1, tone(c, 4)); put(K, R + i, ye - i // 2 - 1, tone(c, 5)) end
      put(K, L - 5, ye - 4, tone(c, 3)); put(K, R + 5, ye - 4, tone(c, 4))
    end
  elseif form == "gable_front" or form == "stepped" then
    local apex = A.vy(d, h + r)
    local back = math.floor(-D * A.Z * 0.8)
    fill({ { L, ye }, { cx, apex }, { cx, apex + back }, { L, ye + back } }, 2, true)
    fill({ { cx + 1, apex }, { R + 1, ye }, { R + 1, ye + back }, { cx + 1, apex + back } }, 4, true)
    ridge_pts = { cx, cx, apex + back, apex }
    P.use(K, "structure")
    local wc = col(opt.gable_c or opt.wall_c or "plaster")
    local gx0, gx1 = A.px(x0), A.px(x1) - 1
    local ytop_wall = A.vy(d, h) + 1
    if form == "stepped" then
      local steps = opt.steps or 5
      local sw = (gx1 - gx0) / (steps * 2 - 1)
      for y = apex - 4, ytop_wall do
        for x = gx0, gx1 do
          local k = math.min(x - gx0, gx1 - x) / sw
          local lvl = math.floor(k) + 1
          local ytop_step = ytop_wall - math.floor((ytop_wall - apex + 4) * lvl / steps)
          if y >= ytop_step then
            put(K, x, y, WALL.brick(wc, (x < gx0 + 3) and 2 or 3, x, y, x - gx0, y - apex, opt))
          end
        end
      end
      if opt.blind_c then                                                      -- white blind niches in the steps
        local bc = col(opt.blind_c)
        for k = 1, steps - 1 do
          local xx = math.floor(gx0 + sw * k + sw * 0.2)
          local ytop_step = ytop_wall - math.floor((ytop_wall - apex + 4) * k / steps)
          for y = ytop_step + 4, ytop_wall - 3 do put(K, xx, y, tone(bc, 3)); put(K, xx + 1, y, tone(bc, 3)); put(K, gx1 - (xx - gx0), y, tone(bc, 3)); put(K, gx1 - (xx - gx0) - 1, y, tone(bc, 4)) end
        end
      end
    else
      local wm = opt.gable_mat or "plaster"
      for y = apex + 2, ytop_wall do
        local t = (y - apex) / math.max(1, ytop_wall - apex)
        local hw = (gx1 - gx0) / 2 * t
        for x = math.floor(cx - hw), math.floor(cx + hw) do put(K, x, y, (WALL[wm] or WALL.plaster)(wc, 3, x, y, x - gx0, y - apex, opt)) end
      end
      if opt.timber then
        local tc = col(opt.timber)
        P.line(K, gx0, ytop_wall, cx, apex + 2, tone(tc, 3), 2); P.line(K, cx, apex + 2, gx1, ytop_wall, tone(tc, 3), 2)
        P.vline(K, math.floor(cx), apex + 3, ytop_wall, tone(tc, 3))
      end
      P.use(K, "roof")
      P.line(K, L, ye, cx, apex, tone(c, 5), 2); P.line(K, cx, apex, R, ye, tone(c, 5), 2)        -- barge boards
    end
    if opt.crossed_ends then                                                    -- Norse crossed gable finials
      P.use(K, "props")
      local wc2 = col(opt.crossed_ends)
      P.line(K, cx - 1, apex + 2, cx + 6, apex - 8, tone(wc2, 3), 2); P.line(K, cx + 1, apex + 2, cx - 6, apex - 8, tone(wc2, 3), 2)
      put(K, cx + 7, apex - 9, tone(wc2, 2)); put(K, cx - 7, apex - 9, tone(wc2, 2))
    end
  elseif form == "shed" then
    fill({ { L, ye }, { R + 1, ye }, { R + 1, yr }, { L, yr } }, 3)
    for x = L, R do put(K, x, ye, tone(c, 5)) end
    ridge_pts = nil
  end
  -- ridge cap (team colour unless given) and ornaments
  if ridge_pts and form ~= "stepped" then
    local rc = opt.ridge and col(opt.ridge) or C.TEAM
    P.use(K, (rc == C.TEAM) and "team" or "roof")
    if form == "gable_front" then
      for y = ridge_pts[3], ridge_pts[4] do put(K, ridge_pts[1], y, tone(rc, 2)); put(K, ridge_pts[1] + 1, y, tone(rc, 4)) end
    else
      for x = ridge_pts[1], ridge_pts[2] do put(K, x, ridge_pts[3], tone(rc, 2)); put(K, x, ridge_pts[3] + 1, tone(rc, 4)) end
    end
    P.use(K, "props")
    local orn = opt.ornament
    if orn and form ~= "gable_front" then
      for _, ex in ipairs({ ridge_pts[1], ridge_pts[2] }) do
        local sgn = (ex == ridge_pts[1]) and -1 or 1
        local y0 = ridge_pts[3]
        if orn == "chiwen" or orn == "shachi" then                                -- fish-tail ridge ends
          local oc = col(opt.ornament_c) or ((orn == "shachi") and C.gold or tone(c, 4))
          P.rect(K, ex - 1, y0 - 4, ex + 1, y0, tone(oc, 3)); put(K, ex + sgn * 2, y0 - 5, tone(oc, 2)); put(K, ex + sgn * 2, y0 - 6, tone(oc, 2)); put(K, ex + sgn, y0 - 6, tone(oc, 3))
        elseif orn == "dragon" then
          local oc = col(opt.ornament_c) or C.wood_dark
          P.line(K, ex, y0, ex + sgn * 4, y0 - 6, tone(oc, 3), 2); put(K, ex + sgn * 5, y0 - 7, tone(oc, 2))
        elseif orn == "cross" then
          local oc = col(opt.ornament_c) or C.gold
          P.vline(K, ex, y0 - 6, y0, tone(oc, 3)); P.hline(K, ex - 2, ex + 2, y0 - 4, tone(oc, 3))
        end
      end
    end
  end
  P.use(K, "structure")
  return { ye = ye, yr = yr, yb = yb, L = L, R = R, top = math.min(yr, yb) }
end

---------------------------------------------------------------------------------------------- towers, domes
-- round tower front at depth d (front of the cylinder), radius r, height h, top = cone | dome | crenel | flat
function A.round_tower(K, cx, d, r, h, mat, c, top, opt)
  opt = opt or {}
  c = col(c)
  local x0, x1 = A.px(cx - r), A.px(cx + r) - 1
  local yb, yt = A.vy(d, 0), A.vy(d, h) + 1
  local f = WALL[mat] or WALL.ashlar
  for y = yt, yb do for x = x0, x1 do
    local fr = (x - x0) / math.max(1, x1 - x0)
    local s = (fr < 0.15) and 2 or ((fr < 0.55) and 3 or ((fr < 0.82) and 4 or 5))
    put(K, x, y, f(c, s, x, y, x - x0, y - yt, opt))
  end end
  if opt.windows then for i = 1, opt.windows do A.window(K, cx, d, h * i / (opt.windows + 1), 0.25, 0.5, "slit") end end
  local res = { top = yt }
  local tc = col(opt.top_c or c)
  if top == "cone" or top == "cone_lead" then
    local ch = (opt.cone_h or (r * 2.2)) * A.Z
    local mat2 = (top == "cone_lead") and "lead" or (opt.top_mat or "slate")
    local apex = yt - math.floor(ch)
    P.use(K, "roof")
    for y = apex, yt + 2 do
      local t = (y - apex) / math.max(1, yt + 2 - apex)
      local hw = (x1 - x0) / 2 * t + 2 * t
      local mid = (x0 + x1) / 2
      for x = math.floor(mid - hw), math.floor(mid + hw) do
        local fr = (x - (mid - hw)) / math.max(1, 2 * hw)
        local s = (fr < 0.25) and 2 or ((fr < 0.6) and 3 or 4)
        put(K, x, y, (ROOF[mat2] or ROOF.slate)(tc, s, x, y - apex, x, y))
      end
    end
    P.use(K, "props")
    local fin = opt.finial
    local mid = math.floor((x0 + x1) / 2)
    if fin == "crescent" then P.vline(K, mid, apex - 5, apex, C.gold); put(K, mid - 1, apex - 7, C.gold); put(K, mid - 2, apex - 6, C.gold); put(K, mid + 1, apex - 7, C.gold)
    elseif fin == "cross" then P.vline(K, mid, apex - 6, apex, C.gold); P.hline(K, mid - 2, mid + 2, apex - 4, C.gold)
    elseif fin then P.vline(K, mid, apex - 4, apex, C.gold) end
    res.top = apex - 7
  elseif top == "dome" then
    res.top = A.dome(K, cx, d + r, r * 1.05, opt.dome_h or r * 0.9, h, opt.top_c or c, opt.finial)
  elseif top == "crenel" then
    A.merlons(K, cx - r - 0.1, cx + r + 0.1, d, h, c, opt.merlon)
    res.top = yt - 7
  end
  P.use(K, "structure")
  return res
end

-- dome: centre (cx, dc depth), base radius r (m), height hd (m), sitting at height h0; lead ribs, finial
function A.dome(K, cx, dc, r, hd, h0, c, finial, opt)
  opt = opt or {}
  c = col(c)
  local mx = A.px(cx)
  local by = A.vy(dc - r * 0.6, h0)                    -- visible base (front of the drum top)
  local rx = r * A.X
  local ry = hd * A.Z + r * A.Z * 0.6
  P.use(K, "roof")
  if opt.shadow ~= false then                          -- shadow on the terrace / drum, light from the upper left
    local sx, srx, sry = mx + rx * 0.35, rx * 1.0, math.max(2, ry * 0.35)
    for y = math.floor(by - sry), math.ceil(by + sry * 0.6) do
      for x = math.floor(sx - srx), math.ceil(sx + srx) do
        local nx, ny = (x - sx) / srx, (y - by) / sry
        if nx * nx + ny * ny <= 1 then A.darken(K, x, y, 0.72) end
      end
    end
  end
  for y = math.floor(by - ry), by do
    for x = math.floor(mx - rx), math.ceil(mx + rx) do
      local nx, ny = (x - mx) / rx, (y - by) / ry
      if nx * nx + ny * ny <= 1 then
        local nz = math.sqrt(math.max(0, 1 - nx * nx - ny * ny))
        local lit = -nx * 0.55 - ny * 0.45 + nz * 0.5
        local s = (lit > 0.7) and 1 or ((lit > 0.42) and 2 or ((lit > 0.1) and 3 or ((lit > -0.2) and 4 or 5)))
        local v = tone(c, s)
        local ang = math.atan(nx, -ny)
        if opt.ribs ~= false and math.floor((ang + math.pi) / (math.pi / 10)) % 2 == 0 and nz > 0.15 and (x % 2 == 0) then v = tone(c, s + 1) end
        put(K, x, y, v)
      end
    end
  end
  for x = math.floor(mx - rx), math.ceil(mx + rx) do put(K, x, by, tone(c, 5)) end
  P.use(K, "props")
  local top = math.floor(by - ry)
  if finial == "crescent" then
    P.vline(K, mx, top - 6, top, C.gold); P.rect(K, mx - 1, top - 4, mx + 1, top - 3, C.gold)
    put(K, mx - 2, top - 8, C.gold); put(K, mx - 2, top - 9, C.gold); put(K, mx - 1, top - 10, C.gold); put(K, mx + 1, top - 10, C.gold); put(K, mx, top - 7, C.gold)
    top = top - 10
  elseif finial == "cross" then P.vline(K, mx, top - 7, top, C.gold); P.hline(K, mx - 2, mx + 2, top - 5, C.gold); top = top - 7
  elseif finial then P.vline(K, mx, top - 4, top, C.gold); P.rect(K, mx - 1, top - 6, mx + 1, top - 4, C.gold); top = top - 6 end
  P.use(K, "structure")
  return top
end

-- drum (cylindrical base with windows) under a dome
function A.drum(K, cx, dc, r, h0, hdrum, mat, c, opt)
  local res = A.facade(K, cx - r, cx + r, dc - r * 0.6, h0 + hdrum, mat, c, { h0 = h0, band_c = opt and opt.band_c })
  for i = -2, 2 do A.window(K, cx + i * r * 0.36, dc - r * 0.6, h0 + hdrum * 0.25, 0.16, hdrum * 0.55, "arch_round") end
  return res
end

-- slender pencil minaret: shaft, balcony (şerefe), conical lead cap
function A.minaret(K, cx, d, h, c, cap_c, opt)
  c = col(c)
  local r = 0.32
  local x0, x1 = A.px(cx - r), A.px(cx + r) - 1
  local yb, yt = A.vy(d, 0), A.vy(d, h)
  for y = yt, yb do for x = x0, x1 do put(K, x, y, tone(c, (x == x0) and 2 or ((x == x1) and 4 or 3))) end end
  local by = A.vy(d, h * 0.72)
  P.rect(K, x0 - 3, by - 1, x1 + 3, by + 1, tone(c, 2)); P.hline(K, x0 - 3, x1 + 3, by + 2, tone(c, 5))
  for x = x0 - 3, x1 + 3, 2 do put(K, x, by - 2, tone(c, 3)) end
  P.use(K, "roof")
  local cc = col(cap_c)
  for i = 0, 22 do
    local hw = math.floor((i / 22) * (r * A.X + 1))
    for x = math.floor((x0 + x1) / 2) - hw, math.floor((x0 + x1) / 2) + hw do put(K, x, yt - 22 + i, tone(cc, (x < (x0 + x1) / 2) and 2 or 4)) end
  end
  P.use(K, "props")
  local mid = math.floor((x0 + x1) / 2)
  P.vline(K, mid, yt - 28, yt - 22, C.gold); put(K, mid - 1, yt - 30, C.gold); put(K, mid - 2, yt - 29, C.gold); put(K, mid + 1, yt - 30, C.gold)
  P.use(K, "structure")
  return yt - 30
end

---------------------------------------------------------------------------------------------- openings
-- window centred at cx (m) on a wall at depth d, sill at height hs, width w, height hh (m)
function A.window(K, cx, d, hs, w, hh, kind, opt)
  opt = opt or {}
  local x0, x1 = A.px(cx - w / 2), A.px(cx + w / 2) - 1
  local yb, yt = A.vy(d, hs), A.vy(d, hs + hh)
  local glass = opt.glow and C.glow or P.hex("#2a2234")
  for y = yt, yb do for x = x0, x1 do
    local v = glass
    if kind == "arch_round" or kind == "arch_pointed" or kind == "horseshoe" then
      local rw = (x1 - x0) / 2
      local cxp = (x0 + x1) / 2
      local dy = y - yt
      if dy < rw then
        local dx = math.abs(x - cxp)
        if kind == "arch_pointed" then if dx > (dy + 0.5) * 0.9 then v = nil end
        elseif dx * dx + (rw - dy) ^ 2 > rw * rw + 0.5 then v = nil end
      end
    end
    if v and (kind == "lattice" or opt.lattice) and ((x + y) % 3 == 0 or (x - y) % 3 == 0) then v = tone(col(opt.frame or "wood_dark"), 3) end
    if v and kind == "shoji" then v = ((x - x0) % 3 == 0 or (y - yt) % 3 == 0) and tone(C.wood_dark, 3) or tone(C.cream, 2) end
    put(K, x, y, v)
  end end
  if kind == "slit" then return end
  local fc = col(opt.frame or "wood_dark")
  for x = x0 - 1, x1 + 1 do put(K, x, yb + 1, tone(col(opt.sill or "stone_light"), 2)) end
  if opt.shutters then
    local sc = col(opt.shutters)
    for y = yt, yb do put(K, x0 - 2, y, tone(sc, 3)); put(K, x0 - 1, y, tone(sc, 4)); put(K, x1 + 1, y, tone(sc, 3)); put(K, x1 + 2, y, tone(sc, 4)) end
  end
  if opt.tile_lunette then for x = x0, x1 do put(K, x, yt - 2, tone(col(opt.tile_lunette), 3)); put(K, x, yt - 3, tone(col(opt.tile_lunette), 2)) end end
end

-- door: kind = rect | arch_round | arch_pointed | horseshoe | gate (big double leaf with studs)
function A.door(K, cx, d, w, hh, kind, c, opt)
  opt = opt or {}
  c = col(c or "wood_dark")
  local x0, x1 = A.px(cx - w / 2), A.px(cx + w / 2) - 1
  local yb, yt = A.vy(d, 0), A.vy(d, hh)
  local rw = (x1 - x0) / 2
  local cxp = (x0 + x1) / 2
  for y = yt, yb do for x = x0, x1 do
    local inside = true
    local dy = y - yt
    if (kind == "arch_round" or kind == "horseshoe") and dy < rw then inside = (x - cxp) ^ 2 + (rw - dy) ^ 2 <= rw * rw + 0.5 end
    if kind == "arch_pointed" and dy < rw * 1.3 then inside = math.abs(x - cxp) <= (dy + 0.5) * 0.85 end
    if inside then
      local v = tone(c, ((x - x0) % 4 == 0) and 4 or 3)
      if kind == "gate" and (x - x0) % 6 == 3 and (y - yt) % 6 == 3 then v = tone(C.iron, 2) end
      if math.abs(x - cxp) < 0.6 and (kind == "gate" or w > 1.2) then v = tone(c, 5) end
      put(K, x, y, v)
    end
  end end
  -- surround: stone voussoirs / frame
  local fc = col(opt.frame or "stone_dark")
  for y = yt + math.floor(rw), yb do put(K, x0 - 1, y, tone(fc, 2)); put(K, x1 + 1, y, tone(fc, 4)) end
  if kind == "rect" or kind == "gate" then for x = x0 - 1, x1 + 1 do put(K, x, yt - 1, tone(fc, 3)) end
  else
    for a = 0, 180, 6 do
      local r2 = rw + 1.5
      local x = cxp + math.cos(math.rad(a)) * r2
      local y = yt + rw - math.sin(math.rad(a)) * r2 * ((kind == "arch_pointed") and 1.3 or 1)
      put(K, x, y, tone(fc, (a < 90) and 3 or 2))
    end
  end
  put(K, x0 + 1 + (x1 - x0) * 0.75, (yt + yb) / 2 + 2, C.gold)                       -- ring handle
  if opt.muqarnas then                                                               -- stalactite hood over the portal
    local mc = col(opt.muqarnas)
    for row = 0, 2 do for x = x0 - 2 + row * 2, x1 + 2 - row * 2, 3 do P.rect(K, x, yt - 10 + row * 3, x + 1, yt - 9 + row * 3, tone(mc, 2 + row)) end end
  end
end

---------------------------------------------------------------------------------------------- banners, flags
function A.banner(K, cx, d, h, w, hh, emblem, ec)
  local x0, x1 = A.px(cx - w / 2), A.px(cx + w / 2) - 1
  local yt, yb = A.vy(d, h), A.vy(d, h - hh)
  P.use(K, "props")
  P.hline(K, x0 - 2, x1 + 2, yt - 1, C.wood_dark); put(K, x0 - 2, yt - 2, C.gold); put(K, x1 + 2, yt - 2, C.gold)
  P.use(K, "team")
  for y = yt, yb do for x = x0, x1 do
    local tail = y > yb - 4 and math.abs(x - (x0 + x1) / 2) < (y - (yb - 4))
    if not tail then put(K, x, y, (x == x0) and C.TEAM_L or ((x == x1) and C.TEAM_D or ((y == yt) and C.TEAM_H or C.TEAM))) end
  end end
  P.use(K, "props")
  if emblem then CH.emblem(K, math.floor((x0 + x1) / 2), yt + math.floor((yb - yt) * 0.42), emblem, col(ec or "gold"), 1) end
  P.use(K, "structure")
end

function A.flag(K, cx, d, h, len, emblem, ec)
  local x, yb = A.px(cx), A.vy(d, 0)
  local yt = A.vy(d, h)
  P.use(K, "props")
  P.vline(K, x, yt, yb, C.wood_dark); P.vline(K, x + 1, yt, yb, P.shade(C.wood_dark, 0.7)); P.rect(K, x - 1, yt - 2, x + 1, yt - 1, C.gold)
  P.use(K, "team")
  local fl = len or 14
  for i = 0, fl do
    local wave = math.floor(math.sin(i / fl * math.pi * 1.6) * 1.5 + 0.5)
    for j = 0, 8 do put(K, x + 2 + i, yt + j + wave, (j == 0) and C.TEAM_L or ((j == 8) and C.TEAM_D or (((i // 4) % 2 == 0) and C.TEAM or C.TEAM_L))) end
  end
  P.use(K, "props")
  if emblem then CH.emblem(K, x + 2 + math.floor(fl / 2), yt + 4, emblem, col(ec or "white"), 0) end
  P.use(K, "structure")
end

-- Civ war standards (Age III dressing; docs/art/culture/<civ>.md). Civ colours on the cloth (props layer), plus one
-- team-coloured element on every standard (tassels, border, header or tails) so friend / foe still reads.
--   spec = { form, field, field2, emblem, ec }
--   forms: sancak (Ottoman red swallowtail with crescent + tug finial), sulde (Mongol black horsehair ring under a
--   spear blade), labarum (Byzantine banner hanging from a crossbar), nobori (Japanese tall narrow banner, mon at the
--   top), qi (Chinese tall banner with a serrated flame border and a big character), oriflamme (Frankish red forked
--   banner), pennon (English St George swallowtail), gonfanon (Teutonic hanging banner with tails), raven (Norse
--   quarter-round raven banner), alam (Mamluk sultanic-yellow banner with an inscription band)
function A.standard(K, cx, d, h, spec)
  local x, yb, yt = A.px(cx), A.vy(d, 0), A.vy(d, h)
  local f1, f2 = col(spec.field or "#B3202A"), col(spec.field2 or "white")
  local ec = col(spec.ec or "white")
  local form = spec.form
  local function cloth(x0, y0, x1, y1, inside, c, layer)
    P.use(K, layer or "props")
    for y = y0, y1 do for xx = x0, x1 do
      if inside == nil or inside(xx, y) then
        local v = (xx == x0) and tone(c, 2) or ((xx == x1 or y == y1) and tone(c, 4) or tone(c, 3))
        put(K, xx, y, v)
      end
    end end
  end
  local function team(pts) P.use(K, "team"); for _, q in ipairs(pts) do put(K, q[1], q[2], q[3] or C.TEAM) end end
  P.use(K, "props")
  P.vline(K, x, yt, yb, C.wood_dark); P.vline(K, x + 1, yt, yb, P.shade(C.wood_dark, 0.7))
  if form == "sulde" then
    -- spear blade, gilt collar, a full ring of black horsehair; team ribbons tied under it
    P.vline(K, x, yt - 6, yt - 1, C.steel or col("steel")); put(K, x + 1, yt - 4, tone(col("steel"), 2))
    P.rect(K, x - 1, yt, x + 2, yt + 1, C.gold)
    local hc = col(spec.field or "#2B2622")
    for i = -4, 5 do for y = yt + 2, yt + 13 - math.abs(i - 0.5) // 1 do put(K, x + i, y, tone(hc, (i < 0) and 2 or ((i > 2) and 4 or 3))) end end
    P.use(K, "team"); for y = yt + 14, yt + 19 do put(K, x - 1, y, C.TEAM); put(K, x + 2, y + 1, C.TEAM_D) end
  elseif form == "sancak" then
    -- gilt ball + crescent finial, a small horsetail under it, a crimson swallowtail with a white crescent
    P.rect(K, x - 1, yt - 3, x + 1, yt - 1, C.gold); put(K, x - 1, yt - 5, C.gold); put(K, x + 1, yt - 5, C.gold); put(K, x, yt - 4, C.gold)
    for i = -2, 2 do for y = yt, yt + 6 - math.abs(i) do put(K, x + i, y, tone(col("#2a2026"), 3)) end end
    local x0, x1, y0, y1 = x + 2, x + 17, yt + 7, yt + 17
    cloth(x0, y0, x1, y1, function(xx, y) return not (xx > x1 - 5 and math.abs(y - (y0 + y1) / 2) < (xx - (x1 - 5)) * 0.9) end, f1)
    CH.emblem(K, x0 + 6, y0 + 5, "crescent", ec, 1)
    team({ { x0, y0 }, { x0, y0 + 1 }, { x0, y0 + 2 }, { x0, y1 - 2 }, { x0, y1 - 1 }, { x0, y1 } })
    for y = y0, y1 do put(K, x0, y, C.TEAM) end
  elseif form == "labarum" then
    -- crossbar with gilt ends, a square banner hanging from it (chi-rho in gold), team tassels along the hem
    P.hline(K, x - 7, x + 8, yt + 1, C.wood_dark); put(K, x - 8, yt + 1, C.gold); put(K, x + 9, yt + 1, C.gold)
    P.rect(K, x - 1, yt - 4, x + 1, yt - 2, C.gold)
    local x0, x1, y0, y1 = x - 6, x + 7, yt + 2, yt + 16
    cloth(x0, y0, x1, y1, nil, f1)
    for xx = x0, x1 do put(K, xx, y0 + 1, tone(C.gold, 2)); put(K, xx, y1 - 1, tone(C.gold, 3)) end
    CH.emblem(K, x + 1, y0 + 7, spec.emblem or "chirho", ec, 1)
    P.use(K, "team"); for xx = x0, x1, 2 do put(K, xx, y1 + 1, C.TEAM); put(K, xx, y1 + 2, C.TEAM_D) end
  elseif form == "nobori" then
    -- tall narrow banner held by the pole and a short top arm; the mon at the top, team-coloured header band
    P.hline(K, x, x + 9, yt, C.wood_dark)
    local x0, x1, y0, y1 = x + 2, x + 9, yt + 1, yt + 26
    cloth(x0, y0, x1, y1, nil, f1)
    for y = y0 + 3, y1, 5 do put(K, x1 + 1, y, tone(f1, 4)) end                       -- chichi loops
    CH.emblem(K, x0 + 4, y0 + 8, spec.emblem or "tomoe", ec, 0)
    P.use(K, "team"); for y = y0, y0 + 2 do for xx = x0, x1 do put(K, xx, y, (y == y0) and C.TEAM_L or C.TEAM) end end
    for y = y1 - 2, y1 do for xx = x0, x1 do put(K, xx, y, C.TEAM_D) end end
  elseif form == "qi" then
    -- tall red banner, serrated flame border, one big black character; border teeth in team colour
    P.rect(K, x - 1, yt - 4, x + 1, yt - 1, C.gold); put(K, x, yt - 5, tone(C.gold, 2))
    local x0, x1, y0, y1 = x + 2, x + 13, yt, yt + 20
    cloth(x0, y0, x1, y1, nil, f1)
    CH.emblem(K, x0 + 6, y0 + 9, spec.emblem or "hanzi", ec, 1)
    P.use(K, "team")
    for y = y0, y1, 2 do put(K, x1 + 1, y, C.TEAM); put(K, x1 + 2, y, C.TEAM_D) end
    for xx = x0, x1 + 1, 2 do put(K, xx, y1 + 1, C.TEAM); put(K, xx + 1, y1 + 2, C.TEAM_D) end
  elseif form == "oriflamme" then
    -- long red banner split into flame-like tails, gilt lance head; team on the hoist
    P.rect(K, x - 1, yt - 5, x + 1, yt - 1, C.gold); put(K, x, yt - 6, C.gold)
    local x0, x1, y0, y1 = x + 2, x + 20, yt, yt + 9
    cloth(x0, y0, x1, y1, function(xx, y)
      if xx < x0 + 8 then return true end
      local t = (xx - x0 - 8) / 12
      local band = (y - y0) % 4
      return band < 3 - t * 2 + 0.5
    end, f1)
    P.use(K, "team"); for y = y0, y1 do put(K, x0, y, C.TEAM); put(K, x0 + 1, y, C.TEAM_D) end
  elseif form == "pennon" then
    -- St George: white field, red cross, a swallowtail fly in team colour
    P.rect(K, x - 1, yt - 2, x + 1, yt - 1, C.gold)
    local x0, x1, y0, y1 = x + 2, x + 13, yt, yt + 10
    cloth(x0, y0, x1, y1, nil, f2)
    P.use(K, "props")
    for xx = x0, x1 do put(K, xx, y0 + 4, tone(f1, 3)); put(K, xx, y0 + 5, tone(f1, 3)) end
    for y = y0, y1 do put(K, x0 + 4, y, tone(f1, 3)); put(K, x0 + 5, y, tone(f1, 3)) end
    P.use(K, "team")
    for i = 0, 7 do for y = y0 + i // 2, y1 - i // 2 do
      if math.abs(y - (y0 + y1) / 2) > 1.5 - i * 0.1 then put(K, x1 + 1 + i, y, (i < 2) and C.TEAM_L or C.TEAM) end
    end end
  elseif form == "gonfanon" then
    -- crossbar, white banner with a black cross, three tails in team colour
    P.hline(K, x - 6, x + 7, yt + 1, C.wood_dark); P.rect(K, x - 1, yt - 4, x + 1, yt - 2, C.gold)
    local x0, x1, y0, y1 = x - 5, x + 6, yt + 2, yt + 15
    cloth(x0, y0, x1, y1, nil, f2)
    CH.emblem(K, x + 1, y0 + 6, spec.emblem or "cross_pattee", ec, 1)
    P.use(K, "team")
    for k = 0, 2 do local tx = x0 + 1 + k * 4 for y = y1 + 1, y1 + 5 - (k % 2) do put(K, tx, y, C.TEAM); put(K, tx + 1, y, C.TEAM_D) end end
  elseif form == "raven" then
    -- quarter-round white banner with a black raven, fringed curved edge in team colour
    P.rect(K, x - 1, yt - 3, x + 1, yt - 1, C.steel or col("steel"))
    local x0, y0, r = x + 2, yt, 14
    cloth(x0, y0, x0 + r, y0 + r, function(xx, y) return (xx - x0) ^ 2 + (y - y0) ^ 2 <= r * r end, f2)
    CH.emblem(K, x0 + 5, y0 + 5, "raven", ec, 1)
    P.use(K, "team")
    for a = 0, 16 do
      local t = a / 16 * math.pi / 2
      put(K, x0 + math.floor(math.cos(t) * (r + 1) + 0.5), y0 + math.floor(math.sin(t) * (r + 1) + 0.5), (a % 2 == 0) and C.TEAM or C.TEAM_D)
    end
  else -- alam: sultanic yellow banner with a white inscription band, team-coloured hoist and fringe
    P.rect(K, x - 1, yt - 4, x + 1, yt - 1, C.gold); put(K, x, yt - 5, tone(C.gold, 1))
    local x0, x1, y0, y1 = x + 2, x + 16, yt, yt + 12
    cloth(x0, y0, x1, y1, nil, f1)
    P.use(K, "props")
    for xx = x0 + 1, x1 - 1 do put(K, xx, y0 + 4, tone(f2, 2)); put(K, xx, y0 + 6, tone(f2, 2))
      if (xx * 7 % 5) < 3 then put(K, xx, y0 + 5, tone(col(spec.ec or "#2a2234"), 3)) else put(K, xx, y0 + 5, tone(f2, 2)) end end
    P.use(K, "team")
    for y = y0, y1 do put(K, x0, y, C.TEAM) end
    for xx = x0, x1, 2 do put(K, xx, y1 + 1, C.TEAM_D) end
  end
  P.use(K, "structure")
end

-- Ottoman / Mongol horsetail standard (tuğ): pole, gilt ball, hanging hair (team-coloured cords)
function A.tug(K, cx, d, h, hair)
  local x, yb, yt = A.px(cx), A.vy(d, 0), A.vy(d, h)
  P.use(K, "props")
  P.vline(K, x, yt, yb, C.wood_dark); P.rect(K, x - 1, yt - 3, x + 1, yt - 1, C.gold)
  local hc = col(hair or "#2a2026")
  for i = -3, 3 do for y = yt + 1, yt + 11 - math.abs(i) do put(K, x + i, y, tone(hc, (i < 0) and 2 or 3)) end end
  P.use(K, "team"); P.hline(K, x - 2, x + 2, yt, C.TEAM); P.use(K, "structure")
end

---------------------------------------------------------------------------------------------- ground, shadow
function A.ground(K, x0, x1, d0, d1, c, opt)
  opt = opt or {}
  P.use(K, "ground")
  local gc = col(c or "dirt")
  local px0, px1 = A.px(x0), A.px(x1)
  local y0, y1 = -math.floor(d1 * A.X), -math.floor(d0 * A.X)                       -- ground seen from above: 32 px/m
  for y = y0, y1 do for x = px0, px1 do
    local cx, cy = math.min(x - px0, px1 - x), math.min(y - y0, y1 - y)
    local t = N(x, y, 23)
    if not (cx + cy < 5) then
      local v = tone(gc, (t < 0.07) and 4 or ((t > 0.93) and 2 or 3))
      if opt.paving then
        -- flagstones a step darker than the (light) walls standing on them, so the building keeps its outline
        local pc = col(opt.paving)
        if (y - y0) % 7 == 6 or ((x - px0) + ((y - y0) // 7) % 2 * 5) % 10 == 0 then v = tone(pc, 5) else v = tone(pc, (t > 0.85) and 3 or 4) end
      end
      if cx == 0 or cy == 0 or cx + cy == 5 then v = tone(opt.paving and col(opt.paving) or gc, 5) end
      put(K, x, y, v)
    end
  end end
  P.use(K, "structure")
end

function A.shadow_ellipse(K, cx, d, rx, ry)
  local SH = P.hex("#221c2a")
  local mx, my = A.px(cx), A.vy(d, 0)
  P.use(K, "shadow")
  for y = -ry, ry do for x = -rx, rx do
    if (x * x) / ((rx + 0.5) ^ 2) + (y * y) / ((ry + 0.5) ^ 2) <= 1 and (mx + x + my + y) % 2 == 0 then
      local own = K.owner[math.floor(my + y + K.oy) * K.w + math.floor(mx + x + K.ox)]
      if P.alpha(P.get(K, mx + x, my + y)) == 0 or own == "ground" then put(K, mx + x, my + y, SH) end
    end
  end end
  P.use(K, "structure")
end

return A
