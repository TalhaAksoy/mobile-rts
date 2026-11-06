-- Britons (medieval England / Wales, c. 1100-1450). Source brief: docs/art/culture/britons.md
-- Team colour on the surcoats / jacks and the knight's caparison; civ identity in the white shield with the red
-- St George cross, kettle hats and bascinets, the man-high yew longbow, thatched cottages, Norman keeps, grey rubble.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { stone = "#9A968C", stone_d = "#6E6A62", slate = "#4A5563", thatch = "#BFA266", daub = "#EDE6D3",
              oak = "#4B3424", gules = "#B3282D", gold = "#E2B437", white = "#F2EFE6", green = "#4E6B35",
              iron = "#8B9199", skin = "#E8B890" }
local base = { skin = PAL.skin, hair = "hair_red", beard = "short", boots = "#4A3420", legs = "#6A5A40", boot_h = 6 }
local S = {}
S.villager = merge(base, { villager = true, hat = "hood", hat_color = PAL.green, hood_lining = "#7A6040", shirt = "#8A6A44",
  sleeve = "#8A6A44", coat = "team", coat_kind = "tabard", coat_len = 6, belt = "#4A3420", weapon = "axe" })
S.swordsman = merge(base, { hat = "nasal", hat_color = PAL.iron, coif = PAL.iron, armor = PAL.iron, armor_kind = "mail",
  sleeve = PAL.iron, sleeve_kind = "mail", legs = PAL.iron, legs_pattern = "mail", coat = "team", coat_kind = "tabard",
  coat_len = 9, belt = "#4A3420", weapon = "sword", attack = "slash", shield = "heater", shield_color = PAL.white,
  shield_rim = PAL.oak, emblem = "cross", emblem_color = PAL.gules })
S.spearman = merge(base, { hat = "kettle", hat_color = PAL.iron, armor = "#D8CCB0", armor_kind = "quilt", sleeve = "#D8CCB0",
  coat = "team", coat_kind = "tabard", coat_top = 4, coat_len = 6, belt = "#4A3420", weapon = "halberd", attack = "thrust",
  shield = "small_round", shield_color = PAL.iron, shield_rim = PAL.oak, emblem = "boss" })
S.archer = merge(base, { hat = "hood", hat_color = "#7A6040", shirt = "#8A6A44", sleeve = "#8A6A44", coat = "team",
  coat_kind = "tabard", coat_len = 5, belt = "#4A3420", weapon = "bow", bow = "short", attack = "bow", quiver = "#6A5030" })
S.longbowman = merge(base, { hat = "kettle", hat_color = PAL.iron, armor = PAL.white, armor_kind = "quilt", sleeve = "team",
  coat = "team", coat_kind = "tabard", coat_top = 4, coat_len = 6, coat_emblem = "cross", coat_emblem_color = PAL.white,
  belt = "#4A3420", weapon = "bow", bow = "long", bow_color = "#A87A48", attack = "bow", quiver = "#6A5030" })
S.cavalry = merge(base, { hat = "great", hat_color = "steel", helm_band = PAL.gold, armor = PAL.iron, armor_kind = "mail",
  sleeve = PAL.iron, sleeve_kind = "mail", legs = PAL.iron, legs_pattern = "mail", coat = "team", coat_kind = "tabard",
  coat_len = 9, coat_emblem = "lions", coat_emblem_color = PAL.gold, weapon = "lance", attack = "thrust", pennant = PAL.gules,
  shield = "heater", shield_color = PAL.gules, shield_rim = PAL.gold, emblem = "lions", emblem_color = PAL.gold,
  mount = "horse", mount_color = "horse_bay", barding = "team", barding_trim = PAL.gold, barding_emblem = "lions",
  barding_emblem_color = PAL.gold })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "cross", ec = PAL.white, flag_ec = PAL.white,
  wall = "ashlar", wall_c = PAL.stone, base_c = PAL.stone_d, plaster_c = PAL.daub, timber_c = PAL.oak,
  roof = "gable", roof_mat = "slate", roof_c = PAL.slate, pitch = 0.6, house_roof = "gable", tower_top = "crenel",
  tower_round = false, tower_roof = "flat", door_c = PAL.oak, frame_c = PAL.stone_d, arch = "arch_round",
  window = "arch_round", merlon = "rect", keep_flat = true, paving_c = "#B8B2A4", castle_tower_top = "crenel",
  stable_roof = "gable", sails = 4, sail_c = PAL.daub, props = { "hay", "well", "barrel" },
  tc = "norman_keep", house = "cruck_cottage", castle = "concentric", mill = "post_mill", archery = "butts",
  stable = "thatch_stable",
}
return S
