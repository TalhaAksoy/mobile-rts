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
end
