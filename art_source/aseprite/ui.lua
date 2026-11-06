-- UI art from the pixel-art set: unit portraits (art/units/<civ>/<role>/{pose_01,pose_02,action_reference,
-- rear_reference}.png), building icons (art/buildings/<civ>/<id>.png) and each civ's gallery poster
-- (art/concept_sheets/<civ>.png). Images are upscaled by whole numbers (nearest) so they stay crisp under the
-- UI's linear filtering. Team-coloured parts use team 0 (the player's blue).
local P = dofile(GEN_ROOT .. "/px.lua")
local C = dofile(GEN_ROOT .. "/palette.lua")
local UI = {}

local function load(path) return Image { fromFile = path } end

local function cell(sheet, col, row)
  local fw, fh = sheet.width // 8, sheet.height // 6
  return P.crop(sheet, col * fw, row * fh, fw, fh)
end

local function trim(img)
  local x0, y0, x1, y1 = P.bbox(img)
  if not x0 then return img end
  return P.crop(img, x0, y0, x1 - x0 + 1, y1 - y0 + 1)
end

local function upscale(img, k)
  if k == 1 then return Image(img) end
  local out = Image(img.width * k, img.height * k, ColorMode.RGB)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local c = img:getPixel(x, y)
      if P.alpha(c) > 0 then
        for dy = 0, k - 1 do for dx = 0, k - 1 do out:drawPixel(x * k + dx, y * k + dy, c) end end
      end
    end
  end
  return out
end

local function flip(img)
  local out = Image(img.width, img.height, ColorMode.RGB)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do out:drawPixel(img.width - 1 - x, y, img:getPixel(x, y)) end end
  return out
end

-- fit into a size x size canvas, bottom-centred, whole-number scale
local function framed(img, size, margin)
  img = trim(img)
  local k = math.max(1, math.floor(math.min((size - 2 * margin) / img.width, (size - 2 * margin) / img.height)))
  local up = upscale(img, k)
  local out = Image(size, size, ColorMode.RGB)
  out:drawImage(up, Point((size - up.width) // 2, size - margin - up.height))
  return out
end

local function save(img, path)
  app.fs.makeAllDirectories(app.fs.filePath(path))
  img:saveAs(path)
end

-- base = folder with the 3/4 sheets (build/px34)
function UI.unit(godot, base, civ, role)
  local sheet = load(string.format("%s/units/%s/%s_t0.png", base, civ, role))
  local dir = string.format("%s/art/units/%s/%s", godot, civ, role)
  save(framed(cell(sheet, 0, 0), 160, 6), dir .. "/pose_01.png")
  save(framed(cell(sheet, 2, 1), 160, 6), dir .. "/pose_02.png")
  save(framed(cell(sheet, 3, 2), 160, 6), dir .. "/action_reference.png")
  save(framed(flip(cell(sheet, 6, 1)), 160, 6), dir .. "/rear_reference.png")
  return cell(sheet, 0, 0)
end

function UI.building(godot, base, civ, bid)
  local img = trim(load(string.format("%s/buildings/%s/%s_t0.png", base, civ, bid)))
  local k = math.max(1, math.floor(math.min(360 / img.width, 360 / img.height)))
  local up = upscale(img, k)
  save(up, string.format("%s/art/buildings/%s/%s.png", godot, civ, bid))
  return img
end

-- gallery poster: town centre and castle on top, every unit in a row below, on a parchment card
function UI.poster(godot, civ, units, blds)
  local W, H = 480, 680
  local out = Image(W, H, ColorMode.RGB)
  local paper, edge = P.hex("#e9dcbc"), P.hex("#8a6a44")
  for y = 0, H - 1 do for x = 0, W - 1 do
    local n = P.noise(x // 3, y // 3, 99)
    local c = (n > 0.92) and P.shade(paper, 0.95) or paper
    if x < 6 or y < 6 or x >= W - 6 or y >= H - 6 then c = edge end
    out:drawPixel(x, y, c)
  end end
  local function place(img, k, cx, by)
    local up = upscale(trim(img), k)
    out:drawImage(up, Point(math.floor(cx - up.width / 2), by - up.height))
  end
  if blds.castle then place(blds.castle, 1, W * 0.30, 300) end
  if blds.town_center then place(blds.town_center, 1, W * 0.74, 300) end
  -- ground line
  for x = 20, W - 21 do out:drawPixel(x, 302, edge) end
  local n = #units
  local per_row = math.min(n, 3)
  local rows = math.ceil(n / per_row)
  local i = 0
  for r = 0, rows - 1 do
    local cnt = math.min(per_row, n - r * per_row)
    for c = 0, cnt - 1 do
      i = i + 1
      local cx = W * (c + 1) / (cnt + 1)
      place(units[i], 2, cx, 300 + 180 * (r + 1) - 10)
    end
  end
  save(out, string.format("%s/art/concept_sheets/%s.png", godot, civ))
end

return UI
