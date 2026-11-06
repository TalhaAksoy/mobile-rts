-- Physique per civ for the 2D units: the people differ, not only their clothes. Mirrors
-- art_source/blender/units/unitstyle.py PHYSIQUE (same tones, hair colours and role picks) and follows
-- docs/art/culture/<civ>.md. Only what history supports:
--   stature  rows added (+) / removed (-) from the figure: the medieval averages (~157-172 cm) -> +-4 % = +-2 px
--   build    torso width in px (stocky steppe riders, lean desert infantry ...)
--   skins    a RANGE of tones; roles pick different ones, so an army reads as many people, never one flat tone
--   hair     colours (roles pick in turn) and the documented hair / beard customs
-- Facial features are deliberately not varied by civ (it reads as caricature in pixel art; the briefs do not ask it).
local PH = {}

local SKIN = {
  fair = "#EBC4A4", ruddy = "#E3A88A", light = "#E0AE88", olive = "#C99C72", tanned = "#B98159",
  brown = "#9C6844", warm = "#E3B68E", honey = "#CF9F70",
}

local CIV = {
  britons    = { stature = 1, build = 0, skins = { "fair", "ruddy", "light" }, hair = { "hair_brown", "hair_red", "hair_blond" } },
  franks     = { stature = 1, build = 0, skins = { "light", "fair", "ruddy" }, hair = { "hair_brown", "hair_brown", "hair_blond" },
                 hair_style = "bowl" },
  teutons    = { stature = 2, build = 1, skins = { "fair", "ruddy", "light" }, hair = { "hair_blond", "hair_brown", "hair_blond" } },
  vikings    = { stature = 2, build = 1, skins = { "fair", "ruddy", "fair" }, hair = { "hair_blond", "hair_red", "hair_brown" },
                 hair_style = "long", beard = "braided" },
  byzantines = { stature = 0, build = 0, skins = { "olive", "light", "tanned" }, hair = { "hair_black", "hair_brown", "hair_black" } },
  ottomans   = { stature = 0, build = 0, skins = { "light", "olive", "tanned" }, hair = { "hair_black", "hair_brown", "hair_black" } },
  saracens   = { stature = 0, build = -1, skins = { "tanned", "olive", "brown" }, hair = { "hair_black", "hair_black", "hair_brown" } },
  mongols    = { stature = -1, build = 1, skins = { "honey", "tanned", "warm" }, hair = { "hair_black", "hair_black", "hair_black" } },
  chinese    = { stature = -1, build = 0, skins = { "warm", "honey", "light" }, hair = { "hair_black", "hair_black", "hair_black" },
                 hair_style = "bun" },
  japanese   = { stature = -2, build = 0, skins = { "warm", "honey", "light" }, hair = { "hair_black", "hair_black", "hair_black" } },
}
PH.CIV = CIV

-- which of the civ's tones / hair colours a role gets (fixed, so a unit always looks the same)
local ROLE_PICK = { villager = 1, swordsman = 2, spearman = 3, archer = 1, cavalry = 2 }

function PH.apply(st, civ, role)
  local ph = CIV[civ]
  if not ph or st.villager_keep then return st end
  local o = {}
  for k, v in pairs(st) do o[k] = v end
  local i = ROLE_PICK[role] or 3
  o.skin = SKIN[ph.skins[(i - 1) % #ph.skins + 1]]
  if role ~= "berserker" then                      -- the berserker keeps his own (red) hair
    o.hair = ph.hair[(i - 1) % #ph.hair + 1]
    o.beard_color = nil                            -- the beard follows the hair
  end
  if ph.hair_style and not st.hair_style then o.hair_style = ph.hair_style end
  if ph.beard and o.beard and o.beard ~= "none" and o.beard ~= "moustache" and o.beard ~= "moustache_long" then o.beard = ph.beard end
  o.stature = ph.stature
  o.build_px = ph.build
  return o
end

return PH
