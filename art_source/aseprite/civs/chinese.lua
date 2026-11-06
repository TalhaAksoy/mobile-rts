-- Chinese, Song to early Ming (c. 1000-1450). Source brief: docs/art/culture/chinese.md
-- Team colour on the coats under the lamellar and the padded jackets; civ identity in lamellar with long skirts,
-- red-tasselled spears, tall painted tiger-face shields, dao sabres, the box-magazine repeating crossbow,
-- red lacquer columns on stone platforms, grey tile hip-and-gable roofs with gently up-swept eaves.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { vermilion = "#B13A2B", tile = "#5E6168", brick = "#8A8F93", plaster = "#ECE6D6", earth = "#B89A6A",
              malachite = "#2F6E68", azurite = "#3A5E9A", glazed = "#4C8A4E", red = "#C8382F", black = "#3A3532",
              wood = "#7A5A3A", hemp = "#A39887", iron = "#7E8590", skin = "#E0B088" }
local base = { skin = PAL.skin, hair = PAL.black, beard = "moustache", boots = PAL.black, legs = "#4A4440", boot_h = 5 }
local soldier = merge(base, { hat = "chinese", hat_color = PAL.iron, aventail = PAL.iron, lacing = PAL.red,
  plume = PAL.red, armor = PAL.iron, armor_kind = "lamellar", armor2 = PAL.red, sleeve = "team", coat = "team",
  coat_kind = "tabard", coat_top = 12, coat_len = 10, coat_pattern = "lamellar", coat2 = PAL.iron,
  shoulders = PAL.iron, shoulders_kind = "lamellar", belt = PAL.black, buckle = "gold" })
local S = {}
S.villager = merge(base, { villager = true, hat = "straw", shirt = PAL.hemp, sleeve = PAL.hemp, coat = "team",
  coat_kind = "kaftan", coat_len = 5, belt = PAL.black, legs = PAL.hemp, weapon = "axe", hair_style = "topknot" })
S.swordsman = merge(soldier, { weapon = "dao", attack = "slash", shield = "tall", shield_color = PAL.red,
  shield_rim = PAL.black, shield_face = "tiger", shield_color2 = "#E8B83A", emblem = "none" })
S.spearman = merge(soldier, { coat_len = 4, weapon = "spear", attack = "thrust", tassel = PAL.red })
S.archer = merge(base, { hat = "cap", cap_kind = "futou", hat_color = PAL.black, shirt = "team", sleeve = "team",
  armor = "team", armor_kind = "quilt", coat = nil, belt = PAL.black, weapon = "bow", bow = "recurve", attack = "bow",
  quiver = PAL.red })
S.chu_ko_nu = merge(base, { hat = "cap", hat_color = PAL.black, shirt = "team", sleeve = "team", armor = "team",
  armor_kind = "quilt", belt = PAL.black, weapon = "crossbow", repeater = true, attack = "crossbow", quiver = PAL.wood })
S.cavalry = merge(soldier, { weapon = "lance", attack = "thrust", pennant = PAL.red, bow_case = PAL.wood,
  mount = "horse", mount_color = "horse_chestnut", blanket = PAL.red, blanket_trim = "gold", saddle = PAL.black })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "hanzi", ec = PAL.black, flag_ec = PAL.black,
  wall = "plaster", wall_c = PAL.plaster, posts_c = PAL.vermilion, base_c = PAL.brick, roof = "curved",
  roof_mat = "east", roof_c = PAL.tile, pitch = 0.4, over = 0.5, ornament = "chiwen", ornament_c = PAL.tile,
  ridge = nil, timber_c = PAL.vermilion, door_c = PAL.vermilion, frame_c = PAL.malachite, arch = "rect",
  window = "lattice", castle_wall = "ashlar", castle_wall_c = PAL.brick, merlon = "rect", keep_flat = false,
  keep_roof = "curved", tower_round = false, tower_roof = "curved", tower_top = "none", stable_roof = "curved",
  paving_c = "#C8C2B4", sail_c = PAL.hemp, mill = "watermill", props = { "lion", "bamboo", "stone_lantern" },
  kit_post = "lantern", watch = "beacon_pavilion", barracks = "bing_ying", archery = "she_pavilion", stable = "ma_peng", tc = "yamen", castle = "chenglou", house = "courtyard_house", 
}
return S
