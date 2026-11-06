-- Mongols, c. 1200-1370. Source brief: docs/art/culture/mongols.md
-- Team colour on the deel robes / lamellar coats; civ identity in shaved crowns with braided loops, fur-brimmed
-- hats, iron bowl helmets with horsehair plume, hooked spears, wicker shields, dun ponies, white felt gers with
-- orange doors, black horsetail tug standards (no heraldry).
local merge = function(a, b) local o = {} for k, v in pairs(a) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end
local PAL = { felt = "#EDE4CF", felt2 = "#B9A47E", orange = "#C35A2A", sky = "#2E5FA3", lacquer = "#9B2B25",
              black = "#2B2622", rawhide = "#8A6A44", gold = "#C59B3A", deel = "#7B5A3A", dun = "#C49A5E",
              iron = "#8C9094", skin = "#C8925E" }
local base = { skin = PAL.skin, hair = "hair_black", hair_style = "mongol", beard = "moustache", boots = "#5A3A24",
               legs = "#5A4430", boot_h = 7, boots_cuff = PAL.rawhide }
local soldier = merge(base, { hat = "conical", hat_color = PAL.iron, hat_rim = PAL.rawhide, rim_kind = "leather",
  aventail = PAL.rawhide, aventail_kind = "leather", plume = "#B02A20", armor = PAL.lacquer, armor_kind = "lamellar",
  armor2 = PAL.rawhide, sleeve = "team", coat = "team", coat_kind = "kaftan", coat_top = 10, coat_len = 9, sash = PAL.sky,
  shoulders = PAL.lacquer, shoulders_kind = "lamellar" })
local S = {}
S.villager = merge(base, { villager = true, hat = "mongol_hat", hat_color = PAL.felt2, hat_rim = "fur", hat_knob = PAL.orange,
  shirt = PAL.deel, sleeve = "team", coat = "team", coat_kind = "kaftan", coat_len = 11, sash = PAL.sky, weapon = "axe" })
S.swordsman = merge(soldier, { weapon = "scimitar", attack = "slash", shield = "small_round", shield_color = "#B89A5E",
  shield_pattern = "quilt", shield_rim = PAL.rawhide, emblem = "boss" })
S.spearman = merge(soldier, { armor = PAL.rawhide, armor_kind = "quilt", weapon = "spear", spear_hook = true,
  attack = "thrust", tassel = PAL.black })
S.archer = merge(base, { hat = "fur", hat_color = "fur", hat_cap = PAL.sky, hat_knob = PAL.orange, shirt = PAL.deel,
  sleeve = "team", coat = "team", coat_kind = "kaftan", coat_len = 10, sash = PAL.orange, weapon = "bow", bow = "recurve",
  attack = "bow", quiver = PAL.lacquer, bow_case = PAL.rawhide })
S.horse_archer = merge(soldier, { shoulders = nil, armor = PAL.rawhide, armor_kind = "lamellar", weapon = "bow",
  bow = "recurve", attack = "bow", quiver = PAL.lacquer, bow_case = PAL.rawhide, mount = "horse", mount_small = true,
  mount_color = PAL.dun, mane = PAL.black, blanket = PAL.sky, blanket_trim = PAL.orange, saddle = PAL.orange })
S._palette = PAL
S._buildings = {
  palette = PAL, emblem = "tug", ec = PAL.black, flag_ec = "white", felt_c = PAL.felt, rope_c = PAL.felt2,
  door_c = PAL.orange, wall = "rammed", wall_c = "#B89A6E", roof = "gable", roof_mat = "east", roof_c = "#6A6E74",
  timber_c = "#6A4A2E", frame_c = PAL.orange, arch = "rect", window = "rect", tower_top = "none",
  kit_fence = true, kit_post = "tug", sail_c = PAL.felt, props = { "cart", "hitching" },
  tc = "ordo", house = "ger_house", barracks = "ger_camp", archery = "steppe_range", stable = "horse_line",
  castle = "karakorum", watch = "timber_lookout", smith = "ger_smith", lumber = "ger_lumber", mine = "ger_mine",
  mill = "ger_quern", market = "caravan",
}
return S
