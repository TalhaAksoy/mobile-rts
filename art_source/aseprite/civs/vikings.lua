-- Vikings (Norse, c. 800-1100). Source brief: docs/art/culture/vikings.md
-- Team colour on the painted round shields (halves with the Gokstad yellow / black kept as the civ accent on the
-- villagers' and archers' side) and the tunics; civ identity in spectacle-guard helmets, mail byrnies, wolf-pelt
-- berserkers with Dane axes, bow-sided timber longhouses with turf and shingle roofs, crossed gable ends,
-- the Trelleborg ring fort, rune stones, the raven banner. No horned helmets, no stone castles.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { tar = "#3B2B1E", weathered = "#7A6650", turf = "#5D6B39", sod = "#6B5236", thatch = "#B89B5E",
              woad = "#3C5A7A", madder = "#9B3A2A", weld = "#D2B048", black = "#1E1C1A", wool = "#8C7F6A",
              iron = "#6E7277", skin = "#EAC0A0" }
local base = { skin = PAL.skin, hair = "hair_blond", hair_style = "long", beard = "full", boots = "#4A3420", legs = PAL.wool,
               boot_h = 5, leg_wraps = "#6A5A44" }
local S = {}
S.villager = merge(base, { villager = true, hat = "cap", hat_color = PAL.wool, shirt = PAL.wool, sleeve = PAL.wool,
  coat = "team", coat_kind = "tabard", coat_len = 5, trim = PAL.weld, belt = "#4A3420", weapon = "axe" })
S.swordsman = merge(base, { hat = "spangen", hat_color = PAL.iron, helm_band = "#8A7A5A", spectacle = true, armor = PAL.iron,
  armor_kind = "mail", sleeve = PAL.iron, sleeve_kind = "mail", coat = "team", coat_kind = "tabard", coat_top = 12, coat_len = 6,
  belt = "#4A3420", buckle = "bronze", weapon = "sword", attack = "slash", shield = "round", shield_color = "team",
  shield_pattern = "halves", shield_color2 = PAL.weld, shield_rim = PAL.tar, emblem = "boss", boss = PAL.iron })
S.spearman = merge(base, { hat = "nasal", hat_color = PAL.iron, shirt = PAL.woad, armor = "#8A7A5A", armor_kind = "quilt",
  sleeve = PAL.woad, coat = "team", coat_kind = "tabard", coat_top = 3, coat_len = 6, belt = "#4A3420", weapon = "spear",
  attack = "thrust", shield = "round", shield_color = "team", shield_pattern = "quarters", shield_color2 = PAL.black,
  shield_rim = PAL.tar, emblem = "boss", boss = PAL.iron })
S.archer = merge(base, { hat = "hood", hat_color = PAL.wool, shirt = PAL.wool, sleeve = PAL.wool, coat = "team",
  coat_kind = "tabard", coat_len = 5, belt = "#4A3420", weapon = "bow", bow = "long", bow_color = "#8A6A44", attack = "bow",
  quiver = PAL.sod })
S.berserker = merge(base, { hat = "fur", hat_color = "#6E6458", wolf = true, hair = "hair_red", beard_color = "hair_red",
  shirt = "team", sleeve = PAL.skin, coat = nil, armor = "team", armor_kind = "cloth", belt = PAL.black, buckle = "bronze",
  bracers = "#4A3420", weapon = "dane_axe", attack = "slash" })
S.cavalry = merge(S.spearman, { mount = "horse", mount_small = true, mount_color = PAL.weld, mane = PAL.black,
  blanket = PAL.madder, blanket_trim = PAL.weld, saddle = "#4A3420" })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "raven", ec = PAL.black, flag_ec = PAL.black,
  wall = "stave", wall_c = PAL.tar, base_c = "#7A7A72", timber_c = PAL.tar, roof = "gable", roof_mat = "shingle",
  roof_c = PAL.weathered, pitch = 0.95, over = 0.35, crossed_ends = PAL.tar, house_roof = "gable", ridge = nil,
  door_c = "#5A4030", frame_c = PAL.tar, arch = "rect", window = "rect", tower_top = "none", tower_round = false,
  tower_roof = "gable", merlon = false, castle_wall = "planks", castle_wall_c = PAL.tar, paving_c = nil,
  kit_fence = true, kit_post = "runestone", stable_roof = "gable", sail_c = PAL.wool, props = { "runestone", "barrel" },
  barracks = "trelleborg_hall", archery = "hide_targets", stable = "byre", tc = "great_hall", castle = "trelleborg", house = "turf_house", watch = "horn_tower", mill = "norse_mill",
}
return S
