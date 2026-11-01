# Pocket Empires — Art Direction Bible

Status: v1 (2026-10-31). The source of truth is the in-game **Art Gallery** (`scenes/ArtPreview.tscn`,
`scripts/ArtPreview.gd`). This document records what was read from it and how it becomes 3D.

## 1. Sources inspected

| Source | Path | Content |
|---|---|---|
| Building atlas (5 civs) | `sample_project/art/buildings_reference/reference_first_5.png` (1448×1086) | Ottomans, Byzantines, Britons, Franks, Mongols × 13 building types |
| Building atlas (5 civs) | `sample_project/art/buildings_reference/reference_last_5.png` (1448×1086) | Teutons, Japanese, Saracens, Vikings, Chinese × 13 |
| Per-building crops | `sample_project/art/buildings/<civ>/<type>.png` (v2 "atlas-exact", 79–174 px wide, bottom-centre pivot) | 130 sprites, manifest `data/building_art_manifest.json` |
| Unit concept sheets | `sample_project/art/concept_sheets/<civ>.png` | 5 roles per civ (villager, swordsman, spearman, archer, unique unit) with poses |
| Unit sprites | `sample_project/art/units/<civ>/<role>/{pose_01,pose_02,action_reference,rear_reference}.png` (160×160) | 50 roles |
| Flags | `sample_project/art/flags/<civ>_reference.png` | used to derive banner/flag textures (`art_source/textures/emblems/`) |

Building types in the gallery: Town Center, House, Barracks, Archery Range, Stable, Blacksmith, Market, Watch Tower,
Stone Wall, Lumber Camp, Mining Camp, Mill, Castle. The game's `Building3D.BuildingType` also has **Farm**, which has no
gallery cell, and has **no Market or Stone Wall** gameplay type. Those two are art-only in the gallery; no gameplay is invented for them.

## 2. Camera & perspective

* Gallery: ~30° 3/4 isometric view from the front-left, pixel-art rendering, warm parchment background.
* Game: perspective camera, **45° pitch**, FOV 50, heights 12 / 24 / 38 m (close / default / far). The camera looks along −Z;
  building fronts face **+Z (Godot) = −Y (Blender)**.
* Consequence: from 45° the **roof dominates every silhouette**. Civ identity must live in the roof form and colour
  (dome, slate cone, kawara upturn, felt dome, shingle gable), not only in facades.
* Texel density: 32 px/m. That is ≈1 texel per screen pixel at default zoom (≈30 px/m on a 540×960 portrait viewport), ≈2 px at
  close zoom. This matches the pixel density of the existing unit sprites.

## 3. Style statement

Premium stylised 3D diorama: real geometry (domes, cones, arches, gables, tiers), every surface textured with
**small hand-tuned pixel-art patterns** (5-colour hue-shifted ramps: shadows drift violet, lights drift warm; light Bayer
dithering), nearest-neighbour filtering with mipmaps, warm key light. No photo textures, no normal maps, no PBR noise.
Each building sits on its own irregular dirt **diorama pad** inside the gameplay footprint.

## 4. Shared material palette (`art_source/blender/pe_kit.py` → `RAMPS`, `MATERIALS`)

| Family | Materials | Used by |
|---|---|---|
| Masonry | `PE_StoneWarm` (ashlar, warm), `PE_StoneGrey` (ashlar, cool), `PE_Sandstone`, `PE_StoneBrick` (Byzantine opus mixtum band) | all stone civs |
| Plaster | `PE_PlasterCream`, `PE_PlasterWhite` | Ottoman, Japanese, Briton half-timber |
| Roofs | `PE_RoofRed` (barrel tiles), `PE_RoofSlate` (blue slate), `PE_SlateDark` (Teutonic), `PE_RoofDark` (kawara), `PE_RoofTeal` (Chinese glazed), `PE_Shingle` (Viking wood), `PE_DomeLead` (charcoal-slate lead), `PE_TileTeal` | per civ |
| Timber | `PE_WoodDark` (planks), `PE_WoodLight`, `PE_Beam` (grain along length), `PE_Lattice` (shoji / khana) | all |
| Accent | `PE_Gold`, `PE_Iron`, `PE_LacquerRed`, `PE_ClothRed`, `PE_Felt`, `PE_FeltBlue`, `PE_Window` (dark recess) | per civ |
| Ground / nature | `PE_Dirt`, `PE_Grass`, `PE_Foliage`, `PE_NatureAtlas` (foliage/bark/rock/gold quadrants, 1 draw call per prop) | pads, trees, mines |
| Identity | `PE_Banner_<civ>` (flag emblem on civ field colour, gold trim), `TEAM_Trim` (recoloured per team in Godot) | every building |

Rules: one material per surface family, shared by every asset. No unique texture per prop. Mid-tones stay
mid-value so the warm sun reads.

## 5. Team vs civ identity

* **Civ identity** = architecture + palette + `PE_Banner_<civ>` banners and flags (from the gallery's flags).
* **Team identity** = `TEAM_Trim` surfaces (minaret bands, portal bands, tower bands, Viking shields, gate boards),
  recoloured at runtime to blue (team 0) or red (team 1) from `FactionArtManager.TEAM_COLORS`. **Every building must have
  at least one TEAM_ surface** (enforced by `test_building_models.gd`), so ownership is readable even when both players
  pick the same civilization.

## 6. Per-civilization architectural rules (as built + target)

| Civ | Read from gallery | 3D translation (Town Center as built) | Must avoid |
|---|---|---|---|
| Ottomans | lead domes, pencil minarets, pointed arches, red tiles on secondary roofs, red crescent banners | central dome on windowed drum + half-dome cascade, 4 minarets, pishtaq portal, red-tile porticos | domes on economic buildings (House/Lumber Camp have none) |
| Byzantines | terracotta domes, round arches, stone-and-brick bands, purple/gold | cross-in-square, terracotta main dome + 4 corner domes, red gabled arms, round-arch portal | Ottoman pencil minarets |
| Britons | stone keep, steep blue slate, round towers, half-timber, red cross | slate-roofed hall, half-timbered front gable, 4 round towers with cones | French gothic spires |
| Franks | tall Gothic, steep blue slate, spires, fleur-de-lis | nave + transept, dominant crossing spire, twin facade towers, rose window | squat keep look (distinguish from Britons by height + spire) |
| Mongols | felt ger, radial ropes, toono crown, blue standards | great ger on timber platform, felt dome with dark ribs, orange/blue bands, 4 banner poles | any stone or tile |
| Teutons | heavy grey stone, near-black slate, crenellated keep, black cross | dark hip roof hall, square bergfried with crenellations + spire, gatehouse | light/airy gothic (that is Franks) |
| Japanese | tiered keep, white plaster + dark timber, kawara, upturned eaves, red accents | ishigaki battered base, 3 tiers, curved hip roofs, red lacquer bands, nobori | Chinese red walls / teal tiles |
| Saracens | sandstone, gold dome, teal accents, slender minarets | gold dome on teal-banded drum, iwan portal, teal-domed minarets, tent, palms | Ottoman lead dome / pencil cones |
| Vikings | timber longhouse, steep shingle roof, carved gable heads, shields | stave hall on stone footing, steep shingle gable, crossed dragon gables, team shields | stone castle forms |
| Chinese | tiered pavilion, green-teal tiles, red columns, walled platform, gold ridges | crenellated stone platform with gate, 2 red pavilions with teal curved roofs, gold ridge ornaments | Japanese white walls / dark tiles |

### 6.1 Mills and upgraded buildings

The Mill keeps the gallery's tower-windmill silhouette for every civ, so it is recognisable at a glance. The civ shows
in the tower material, cap, granary annex and props:

| Civ | Tower | Cap | Granary annex and props |
|---|---|---|---|
| Ottomans | plaster | red-tile cone | red-tiled granary, cypress |
| Byzantines | brick-banded | terracotta | domed granary, amphorae |
| Britons | whitewash | thatch | half-timbered granary under thatch, hay |
| Franks | pale stone | blue-slate cone, gilt finial | barrels |
| Mongols | felt | felt tent cap | ger, cart, lattice sails |
| Teutons | dark stone | black slate | half-timbered granary |
| Japanese | plaster | double-eave kawara | kura storehouse, straw bales |
| Saracens | sandstone | teal dome | domed granary, date palm |
| Vikings | planked | shingle | stabbur on stone posts, shield |
| Chinese | stone | teal pavilion cap on red posts | red-pillared granary |

**Upgraded buildings** (a building's own ★ technology) get the civ upgrade kit around their footprint. The kit has a
kerb, four culture-specific corner pieces and two front standards with the civ banner and a team pennant. It is
listed in docs/design/FARMS_TECHS_UPGRADES.md §3. Fields are farmland, so their crop follows the **map biome**, not the
civ.

### 6.2 Houses

Houses are the most numerous building, so the civ has to read from the roof and one tall marker at RTS pitch. Every house
carries a team surface that is visible from above (pennant, awning, lanterns, shields or a band), 448–628 tris, 8–10
materials. In-game evidence: `docs/audits/evidence/houses/houses_ingame_10civs.png`.

| Civ | Form | Roof | Marker / props | Team surface |
|---|---|---|---|---|
| Ottomans | two storeys, stone + plaster cumba | red barrel tile hip | slim corner tower, lead cone | tower band, awning |
| Byzantines | L-plan, stone with brick bands | low terracotta gables | arcaded loggia, vine pergola, amphorae | loggia awning, pennant |
| Britons | whitewash cottage, timber frame | hipped thatch + eyebrow dormer | stone chimney, wattle fence | shutters, pennant |
| Franks | tall pale-stone manor | steep blue slate hip + dormer | round stair turret, slate spire, gilt finial | shutters, turret pennant |
| Mongols | family ger | white felt dome, rope bands | toono + stove pipe, felt ox cart, hitching line | wall band, pennant |
| Teutons | stone ground floor, jettied half-timber | very steep black slate, gable to the street | stepped stone gable | shutters, pennant on the top step |
| Japanese | minka, white plaster in dark frame | irimoya kawara with lifted eaves | engawa veranda, bamboo fence | noren curtain, nobori cloth |
| Saracens | flat-roofed sandstone, two heights | parapets + roof terrace | wind catcher, mashrabiya, teal door frame | terrace awning |
| Vikings | small longhouse, plank walls | steep shingle (turf was rejected: it read as grass ground) | crossed gable boards, drying rack | wall shields, pennant |
| Chinese | courtyard house on a platform | teal curved hip, gold ridge ends | red columns, courtyard wall + gate | eave lanterns, pennant |

### 6.3 Other building types (civ kit)

Barracks, Archery Range, Stable, Blacksmith, the camps, Watch Tower and Castle use one layout per type for every civ
(`art_source/blender/bldtypes.py`), so a player recognises the type at a glance. The civ is carried by the kit
(`civstyle.py`):

| Civ | Walls | Roof | Tower form | Castle wall top |
|---|---|---|---|---|
| Ottomans | cream plaster on warm stone | red tile hip, lead-domed cupola on long halls | round plaster tower, lead cone | crenels |
| Byzantines | stone with brick bands | low terracotta gable | square banded tower, terracotta dome | crenels |
| Britons | whitewash + timber frame | thatch gable (as houses and mill; only the TC keeps slate) | round grey tower, slate cone | crenels |
| Franks | pale stone, pointed openings | steep blue slate hip | round tower with tall slate spire, gilt finial | crenels |
| Mongols | felt gers, felt awnings | felt dome | timber frame with felt-capped lookout | timber palisade |
| Teutons | grey stone | very steep black slate, stepped stone gables | square crenellated bergfried with black spire | crenels |
| Japanese | white plaster in dark frame, lattice | irimoya kawara | yagura on a battered stone base | tile-capped white wall on stone base |
| Saracens | sandstone, teal trims, pointed arches | flat roof with crenellated parapet, cloth awnings | square sandstone tower, small teal dome | crenels |
| Vikings | dark planks with light battens | steep shingle, crossed gable boards | timber tower, shingle pyramid, team shield | timber palisade |
| Chinese | grey stone, red lacquer columns, lattice | teal curved hip, gold ridge ends | stone base with red-pillared pavilion top | teal tile-capped wall |

Britons were switched from slate to thatch on kit buildings after the first in-game capture: with slate, Briton and
Frank barracks (blue roof + round tower) were too close.

## 7. Scene look & environment (HD-2D environment pass, style reference: Octopath Traveler 2)

Style principles taken from the reference. Nothing was copied: no images, textures or names in the repo.

* **Light:** warm, low key light (`1, 0.9, 0.76`, energy 1.35, pitch −36° for long shadows, shadow opacity 0.85), cool
  ambient (`0.46, 0.54, 0.72` × 0.6), filmic tonemap at exposure 0.92, contrast 1.08 / saturation 1.08 (Environment
  adjustments; verified working in the Compatibility renderer).
* **Ground (`shaders/hd2d_ground.gdshader` + `scripts/HD2DGround.gd`):** world-space pixel-art textures (32 px/m, no
  per-tile repetition grid): lush grass with blade strokes, dry-grass patches, bare dirt, pebble paths; sand / dark sand
  on desert maps. A per-map control texture places worn courtyards around Town Centers, rocky ground at mines, and dirt
  roads that follow **real A\* routes** (base ↔ base, base → its gold/stone/food). Transitions are Bayer-dithered at
  texel-snapped positions, so they read as crisp pixel steps. Light variation is quantised to 4 levels.
* **Ground scatter (`shaders/hd2d_scatter.gdshader` + `scripts/HD2DScatter.gd`):** grass tufts, four flower colours,
  ferns and mushrooms next to trees, pebbles on dirt, dry tufts on desert. Crossed pixel-art quads with darker roots and
  gentle wind sway. One MultiMesh per 10 map rows (~6 draw calls). Instances under a newly placed building are hidden.
* **Water (`shaders/hd2d_water.gdshader`):** deep teal with 4 quantised ripple tones and blinking sparkle texels.
* **Framing:** soft cool vignette (`shaders/hd2d_vignette.gdshader`, multiply blend on a CanvasLayer below the HUD,
  `MOUSE_FILTER_IGNORE`, so it never blocks input).
* **No depth-of-field / tilt-shift.** Correction to v1 of this document: the `dof_blur_*` keys that used to sit in
  `Main3D.tscn` were on the `Environment` resource, which has no such properties in Godot 4, so the game **never had DOF**.
  The dead keys were removed. A tilt-shift band is optional future work. It would blur the top of a portrait screen,
  which is where enemies come from, so it needs a readability decision first.
* Units keep their HD-2D sprites. Behind 3D trees and buildings they render a team-coloured **occlusion silhouette**.

### 7.1 Biomes (one prop set per map family)

| Biome | Maps | Trees | Gold / Stone | Food | Ground / water / cliffs |
|---|---|---|---|---|---|
| temperate | Yeşil Vadi, Nehir Geçidi | pine + oak (lush green) | grey boulders / grey quarry | berry bush (red) | lush + dry grass, teal water |
| desert | Çöl Vahası | date palm + umbrella acacia | sandstone hoodoos / terraced sandstone quarry | prickly pear | sand + dark sand, dune grass, small cactus, bleached stones, turquoise water, warm sandstone cliff tint |
| steppe | Yayla Bozkırı | scots pine + juniper (sage, red bark) | pale lichen granite | rosehip (kuşburnu) | muted sage-ochre grass, feather grass, thistle, lichen stones, cold slate water, cool cliff tint |
| autumn | Hazine Vadisi | larch (gold) + red oak | temperate rock (shared) | sloe bush (blue-black on orange) | late-season olive grass with dry patches, leaf litter, mushrooms near trees, warm cliff tint |

Rules: each biome changes **ramps** before geometry (one atlas per biome, same layout), resource **silhouettes stay
recognisable across biomes** (mines keep the timber adit frame and gold crystals; food props keep a bright fruit colour
against the foliage), and footprints/heights stay in the temperate range so gameplay readability does not change.
No snow biome: the user chose to theme only the existing five maps.

Before/after on the same seeded map: `docs/audits/evidence/environment/before_map{0,1}_*` vs `after_map{0,1}_*`.

### 7.2 Hills (natural elevation)

Hills used to be stepped block terraces: flat 1-cell tiles with thin vertical stone walls between them. They are now
real slopes:

* **Shape.** Each cell still gets a target level (lowland 0, hill 2.2 m, highland rock peak 4.4 m, water bed −0.65 m).
  `MapGenerator3D._build_height_grid` blurs these levels (gaussian σ ≈ 1 cell) into a 1 m vertex grid and adds a gentle
  roll (±0.22 m) to open ground. The two bases stay level out to 7.5 cells, and land next to water is held low so banks
  slope into rivers and lakes instead of dropping as a wall.
* **One surface.** The ground mesh is built from that grid. `get_height_at()` samples the same triangles, so units,
  buildings, trees, mines, bushes and grass tufts all stand on the visible ground. Units follow it every frame, and a tap
  on a hilltop is ray-marched onto the hilltop.
* **Readability from the high camera.** In `hd2d_ground.gdshader`, slopes facing the sun are lighter and slopes facing
  away are darker, in quantised dithered bands. High ground is slightly lighter. Steep ground shows earth, and the
  steepest shows the biome-tinted rock.
* **Water.** There is one water surface over the wet area, so the shoreline follows the terrain. Lake corners are rounded.
* **Building on hills.** A building needs ground that rises at most 0.8 m across its footprint. It sits at the lowest
  point, slightly dug into the uphill side and never floating. The player, the AI and mill fields all use the same
  check. On the hilly Highland map about half of the open 2×2 plots are level enough; on the other maps 70–90 % are.

Evidence: `docs/audits/evidence/terrain/hills_before.png` vs `hills_after.png` (same seeds, fog hidden for the capture),
and `hills_details.png` (villagers on a slope beside a barracks built on sloped ground, a river ford, an oasis shore).

## 8. Interpretation decisions & known deviations (honest list)

* Gallery art is a single 3/4 view. Hidden sides are inferred by mirroring the visible massing without the entrance.
* Gallery crops include crowds of tiny figures and dense vegetation. The 3D versions keep 2–4 props/trees inside the footprint
  so gameplay space and selection stay clear.
* **Japanese TC** has less red lacquer and gold than the gallery cell. **Mongol TC** has simpler ornament than the gallery
  (no painted felt patterns). **Ottoman TC** courtyard wall became side porticos. None of these is a 1:1 reproduction.
* Units: all 10 civs are rigged 3D characters (`art_source/blender/units/unitstyle.py` has the table read from each
  concept sheet). Their 2D sprites are rendered from the same models.
  - **Culture through materials.** 16 px atlas patterns carry the cloth and armour:
    - Ottoman / Byzantine / Frankish / Saracen embroidery;
    - Chinese brocade;
    - mail;
    - Mongol, Chinese and Byzantine lamellar;
    - Byzantine gilded scale;
    - Japanese lacquered plates;
    - Viking studded leather;
    - fur and straw.
  - **Shields and barding** carry the gallery flag emblems: the chi-rho, the fleur-de-lis, the Mongol flame, the
    crescents, the Teutonic eagle, the Norse dragon and the Chinese dragon. The Teutonic cross is drawn as a shape.
  - **Headwear and weapons are modelled per culture:**
    - turbans, the bork, hoods, mail coifs;
    - nasal, kettle, spangen, crested, great, Mongol and Chinese helmets;
    - kabuto with gold kuwagata, jingasa, straw hats, hachimaki, the berserker's wolf pelt;
    - scimitar, sword, katana, dao, yari, lance with an emblem pennant, recurve / long / yumi bows, musket,
      repeating crossbow, bearded axes;
    - sashimono banners on the back.
  - **Mounts.** A second rig: the humanoid rider on the saddle of a horse or a camel, with its own idle, canter,
    attack and fall animations. The cataphract wears gilded scale barding, the knight a blue-and-gold check caparison
    with the fleur-de-lis, and the mamluk rides a camel with a green embroidered blanket and gold tassels.
  - **Simplified.**
    - Embroidery is a repeated motif, not hand-painted.
    - Archers carry their bows at the side and draw only in the attack.
    - Villagers use the axe for every job.
  - **Changed for gameplay.** The waist sash is the team colour.
  - **Evidence.** `docs/audits/evidence/units/<civ>_gallery_3d.png` (the gallery row above the models).
