-- Briton layouts (docs/art/culture/britons.md): Norman great tower with corner turrets and a forebuilding,
-- Edwardian concentric castle with a twin-towered gatehouse, cruck-framed thatched cottage, archery butts,
-- thatched stable.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL

  local function pilasters(K, s, x0, x1, d, h, n)
    local c = col(s.wall_c)
    P.use(K, "structure")
    for i = 0, n do
      local x = A.px(x0 + (x1 - x0) * i / n)
      for y = A.vy(d, h), A.vy(d, 0) do P.put(K, x - 1, y, tone(c, 2)); P.put(K, x, y, tone(c, 2)); P.put(K, x + 1, y, tone(c, 4)) end
    end
  end

  SP.norman_keep = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    M.block(K, s, 1.0, 2.8, 2.6, 2.0, 2.6, { roof = "gable", rise = 1.0 })                    -- hall beside it
    M.windows(K, s, 1.2, 2.6, 2.6, 1.0, 2, 0.3, 0.6)
    M.block(K, s, -2.2, 1.0, 2.2, 2.8, 6.6, { flat = true })
    for _, x in ipairs({ -2.2, 1.0 }) do M.block(K, s, x - 0.3, x + 0.3, 2.0, 0.6, 7.6, { flat = true, base = false }) end
    pilasters(K, s, -2.2, 1.0, 2.2, 6.6, 3)
    for i = 0, 2 do M.windows(K, s, -2.0, 0.8, 2.2, 1.6 + i * 1.6, 3, 0.22, 0.6) end
    -- forebuilding with the first-floor stair
    M.block(K, s, -1.4, 0.2, 1.4, 0.8, 3.0, { flat = true, base = false })
    A.door(K, -0.6, 1.4, 0.7, 1.4, "arch_round", s.door_c)
    P.use(K, "structure")
    local c = col(s.wall_c)
    for i = 0, 6 do P.rect(K, A.px(0.3) + i * 4, A.vy(1.3, i * 0.22), A.px(0.3) + i * 4 + 4, A.vy(1.3, 0), tone(c, (i % 2 == 0) and 2 or 3)) end
    M.banners(K, s, { -1.5, 0.3 }, 2.2, 5.4, 0.4, 1.2)
    M.props(K, s, { { "well", 2.2, 0.6 }, { "hay", -2.4, 0.6 } })
    M.flag(K, s, -0.6, 2.4, 9.0)
  end

  SP.concentric = function(K, s)
    M.ground(K, s, 4, { paving = s.paving_c })
    M.block(K, s, -2.8, 2.8, 3.6, 2.6, 5.4, { flat = true })                                    -- inner ward wall
    for _, x in ipairs({ -2.6, 2.6 }) do A.round_tower(K, x, 3.4, 0.9, 6.6, "ashlar", s.wall_c, "crenel", { merlon = "rect" }) end
    M.block(K, s, -3.7, 3.7, 0.7, 0.6, 3.0, { flat = true, base = false })                      -- outer, lower wall
    for _, x in ipairs({ -3.5, 3.5 }) do A.round_tower(K, x, 0.3, 0.7, 3.8, "ashlar", s.wall_c, "crenel", { merlon = "rect" }) end
    -- massive twin-towered gatehouse
    for _, x in ipairs({ -0.85, 0.85 }) do A.round_tower(K, x, 0.4, 0.8, 5.8, "ashlar", s.wall_c, "crenel", { merlon = "rect", windows = 2 }) end
    M.block(K, s, -0.6, 0.6, 0.9, 0.8, 5.2, { flat = true, base = false })
    M.door(K, s, 0, 0.9, 0.9, 2.0, "gate")
    M.banners(K, s, { -2.3, 2.3 }, 0.7, 2.8, 0.5, 1.2)
    M.flag(K, s, 0, 3.6, 8.0)
  end

  SP.cruck_cottage = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.6, 1.4, 1.2, 2.2, 1.9, { wall = "plaster", wall_c = s.plaster_c, timber = s.timber_c, roof = "hip",
      roof_mat = "thatch", roof_c = s.palette.thatch, rise = 1.4, over = 0.45, ridge = s.palette.thatch, base = false })
    M.door(K, s, -0.8, 1.2, 0.65, 1.45, "rect")
    A.window(K, 0.5, 1.2, 0.8, 0.45, 0.45, "rect", { shutters = s.timber_c, frame = s.timber_c })
    Pr.fence(K, -1.9, 1.9, 0.25)
    M.props(K, s, { { "hay", 1.6, 1.0 } })
  end

  SP.butts = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, -1.0, 4.2, 1.2, 1.9, { wall = "planks", wall_c = s.timber_c, roof = "hip", roof_mat = "thatch", roof_c = s.palette.thatch, rise = 0.7, base = false })
    for i, x in ipairs({ -0.4, 0.8, 2.0 }) do                                                    -- turf-mound butts with targets
      local px, yb = A.px(x), A.vy(3.6, 0)
      P.use(K, "props")
      Pr.blob(K, px, yb - 6, 14, 8, P.hex("#5E8A3A"), i)
      P.use(K, "structure")
      Pr.target(K, x, 3.4)
    end
    for i, x in ipairs({ -2.2, -1.2 }) do Pr.target(K, x, 2.4) end
    M.props(K, s, { { "rack", 1.6, 1.0 }, { "barrel", 2.4, 0.6 } })
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.flag(K, s, -2.6, 0.7, 3.8)
  end

  SP.thatch_stable = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 3.0, 2.6, 2.3, { wall = "plaster", wall_c = s.plaster_c, timber = s.timber_c, roof = "gable",
      roof_mat = "thatch", roof_c = s.palette.thatch, rise = 1.3, over = 0.45, ridge = s.palette.thatch })
    for x = -2.3, 2.2, 1.15 do A.door(K, x + 0.45, 3.0, 0.8, 1.6, "rect", s.door_c) end
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.props(K, s, { { "horse", -1.6, 1.4, "horse_bay" }, { "horse", 1.2, 1.1, "horse_grey" }, { "trough", 0.0, 1.9 }, { "hay", 2.3, 2.2 } })
    M.flag(K, s, 2.75, 2.6, 4.2)
  end

  -- watch tower: square stone tower, crenels hidden under a timber hoarding (brattice) with a pent roof
  SP.hoarding_tower = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -0.85, 0.85, 1.3, 1.6, 5.2, { flat = true, merlons = false })
    M.windows(K, s, -0.4, 0.4, 1.3, 3.0, 1, 0.22, 0.6)
    M.door(K, s, 0, 1.3, 0.55, 1.2, "arch_round")
    M.block(K, s, -1.12, 1.12, 1.05, 2.0, 6.2, { h0 = 5.2, wall = "planks", wall_c = s.timber_c or "wood", roof = "hip",
      rise = 0.75, roof_mat = "shingle", roof_c = "#6A4A30", base = false, timber = false, posts = false })
    A.banner(K, 0, 1.3, 4.6, 0.36, 0.9, s.emblem, s.ec)
  end
end
