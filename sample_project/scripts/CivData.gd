class_name CivData
extends RefCounted

enum CivType {
	OTTOMANS,
	BYZANTINES,
	BRITONS,
	FRANKS,
	MONGOLS,
	TEUTONS,
	JAPANESE,
	SARACENS,
	VIKINGS,
	CHINESE
}

enum MapType {
	FOREST_VALLEY,
	DESERT_OASIS,
	RIVER_CROSSING,
	HIGHLAND_PLAINS,
	GOLD_RUSH
}

const CIVS: Dictionary = {
	CivType.OTTOMANS: {
		"id": "ottomans",
		"name": "Osmanlılar",
		"title": "Osmanlı İmparatorluğu",
		"icon": "",
		"flag_color": Color(0.85, 0.15, 0.15), # Crimson red
		"accent_color": Color(0.95, 0.8, 0.2), # Gold
		"bonus_desc": "• Askeri üretim hızı +%25\n• Kule menzili ve hasarı +%20\n• Kuşatma ve ateşli silah gücü",
		"train_speed_mult": 0.8, # 20% faster
		"tower_damage_mult": 1.25,
		"wood_gather_mult": 1.0,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.0,
		"cavalry_speed_mult": 1.0,
		"building_hp_mult": 1.0,
		"unique_unit_name": "Yeniçeri",
		"unique_unit_type": "JANISSARY",
		"unique_unit_desc": "Yüksek zırh delen tüfekli menzilli asker."
	},
	CivType.BYZANTINES: {
		"id": "byzantines",
		"name": "Bizanslılar",
		"title": "Bizans İmparatorluğu",
		"icon": "",
		"flag_color": Color(0.5, 0.1, 0.5), # Imperial Purple
		"accent_color": Color(0.95, 0.85, 0.3),
		"bonus_desc": "• Binaların canı +%30\n• Bina odun maliyeti -%15\n• Güçlü savunma ve ağır zırh",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.0,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.0,
		"cavalry_speed_mult": 1.0,
		"building_hp_mult": 1.35,
		"building_cost_mult": 0.85,
		"unique_unit_name": "Katafrakt",
		"unique_unit_type": "CATAPHRACT",
		"unique_unit_desc": "Piyadelere ekstra hasar veren zırhlı elit süvari."
	},
	CivType.BRITONS: {
		"id": "britons",
		"name": "Britanyalılar",
		"title": "Büyük Britanya",
		"icon": "",
		"flag_color": Color(0.15, 0.35, 0.85), # Royal Blue
		"accent_color": Color(0.9, 0.9, 0.9),
		"bonus_desc": "• Okçuların menzili +%30\n• Odun toplama hızı +%15\n• Erken okçu üstünlüğü",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.20,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.0,
		"cavalry_speed_mult": 1.0,
		"building_hp_mult": 1.0,
		"archer_range_mult": 1.3,
		"unique_unit_name": "Uzun Yaylı",
		"unique_unit_type": "LONGBOWMAN",
		"unique_unit_desc": "Kule menzilinin dışından vurabilen efsanevi okçu."
	},
	CivType.FRANKS: {
		"id": "franks",
		"name": "Franklar",
		"title": "Frank Krallığı",
		"icon": "",
		"flag_color": Color(0.2, 0.45, 0.8), # French Blue
		"accent_color": Color(0.95, 0.75, 0.2), # Fleur-de-lis Gold
		"bonus_desc": "• Süvarilerin canı +%25\n• Çiftlikler %25 daha az odun ister\n• Güçlü şövalye ordusu",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.0,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.15,
		"cavalry_hp_mult": 1.25,
		"cavalry_speed_mult": 1.05,
		"building_hp_mult": 1.0,
		"unique_unit_name": "Şövalye Paladin",
		"unique_unit_type": "PALADIN",
		"unique_unit_desc": "Muazzam cana ve hücum gücüne sahip asil şövalye."
	},
	CivType.MONGOLS: {
		"id": "mongols",
		"name": "Moğollar",
		"title": "Moğol Hanlığı",
		"icon": "",
		"flag_color": Color(0.75, 0.45, 0.1), # Steppe Amber
		"accent_color": Color(0.2, 0.6, 0.8),
		"bonus_desc": "• Süvariler %25 daha hızlı hareket eder\n• Besin toplama hızı +%20\n• Hızlı akın ve vur-kaç taktiği",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.0,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.25,
		"cavalry_speed_mult": 1.25,
		"building_hp_mult": 1.0,
		"unique_unit_name": "Mangudai",
		"unique_unit_type": "MANGUDAI",
		"unique_unit_desc": "Hareket halindeyken hızla ok yağdıran atlı okçu."
	},
	CivType.TEUTONS: {
		"id": "teutons",
		"name": "Tötonlar",
		"title": "Töton Şövalyeleri Tarikatı",
		"icon": "",
		"flag_color": Color(0.2, 0.2, 0.2), # Iron Black & White
		"accent_color": Color(0.9, 0.2, 0.2),
		"bonus_desc": "• Piyadeler ve kuleler +2 ekstra zırh\n• Çiftlik maliyeti -%33\n• Ağır zırhlı yıkılmaz piyadeler",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.2,
		"wood_gather_mult": 1.0,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.1,
		"cavalry_speed_mult": 0.95,
		"building_hp_mult": 1.1,
		"armor_bonus": 3,
		"unique_unit_name": "Töton Şövalyesi",
		"unique_unit_type": "TEUTONIC_KNIGHT",
		"unique_unit_desc": "Piyadelerin efendisi, aşırı yüksek zırhlı demir savaşçı."
	},
	CivType.JAPANESE: {
		"id": "japanese",
		"name": "Japonlar",
		"title": "Japon Şogunluğu",
		"icon": "",
		"flag_color": Color(0.85, 0.2, 0.3), # Cherry Red
		"accent_color": Color(1.0, 1.0, 1.0),
		"bonus_desc": "• Piyadeler %25 daha hızlı saldırır\n• Odun ve maden toplama +%10\n• Hızlı ve ölümcül kılıç ustaları",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.15,
		"gold_gather_mult": 1.15,
		"food_gather_mult": 1.1,
		"cavalry_speed_mult": 1.0,
		"building_hp_mult": 1.0,
		"infantry_atk_speed_mult": 0.75, # 25% faster swing
		"unique_unit_name": "Samuray",
		"unique_unit_type": "SAMURAI",
		"unique_unit_desc": "Katana ile yıldırım hızında kesen, kritik vuran savaşçı."
	},
	CivType.SARACENS: {
		"id": "saracens",
		"name": "Sarazenler",
		"title": "Eyyubi & Abbasi Sultanlığı",
		"icon": "",
		"flag_color": Color(0.1, 0.55, 0.25), # Islamic Emerald
		"accent_color": Color(0.95, 0.8, 0.2),
		"bonus_desc": "• Altın madenciliği hızı +%30\n• Süvarilere karşı güçlü develer\n• Ticaret ve pazar zenginliği",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.0,
		"gold_gather_mult": 1.30,
		"food_gather_mult": 1.0,
		"cavalry_speed_mult": 1.05,
		"building_hp_mult": 1.0,
		"unique_unit_name": "Memlük",
		"unique_unit_type": "MAMELUKE",
		"unique_unit_desc": "Hançer fırlatan ve süvarileri darmadağın eden deve binicisi."
	},
	CivType.VIKINGS: {
		"id": "vikings",
		"name": "Vikingler",
		"title": "İskandinav Krallığı",
		"icon": "",
		"flag_color": Color(0.15, 0.45, 0.55), # Nordic Teal
		"accent_color": Color(0.9, 0.6, 0.2),
		"bonus_desc": "• Piyadeler +%20 can ve otomatik can yenilenmesi\n• Odun toplama hızı +%15\n• Korkusuz yakın dövüş gazabı",
		"train_speed_mult": 1.0,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.20,
		"gold_gather_mult": 1.0,
		"food_gather_mult": 1.05,
		"cavalry_speed_mult": 1.0,
		"building_hp_mult": 1.0,
		"infantry_hp_mult": 1.25,
		"infantry_regen": 2.0, # 2 HP per sec
		"unique_unit_name": "Berserker",
		"unique_unit_type": "BERSERKER",
		"unique_unit_desc": "Yaralandıkça canı yenilenen ve çift baltayla biçen vahşi."
	},
	CivType.CHINESE: {
		"id": "chinese",
		"name": "Çinliler",
		"title": "Çin İmparatorluğu",
		"icon": "",
		"flag_color": Color(0.85, 0.25, 0.1), # Imperial Vermilion
		"accent_color": Color(0.95, 0.85, 0.1),
		"bonus_desc": "• Oyuna +2 fazladan işçi ile başlar\n• Nüfus limiti +5 fazladan başlar\n• Geliştirmeler ve birimler %15 daha ucuz",
		"train_speed_mult": 0.9,
		"tower_damage_mult": 1.0,
		"wood_gather_mult": 1.1,
		"gold_gather_mult": 1.1,
		"food_gather_mult": 1.1,
		"cavalry_speed_mult": 1.0,
		"building_hp_mult": 1.0,
		"start_villager_bonus": 2,
		"cost_discount_mult": 0.85,
		"unique_unit_name": "Chu-Ko-Nu",
		"unique_unit_type": "CHUKONU",
		"unique_unit_desc": "Tek seferde 3 ok fırlatan seri makineli arbaletçi."
	}
}

const MAP_CONFIGS: Dictionary = {
	MapType.FOREST_VALLEY: {
		"name": "Yeşil Vadi",
		"subtitle": "Forest Valley",
		"desc": "Gür ağaçlıklar, dar geçitler ve zengin odun kaynakları.",
		"tree_density": 0.38,
		"water_freq": 0.08,
		"gold_nodes": 7,
		"food_nodes": 9,
		"ground_color": Color(0.24, 0.48, 0.22),
		"ground_accent": Color(0.29, 0.55, 0.26),
		"water_color": Color(0.18, 0.42, 0.65)
	},
	MapType.DESERT_OASIS: {
		"name": "Çöl Vahası",
		"subtitle": "Desert Oasis",
		"desc": "Merkezde hayat veren vaha ve altın madenleri, açık kum tepeleri.",
		"tree_density": 0.14,
		"water_freq": 0.15, # Central lake
		"gold_nodes": 10,
		"food_nodes": 6,
		"ground_color": Color(0.82, 0.72, 0.45),
		"ground_accent": Color(0.76, 0.64, 0.38),
		"water_color": Color(0.12, 0.62, 0.75)
	},
	MapType.RIVER_CROSSING: {
		"name": "Nehir Geçidi",
		"subtitle": "River Crossing",
		"desc": "İki tarafı ayıran nehir ve stratejik sığ geçit köprüleri.",
		"tree_density": 0.24,
		"water_freq": 0.22,
		"gold_nodes": 8,
		"food_nodes": 8,
		"ground_color": Color(0.32, 0.52, 0.25),
		"ground_accent": Color(0.28, 0.46, 0.22),
		"water_color": Color(0.15, 0.48, 0.72)
	},
	MapType.HIGHLAND_PLAINS: {
		"name": "Yayla Bozkırı",
		"subtitle": "Highland Plains",
		"desc": "Kayalık tepeler, açık süvari alanları ve dağınık zenginlikler.",
		"tree_density": 0.18,
		"water_freq": 0.04,
		"gold_nodes": 8,
		"food_nodes": 10,
		"ground_color": Color(0.42, 0.56, 0.32),
		"ground_accent": Color(0.48, 0.52, 0.38),
		"water_color": Color(0.22, 0.5, 0.68)
	},
	MapType.GOLD_RUSH: {
		"name": "Hazine Vadisi",
		"subtitle": "Gold Rush",
		"desc": "Tarafsız orta bölgede devasa altın ve taş madenleri. Kanlı savaş!",
		"tree_density": 0.20,
		"water_freq": 0.06,
		"gold_nodes": 15,
		"food_nodes": 6,
		"ground_color": Color(0.45, 0.48, 0.36),
		"ground_accent": Color(0.52, 0.46, 0.30),
		"water_color": Color(0.18, 0.45, 0.6)
	}
}

static func get_civ(civ_type: CivType) -> Dictionary:
	return CIVS.get(civ_type, CIVS[CivType.OTTOMANS])

static func get_map_config(map_type: MapType) -> Dictionary:
	return MAP_CONFIGS.get(map_type, MAP_CONFIGS[MapType.FOREST_VALLEY])
