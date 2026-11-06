-- Menu icons (16x16 pixel art, saved x3 = 48 px) for the civ select screen, so its headings and field labels
-- are pictures instead of words: crown (perks), star (unique unit), swords (army), skull (difficulty), map (map
-- size), mountains (battlefield), shield (opponents), crossing arrows (random civ), back arrow, start (play).
--   aseprite -b --script-param root=$PWD --script art_source/aseprite/ui_icons.lua
-- Output: sample_project/assets/ui/icons/<name>.png
local root = app.params.root or "."
local OUT = root .. "/sample_project/assets/ui/icons/"
local SCALE = 3

local PAL = {
  K = "#2a1a0e", G = "#e3b341", g = "#a8781e", Y = "#f6dc7a", W = "#f3efe6", w = "#c9c0ae", S = "#b8c0cc",
  s = "#6c7584", R = "#b8262a", r = "#7e1a1e", B = "#6b4a2e", N = "#5e8a3a", n = "#3a5a26", U = "#3e5486",
  u = "#7fa0d8", T = "#e8d6ae", t = "#b89a6a",
}

local ICONS = {
  crown = {
    "................",
    "................",
    ".K.....K.....K..",
    "KYK...KYK...KYK.",
    "KGK...KGK...KGK.",
    "KGGK.KGGGK.KGGK.",
    "KGGGKGGGGGKGGGK.",
    "KGGGGGGGGGGGGGK.",
    "KGRGGGGUGGGGRGK.",
    "KGGGGGGGGGGGGGK.",
    "KgggggggggggggK.",
    "KYYYYYYYYYYYYYK.",
    "KgggggggggggggK.",
    ".KKKKKKKKKKKKK..",
  },
  star = {
    ".......KK.......",
    "......KYYK......",
    "......KYGK......",
    ".....KYGGGK.....",
    "KKKKKYGGGGKKKKKK",
    "KYYYYGGGGGGGGGgK",
    ".KGGGGGGGGGGGgK.",
    "..KGGGGGGGGGgK..",
    "...KGGGGGGGgK...",
    "...KGGGGGGGgK...",
    "..KGGGGKKGGGgK..",
    "..KGGgK..KGGgK..",
    ".KGgKK....KKggK.",
    ".KKK........KKK.",
  },
  swords = {
    "KK............KK",
    "KSK..........KSK",
    ".KSK........KSK.",
    "..KSK......KSK..",
    "...KSK....KSK...",
    "....KSK..KSK....",
    ".....KSKKSK.....",
    "......KSSK......",
    "......KSSK......",
    ".....KSKKSK.....",
    "..KGKSK..KSKGK..",
    "...KGK....KGK...",
    "..KBKGK..KGKBK..",
    ".KBK.KK..KK.KBK.",
    ".KK..........KK.",
  },
  skull = {
    "................",
    ".....KKKKKK.....",
    "...KKWWWWWWKK...",
    "..KWWWWWWWWWwK..",
    "..KWWWWWWWWWwK..",
    "..KWKKKWWKKKwK..",
    "..KWKKKWWKKKwK..",
    "..KWWWWKKWWWwK..",
    "...KWWWKKWWwK...",
    "....KWWWWWwK....",
    "....KWKWKWKK....",
    "....KWKWKWwK....",
    ".....KKKKKK.....",
  },
  map = {
    "................",
    ".KKKKKKKKKKKKKK.",
    ".KTTTTTTTTTTTtK.",
    ".KTTuuTTTTTTTtK.",
    ".KTuuuTTTNNTTtK.",
    ".KTTuTTTTNNNTtK.",
    ".KTTTTtTTTNTTtK.",
    ".KTTTTTtTTTTTtK.",
    ".KTTNTTTtTRTRtK.",
    ".KTNNNTTTTTRTtK.",
    ".KTTNTTTTTRTRtK.",
    ".KtttttttttttTK.",
    ".KKKKKKKKKKKKKK.",
  },
  battlefield = {
    "................",
    "......K.........",
    ".....KWK........",
    "....KWSSK.......",
    "...KSSSSSK...K..",
    "..KSSSsSSSK.KWK.",
    ".KSSSsssSSSKSSSK",
    "KSSSsssssSSSsSSK",
    "KSSsssssssSSssSK",
    "KNNNNNNNNNNNNNNK",
    "KnNnnNnnNnnNnnNK",
    "KKKKKKKKKKKKKKKK",
  },
  opponents = {
    "..KKKKKKKKKKKK..",
    "..KRRRRRKUUUUK..",
    "..KRRRRRKUUUUK..",
    "..KRRRRRKUuUUK..",
    "..KRRRRRKUuUUK..",
    "..KRRRRRKUuUUK..",
    "..KRRRRRKUUUUK..",
    "..KRRRRRKUUUUK..",
    "...KRRRRKUUUK...",
    "....KRRRKUUK....",
    ".....KrRKUK.....",
    "......KKKK......",
  },
  shuffle = {                                                         -- two crossing arrows: "random civ"
    "............B...",
    "............BB..",
    "............BBB.",
    "KKKK.....BBBBBBB",
    "KKKKK...BBBBBBBB",
    "....K...B...BBB.",
    "....KK.BB...BB..",
    ".....KKB....B...",
    ".....BKK....K...",
    "....BB.KK...KK..",
    "....B...K...KKK.",
    "BBBBB...KKKKKKKK",
    "BBBB.....KKKKKKK",
    "............KKK.",
    "............KK..",
    "............K...",
  },
  back = {
    "................",
    "......K.........",
    ".....KK.........",
    "....KGK.........",
    "...KGGKKKKKKKKK.",
    "..KGGGGGGGGGGGK.",
    ".KYGGGGGGGGGGGK.",
    "..KGGGGGGGGGGgK.",
    "...KGgKKKKKKKKK.",
    "....KgK.........",
    ".....KK.........",
    "......K.........",
  },
  start = {
    "..KK............",
    "..KRKK..........",
    "..KRRRKK........",
    "..KRRRRRKK......",
    "..KRRRRRRRKK....",
    "..KRRRRRRRRRKK..",
    "..KRRRRRRRRRRRK.",
    "..KrRRRRRRRRKK..",
    "..KrRRRRRRKK....",
    "..KrRRRRKK......",
    "..KrRRKK........",
    "..KrKK..........",
    "..KK............",
  },
}

local function hex(h)
  return Color { r = tonumber(h:sub(2, 3), 16), g = tonumber(h:sub(4, 5), 16), b = tonumber(h:sub(6, 7), 16), a = 255 }
end

app.fs.makeAllDirectories(OUT)
for name, rows in pairs(ICONS) do
  local img = Image(16 * SCALE, 16 * SCALE, ColorMode.RGB)
  img:clear(Color { r = 0, g = 0, b = 0, a = 0 })
  local y0 = math.floor((16 - #rows) / 2)                                -- centre short icons vertically
  for y, row in ipairs(rows) do
    for x = 1, math.min(16, #row) do
      local ch = row:sub(x, x)
      local c = PAL[ch]
      if c then
        local col = hex(c)
        for dy = 0, SCALE - 1 do for dx = 0, SCALE - 1 do
          img:drawPixel((x - 1) * SCALE + dx, (y0 + y - 1) * SCALE + dy, col)
        end end
      end
    end
  end
  img:saveAs(OUT .. name .. ".png")
  print("icon " .. name)
end
