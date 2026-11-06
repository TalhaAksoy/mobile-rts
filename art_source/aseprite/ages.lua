-- Age looks (Köy / Hisar / İmparatorluk). Age II is the base design in civs/<civ>.lua; this file derives
--   Age I  : the village-age kit: no metal armour, cloth caps / hoods / turbans, plain shields, unarmoured horses;
--            buildings use the civ's vernacular materials (mud brick, wattle and daub, rammed earth, thatch, turf)
--            on the civ's own layouts (only the materials and the merlons / tower tops change).
--   Age III: the imperial-age kit: the civ's heaviest historical armour and helmet, plumes / crests, capes, decorated
--            shields, armoured horses; buildings keep the landmarks and get paved yards and extra standards.
-- Generic rules first, then per-civ (and per-role) overrides for authenticity (docs/art/culture/<civ>.md).
local AG = {}

local function copy(t) local o = {} for k, v in pairs(t) do o[k] = v end return o end
local function apply(o, t) if t then for k, v in pairs(t) do if v == AG.NIL then o[k] = nil else o[k] = v end end end return o end
AG.NIL = {}                                                         -- marker: clear the field
local N = AG.NIL

local METAL_KINDS = { mail = true, lamellar = true, scale = true, plate = true }
local HELMETS = { nasal = true, spangen = true, kettle = true, great = true, kabuto = true, conical = true, byz = true,
                  chinese = true, coif_only = true }
local GOLD = "#D8A83A"
local EURO_HORSE = { franks = true, britons = true, teutons = true, byzantines = true }

---------------------------------------------------------------------------------------------- units
-- per civ: [1] / [3] = { all = {...}, <role> = {...} } applied after the generic rule
local UNIT = {
  ottomans = {
    -- Age I: azab / akıncı irregulars: red felt caps, plain coats, no mail; Age III: kapıkulu / sipahi heavy kit
    [1] = { all = { hat = "cap", hat_color = "#A8282A", turban_helmet = N, trim = N, collar = N },
            cavalry = { hat = "fur", hat_color = "#6A4A2E", weapon = "spear", pennant = N, blanket = "#7A5233" },
            janissary = { hat = "bork", hat_color = "#F3EFE6" } },
    [3] = { all = { turban_helmet = "steel", plume = "#F3EFE6", hat_band = GOLD, cape = N, coat_pattern = "brocade",
                    coat2 = GOLD },
            -- Age III devices: crimson kalkan with the white crescent
            swordsman = { armor = "iron", armor_kind = "scale", shoulders = "iron", shoulders_kind = "plate",
                          shield_color = "#B3202A", emblem = "crescent", emblem_color = "#F3EFE6", shield_pattern = N },
            spearman = { armor = "iron", armor_kind = "mail", shield_color = "#B3202A", emblem = "crescent",
                         emblem_color = "#F3EFE6", shield_pattern = N },
            archer = { armor = "#7A5233", armor_kind = "quilt" },
            janissary = { hat = "bork", turban_helmet = N, plume = "#F3EFE6", trim = GOLD },
            cavalry = { armor_kind = "scale", barding = N, chanfron = "steel", blanket2 = GOLD } },
  },
  byzantines = {
    [1] = { all = { hat = "cap", cap_kind = "phrygian", hat_color = "#8A2A3A" } },
    -- Age III: klibanophoroi: gilded lamellar laced in imperial purple, purple cloaks, chi-rho on red shields
    [3] = { all = { hat = "byz", hat_color = "steel", plume = "#6E2A6A", armor = "steel", armor_kind = "lamellar",
                    lacing = "#6E2A6A", cape = "#6E2A6A", trim = GOLD, shield_color = "#A7262B", emblem = "chirho",
                    emblem_color = GOLD, shield_pattern = N, shield_rim = GOLD } },
  },
  saracens = {
    [1] = { all = { hat = "turban", turban_helmet = N } },
    -- Age III: Mamluk khassakiya: steel helmet in the turban, lamellar, sultanic-yellow sash, brass-bossed shields
    [3] = { all = { turban_helmet = "steel", aventail = "iron", aventail_kind = "mail", armor = "steel",
                    armor_kind = "lamellar", trim = GOLD, cape = N, sash = "#D6A62B", hat_band = "#D6A62B",
                    shield_color = "#D6A62B", emblem = "band", emblem_color = "#2a2234", shield_pattern = N, boss = N } },
  },
  mongols = {
    [1] = { all = { hat = "fur", hat_color = "#7A5A3A" } },
    -- Age III: keshig guard: lacquered leather lamellar laced red, conical helmet with a red tassel, no cloaks
    [3] = { all = { hat = "conical", hat_color = "steel", plume = "#B8262A", aventail = "#5A4A3A", aventail_kind = "lamellar",
                    armor = "#2E2624", armor_kind = "lamellar", lacing = "#B8262A", cape = N, sash = "#B8262A",
                    -- black-lacquered lamellar with lamellar pauldrons over a nasij (cloth-of-gold) silk robe
                    shoulders = "#2E2624", shoulders_kind = "lamellar", shoulders2 = "#B8262A", coat_pattern = "brocade",
                    coat2 = GOLD },
            cavalry = { barding = "#4A3A30", barding_pattern = "lamellar", barding_trim = "#B8262A" },
            horse_archer = { barding = "#4A3A30", barding_pattern = "lamellar", barding_trim = "#B8262A" } },
  },
  chinese = {
    [1] = { all = { hat = "headband", hat_color = "#B8262A" } },
    -- Age III: Song heavy infantry: mountain-pattern scale, red-tasselled helmet, red sash, tiger-face shields
    [3] = { all = { hat = "chinese", hat_color = "steel", plume = "#B8262A", armor = "steel", armor_kind = "scale",
                    trim = GOLD, cape = "#C8382F", sash = "#C8382F", shield_face = "tiger", shield_color2 = "#E8B83A",
                    -- scale pauldrons, the round chest mirror (huxinjing) in polished bronze, a red war cloak (pifeng)
                    shoulders = "steel", shoulders_kind = "scale", coat_emblem = "sun", coat_emblem_color = "#E3B341" },
            archer = { cape = N } } ,
  },
  franks = {
    [1] = { all = { hat = "hood", hat_color = "#7A6A4A", armor = "#E2D6BC", armor_kind = "quilt" } },
    -- Age III: royal knights: great helm, fleur-de-lis on the surcoat and the azure shield
    [3] = { all = { hat = "great", hat_color = "steel", helm_crest = GOLD, armor = "steel", armor_kind = "plate",
                    sleeve = "steel", sleeve_kind = "plate", gloves = "steel", cape = N, coat_emblem = "fleur",
                    coat_emblem_color = GOLD, shield_color = "#3E5486", emblem = "fleur", emblem_color = GOLD,
                    shield_pattern = N, shield_rim = GOLD },
            archer = { hat = "kettle", armor = "steel", armor_kind = "mail", sleeve = "#E2D6BC", sleeve_kind = N, gloves = N } },
  },
  britons = {
    [1] = { all = { hat = "hood", hat_color = "#5A6A3A", armor = "#D8CCAA", armor_kind = "quilt" } },
    -- Age III: royal livery: the gold lions on the surcoat and on gules shields
    [3] = { all = { hat = "kettle", hat_color = "steel", plume = "team", armor = "steel", armor_kind = "plate",
                    sleeve = "steel", sleeve_kind = "plate", cape = N, coat_emblem = "lions", coat_emblem_color = GOLD,
                    shield_color = "#B3282D", emblem = "lions", emblem_color = GOLD, shield_pattern = N },
            archer = { armor = "#6A4A2A", armor_kind = "quilt", sleeve = "#D8CCAA", sleeve_kind = N, plume = N },
            longbowman = { armor = "#6A4A2A", armor_kind = "quilt", sleeve = "#D8CCAA", sleeve_kind = N, plume = N } },
  },
  teutons = {
    [1] = { all = { hat = "hood", hat_color = "#6A6A6A", armor = "#D8D0BC", armor_kind = "quilt" } },
    -- Age III: the Order's brethren: white mantle and surcoat with the black cross, team sash
    [3] = { all = { hat = "great", hat_color = "steel", helm_crest = "#F0EEE8", armor = "steel", armor_kind = "plate",
                    sleeve = "steel", sleeve_kind = "plate", gloves = "steel", cape = "#F0EEE8", coat = "#F0EEE8",
                    coat_kind = "tabard", coat_emblem = "cross_pattee", coat_emblem_color = "#1D1A19", sash = "team",
                    shield_color = "#F0EEE8", emblem = "cross", emblem_color = "#1D1A19", shield_pattern = N },
            archer = { hat = "kettle", armor = "steel", armor_kind = "mail", sleeve = "#D8D0BC", sleeve_kind = N, gloves = N,
                       cape = N, helm_crest = N } },
  },
  japanese = {
    [1] = { all = { hat = "straw", hat_color = "#C8A860", armor = N, coat_pattern = N, shoulders = N, mask = N } },
    [3] = { all = { hat = "kabuto", hat_color = "#1D1A19", crest = "#D3A63A", shoulders = "#1D1A19",
                    shoulders_kind = "lamellar", shoulders2 = "team", lacing = "team", mask = "#1D1A19",
                    sashimono = "tomoe", sashimono_color = "#F0EEE8" } },                  -- every warrior carries the clan mon
  },
  vikings = {
    [1] = { all = { hat = "none", armor = N, armor_kind = N } },
    -- Age III: hirdmen: spectacle helmets, mail, raven-painted shields
    [3] = { all = { hat = "spangen", hat_color = "iron", spectacle = true, armor = "iron", armor_kind = "mail",
                    sleeve = "iron", sleeve_kind = "mail", cape = "#6E6458", shield_color = "#E2C04A", emblem = "raven",
                    emblem_color = "#1D1A19", shield_pattern = N },
            berserker = { hat = "fur", spectacle = N, armor = "team", armor_kind = "cloth", sleeve = N, sleeve_kind = N, cape = N } },
  },
}

function AG.unit(st, age, civ, role)
  if age == 2 or st.villager then return st end
  local o = copy(st)
  if age == 1 then
    if o.armor and (METAL_KINDS[o.armor_kind or "mail"]) then o.armor = nil; o.armor_kind = nil; o.armor2 = nil end
    if o.sleeve_kind and METAL_KINDS[o.sleeve_kind] or o.sleeve == "iron" or o.sleeve == "steel" then
      o.sleeve = o.shirt or "#B8A67E"; o.sleeve_kind = nil
    end
    for _, k in ipairs({ "shoulders", "aventail", "mail_veil", "coif", "plume", "helm_crest", "crest", "mask", "cape",
                         "gloves", "turban_helmet", "barding", "chanfron", "spectacle", "shield_pattern", "sashimono" }) do
      o[k] = nil
    end
    if o.bracers == "steel" or o.bracers == "iron" then o.bracers = nil end
    if o.coat_pattern == "lamellar" then o.coat_pattern = nil end
    if HELMETS[o.hat] then o.hat = "hood"; o.hat_color = "#7A6A4A" end
    if o.boots == "steel" or o.boots == "iron" then o.boots = "#4A3420" end
    if o.mount then o.blanket2 = nil; o.blanket_pattern = nil; o.blanket_trim = nil end
    o.coat_emblem = nil
  else
    -- Age III: no shared kit (a gold-trim + team-cape + quartered-shield layer made every civ look alike);
    -- each civ's own heavy kit, devices and colours come from UNIT[civ][3] below
    if o.mount and EURO_HORSE[civ] then o.chanfron = o.chanfron or "steel" end
  end
  local per = UNIT[civ] and UNIT[civ][age]
  if per then apply(o, per.all); apply(o, per[role]) end
  return o
end

---------------------------------------------------------------------------------------------- buildings
-- Age I: vernacular materials on the generic layouts (landmark keys cleared); per civ.
local BLD1 = {
  ottomans   = { wall = "adobe", wall_c = "#B89A74", roof = "flat", top_c = "#9A7E5E", band_c = N, base_c = N },
  byzantines = { wall = "plaster", wall_c = "#E6DCC6", roof_mat = "tiles", base_c = N, band_c = N },
  saracens   = { wall = "adobe", wall_c = "#C8A47A", top_c = "#A88A62", band_c = N, ablaq_c = N, base_c = N },
  chinese    = { wall = "rammed", wall_c = "#B8946A", roof = "hip", roof_mat = "thatch", roof_c = "#A8884E", posts_c = N },
  franks     = { wall = "plaster", wall_c = "#E8DEC6", facade_timber = true, roof_mat = "thatch", roof_c = "#B8964E", base_c = N },
  britons    = { wall = "plaster", wall_c = "#E4D8BC", facade_timber = true, roof_mat = "thatch", roof_c = "#B08A48", base_c = N },
  teutons    = { wall = "plaster", wall_c = "#E8E0CC", facade_timber = true, roof_mat = "thatch", roof_c = "#A8884A", base_c = N },
  japanese   = { wall = "planks", roof_mat = "thatch", roof_c = "#A88A50", roof = "hip" },
  vikings    = { wall = "logs", roof_mat = "turf", roof_c = "#5E7A3A" },
}
local LANDMARK_KEYS = { "tc", "house", "castle", "mill", "watch", "barracks", "archery", "market", "stable", "smith",
                        "lumber", "mine" }
-- civs whose Age I falls back to the generic layouts (none: every civ keeps its own layouts in Age I)
local DROP_LAYOUTS_A1 = {}

function AG.building_spec(s, age, civ)
  if age == 2 then return s end
  local o = copy(s)
  if age == 1 then
    -- the civ keeps its own layouts in the village age (a Japanese village is a Japanese village); the age shows in
    -- the vernacular materials (BLD1), no merlons or tower tops, and no Age III standards
    if DROP_LAYOUTS_A1[civ] then for _, k in ipairs(LANDMARK_KEYS) do o[k] = nil end end
    o.merlon = false
    o.tower_top = "none"
    if not o.watch then o.watch = "village_lookout" end
    o.blind_arches_c = nil
    apply(o, BLD1[civ])
    o.age = 1
  else
    o.age = 3
    if civ ~= "mongols" then o.paving_c = o.paving_c or "#A89A84" end   -- nomad camps stay on open ground
  end
  return o
end

-- Age III dressing: the civ's own war standards (not a generic team flag) and a pair of civ-specific yard props.
-- Standards are historical, not modern national flags (docs/art/culture/<civ>.md); each keeps one team-coloured part.
--   std  = { left, right } standard specs for A.standard (one only on small 2-tile buildings)
--   prop = two A/Pr prop names placed in the yard corners
local DRESS3 = {
  ottomans   = { std = { { form = "sancak", field = "#B3202A", ec = "#F3EFE6" }, { form = "sancak", field = "#3D6B3A", ec = "#F3EFE6" } },
                 prop = { "carpet", "copper_pot" } },                                       -- crimson + green sancak, carpets
  byzantines = { std = { { form = "labarum", field = "#A7262B", ec = "#E3B341", emblem = "chirho" },
                         { form = "labarum", field = "#6E2A6A", ec = "#E3B341", emblem = "cross" } },
                 prop = { "jar", "fountain" } },                                            -- labarum, imperial purple
  saracens   = { std = { { form = "alam", field = "#D6A62B", field2 = "#F3EFE6", ec = "#2a2234" },
                         { form = "alam", field = "#D6A62B", field2 = "#F3EFE6", ec = "#2a2234" } },
                 prop = { "carpet", "jar" } },                                              -- sultanic yellow + tiraz band
  mongols    = { std = { { form = "sulde", field = "#2B2622" }, { form = "sulde", field = "#EDE6D6" } },
                 prop = { "cart", "tug" } },                                                -- black war + white peace sulde
  chinese    = { std = { { form = "qi", field = "#C8382F", ec = "#1D1A19", emblem = "hanzi" },
                         { form = "qi", field = "#C8382F", ec = "#1D1A19", emblem = "hanzi" } },
                 prop = { "lion", "lion" } },                                               -- red character banners, guardian lions
  japanese   = { std = { { form = "nobori", field = "#F0EEE8", ec = "#1D1A19", emblem = "tomoe" },
                         { form = "nobori", field = "#F0EEE8", ec = "#1D1A19", emblem = "tomoe" } },
                 prop = { "stone_lantern", "stone_lantern" } },                             -- nobori with mon
  franks     = { std = { { form = "oriflamme", field = "#A33B2E" }, { form = "gonfanon", field2 = "#3E5486", ec = "#E1B53B", emblem = "fleur" } },
                 prop = { "barrel", "cart" } },                                             -- oriflamme + azure lis
  britons    = { std = { { form = "pennon", field = "#B3282D", field2 = "#F2EFE6" }, { form = "gonfanon", field2 = "#B3282D", ec = "#E2B437", emblem = "lions" } },
                 prop = { "hay", "barrel" } },                                              -- St George + royal lions
  teutons    = { std = { { form = "gonfanon", field2 = "#F0EEE8", ec = "#1D1A19", emblem = "cross_pattee" },
                         { form = "gonfanon", field2 = "#E2B437", ec = "#1D1A19", emblem = "eagle" } },
                 prop = { "barrel", "sacks" } },                                            -- Order cross + imperial eagle
  vikings    = { std = { { form = "raven", field2 = "#F0EEE8", ec = "#1D1A19" }, { form = "raven", field2 = "#E2C04A", ec = "#1D1A19" } },
                 prop = { "runestone", "barrel" } },                                        -- raven banners, rune stones
}
AG.DRESS3 = DRESS3

function AG.dress3(M, K, s, tiles, civ)
  local A, Pr = M.A, M.Pr
  local dr = DRESS3[civ]
  if not dr then
    M.flag(K, s, -(tiles - 0.35), 0.3, 4.4); M.flag(K, s, tiles - 0.35, 0.3, 4.4)
    return
  end
  local x = tiles - 0.35
  local h = (tiles <= 2) and 3.6 or 4.4
  local px = tiles - 0.95
  if Pr[dr.prop[1]] then Pr[dr.prop[1]](K, -px, 0.35) end
  if Pr[dr.prop[2]] then Pr[dr.prop[2]](K, px, 0.35) end
  if tiles <= 2 then
    A.standard(K, -x, 0.3, h, dr.std[1])                                     -- small buildings: one standard
  else
    A.standard(K, -x, 0.3, h, dr.std[1])
    A.standard(K, x - 0.45, 0.3, h, dr.std[2])                               -- right one hangs inward-ish
  end
end

return AG
