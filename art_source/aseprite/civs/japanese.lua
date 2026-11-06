-- Japanese, Kamakura - Sengoku (c. 1185-1570). Source brief: docs/art/culture/japanese.md
-- Team colour on the sashimono back banners, the odoshi lacing of the armour and the coats; civ identity in
-- kabuto with gilt kuwagata, menpo masks, black lacquer lamellar, jingasa, yari, the asymmetric yumi, katana,
-- white plaster and dark cedar, irimoya roofs of grey kawara tile or thick thatch, mitsudomoe mon.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { plaster = "#ECE6D6", cedar = "#3A2E26", kawara = "#5A5F66", hiwada = "#7A5A3A", thatch = "#B79A5E",
              indigo = "#2B3D66", vermilion = "#C2382B", lacquer = "#1D1A19", gilt = "#D3A63A", tannin = "#8A6E4B",
              green = "#6B7A4B", skin = "#E6B88C" }
local base = { skin = PAL.skin, hair = "hair_black", hair_style = "topknot", beard = "moustache", boots = PAL.thatch,
               legs = PAL.indigo, boot_h = 3, leg_wraps = "#E8E0CC" }
local S = {}
S.villager = merge(base, { villager = true, hat = "straw", hat_color = PAL.thatch, shirt = PAL.tannin, sleeve = PAL.tannin,
  coat = "team", coat_kind = "kaftan", coat_len = 4, belt = PAL.lacquer, weapon = "axe" })
S.swordsman = merge(base, { hat = "headband", hat_color = "#F2EEE4", armor = PAL.lacquer, armor_kind = "lamellar",
  armor2 = "team", sleeve = "team", coat = "team", coat_kind = "tabard", coat_top = 12, coat_len = 8, coat_pattern = "lamellar",
  coat2 = PAL.lacquer, belt = PAL.lacquer, weapon = "katana", attack = "slash" })
S.spearman = merge(base, { hat = "jingasa", hat_color = PAL.lacquer, hat_mon = "tomoe", hat_mon_color = PAL.gilt,
  armor = PAL.lacquer, armor_kind = "lamellar", armor2 = PAL.indigo, sleeve = PAL.indigo, coat = "team", coat_kind = "tabard",
  coat_top = 12, coat_len = 7, belt = PAL.lacquer, weapon = "yari", attack = "thrust", sashimono = "tomoe",
  sashimono_color = "white" })
S.archer = merge(base, { hat = "jingasa", hat_color = PAL.lacquer, shirt = PAL.indigo, sleeve = PAL.indigo, armor = "team",
  armor_kind = "lamellar", armor2 = PAL.lacquer, belt = PAL.lacquer, weapon = "bow", bow = "yumi", bow_color = PAL.lacquer,
  attack = "bow", quiver = PAL.lacquer, sashimono = "tomoe", sashimono_color = "white" })
S.samurai = merge(base, { hat = "kabuto", hat_color = PAL.lacquer, crest = PAL.gilt, lacing = "team", mask = PAL.lacquer,
  armor = PAL.lacquer, armor_kind = "lamellar", armor2 = "team", sleeve = PAL.lacquer, sleeve_kind = "lamellar",
  shoulders = PAL.lacquer, shoulders_kind = "lamellar", shoulders2 = "team", coat = PAL.lacquer, coat_kind = "tabard",
  coat_top = 12, coat_len = 9, coat_pattern = "lamellar", coat2 = "team", belt = PAL.vermilion, legs = "#3A3040",
  boots = PAL.lacquer, weapon = "katana", attack = "slash" })
S.cavalry = merge(S.samurai, { mask = nil, weapon = "yari", attack = "thrust", cape = "team", cape_len = 6,
  mount = "horse", mount_small = true, mount_color = "horse_dark", mane = PAL.lacquer, saddle = PAL.vermilion,
  blanket = PAL.vermilion, blanket_trim = PAL.gilt })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "tomoe", ec = "white", flag_ec = "white",
  wall = "plaster", wall_c = PAL.plaster, timber_c = PAL.cedar, facade_timber = PAL.cedar, base_c = "#8A8780",
  roof = "curved", roof_mat = "east", roof_c = PAL.kawara, pitch = 0.5, over = 0.5, ornament = "shachi",
  ornament_c = PAL.kawara, house_roof = "hip", door_c = PAL.cedar, frame_c = PAL.cedar, arch = "rect", window = "shoji",
  tower_round = false, tower_roof = "curved", tower_top = "none", merlon = false, castle_wall = "plaster",
  castle_wall_c = PAL.plaster, keep_roof = "curved", stable_roof = "curved", paving_c = "#C0B8A8", sail_c = PAL.plaster,
  props = { "stone_lantern", "bamboo", "stone_lantern" }, kit_post = "lantern",
  barracks = "nagaya", archery = "iba", stable = "umaya", smith = "katana_forge", lumber = "cedar_yard", mine = "shaft_mouth", tc = "buke_yakata", castle = "yamajiro", house = "minka", watch = "yagura", mill = "watermill",
}
return S
