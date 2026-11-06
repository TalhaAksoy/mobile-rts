-- Franks (Capetian France, c. 1180-1350). Source brief: docs/art/culture/franks.md
-- Team colour on the surcoats and caparisons; civ identity in mail with kettle hats / great helms, heater shields
-- in a greyed azure with a gold lis, the crossbowman, pale limestone Gothic, steep slate, pepper-pot cones.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { lime = "#DCCDA8", lime_d = "#A8977A", slate = "#4C5A6E", lead = "#363C48", azure = "#3E5486",
              gold = "#E1B53B", madder = "#A33B2E", linen = "#CFC2A0", oak = "#6B4A2E", iron = "#8B9199", skin = "#E6B48E" }
local base = { skin = PAL.skin, hair = "hair_brown", beard = "short", boots = "#4A3420", legs = "#6E5A44", boot_h = 6 }
local soldier = merge(base, { hat = "kettle", hat_color = PAL.iron, coif = PAL.iron, armor = PAL.iron, armor_kind = "mail",
  sleeve = PAL.iron, sleeve_kind = "mail", legs = PAL.iron, legs_pattern = "mail", coat = "team", coat_kind = "tabard",
  coat_len = 9, trim = PAL.gold, belt = "#4A3420", buckle = PAL.gold })
local S = {}
S.villager = merge(base, { villager = true, hat = "hood", hat_color = PAL.linen, hood_lining = "#B8A888", shirt = PAL.linen,
  sleeve = PAL.linen, coat = "team", coat_kind = "tabard", coat_len = 6, belt = "#4A3420", weapon = "axe" })
S.swordsman = merge(soldier, { hat = "nasal", weapon = "sword", attack = "slash", shield = "heater",
  shield_color = PAL.azure, shield_rim = PAL.gold, emblem = "fleur", emblem_color = PAL.gold })
S.spearman = merge(base, { hat = "kettle", hat_color = PAL.iron, shirt = "#E2D6BC", armor = "#E2D6BC", armor_kind = "quilt",
  sleeve = "#E2D6BC", coat = "team", coat_kind = "tabard", coat_top = 3, coat_len = 7, belt = "#4A3420", weapon = "spear",
  attack = "thrust", shield = "heater", shield_color = PAL.azure, shield_rim = PAL.oak, emblem = "fleur", emblem_color = PAL.gold })
-- crossbowman (France relied on crossbows, often Genoese mercenaries)
S.archer = merge(base, { hat = "coif_only", coif = PAL.iron, armor = "#E2D6BC", armor_kind = "quilt", sleeve = "#E2D6BC",
  coat = "team", coat_kind = "tabard", coat_top = 4, coat_len = 6, belt = "#4A3420", weapon = "crossbow", attack = "crossbow",
  quiver = PAL.oak, back_shield = "pavise", shield_color = PAL.azure, shield_rim = PAL.oak, emblem = "fleur", emblem_color = PAL.gold })
S.knight = merge(soldier, { hat = "great", hat_color = "steel", helm_band = PAL.gold, helm_crest = PAL.gold, plume = nil,
  shoulders = nil, boots = PAL.iron, gloves = PAL.iron, weapon = "lance", attack = "thrust", pennant = PAL.gold,
  shield = "heater", shield_color = PAL.azure, shield_rim = PAL.gold, emblem = "fleur", emblem_color = PAL.gold,
  mount = "horse", mount_color = "horse_dark", barding = "team", barding_trim = PAL.gold, barding_emblem = "fleur",
  barding_emblem_color = PAL.gold, saddle = PAL.madder })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "fleur", ec = PAL.gold,
  wall = "ashlar", wall_c = PAL.lime, base_c = PAL.lime_d, plaster_c = "#EDE6D4", timber_c = PAL.oak,
  roof = "hip", roof_mat = "slate", roof_c = PAL.slate, pitch = 0.75, ornament = "cross", ornament_c = PAL.gold,
  house_roof = "gable_front", tower_top = "cone", tower_c = PAL.slate, tower_mat = "slate", tower_round = true,
  finial = "cross", door_c = PAL.oak, frame_c = PAL.lime_d, arch = "arch_pointed", window = "arch_pointed",
  shutters = nil, merlon = "rect", paving_c = "#D2C6AA", castle_tower_top = "cone", keep_roof = "hip",
  sails = 4, sail_c = PAL.linen, props = { "well", "barrel", "cart" },
  watch = "pepperpot_tower",
  tc = "cite_palace", castle = "philippe_castle", house = "timber_townhouse", mill = "post_mill",
}
return S
