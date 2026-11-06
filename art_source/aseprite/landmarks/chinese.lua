-- Chinese layouts (docs/art/culture/chinese.md): yamen hall on a stepped white platform, walled-city gate with a
-- chenglou gate tower, courtyard house.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL

  local function platform(K, s, x0, x1, d, D, h)
    M.block(K, s, x0, x1, d, D, h, { flat = true, merlons = false, wall = "ashlar", wall_c = "#D8D2C4", posts = false, base = false, top_c = "#D0CABC" })
    -- front steps
    local c = col("#D8D2C4")
    P.use(K, "structure")
    for i = 0, 3 do
      local y = A.vy(d - 0.15 * (4 - i), h * i / 4)
      for x = A.px(-0.7), A.px(0.7) do P.put(K, x, y, tone(c, (i % 2 == 0) and 2 or 3)); P.put(K, x, y + 1, tone(c, 4)) end
    end
  end

  SP.yamen = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    platform(K, s, -2.6, 2.6, 1.6, 3.2, 0.8)
    M.block(K, s, -2.2, 2.2, 2.0, 2.6, 3.6, { h0 = 0.8, roof = "curved", rise = 1.2, base = false })
    M.block(K, s, -1.4, 1.4, 2.6, 1.6, 5.2, { roof = "curved", rise = 0.9, base = false, h0 = 4.0 })
    M.door(K, s, 0, 2.0, 1.0, 2.0)
    M.windows(K, s, -2.0, -0.7, 2.0, 1.8, 2, 0.45, 1.0)
    M.windows(K, s, 0.7, 2.0, 2.0, 1.8, 2, 0.45, 1.0)
    for _, x in ipairs({ -1.3, 1.3 }) do Pr.lion(K, x, 0.6) end
    M.banners(K, s, { -2.6, 2.6 }, 1.6, 3.4, 0.4, 1.4)
    M.flag(K, s, 2.75, 0.5, 3.8)
  end

  SP.chenglou = function(K, s)
    M.ground(K, s, 4, { paving = s.paving_c })
    M.block(K, s, -3.7, 3.7, 1.2, 2.2, 4.4, { flat = true, merlons = "rect", wall = "ashlar", wall_c = s.castle_wall_c, posts = false, base = false })
    M.door(K, s, 0, 1.2, 1.4, 2.6, "arch_round")
    -- two-storey gate tower on top of the wall
    M.block(K, s, -2.0, 2.0, 1.8, 1.6, 6.4, { h0 = 4.4, roof = "curved", rise = 0.7, base = false })
    M.block(K, s, -1.5, 1.5, 2.0, 1.2, 8.0, { h0 = 6.8, roof = "curved", rise = 0.9, base = false })
    M.windows(K, s, -1.8, 1.8, 1.8, 5.1, 4, 0.3, 0.6)
    -- barbican: low curved outer wall in front
    M.block(K, s, -3.0, -1.0, 0.2, 0.6, 2.6, { flat = true, merlons = "rect", wall = "ashlar", wall_c = s.castle_wall_c, posts = false, base = false })
    M.block(K, s, 1.0, 3.0, 0.2, 0.6, 2.6, { flat = true, merlons = "rect", wall = "ashlar", wall_c = s.castle_wall_c, posts = false, base = false })
    M.banners(K, s, { -2.6, 2.6 }, 1.2, 4.0, 0.5, 1.6)
    M.flag(K, s, 0, 1.8, 10.4)
  end

  SP.courtyard_house = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.6, 1.5, 2.0, 1.8, 2.6, { roof = "gable", rise = 0.7 })
    M.door(K, s, -0.4, 2.0, 0.7, 1.6)
    M.windows(K, s, 0.3, 1.4, 2.0, 1.0, 1, 0.5, 0.8)
    M.block(K, s, -1.8, 1.8, 0.4, 0.3, 1.1, { roof = "gable", rise = 0.15, over = 0.08, posts = false, base = false })    -- courtyard wall: thin tile coping
    A.door(K, 0.9, 0.4, 0.6, 1.0, "rect", s.door_c)
    Pr.bamboo(K, -1.7, 0.9)
  end

  -- watch tower: square brick-faced tower with a crenellated top, a small curved-roof pavilion on it and
  -- beacon smoke rising beside it (the alarm system of the Song frontier)
  SP.beacon_pavilion = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -0.9, 0.9, 1.2, 1.7, 4.6, { wall = s.castle_wall or "ashlar", wall_c = s.castle_wall_c or s.wall_c,
      flat = true, merlons = "rect" })
    M.door(K, s, 0, 1.2, 0.55, 1.3, "arch_round")
    M.block(K, s, -0.8, 0.8, 1.45, 1.2, 5.8, { h0 = 4.6, roof = "curved", rise = 0.5 })
    A.banner(K, 0, 1.2, 3.6, 0.36, 0.9, s.emblem, s.ec)
    if s.age ~= 1 then                                                -- smoke column from the beacon brazier
      local bx, by = A.px(1.05), A.vy(1.3, 4.6)
      P.use(K, "props")
      for i = 0, 10 do
        local cx = bx + math.floor(math.sin(i * 0.9) * 2) + i
        local cy = by - 3 - i * 6
        local r = 2 + i // 3
        for dy = -r, r do for dx = -r, r do
          if dx * dx + dy * dy <= r * r then
            P.put(K, cx + dx, cy + dy, P.hex((dx + dy > r * 0.6) and "#9A9690" or "#CFCBC3"))
          end
        end end
      end
      P.use(K, "structure")
    end
  end

  -- barracks: long timber hall under a grey tile roof with up-swept eaves, halberd racks, red character banners and
  -- a war drum on its stand
  SP.bing_ying = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.7, 2.7, 2.3, 2.4, 2.3, { roof = "curved", rise = 1.0 })
    M.door(K, s, 0, 2.3, 1.0, 1.7, "rect")
    M.windows(K, s, -2.5, 2.5, 2.3, 1.1, 4, 0.5, 0.6)
    for _, x in ipairs({ -2.5, 2.5 }) do A.standard(K, x, 1.2, 3.8, { form = "qi", field = "#C8382F", ec = "#1D1A19", emblem = "hanzi" }) end
    M.props(K, s, { { "rack", -1.4, 1.0 }, { "rack", 1.4, 1.0 } })
    local dx, dy = A.px(0), A.vy(0.8, 0)                            -- drum on an A-frame stand
    P.use(K, "props")
    P.line(K, dx - 9, dy, dx - 4, dy - 18, C.wood_dark, 1); P.line(K, dx + 9, dy, dx + 4, dy - 18, C.wood_dark, 1)
    P.ellipse(K, dx, dy - 18, 8, 7, C.lacquer_red); P.ellipse(K, dx, dy - 18, 6, 5, C.straw)
    P.use(K, "structure")
  end

  -- archery range: walled yard, round straw targets painted with concentric rings, a covered viewing pavilion
  SP.she_pavilion = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 5.0, 0.4, 1.5, { wall = s.castle_wall or "ashlar", wall_c = s.castle_wall_c or s.wall_c,
      roof = "gable", rise = 0.3 })                                                         -- tile-capped back wall
    for i, x in ipairs({ -1.9, -0.7, 0.5 }) do Pr.target(K, x, 3.8 + (i % 2) * 0.25) end
    M.open_shed(K, s, 1.0, 2.7, 1.6, 1.4, 1.7, { roof = "curved", rise = 0.6, bay = 0.85 })   -- viewing pavilion
    M.props(K, s, { { "rack", -1.4, 1.2 }, { "lion", -2.5, 0.6 } })
    A.standard(K, 0.3, 0.8, 3.6, { form = "qi", field = "#C8382F", ec = "#1D1A19", emblem = "hanzi" })
  end

  -- stable: an open-sided timber shed under a tile roof, troughs, a stone hitching post
  SP.ma_peng = function(K, s)
    M.ground(K, s, 3)
    M.open_shed(K, s, -2.8, 2.8, 2.7, 2.2, 2.1, { roof = "curved", rise = 0.9, bay = 1.4 })
    for i, x in ipairs({ -1.9, -0.4, 1.1 }) do Pr.horse(K, x, 2.8, (i == 2) and "horse_grey" or "horse_bay") end
    M.props(K, s, { { "trough", -1.0, 1.6 }, { "trough", 1.4, 1.6 }, { "hay", 2.4, 1.0 } })
    local hx, hy = A.px(-2.3), A.vy(1.0, 0)                                               -- stone hitching post
    P.use(K, "props"); P.rect(K, hx - 2, hy - 16, hx + 2, hy, P.hex("#9A968C")); P.rect(K, hx - 3, hy - 18, hx + 3, hy - 16, P.hex("#C8C4BC"))
    P.use(K, "structure")
    A.standard(K, 2.75, 0.6, 3.6, { form = "qi", field = "#C8382F", ec = "#1D1A19", emblem = "hanzi" })
  end

  -- blacksmith: a brick workshop with an open front, the double-acting box bellows and a brick forge, crossbow racks
  SP.box_bellows_forge = function(K, s)
    M.ground(K, s, 2)
    M.open_shed(K, s, -1.85, 1.85, 2.2, 1.6, 2.1, { wall = s.castle_wall or "ashlar", wall_c = s.castle_wall_c or s.wall_c,
      roof = "curved", rise = 0.7, bay = 1.2 })
    M.props(K, s, { { "forge", -0.6, 2.4 }, { "bellows", 0.6, 2.4 }, { "anvil", 0.4, 0.8 }, { "rack", -1.3, 0.8 } })
    Pr.chimney(K, -0.6, 3.6, 2.6, 3.9, "stone_grey")
  end

  -- lumber camp: a bamboo-and-timber shed, log stacks, the two-man frame saw
  SP.bamboo_shed = function(K, s)
    M.ground(K, s, 2)
    M.open_shed(K, s, -1.85, 0.4, 2.6, 1.2, 1.8, { roof = "curved", rise = 0.5, bay = 0.75, post_c = "#8A9A4A" })
    M.props(K, s, { { "logs", -1.6, 1.0, 1.2, 3 }, { "sawhorse", 0.9, 0.7 }, { "bamboo", 1.6, 2.9 }, { "logs", 0.9, 1.7, 0.8, 2 } })
  end

  -- mining camp: a timber adit into the hillside, baskets on carrying poles, an ore crusher
  SP.timber_adit = function(K, s)
    M.ground(K, s, 2)
    Pr.adit(K, -0.4, 2.7, "#8A7A60")
    M.props(K, s, { { "basket", -1.4, 0.7, "gold" }, { "basket", -0.9, 0.7, "gold" }, { "ore", 1.2, 1.2, "stone_grey", 8 } })
    local px, py = A.px(-1.15), A.vy(0.7, 0)                                                -- carrying pole between the baskets
    P.use(K, "props"); P.line(K, px - 10, py - 12, px + 10, py - 12, C.wood, 1); P.use(K, "structure")
    local cx, cy = A.px(1.4), A.vy(0.4, 0)                                                  -- trip-hammer ore crusher
    P.use(K, "props")
    P.rect(K, cx - 8, cy - 4, cx + 8, cy, P.hex("#9A968C")); P.line(K, cx - 10, cy - 12, cx + 8, cy - 6, C.wood_dark, 2)
    P.rect(K, cx + 5, cy - 9, cx + 9, cy - 4, C.wood); P.vline(K, cx - 6, cy - 14, cy - 4, C.wood_dark)
    P.use(K, "structure")
  end
end
