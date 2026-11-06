-- Saracens (Ayyubid / Mamluk Egypt-Syria, c. 1170-1500). Source brief: docs/art/culture/saracens.md
-- Team colour on the qaba coats (the big surface) and banners; civ identity in turbans over red kalawta caps,
-- quilted kazaghand mail, small round shields, ablaq striped stone, carved domes, stepped crenellations.
-- The game keeps the mamluk on a camel (historically they rode horses; camels were for Bedouin auxiliaries).
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { lime = "#DCC79E", ablaq = "#B04A32", basalt = "#2B2A2A", marble = "#F4EEDF", mud = "#9C7A50",
              wood = "#6A4428", yellow = "#D6A62B", madder = "#A82A2A", cotton = "#E9E3D3", indigo = "#2A5E8C",
              brass = "#C8963E", steel = "#8B9196", skin = "#C68A60" }
local base = { skin = PAL.skin, hair = "hair_black", beard = "full", boots = "#5A3A24", legs = PAL.cotton, boot_h = 4 }
local soldier = merge(base, { hat = "turban", hat_color = PAL.cotton, turban_helmet = PAL.steel, coat = "team",
  coat_kind = "kaftan", coat_len = 8, coat_pattern = "quilt", trim = PAL.brass, sash = PAL.yellow, legs = "#C8B898",
  armor = PAL.steel, armor_kind = "mail", coat_top = 4 })
local S = {}
S.villager = merge(base, { villager = true, hat = "turban", hat_color = PAL.cotton, shirt = PAL.cotton, sleeve = PAL.cotton,
  coat = "team", coat_kind = "kaftan", coat_len = 12, sash = PAL.indigo, weapon = "axe", boots = "#9C7A50" })
S.swordsman = merge(soldier, { weapon = "scimitar", attack = "slash", shield = "small_round", shield_color = PAL.madder,
  shield_rim = PAL.brass, emblem = "boss", boss = PAL.brass })
S.spearman = merge(soldier, { turban_helmet = nil, hat = "turban", coat_pattern = "cloth", armor = "#8a6a44", armor_kind = "leather",
  weapon = "spear", attack = "thrust", shield = "round", shield_color = PAL.wood, shield_rim = PAL.brass, emblem = "boss" })
S.archer = merge(base, { hat = "turban", hat_color = PAL.cotton, shirt = PAL.cotton, sleeve = PAL.cotton, coat = "team",
  coat_kind = "kaftan", coat_len = 7, sash = PAL.yellow, weapon = "bow", bow = "recurve", attack = "bow",
  quiver = PAL.madder, bow_case = PAL.wood })
-- mamluk: red kalawta cap with a white turban wound round it, mail under a coloured qaba, lance, camel
S.mamluk = merge(soldier, { hat = "mamluk", hat_cap = PAL.madder, hat_color = PAL.cotton, shoulders = PAL.steel,
  shoulders_kind = "lamellar", bracers = PAL.steel, weapon = "lance", attack = "thrust", pennant = PAL.yellow,
  shield = "small_round", shield_color = PAL.yellow, shield_rim = PAL.brass, emblem = "cup", emblem_color = PAL.madder,
  bow_case = PAL.wood, mount = "camel", blanket = PAL.madder, blanket_pattern = "stripes", blanket2 = PAL.yellow,
  blanket_trim = PAL.brass, saddle = PAL.wood })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "cup", ec = PAL.madder, flag_ec = PAL.madder,
  wall = "ashlar", wall_c = PAL.lime, ablaq_c = PAL.ablaq, plaster_c = PAL.marble, roof = "flat", top_c = "#CDB88E",
  merlon = "stepped", dome_c = PAL.lime, finial = "crescent", tower_top = "dome", tower_c = PAL.lime,
  timber_c = PAL.wood, door_c = PAL.wood, frame_c = PAL.lime, arch = "arch_pointed", window = "lattice",
  muqarnas_c = PAL.lime, base_c = "#C4AE84", ground = "sand", paving_c = "#E2D2AE", castle_wall = "ashlar",
  castle_wall_c = PAL.lime, keep_flat = true, castle_tower_top = "crenel", tower_round = false, sail_c = PAL.cotton,
  props = { "palm", "jar", "palm", "well" }, kit_cap = "dome",
  watch = "stepped_tower",
  barracks = "tibaq", stable = "istabl", tc = "madrasa", castle = "citadel", house = "malqaf_house", mill = "noria", archery = "maydan",
}
return S
