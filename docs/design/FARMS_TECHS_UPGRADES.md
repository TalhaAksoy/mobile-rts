# Farms, Technologies & Building Upgrades

Status: implemented on 2026-10-31 (uncommitted). Genre reference: Age of Empires IV (mill + farms, per-building
research, ages). It was used for mechanics only. Names, numbers and art are original.

## 1. Mill = farm centre, fields never run out

* **Değirmen (Mill)** is the food drop-off **and** the farm centre. Its panel has **Tarla Aç (50 Odun)**. A field is
  placed automatically in the first free 2×2 slot around the mill: four sides first, then corners. If trees or
  buildings block all eight slots (dense forest maps), it goes on the nearest free 2×2 plot within 4 cells. The
  limit is `MAX_FIELDS_PER_MILL = 6`. A field belongs to the mill within 5 cells of it. No precise placement is
  needed on a phone.
* The stand-alone **Çiftlik** entry was removed from the build menu. The `FARM` building type is now the **field
  (Tarla)**.
* The villager who prepares a field starts farming it automatically. Tapping a field with villagers selected sends
  the first villager to it and spreads the rest over free fields. Empty-handed villagers who tap a finished mill go to
  its free fields.
* **One farmer per field.** The farmer is claimed lazily (`MapGenerator3D.is_field_free_for`): a farmer who walks off
  frees the field. Enemy villagers never use the other team's fields.
* **Fields are infinite.** A harvest swing gives 4 food, against 5 for berries. A farmer whose berries run out moves
  on to a free field by itself.
* **Fields are walkable but not buildable** (`field_cells`, `is_cell_buildable`). A ring of fields therefore never
  walls the mill in. Fields have no physics body; picking is screen-space.
* **The field model follows the map biome**, not the civ:
  * temperate: wheat and a wattle fence
  * desert: barley, an irrigation canal and a mud-brick kerb
  * steppe: rye and cairns
  * autumn: stubble, sheaves and pumpkins

  A team-coloured pennant marks the owner. The crop "grows" while the field is being prepared.
* **The mill model follows the civ.** It is a tower windmill with turning sails (a separate `Sails` node that
  Building3D spins). The masonry, cap, granary annex and props come from the civ's culture
  (see ART_DIRECTION_BIBLE §6.1).
* **Bot:** it builds a mill once the wild food near its TC runs low (< 700) or after 4 minutes, leaving a 6×6 ring
  free. It then adds fields, about 45% of its villager count, at most 6.

## 2. Build times

`Building3D.BUILD_TIME` gives the seconds needed by one villager; more builders add up.

| Building | Time | Building | Time |
|---|---|---|---|
| House | 12 s | Barracks, Archery Range, Stable, Blacksmith | 25 s |
| Field | 6 s | Tower | 30 s |
| Lumber Camp, Mining Camp, Mill | 15 s | Castle, Town Center | 60 s |

Before this change every building took about 6 s.

## 3. Technologies (`scripts/TechData.gd`)

All research is data, and each entry has:
* the building where it is researched
* its cost and time
* the minimum age (and a maximum age, for age-ups)
* its prerequisites
* its effects

`GameController3D` applies the effects generically. They reach existing units and buildings at once, newly spawned
units and placed buildings, and buildings restored from a save. `UIManager3D._add_tech_buttons` lists them in each
building's panel and shows why one is unavailable: age, prerequisite, busy building or resources.

| Building | Age I | Age II | Age III |
|---|---|---|---|
| Town Center | **Hisar Çağı** (age-up) | **İmparatorluk Çağı** (age-up); Surlu Merkez ★ | – |
| House | – | Taş Evler ★ (+3 pop per house, +350 HP) | – |
| Mill | Sulama Kanalları (field +15%, berries +10%) | Ağır Saban ★ (field +20%) | Ekim Nöbeti (field +25%) |
| Lumber Camp | Keskin Baltalar (+15%) | Bıçkı Ocağı ★ (+15%, +3 carry) | Kereste Vinçleri (+20%) |
| Mining Camp | Sert Kazmalar (+15%) | Maden Arabaları ★ (+15%) | Derin Kuyular (+20%) |
| Barracks | – | Talim Meydanı ★ (infantry +20 HP, 20% faster training) | – |
| Archery Range | – | Usta Okçular ★ (+1.5 range, +10 HP) | – |
| Stable | – | Cins Atlar ★ (+10% speed, +25 HP) | – |
| Blacksmith | Demir Silahlar, Takviyeli Zırh, Demir Oklar, El Arabası | Çelik Döküm ★ (all military +2 attack) | – |
| Tower | – | Taş Kule ★ (+500 HP, +4 damage, +1.5 range) | – |
| Castle | – | – | Mazgallı Burçlar ★ (+6 damage, 25% faster fire) |

★ = the building's **own upgrade**. Every building of that type switches to its **upgraded look**: the
civilisation's upgrade kit is placed around the footprint. The kit has a low kerb in the civ's masonry, four corner
pieces and two front standards with the civ banner and a team pennant:

| Civ | Corner pieces |
|---|---|
| Ottomans | lead-capped stone bollards |
| Byzantines | brick piers with terracotta domelets |
| Britons | timber posts with thatch caps |
| Franks | stone pillars with slate spirelets and gilt finials |
| Mongols | horse-tail standards (no kerb) |
| Teutons | dark buttresses |
| Japanese | stone lanterns, plus nobori banners at the front |
| Saracens | sandstone pillars with teal domelets |
| Vikings | carved posts with shields |
| Chinese | red lacquer posts with lanterns |

The building panel shows ★ after the name.

The tech ids of the original game (`AGE_2`, `iron_weapons`, `scale_armor`, `bodkin_arrows`, `wheelbarrow`) were
kept, so older saves still load.

**Bot (verified in 600 s simulations, Yeşil Vadi and Çöl Vahası, enemy waves off):** mill plus 5–6 fields, 3–5
farmers, 13+ techs including the mill line, Age III, 56 soldiers (population cap), 0 stuck villagers. It
researches one technology per think-tick in this order: Mill, Lumber Camp, Mining Camp, Blacksmith, House,
military buildings, defences. It keeps 100 food and 50 gold in reserve, and goes to Age III after 7 minutes with
1000 food and 600 gold.

## 4. Behaviour changes worth knowing

* **Takviyeli Zırh** now applies to military units only. Before, villagers got +2 armour too.
* **Fractional gather bonuses now count** (`Unit3D.harvest_remainder`). Before, `int(5 × 1.15)` truncated to 5, so
  civ bonuses below +20% did nothing.
* **The bot no longer seals its own villagers in.** In 600 s simulations it packed buildings edge to edge around its
  TC. Together with trees and mines this formed closed pockets: 12–14 of 15 villagers were stuck carrying cargo and
  the economy froze. The bot now keeps a 1-cell lane between buildings. It also rejects a site if, once built, any
  walkable cell around the site could no longer reach the worker's area (`EnemyAI3D._keeps_ring_connected`).
* **A failed placement no longer ends the bot's think-tick.** Before, a building with no free spot (archery range,
  stable, mill, …) was retried every tick and returned early. The bot then never reached unit training or research.
  In one simulation it had 0 soldiers after 10 minutes with 5000+ wood.
* **The research reserve only counts resources a tech spends.** Before, low gold blocked wood/food-only techs too.
* `try_train_unit` now refuses unfinished buildings. The UI already hid the button; the bot could still call it.

## 5. Known limits (not changed)

* **Save files do not store depleted trees, mines or bushes.** The map is regenerated from its seed, so chopped trees
  come back after a load and can overlap fields or buildings placed there later. This was pre-existing.
* **A villager keeps its cargo when switched to another resource type.** The cargo is then delivered as the new type.
  This was pre-existing and was left as is.
* Civ-specific 3D models now exist for every building type and all 10 civs (ASSET_INVENTORY §1, §1b, §2b). The upgrade
  kit (★) is added around all of them.

Tests: `test_farm_fields.gd` (26 checks), `test_techs.gd` (40 checks), plus the full `./run_tests.sh`.
