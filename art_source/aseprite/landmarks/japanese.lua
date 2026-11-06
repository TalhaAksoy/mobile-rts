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
end
