-- Byzantine landmark layouts (docs/art/culture/byzantines.md): cross-in-square church with five domes joined to a
-- polychrome palace block, Theodosian-walls fortress, two-storey house with a timber balcony, beacon tower, and a
-- generic watermill (also used by other civs).
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL
  local DARK = "#2a2234"

  SP.byz_church = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    -- palace wing (Tekfur Saray-type, three storeys of banded brick with arched windows)
    M.block(K, s, 0.9, 2.85, 2.4, 2.2, 5.2, { roof = "hip", rise = 0.8 })
    for i = 0, 2 do M.windows(K, s, 1.0, 2.75, 2.4, 0.9 + i * 1.5, 3, 0.3, 0.7) end
    -- church: cross-in-square body, four corner domes and a central dome on a tall drum
    M.block(K, s, -2.6, 1.0, 2.0, 2.8, 3.6, { flat = true, merlons = false })
    for _, q in ipairs({ { -2.15, 2.5 }, { 0.55, 2.5 }, { -2.15, 4.2 }, { 0.55, 4.2 } }) do
      A.drum(K, q[1], q[2], 0.42, 3.6, 0.45, s.wall, s.wall_c, { band_c = s.band_c })
      A.dome(K, q[1], q[2], 0.45, 0.35, 4.05, s.dome_c, "cross")
    end
    A.drum(K, -0.8, 3.4, 0.85, 3.6, 1.1, s.wall, s.wall_c, { band_c = s.band_c })
    A.dome(K, -0.8, 3.4, 0.9, 0.8, 4.7, s.dome_c, "cross")
    -- narthex front with a triple arched entrance
    for i = -1, 1 do A.door(K, -0.8 + i * 0.85, 2.0, 0.6, 1.6, "arch_round", (i == 0) and s.door_c or DARK, { frame = s.frame_c }) end
    M.windows(K, s, -2.5, -1.6, 2.0, 1.8, 2, 0.22, 0.6)
    M.windows(K, s, -0.05, 0.9, 2.0, 1.8, 2, 0.22, 0.6)
    M.banners(K, s, { 1.4, 2.4 }, 2.4, 2.5, 0.4, 1.0)
    M.props(K, s, { { "well", -2.2, 0.6 }, { "jar", 2.4, 0.5 } })
    M.flag(K, s, 2.7, 0.7, 3.6)
  end

  -- Theodosian walls: tall square towers, banded curtain, an inner keep and a low moat wall in front
  SP.theodosian = function(K, s)
    M.ground(K, s, 4, { paving = s.paving_c })
    M.block(K, s, -1.6, 1.6, 4.0, 2.6, 6.8, { flat = true, merlons = "rect" })
    M.windows(K, s, -1.3, 1.3, 4.0, 4.3, 3, 0.3, 0.7)
    M.block(K, s, -3.5, 3.5, 1.4, 0.8, 3.8, { flat = true, merlons = "rect", base = false })
    for _, x in ipairs({ -3.0, -1.0, 1.0, 3.0 }) do
      M.block(K, s, x - 0.55, x + 0.55, 1.0, 1.1, 5.2, { flat = true, merlons = "rect", base = false })
      A.window(K, x, 1.0, 3.6, 0.22, 0.6, "arch_round")
    end
    M.block(K, s, -3.7, 3.7, 0.2, 0.3, 1.2, { flat = true, merlons = "rect", base = false })          -- moat wall
    M.door(K, s, 0, 1.0, 1.1, 2.1, "arch_round")
    M.banners(K, s, { -2.0, 2.0 }, 1.4, 3.6, 0.5, 1.3)
    M.flag(K, s, 0, 4.0, 8.6)
  end

  SP.byz_house = function(K, s)
    M.ground(K, s, 2)
    local b = M.block(K, s, -1.6, 1.4, 1.3, 2.2, 1.9, { upper = { h = 1.5, jetty = 0.3, wall = "planks", c = s.timber_c }, roof = "gable", rise = 0.6 })
    M.door(K, s, -0.8, 1.3, 0.7, 1.45, "arch_round")
    A.window(K, 0.5, 1.3, 0.8, 0.35, 0.55, "arch_round")
    -- wooden balcony rail across the upper floor
    P.use(K, "props")
    local y = A.vy(1.0, 2.15)
    for x = A.px(-1.5), A.px(1.3) do P.put(K, x, y, tone(col(s.timber_c), 3)) end
    for x = A.px(-1.5), A.px(1.3), 5 do P.vline(K, x, y, y + 7, tone(col(s.timber_c), 4)) end
    P.use(K, "structure")
    M.windows(K, s, -1.3, 1.3, 1.0, 2.35, 3, 0.3, 0.6)
    M.props(K, s, { { "jar", -1.8, 0.5 }, { "barrel", 1.6, 0.5 } })
  end

  -- square banded tower with a crenellated top and a beacon brazier
  SP.beacon_tower = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -0.9, 0.9, 1.2, 1.6, 6.6, { flat = true, merlons = "rect" })
    M.windows(K, s, -0.6, 0.6, 1.2, 4.6, 1, 0.3, 0.8)
    M.door(K, s, 0, 1.2, 0.6, 1.3, "arch_round")
    local bx, by = A.px(0), A.vy(2.0, 6.6) - 6
    P.use(K, "props")
    P.rect(K, bx - 5, by, bx + 5, by + 4, C.iron_dark)
    for i = -4, 4 do P.vline(K, bx + i, by - 3 - math.abs((i * 3) % 5), by - 1, (i % 2 == 0) and C.orange or C.yellow) end
    P.use(K, "structure")
    A.banner(K, 0, 1.2, 4.0, 0.4, 1.0, s.emblem, s.ec)
  end

  -- watermill: mill house beside a stream with a vertical wooden wheel (shared by several civs)
  SP.watermill = function(K, s)
    M.ground(K, s, 2)
    M.stream(K, -1.85, -1.1, 0.4, 3.7)                                                     -- the mill race
    M.block(K, s, -1.0, 1.8, 1.4, 2.2, 2.6, { roof = (s.roof == "flat") and nil or (s.mill_roof or s.roof or "gable"), flat = (s.roof == "flat") })
    M.door(K, s, 0.6, 1.4, 0.7, 1.4)
    A.window(K, -0.2, 1.4, 1.2, 0.35, 0.5, s.window or "rect")
    Pr.waterwheel(K, A.px(-1.45), A.vy(1.6, 1.1), 26)
    M.props(K, s, { { "sacks", 1.2, 0.5 }, { "cart", 0.2, 0.3 } })
    M.flag(K, s, 1.85, 0.4, 3.0)
  end

  -- barracks: long two-storey block banded in brick and stone, an arcade of round arches below, shield rack
  SP.byz_barracks = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.7, 2.6, 2.0, 2.6, 2.3, { upper = { h = 1.7, wall = s.wall, c = s.wall_c }, roof = "hip", rise = 1.0 })
    for i = 0, 4 do A.door(K, -2.15 + i * 1.07, 2.0, 0.72, 1.6, "arch_round", (i == 2) and s.door_c or "#2a2234", { frame = s.frame_c }) end
    M.windows(K, s, -2.4, 2.3, 2.0, 2.8, 5, 0.3, 0.6)
    M.banners(K, s, { -1.6, 1.6 }, 2.0, 3.9, 0.42, 1.0)
    M.props(K, s, { { "rack", 1.9, 1.0 }, { "rack", -1.9, 1.0 }, { "dummy", 0.6, 0.7 } })
    M.flag(K, s, 2.75, 1.3, 4.6)
  end

  -- archery range: walled courtyard, a covered round-arched arcade at the back, straw butts in the yard
  SP.byz_range = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 4.1, 1.5, 2.0, { roof = "gable", rise = 0.7 })
    for i = 0, 4 do A.door(K, -2.2 + i * 1.1, 4.1, 0.75, 1.45, "arch_round", "#2a2234", { frame = s.frame_c }) end
    for i, x in ipairs({ -1.8, -0.6, 0.6, 1.8 }) do Pr.target(K, x, 3.0 + (i % 2) * 0.25) end
    M.block(K, s, -2.8, -0.7, 0.25, 0.3, 0.9, { flat = true, merlons = false })         -- low front wall, gate gap
    M.block(K, s, 0.7, 2.8, 0.25, 0.3, 0.9, { flat = true, merlons = false })
    M.props(K, s, { { "rack", -2.0, 1.4 }, { "jar", 2.3, 1.3 } })
    M.flag(K, s, 2.7, 0.9, 4.4)
  end

  -- stable: long single-storey banded brick building, round-arched doors, tiled gable roof, water trough
  SP.byz_stable = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 3.0, 2.4, 2.1, { roof = "gable", rise = 0.8 })
    for x = -2.3, 2.2, 1.15 do A.door(K, x + 0.45, 3.0, 0.8, 1.6, "arch_round", s.door_c, { frame = s.frame_c }) end
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.props(K, s, { { "horse", -1.6, 1.4, "horse_bay" }, { "horse", 1.2, 1.1, "horse_grey" }, { "trough", 0.0, 1.9 }, { "jar", 2.4, 2.1 } })
    M.flag(K, s, 2.75, 2.6, 4.2)
  end

  -- blacksmith: banded brick workshop open to the street through an arcade, forge chimney, anvil, a rack of spears
  SP.byz_smithy = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.85, 1.0, 2.0, 1.7, 2.3, { roof = "gable", rise = 0.7 })
    for i = 0, 2 do A.door(K, -1.4 + i * 0.95, 2.0, 0.7, 1.4, "arch_round", "#2a2234", { frame = s.frame_c }) end
    Pr.glow(K, -0.25, 0.25, 2.0, 0.1, 0.9)
    Pr.chimney(K, 0.6, 3.0, 2.6, 4.0, "brick")
    M.props(K, s, { { "anvil", -0.3, 0.8 }, { "rack", 1.4, 1.2 }, { "barrel", -1.4, 0.6 } })
    M.flag(K, s, 1.8, 0.6, 3.4)
  end

  -- lumber camp: timber shed on stone footings under a tile roof, log stacks
  SP.byz_lumber = function(K, s)
    M.ground(K, s, 2)
    M.open_shed(K, s, -1.85, 0.8, 2.6, 1.2, 1.9, { roof = "gable", rise = 0.5, base = s.base_c, base_h = 0.35, bay = 0.9 })
    M.props(K, s, { { "logs", -1.7, 1.4, 1.6, 3 }, { "logs", 0.4, 0.8, 1.2, 2 }, { "sawhorse", 1.3, 1.9 }, { "jar", 1.5, 0.5 } })
    M.flag(K, s, 1.8, 0.4, 3.2)
  end

  -- mining camp: timber shaft frame, ore carts, cut marble blocks from the quarry
  SP.byz_quarry = function(K, s)
    M.ground(K, s, 2)
    Pr.quarry(K, -1.85, 0.3, 2.4, "#E2DCCC")
    Pr.headframe(K, 1.0, 2.6)
    M.props(K, s, { { "blocks", -1.0, 1.0 }, { "cart", 0.4, 0.6, "gold" }, { "ore", 1.5, 1.3, "stone_grey", 7 } })
    M.flag(K, s, -1.85, 0.4, 3.2)
  end
end
