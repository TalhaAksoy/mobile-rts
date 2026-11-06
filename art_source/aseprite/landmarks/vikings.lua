-- Norse layouts (docs/art/culture/vikings.md): chieftain's great hall (bow-sided longhouse, shingle roof, crossed
-- gable ends, shields on the wall), Trelleborg ring fortress, turf-roofed house, timber horn tower, Norse mill.
return function(M)
  local A, Pr = M.A, M.Pr
  local P = dofile(GEN_ROOT .. "/px.lua")
  local C = dofile(GEN_ROOT .. "/palette.lua")
  local CH = dofile(GEN_ROOT .. "/char.lua")
  local col, tone = A.col, A.tone
  local SP = M.SPECIAL

  local function shields_on_wall(K, s, x0, x1, d, h)
    local cols = { "team", s.palette.weld, "team", s.palette.black, "team", s.palette.madder }
    local i = 0
    for x = x0, x1, 0.55 do
      i = i + 1
      local st = { shield = "small_round", shield_color = cols[(i - 1) % #cols + 1], shield_rim = s.palette.tar, emblem = "boss", boss = "iron" }
      CH.shield(K, st, A.px(x), A.vy(d, h))
    end
  end

  SP.great_hall = function(K, s)
    M.ground(K, s, 3)
    M.block(K, s, -2.9, 2.9, 1.8, 3.0, 2.0, { roof = "gable", rise = 2.4, over = 0.45 })
    -- inclined outer posts (Trelleborg type)
    P.use(K, "props")
    for x = -2.7, 2.7, 0.9 do P.line(K, A.px(x), A.vy(1.4, 0), A.px(x), A.vy(1.8, 1.9), col(s.timber_c), 2) end
    P.use(K, "structure")
    shields_on_wall(K, s, -2.4, 2.4, 1.8, 1.25)
    M.door(K, s, 0, 1.8, 0.9, 1.5)
    -- crossed dragon gable posts at both ends of the ridge
    P.use(K, "props")
    local ry = A.vy(3.3, 4.4)
    for _, x in ipairs({ -3.1, 3.1 }) do
      local px = A.px(x)
      P.line(K, px - 1, ry + 4, px + 7, ry - 8, col(s.timber_c), 2); P.line(K, px + 1, ry + 4, px - 7, ry - 8, col(s.timber_c), 2)
      P.put(K, px + 8, ry - 9, tone(col(s.palette.weld), 3)); P.put(K, px - 8, ry - 9, tone(col(s.palette.weld), 3))
    end
    P.use(K, "structure")
    Pr.runestone(K, -2.4, 0.5)
    M.props(K, s, { { "barrel", 2.4, 0.6 } })
    M.flag(K, s, 2.8, 0.6, 3.8)
  end

  SP.trelleborg = function(K, s)
    M.ground(K, s, 4)
    -- longhouses inside the ring
    M.block(K, s, -2.4, 0.2, 3.6, 2.0, 1.8, { roof = "gable", rise = 1.6 })
    M.block(K, s, 0.6, 3.0, 4.2, 1.8, 1.7, { roof = "gable", rise = 1.5 })
    -- circular earth rampart with timber facing and a stake palisade, gate at the front
    P.use(K, "structure")
    local sod = col(s.palette.sod)
    local cx, cy = 0, A.vy(1.6, 0) - 10
    for a = 0, 359, 1 do
      local r = math.rad(a)
      local x = math.floor(cx + math.cos(r) * A.X * 3.6)
      local y = math.floor(cy + math.sin(r) * A.X * 1.4)
      local front = math.sin(r) > 0
      if not (front and math.abs(x) < A.px(0.6)) then
        for k = 0, 12 do P.put(K, x, y - k, (k > 9) and tone(col(s.palette.turf), (k == 12) and 2 or 3) or (front and A.WALL.planks(col(s.timber_c), 3, x, y - k, x, y - k, {}) or tone(sod, 4))) end
        if a % 4 == 0 then P.vline(K, x, y - 19, y - 12, tone(col(s.timber_c), front and 3 or 4)); P.put(K, x, y - 20, tone(col(s.timber_c), 2)) end
      end
    end
    A.door(K, 0, 0.2, 1.0, 1.4, "rect", s.door_c)
    M.flag(K, s, 0.9, 0.3, 3.6)
  end

  SP.turf_house = function(K, s)
    M.ground(K, s, 2)
    M.block(K, s, -1.6, 1.4, 1.3, 2.2, 1.3, { roof = "hip", roof_mat = "turf", roof_c = s.palette.turf, rise = 1.4, over = 0.4,
      ridge = s.palette.turf, wall = "planks", wall_c = s.palette.tar })
    M.door(K, s, -0.6, 1.3, 0.6, 1.2)
    M.props(K, s, { { "barrel", 1.6, 0.5 }, { "logs", -1.8, 0.6, 0.6, 2 } })
  end

  SP.horn_tower = function(K, s)
    M.ground(K, s, 2)
    M.stilts(K, s, -0.9, 0.9, 1.0, 1.4, 5.2)
    M.block(K, s, -1.0, 1.0, 1.0, 1.4, 6.2, { h0 = 5.2, wall = "planks", roof = "gable", rise = 1.0, base = false })
    P.use(K, "props")
    P.line(K, A.px(0.6), A.vy(1.0, 5.8), A.px(1.1), A.vy(1.0, 5.5), C.cream, 2)                   -- war horn
    P.use(K, "structure")
    A.banner(K, 0, 1.0, 5.0, 0.4, 0.9, s.emblem, s.ec)
  end

  -- Norse horizontal mill: a tiny plank hut over a stream
  SP.norse_mill = function(K, s)
    M.ground(K, s, 2)
    P.use(K, "ground")
    M.stream(K, -0.9, 0.3, 0.4, 3.7)
    P.use(K, "structure")
    M.block(K, s, -1.1, 0.5, 2.0, 1.4, 1.4, { h0 = 0.3, roof = "gable", rise = 0.9, wall = "planks", base = false })
    M.door(K, s, -0.2, 2.0, 0.5, 1.0)
    M.props(K, s, { { "sacks", 1.2, 0.8 }, { "runestone", 1.6, 2.4 } })
    local px, py = A.px(1.0), A.vy(0.5, 0)
    P.use(K, "props"); P.ellipse(K, px, py - 4, 7, 3, C.stone_grey); P.ellipse(K, px, py - 7, 6, 2, P.shade(C.stone_grey, 1.15)); P.use(K, "structure")
    M.flag(K, s, 1.85, 0.4, 3.0)
  end

  -- barracks: Trelleborg hall, a long plank hall with bowed walls, a row of sloping outer posts propping the eaves,
  -- shingle roof, round shields hung along the wall
  SP.trelleborg_hall = function(K, s)
    M.ground(K, s, 3)
    local b = M.block(K, s, -2.7, 2.7, 2.2, 2.6, 1.9, { roof = "gable", rise = 1.7 })
    local f = b.facade
    P.use(K, "props")
    for i = 0, 7 do                                                  -- sloping outer posts
      local x = A.px(-2.55 + i * 0.73)
      P.line(K, x - 6, f.yb + 6, x, f.yt - 2, C.wood_dark, 2)
    end
    for i = 0, 4 do                                                  -- shields on the wall: team field, iron boss
      local cx, cy = A.px(-2.0 + i * 1.0), f.yt + 12
      P.use(K, "team"); P.ellipse(K, cx, cy, 5, 5, C.TEAM_D); P.ellipse(K, cx, cy, 4, 4, C.TEAM)
      P.use(K, "props"); P.ellipse(K, cx, cy, 1, 1, C.iron)
    end
    P.use(K, "structure")
    M.door(K, s, 0, 2.2, 0.8, 1.4, "rect")
    M.props(K, s, { { "rack", 2.0, 0.9 }, { "runestone", -2.2, 0.8 }, { "barrel", -1.4, 0.6 } })
    M.flag(K, s, 2.7, 1.4, 4.2)
  end

  -- archery range: a cleared yard, straw and hide targets on posts, a turf-roofed lean-to
  SP.hide_targets = function(K, s)
    M.ground(K, s, 3)
    M.open_shed(K, s, -2.8, -0.6, 3.6, 1.4, 1.6, { wall = "planks", wall_c = s.timber_c, roof = "shed", rise = 0.6,
      roof_mat = "turf", roof_c = "#5E7A3A", base = false, timber = false, posts = false, bay = 1.1 })
    for i, x in ipairs({ 0.2, 1.2, 2.2 }) do
      Pr.target(K, x, 3.5 + (i % 2) * 0.3)
      local px, py = A.px(x), A.vy(3.5 + (i % 2) * 0.3, 0) - 18                           -- stretched hide over it
      P.use(K, "props"); P.rect(K, px - 5, py - 6, px + 5, py + 6, P.hex("#B08A60")); P.ellipse(K, px, py, 2, 2, C.red)
      P.use(K, "structure")
    end
    M.props(K, s, { { "rack", -1.8, 1.4 }, { "runestone", 2.4, 1.2 }, { "barrel", -0.4, 0.8 } })
    M.flag(K, s, -2.6, 0.8, 4.0)
  end

  -- stable: a low turf-roofed byre with wattle partitions between the stalls
  SP.byre = function(K, s)
    M.ground(K, s, 3)
    M.open_shed(K, s, -2.8, 2.8, 3.0, 2.2, 1.5, { wall = "planks", wall_c = s.timber_c, roof = "gable", roof_mat = "turf",
      roof_c = "#5E7A3A", rise = 1.1, base = false, timber = false, posts = false, bay = 1.4 })
    for i, x in ipairs({ -1.4, 0.0, 1.4 }) do                                             -- wattle partitions
      local px, py = A.px(x), A.vy(3.0, 0)
      P.use(K, "props")
      for y = py - 20, py do for xx = px - 2, px + 2 do P.put(K, xx, y, tone(C.wood, ((y + xx) % 3 == 0) and 4 or 2)) end end
      P.use(K, "structure")
    end
    Pr.fence(K, -2.8, 2.8, 0.35)
    M.props(K, s, { { "horse", -1.6, 1.4, "horse_bay" }, { "horse", 1.2, 1.1, "horse_grey" }, { "trough", 0.0, 1.9 }, { "hay", 2.3, 2.2 } })
    M.flag(K, s, 2.75, 2.6, 4.0)
  end

  -- blacksmith: an open-sided turf-roofed shed, a clay forge with bellows, the anvil on a log
  SP.turf_forge = function(K, s)
    M.ground(K, s, 2)
    M.open_shed(K, s, -1.85, 1.0, 2.2, 1.4, 1.6, { wall = "planks", wall_c = s.timber_c, roof = "gable", roof_mat = "turf",
      roof_c = "#5E7A3A", rise = 0.8, base = false, timber = false, posts = false, bay = 0.95 })
    M.props(K, s, { { "furnace", -0.6, 2.4 }, { "bellows", 0.4, 2.4 }, { "stump", 0.5, 0.8 }, { "anvil", -0.6, 0.7 }, { "runestone", 1.6, 1.4 } })
    M.flag(K, s, 1.85, 0.4, 3.0)
  end

  -- lumber camp: pine logs, an adze bench and a half-built boat on its trestles
  SP.boat_yard = function(K, s)
    M.ground(K, s, 2)
    Pr.boat(K, 0.0, 2.2)
    M.props(K, s, { { "logs", -1.7, 1.0, 1.2, 3 }, { "stump", 1.3, 0.8 }, { "sawhorse", 0.4, 0.5 } })
    M.flag(K, s, 1.85, 0.4, 3.0)
  end

  -- mining camp: a bog-iron pit, a clay shaft furnace for smelting and heaps of slag
  SP.bog_iron = function(K, s)
    M.ground(K, s, 2)
    local px, py = A.px(-0.6), A.vy(2.2, 0)
    P.use(K, "props")
    Pr.blob(K, px, py - 4, 22, 7, P.hex("#4A3A2A"), 3)                                     -- the peat bog pit
    Pr.blob(K, px - 4, py - 5, 12, 4, P.hex("#6A4A2A"), 5)
    P.use(K, "structure")
    M.props(K, s, { { "furnace", 1.1, 2.0 }, { "ore", 1.4, 0.8, "iron_dark", 8 }, { "ore", -1.3, 0.6, "#8A4A2A", 6 }, { "basket", 0.2, 0.6, "#8A4A2A" } })
    M.flag(K, s, -1.85, 0.4, 3.0)
  end
end
