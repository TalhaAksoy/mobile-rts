-- Byzantines, c. 950-1200. Source brief: docs/art/culture/byzantines.md
-- Team colour on the kavadion coats, the big kite shields' field (white border + cross kept) and the
-- cataphract's felt barding; civ identity in banded brick, round arches, domes on drums, purple / gold trim.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { stone = "#D9CDB4", brick = "#A85A3C", mortar = "#C9B9A0", tile = "#B05A3A", lead = "#7E8A93",
              purple = "#6A2C5E", madder = "#A7262B", woad = "#2F4E8C", linen = "#E8DFC8", gold = "#C8A23E",
              iron = "#8E949A", leather = "#5B4632", skin = "#D8A47C" }
local base = { skin = PAL.skin, hair = "hair_black", beard = "full", boots = PAL.leather, legs = "#6E6658", boot_h = 6 }
local soldier = merge(base, { hat = "conical", hat_color = PAL.iron, aventail = PAL.iron, aventail_kind = "mail",
  armor = PAL.iron, armor_kind = "lamellar", armor2 = PAL.leather, sleeve = "team", coat = "team", coat_kind = "tabard",
  coat_top = 10, coat_len = 8, trim = PAL.gold, belt = PAL.leather, buckle = PAL.gold })
local S = {}
S.villager = merge(base, { villager = true, hat = "cap", hat_color = "#8a6a4a", shirt = PAL.linen, sleeve = PAL.linen,
  coat = "team", coat_kind = "tabard", coat_len = 7, trim = PAL.linen, belt = PAL.leather, legs = "#7a6a52", weapon = "axe" })
S.swordsman = merge(soldier, { weapon = "sword", attack = "slash", shield = "kite", shield_color = "team",
  shield_rim = "white", emblem = "cross", emblem_color = "white" })
S.spearman = merge(soldier, { weapon = "spear", attack = "thrust", shield = "round", shield_color = "team",
  shield_rim = "white", emblem = "chirho", emblem_color = PAL.gold })
-- toxotes: padded kavadion, phakeolion turban-wrap, composite bow, big quiver, no shield
S.archer = merge(base, { hat = "turban", hat_color = "#C8B898", shirt = "team", sleeve = "team", armor = "team",
  armor_kind = "quilt", coat = nil, belt = PAL.leather, weapon = "bow", bow = "recurve", attack = "bow",
  quiver = PAL.leather, legs = "#6E6658" })
-- cataphract: mail face-veil (faceless), lamellar klibanion with skirt, lance, felt barding to the knees
S.cataphract = merge(soldier, { hat = "byz", hat_color = PAL.iron, helm_band = PAL.gold, mail_veil = PAL.iron,
  aventail = PAL.iron, shoulders = PAL.iron, shoulders_kind = "lamellar", bracers = PAL.iron, weapon = "lance",
  attack = "thrust", pennant = PAL.purple, shield = "small_round", shield_color = PAL.madder, shield_rim = PAL.gold,
  emblem = "cross", mount = "horse", mount_color = "horse_dark", barding = "team", barding_pattern = "quilt",
  barding_trim = PAL.gold, barding_emblem = "cross", barding_emblem_color = PAL.gold, chanfron = PAL.iron })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "chirho", ec = PAL.gold,
  wall = "brick_banded", wall_c = PAL.brick, band_c = PAL.stone, mortar_c = PAL.mortar, plaster_c = "#E6DCC6",
  roof = "gable", roof_mat = "tiles", roof_c = PAL.tile, pitch = 0.3, dome_c = PAL.lead, finial = "cross",
  tower_top = "crenel", tower_c = PAL.tile, timber_c = "#6A4A2E", door_c = "#5A3A24", frame_c = PAL.stone,
  arch = "arch_round", window = "arch_round", merlon = "rect", base_c = PAL.stone, paving_c = PAL.stone,
  castle_wall = "brick_banded", castle_wall_c = PAL.brick, castle_tower_top = "crenel", keep_flat = true,
  sails = 4, sail_c = PAL.linen, mill_roof_c = PAL.tile, mill_roof_mat = "tiles", props = { "jar", "well", "cart" },
  tc = "byz_church", castle = "theodosian", mill = "watermill", house = "byz_house", watch = "beacon_tower",
}
return S
