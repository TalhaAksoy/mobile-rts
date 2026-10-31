# Asset Inventory & Per-Asset Validation

Status legend: NOT STARTED · WIP · IMPORTED · TESTED · APPROVED · BLOCKED.
**TESTED** here means: Blender preview reviewed, GLB imported by Godot, `test_building_models.gd` passed (footprint, ground
contact, shared materials, team trim blue/red, construction states, save/load), and the asset was captured in the
**real** Main3D game scene. **APPROVED** is reserved for sign-off by the project's art owner. The only reviewer so far is
the automated / advisor process, so nothing is marked APPROVED.

Common to every model below: Godot scene = the `.glb` itself, instanced through `data/art/building_model_manifest.json`
(no wrapper `.tscn` needed). Textures = shared 64×64 library (`assets/3d/materials/textures`, 38 textures, ~0.2 MB total).
Collision = unchanged `BoxShape3D` footprint from `Building3D` (models never generate collision). Selection = unchanged
screen-space picking + footprint fallback.

## 1. Buildings (3D)

| Asset ID | Civ | Type | Blender source | GLB | Tris | Mats | Height m | In-game evidence | Perf notes | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| ottomans/town_center | Ottomans | Town Center | art_source/blender/ottomans/town_center.blend | assets/3d/buildings/ottomans/town_center.glb | 3869 | 13 | 5.26 | slice/compare_ottomans_town_center.png, slice/env_v3_* | heaviest asset; minaret/drum detail could LOD | TESTED |
| ottomans/house | Ottomans | House | …/ottomans/house.blend | …/ottomans/house.glb | 723 | 10 | 3.56 | slice/ott_slice_0_*.png, env_v3_* | — | TESTED |
| ottomans/barracks | Ottomans | Barracks | …/ottomans/barracks.blend | …/ottomans/barracks.glb | 1042 | 11 | 3.76 | slice/ott_slice_0_*.png | — | TESTED |
| ottomans/lumber_camp | Ottomans | Lumber Camp | …/ottomans/lumber_camp.blend | …/ottomans/lumber_camp.glb | 589 | 10 | 1.92 | slice/ott_slice_0_*.png | — | TESTED |
| byzantines/town_center | Byzantines | Town Center | …/byzantines/town_center.blend | …/byzantines/town_center.glb | 1430 | 10 | 4.02 | slice/all_civ_town_centers_ingame.png | — | TESTED |
| britons/town_center | Britons | Town Center | …/britons/town_center.blend | …/britons/town_center.glb | 1152 | 11 | 4.66 | same | — | TESTED |
| franks/town_center | Franks | Town Center | …/franks/town_center.blend | …/franks/town_center.glb | 1174 | 10 | 6.81 | same | tallest asset: occludes units behind it (silhouettes handle it) | TESTED |
| mongols/town_center | Mongols | Town Center | …/mongols/town_center.blend | …/mongols/town_center.glb | 1557 | 13 | 3.63 | slice/compare_mongols_town_center.png | — | TESTED |
| teutons/town_center | Teutons | Town Center | …/teutons/town_center.blend | …/teutons/town_center.glb | 978 | 10 | 6.21 | all_civ_town_centers_ingame.png | tall keep | TESTED |
| japanese/town_center | Japanese | Town Center | …/japanese/town_center.blend | …/japanese/town_center.glb | 1131 | 12 | 5.47 | slice/compare_japanese_town_center.png | — | TESTED |
| saracens/town_center | Saracens | Town Center | …/saracens/town_center.blend | …/saracens/town_center.glb | 1582 | 12 | 4.76 | all_civ_town_centers_ingame.png | — | TESTED |
| vikings/town_center | Vikings | Town Center | …/vikings/town_center.blend | …/vikings/town_center.glb | 705 | 12 | 4.23 | same | — | TESTED |
| chinese/town_center | Chinese | Town Center | …/chinese/town_center.blend | …/chinese/town_center.glb | 980 | 12 | 4.65 | same | — | TESTED |
| byzantines/house | Byzantines | House | …/byzantines/house.blend | …/byzantines/house.glb | 580 | 9 | 2.83 | houses/houses_ingame_10civs.png | stone/brick bands, terracotta gables, arcaded loggia (team awning) | TESTED |
| britons/house | Britons | House | …/britons/house.blend | …/britons/house.glb | 571 | 10 | 3.12 | houses/houses_ingame_10civs.png | whitewash + timber frame, hipped thatch, stone chimney | TESTED |
| franks/house | Franks | House | …/franks/house.blend | …/franks/house.glb | 569 | 10 | 4.33 | houses/houses_ingame_10civs.png | tall pale stone, blue slate hip roof + dormer, turret with slate spire | TESTED |
| mongols/house | Mongols | House | …/mongols/house.blend | …/mongols/house.glb | 584 | 9 | 1.98 | houses/houses_ingame_10civs.png | felt ger, rope bands, toono + stove pipe, felt ox cart | TESTED |
| teutons/house | Teutons | House | …/teutons/house.blend | …/teutons/house.glb | 521 | 9 | 4.16 | houses/houses_ingame_10civs.png | stone ground floor, jettied half-timber, black slate, stepped front gable | TESTED |
| japanese/house | Japanese | House | …/japanese/house.blend | …/japanese/house.glb | 628 | 9 | 2.63 | houses/houses_ingame_10civs.png | minka: white plaster + dark frame, irimoya kawara roof, engawa, team noren | TESTED |
| saracens/house | Saracens | House | …/saracens/house.blend | …/saracens/house.glb | 452 | 8 | 3.16 | houses/houses_ingame_10civs.png | flat-roofed sandstone, wind catcher, mashrabiya, teal door frame, team awning | TESTED |
| vikings/house | Vikings | House | …/vikings/house.blend | …/vikings/house.glb | 532 | 9 | 2.66 | houses/houses_ingame_10civs.png | longhouse: plank walls, steep shingle roof, crossed gable boards, team shields | TESTED |
| chinese/house | Chinese | House | …/chinese/house.blend | …/chinese/house.glb | 448 | 10 | 2.37 | houses/houses_ingame_10civs.png | courtyard: red columns, teal curved roof, gold ridge ends, wall + gate, team lanterns | TESTED |

## 1b. Kit-built buildings (civ kit: `civstyle.py` + `bldtypes.py`)

All entries below pass `test_building_models.gd` (footprint, ground contact, shared library materials, TEAM trim blue/red,
construction states, save/load). In-game evidence: one sheet per type, all 10 civs, `docs/audits/evidence/buildings/<type>_ingame_10civs.png`.
Ottoman Barracks and Lumber Camp are hand-written (section 1). Status for all: TESTED. The Mongol house cart wheels were
later capped (`cylinder_between(cap=True)`); its in-game house sheet predates that two-wheel change.

| Type | Grid | Tris (min–max) | Mats (min–max) | Civs |
|---|---|---|---|---|
| Barracks | 3x3 | 778–1186 | 9–12 | 10 |
| Archery Range | 3x3 | 1078–1332 | 12–14 | 10 |
| Stable | 3x3 | 897–1179 | 11–13 | 10 |
| Blacksmith | 2x2 | 507–737 | 9–11 | 10 |
| Lumber Camp | 2x2 | 495–617 | 9–10 | 10 |
| Mining Camp | 2x2 | 695–817 | 9–10 | 10 |
| Watch Tower | 2x2 | 247–512 | 7–10 | 10 |
| Castle | 4x4 | 1196–2626 | 8–11 | 10 |

**Performance, desktop only (not a mobile measurement):** the same seed-5 base with one of every building type added
(`full_base_britons_japanese.png`) renders **~797 draw calls / ~117k primitives**, against ~440 / ~79k with one extra
building. Each kit building costs roughly 30–40 draw calls (one per material surface, plus shadow passes). This has not
been measured on a phone. The obvious next step, if mobile profiling shows it is needed, is to bake each building's 9–14
library materials into one per-building atlas (1–2 surfaces).

## 2. Environment (3D, one nature-atlas surface each; food props +1 fruit surface)

Props are chosen per map **biome** (`CivData.BIOME_PROPS`). Yeşil Vadi and Nehir Geçidi = temperate, Çöl Vahası = desert,
Yayla Bozkırı = steppe, Hazine Vadisi = autumn. Previews: `docs/art/previews/env_<folder>_<asset>.png`. In-game evidence
for all five maps (seed 777): `docs/audits/evidence/environment/biomes/biome_map{0..4}_*` and the side-by-side sheets
`biomes_default_all.png`, `biomes_close_all.png`. All entries pass `test_building_models.gd` and `test_biome_props.gd`.

| Manifest id | Biome | Resource (UI name) | Tris | Mats | Notes | Status |
|---|---|---|---|---|---|---|
| tree_pine | temperate | wood (Çam Ağacı) | 120 | 1 | | TESTED |
| tree_oak | temperate | wood (Meşe Ağacı) | 272 | 1 | | TESTED |
| gold_mine | temperate, autumn | gold (Altın Madeni) | 325 | 1 | shrinks 100%→55% with remaining gold | TESTED |
| stone_mine | temperate, autumn | stone (Taş Ocağı) | 205 | 1 | shrinks 100%→55% | TESTED |
| berry_bush | temperate | food (Böğürtlen Çalısı) | 330 | 2 | | TESTED |
| desert/tree_palm | desert | wood (Hurma Ağacı) | 343 | 1 | ringed curved trunk, V-folded double-sided fronds, date clusters | TESTED |
| desert/tree_acacia | desert | wood (Akasya) | 222 | 1 | flat umbrella canopy | TESTED |
| desert/gold_mine | desert | gold (Altın Madeni) | 438 | 1 | stepped sandstone hoodoos + gold crystals; heaviest env prop | TESTED |
| desert/stone_mine | desert | stone (Kumtaşı Ocağı) | 100 | 1 | terraced quarry face + cut blocks | TESTED |
| desert/prickly_pear | desert | food (Frenk İnciri) | 306 | 2 | cactus pads + red fruit | TESTED |
| steppe/tree_scots_pine | steppe | wood (Sarıçam) | 204 | 1 | red bark, wind-swept crown | TESTED |
| steppe/tree_juniper | steppe | wood (Ardıç) | 96 | 1 | squat faceted cones | TESTED |
| steppe/gold_mine | steppe | gold (Altın Madeni) | 325 | 1 | temperate geometry, pale granite atlas | TESTED |
| steppe/stone_mine | steppe | stone (Granit Ocağı) | 205 | 1 | temperate geometry, pale granite atlas | TESTED |
| steppe/rosehip_bush | steppe | food (Kuşburnu Çalısı) | 401 | 2 | arching canes + hips | TESTED |
| autumn/tree_pine | autumn | wood (Melez Ağacı) | 120 | 1 | pine geometry, golden larch foliage | TESTED |
| autumn/tree_oak | autumn | wood (Kızıl Meşe) | 272 | 1 | oak geometry, red-orange foliage | TESTED |
| autumn/berry_bush | autumn | food (Çakal Eriği) | 330 | 2 | blue-black sloes on orange leaves | TESTED |

Ground textures (`GR_GrassLush`, `GR_GrassDry`, `GR_Dirt`, `GR_Path`, `GR_Sand`, `GR_SandDark`, `GR_GrassSteppe`,
`GR_GrassAutumn`), the four nature atlases and the scatter atlas (`SC_ScatterAtlas`, 4×8 cells: common rows plus autumn leaf
litter, desert cactus/dune grass/bleached stones, steppe feather grass/thistle/lichen stone) are baked by
`pe_kit.export_material_library()` / `pe_kit.bake_scatter_atlas()` (both run by `build_environment.py`).

## 2b. Mills, fields and civ upgrade kits (farm & upgrade pass)

| Asset | Count | Source | Tris | Notes | Status |
|---|---|---|---|---|---|
| `<civ>/mill` | 10 (all civs) | `art_source/blender/buildings/<civ>_mill.py` → `parts.build_mill()` | 587–712 | tower windmill + separate `Sails` node (spun in Building3D); civ masonry/cap/annex/props | TESTED (test_building_models: footprint, ground, library materials, TEAM band) |
| `field`, `<biome>/field` | 4 (temperate, desert, steppe, autumn) | `environment/field.py` | 102–370 | 5–6 surfaces (soil, crop, border, wood, team pennant) | TESTED (test_farm_fields, in-game captures `docs/audits/evidence/farms/`) |
| `upgrade_kits/<civ>` | 10 | `environment/upgrade_kit.py` | 198–358 | dressing around any building with its own upgrade researched | TESTED (test_techs: loads + team surface; captures `docs/audits/evidence/upgrades/`) |

## 2c. 2D sprite set (rendered from the 3D models)

286 PNGs, 8 MB, in `sample_project/assets/sprites/`:
* 110 buildings × 2 teams;
* 4 biome fields × 2 teams;
* 10 upgrade kits × back/front × 2 teams;
* 18 environment props.

Placement data: `data/art/sprite_manifest.json`. Pipeline: BLENDER_PIPELINE §3.2.

Verification:
* `test_visual_style.gd`, 1141 checks:
  * 3D mode on all five maps: every prop and every civ × type × team is 3D;
  * 2D mode: every object uses its rendered sprite, with the right team, construction reveal and kit halves.
* In-game: `docs/audits/evidence/sprites/` (2D vs 3D, same seed) and the Android emulator capture.
* Status: TESTED.


## 3. Still on the previous (sprite / procedural) art

| Group | Count | Current art | Notes |
|---|---|---|---|
| Buildings | 0 | every building type has a 3D model for all 10 civs (sections 1, 1b, 2b) | 2D mode uses sprites rendered from those models (section 2c); the old hand-drawn sprites are only the last fallback |
| Farm (all civs) | – | replaced by biome **fields** placed from the Mill (section 2b) | done |
| Units (villager, swordsman, spearman, archer, cavalry + 10 unique) | 50 roles | HD-2D sprites + new occlusion silhouette | **3D characters + rigs + 6 animations not started.** Spec allows sprites until 3D replacements are validated. A rigged character pipeline is a separate milestone. |
| Cliffs / bridges / map skirt | — | procedural `PixelArtTextures` (cliffs tinted per biome) | ground, water and scatter were redone in the environment pass. Real biome cliff geometry is next |
| Market, Stone Wall | 20 gallery cells | — | not gameplay types in `Building3D`, so not built |
| Placement ghost | 1 | green box | could show the model as a translucent ghost |
