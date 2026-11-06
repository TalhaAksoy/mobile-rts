-- Pixel-art drawing helpers for the Pocket Empires 2D sprite generator (runs inside Aseprite, batch or live).
-- All drawing goes through a "canvas": one flat Image plus one Image per layer. Every pixel written lands in the
-- flat image and in the current layer only (it is erased from the other layers), so the saved .aseprite layers
-- always add up to exactly the flat result whatever the draw order was.
local P = {}

local pc = app.pixelColor
P.CLEAR = pc.rgba(0, 0, 0, 0)

function P.hex(h, a)
  h = h:gsub("#", "")
  return pc.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), a or 255)
end

function P.rgb(c) return pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), pc.rgbaA(c) end

-- multiply brightness (f < 1 darker, f > 1 lighter), with a slight hue shift: shadows cooler, lights warmer
function P.shade(c, f)
  local r, g, b, a = P.rgb(c)
  local function cl(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end
  if f < 1 then
    return pc.rgba(cl(r * f * 0.96), cl(g * f), cl(b * f * 1.06 + 4), a)
  end
  local add = (f - 1) * 255 * 0.55
  return pc.rgba(cl(r * f + add * 0.25 + 4), cl(g * f + add * 0.2), cl(b * f + add * 0.1), a)
end

function P.alpha(c) return pc.rgbaA(c) end

---------------------------------------------------------------------------------------------- canvas
function P.canvas(w, h, layers)
  return { w = w, h = h, flat = Image(w, h, ColorMode.RGB), owner = {}, layers = {}, order = layers,
           cur = layers[1], ox = 0, oy = 0 }
end

-- builds K.layers[name] from the flat image and the per-pixel owner map
function P.split(K)
  local imgs = {}
  for _, n in ipairs(K.order) do imgs[n] = Image(K.w, K.h, ColorMode.RGB) end
  local used = {}
  local x0, y0, x1, y1 = math.huge, math.huge, -1, -1
  for idx, n in pairs(K.owner) do
    local x, y = idx % K.w, idx // K.w
    local c = K.flat:getPixel(x, y)
    if pc.rgbaA(c) > 0 then
      if not imgs[n] then n = K.order[#K.order] end          -- a kit drew on a layer this canvas lacks
      imgs[n]:drawPixel(x, y, c); used[n] = true
      if x < x0 then x0 = x end; if x > x1 then x1 = x end
      if y < y0 then y0 = y end; if y > y1 then y1 = y end
    end
  end
  K.layers = imgs
  K.used = used
  K.bb = (x1 >= 0) and { x0, y0, x1, y1 } or nil
  return K
end

function P.use(K, layer) K.cur = layer end

-- origin offset: all drawing coordinates are relative to (K.ox, K.oy)
function P.put(K, x, y, c)
  x = math.floor(x + K.ox); y = math.floor(y + K.oy)
  if x < 0 or y < 0 or x >= K.w or y >= K.h then return end
  K.flat:drawPixel(x, y, c)
  -- remember which layer owns the pixel; P.split() builds the layer images once at the end
  K.owner[y * K.w + x] = (K.force and K.force[c]) or K.cur   -- team-ramp pixels always land on "team"
end

function P.get(K, x, y)
  x = math.floor(x + K.ox); y = math.floor(y + K.oy)
  if x < 0 or y < 0 or x >= K.w or y >= K.h then return P.CLEAR end
  return K.flat:getPixel(x, y)
end

function P.rect(K, x0, y0, x1, y1, c)
  if x0 > x1 then x0, x1 = x1, x0 end
  if y0 > y1 then y0, y1 = y1, y0 end
  for y = y0, y1 do for x = x0, x1 do P.put(K, x, y, c) end end
end

function P.hline(K, x0, x1, y, c) P.rect(K, x0, y, x1, y, c) end
function P.vline(K, x, y0, y1, c) P.rect(K, x, y0, x, y1, c) end

-- Bresenham line; th = thickness (1..3), drawn as a small square brush
-- points may also be given as {x,y} tables (e.g. from P.at), which keeps multi-value calls unambiguous
function P.line(K, ...)
  local a = {}
  for _, v in ipairs({ ... }) do
    if type(v) == "table" then a[#a + 1] = v[1]; a[#a + 1] = v[2] else a[#a + 1] = v end
  end
  local x0, y0, x1, y1, c, th = a[1], a[2], a[3], a[4], a[5], a[6]
  assert(type(c) == "number" and math.abs(x1 - x0) < 2000 and math.abs(y1 - y0) < 2000, "P.line: bad arguments")
  th = th or 1
  x0 = math.floor(x0 + 0.5); y0 = math.floor(y0 + 0.5); x1 = math.floor(x1 + 0.5); y1 = math.floor(y1 + 0.5)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  local lo = -math.floor((th - 1) / 2)
  local hi = lo + th - 1
  while true do
    for oy = lo, hi do for ox = lo, hi do P.put(K, x0 + ox, y0 + oy, c) end end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

function P.ellipse(K, cx, cy, rx, ry, c)
  for y = -ry, ry do
    for x = -rx, rx do
      local v = (x * x) / ((rx + 0.5) ^ 2) + (y * y) / ((ry + 0.5) ^ 2)
      if v <= 1.0 then P.put(K, cx + x, cy + y, c) end
    end
  end
end

-- even-odd scanline polygon fill; pts = {{x,y},...}
function P.poly(K, pts, c)
  local miny, maxy = math.huge, -math.huge
  for _, p in ipairs(pts) do miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
  for y = math.floor(miny), math.ceil(maxy) do
    local yc = y + 0.5
    local xs = {}
    local n = #pts
    for i = 1, n do
      local a, b = pts[i], pts[i % n + 1]
      if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
        xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = math.floor(xs[i] + 0.5), math.floor(xs[i + 1] - 0.5) do P.put(K, x, y, c) end
    end
  end
end

-- angle convention: 0 = straight down, 90 = forward (screen left, the way units face), 180 = up, -90 = back
function P.dir(a)
  local r = math.rad(a)
  return -math.sin(r), math.cos(r)
end

function P.along(x, y, a, len)
  local dx, dy = P.dir(a)
  return x + dx * len, y + dy * len
end

function P.at(x, y, a, len) local px, py = P.along(x, y, a, len) return { px, py } end

---------------------------------------------------------------------------------------------- image ops
function P.copy(img) return Image(img) end

-- 1px outline around the opaque silhouette (4-neighbourhood) -> new image with only the outline
function P.outline_of(img, col, bb)
  local w, h = img.width, img.height
  local out = Image(w, h, ColorMode.RGB)
  local bx0, by0, bx1, by1 = 0, 0, w - 1, h - 1
  if bb then
    bx0, by0 = math.max(0, bb[1] - 1), math.max(0, bb[2] - 1)
    bx1, by1 = math.min(w - 1, bb[3] + 1), math.min(h - 1, bb[4] + 1)
  end
  for y = by0, by1 do
    for x = bx0, bx1 do
      if pc.rgbaA(img:getPixel(x, y)) == 0 then
        local hit = false
        if x > 0 and pc.rgbaA(img:getPixel(x - 1, y)) > 0 then hit = true
        elseif x < w - 1 and pc.rgbaA(img:getPixel(x + 1, y)) > 0 then hit = true
        elseif y > 0 and pc.rgbaA(img:getPixel(x, y - 1)) > 0 then hit = true
        elseif y < h - 1 and pc.rgbaA(img:getPixel(x, y + 1)) > 0 then hit = true end
        if hit then out:drawPixel(x, y, col) end
      end
    end
  end
  return out
end

-- selective outline: like outline_of, but each outline pixel takes a dark version of the neighbouring colour
-- (light-side neighbours preferred), which reads softer and more detailed than a flat black line
function P.sel_outline_of(img, bb, darkest)
  local w, h = img.width, img.height
  local out = Image(w, h, ColorMode.RGB)
  local bx0, by0, bx1, by1 = 0, 0, w - 1, h - 1
  if bb then
    bx0, by0 = math.max(0, bb[1] - 1), math.max(0, bb[2] - 1)
    bx1, by1 = math.min(w - 1, bb[3] + 1), math.min(h - 1, bb[4] + 1)
  end
  local dk = darkest or pc.rgba(28, 22, 38, 255)
  local dr, dg, db = pc.rgbaR(dk), pc.rgbaG(dk), pc.rgbaB(dk)
  for y = by0, by1 do
    for x = bx0, bx1 do
      if pc.rgbaA(img:getPixel(x, y)) == 0 then
        local n
        for _, o in ipairs({ { 0, 1 }, { 1, 0 }, { -1, 0 }, { 0, -1 } }) do
          local nx, ny = x + o[1], y + o[2]
          if nx >= 0 and ny >= 0 and nx < w and ny < h then
            local c = img:getPixel(nx, ny)
            if pc.rgbaA(c) > 0 then n = c; break end
          end
        end
        if n then
          -- 35% of the neighbour + 65% of the dark ink
          local r = math.floor(pc.rgbaR(n) * 0.35 + dr * 0.65)
          local g = math.floor(pc.rgbaG(n) * 0.35 + dg * 0.65)
          local b = math.floor(pc.rgbaB(n) * 0.35 + db * 0.65)
          out:drawPixel(x, y, pc.rgba(r, g, b, 255))
        end
      end
    end
  end
  return out
end

-- paste src over dst (skips fully transparent pixels)
function P.blit(dst, src, ox, oy)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local c = src:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local tx, ty = x + ox, y + oy
        if tx >= 0 and ty >= 0 and tx < dst.width and ty < dst.height then dst:drawPixel(tx, ty, c) end
      end
    end
  end
end

-- exact colour replacement, map = { [pixel]=pixel }
function P.recolor(img, map)
  local out = Image(img)
  for it in out:pixels() do
    local v = map[it()]
    if v then it(v) end
  end
  return out
end

-- nearest-neighbour rotation by deg (screen clockwise) around (px,py), then shift by (sx,sy)
function P.rotate(img, deg, px, py, sx, sy)
  local w, h = img.width, img.height
  local out = Image(w, h, ColorMode.RGB)
  local r = math.rad(deg)
  local cs, sn = math.cos(r), math.sin(r)
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local dx, dy = x - px - (sx or 0), y - py - (sy or 0)
      local srcx = math.floor(dx * cs + dy * sn + px + 0.5)
      local srcy = math.floor(-dx * sn + dy * cs + py + 0.5)
      if srcx >= 0 and srcy >= 0 and srcx < w and srcy < h then
        local c = img:getPixel(srcx, srcy)
        if pc.rgbaA(c) > 0 then out:drawPixel(x, y, c) end
      end
    end
  end
  return out
end

-- bounding box of opaque pixels: x0,y0,x1,y1 (nil if empty)
function P.bbox(img)
  local x0, y0, x1, y1 = math.huge, math.huge, -1, -1
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      if pc.rgbaA(img:getPixel(x, y)) > 0 then
        if x < x0 then x0 = x end; if x > x1 then x1 = x end
        if y < y0 then y0 = y end; if y > y1 then y1 = y end
      end
    end
  end
  if x1 < 0 then return nil end
  return x0, y0, x1, y1
end

function P.crop(img, x, y, w, h)
  local out = Image(w, h, ColorMode.RGB)
  out:drawImage(img, Point(-x, -y))
  return out
end

-- deterministic hash noise in [0,1)
function P.noise(x, y, seed)
  local n = math.floor(x) * 374761393 + math.floor(y) * 668265263 + (seed or 0) * 982451653
  n = (n ~ (n >> 13)) * 1274126177
  n = n ~ (n >> 16)
  return (n & 0xffff) / 65536.0
end

---------------------------------------------------------------------------------------------- json
local function esc(s) return '"' .. tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"' end
function P.json(v, ind)
  ind = ind or ""
  local t = type(v)
  if t == "table" then
    if #v > 0 or next(v) == nil then
      local parts = {}
      for _, x in ipairs(v) do parts[#parts + 1] = P.json(x, ind .. "  ") end
      return "[" .. table.concat(parts, ", ") .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = ind .. "  " .. esc(k) .. ": " .. P.json(v[k], ind .. "  ") end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. ind .. "}"
  elseif t == "string" then return esc(v)
  elseif t == "boolean" then return tostring(v)
  elseif t == "number" then
    if v == math.floor(v) then return string.format("%d", v) end
    return string.format("%.3f", v)
  end
  return "null"
end

function P.write(path, text)
  app.fs.makeAllDirectories(app.fs.filePath(path))
  local f = io.open(path, "w"); f:write(text); f:close()
end

return P
