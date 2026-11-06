-- Mongol layouts (docs/art/culture/mongols.md): everything is built around the felt ger (lattice wall, three rope
-- bands, low conical roof, toono smoke ring, orange door), ger-carts, horse lines, tug standards; the castle is a
-- Karakorum-style rammed-earth enclosure with timber gate towers.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL
  local function N(x, y, s) return P.noise(x, y, s or 7) end

  -- ger: centre x (m), front of the wall at depth d, radius r (m), wall height hw; optional cart platform
  local function ger(K, s, cx, d, r, hw, opt)
    opt = opt or {}
    local felt, rope = col(s.felt_c), col(s.rope_c)
    local h0 = opt.cart and 0.6 or 0
    if opt.cart then                                                             -- ox-cart platform with wheels
      P.use(K, "props")
      local x0, x1 = A.px(cx - r - 0.3), A.px(cx + r + 0.3)
      for y = A.vy(d, 0.6), A.vy(d, 0.35) do for x = x0, x1 do P.put(K, x, y, tone(col(s.door_c), (y == A.vy(d, 0.6)) and 2 or 3)) end end
      for _, wx in ipairs({ cx - r * 0.6, cx + r * 0.6 }) do P.ellipse(K, A.px(wx), A.vy(d, 0.3), 9, 9, C.wood_dark); P.ellipse(K, A.px(wx), A.vy(d, 0.3), 6, 6, C.wood); P.put(K, A.px(wx), A.vy(d, 0.3), C.iron) end
      P.line(K, x0 - 30, A.vy(d, 0.4), x0, A.vy(d, 0.5), C.wood_dark, 2)
      P.use(K, "structure")
    end
    A.shadow_ellipse(K, cx + 0.3, d + r * 0.4, math.floor(r * 34), math.floor(r * 8))
    local x0, x1 = A.px(cx - r), A.px(cx + r) - 1
    local yb, yt = A.vy(d, h0), A.vy(d, h0 + hw)
    P.use(K, "structure")
    for y = yt, yb do for x = x0, x1 do
      local fr = (x - x0) / math.max(1, x1 - x0)
      local sh = (fr < 0.15) and 2 or ((fr < 0.6) and 3 or ((fr < 0.85) and 4 or 5))
      local v = tone(felt, sh)
      if N(x, y, 19) < 0.06 then v = tone(felt, sh + 1) end
      P.put(K, x, y, v)
    end end
    for _, f in ipairs({ 0.18, 0.5, 0.82 }) do local yy = math.floor(yt + (yb - yt) * f) for x = x0, x1 do P.put(K, x, yy, tone(rope, 3)) end end
    -- roof: low cone, roof poles radiating from the toono
    P.use(K, "roof")
    local apex = A.vy(d + r, h0 + hw + r * 0.55)
    local mid = (x0 + x1) / 2
    for y = apex, yt + 1 do
      local t = (y - apex) / math.max(1, yt + 1 - apex)
      local hwid = (x1 - x0) / 2 * (0.25 + 0.75 * t) + 3 * t
      for x = math.floor(mid - hwid), math.floor(mid + hwid) do
        local fr = (x - (mid - hwid)) / math.max(1, 2 * hwid)
        local v = tone(felt, (fr < 0.3) and 2 or ((fr < 0.7) and 3 or 4))
        if math.floor((x - mid) / math.max(1, hwid) * 8 + 8) % 2 == 0 and t > 0.2 then v = tone(felt, (fr < 0.3) and 3 or 4) end
        P.put(K, x, y, v)
      end
    end
    for x = x0 - 3, x1 + 3 do P.put(K, x, yt + 1, tone(rope, 4)) end
    -- toono: orange-painted smoke ring with a team-coloured cloth flap
    local tw = math.floor((x1 - x0) * 0.13)
    P.use(K, "structure")
    for x = math.floor(mid - tw), math.floor(mid + tw) do P.put(K, x, apex - 1, tone(col(s.door_c), 2)); P.put(K, x, apex, tone(col(s.door_c), 4)) end
    P.use(K, "team")
    for x = math.floor(mid - tw), math.floor(mid + tw) do for y = apex + 1, apex + 4 do P.put(K, x, y, (y == apex + 1) and C.TEAM_L or C.TEAM) end end
    P.use(K, "structure")
    -- orange door with a knot pattern
    if not opt.no_door then
      local dw = math.max(0.5, r * 0.32)
      A.door(K, cx - r * 0.25, d, dw, math.min(hw * 0.85, 1.4), "rect", s.door_c, { frame = s.door_c })
    end
    return apex
  end
  M.ger = ger

  SP.ger_house = function(K, s)
    M.ground(K, s, 2)
    ger(K, s, -0.2, 1.4, 1.35, 1.2)
    M.props(K, s, { { "cart", 1.4, 0.4 }, { "jar", -1.7, 0.6 } })
  end

  SP.ordo = function(K, s)
    M.ground(K, s, 3)
    ger(K, s, -2.0, 3.6, 0.85, 0.9)
    ger(K, s, 2.0, 3.8, 0.8, 0.9)
    ger(K, s, 0, 1.9, 2.0, 1.6, { cart = true })
    for _, x in ipairs({ -1.4, 1.4 }) do A.tug(K, x, 0.6, 3.6) end
    M.flag(K, s, 2.7, 0.6, 3.6)
  end

  SP.ger_camp = function(K, s)
    M.ground(K, s, 3)
    ger(K, s, -1.6, 3.3, 1.1, 1.1); ger(K, s, 1.5, 3.4, 1.0, 1.0); ger(K, s, -0.2, 1.7, 1.25, 1.2)
    Pr.fence(K, -2.8, 2.8, 0.3)
    M.props(K, s, { { "rack", 1.9, 1.0 }, { "dummy", -2.2, 0.8 } })
    A.tug(K, 2.5, 1.8, 3.6, "#2a2026")
  end

  SP.steppe_range = function(K, s)
    M.ground(K, s, 3)
    ger(K, s, -2.0, 3.8, 0.8, 0.9)
    for i, x in ipairs({ -0.8, 0.0, 0.8, 1.6 }) do                         -- leather target cylinders
      local px, yb = A.px(x), A.vy(3.2, 0)
      P.use(K, "props")
      for y = yb - 12, yb do for xx = px - 3, px + 3 do P.put(K, xx, y, tone(col(s.palette.rawhide), (xx < px - 1) and 2 or 3)) end end
      P.hline(K, px - 3, px + 3, yb - 6, C.red)
      P.use(K, "structure")
    end
    Pr.target(K, -0.4, 2.0); Pr.target(K, 1.2, 1.8)
    Pr.hitching(K, -2.6, 2.6, 0.5)
    A.tug(K, 2.6, 0.6, 3.6)
  end

  SP.horse_line = function(K, s)
    M.ground(K, s, 3)
    ger(K, s, -2.0, 3.8, 0.8, 0.9)
    Pr.hitching(K, -2.6, 2.6, 2.4)
    M.props(K, s, { { "horse", -1.4, 1.9, s.palette.dun }, { "horse", 0.2, 1.8, "horse_dark" }, { "horse", 1.8, 1.9, "horse_grey" },
                    { "trough", 0.0, 0.6 }, { "hay", 2.3, 0.6 } })
    A.tug(K, 2.7, 2.6, 3.4)
  end

  SP.karakorum = function(K, s)
    M.ground(K, s, 4)
    ger(K, s, 0, 3.8, 1.9, 1.5)
    M.block(K, s, -3.6, 3.6, 0.9, 0.6, 2.6, { flat = true, merlons = false, base = false })
    -- timber gate towers with grey Chinese-style tiled roofs
    for _, x in ipairs({ -0.9, 0.9 }) do
      M.block(K, s, x - 0.5, x + 0.5, 0.6, 0.9, 3.4, { wall = "planks", wall_c = s.timber_c, roof = "curved", roof_mat = "east", roof_c = s.roof_c, rise = 0.5, base = false })
    end
    M.door(K, s, 0, 0.9, 1.0, 2.0, "rect")
    for _, x in ipairs({ -2.6, 2.6 }) do A.tug(K, x, 0.4, 3.8) end
    M.flag(K, s, 0, 3.8, 6.6)
  end

  SP.timber_lookout = function(K, s)
    M.ground(K, s, 2)
    local px0, px1 = A.px(-0.8), A.px(0.8)
    local yb, yt = A.vy(1.0, 0), A.vy(1.0, 5.6)
    P.use(K, "structure")
    for _, x in ipairs({ px0, px1 - 2 }) do P.rect(K, x, yt, x + 2, yb, C.wood) end
    for y = yt + 8, yb - 8, 24 do P.line(K, px0, y, px1, y + 22, C.wood_dark, 1); P.line(K, px1, y, px0, y + 22, C.wood_dark, 1) end
    M.block(K, s, -1.05, 1.05, 1.0, 1.4, 6.6, { wall = "felt", wall_c = s.felt_c, roof = "hip", roof_mat = "felt", roof_c = s.felt_c, rise = 0.6, base = false, h0 = 5.6 })
    A.tug(K, 0.6, 1.6, 8.2, "#2a2026")
  end

  local function ger_work(K, s, list, flagx)
    M.ground(K, s, 2)
    ger(K, s, -0.9, 2.4, 1.0, 1.0)
    M.props(K, s, list)
    A.tug(K, flagx or 1.7, 0.6, 3.0)
  end
  SP.ger_smith = function(K, s) ger_work(K, s, { { "forge", 0.9, 1.2 }, { "anvil", 0.6, 0.5 }, { "barrel", 1.6, 1.6 } }) end
  SP.ger_lumber = function(K, s) ger_work(K, s, { { "logs", 0.3, 1.4, 1.2, 3 }, { "cart", -0.6, 0.4 }, { "stump", 1.5, 0.6 } }) end
  SP.ger_mine = function(K, s) ger_work(K, s, { { "ore", 0.8, 1.2, "stone_grey", 10 }, { "ore", 1.5, 0.5, "gold", 7 }, { "cart", -0.4, 0.4, "gold" } }) end
  SP.ger_quern = function(K, s)                     -- storage ger with a stone hand-quern and grain sacks
    ger_work(K, s, { { "sacks", 0.9, 1.0 }, { "sacks", 1.5, 1.5 }, { "cart", -0.5, 0.35 } })
    local px, yb = A.px(1.0), A.vy(0.5, 0)
    P.use(K, "props")
    P.ellipse(K, px, yb - 4, 7, 3, C.stone_grey); P.ellipse(K, px, yb - 7, 6, 2, P.shade(C.stone_grey, 1.15)); P.vline(K, px + 3, yb - 13, yb - 8, C.wood)
    P.use(K, "structure")
  end
  SP.caravan = function(K, s)
    M.T.market(K, s)
    ger(K, s, 2.3, 0.9, 0.6, 0.7)
  end
end
