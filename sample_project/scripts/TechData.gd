class_name TechData
extends RefCounted
## Every research in the game, data-driven: where it is researched, what it costs, which age it needs,
## what it requires, and its effects. GameController3D applies effects generically; UIManager3D
## lists a building's techs from here. Original names/numbers (genre-standard economy/upgrade lines,
## not copied from any specific game).
##
## Effect dictionaries:
##   {"type": "age", "to": 2}
##   {"type": "gather", "kind": "wood"|"gold"|"stone"|"food"|"field", "mult": 1.15}
##   {"type": "carry", "add": 5}
##   {"type": "unit", "filter": "infantry"|"ranged"|"cavalry"|"villager"|"military"|"all",
##        "stat": "attack_dmg"|"armor"|"max_hp"|"move_speed"|"attack_range", "add": x | "mult": x}
##   {"type": "building", "building": BuildingType, "stat": "max_hp"|"armor"|"shoot_damage"|"shoot_range"|"shoot_cooldown",
##        "add": x | "mult": x}
##   {"type": "house_pop", "add": 3}
##   {"type": "train_speed", "building": BuildingType, "mult": 0.8}
##   {"type": "level", "building": BuildingType}       -> that building type shows its upgraded (civ) look

const B := Building3D.BuildingType

const TECHS: Dictionary = {
	# ---- Ages (Town Center) ------------------------------------------------------------------
	"AGE_2": {"name": "Çağ II: Hisar Çağı", "building": B.TOWN_CENTER, "age": 1, "max_age": 1,
		"cost": {"food": 500, "gold": 200}, "time": 20.0, "effects": [{"type": "age", "to": 2}],
		"desc": "Kale, şövalye ve yeni geliştirmeler"},
	"AGE_3": {"name": "Çağ III: İmparatorluk Çağı", "building": B.TOWN_CENTER, "age": 2, "max_age": 2,
		"cost": {"food": 1000, "gold": 600}, "time": 35.0, "effects": [{"type": "age", "to": 3}],
		"desc": "En güçlü geliştirmeler açılır"},
	"tc_fortify": {"name": "Surlu Merkez", "building": B.TOWN_CENTER, "age": 2,
		"cost": {"wood": 200, "stone": 150}, "time": 25.0,
		"effects": [{"type": "building", "building": B.TOWN_CENTER, "stat": "max_hp", "add": 800},
			{"type": "building", "building": B.TOWN_CENTER, "stat": "armor", "add": 3},
			{"type": "building", "building": B.TOWN_CENTER, "stat": "shoot_damage", "add": 4},
			{"type": "level", "building": B.TOWN_CENTER}],
		"desc": "+800 can, +3 zırh, +4 ok hasarı"},

	# ---- House -------------------------------------------------------------------------------
	"stone_houses": {"name": "Taş Evler", "building": B.HOUSE, "age": 2,
		"cost": {"wood": 150, "stone": 75}, "time": 20.0,
		"effects": [{"type": "house_pop", "add": 3},
			{"type": "building", "building": B.HOUSE, "stat": "max_hp", "add": 350},
			{"type": "level", "building": B.HOUSE}],
		"desc": "Her ev +3 nüfus, +350 can"},

	# ---- Mill (farm centre) ------------------------------------------------------------------
	"irrigation": {"name": "Sulama Kanalları", "building": B.MILL, "age": 1,
		"cost": {"wood": 100, "food": 50}, "time": 15.0,
		"effects": [{"type": "gather", "kind": "field", "mult": 1.15}, {"type": "gather", "kind": "food", "mult": 1.10}],
		"desc": "Tarla +%15, çalı +%10 toplama"},
	"heavy_plough": {"name": "Ağır Saban", "building": B.MILL, "age": 2, "requires": ["irrigation"],
		"cost": {"wood": 175, "food": 100}, "time": 20.0,
		"effects": [{"type": "gather", "kind": "field", "mult": 1.20}, {"type": "level", "building": B.MILL}],
		"desc": "Tarla +%20 toplama, büyük değirmen"},
	"crop_rotation": {"name": "Ekim Nöbeti", "building": B.MILL, "age": 3, "requires": ["heavy_plough"],
		"cost": {"wood": 300, "gold": 150}, "time": 30.0,
		"effects": [{"type": "gather", "kind": "field", "mult": 1.25}],
		"desc": "Tarla +%25 toplama"},

	# ---- Lumber camp -------------------------------------------------------------------------
	"sharp_axes": {"name": "Keskin Baltalar", "building": B.LUMBER_CAMP, "age": 1,
		"cost": {"wood": 75, "food": 50}, "time": 15.0,
		"effects": [{"type": "gather", "kind": "wood", "mult": 1.15}],
		"desc": "Odun +%15 toplama"},
	"saw_pit": {"name": "Bıçkı Ocağı", "building": B.LUMBER_CAMP, "age": 2, "requires": ["sharp_axes"],
		"cost": {"wood": 150, "gold": 50}, "time": 20.0,
		"effects": [{"type": "gather", "kind": "wood", "mult": 1.15}, {"type": "carry", "add": 3},
			{"type": "level", "building": B.LUMBER_CAMP}],
		"desc": "Odun +%15, +3 taşıma"},
	"timber_cranes": {"name": "Kereste Vinçleri", "building": B.LUMBER_CAMP, "age": 3, "requires": ["saw_pit"],
		"cost": {"wood": 250, "gold": 150}, "time": 30.0,
		"effects": [{"type": "gather", "kind": "wood", "mult": 1.20}],
		"desc": "Odun +%20"},

	# ---- Mining camp -------------------------------------------------------------------------
	"hard_picks": {"name": "Sert Kazmalar", "building": B.MINING_CAMP, "age": 1,
		"cost": {"wood": 100, "food": 50}, "time": 15.0,
		"effects": [{"type": "gather", "kind": "gold", "mult": 1.15}, {"type": "gather", "kind": "stone", "mult": 1.15}],
		"desc": "Altın ve taş +%15"},
	"mine_carts": {"name": "Maden Arabaları", "building": B.MINING_CAMP, "age": 2, "requires": ["hard_picks"],
		"cost": {"wood": 175, "gold": 75}, "time": 20.0,
		"effects": [{"type": "gather", "kind": "gold", "mult": 1.15}, {"type": "gather", "kind": "stone", "mult": 1.15},
			{"type": "level", "building": B.MINING_CAMP}],
		"desc": "Altın ve taş +%15"},
	"deep_shafts": {"name": "Derin Kuyular", "building": B.MINING_CAMP, "age": 3, "requires": ["mine_carts"],
		"cost": {"wood": 250, "gold": 200}, "time": 30.0,
		"effects": [{"type": "gather", "kind": "gold", "mult": 1.20}, {"type": "gather", "kind": "stone", "mult": 1.20}],
		"desc": "Altın ve taş +%20"},

	# ---- Military buildings: their own upgrades ----------------------------------------------
	"drill_yard": {"name": "Talim Meydanı", "building": B.BARRACKS, "age": 2,
		"cost": {"food": 150, "gold": 100}, "time": 25.0,
		"effects": [{"type": "unit", "filter": "infantry", "stat": "max_hp", "add": 20},
			{"type": "train_speed", "building": B.BARRACKS, "mult": 0.8}, {"type": "level", "building": B.BARRACKS}],
		"desc": "Piyade +20 can, %20 hızlı eğitim"},
	"master_archers": {"name": "Usta Okçular", "building": B.ARCHERY_RANGE, "age": 2,
		"cost": {"wood": 150, "gold": 125}, "time": 25.0,
		"effects": [{"type": "unit", "filter": "ranged", "stat": "attack_range", "add": 1.5},
			{"type": "unit", "filter": "ranged", "stat": "max_hp", "add": 10}, {"type": "level", "building": B.ARCHERY_RANGE}],
		"desc": "Okçu +1.5 menzil, +10 can"},
	"bred_horses": {"name": "Cins Atlar", "building": B.STABLE, "age": 2,
		"cost": {"food": 200, "gold": 100}, "time": 25.0,
		"effects": [{"type": "unit", "filter": "cavalry", "stat": "move_speed", "mult": 1.10},
			{"type": "unit", "filter": "cavalry", "stat": "max_hp", "add": 25}, {"type": "level", "building": B.STABLE}],
		"desc": "Süvari +%10 hız, +25 can"},

	# ---- Blacksmith (ids kept from the original game: saves stay compatible) -----------------
	"iron_weapons": {"name": "Demir Silahlar", "building": B.BLACKSMITH, "age": 1,
		"cost": {"food": 100, "gold": 40}, "time": 12.0,
		"effects": [{"type": "unit", "filter": "infantry", "stat": "attack_dmg", "add": 3}],
		"desc": "+3 piyade saldırısı"},
	"scale_armor": {"name": "Takviyeli Zırh", "building": B.BLACKSMITH, "age": 1,
		"cost": {"food": 100, "gold": 40}, "time": 12.0,
		"effects": [{"type": "unit", "filter": "military", "stat": "armor", "add": 2}],
		"desc": "+2 asker zırhı"},
	"bodkin_arrows": {"name": "Demir Oklar", "building": B.BLACKSMITH, "age": 1,
		"cost": {"wood": 100, "gold": 50}, "time": 12.0,
		"effects": [{"type": "unit", "filter": "ranged", "stat": "attack_dmg", "add": 3}],
		"desc": "+3 okçu saldırısı"},
	"wheelbarrow": {"name": "El Arabası", "building": B.BLACKSMITH, "age": 1,
		"cost": {"wood": 100, "food": 50}, "time": 12.0,
		"effects": [{"type": "carry", "add": 5}, {"type": "unit", "filter": "villager", "stat": "move_speed", "mult": 1.15}],
		"desc": "Köylü +5 taşıma, +%15 hız"},
	"steel_forging": {"name": "Çelik Döküm", "building": B.BLACKSMITH, "age": 2, "requires": ["iron_weapons"],
		"cost": {"food": 200, "gold": 150}, "time": 25.0,
		"effects": [{"type": "unit", "filter": "military", "stat": "attack_dmg", "add": 2}, {"type": "level", "building": B.BLACKSMITH}],
		"desc": "Tüm askerler +2 saldırı"},

	# ---- Defences ----------------------------------------------------------------------------
	"stone_tower": {"name": "Taş Kule", "building": B.TOWER, "age": 2,
		"cost": {"wood": 100, "stone": 150}, "time": 25.0,
		"effects": [{"type": "building", "building": B.TOWER, "stat": "max_hp", "add": 500},
			{"type": "building", "building": B.TOWER, "stat": "shoot_damage", "add": 4},
			{"type": "building", "building": B.TOWER, "stat": "shoot_range", "add": 1.5},
			{"type": "level", "building": B.TOWER}],
		"desc": "+500 can, +4 hasar, +1.5 menzil"},
	"murder_holes": {"name": "Mazgallı Burçlar", "building": B.CASTLE, "age": 3,
		"cost": {"wood": 200, "stone": 250}, "time": 30.0,
		"effects": [{"type": "building", "building": B.CASTLE, "stat": "shoot_damage", "add": 6},
			{"type": "building", "building": B.CASTLE, "stat": "shoot_cooldown", "mult": 0.75},
			{"type": "level", "building": B.CASTLE}],
		"desc": "+6 hasar, %25 hızlı atış"},
}

## Display order of techs inside a building panel.
static func techs_for_building(b_type: int) -> Array:
	var out: Array = []
	for id in TECHS.keys():
		if TECHS[id]["building"] == b_type:
			out.append(id)
	return out

static func get_tech(id: String) -> Dictionary:
	return TECHS.get(id, {})

static func cost_text(id: String) -> String:
	var names := {"food": "Besin", "wood": "Odun", "gold": "Altın", "stone": "Taş"}
	var parts: Array = []
	for k in ["food", "wood", "gold", "stone"]:
		var v: int = int(TECHS[id]["cost"].get(k, 0))
		if v > 0:
			parts.append("%d %s" % [v, names[k]])
	return ", ".join(parts)

static func age_name(age: int) -> String:
	match age:
		1: return "Köy Çağı"
		2: return "Hisar Çağı"
		3: return "İmparatorluk Çağı"
	return "Çağ %d" % age

## True when the unit type matches an effect filter.
static func unit_matches(u, filter: String) -> bool:
	match filter:
		"all": return true
		"villager": return u.unit_type == Unit3D.UnitType.VILLAGER
		"military": return u.unit_type != Unit3D.UnitType.VILLAGER
		"infantry": return u.is_infantry()
		"ranged": return u.is_ranged()
		"cavalry": return u.is_cavalry()
	return false
