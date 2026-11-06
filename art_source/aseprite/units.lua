-- Builds one unit: 34 animation frames -> layered .aseprite source (tags per animation) + the game's sprite sheets
-- (8 columns x 6 rows, one animation per row, team colours swapped per sheet) + a meta JSON for the manifest.
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local CH = dofile(GEN_ROOT .. "/char.lua")
local U = {}

U.PX_PER_M = 32
U.ANIMS = { -- name, frames, fps, loop (row order = sheet rows, same as the Blender sheets)
  { "idle", 4, 4, true }, { "walk", 8, 10, true }, { "attack", 6, 8, false },
  { "gather", 6, 7, true }, { "build", 4, 8, true }, { "death", 6, 7, false },
}
local LAYERS = { "outline", "shadow", "mount", "body", "armor", "team", "weapon" }
local SHADOW = P.hex("#221c2a")

local function deep(t) local o = {} for k, v in pairs(t) do o[k] = type(v) == "table" and deep(v) or v end return o end

---------------------------------------------------------------------------------------------- poses
local function idle(st, i)
  local b = (i >= 2) and 1 or 0
  if st.mount then b = 0 end
  local p = { bob = b, af = 18, ab = -8, hb = 0 }
  local w = st.weapon
  if w == "spear" or w == "yari" or w == "halberd" or w == "naginata" or w == "guandao" or w == "lance" then p.af = 30; p.w = 172 - b * 2; p.wopt = { back = 10, len = 28 }
  elseif w == "bow" then p.af = 25; p.w = 0
  elseif w == "musket" then p.af = 35; p.w = 160
  elseif w == "crossbow" then p.af = 60
  elseif st.villager then p.weapon = false
  else p.w = 45 end
  return p
end

local function walk(st, i)
  local ph = 2 * math.pi * i / 8
  local s, c = math.sin(ph), math.cos(ph)
  local dxf = -math.floor(2.6 * s + 0.5)        -- small stride: in 3/4 view the legs mostly alternate lifting
  local p = idle(st, 0)
  p.bob = (math.abs(s) < 0.5) and -1 or 0
  p.lf = { dxf, (c > 0.3) and 2 or 0 }
  p.lb = { -dxf, (c < -0.3) and 2 or 0 }
  p.af = (p.af or 18) + math.floor(18 * s)
  p.ab = -8 - math.floor(18 * s)
  if st.mount then                                  -- riders keep still, the mount walks
    p = idle(st, 0); p.gait = i; p.hb = (i % 4 == 1 or i % 4 == 2) and -1 or 0; p.bob = 0
  end
  if p.w and (st.weapon == "spear" or st.weapon == "yari" or st.weapon == "halberd" or st.weapon == "naginata" or st.weapon == "guandao" or st.weapon == "lance") then p.af = 30 end
  if st.weapon == "bow" then p.af = 25 end
  return p
end

local ATTACK = {}
ATTACK.slash = function(st, i)
  local af = ({ 195, 222, 165, 95, 55, 100 })[i + 1]
  local lean = ({ 0, 1, 0, -1, -1, 0 })[i + 1]
  return { af = af, w = af + ((i < 2) and 15 or 0), lean = lean, lf = { ({ 0, 0, -2, -3, -3, -2 })[i + 1], 0 }, ab = 5 }
end
ATTACK.thrust = function(st, i)
  local lean = ({ 1, 2, 0, -2, -2, 0 })[i + 1]
  return { af = ({ 70, 60, 80, 95, 95, 80 })[i + 1], w = 97, lean = lean, wopt = { back = 12, len = 26 },
           lf = { ({ 0, 0, -2, -5, -5, -2 })[i + 1], 0 }, ab = 30 }
end
ATTACK.bow = function(st, i)
  local d = ({ 0, 3, 6, 6, 0, 0 })[i + 1]
  return { af = 88, w = 90, wopt = { draw = d, arrow = (i >= 1 and i <= 3) }, lean = (i == 4) and 1 or 0 }
end
ATTACK.crossbow = function(st, i)
  return { af = 85, w = 90, wopt = { arrow = (i < 3) }, lean = (i == 3) and 1 or 0 }
end
ATTACK.gun = function(st, i)
  return { af = 85, w = 92, wopt = { flash = (i == 2), smoke = (i >= 3 and i <= 4) and (i - 2) or nil },
           lean = (i == 2 or i == 3) and 1 or 0 }
end

local function chop(st, i, tool)
  local af = ({ 170, 198, 130, 55, 25, 95 })[i + 1]
  return { af = af, w = af + 10, weapon = tool, lean = ({ 0, 1, 0, -1, -1, 0 })[i + 1], bob = ({ 0, 0, 0, 1, 1, 0 })[i + 1], ab = 10 }
end
local function hammer(st, i)
  local af = ({ 160, 188, 80, 40 })[i + 1]
  return { af = af, w = af + 20, weapon = "hammer", lean = ({ 0, 0, -1, -1 })[i + 1], bob = ({ 0, 0, 1, 1 })[i + 1], ab = 15 }
end

---------------------------------------------------------------------------------------------- frames
local CW, CH_, AX, AY = 176, 176, 88, 132

local function new_canvas()
  local K = P.canvas(CW, CH_, LAYERS)
  K.ox, K.oy = AX, AY
  K.force = C.team_force({ [SHADOW] = "shadow" })
  return K
end

-- dithered ground shadow under the feet (the 2D style shows units from above, so they need one)
local function ground_shadow(K, mounted)
  local rx, ry = mounted and 22 or 11, mounted and 5 or 3
  P.use(K, "shadow")
  for y = -ry, ry do for x = -rx, rx do
    if (x * x) / ((rx + 0.5) ^ 2) + (y * y) / ((ry + 0.5) ^ 2) <= 1 and (x + y) % 2 == 0 then P.put(K, x + 1, y, SHADOW) end
  end end
  P.use(K, "body")
end

local function finish(K)
  P.split(K)
  -- outline layer around the silhouette (not around the dithered shadow)
  local solid = Image(K.flat)
  if K.used.shadow then
    for it in K.layers.shadow:pixels() do if P.alpha(it()) > 0 then solid:drawPixel(it.x, it.y, P.CLEAR) end end
  end
  local ol = P.sel_outline_of(solid, K.bb)
  K.layers.outline = ol
  K.used.outline = true
  if K.bb then K.bb = { K.bb[1] - 1, K.bb[2] - 1, K.bb[3] + 1, K.bb[4] + 1 } end
  local flat = Image(K.layers.shadow)
  flat:drawImage(ol, Point(0, 0)); flat:drawImage(solid, Point(0, 0))
  K.flat = flat
  return K
end

local function render(st, pose)
  local K = new_canvas()
  ground_shadow(K, st.mount ~= nil)
  if st.mount then CH.draw_mounted(K, st, pose) else CH.draw(K, st, pose) end
  return finish(K)
end

-- the body falls, the ground shadow stays where it was
local function rotated(K, deg, sy)
  local R = { layers = {}, used = K.used }
  for n, im in pairs(K.layers) do
    if K.used[n] then R.layers[n] = (n == "shadow") and Image(im) or P.rotate(im, deg, AX, AY, 0, sy) end
  end
  local flat = Image(K.layers.shadow or Image(K.flat.width, K.flat.height, ColorMode.RGB))
  for _, n in ipairs({ "outline", "mount", "body", "armor", "team", "weapon" }) do
    if R.layers[n] then flat:drawImage(R.layers[n], Point(0, 0)) end
  end
  R.flat = flat
  R.bb = { P.bbox(R.flat) }
  return R
end

function U.frames(st)
  local out = {}
  local function add(name, K) out[#out + 1] = { anim = name, K = K } end
  for i = 0, 3 do add("idle", render(st, idle(st, i))) end
  for i = 0, 7 do add("walk", render(st, walk(st, i))) end
  local atk = st.attack or "slash"
  for i = 0, 5 do
    if st.villager then add("attack", render(st, chop(st, i, st.weapon or "axe")))
    elseif st.attack_fn then add("attack", render(st, st.attack_fn(st, i)))
    else add("attack", render(st, ATTACK[atk](st, i))) end
  end
  for i = 0, 5 do
    if st.villager then add("gather", render(st, chop(st, i, st.gather_tool or "axe")))
    else add("gather", render(st, idle(st, i % 4))) end
  end
  for i = 0, 3 do
    if st.villager then add("build", render(st, hammer(st, i)))
    else add("build", render(st, idle(st, i))) end
  end
  -- death: recoil, buckle, fall backwards (the unit faces left, so it falls to the right), lie still
  local base = idle(st, 0)
  local k1 = deep(base); k1.lean = 1; k1.af = 150; k1.w = 170; k1.ab = 160; k1.hlean = 1
  local k2 = deep(base); k2.lean = 3; k2.bob = 5; k2.af = 120; k2.w = 140; k2.ab = 150
  local f1, f2 = render(st, k1), render(st, k2)
  add("death", f1); add("death", f2)
  add("death", rotated(f2, 35, -2)); add("death", rotated(f2, 70, -5))
  local lying = rotated(f2, 90, -7)
  add("death", lying); add("death", lying)
  return out
end

---------------------------------------------------------------------------------------------- output
local function team_map(team) return C.team_map(team) end

-- st: style table; key: "<civ>/<role>"; paths: {aseprite=, png_dir=, meta=, res_dir=}
function U.build(st, civ, role, paths)
  local frames = U.frames(st)
  -- common crop over all frames
  local x0, y0, x1, y1 = math.huge, math.huge, -1, -1
  for _, f in ipairs(frames) do
    local bb = f.K.bb
    local a, b, c, d = bb and bb[1], bb and bb[2], bb and bb[3], bb and bb[4]
    if a then x0 = math.min(x0, a); y0 = math.min(y0, b); x1 = math.max(x1, c); y1 = math.max(y1, d) end
  end
  y1 = math.max(y1, AY)
  local w, h = x1 - x0 + 1, y1 - y0 + 1
  local ax, ay = AX - x0 + 0.5, AY - y0 + 1

  -- layered Aseprite source
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.filename = paths.aseprite
  local layer_objs = {}
  layer_objs[LAYERS[1]] = spr.layers[1]; spr.layers[1].name = LAYERS[1]
  for i = 2, #LAYERS do local L = spr:newLayer(); L.name = LAYERS[i]; layer_objs[LAYERS[i]] = L end
  for i = 2, #frames do spr:newEmptyFrame() end
  local fi = 1
  for _, a in ipairs(U.ANIMS) do
    local first = fi
    for j = 1, a[2] do
      local f = frames[fi]
      spr.frames[fi].duration = 1.0 / a[3]
      for _, ln in ipairs(LAYERS) do
        local im = f.K.layers[ln]
        if im and f.K.used[ln] then spr:newCel(layer_objs[ln], fi, P.crop(im, x0, y0, w, h), Point(0, 0)) end
      end
      fi = fi + 1
    end
    local tag = spr:newTag(first, fi - 1); tag.name = a[1]
    if a[4] == false then pcall(function() tag.repeats = 1 end) end
  end
  app.fs.makeAllDirectories(app.fs.filePath(paths.aseprite))
  spr:saveAs(paths.aseprite)
  spr:close()

  -- sheets per team
  local meta = { w = w, h = h, anchor = { ax, ay }, px_per_m = U.PX_PER_M, hframes = 8, vframes = #U.ANIMS,
                 anims = {}, view = "oblique" }
  local row = 0
  local sheet = Image(w * 8, h * #U.ANIMS, ColorMode.RGB)
  fi = 1
  for _, a in ipairs(U.ANIMS) do
    meta.anims[a[1]] = { row = row, frames = a[2], fps = a[3], loop = a[4] }
    for j = 0, a[2] - 1 do
      sheet:drawImage(P.crop(frames[fi].K.flat, x0, y0, w, h), Point(j * w, row * h))
      fi = fi + 1
    end
    row = row + 1
  end
  app.fs.makeAllDirectories(paths.png_dir)
  for team = 0, 1 do
    local name = string.format("%s_t%d.png", paths.name or role, team)
    P.recolor(sheet, team_map(team)):saveAs(app.fs.joinPath(paths.png_dir, name))
    meta["t" .. team] = paths.res_dir .. "/" .. name
  end
  P.write(paths.meta, P.json(meta))
  return meta
end

return U
