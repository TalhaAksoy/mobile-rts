-- Teutons (Holy Roman Empire / Teutonic Order, c. 1230-1450). Source brief: docs/art/culture/teutons.md
-- Red-brick Brick Gothic (Malbork): dark-glazed diaper patterns, stepped gables with white blind niches, red tile.
-- (This replaces the older "grey stone / black slate" direction, following the research.)
-- Team colour on surcoats / brigandines; the teutonic knight keeps the Order's white with the black cross and
-- carries the team colour on his crest and sash instead.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { brick = "#9E3F27", brick_d = "#6E2A1C", glazed = "#3B2A26", white = "#E8E1D2", tile = "#B4472F",
              granite = "#8A8F93", black = "#1C1C1E", gold = "#E0B43A", grey = "#9A9488", oak = "#5A4030",
              green = "#7E8B5A", skin = "#E8B890" }
local base = { skin = PAL.skin, hair = "hair_blond", beard = "full", boots = "#3E2A1C", legs = "#5A5048", boot_h = 6 }
local S = {}
S.villager = merge(base, { villager = true, hat = "hood", hat_color = PAL.green, hood_lining = PAL.grey, shirt = "#7A6A50",
  sleeve = "#7A6A50", coat = "team", coat_kind = "tabard", coat_len = 6, belt = "#3E2A1C", weapon = "axe" })
S.swordsman = merge(base, { hat = "kettle", hat_color = PAL.granite, coif = PAL.granite, armor = PAL.granite, armor_kind = "mail",
  sleeve = PAL.granite, sleeve_kind = "mail", coat = "team", coat_kind = "tabard", coat_len = 8, trim = PAL.gold,
  belt = "#3E2A1C", weapon = "messer", attack = "slash", shield = "heater", shield_color = PAL.gold, shield_rim = PAL.black,
  emblem = "eagle", emblem_color = PAL.black })
S.spearman = merge(base, { hat = "kettle", hat_color = PAL.granite, armor = "team", armor_kind = "brocade", armor2 = PAL.granite,
  sleeve = PAL.granite, sleeve_kind = "mail", belt = "#3E2A1C", weapon = "halberd", attack = "thrust" })
S.archer = merge(base, { hat = "hood", hat_color = PAL.grey, armor = PAL.grey, armor_kind = "quilt", sleeve = PAL.grey,
  coat = "team", coat_kind = "tabard", coat_top = 4, coat_len = 6, coat_emblem = "cross", coat_emblem_color = PAL.black,
  belt = "#3E2A1C", weapon = "crossbow", attack = "crossbow", quiver = PAL.oak })
S.teutonic_knight = merge(base, { hat = "great", hat_color = "steel", helm_crest = "team", armor = PAL.granite, armor_kind = "mail",
  sleeve = PAL.granite, sleeve_kind = "mail", legs = PAL.granite, legs_pattern = "mail", boots = "steel", gloves = "steel",
  shoulders = "steel", coat = PAL.white, coat_kind = "tabard", coat_len = 11, coat_emblem = "cross_pattee",
  coat_emblem_color = PAL.black, sash = "team", weapon = "sword", blade_len = 23, attack = "slash", shield = "heater",
  shield_color = PAL.white, shield_rim = PAL.black, emblem = "cross", emblem_color = PAL.black })
S.cavalry = merge(S.teutonic_knight, { blade_len = nil, weapon = "lance", attack = "thrust", pennant = PAL.white,
  mount = "horse", mount_color = "horse_grey", barding = "team", barding_trim = PAL.white, barding_emblem = "cross_pattee",
  barding_emblem_color = PAL.black, chanfron = "steel" })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "cross_pattee", ec = PAL.black, flag_ec = PAL.black,
  wall = "brick", wall_c = PAL.brick, glazed_c = PAL.glazed, mortar_c = "#C8B49A", base_c = PAL.granite,
  plaster_c = PAL.white, timber_c = PAL.oak, roof = "gable", roof_mat = "tiles", roof_c = PAL.tile, pitch = 0.8,
  house_roof = "gable_front", blind_c = PAL.white, steps = 5, tower_top = "crenel", tower_round = false,
  tower_roof = "hip", door_c = PAL.oak, frame_c = PAL.brick_d, arch = "arch_pointed", window = "arch_pointed",
  merlon = "rect", keep_roof = "stepped", paving_c = "#B8A890", castle_wall = "brick", castle_wall_c = PAL.brick,
  castle_tower_top = "crenel", sails = 4, sail_c = PAL.white, props = { "barrel", "cart", "sacks" },
  watch = "brick_tower",
  barracks = "brick_dormitory", archery = "brick_yard", stable = "loft_stable", smith = "brick_smithy", lumber = "fachwerk_shed", mine = "treadwheel_mine", tc = "ordensburg", castle = "malbork", house = "fachwerk", mill = "watermill",
}
return S
