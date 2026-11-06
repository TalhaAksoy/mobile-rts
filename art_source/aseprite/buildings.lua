-- Building layouts v2 (32 px/m, 3/4 oblique view). Sizes in metres (footprint: 2 tiles = 4 m). Each type has a
-- generic layout built from the civ's architectural vocabulary (civs/<civ>.lua _buildings, researched in
-- docs/art/culture/<civ>.md); civ-specific landmark layouts are chosen by keys such as tc = "kulliye".
-- Output per building: layered .aseprite source + t0/t1 PNGs + meta JSON for sprite_manifest.json.
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local A = dofile(GEN_ROOT .. "/arch.lua")
local Pr = dofile(GEN_ROOT .. "/props.lua")
local CIVS = dofile(GEN_ROOT .. "/civs.lua")
local M = {}
M.PX_PER_M = 32
M.TYPES = { town_center = 3, house = 2, barracks = 3, archery_range = 3, stable = 3, castle = 4, watch_tower = 2,
            blacksmith = 2, lumber_camp = 2, mining_camp = 2, mill = 2 }
M.UI_ONLY = { market = 3, stone_wall = 2 }
local LAYERS = { "outline", "shadow", "ground", "structure", "roof", "team", "props" }
local col, tone = A.col, A.tone
M.A, M.Pr = A, Pr

---------------------------------------------------------------------------------------------- civ-aware pieces
local function wall_opts(s, o)
  o = o or {}
  return { band_c = s.band_c, glazed = s.glazed_c, mortar = s.mortar_c, ablaq_c = s.ablaq_c, timber = o.timber,
           braces = o.braces, posts = o.posts, blind_arches = o.blind_arches, base = o.base, base_h = o.base_h,
           eave_shadow = o.eave_shadow or 3, h0 = o.h0, stripe = o.stripe, timber_step = o.timber_step }
end

-- one building block: front facade + roof in the civ style. o: wall, wall_c, roof (form), roof_mat, roof_c, rise,
-- flat (stone terrace instead of a roof), merlons, upper = {h, wall, c, timber, jetty}, base
function M.block(K, s, x0, x1, d, D, h, o)
  o = o or {}
  local wall, wc = o.wall or s.wall, o.wall_c or s.wall_c
  local f = A.facade(K, x0, x1, d, h, wall, wc, wall_opts(s, { base = (o.base ~= false) and (o.base or s.base_c) or nil,
    timber = o.timber or ((o.timber ~= false) and s.facade_timber or nil), braces = o.braces or s.braces,
    posts = (o.posts ~= false) and (o.posts or s.posts_c) or nil, blind_arches = o.blind_arches or s.blind_arches_c, stripe = o.stripe, h0 = o.h0 }))
  local top_h = h
  if o.upper then                                                  -- upper storey (jettied out over the street)
    local u = o.upper
    local jd = d - (u.jetty or 0)
    if u.jetty then
      P.use(K, "props")
      for x = x0, x1, 0.6 do local bx = A.px(x) P.line(K, bx, A.vy(d, h - 0.25), bx, A.vy(jd, h), tone(col(s.timber_c or "wood_dark"), 4), 1) end
      P.use(K, "structure")
    end
    A.facade(K, x0 - (u.jetty or 0) * 0.3, x1 + (u.jetty or 0) * 0.3, jd, h + u.h, u.wall or "plaster", u.c or s.plaster_c or "plaster",
      wall_opts(s, { h0 = h, timber = u.timber, braces = u.braces }))
    top_h = h + u.h
    d = jd
  end
  local r
  if o.flat or o.roof == "flat" or (not o.roof and s.roof == "flat") then
    local tc = col(o.top_c or s.top_c or wc)
    P.use(K, "roof")
    local yt, yb = A.vy(d + D, top_h), A.vy(d, top_h)
    -- terrace seen from above: a smooth lit surface (no wall coursing, so it reads as a roof, not more wall),
    -- a bright parapet lip at the front edge and a dark cornice shadow line on the facade just below it
    local px0, px1 = A.px(x0), A.px(x1) - 1
    for y = yt, yb do for x = px0, px1 do
      local v
      if y == yb or y == yb - 1 then v = tone(tc, 1)
      elseif y == yt or x == px0 or x == px1 then v = tone(tc, 3)
      else
        local t = P.noise(x, y, 41)
        v = tone(tc, (t < 0.06) and 3 or 2)
        if (yb - y) % 9 == 0 and t < 0.6 then v = tone(tc, 3) end           -- faint screed joints
      end
      P.put(K, x, y, v)
    end end
    P.use(K, "structure")
    for x = px0, px1 do P.put(K, x, yb + 1, tone(col(wc), 5)) end
    r = { top = yt, yr = yt, ye = yb }
    local mk = o.merlons
    if mk == nil then mk = s.merlon end
    if mk then A.merlons(K, x0, x1, d, top_h, wc, mk) end
  else
    local form = o.roof or s.roof or "hip"
    r = A.roof(K, form, x0, x1, d, D, top_h, o.rise or (D * (s.pitch or 0.45)), o.roof_mat or s.roof_mat, o.roof_c or s.roof_c,
      { over = o.over or s.over, ornament = o.ornament or s.ornament, ornament_c = s.ornament_c, wall_c = wc, gable_c = o.gable_c or wc,
        gable_mat = o.gable_mat or wall, timber = o.gable_timber or s.gable_timber, steps = s.steps, blind_c = s.blind_c,
        crossed_ends = s.crossed_ends, ridge = o.ridge or s.ridge, glazed = s.glazed_c })
  end
  r.facade = f
  r.d = d
  r.h = top_h
  return r
end

local function door(K, s, cx, d, w, h, kind)
  A.door(K, cx, d, w, h, kind or s.arch or "rect", s.door_c, { frame = s.frame_c, muqarnas = (s.muqarnas_c and w >= 1.2) and s.muqarnas_c or nil })
end
local function windows(K, s, x0, x1, d, hs, n, w, hh)
  local step = (x1 - x0) / n
  local kind = s.window or "rect"
  for i = 0, n - 1 do
    A.window(K, x0 + step * (i + 0.5), d, hs, w or 0.35, hh or 0.6, kind,
      { shutters = s.shutters, lattice = (kind == "lattice"), frame = s.frame_c, tile_lunette = s.tile_c, glow = s.glow })
  end
end
local function banners(K, s, xs, d, h, w, hh) for _, x in ipairs(xs) do A.banner(K, x, d, h, w or 0.45, hh or 1.1, s.emblem, s.ec) end end
local function flag(K, s, x, d, h) A.flag(K, x, d, h, 14, s.emblem, s.flag_ec or s.ec) end
local function ground(K, s, tiles, opt)
  if s.age == 3 and s.paving_c and not (opt and opt.paving) then opt = { paving = s.paving_c or "#A89A84" } end   -- Age III: paved yards
  A.ground(K, -tiles + 0.1, tiles - 0.1, 0.05, tiles * 2 - 0.1, s.ground or "dirt", opt)
end
local function props(K, s, list) for _, q in ipairs(list) do local f = Pr[q[1]] if f then f(K, q[2], q[3], q[4], q[5]) end end end
local function civ_props(K, s, spots)
  local list = s.props or {}
  for i, sp in ipairs(spots) do
    local name = list[((i - 1) % math.max(1, #list)) + 1]
    if name and Pr[name] then Pr[name](K, sp[1], sp[2]) end
  end
end
local function round_tower(K, s, cx, d, r, h, top)
  return A.round_tower(K, cx, d, r, h, s.tower_wall or s.wall, s.tower_wall_c or s.wall_c, top or s.tower_top or "cone",
    { top_c = s.tower_c, top_mat = s.tower_mat, finial = s.finial, merlon = s.merlon, band_c = s.band_c, glazed = s.glazed_c })
end
M.door, M.windows, M.banners, M.flag, M.ground, M.props, M.civ_props, M.round_tower = door, windows, banners, flag, ground, props, civ_props, round_tower

-- open-fronted shed (shooting shed, open stable, lean-to): the block with its front opened into a dark interior
-- between posts every `bay` m. o: the M.block options plus post_c
function M.open_shed(K, s, x0, x1, d, D, h, o)
  o = o or {}
  local b = M.block(K, s, x0, x1, d, D, h, o)
  local f = b.facade
  P.use(K, "structure")
  for y = f.yt + 4, f.yb - 2 do for x = f.x0 + 3, f.x1 - 3 do P.put(K, x, y, tone(P.hex("#2a2234"), (y < f.yt + 9) and 4 or 3)) end end
  local pc = tone(col(o.post_c or s.posts_c or s.timber_c or "wood_dark"), 3)
  local bay = A.px(o.bay or 1.2)
  for x = f.x0, f.x1 - 2, bay do P.rect(K, x, f.yt, x + 2, f.yb, pc) end
  P.rect(K, f.x1 - 2, f.yt, f.x1, f.yb, pc)
  return b
end

-- a mill stream / race on the ground: x0..x1 m wide, from d1 (behind) to d0 (front) m, rounded ends, dark banks,
-- light ripples; stays inside the pad so it never looks cut off at the sprite edge
function M.stream(K, x0, x1, d0, d1)
  P.use(K, "ground")
  local W = P.hex("#4a86b8")
  local px0, px1 = A.px(x0), A.px(x1)
  local ya, yb = -math.floor(d1 * A.X), -math.floor(d0 * A.X)
  local r = (px1 - px0) / 2
  local cx = (px0 + px1) / 2
  for y = ya, yb do for x = px0, px1 do
    local ey = math.min(y - ya, yb - y)
    local inside = true
    if ey < r then local dx, dy = (x - cx) / r, (r - ey) / r if dx * dx + dy * dy > 1 then inside = false end end
    if inside then
      local edge = (x <= px0 + 1 or x >= px1 - 1)
      local v = edge and tone(W, 5) or tone(W, (((x * 3 + y * 7) % 23) < 2) and 1 or ((((x + y) % 6) == 0) and 2 or 3))
      P.put(K, x, y, v)
    end
  end end
  P.use(K, "structure")
end

-- a lookout hut on four timber legs with X bracing and a narrow side ladder (stilt watch towers)
function M.stilts(K, s, x0, x1, d, D, h, c)
  c = col(c or s.timber_c or "wood")
  P.use(K, "structure")
  local fx0, fx1 = A.px(x0) + 1, A.px(x1) - 3
  local yb, yt = A.vy(d, 0), A.vy(d, h)
  local byb = A.vy(d + D - 0.3, 0)
  for _, x in ipairs({ fx0 + 4, fx1 - 4 }) do P.rect(K, x, yt, x + 1, byb, tone(c, 4)) end       -- back legs
  for _, x in ipairs({ fx0, fx1 }) do P.rect(K, x, yt, x + 2, yb, tone(c, 3)); P.vline(K, x, yt, yb, tone(c, 2)) end
  local seg = math.max(18, (yb - yt) // 3)
  for y = yt + 4, yb - seg + 2, seg do
    P.line(K, fx0 + 2, y, fx1, y + seg - 2, tone(c, 4), 1)
    P.line(K, fx1, y, fx0 + 2, y + seg - 2, tone(c, 4), 1)
    P.hline(K, fx0, fx1 + 2, y, tone(c, 3))
  end
  local lx = fx1 + 5                                                                    -- ladder at the side
  P.use(K, "props")
  P.line(K, lx, yt + 2, lx + 3, yb, tone(c, 3), 1); P.line(K, lx + 5, yt + 2, lx + 8, yb, tone(c, 3), 1)
  for y = yt + 6, yb - 2, 6 do local t = (y - yt) / (yb - yt) P.hline(K, lx + math.floor(t * 3), lx + 5 + math.floor(t * 3), y, tone(c, 2)) end
  P.use(K, "structure")
end

---------------------------------------------------------------------------------------------- generic layouts
local T = {}

T.house = function(K, s)
  ground(K, s, 2)
  M.block(K, s, -1.6, 1.4, 1.1, 2.3, 2.6, { roof = s.house_roof })
  door(K, s, -0.7, 1.1, 0.7, 1.5)
  windows(K, s, -0.1, 1.3, 1.1, 1.1, 2)
  props(K, s, { { "barrel", -1.75, 0.6 }, { "crate", 1.55, 0.5 } })
  civ_props(K, s, { { -1.6, 0.3 } })
end

T.barracks = function(K, s)
  ground(K, s, 3)
  M.block(K, s, -2.6, 2.2, 1.9, 3.2, 3.2)
  if s.tower_top and s.tower_top ~= "none" then round_tower(K, s, -2.5, 1.6, 0.65, 4.8) end
  door(K, s, 0, 1.9, 1.3, 2.1, s.arch)
  windows(K, s, -2.2, 2.0, 1.9, 1.6, 4)
  banners(K, s, { -1.1, 1.1 }, 1.9, 3.0)
  props(K, s, { { "rack", 1.6, 0.9 }, { "dummy", -1.6, 0.9 }, { "dummy", -0.9, 0.5 } })
  flag(K, s, 2.6, 1.3, 4.6)
end

T.archery_range = function(K, s)
  ground(K, s, 3)
  local b = M.block(K, s, -2.7, 0.6, 4.0, 1.6, 2.2, { roof = (s.roof == "flat") and nil or "gable", flat = (s.roof == "flat") })
  local f = b.facade
  P.use(K, "structure")
  for y = f.yt + 4, f.yb - 2 do for x = f.x0 + 4, f.x1 - 4 do P.put(K, x, y, tone(P.hex("#2a2234"), (y < f.yt + 8) and 4 or 3)) end end
  for x = f.x0 + 2, f.x1, 30 do P.rect(K, x, f.yt, x + 2, f.yb, tone(col(s.timber_c or "wood_dark"), 3)) end
  for i, x in ipairs({ -2.3, -1.2, -0.1, 1.0, 2.1 }) do Pr.target(K, x, 3.0 + (i % 2) * 0.3) end
  Pr.fence(K, -2.8, 2.8, 0.4)
  props(K, s, { { "hay", 2.2, 3.4 }, { "barrel", 2.5, 2.2 } })
  flag(K, s, 2.7, 1.2, 4.4)
end

T.stable = function(K, s)
  ground(K, s, 3)
  M.block(K, s, -2.8, 2.8, 3.0, 2.6, 2.4, { roof = (s.roof == "flat") and nil or (s.stable_roof or "gable"), flat = (s.roof == "flat") })
  for x = -2.4, 2.2, 1.15 do
    A.door(K, x + 0.45, 3.0, 0.8, 1.6, "rect", s.door_c, { frame = s.frame_c })
    local hx, hy = A.px(x + 0.45), A.vy(3.0, 1.75)
    P.use(K, "props")
    P.rect(K, hx - 2, hy - 9, hx + 2, hy, P.hex("#7a4a2a")); P.put(K, hx - 2, hy - 9, P.hex("#3c2a24")); P.put(K, hx - 1, hy - 6, P.hex("#241c26"))
    P.use(K, "structure")
  end
  Pr.fence(K, -2.8, 2.8, 0.35)
  props(K, s, { { "horse", -1.6, 1.4, s.horse_c or "horse_bay" }, { "horse", 1.2, 1.1, "horse_grey" }, { "trough", 0.0, 1.9 }, { "hay", 2.3, 2.2 } })
  flag(K, s, 2.75, 2.6, 4.2)
end

T.castle = function(K, s)
  ground(K, s, 4, { paving = s.paving_c })
  M.block(K, s, -1.7, 1.7, 3.6, 2.8, 6.6, { flat = s.keep_flat, roof = (not s.keep_flat) and s.keep_roof or nil, merlons = s.merlon })
  windows(K, s, -1.4, 1.4, 3.6, 4.2, 3, 0.3, 0.7)
  M.block(K, s, -3.6, 3.6, 0.7, 0.8, 3.2, { flat = true, merlons = s.merlon or "rect", wall = s.castle_wall, wall_c = s.castle_wall_c, base = false })
  for _, x in ipairs({ -3.4, 3.4 }) do round_tower(K, s, x, 0.35, 0.75, 4.6, s.castle_tower_top) end
  for _, x in ipairs({ -0.95, 0.95 }) do round_tower(K, s, x, 0.25, 0.45, 4.0, "crenel") end
  door(K, s, 0, 0.7, 1.3, 2.2, "gate")
  banners(K, s, { -2.2, 2.2 }, 0.7, 3.0, 0.5, 1.3)
  flag(K, s, 0, 3.6, 8.4)
end

T.watch_tower = function(K, s)
  ground(K, s, 2)
  if s.tower_round then
    round_tower(K, s, 0, 1.0, 0.95, 7.2)
  else
    local flat = (not s.tower_roof) and s.roof == "flat"
    M.block(K, s, -0.9, 0.9, 1.2, 1.6, 7.0, { roof = (not flat) and (s.tower_roof or "hip") or nil, flat = flat, rise = 1.4 })
    windows(K, s, -0.6, 0.6, 1.2, 4.8, 1, 0.3, 0.8)
  end
  door(K, s, 0, 1.2, 0.6, 1.3)
  banners(K, s, { 0 }, 1.2, 4.0, 0.4, 1.0)
end

T.town_center = function(K, s)
  ground(K, s, 3, { paving = s.paving_c })
  M.block(K, s, -2.8, 2.8, 1.6, 3.0, 3.6)
  M.block(K, s, -1.0, 1.0, 2.2, 2.2, 6.2, { roof = s.tc_tower_roof, rise = 1.6 })
  if s.tower_top and s.tower_top ~= "none" then for _, x in ipairs({ -2.7, 2.7 }) do round_tower(K, s, x, 1.3, 0.6, 5.0) end end
  door(K, s, 0, 1.6, 1.3, 2.2, s.arch)
  windows(K, s, -2.6, 2.6, 1.6, 1.8, 6)
  banners(K, s, { -1.6, 1.6 }, 1.6, 3.4)
  civ_props(K, s, { { -2.5, 0.5 }, { 2.4, 0.6 } })
end

T.blacksmith = function(K, s)
  ground(K, s, 2)
  local b = M.block(K, s, -1.8, 0.9, 1.6, 2.0, 2.4)
  door(K, s, -1.0, 1.6, 0.7, 1.5)
  local cx = A.px(0.45)
  P.use(K, "props")
  local yt = A.vy(2.6, 3.9)
  for y = yt, A.vy(2.5, 2.4) do for x = cx, cx + 6 do P.put(K, x, y, A.WALL.brick(C.brick, (x == cx) and 2 or 3, x, y, x - cx, y, {})) end end
  for _, q in ipairs({ { 3, -6, 3 }, { 6, -13, 4 }, { 2, -21, 4 } }) do for yy = -q[3], q[3] do for xx = -q[3], q[3] do
    if xx * xx + yy * yy <= q[3] * q[3] and (xx + yy) % 2 == 0 then P.put(K, cx + q[1] + xx, yt + q[2] + yy, C.grey_cloth) end end end end
  P.use(K, "structure")
  props(K, s, { { "forge", 1.4, 1.0 }, { "anvil", 0.3, 0.6 }, { "trough", -1.0, 0.4 }, { "barrel", 1.7, 0.3 } })
  flag(K, s, -1.9, 0.6, 3.4)
end

T.lumber_camp = function(K, s)
  ground(K, s, 2)
  local b = M.block(K, s, -1.9, 0.6, 2.6, 1.2, 2.0, { roof = (s.roof ~= "flat") and "shed" or nil, flat = (s.roof == "flat"), rise = 0.5 })
  local f = b.facade
  P.use(K, "structure")
  for y = f.yt + 2, f.yb - 1 do for x = f.x0 + 3, f.x1 - 3 do P.put(K, x, y, P.hex("#2e2630")) end end
  for x = f.x0 + 1, f.x1, 24 do P.rect(K, x, f.yt, x + 2, f.yb, tone(col(s.timber_c or "wood_dark"), 3)) end
  props(K, s, { { "logs", -1.7, 1.6, 1.6, 3 }, { "logs", 0.6, 0.9, 1.2, 3 }, { "sawhorse", -0.4, 0.5 }, { "stump", 1.4, 2.4 } })
  flag(K, s, 1.8, 1.8, 3.2)
end

T.mining_camp = function(K, s)
  ground(K, s, 2)
  M.block(K, s, -1.9, -0.1, 2.6, 1.2, 2.0, { roof = (s.roof ~= "flat") and "shed" or nil, flat = (s.roof == "flat"), rise = 0.5 })
  Pr.headframe(K, 0.9, 2.4)
  props(K, s, { { "ore", 1.3, 0.8, "stone_grey", 10 }, { "ore", -1.4, 0.7, "gold", 8 }, { "cart", 0.0, 0.6, "gold" } })
  flag(K, s, -1.9, 0.5, 3.2)
end

T.mill = function(K, s)
  ground(K, s, 2)
  M.block(K, s, 0.1, 1.9, 1.4, 1.6, 2.0, { roof = (s.roof ~= "flat") and "gable" or nil, flat = (s.roof == "flat") })
  A.round_tower(K, -0.8, 1.6, 0.85, 3.6, s.mill_wall or s.tower_wall or s.wall, s.mill_wall_c or s.wall_c, "cone",
    { top_c = s.mill_roof_c or s.tower_c or s.roof_c, top_mat = s.mill_roof_mat or s.tower_mat or s.roof_mat, cone_h = 1.2, band_c = s.band_c })
  A.door(K, -0.8, 1.6, 0.5, 1.2, "rect", s.door_c)
  Pr.sails(K, A.px(-0.8), A.vy(1.6, 3.4), 40, s.sails or 4, s.sail_c)
  props(K, s, { { "sacks", 1.3, 0.6 }, { "cart", -0.2, 0.2 } })
  flag(K, s, 1.9, 0.6, 3.0)
end

T.market = function(K, s)
  ground(K, s, 3, { paving = s.paving_c or "stone" })
  M.block(K, s, -2.2, 2.2, 3.4, 2.0, 2.8)
  door(K, s, 0, 3.4, 1.0, 1.8, s.arch)
  for i, x in ipairs({ -2.0, -0.4, 1.2 }) do
    local d = 1.2 + (i % 2) * 0.4
    local x0, x1 = A.px(x), A.px(x + 1.3)
    local yb, yt = A.vy(d, 0), A.vy(d, 1.9)
    P.use(K, "props")
    P.rect(K, x0, A.vy(d, 0.9), x1, yb, C.wood); P.hline(K, x0, x1, A.vy(d, 0.9), C.wood_light)
    P.vline(K, x0, yt, yb, C.wood_dark); P.vline(K, x1, yt, yb, C.wood_dark)
    Pr.blob(K, math.floor((x0 + x1) / 2) - 6, A.vy(d, 1.0), 5, 3, ({ C.orange, C.red, C.green })[i], i)
    Pr.blob(K, math.floor((x0 + x1) / 2) + 6, A.vy(d, 1.0), 5, 3, ({ C.yellow, C.gold, C.brown })[i], i + 3)
    P.use(K, "team")
    for xx = x0 - 2, x1 + 2 do for y = yt - 4, yt do P.put(K, xx, y, (((xx - x0) // 4) % 2 == 0) and ((y == yt - 4) and C.TEAM_L or C.TEAM) or ((y == yt - 4) and C.white or C.cream)) end end
    P.use(K, "structure")
  end
  props(K, s, { { "barrel", -2.6, 0.4 }, { "crate", 2.5, 0.4 }, { "sacks", 2.4, 1.0 } })
  flag(K, s, 0, 3.4, 4.6)
end

T.stone_wall = function(K, s)
  ground(K, s, 2)
  M.block(K, s, -1.9, 1.9, 0.9, 0.9, 3.0, { flat = true, merlons = s.merlon or "rect", wall = s.castle_wall, wall_c = s.castle_wall_c, base = false })
  round_tower(K, s, 0, 0.6, 0.6, 3.8, "crenel")
  banners(K, s, { -1.2, 1.2 }, 0.9, 2.7, 0.4, 1.0)
end
M.T = T

---------------------------------------------------------------------------------------------- civ landmarks
-- Each civ file may add special layouts with M.SPECIAL[name] = function(K, s) ... end (see civs/*.lua), chosen
-- by its _buildings keys: tc, house, castle, mill, watch, barracks, archery, market, stable, smith, lumber, mine.
M.SPECIAL = {}
local SPECIAL_KEY = { town_center = "tc", house = "house", castle = "castle", mill = "mill", watch_tower = "watch",
                      barracks = "barracks", archery_range = "archery", market = "market", stable = "stable",
                      blacksmith = "smith", lumber_camp = "lumber", mining_camp = "mine", stone_wall = "wall_kind" }
local loaded_specials = false
local function load_specials()
  if loaded_specials then return end
  loaded_specials = true
  for _, f in ipairs({ "ottomans", "byzantines", "saracens", "mongols", "chinese", "franks", "britons", "teutons", "japanese", "vikings" }) do
    local path = GEN_ROOT .. "/landmarks/" .. f .. ".lua"
    if app.fs.isFile(path) then
      local add = dofile(path)
      add(M)
    end
  end
end

-- Age I watch post (every civ but the nomads): a plank lookout hut on four legs, roofed in the village material
M.SPECIAL.village_lookout = function(K, s)
  ground(K, s, 2)
  M.stilts(K, s, -0.85, 0.85, 1.0, 1.3, 4.4)
  M.block(K, s, -0.95, 0.95, 1.0, 1.3, 5.4, { h0 = 4.4, wall = "planks", wall_c = s.timber_c or "wood", roof = "hip",
    rise = 0.9, base = false, timber = false, posts = false,
    -- flat-roof civs have no roof colour of their own: a palm-frond / reed thatch hood
    roof_mat = s.roof_c and s.roof_mat or "thatch", roof_c = s.roof_c or "#A88A62" })
  A.banner(K, 0, 1.0, 4.3, 0.36, 0.8, s.emblem, s.ec)
end

---------------------------------------------------------------------------------------------- output
local SHADOW = P.hex("#221c2a")
-- drop shadow of the building onto the ground (light from the upper left -> shadow to the right and down):
-- the walls/roof silhouette shifted, dithered, only where nothing solid stands
local CAST = { structure = true, roof = true, team = true }
function M.cast_shadow(K, dx, dy)
  dx, dy = dx or 9, dy or 4
  local W, H = K.w, K.h
  local marks = {}
  for y = 0, H - 1 - dy do for x = 0, W - 1 - dx do
    if CAST[K.owner[y * W + x]] then
      local tx, ty = x + dx, y + dy
      local own = K.owner[ty * W + tx]
      if (own == nil or own == "ground" or own == "shadow") and (tx + ty) % 2 == 0 then marks[#marks + 1] = ty * W + tx end
    end
  end end
  P.use(K, "shadow")
  for _, i in ipairs(marks) do P.put(K, (i % W) - K.ox, (i // W) - K.oy, SHADOW) end
  P.use(K, "structure")
end

function M.emit(fn, teams, plane_z, paths, extra, ui_only)
  local W, H, AX, AY = 380, 480, 190, 400
  local K = P.canvas(W, H, LAYERS)
  K.ox, K.oy = AX, AY
  K.force = C.team_force({ [SHADOW] = "shadow" })
  K.cur = "structure"
  fn(K)
  M.cast_shadow(K)
  P.split(K)
  local solid = Image(K.flat)
  for _, ln in ipairs({ "shadow", "ground" }) do
    if K.used[ln] then for it in K.layers[ln]:pixels() do if P.alpha(it()) > 0 then solid:drawPixel(it.x, it.y, P.CLEAR) end end end
  end
  local ol = P.sel_outline_of(solid, K.bb)
  local flat = Image(W, H, ColorMode.RGB)
  for _, ln in ipairs({ "ground", "shadow" }) do if K.used[ln] then flat:drawImage(K.layers[ln], Point(0, 0)) end end
  flat:drawImage(ol, Point(0, 0)); flat:drawImage(solid, Point(0, 0))
  K.layers.outline = ol; K.used.outline = true
  local x0, y0, x1, y1 = K.bb[1] - 1, K.bb[2] - 1, K.bb[3] + 1, math.max(K.bb[4] + 1, AY)
  local w, h = x1 - x0 + 1, y1 - y0 + 1
  local spr = Sprite(w, h, ColorMode.RGB)
  local objs = { [LAYERS[1]] = spr.layers[1] }; spr.layers[1].name = LAYERS[1]
  for i = 2, #LAYERS do local L = spr:newLayer(); L.name = LAYERS[i]; objs[LAYERS[i]] = L end
  for _, ln in ipairs(LAYERS) do if K.used[ln] then spr:newCel(objs[ln], 1, P.crop(K.layers[ln], x0, y0, w, h), Point(0, 0)) end end
  app.fs.makeAllDirectories(app.fs.filePath(paths.aseprite))
  spr:saveAs(paths.aseprite); spr:close()
  local img = P.crop(flat, x0, y0, w, h)
  app.fs.makeAllDirectories(app.fs.filePath(paths.png))
  local meta = { w = w, h = h, anchor = { AX - x0 + 0.5, AY - y0 }, px_per_m = M.PX_PER_M, view = "oblique", plane_z = plane_z }
  for k, v in pairs(extra or {}) do meta[k] = v end
  if teams then
    for team = 0, 1 do
      P.recolor(img, C.team_map(team)):saveAs((paths.png:gsub("%.png$", "_t" .. team .. ".png")))
      meta["t" .. team] = paths.res:gsub("%.png$", "_t" .. team .. ".png")
    end
  else
    img:saveAs(paths.png); meta.img = paths.res
  end
  if not ui_only then P.write(paths.meta, P.json(meta)) end
  return meta
end

-- age: 1 / 2 / 3 (ages.lua); 2 = the base design, written without a suffix
function M.build(civ, bid, paths, age)
  load_specials()
  age = age or 2
  local AG = dofile(GEN_ROOT .. "/ages.lua")
  local s = AG.building_spec(CIVS[civ]._buildings, age, civ)
  local tiles = M.TYPES[bid] or M.UI_ONLY[bid]
  local key = s[SPECIAL_KEY[bid] or ""]
  local fn = (key and M.SPECIAL[key]) or T[bid]
  local name = (age == 2) and bid or (bid .. "_a" .. age)
  return M.emit(function(K)
    fn(K, s)
    if age == 3 then AG.dress3(M, K, s, tiles, civ) end
  end, true, tiles * 1.0, {
    aseprite = paths.aseprite, png = paths.png_dir .. "/" .. name .. ".png", res = paths.res_dir .. "/" .. name .. ".png",
    meta = paths.meta }, nil, M.UI_ONLY[bid] ~= nil)
end

return M
