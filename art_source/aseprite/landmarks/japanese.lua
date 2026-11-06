-- Japanese layouts (docs/art/culture/japanese.md): buke yakata (moated lord's compound with a gate tower and a
-- main hall), yamajiro hill fort with stone-faced terraces and yagura, minka farmhouse, open timber yagura.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL

  -- battered stone-faced terrace (ishigaki)
  local function ishigaki(K, x0, x1, d, h)
    local c = col("#8A8780")
    P.use(K, "structure")
    local yb, yt = A.vy(d, 0), A.vy(d, h)
    for y = yt, yb do
      local inset = math.floor((y - yt) * -0.25)
      for x = A.px(x0) - inset, A.px(x1) + inset do P.put(K, x, y, A.WALL.ashlar(c, (x < A.px(x0) - inset + 3) and 2 or 3, x, y, x, y, {})) end
    end
  end

  SP.buke_yakata = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    M.block(K, s, -2.6, 2.6, 2.4, 2.6, 3.0, { h0 = 0.4, roof = "curved", rise = 1.6 })      -- main hall on a raised floor
    M.windows(K, s, -2.4, 2.4, 2.4, 1.0, 5, 0.6, 1.2)
    -- earth wall with a white plaster top and the yagura-mon gate
    M.block(K, s, -2.9, 2.9, 0.7, 0.4, 1.6, { roof = "gable", rise = 0.25, base = false, timber = false })
    M.block(K, s, -0.8, 0.8, 0.5, 0.9, 3.6, { roof = "curved", rise = 0.7, base = false })
    A.door(K, 0, 0.5, 1.0, 1.8, "rect", s.door_c, { frame = s.frame_c })
    for _, x in ipairs({ -2.2, 2.2 }) do                                                      -- nobori banners
      A.flag(K, x, 0.5, 3.2, 6, s.emblem, s.ec)
    end
    Pr.stone_lantern(K, -1.3, 0.2); Pr.stone_lantern(K, 1.3, 0.2)
  end

  SP.yamajiro = function(K, s)
    M.ground(K, s, 4)
    ishigaki(K, -3.4, 3.4, 2.4, 2.4)
    M.block(K, s, -1.6, 1.6, 3.2, 2.0, 5.4, { h0 = 2.4, roof = "curved", rise = 0.9, base = false })   -- small keep
    M.block(K, s, -1.1, 1.1, 3.6, 1.2, 7.2, { h0 = 5.4, roof = "curved", rise = 0.8, base = false })
    for _, x in ipairs({ -2.8, 2.8 }) do M.block(K, s, x - 0.6, x + 0.6, 2.4, 1.0, 4.6, { h0 = 2.4, roof = "curved", rise = 0.6, base = false }) end
    -- palisade and gate tower in front
    P.use(K, "props")
    for x = A.px(-3.6), A.px(3.6), 3 do if math.abs(x) > A.px(0.7) then P.rect(K, x, A.vy(0.6, 1.8), x + 1, A.vy(0.6, 0), A.tone(col(s.timber_c), 3)) end end
    P.use(K, "structure")
    M.block(K, s, -0.7, 0.7, 0.5, 0.8, 3.4, { roof = "curved", rise = 0.6, base = false })
    A.door(K, 0, 0.5, 0.9, 1.7, "rect", s.door_c)
    for _, x in ipairs({ -2.0, 2.0 }) do A.flag(K, x, 0.3, 3.6, 6, s.emblem, s.ec) end
    M.flag(K, s, 0, 3.6, 10.0)
  end

  SP.minka = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.6, 1.4, 1.3, 2.3, 1.8, { roof = "hip", roof_mat = "thatch", roof_c = s.palette.thatch, rise = 1.9, over = 0.45,
      ridge = s.palette.cedar, base = false })
    M.door(K, s, -0.6, 1.3, 0.8, 1.5, "rect")
    A.window(K, 0.7, 1.3, 0.7, 0.5, 0.55, "shoji")
    M.props(K, s, { { "bamboo", -1.8, 0.8 }, { "sacks", 1.6, 0.5 } })
  end

  SP.yagura = function(K, s)
    M.ground(K, s, 2)
    M.stilts(K, s, -0.9, 0.9, 1.0, 1.4, 5.0)
    M.block(K, s, -1.0, 1.0, 1.0, 1.4, 6.4, { h0 = 5.0, wall = "planks", wall_c = s.palette.cedar, roof = "curved", rise = 0.7, base = false, timber = false })
    P.use(K, "props")
    P.ellipse(K, A.px(0.4), A.vy(1.2, 5.6), 4, 4, col(s.palette.vermilion))                            -- war drum
    P.use(K, "structure")
    A.flag(K, 0.9, 1.4, 7.4, 6, s.emblem, s.ec)
  end

  -- barracks: nagaya, a long low timber row house under a tile roof, yari racks and nobori banners in the yard
  SP.nagaya = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 2.6, 2.4, 1.9, { roof = "curved", rise = 0.9 })
    for i = 0, 5 do
      local x = -2.35 + i * 0.94
      if i % 2 == 0 then A.door(K, x, 2.6, 0.7, 1.4, "rect", s.door_c, { frame = s.frame_c })
      else A.window(K, x, 2.6, 0.9, 0.6, 0.5, "shoji", { frame = s.frame_c }) end
    end
    for _, x in ipairs({ -2.4, -1.5, 1.5, 2.4 }) do A.standard(K, x, 1.2, 3.6, { form = "nobori", field = "#F0EEE8", ec = "#1D1A19", emblem = s.emblem }) end
    M.props(K, s, { { "rack", -0.6, 1.0 }, { "rack", 0.6, 1.0 }, { "stone_lantern", 2.1, 0.6 } })
  end

  -- archery range: the covered shooting shed (iba) in front, round paper targets (mato) on an earth bank behind
  SP.iba = function(K, s)
    M.ground(K, s, 3)
    local P2 = P
    local by = A.vy(4.6, 0)
    P.use(K, "props")
    for x = A.px(-2.7), A.px(2.7) do for y = by - 14, by do                                   -- earth bank (azuchi)
      P.put(K, x, y, tone(P.hex("#8A6A48"), (y < by - 11) and 2 or ((P.noise(x, y, 5) < 0.2) and 4 or 3)))
    end end
    for i, x in ipairs({ -1.6, -0.5, 0.6, 1.7 }) do                                         -- mato: white with black rings
      local px, py = A.px(x), by - 8
      P.ellipse(K, px, py, 5, 5, P.hex("#1D1A19")); P.ellipse(K, px, py, 4, 4, P.hex("#F0EEE8"))
      P.ellipse(K, px, py, 3, 3, P.hex("#1D1A19")); P.ellipse(K, px, py, 2, 2, P.hex("#F0EEE8")); P.put(K, px, py, P.hex("#1D1A19"))
    end
    P.use(K, "structure")
    M.open_shed(K, s, -2.6, 2.6, 1.0, 1.3, 1.8, { roof = "curved", rise = 0.6, bay = 1.3 })
    A.standard(K, 2.75, 0.6, 3.4, { form = "nobori", field = "#F0EEE8", ec = "#1D1A19", emblem = s.emblem })
  end

  -- stable: umaya, an open-fronted timber stable under a thatched roof, horses tethered in the stalls
  SP.umaya = function(K, s)
    M.ground(K, s, 3)
    M.open_shed(K, s, -2.8, 2.8, 2.6, 2.2, 2.0, { roof = "hip", roof_mat = "thatch", roof_c = "#A88A50", rise = 1.0, bay = 1.4,
      post_c = "wood_dark" })
    for i, x in ipairs({ -2.0, -0.6, 0.8 }) do Pr.horse(K, x, 2.7, (i == 2) and "horse_grey" or "horse_bay") end
    M.props(K, s, { { "trough", 1.9, 1.6 }, { "hay", -2.3, 1.2 }, { "stone_lantern", 2.5, 0.6 } })
    A.standard(K, -2.75, 0.6, 3.4, { form = "nobori", field = "#F0EEE8", ec = "#1D1A19", emblem = s.emblem })
  end
end
