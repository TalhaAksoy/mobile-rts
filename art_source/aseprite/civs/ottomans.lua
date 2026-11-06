-- Ottomans, c. 1400-1550 (Bursa / Edirne / early Istanbul). Source brief: docs/art/culture/ottomans.md
-- Team colour sits on the kaftans / dolama coats (the big readable surface); civ identity is in the turbans,
-- the janissary börk, round kalkan shields, curved kılıç and the grey lead domes of the buildings.
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end

local PAL = {
  limestone = "#E3D7BF", brick = "#A4553A", plaster = "#F1EDE3", lead = "#7D8790", tile = "#B4654A",
  timber = "#6B4A2E", cobalt = "#1F4FA0", turquoise = "#3BA6A4", crimson = "#B3202A", jan_blue = "#2D4C8C",
  green = "#3D6B3A", brass = "#C9A44A", undyed = "#CDBF9A", brown = "#7A5233", skin = "#D9A27A",
}

local base = { skin = PAL.skin, hair = "hair_black", hair_style = "short", beard = "full", boots = "#5A3A24",
               legs = "#E0D8C8", boot_h = 5 }
local soldier = merge(base, { hat = "turban", hat_color = "white", coat = "team", coat_kind = "kaftan", coat_len = 9,
                              trim = PAL.brass, collar = true, sash = PAL.green, legs = "#C8BCA0", boots = "#3E2A1C" })

local S = {}
S.villager = merge(base, { villager = true, hat = "turban", hat_color = "#EEE8DA", shirt = PAL.undyed, sleeve = PAL.undyed,
                           coat = "team", coat_kind = "kaftan", coat_len = 8, coat_top = 3, sash = PAL.brown,
                           legs = PAL.undyed, weapon = "axe" })
-- azab / levend: turban over the çiçak helmet, mail over the kaftan, round kalkan, kılıç
S.swordsman = merge(soldier, { hat = "turban", turban_helmet = "steel", armor = "iron", armor_kind = "mail",
                               sleeve = "iron", sleeve_kind = "mail", coat_top = 8, weapon = "scimitar",
                               attack = "slash", shield = "round", shield_color = PAL.crimson, shield_rim = PAL.brass,
                               shield_pattern = "brocade", shield_color2 = PAL.brass, emblem = "boss", boss = PAL.brass })
S.spearman = merge(soldier, { coat = "team", coat_pattern = "cloth", armor = nil, shirt = "#B8A67E", sleeve = "#B8A67E",
                              weapon = "spear", attack = "thrust", tassel = PAL.crimson, shield = "small_round",
                              shield_color = PAL.brass, shield_rim = "#5A3A24", emblem = "boss" })
S.archer = merge(soldier, { coat_len = 6, sleeve = "#E8E0CC", shirt = "#E8E0CC", weapon = "bow", bow = "recurve",
                            bow_color = "#5A3A24", attack = "bow", quiver = PAL.crimson, bow_case = "#7A5233",
                            bracers = "#7A5233" })
-- janissary: tall white börk with the back flap and brass spoon holder, moustache only, blue dolama (team),
-- matchlock tüfek; no armour, no shield
S.janissary = merge(base, { hat = "bork", hat_color = "#F3EFE6", hat_band = PAL.brass, beard = "moustache_long",
                            shirt = "#E8E0CC", sleeve = "team", coat = "team", coat_kind = "kaftan", coat_len = 9,
                            coat_open = true, trim = PAL.brass, sash = PAL.crimson, legs = "#E0D8C8", boots = "#7A2A20",
                            weapon = "musket", attack = "gun", match_cord = true })
-- sipahi: turban round a pointed helmet, mail with plates, crimson kaftan (team), kalkan, lance with pennon,
-- lean Turkoman horse with a colourful saddle cloth and brass-fitted bridle, no barding
S.cavalry = merge(soldier, { turban_helmet = "steel", armor = "iron", armor_kind = "mail", sleeve = "iron",
                             sleeve_kind = "mail", bracers = "steel", weapon = "lance", attack = "thrust",
                             pennant = PAL.crimson, shield = "round", shield_color = PAL.crimson, shield_rim = PAL.brass,
                             shield_pattern = "brocade", shield_color2 = PAL.brass, emblem = "boss", boss = PAL.brass,
                             mount = "horse", mount_color = "horse_chestnut", blanket = PAL.cobalt,
                             blanket_pattern = "brocade", blanket2 = PAL.brass, blanket_trim = PAL.brass, saddle = PAL.crimson })

S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "crescent", ec = "white", banner_field = "team",
  wall = "ashlar_banded", wall_c = PAL.limestone, band_c = PAL.brick, plaster_c = PAL.plaster,
  roof = "hip", roof_mat = "tiles", roof_c = PAL.tile, roof_low = true,
  dome_c = PAL.lead, finial = "crescent", tile_c = PAL.cobalt, tile2_c = PAL.turquoise,
  tower_top = "cone_lead", tower_c = PAL.lead, timber_c = PAL.timber, door_c = PAL.timber,
  arch = "arch_pointed", window = "lattice", muqarnas_c = PAL.limestone, frame_c = "#8a7a62", sail_c = "#F1EDE3",
  props = { "cypress", "carpet", "copper_pot", "tug" }, base_c = "#B8AC94", paving_c = "#D8CCB4", merlon = "rect",
  stable = "ottoman_stable", smith = "ottoman_smithy", lumber = "ottoman_lumber", mine = "ottoman_mine", tc = "kulliye", house = "konak", castle = "rumelihisari", mill = "aegean_windmill", watch = "square_gallery",
  barracks = "oda", archery = "nisan_tasi", market = "bedesten",
}
return S
