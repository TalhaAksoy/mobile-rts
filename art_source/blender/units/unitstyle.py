"""Per civ x role style table, read from the gallery concept sheets (sample_project/art/concept_sheets/<civ>.png).

Values are palette names (charkit.PALETTE), patterns ("pat:<name>", PATTERNS below) or emblems (the gallery flags,
charkit.EMBLEMS). Each civ has the sheet's five roles; civs whose sheet has no mounted unit also get "cavalry":
that civ's swordsman on a horse (the game's generic cavalry). Mounted roles have "mount": "horse" | "camel".
attack: slash | thrust | bow | gun.  The waist sash is always the team colour (the palette's team swatch) - an intentional change
from the sheets so that armies stay readable; everything else follows the sheet. Interpretations are noted per civ.
"""

PATTERNS = {
    # embroidered / brocade cloth
    "emb_red_gold": ("embroidery", "red", "gold", "yellow"),
    "emb_purple_gold": ("embroidery", "purple", "gold", "yellow"),
    "emb_blue_gold": ("embroidery", "royal", "gold", "yellow"),
    "emb_green_gold": ("embroidery", "green", "gold", "yellow"),
    "emb_white_black": ("embroidery", "white", "black_cloth", "grey_cloth"),
    "emb_red_white": ("embroidery", "red", "white", "cream"),
    "brocade_red": ("brocade", "red", "gold", "yellow"),
    "brocade_purple": ("brocade", "purple", "gold", "yellow"),
    "brocade_blue": ("brocade", "blue", "gold", "sky"),
    "brocade_navy": ("brocade", "navy", "sky", "white"),
    # armour
    "mail_iron": ("mail", "iron", "iron_dark"),
    "mail_steel": ("mail", "steel", "iron"),
    "lamellar_brown": ("lamellar", "brown_light", "brown_dark", "blue"),
    "lamellar_red": ("lamellar", "red_dark", "black_lacquer", "gold"),
    "lamellar_steel": ("lamellar", "steel", "iron_dark", "gold"),
    "lamellar_gold": ("lamellar", "gold", "gold_dark", "purple"),
    "scale_gold": ("scale", "gold", "gold_dark", "yellow"),
    "scale_iron": ("scale", "iron", "iron_dark", "steel"),
    "plates_red": ("plates", "red_lacquer", "black_lacquer", "white"),
    "plates_black": ("plates", "black_lacquer", "red_lacquer", "gold"),
    "studded_leather": ("studded", "leather", "iron"),
    "quilt_cream": ("quilt", "cream", "linen"),
    # fur / natural
    "fur_white": ("fur", "fur", "fur_dark"),
    "fur_wolf": ("fur", "fur_wolf", "fur_grey"),
    "fur_brown": ("fur", "fur_brown", "brown_dark"),
    "straw_hat": ("straw", "straw", "straw_dark"),
    "knot_navy": ("knot", "navy", "gold", "sky"),
    "check_blue": ("check", "royal", "gold"),
}

# shared looks
_turban = dict(hat="turban", hat_cap="red", hat_color="white")

STYLES = {
    # ------------------------------------------------------------------------------------------------ OTTOMANS
    # Sheet: red-capped white turbans; red kaftans with gold trim and embroidery; scimitar + black sunburst shield,
    # spear + red crescent shield, recurve bow; janissary in a tall white bork with a musket.
    "ottomans": {
        "villager": dict(_turban, shirt="white", vest="brown", trousers="red", legs="baggy", boots="brown_dark",
                         beard="beard_black", belt="brown", weapon="axe", attack="slash"),
        "swordsman": dict(_turban, shirt="white", coat="pat:emb_red_gold", sleeve="red", trim="gold", trousers="black_cloth",
                          boots="brown_dark", bracers="leather", belt="brown", buckle="gold", beard="beard_black",
                          weapon="scimitar", shield="round", shield_color="black_cloth", shield_rim="gold",
                          emblem_shape="sunburst", emblem_color="gold", attack="slash"),
        "spearman": dict(_turban, shirt="white", coat="pat:emb_red_gold", sleeve="red", trim="gold", trousers="black_cloth",
                         boots="brown_dark", bracers="leather", belt="brown", beard="beard_black", weapon="spear",
                         tassel="red", shield="round", shield_rim="gold", emblem="ottomans", attack="thrust"),
        "archer": dict(_turban, shirt="white", coat="pat:emb_red_gold", sleeve="red", trim="gold", skirt_len=0.26,
                       trousers="black_cloth", boots="brown_dark", bracers="leather", belt="brown", crossbelt="leather",
                       beard="beard_black", weapon="bow", bow="short", bow_color="wood_dark", quiver="red", attack="bow"),
        "janissary": dict(hat="bork", hat_color="white", hat_band="gold", shirt="red_dark", coat="pat:emb_red_gold",
                          sleeve="red", trim="gold", skirt_len=0.40, trousers="navy", boots="brown_dark", belt="gold",
                          beard="beard_black", beard_kind="moustache", weapon="musket", attack="gun"),
        # sipahi: the Ottoman swordsman on a horse with a red embroidered blanket
        "cavalry": dict(_turban, shirt="white", coat="pat:emb_red_gold", sleeve="red", trim="gold", trousers="black_cloth",
                        boots="brown_dark", belt="brown", beard="beard_black", weapon="scimitar", shield="round",
                        shield_color="black_cloth", shield_rim="gold", emblem_shape="sunburst", attack="slash",
                        mount="horse", mount_color="horse_bay", blanket="pat:emb_red_gold", saddle="leather"),
    },
    # --------------------------------------------------------------------------------------------- BYZANTINES
    # Sheet: imperial purple and gold. Gilded scale / lamellar armour, crested helmets with purple plumes, purple capes,
    # shields with the gold chi-rho / cross (flag emblem). Cataphract: scale-armoured rider and horse, lance + pennant.
    "byzantines": {
        "villager": dict(hat="turban", hat_cap="purple", hat_color="white", shirt="white", tunic="pat:emb_purple_gold",
                         tunic_len=0.28, sleeve="white", trousers="brown", boots="brown_dark", belt="brown",
                         beard="beard_black", weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_byz", hat_color="steel", helm_band="gold", plume="purple", armor="pat:scale_gold",
                          armor_skirt="pat:lamellar_gold", sleeve="purple", shoulders="gold", cape="purple",
                          cape_trim="gold", trousers="grey_cloth", boots="brown_dark", bracers="steel", belt="brown",
                          beard="beard_black", weapon="sword", shield="oval", shield_rim="gold", emblem="byzantines",
                          attack="slash"),
        "spearman": dict(hat="helm_byz", hat_color="steel", helm_band="gold", plume="purple", armor="pat:scale_gold",
                         armor_skirt="pat:lamellar_gold", sleeve="purple", shoulders="gold", trousers="grey_cloth",
                         boots="brown_dark", bracers="steel", belt="brown", beard="beard_black", weapon="spear",
                         pennant="purple", pennant_emblem="byzantines", shield="oval", shield_rim="gold",
                         emblem="byzantines", attack="thrust"),
        "archer": dict(hat="helm_nasal", hat_color="steel", helm_band="gold", tunic="pat:emb_purple_gold", tunic_len=0.26,
                       armor="pat:mail_iron", sleeve="purple", trousers="grey_cloth", boots="brown_dark",
                       bracers="leather", belt="brown", crossbelt="leather", beard="beard_black", weapon="bow",
                       bow="short", quiver="purple", attack="bow"),
        "cataphract": dict(hat="helm_byz", hat_color="gold", helm_band="gold", plume="purple", armor="pat:scale_gold",
                           sleeve="pat:scale_gold", shoulders="gold", cape="purple", cape_trim="gold", cape_len=0.6,
                           trousers="purple_dark", boots="brown_dark", gloves="steel", beard="beard_black",
                           weapon="lance", pennant="purple", pennant_emblem="byzantines", attack="thrust",
                           mount="horse", mount_color="horse_dark", barding="pat:scale_gold", barding_trim="purple",
                           chanfron="gold", saddle="purple"),
    },
    # ------------------------------------------------------------------------------------------------ BRITONS
    # Sheet: red and white with mail. Kettle helmets over mail coifs, red surcoats with white trim, heater shields
    # (white with a red lion / St George's cross -> the flag's cross for both), red hoods for the archers.
    "britons": {
        "villager": dict(hat="hood", hat_color="cream", hood_lining="linen", shirt="cream", vest="brown",
                         tunic="red", tunic_len=0.22, sleeve="cream", trousers="brown", boots="brown_dark",
                         belt="brown", beard="beard_brown", weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_kettle", hat_color="steel", coif="pat:mail_iron", armor="pat:mail_iron",
                          tunic="pat:emb_red_white", tunic_trim="white", tunic_len=0.30, sleeve="pat:mail_iron",
                          trousers="pat:mail_iron", boots="brown_dark", gloves="leather", belt="brown",
                          beard="beard_brown", weapon="sword", shield="heater", shield_rim="steel", emblem="britons",
                          attack="slash"),
        "spearman": dict(hat="helm_kettle", hat_color="steel", coif="pat:mail_iron", armor="pat:mail_iron",
                         tunic="red", tunic_trim="white", chest_cross="white", tunic_len=0.30, sleeve="pat:mail_iron",
                         trousers="pat:mail_iron", boots="brown_dark", gloves="leather", belt="brown",
                         beard="beard_brown", weapon="spear", shield="heater", shield_rim="steel", emblem="britons",
                         attack="thrust"),
        "archer": dict(hat="hood", hat_color="red", hood_lining="cream", shirt="cream", tunic="red", tunic_trim="white",
                       tunic_len=0.26, sleeve="cream", trousers="brown", boots="brown_dark", bracers="leather",
                       belt="brown", crossbelt="leather", beard="beard_brown", weapon="bow", bow="short",
                       quiver="brown", attack="bow"),
        "longbowman": dict(hat="hood", hat_color="red_dark", hood_lining="red", hood_point=True, shirt="cream",
                           tunic="pat:emb_red_white", tunic_trim="gold", tunic_len=0.32, sleeve="cream",
                           trousers="brown", boots="brown_dark", bracers="leather", belt="brown", crossbelt="leather",
                           beard="beard_brown", weapon="bow", bow="long", bow_color="wood", quiver="brown",
                           attack="bow"),
        "cavalry": dict(hat="helm_kettle", hat_color="steel", coif="pat:mail_iron", armor="pat:mail_iron",
                        tunic="pat:emb_red_white", tunic_trim="white", sleeve="pat:mail_iron", trousers="pat:mail_iron",
                        boots="brown_dark", belt="brown", beard="beard_brown", weapon="sword", shield="heater",
                        shield_rim="steel", emblem="britons", attack="slash", mount="horse", mount_color="horse_brown",
                        blanket="red", saddle="leather"),
    },
    # ------------------------------------------------------------------------------------------------- FRANKS
    # Sheet: royal blue and gold fleur-de-lis. Nasal helmets over mail coifs, blue surcoats with gold, heater
    # shields with the fleur-de-lis, blue hoods for archers. Knight: crested great helm, blue caparisoned horse
    # with the fleur-de-lis, lance.
    "franks": {
        "villager": dict(hat="hood", hat_color="linen", hood_lining="cream", shirt="cream", vest="brown",
                         tunic="royal", tunic_len=0.22, sleeve="cream", trousers="brown", boots="brown_dark",
                         belt="brown", beard="beard_brown", weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_nasal", hat_color="steel", helm_band="gold", coif="pat:mail_iron",
                          armor="pat:mail_iron", tunic="pat:emb_blue_gold", tunic_trim="gold", tunic_len=0.30,
                          sleeve="pat:mail_iron", trousers="pat:mail_iron", boots="brown_dark", gloves="leather",
                          belt="brown", beard="beard_brown", weapon="sword", shield="heater", shield_rim="gold",
                          emblem="franks", attack="slash"),
        "spearman": dict(hat="helm_nasal", hat_color="steel", helm_band="gold", coif="pat:mail_iron",
                         armor="pat:mail_iron", tunic="pat:emb_blue_gold", tunic_trim="gold", tunic_len=0.30,
                         sleeve="pat:mail_iron", trousers="pat:mail_iron", boots="brown_dark", gloves="leather",
                         belt="brown", beard="beard_brown", weapon="spear", pennant="royal", pennant_emblem="franks",
                         shield="heater", shield_rim="gold", emblem="franks", attack="thrust"),
        "archer": dict(hat="hood", hat_color="royal", hood_lining="gold", shirt="cream", tunic="pat:emb_blue_gold",
                       tunic_trim="gold", tunic_len=0.26, sleeve="royal", trousers="brown", boots="brown_dark",
                       bracers="leather", belt="brown", crossbelt="leather", beard="beard_brown", weapon="bow",
                       bow="short", quiver="royal", attack="bow"),
        "knight": dict(hat="helm_great", hat_color="steel", helm_band="gold", plume="royal", plume2="white",
                       armor="pat:mail_steel",
                       tunic="pat:emb_blue_gold", tunic_trim="gold", sleeve="pat:mail_steel", shoulders="steel",
                       trousers="pat:mail_steel", boots="steel", gloves="steel", weapon="lance", shaft="royal",
                       pennant="royal", pennant_emblem="franks", shield="heater", shield_rim="gold", emblem="franks",
                       attack="thrust", mount="horse", mount_color="horse_dark", barding="pat:check_blue",
                       barding_trim="gold", barding_emblem="franks", chanfron="steel", saddle="royal"),
    },
    # ------------------------------------------------------------------------------------------------ MONGOLS
    # Sheet: blue deel coats, fur trims and hats, brown lamellar over blue, spiked helmets with blue plumes and fur
    # rims, curved sabres, round dark shields with the gold flame-crescent. Elite: horse archer on a brown horse.
    "mongols": {
        "villager": dict(hat="fur_hat", hat_cap="blue", fur="pat:fur_white", coat="pat:fur_brown", sleeve="brown_light",
                         trim="pat:fur_white", shirt="blue", trousers="brown", boots="brown_dark", belt="leather",
                         beard="beard_black", weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_mongol", hat_color="steel", fur="pat:fur_white", plume="blue",
                          armor="pat:lamellar_brown", armor_skirt="pat:lamellar_brown", coat="blue", trim="gold",
                          cuirass="pat:lamellar_brown", cuirass_trim="gold",
                          sleeve="blue", collar="pat:fur_white", trousers="blue_dark", boots="brown_dark",
                          bracers="pat:lamellar_brown", belt="leather", buckle="gold", beard="beard_black",
                          weapon="scimitar", shield="round", shield_rim="gold", emblem="mongols", attack="slash"),
        "spearman": dict(hat="helm_mongol", hat_color="steel", fur="pat:fur_white", plume="blue",
                         armor="pat:lamellar_brown", armor_skirt="pat:lamellar_brown", coat="blue", trim="gold",
                          cuirass="pat:lamellar_brown", cuirass_trim="gold",
                         sleeve="blue", collar="pat:fur_white", trousers="blue_dark", boots="brown_dark",
                         bracers="pat:lamellar_brown", belt="leather", beard="beard_black", weapon="spear",
                         tassel="blue", shield="round", shield_rim="gold", emblem="mongols", attack="thrust"),
        "archer": dict(hat="helm_mongol", hat_color="steel", fur="pat:fur_white", plume="blue",
                       armor="pat:lamellar_brown", coat="blue", trim="gold", sleeve="blue", collar="pat:fur_white",
                       cuirass="pat:lamellar_brown", cuirass_trim="gold",
                       skirt_len=0.26, trousers="blue_dark", boots="brown_dark", bracers="leather", belt="leather",
                       crossbelt="leather", beard="beard_black", weapon="bow", bow="short", quiver="leather",
                       attack="bow"),
        "horse_archer": dict(hat="helm_mongol", hat_color="steel", fur="pat:fur_white", plume="blue",
                             armor="pat:lamellar_brown", coat="blue", trim="gold", sleeve="blue",
                             cuirass="pat:lamellar_brown", cuirass_trim="gold",
                             collar="pat:fur_white", trousers="blue_dark", boots="brown_dark", bracers="leather",
                             belt="leather", beard="beard_black", weapon="bow", bow="short", quiver="leather",
                             attack="bow", mount="horse", mount_color="horse_brown", blanket="blue", saddle="leather"),
    },
    # ------------------------------------------------------------------------------------------------ TEUTONS
    # Sheet: white surcoats with the black cross over mail, nasal helms with mail coifs and brown hoods, white
    # shields with the black cross. Teutonic knight: great helm with a gold cross, white cape with the black cross,
    # sword, shield with the black eagle (flag emblem).
    "teutons": {
        "villager": dict(hat="hood", hat_color="white", hood_lining="cream", shirt="cream",
                         tunic="white", chest_cross="black_cloth", tunic_len=0.24, sleeve="cream",
                         trousers="brown_dark", boots="brown_dark", belt="brown", beard="beard_brown",
                         weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_nasal", hat_color="steel", coif="pat:mail_iron", armor="pat:mail_iron",
                          tunic="white", chest_cross="black_cloth", tunic_trim="black_cloth", tunic_len=0.30,
                          sleeve="pat:mail_iron", shoulders="brown", trousers="pat:mail_iron", boots="brown_dark",
                          gloves="leather", belt="brown", beard="beard_brown", weapon="sword", shield="heater",
                          shield_color="white", shield_cross="black_cloth", shield_rim="black_cloth", attack="slash"),
        "spearman": dict(hat="helm_nasal", hat_color="steel", coif="pat:mail_iron", armor="pat:mail_iron",
                         tunic="white", chest_cross="black_cloth", tunic_trim="black_cloth", tunic_len=0.30,
                         sleeve="pat:mail_iron", shoulders="brown", trousers="pat:mail_iron", boots="brown_dark",
                         gloves="leather", belt="brown", beard="beard_brown", weapon="spear", pennant="white",
                         shield="heater", shield_color="white", shield_cross="black_cloth", shield_rim="gold",
                         attack="thrust"),
        "archer": dict(hat="hood", hat_color="white", hood_lining="black_cloth", shirt="cream", tunic="white",
                       chest_cross="black_cloth", tunic_len=0.26, sleeve="cream", trousers="brown_dark",
                       boots="brown_dark", bracers="leather", belt="brown", crossbelt="leather",
                       beard="beard_brown", weapon="bow", bow="short", quiver="brown", attack="bow"),
        "teutonic_knight": dict(hat="helm_great", hat_color="steel", helm_band="gold", armor="pat:mail_steel",
                                tunic="white", chest_cross="black_cloth", tunic_trim="gold", tunic_len=0.36,
                                sleeve="pat:mail_steel", shoulders="steel", cape="white", cape_cross="black_cloth",
                                cape_len=0.90, trousers="pat:mail_steel", boots="steel", gloves="steel",
                                weapon="sword", shield="heater", shield_rim="gold", emblem="teutons", attack="slash"),
        "cavalry": dict(hat="helm_nasal", hat_color="steel", coif="pat:mail_iron", armor="pat:mail_iron",
                        tunic="white", chest_cross="black_cloth", sleeve="pat:mail_iron", trousers="pat:mail_iron",
                        boots="brown_dark", belt="brown", beard="beard_brown", weapon="sword", shield="heater",
                        shield_color="white", shield_cross="black_cloth", shield_rim="black_cloth", attack="slash",
                        mount="horse", mount_color="horse_white", blanket="white", saddle="brown"),
    },
    # ----------------------------------------------------------------------------------------------- JAPANESE
    # Sheet: red-and-black lacquered lamellar (do) with big shoulder plates (sode), white baggy hakama, straw
    # sandals with wrapped shins, hachimaki headbands, conical jingasa, katana / yari / tall yumi, white sashimono
    # back banners with the red disc. Samurai: kabuto with gold kuwagata horns. No shields (as on the sheet).
    "japanese": {
        "villager": dict(hat="straw_hat", hat_color="pat:straw_hat", shirt="white", robe="white", robe_trim="red",
                         robe_len=0.20, sleeve="white", vest="brown", trousers="black_cloth", legs="baggy",
                         boots="tan", boot_h=0.08, wraps="white", hair="hair_black", beard="beard_black",
                         beard_kind="goatee", weapon="axe", attack="slash"),
        "swordsman": dict(hat="hachimaki", hair="hair_black", topknot=True, shirt="white", cuirass="pat:plates_red",
                          cuirass_trim="gold", tassets="pat:plates_red", shoulders="pat:plates_red",
                          shoulder_kind="sode", sleeve="black_lacquer", trousers="white", legs="baggy", boots="tan",
                          boot_h=0.08, wraps="black_cloth", bracers="black_lacquer", beard="beard_black",
                          beard_kind="moustache", weapon="katana", grip="black_cloth", guard="gold", attack="slash"),
        "spearman": dict(hat="jingasa", hat_color="black_lacquer", hat_rim="red_lacquer", hat_mon="red",
                         shirt="white", cuirass="pat:plates_black", cuirass_trim="red", tassets="pat:plates_black",
                         shoulders="pat:plates_black", shoulder_kind="sode", sleeve="black_lacquer",
                         trousers="white", legs="baggy", boots="tan", boot_h=0.08, wraps="black_cloth",
                         bracers="black_lacquer", beard="beard_black", beard_kind="goatee", weapon="yari",
                         tassel="red", sashimono="japanese", attack="thrust"),
        "archer": dict(hat="hachimaki", hair="hair_black", topknot=True, shirt="white", cuirass="pat:plates_red",
                       cuirass_trim="gold", tassets="pat:plates_red", shoulders="pat:plates_red",
                       shoulder_kind="sode", sleeve="black_lacquer", trousers="white", legs="baggy", boots="tan",
                       boot_h=0.08, wraps="black_cloth", bracers="black_lacquer", beard="beard_black",
                       beard_kind="moustache", weapon="bow", bow="yumi", bow_color="black_lacquer",
                       quiver="black_lacquer", fletch="white", attack="bow"),
        "samurai": dict(hat="kabuto", hat_color="black_lacquer", shikoro="pat:plates_red", shirt="red",
                        cuirass="pat:plates_red", cuirass_trim="gold", tassets="pat:plates_red",
                        shoulders="pat:plates_red", shoulder_kind="sode", sleeve="pat:brocade_red",
                        trousers="black_cloth", legs="baggy", boots="black_lacquer", boot_h=0.16,
                        greaves="black_lacquer", bracers="black_lacquer", gloves="black_lacquer",
                        beard="beard_black", beard_kind="moustache", weapon="katana", grip="white", guard="gold",
                        sashimono="japanese", scabbard="black_lacquer", attack="slash"),
        "cavalry": dict(hat="kabuto", hat_color="black_lacquer", shikoro="pat:plates_red", shirt="red",
                        cuirass="pat:plates_red", cuirass_trim="gold", shoulders="pat:plates_red",
                        shoulder_kind="sode", sleeve="black_lacquer", trousers="white", boots="black_lacquer",
                        beard="beard_black", beard_kind="moustache", weapon="katana", grip="black_cloth",
                        guard="gold", sashimono="japanese", attack="slash", mount="horse",
                        mount_color="horse_dark", blanket="red_lacquer", saddle="black_lacquer"),
    },
    # ---------------------------------------------------------------------------------------------- SARACENS
    # Sheet: green and white. White turbans with green caps and tails, mail with green tunics / capes and gold,
    # scimitars, round green shields with the gold star (flag emblem), veiled archers. Mamluk: veiled rider on a
    # camel with a green blanket and gold tassels, sabre raised.
    "saracens": {
        "villager": dict(hat="turban", hat_cap="green", hat_color="white", shirt="white", vest="brown",
                         trousers="brown", legs="baggy", boots="brown_dark", belt="leather", beard="beard_black",
                         weapon="axe", attack="slash"),
        "swordsman": dict(hat="turban", hat_cap="green", hat_color="white", turban_tail=True, armor="pat:mail_iron",
                          coat="pat:emb_green_gold", sleeve="pat:mail_iron", trim="gold", collar="green",
                          trousers="cream", legs="baggy", boots="brown_dark", bracers="leather", belt="leather",
                          buckle="gold", beard="beard_black", weapon="scimitar", shield="round", shield_rim="gold",
                          emblem="saracens", attack="slash"),
        "spearman": dict(hat="turban", hat_cap="green", hat_color="white", turban_tail=True, armor="pat:mail_iron",
                         coat="pat:emb_green_gold", sleeve="pat:mail_iron", trim="gold", collar="green",
                         trousers="cream", legs="baggy", boots="brown_dark", bracers="leather", belt="leather",
                         beard="beard_black", weapon="spear", shield="round", shield_rim="gold", emblem="saracens",
                         attack="thrust"),
        "archer": dict(hat="turban", hat_cap="green", hat_color="green", turban_tail=True, veil="green",
                       armor="pat:mail_iron", robe="pat:emb_green_gold", robe_trim="gold", sleeve="white",
                       trousers="cream", legs="baggy", boots="brown_dark", bracers="leather", belt="leather",
                       crossbelt="leather", weapon="bow", bow="short", bow_color="gold_dark", quiver="leather",
                       attack="bow"),
        "mamluk": dict(hat="turban", hat_cap="green", hat_color="white", turban_tail=True, veil="green",
                       armor="pat:mail_steel", coat="pat:emb_green_gold", sleeve="pat:mail_steel", trim="gold",
                       cape="green", cape_trim="gold", cape_len=0.6, trousers="cream", boots="brown_dark",
                       belt="leather", weapon="scimitar", attack="slash", mount="camel", mount_color="camel",
                       blanket="pat:emb_green_gold", tassels="gold", saddle="green"),
    },
    # ------------------------------------------------------------------------------------------------ VIKINGS
    # Sheet: navy and brown with fur mantles, studded leather, spangenhelms with spectacle guards, round navy
    # shields with the white dragon (flag emblem), blond topknots for the bare-headed. Berserker: wolf pelt over the
    # head, bare tattooed arms and chest, an axe in each hand.
    "vikings": {
        "villager": dict(hair="hair_blond", topknot=True, beard="beard_blond", shirt="cream",
                         vest="pat:studded_leather", trousers="navy", boots="brown_dark", wraps="leather",
                         belt="leather", buckle="gold", weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_spangen", hat_color="steel", beard="beard_brown", tunic="navy",
                          tunic_trim="pat:knot_navy", tunic_len=0.28, armor="pat:studded_leather",
                          vest="pat:studded_leather", shoulders="pat:fur_white", shoulder_kind="fur", sleeve="navy",
                          trousers="navy", boots="brown_dark", wraps="leather", bracers="leather", belt="leather",
                          buckle="gold", weapon="sword", shield="round", shield_rim="bronze", emblem="vikings",
                          attack="slash"),
        "spearman": dict(hat="helm_spangen", hat_color="steel", beard="beard_brown", tunic="navy",
                         tunic_trim="pat:knot_navy", tunic_len=0.28, vest="pat:studded_leather",
                         shoulders="pat:fur_white", shoulder_kind="fur", sleeve="navy", trousers="navy",
                         boots="brown_dark", wraps="leather", bracers="leather", belt="leather", weapon="spear",
                         shield="round", shield_rim="bronze", emblem="vikings", attack="thrust"),
        "archer": dict(hair="hair_blond", braids=True, beard="beard_blond", tunic="navy", tunic_len=0.26,
                       vest="pat:studded_leather", collar="pat:fur_white", sleeve="navy", trousers="navy",
                       boots="brown_dark", wraps="leather", bracers="leather", belt="leather", crossbelt="leather",
                       weapon="bow", bow="short", quiver="leather", attack="bow"),
        "berserker": dict(hat="wolf_pelt", beard="beard_red", beard_kind="long", armor="skin", shirt="skin",
                          bare_arms=True, sleeve="skin", shoulders="pat:fur_wolf", shoulder_kind="fur",
                          tunic=None, trousers="navy", boots="pat:fur_brown", wraps="leather", bracers="leather",
                          belt="leather", buckle="gold", weapon="bearded_axe", weapon_left="bearded_axe",
                          attack="slash"),
        "cavalry": dict(hat="helm_spangen", hat_color="steel", beard="beard_brown", tunic="navy",
                        tunic_trim="pat:knot_navy", vest="pat:studded_leather", shoulders="pat:fur_white",
                        shoulder_kind="fur", sleeve="navy", trousers="navy", boots="brown_dark", weapon="sword",
                        shield="round", shield_rim="bronze", emblem="vikings", attack="slash", mount="horse",
                        mount_color="horse_grey", blanket="navy", saddle="leather"),
    },
    # ------------------------------------------------------------------------------------------------ CHINESE
    # Sheet: red robes with gold, dark lamellar with gold trim, black-and-gold helmets with red plumes and flaps,
    # dao sabres, round red shield with the gold dragon (flag emblem), straw hats for villagers. Chu Ko Nu: repeating
    # crossbow and a bolt quiver.
    "chinese": {
        "villager": dict(hat="straw_hat", hat_color="pat:straw_hat", shirt="white", robe="red", robe_trim="white",
                         robe_len=0.22, sleeve="white", trousers="brown", boots="black_cloth", belt="brown",
                         beard="beard_black", beard_kind="goatee", weapon="axe", attack="slash"),
        "swordsman": dict(hat="helm_chinese", hat_color="black_lacquer", plume="red", flaps="pat:lamellar_red",
                          robe="pat:brocade_red", robe_len=0.30, cuirass="pat:lamellar_red", cuirass_trim="gold",
                          tassets="pat:lamellar_red", shoulders="gold", sleeve="red", trousers="black_cloth",
                          boots="black_cloth", bracers="gold", belt="gold", buckle="gold", beard="beard_black",
                          beard_kind="moustache", weapon="dao", attack="slash"),
        "spearman": dict(hat="helm_chinese", hat_color="black_lacquer", plume="red", flaps="pat:lamellar_red",
                         robe="pat:brocade_red", robe_len=0.30, cuirass="pat:lamellar_red", cuirass_trim="gold",
                         tassets="pat:lamellar_red", shoulders="gold", sleeve="red", trousers="black_cloth",
                         boots="black_cloth", bracers="gold", belt="gold", beard="beard_black",
                         beard_kind="moustache", weapon="spear", tassel="red", shield="round", shield_rim="gold",
                         emblem="chinese", attack="thrust"),
        "archer": dict(hat="helm_chinese", hat_color="black_lacquer", plume="red", flaps="pat:lamellar_red",
                       robe="pat:brocade_red", robe_len=0.28, cuirass="pat:lamellar_red", cuirass_trim="gold",
                       shoulders="gold", sleeve="red", trousers="black_cloth", boots="black_cloth", bracers="gold",
                       belt="gold", beard="beard_black", beard_kind="moustache", weapon="bow", bow="short",
                       bow_color="red_lacquer", quiver="red_lacquer", fletch="red", attack="bow"),
        "chu_ko_nu": dict(hat="helm_chinese", hat_color="black_lacquer", plume="red", flaps="pat:lamellar_red",
                          robe="pat:brocade_red", robe_len=0.30, cuirass="pat:lamellar_red", cuirass_trim="gold",
                          tassets="pat:lamellar_red", shoulders="gold", sleeve="red", trousers="black_cloth",
                          boots="black_cloth", bracers="gold", belt="gold", beard="beard_black",
                          beard_kind="moustache", weapon="chukonu", quiver="wood", fletch="white", attack="gun"),
        "cavalry": dict(hat="helm_chinese", hat_color="black_lacquer", plume="red", flaps="pat:lamellar_red",
                        robe="pat:brocade_red", cuirass="pat:lamellar_red", cuirass_trim="gold", shoulders="gold",
                        sleeve="red", trousers="black_cloth", boots="black_cloth", beard="beard_black",
                        beard_kind="moustache", weapon="dao", attack="slash", mount="horse", mount_color="horse_bay",
                        blanket="pat:brocade_red", saddle="red_lacquer"),
    },
}


# ---------------------------------------------------------------------------------------------------------------
# Age looks (same plan as the 2D set, art_source/aseprite/ages.lua): Age II = STYLES above.
#   Age I  : village-age kit, no metal armour, cloth hats / hoods / turbans, unarmoured horses.
#   Age III: the civ's heaviest kit: helmet + plume, armour, cape in the team colour, gilded trim, barded horses.
# ---------------------------------------------------------------------------------------------------------------
_METAL = ("pat:mail", "pat:scale", "pat:lamellar", "pat:plates", "steel", "iron")
_HELMS = ("helm_byz", "helm_chinese", "helm_great", "helm_kettle", "helm_mongol", "helm_nasal", "helm_spangen",
          "kabuto", "coif")
_DROP1 = ("cuirass", "cuirass_trim", "armor_skirt", "tassets", "shoulders", "shoulder_kind", "greaves", "plume",
          "cape", "cape_trim", "cape_cross", "barding", "barding_emblem", "barding_trim", "chanfron", "neck_guard",
          "shikoro", "sashimono", "coif", "veil")
_D = object()                      # marker: delete the key
AGE_UNIT = {
    "ottomans": {1: {"all": dict(hat="turban", hat_cap="red", hat_color="cream"), "cavalry": dict(hat="fur_hat", hat_color="fur_brown")},
                 3: {"all": dict(hat="helm_mongol", hat_color="steel", armor="pat:scale_iron", sleeve="pat:mail_steel",
                                 plume="white", cape=_D, shield_color="red", emblem="ottomans",
                                 emblem_shape=_D, trim="gold"),
                     "janissary": dict(hat="bork", hat_color="white", armor=_D, sleeve="red", plume="white")}},
    "byzantines": {1: {"all": dict(hat="hood", hat_color="red_dark")},
                   3: {"all": dict(hat="helm_byz", hat_color="steel", armor="pat:lamellar_gold", plume="purple", cape="purple",
                                   cape_trim="gold", trim="gold", shield_color="red", emblem="byzantines", shield_rim="gold")}},
    "saracens": {1: {"all": dict(hat="turban", hat_color="white")},
                 3: {"all": dict(armor="pat:mail_steel", cuirass="steel", cuirass_trim="gold", cape=_D, helm_band="yellow",
                                 hat_band="yellow", chest_emblem="saracens", trim="yellow",
                                 shield_color="yellow", emblem="saracens")}},
    "mongols": {1: {"all": dict(hat="fur_hat", hat_color="fur_brown")},
                3: {"all": dict(hat="helm_mongol", hat_color="steel", armor="pat:lamellar_red", plume="red", cape=_D,
                                fur="pat:fur_brown", tassel="red",
                                shoulders="black_lacquer", coat="pat:brocade_red", collar="pat:fur_brown")}},
    "chinese": {1: {"all": dict(hat="hachimaki", hat_color="red")},
                3: {"all": dict(hat="helm_chinese", hat_color="steel", armor="pat:scale_iron", plume="red",
                                chest_emblem="chinese", trim="red", cape="red", cape_trim="gold",
                                shoulders="steel")}},
    "franks": {1: {"all": dict(hat="hood", hat_color="brown_light", armor="pat:quilt_cream")},
               3: {"all": dict(hat="helm_great", hat_color="steel", armor="pat:mail_steel", cuirass="steel", gloves="steel",
                               chest_emblem="franks", shield_color="royal", emblem="franks", shield_rim="gold", cape=_D)}},
    "britons": {1: {"all": dict(hat="hood", hat_color="green_dark", armor="pat:quilt_cream")},
                3: {"all": dict(hat="helm_kettle", hat_color="steel", armor="pat:mail_steel", cuirass="steel", plume="TEAM",
                                chest_emblem="britons", shield_color="red", emblem="britons", cape=_D)}},
    "teutons": {1: {"all": dict(hat="hood", hat_color="grey_cloth", armor="pat:quilt_cream")},
                3: {"all": dict(hat="helm_great", hat_color="steel", armor="pat:mail_steel", cuirass="steel", gloves="steel",
                                cape="white", cape_cross="black_cloth", tunic="white", chest_cross="black_cloth",
                                shield_color="white", emblem="teutons")}},
    "japanese": {1: {"all": dict(hat="straw_hat", hat_color="straw")},
                 3: {"all": dict(hat="kabuto", hat_color="black_lacquer", armor="pat:plates_black", shoulders="black_lacquer",
                                 shoulder_kind="sode", sashimono="japanese")}},
    "vikings": {1: {"all": dict(hat=_D)},
                3: {"all": dict(hat="helm_spangen", hat_color="iron", armor="pat:mail_iron", cape="fur_dark",
                                shield_color="yellow", emblem="vikings"),
                    "berserker": dict(hat="wolf_pelt", armor=_D, cape=_D)}},
}


def _age_style(st, civ, role, age):
    if age == 2 or role == "villager":
        return st
    o = dict(st)
    if age == 1:
        if str(o.get("armor", "")).startswith(_METAL):
            o.pop("armor", None)
        if str(o.get("sleeve", "")).startswith(_METAL):
            o["sleeve"] = o.get("shirt", "linen")
        if str(o.get("trousers", "")).startswith(_METAL):
            o["trousers"] = "brown"
        for k in _DROP1:
            o.pop(k, None)
        if o.get("gloves") in ("steel", "iron"):
            o.pop("gloves")
        if o.get("hat") in _HELMS:
            o["hat"] = "hood"; o["hat_color"] = "brown_light"
        if o.get("mount"):
            o["blanket"] = "brown"
    else:
        # Age III: no shared kit (gold trim + team cape everywhere made the civs look alike); per civ in AGE_UNIT
        if o.get("mount") and civ in ("franks", "britons", "teutons", "byzantines"):
            o.setdefault("chanfron", "steel")
    per = AGE_UNIT.get(civ, {}).get(age, {})
    for part in (per.get("all"), per.get(role)):
        for k, v in (part or {}).items():
            if v is _D:
                o.pop(k, None)
            else:
                o[k] = v
    if age == 3 and o.get("weapon") in ("bow", "crossbow", "chukonu") and role != "cavalry":
        o.pop("cuirass", None); o.pop("gloves", None)       # archers stay lighter
    return o


def get(civ, role, age=2):
    st = {k: v for k, v in STYLES[civ][role].items() if v is not None}
    return _age_style(st, civ, role, age)
