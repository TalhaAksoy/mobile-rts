-- Mamluk landmark layouts (docs/art/culture/saracens.md): madrasa-mausoleum with an ablaq facade, muqarnas portal,
-- carved dome and a three-tier minaret; Cairo-citadel fortress with a glacis; mud-brick house with a wind-catcher
-- and a mashrabiya bay; Hama noria; maydan archery ground with the qabaq target pole.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL
  local DARK = "#2a2234"

  -- three-tier Mamluk minaret: square shaft, octagonal middle, round top with a pavilion and bulb
  local function mamluk_minaret(K, s, cx, d, h)
    local c = col(s.wall_c)
    M.block(K, s, cx - 0.42, cx + 0.42, d, 0.84, h * 0.45, { flat = true, merlons = false, wall = "ablaq" })
    local x0, x1 = A.px(cx - 0.32), A.px(cx + 0.32) - 1
    local y0, y1 = A.vy(d + 0.1, h * 0.78), A.vy(d + 0.1, h * 0.45)
    for y = y0, y1 do for x = x0, x1 do P.put(K, x, y, tone(c, (x <= x0 + 1) and 2 or ((x >= x1 - 1) and 4 or 3))) end end
    for x = x0 - 3, x1 + 3 do P.put(K, x, y1, tone(c, 2)); P.put(K, x, y0, tone(c, 2)) end
    local x2, x3 = A.px(cx - 0.2), A.px(cx + 0.2) - 1
    local y2 = A.vy(d + 0.15, h)
    for y = y2, y0 do for x = x2, x3 do P.put(K, x, y, ((x - x2) % 3 == 1) and P.hex(DARK) or tone(c, 3)) end end
    return A.dome(K, cx, d + 0.35, 0.28, 0.4, h, s.dome_c, "crescent")
  end

  SP.madrasa = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    M.block(K, s, -2.8, 0.9, 2.0, 3.0, 4.6, { flat = true, wall = "ablaq" })
    -- recessed portal with a muqarnas hood
    M.block(K, s, -1.6, -0.2, 1.7, 0.3, 4.2, { flat = true, merlons = false, wall = "ablaq" })
    A.door(K, -0.9, 1.7, 1.0, 2.4, "arch_pointed", s.door_c, { muqarnas = s.muqarnas_c, frame = s.frame_c })
    M.windows(K, s, -2.7, -1.7, 2.0, 2.4, 1, 0.35, 0.9)
    M.windows(K, s, -0.1, 0.8, 2.0, 2.4, 1, 0.35, 0.9)
    -- mausoleum: square base, tall drum, carved stone dome
    M.block(K, s, 0.9, 2.8, 2.2, 2.0, 4.0, { flat = true })
    A.drum(K, 1.85, 3.3, 0.8, 4.0, 0.7, "ashlar", s.wall_c, {})
    A.dome(K, 1.85, 3.3, 0.85, 1.1, 4.7, s.dome_c, "crescent")
    mamluk_minaret(K, s, -2.3, 2.6, 9.0)
    M.props(K, s, { { "palm", 2.5, 0.8 }, { "jar", -2.6, 0.5 } })
    M.flag(K, s, 2.75, 0.5, 3.6)
  end

  SP.citadel = function(K, s)
    M.ground(K, s, 4, { paving = s.paving_c })
    M.block(K, s, -1.7, 1.7, 3.9, 2.6, 6.6, { flat = true })
    M.windows(K, s, -1.4, 1.4, 3.9, 4.4, 3, 0.25, 0.6)
    M.block(K, s, -3.6, 3.6, 0.9, 0.8, 3.6, { flat = true, base = false })
    -- glacis: sloping base in front of the curtain
    P.use(K, "structure")
    local c = col(s.wall_c)
    for y = A.vy(0.9, 1.0), A.vy(0.3, 0) do for x = A.px(-3.6), A.px(3.6) do P.put(K, x, y, tone(c, 4)) end end
    for _, x in ipairs({ -3.3, 3.3 }) do A.round_tower(K, x, 0.5, 0.95, 5.0, "ashlar", s.wall_c, "crenel", { merlon = "stepped" }) end
    for _, x in ipairs({ -1.0, 1.0 }) do M.block(K, s, x - 0.5, x + 0.5, 0.6, 0.8, 4.6, { flat = true, base = false }) end
    M.door(K, s, 0, 0.9, 1.1, 2.2, "arch_pointed")
    M.banners(K, s, { -2.2, 2.2 }, 0.9, 3.4, 0.5, 1.3)
    M.flag(K, s, 0, 3.9, 8.4)
  end

  SP.malqaf_house = function(K, s)
    M.ground(K, s, 2)
    local b = M.block(K, s, -1.6, 1.4, 1.3, 2.2, 3.4, { wall = "adobe", wall_c = col(s.palette.mud) and s.palette.mud or s.wall_c, flat = true, merlons = false })
    -- wind-catcher (malqaf): a mud-brick shaft on the roof with a slanted hood and a dark mouth facing the breeze
    P.use(K, "structure")
    local mud = col(s.palette.mud)
    local mx, my = A.px(-1.15), A.vy(2.6, 3.4)
    local W, H = 13, 20
    for x = mx, mx + W - 1 do
      local top = my - H + math.floor((x - mx) * 0.45)                        -- hood slopes down to the right
      for y = top, my do
        local sh = (x >= mx + W - 3) and 4 or ((x < mx + 2) and 2 or 3)       -- right side in shade
        P.put(K, x, y, A.WALL.adobe(mud, sh, x, y, x, y, {}))
      end
      P.put(K, x, top, tone(mud, 1)); P.put(K, x, top + 1, tone(mud, 2))       -- lit hood lip
    end
    P.rect(K, mx + 2, my - H + 6, mx + W - 5, my - 9, P.hex(DARK))           -- mouth
    for x = mx, mx + W + 2 do P.put(K, x, my + 1, tone(mud, 5)) end          -- contact shadow on the terrace
    -- mashrabiya bay: projecting lattice box on the upper floor
    local x0, x1 = A.px(0.1), A.px(1.2)
    local y0, y1 = A.vy(1.1, 3.0), A.vy(1.1, 1.9)
    for y = y0, y1 do for x = x0, x1 do P.put(K, x, y, ((x + y) % 2 == 0) and tone(col(s.timber_c), 3) or tone(col(s.timber_c), 5)) end end
    for x = x0 - 1, x1 + 1 do P.put(K, x, y0 - 1, tone(col(s.timber_c), 2)); P.put(K, x, y1 + 1, tone(col(s.timber_c), 4)) end
    M.door(K, s, -0.8, 1.3, 0.7, 1.5, "rect")
    M.props(K, s, { { "jar", -1.8, 0.5 }, { "jar", -1.4, 0.3 }, { "palm", 1.6, 0.6 } })
  end

  -- Hama-style noria: giant wooden wheel on a stone aqueduct arch, with a small ox-turned mill house
  SP.noria = function(K, s)
    M.ground(K, s, 2)
    P.use(K, "ground")
    M.stream(K, -1.85, -0.65, 0.4, 3.7)
    P.use(K, "structure")
    M.block(K, s, 0.2, 1.9, 1.6, 1.6, 2.2, { flat = true })
    M.door(K, s, 1.0, 1.6, 0.6, 1.3, "arch_pointed")
    M.block(K, s, -1.6, 0.2, 2.6, 0.4, 2.8, { flat = true, merlons = false })            -- aqueduct
    for x = -1.4, 0.0, 0.6 do A.door(K, x, 2.6, 0.4, 1.6, "arch_pointed", DARK) end
    Pr.waterwheel(K, A.px(-1.3), A.vy(1.4, 1.7), 40)
    M.props(K, s, { { "sacks", 1.4, 0.5 }, { "jar", 0.4, 0.4 } })
    M.flag(K, s, 1.85, 0.4, 3.0)
  end

  -- maydan: open ground with the qabaq target (gourd on a tall pole) and a shaded stone bench
  SP.maydan = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, -0.8, 4.2, 1.2, 2.0, { flat = true, merlons = "stepped" })
    A.door(K, -1.8, 4.2, 1.2, 1.6, "arch_pointed", DARK)
    local px, yb = A.px(1.2), A.vy(3.2, 0)
    P.use(K, "props")
    P.vline(K, px, yb - 110, yb, C.wood_dark); P.vline(K, px + 1, yb - 110, yb, C.wood)
    Pr.blob(K, px, yb - 114, 5, 5, C.gold, 3); P.put(K, px, yb - 120, C.green)
    P.use(K, "structure")
    for i, x in ipairs({ -2.2, -0.8, 0.4, 2.2 }) do Pr.target(K, x, 2.4 + (i % 2) * 0.3) end
    Pr.fence(K, -2.8, 2.8, 0.35)
    Pr.palm(K, 2.6, 1.8)
    M.flag(K, s, -2.6, 0.7, 3.8)
  end

  -- watch tower: square ashlar tower with stepped crenellations and a flag on top
  SP.stepped_tower = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -0.85, 0.85, 1.3, 1.6, 6.0, { flat = true, merlons = "stepped" })
    M.windows(K, s, -0.4, 0.4, 1.3, 3.8, 1, 0.24, 0.6)
    M.door(K, s, 0, 1.3, 0.55, 1.3, "arch_pointed")
    A.banner(K, 0, 1.3, 3.0, 0.36, 0.9, s.emblem, s.ec)
    M.flag(K, s, 0.45, 2.3, 8.0)
  end

  -- barracks: tibaq of the Cairo citadel, a tall plain stone block of three storeys with small windows, an arcade
  -- at the base and the yellow sultanic banner
  SP.tibaq = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.4, 2.4, 2.1, 2.6, 4.6, { flat = true, merlons = false })
    for i = 0, 3 do A.door(K, -1.8 + i * 1.2, 2.1, 0.8, 1.5, "arch_pointed", "#2a2234", { frame = s.frame_c }) end
    for row = 0, 1 do M.windows(K, s, -2.2, 2.2, 2.1, 2.3 + row * 1.15, 6, 0.2, 0.42) end
    A.standard(K, -2.7, 1.5, 4.4, { form = "alam", field = "#D6A62B", field2 = "#F3EFE6", ec = "#2a2234" })
    M.props(K, s, { { "rack", 2.4, 1.1 }, { "jar", -1.8, 0.8 }, { "palm", 2.6, 0.4 } })
  end
end
