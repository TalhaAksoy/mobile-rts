-- Ottoman landmark layouts (docs/art/culture/ottomans.md): külliye, konak, Rumelihisarı-type fortress, Aegean
-- windmill, square watch tower with a timber gallery, janissary oda, nişan taşı archery yard, bedesten.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL
  local DARK = "#2a2234"

  -- külliye: single-dome mosque with a domed portico, pencil minaret, low madrasa wing, şadırvan, cypresses
  SP.kulliye = function(K, s)
    M.ground(K, s, 3, { paving = "#D8CCB4" })
    Pr.cypress(K, -2.6, 3.6); Pr.cypress(K, 2.7, 4.6)
    M.block(K, s, -2.85, -1.75, 2.0, 2.6, 2.3, { flat = true, merlons = false })            -- madrasa wing
    for _, x in ipairs({ -2.55, -2.05 }) do A.dome(K, x, 3.1, 0.32, 0.25, 2.3, s.dome_c, "ball") end
    M.windows(K, s, -2.75, -1.85, 2.0, 0.9, 2, 0.25, 0.55)
    M.block(K, s, -1.55, 1.55, 2.3, 2.9, 3.5, { flat = true, merlons = false })              -- prayer hall
    M.windows(K, s, -1.4, 1.4, 2.3, 1.3, 3, 0.3, 0.9)
    A.drum(K, 0, 3.75, 1.25, 3.5, 0.55, s.wall, s.wall_c, { band_c = s.band_c })
    A.dome(K, 0, 3.75, 1.3, 1.25, 4.05, s.dome_c, "crescent")
    M.block(K, s, -1.55, 1.55, 1.15, 1.1, 2.4, { flat = true, merlons = false, base = false })  -- portico
    for i = 0, 2 do
      local cx = -1.03 + i * 1.03
      A.door(K, cx, 1.15, 0.78, 1.8, "arch_pointed", DARK, { frame = s.frame_c })
      A.dome(K, cx, 1.7, 0.45, 0.34, 2.4, s.dome_c, "ball")
    end
    A.minaret(K, 2.25, 2.4, 9.5, s.wall_c, s.dome_c)
    Pr.fountain(K, -0.9, 0.35)
    A.tug(K, 2.6, 0.5, 3.4)
    M.flag(K, s, -2.7, 0.6, 3.6)
  end

  -- konak: stone ground floor, whitewashed timber upper floor jutting out on brackets, lattice windows, low tile hip
  SP.konak = function(K, s)
    M.ground(K, s, 2)
    Pr.cypress(K, -1.7, 3.0)
    local b = M.block(K, s, -1.6, 1.4, 1.3, 2.2, 1.9, { wall = "ashlar", upper = { h = 1.6, jetty = 0.35, wall = "plaster", c = s.plaster_c, timber = s.timber_c }, roof = "hip", rise = 0.7 })
    M.door(K, s, -0.8, 1.3, 0.7, 1.45, "arch_pointed")
    A.window(K, 0.5, 1.3, 0.8, 0.4, 0.5, "lattice", { frame = s.timber_c })
    M.windows(K, s, -1.4, 1.4, 0.95, 2.35, 3, 0.35, 0.65)
    P.use(K, "props")
    local cx, cy = A.px(0.9), A.vy(2.3, 3.9)
    P.rect(K, cx, cy - 12, cx + 4, cy, col(s.plaster_c)); P.rect(K, cx - 1, cy - 14, cx + 5, cy - 12, col(s.roof_c))
    P.use(K, "structure")
    M.props(K, s, { { "jar", -1.8, 0.5 }, { "copper_pot", 1.6, 0.5 } })
  end

  -- Rumelihisarı-type fortress: massive round towers with conical lead roofs, banded curtain walls
  SP.rumelihisari = function(K, s)
    M.ground(K, s, 4, { paving = "#CFC4AE" })
    M.block(K, s, -2.6, 2.6, 4.6, 1.2, 4.6, { flat = true, merlons = "rect" })
    for _, x in ipairs({ -2.6, 2.6 }) do A.round_tower(K, x, 4.0, 1.15, 7.2, s.wall, s.wall_c, "cone_lead", { top_c = s.dome_c, finial = "crescent", band_c = s.band_c, cone_h = 2.2 }) end
    M.block(K, s, -3.5, 3.5, 0.8, 0.8, 3.4, { flat = true, merlons = "rect", base = false })
    for _, x in ipairs({ -3.3, 3.3 }) do A.round_tower(K, x, 0.3, 0.95, 5.2, s.wall, s.wall_c, "cone_lead", { top_c = s.dome_c, finial = "crescent", band_c = s.band_c, cone_h = 1.8 }) end
    M.door(K, s, 0, 0.8, 1.4, 2.3, "arch_pointed")
    M.banners(K, s, { -1.9, 1.9 }, 0.8, 3.2, 0.5, 1.3)
    A.tug(K, 0.9, 0.3, 3.6)
    M.flag(K, s, 0, 4.6, 7.6)
  end

  -- Aegean round stone windmill, conical cap, 8 triangular cloth sails
  SP.aegean_windmill = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, 0.2, 1.9, 1.6, 1.4, 1.9, { roof = "hip", rise = 0.6 })
    A.round_tower(K, -0.75, 1.7, 0.95, 3.4, "plaster", s.plaster_c, "cone", { top_c = "#8a6a44", top_mat = "shingle", cone_h = 1.1 })
    A.door(K, -0.75, 1.7, 0.5, 1.2, "arch_round", s.door_c)
    A.window(K, -0.75, 1.7, 2.2, 0.25, 0.35, "rect")
    Pr.sails(K, A.px(-0.75), A.vy(1.7, 3.3), 44, 8, s.sail_c or "cream")
    M.props(K, s, { { "sacks", 1.3, 0.6 }, { "jar", 1.9, 0.4 } })
    M.flag(K, s, 1.85, 0.4, 3.0)
  end

  -- square stone watch tower with a timber gallery and a pyramidal lead cap
  SP.square_gallery = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -0.85, 0.85, 1.3, 1.6, 6.0, { flat = true, merlons = false })
    local gx0, gx1 = A.px(-1.15), A.px(1.15)
    local gy = A.vy(1.0, 6.0)
    P.use(K, "structure")
    for y = gy - 14, gy do for x = gx0, gx1 do P.put(K, x, y, A.WALL.planks(col(s.timber_c), (x < gx0 + 3) and 2 or 3, x, y, x - gx0, y - gy, {})) end end
    for x = gx0 + 4, gx1 - 4, 7 do P.rect(K, x, gy - 11, x + 3, gy - 5, P.hex(DARK)) end
    A.roof(K, "hip", -1.25, 1.25, 1.0, 1.9, 6.6, 1.4, "lead", s.dome_c, { ridge = s.dome_c })
    M.door(K, s, 0, 1.3, 0.6, 1.3, "arch_pointed")
    M.windows(K, s, -0.5, 0.5, 1.3, 3.2, 1, 0.25, 0.7)
    A.banner(K, 0, 1.3, 5.6, 0.4, 1.0, s.emblem, s.ec)
  end

  -- janissary oda: long stone block with a row of small domes, an arcade, the copper kazan by the door
  SP.oda = function(K, s)
    M.ground(K, s, 3, { paving = "#D8CCB4" })
    -- janissary oda: a long two-storey barrack hall under a low red-tile hip roof (no domes: those are for
    -- mosques and madrasas), arcaded ground floor, lattice windows above
    M.block(K, s, -2.7, 2.5, 2.2, 2.4, 3.0, { roof = "hip", rise = 1.0 })
    M.windows(K, s, -2.5, 2.3, 2.2, 2.25, 5, 0.32, 0.5)
    for i = 0, 4 do A.door(K, -2.3 + i * 1.1, 2.2, 0.75, 1.9, "arch_pointed", (i == 2) and s.door_c or DARK, { frame = s.frame_c }) end
    Pr.copper_pot(K, 1.2, 1.1)
    M.props(K, s, { { "rack", -1.7, 1.2 }, { "dummy", -0.6, 0.6 } })
    A.tug(K, 2.5, 0.6, 3.6)
    M.flag(K, s, -2.6, 0.6, 3.8)
  end

  -- walled archery yard with nişan taşı record stones and straw targets, small tiled shelter
  SP.nisan_tasi = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, -0.9, 4.2, 1.4, 2.1, { roof = "hip", rise = 0.6 })
    A.door(K, -1.85, 4.2, 1.1, 1.7, "arch_pointed", DARK)
    for i, x in ipairs({ -0.2, 0.8, 1.8, 2.6 }) do Pr.nisan_tasi(K, x, 3.6 + (i % 2) * 0.4) end
    for i, x in ipairs({ -2.2, -1.0, 0.2, 1.4 }) do Pr.target(K, x, 2.6 + (i % 2) * 0.25) end
    Pr.fence(K, -2.8, 2.8, 0.35)
    Pr.cypress(K, 2.7, 1.5)
    M.flag(K, s, -2.6, 0.7, 3.8)
  end

  -- bedesten: hall under a row of small lead domes, stalls with awnings in front
  SP.bedesten = function(K, s)
    M.T.market(K, s)
    for i = 0, 2 do A.dome(K, -1.45 + i * 1.45, 4.4, 0.55, 0.4, 2.8, s.dome_c, "ball") end
  end

  -- stable: long stone and brick building under a red tile roof, round-arched doorways, hay and a trough
  SP.ottoman_stable = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 3.0, 2.6, 2.3, { roof = "hip", rise = 1.0 })
    for x = -2.3, 2.2, 1.15 do A.door(K, x + 0.45, 3.0, 0.8, 1.6, "arch_round", s.door_c, { frame = s.frame_c }) end
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.props(K, s, { { "horse", -1.6, 1.4, "horse_grey" }, { "horse", 1.2, 1.1, "horse_bay" }, { "trough", 0.0, 1.9 }, { "hay", 2.3, 2.2 }, { "cypress", -2.6, 2.6 } })
    M.flag(K, s, 2.75, 2.6, 4.2)
  end
end
