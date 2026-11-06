-- Teutonic layouts (docs/art/culture/teutons.md): Ordensburg convent-castle with a stepped gable and a square
-- corner tower, Malbork-style castle with a gate tower over a moat, Fachwerk house with a red tile gable.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL

  local function hoarding(K, s, x0, x1, d, h)
    local c = col(s.timber_c)
    P.use(K, "props")
    local yt, yb = A.vy(d - 0.2, h + 0.7), A.vy(d - 0.2, h)
    for y = yt, yb do for x = A.px(x0), A.px(x1) do P.put(K, x, y, A.WALL.planks(c, (y == yt) and 2 or 3, x, y, x, y, {})) end end
    for x = A.px(x0), A.px(x1), 6 do P.vline(K, x, yb, yb + 4, tone(c, 4)) end
    P.use(K, "roof")
    for y = yt - 6, yt do for x = A.px(x0) - 2, A.px(x1) + 2 do P.put(K, x, y, A.ROOF.tiles(col(s.roof_c), (y < yt - 3) and 2 or 3, x, yt - y, x, y)) end end
    P.use(K, "structure")
  end

  SP.ordensburg = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    M.block(K, s, -2.8, 1.0, 2.2, 2.6, 4.4, { roof = "stepped", rise = 2.4 })
    M.windows(K, s, -2.5, -0.4, 2.2, 1.4, 3, 0.3, 1.0)
    A.door(K, 0.2, 2.2, 1.0, 2.0, "arch_pointed", s.door_c, { frame = s.frame_c })
    -- square corner tower (bergfried) with a pyramid cap
    M.block(K, s, 1.0, 2.6, 2.0, 1.6, 7.6, { roof = "hip", rise = 2.2 })
    M.windows(K, s, 1.2, 2.4, 2.0, 5.0, 1, 0.3, 0.9)
    A.banner(K, 1.8, 2.0, 4.2, 0.5, 1.4, s.emblem, s.ec)
    M.props(K, s, { { "barrel", -2.4, 0.6 }, { "sacks", -1.9, 0.4 }, { "cart", 2.0, 0.5 } })
    M.flag(K, s, -1.0, 2.6, 7.4)
  end

  SP.malbork = function(K, s)
    M.ground(K, s, 4, { paving = s.paving_c })
    M.block(K, s, -3.0, 0.4, 3.8, 2.4, 5.6, { roof = "stepped", rise = 2.6 })
    M.block(K, s, 0.4, 2.0, 3.5, 1.6, 8.6, { roof = "hip", rise = 2.4 })                     -- main tower
    M.windows(K, s, -2.8, 0.2, 3.8, 2.6, 3, 0.3, 1.1)
    M.block(K, s, 2.0, 3.6, 3.8, 2.4, 4.8, { roof = "gable", rise = 1.6 })
    -- curtain with timber hoardings, gate tower over the moat
    M.block(K, s, -3.7, 3.7, 0.9, 0.6, 3.0, { flat = true, merlons = false, base = false })
    hoarding(K, s, -3.7, -0.9, 0.9, 3.0); hoarding(K, s, 0.9, 3.7, 0.9, 3.0)
    M.block(K, s, -0.8, 0.8, 0.6, 1.0, 5.4, { roof = "hip", rise = 1.6, base = false })
    M.door(K, s, 0, 0.6, 1.0, 2.0, "arch_pointed")
    P.use(K, "ground")                                                                        -- moat
    for y = A.vy(0.3, 0) + 2, -1 do for x = A.px(-3.7), A.px(3.7) do P.put(K, x, y, tone(P.hex("#4a6e8a"), ((x + y) % 7 == 0) and 2 or 3)) end end
    P.use(K, "props")
    for y = A.vy(0.3, 0) + 1, -1 do for x = A.px(-0.5), A.px(0.5) do P.put(K, x, y, A.WALL.planks(col(s.timber_c), 3, x, y, x, y, {})) end end
    P.use(K, "structure")
    A.banner(K, 0, 0.6, 4.6, 0.5, 1.2, s.emblem, s.ec)
    M.flag(K, s, 1.2, 3.5, 11.0)
  end

  SP.fachwerk = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.3, 1.3, 1.2, 2.2, 1.9, { wall = "plaster", wall_c = s.plaster_c, timber = s.timber_c, braces = true,
      upper = { h = 1.7, jetty = 0.25, wall = "plaster", c = s.plaster_c, timber = s.timber_c, braces = true },
      roof = "gable_front", rise = 2.2, gable_mat = "plaster", gable_timber = s.timber_c, gable_c = s.plaster_c })
    M.door(K, s, -0.5, 1.2, 0.7, 1.45, "rect")
    A.window(K, 0.6, 1.2, 0.7, 0.4, 0.55, "rect", { shutters = s.palette.green, frame = s.timber_c })
    M.windows(K, s, -1.1, 1.1, 0.95, 2.3, 2, 0.35, 0.6)
    M.props(K, s, { { "barrel", -1.7, 0.5 }, { "cart", 1.4, 0.4 } })
  end

  -- watch tower: square Brick Gothic tower under a steep tile gable facing the street
  SP.brick_tower = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -0.85, 0.85, 1.3, 1.6, 5.4, { roof = "gable_front", rise = 1.9 })
    M.windows(K, s, -0.45, 0.45, 1.3, 3.6, 2, 0.2, 0.7)
    M.door(K, s, 0, 1.3, 0.55, 1.3, "arch_pointed")
    A.banner(K, 0, 1.3, 2.9, 0.36, 0.9, s.emblem, s.ec)
  end

  -- barracks: long Brick Gothic dormitory hall, red tile roof, a row of small lancets, gate arch with the cross
  SP.brick_dormitory = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.6, 2.1, 2.4, 2.4, { roof = "gable", rise = 1.6 })
    for i = 0, 6 do A.window(K, -2.45 + i * 0.8, 2.1, 1.3, 0.18, 0.55, "arch_pointed", { frame = s.frame_c }) end
    M.block(K, s, -0.7, 0.7, 1.7, 0.6, 3.0, { roof = "stepped", rise = 1.2 })      -- gate house with stepped gable
    M.door(K, s, 0, 1.7, 0.9, 1.9, "arch_pointed")
    M.banners(K, s, { 0 }, 1.7, 2.9, 0.4, 0.8)
    M.props(K, s, { { "rack", 2.0, 1.0 }, { "dummy", -1.9, 0.9 }, { "barrel", -2.5, 1.5 } })
    M.flag(K, s, 2.75, 1.5, 4.6)
  end

  -- archery range: brick-walled yard with a timber shooting shed (tile pent roof) and crossbow targets
  SP.brick_yard = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 5.0, 0.4, 1.6, { flat = true, merlons = "rect" })            -- back wall
    M.open_shed(K, s, -2.6, -0.4, 3.4, 1.4, 1.9, { wall = "planks", wall_c = s.timber_c, roof = "shed", rise = 0.7, base = false,
      timber = false, posts = false, bay = 1.1 })
    for i, x in ipairs({ 0.4, 1.3, 2.2 }) do Pr.target(K, x, 3.6 + (i % 2) * 0.25) end
    M.block(K, s, -2.8, -0.7, 0.25, 0.3, 1.0, { flat = true, merlons = false })
    M.block(K, s, 0.7, 2.8, 0.25, 0.3, 1.0, { flat = true, merlons = false })
    M.props(K, s, { { "rack", 1.5, 1.4 }, { "barrel", -2.1, 1.5 } })
    M.flag(K, s, 2.75, 0.9, 4.4)
  end

  -- stable: brick ground floor with a half-timbered hay loft above, red tile roof
  SP.loft_stable = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 3.0, 2.4, 1.9, { upper = { h = 1.2, wall = "plaster", c = s.plaster_c, timber = s.timber_c },
      roof = "gable", rise = 1.4 })
    for x = -2.3, 2.2, 1.15 do A.door(K, x + 0.45, 3.0, 0.8, 1.6, "arch_pointed", s.door_c, { frame = s.frame_c }) end
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.props(K, s, { { "horse", -1.6, 1.4, "horse_bay" }, { "horse", 1.2, 1.1, "horse_grey" }, { "trough", 0.0, 1.9 }, { "hay", 2.3, 2.2 } })
    M.flag(K, s, 2.75, 2.6, 4.4)
  end
end
