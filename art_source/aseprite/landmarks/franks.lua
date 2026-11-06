-- Frankish layouts (docs/art/culture/franks.md): Palais de la Cité hall with a Sainte-Chapelle-style chapel (spire,
-- rose window, buttresses), Philip Augustus castle with a cylindrical donjon, timber town house, post windmill.
-- Also defines rose_window / post_mill / timber_townhouse used by other western civs.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL

  local function rose_window(K, cx, d, h, r)
    local mx, my = A.px(cx), A.vy(d, h)
    local rr = math.floor(r * A.X)
    P.use(K, "structure")
    for y = -rr, rr do for x = -rr, rr do
      local dd = math.sqrt(x * x + y * y)
      if dd <= rr then
        local a = math.atan(y, x)
        local v = (math.floor((a + math.pi) / (math.pi / 6)) % 2 == 0) and P.hex("#3A5FA8") or P.hex("#B0302A")
        if dd > rr - 1.5 or math.abs(dd - rr * 0.45) < 0.8 or (dd > 2 and math.floor((a + math.pi) / (math.pi / 6) * 2) % 2 == 0 and (x + y) % 2 == 0) then v = P.hex("#A8977A") end
        P.put(K, mx + x, my + y, v)
      end
    end end
  end
  M.rose_window = rose_window

  local function buttresses(K, s, x0, x1, d, h, n)
    local c = col(s.wall_c)
    P.use(K, "structure")
    for i = 0, n do
      local x = A.px(x0 + (x1 - x0) * i / n)
      for y = A.vy(d - 0.25, h * 0.9), A.vy(d - 0.25, 0) do P.put(K, x - 1, y, tone(c, 2)); P.put(K, x, y, tone(c, 3)); P.put(K, x + 1, y, tone(c, 4)) end
      P.put(K, x, A.vy(d - 0.25, h * 0.9) - 3, tone(c, 2)); P.put(K, x, A.vy(d - 0.25, h * 0.9) - 2, tone(c, 2))   -- pinnacle
    end
  end
  M.buttresses = buttresses

  SP.cite_palace = function(K, s)
    M.ground(K, s, 3, { paving = s.paving_c })
    -- great hall
    M.block(K, s, -2.8, 0.6, 2.0, 2.8, 3.6, { roof = "gable", rise = 1.9 })
    M.windows(K, s, -2.6, 0.4, 2.0, 1.5, 4, 0.3, 1.3)
    M.door(K, s, -1.1, 2.0, 0.9, 1.8)
    buttresses(K, s, -2.8, 0.6, 2.0, 3.6, 4)
    -- chapel: tall, steep, a lead spire and a rose window
    local r = M.block(K, s, 0.7, 2.7, 1.6, 2.6, 5.4, { roof = "gable_front", rise = 2.6, gable_mat = "ashlar" })
    rose_window(K, 1.7, 1.6, 4.2, 0.55)
    A.door(K, 1.7, 1.6, 0.9, 2.0, "arch_pointed", s.door_c, { frame = s.frame_c })
    M.windows(K, s, 0.8, 2.6, 1.6, 0.6, 2, 0.2, 1.1)
    buttresses(K, s, 0.7, 2.7, 1.6, 5.4, 2)
    local sx, sy = A.px(1.7), A.vy(2.9, 8.3)
    P.use(K, "roof")
    for i = 0, 26 do local hw = math.floor(i / 6) for x = sx - hw, sx + hw do P.put(K, x, sy - 26 + i, tone(col(s.palette.lead), (x < sx) and 2 or 4)) end end
    P.use(K, "props"); P.vline(K, sx, sy - 33, sy - 26, C.gold); P.hline(K, sx - 2, sx + 2, sy - 30, C.gold); P.use(K, "structure")
    M.banners(K, s, { -2.2, -0.2 }, 2.0, 3.4, 0.4, 1.1)
    M.props(K, s, { { "well", -2.3, 0.6 }, { "cart", 1.9, 0.4 } })
    M.flag(K, s, 2.8, 0.5, 3.8)
  end

  SP.philippe_castle = function(K, s)
    M.ground(K, s, 4, { paving = s.paving_c })
    -- cylindrical donjon at the back with a slate cone
    A.round_tower(K, 0, 3.6, 1.35, 7.4, "ashlar", s.wall_c, "cone", { top_c = s.tower_c, top_mat = "slate", finial = "cross", cone_h = 2.6, windows = 3 })
    M.block(K, s, -3.6, 3.6, 0.8, 0.8, 3.4, { flat = true, merlons = "rect", base = false })
    for _, x in ipairs({ -3.3, 3.3 }) do A.round_tower(K, x, 0.4, 0.85, 5.0, "ashlar", s.wall_c, "cone", { top_c = s.tower_c, top_mat = "slate", finial = "ball", cone_h = 1.8 }) end
    for _, x in ipairs({ -0.85, 0.85 }) do A.round_tower(K, x, 0.3, 0.55, 4.6, "ashlar", s.wall_c, "cone", { top_c = s.tower_c, top_mat = "slate", cone_h = 1.3 }) end
    M.door(K, s, 0, 0.8, 1.0, 2.1, "arch_pointed")
    M.banners(K, s, { -2.2, 2.2 }, 0.8, 3.2, 0.5, 1.3)
    M.flag(K, s, 1.6, 3.4, 7.0)
  end

  SP.timber_townhouse = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.3, 1.3, 1.2, 2.2, 2.0, { wall = "ashlar", upper = { h = 1.8, jetty = 0.3, wall = "plaster", c = s.plaster_c, timber = s.timber_c, braces = true },
      roof = "gable_front", rise = 2.0, gable_mat = "plaster", gable_timber = s.timber_c })
    M.door(K, s, -0.5, 1.2, 0.7, 1.5, "arch_pointed")
    A.window(K, 0.6, 1.2, 0.8, 0.4, 0.6, "rect", { shutters = s.shutters, frame = s.timber_c })
    M.windows(K, s, -1.1, 1.1, 0.9, 2.4, 2, 0.4, 0.7)
    M.props(K, s, { { "barrel", -1.7, 0.5 }, { "barrel", -1.4, 0.3 }, { "crate", 1.6, 0.5 } })
  end

  -- post windmill: timber body on a trestle, four lattice sails
  SP.post_mill = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, 0.4, 1.9, 1.6, 1.4, 1.8, { roof = s.house_roof == "gable_front" and "gable" or (s.roof == "flat" and nil or s.roof), flat = s.roof == "flat" })
    local px, yb = A.px(-0.7), A.vy(1.5, 0)
    P.use(K, "structure")
    P.line(K, px - 18, yb, px, yb - 40, C.wood_dark, 2); P.line(K, px + 18, yb, px, yb - 40, C.wood_dark, 2); P.vline(K, px, yb - 44, yb, C.wood)
    M.block(K, s, -1.45, 0.05, 1.4, 1.2, 4.2, { wall = "planks", wall_c = "#8A6A44", roof = "gable_front", rise = 1.0, roof_mat = "shingle",
      roof_c = "#6A4A2E", base = false, h0 = 1.6, posts = false, timber = false })
    Pr.sails(K, A.px(-0.7), A.vy(1.3, 3.3), 46, 4, s.sail_c)
    M.props(K, s, { { "sacks", 1.3, 0.5 }, { "cart", -0.4, 0.2 } })
    M.flag(K, s, 1.9, 0.4, 3.0)
  end

  -- watch tower: slim round limestone tower under a steep slate pepper-pot cone, with a pennon
  SP.pepperpot_tower = function(K, s)
    M.ground(K, s, 2)
    local village = s.age == 1
    A.round_tower(K, 0, 1.2, 0.72, 6.0, s.wall, s.wall_c, "cone", { top_c = village and s.roof_c or s.tower_c,
      top_mat = village and s.roof_mat or s.tower_mat, finial = (not village) and s.finial or nil, cone_h = 2.6, windows = 2 })
    M.door(K, s, 0, 1.2, 0.5, 1.2, "arch_pointed")
    M.flag(K, s, 0.95, 1.4, 4.8)
  end

  -- barracks: tall limestone hall with stepped buttresses and pointed lancets under a steep slate roof
  SP.buttress_hall = function(K, s)
    M.ground(K, s, 3)
    local b = M.block(K, s, -2.5, 2.3, 2.1, 2.6, 3.0, { roof = "gable", rise = 2.0 })
    local f = b.facade
    P.use(K, "structure")
    for _, x in ipairs({ -2.5, -1.3, 1.1, 2.3 }) do                  -- buttresses: lit face + shadow side
      local bx = A.px(x)
      for y = f.yt + 6, f.yb do
        local w = (y < f.yt + 20) and 2 or 3
        for xx = bx - w, bx + w do P.put(K, xx, y, tone(col(s.wall_c), (xx < bx) and 2 or 4)) end
      end
    end
    M.door(K, s, -0.1, 2.1, 1.0, 1.9, "arch_pointed")
    M.windows(K, s, -2.3, 2.1, 2.1, 1.6, 4, 0.22, 0.9)
    M.banners(K, s, { -0.1 }, 2.1, 3.2, 0.45, 1.0)
    M.props(K, s, { { "rack", 1.9, 1.0 }, { "rack", -1.9, 1.0 }, { "dummy", 0.8, 0.6 } })
    M.flag(K, s, 2.7, 1.4, 4.8)
  end

  -- archery range: timber shed with a slate pentice roof, straw butts, a crossbow rack
  SP.pentice_range = function(K, s)
    M.ground(K, s, 3)
    M.open_shed(K, s, -2.8, 0.2, 3.9, 1.6, 2.0, { wall = "planks", wall_c = s.timber_c, roof = "shed", rise = 0.8, base = false,
      timber = false, posts = false, bay = 1.0 })
    for i, x in ipairs({ 0.9, 1.8, 2.5 }) do Pr.target(K, x, 3.4 + (i % 2) * 0.3) end
    for i, x in ipairs({ -2.2, -1.0 }) do Pr.target(K, x, 2.3) end
    M.props(K, s, { { "rack", 1.3, 1.1 }, { "barrel", 2.4, 0.8 } })
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.flag(K, s, -2.6, 0.8, 4.0)
  end

  -- stable: long half-timbered stable on a low stone plinth, a hay-loft door in a gabled dormer, horse trough
  SP.frank_stable = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.8, 2.8, 3.0, 2.4, 2.2, { wall = "plaster", wall_c = s.plaster_c, timber = s.timber_c or "wood_dark",
      braces = true, base = s.base_c, base_h = 0.5, roof = "hip", rise = 1.6 })
    for x = -2.3, 2.2, 1.15 do A.door(K, x + 0.45, 3.0, 0.8, 1.6, "rect", s.door_c) end
    M.block(K, s, -0.45, 0.45, 2.9, 0.5, 3.0, { h0 = 2.2, wall = "planks", wall_c = s.timber_c, roof = "gable_front", rise = 0.7, base = false })
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.props(K, s, { { "horse", -1.6, 1.4, "horse_bay" }, { "horse", 1.2, 1.1, "horse_grey" }, { "trough", 0.0, 1.9 }, { "hay", 2.3, 2.2 } })
    M.flag(K, s, 2.75, 2.6, 4.4)
  end
end
